#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on 6/27/23

This script is used for getting the aftershocks density within a swath along a cross-section.

@author: zelong
"""
import matplotlib.pyplot as plt
import numpy as np
import utm
import math
import os


def project_point_onto_line(point_lonlat, line_start_lonlat, line_end_lonlat):
    """
    used in aftershocks_profile.aftershock_density_along_profile

    point:
        the point coordinates, [lon, lat], the unit is degree
    line_start:
        the coordinates of the start point, [lon, lat]
    line_end:
        the coordinates of the end point, [lon, lat]

    return:
        the point coordinates which is projected onto the survey line (from start point to end point)

        the distance between the original point to the survey line, which could be used for selecting points within a swath, the unit is km

        the distance between the projected point onto the survey line and the start point
    """
    # degree to utm firstly
    point_easting, point_northing, zone_num, zone_letter = utm.from_latlon(point_lonlat[1], point_lonlat[0])
    point_start_easting, point_start_northing, _, _, = utm.from_latlon(line_start_lonlat[1], line_start_lonlat[0])
    point_end_easting, point_end_northing, _, _, = utm.from_latlon(line_end_lonlat[1], line_end_lonlat[0])
    point = np.array([point_easting, point_northing])
    line_start = np.array([point_start_easting, point_start_northing])
    line_end = np.array([point_end_easting, point_end_northing])

    # calculate direction vector
    line_direction = line_end - line_start
    # calculate the unit vector of the line
    line_direction_unit = line_direction / np.linalg.norm(line_direction)
    # calculate the vector from the point to start point
    point_vector = point - line_start
    # calculate the projection vector
    projection_vector = np.dot(point_vector, line_direction_unit) * line_direction_unit
    # calculate the point coordinates after projection
    projected_point = line_start + projection_vector

    # calculate the distances
    distance_to_line = (math.sqrt((point_easting - projected_point[0])**2 +
                          (point_northing - projected_point[1])**2) / 1000)  # the unit from m to km
    distance_to_start_point = (math.sqrt((point_start_easting - projected_point[0])**2 +
                                         (point_start_northing - projected_point[1])**2) / 1000)

    # projected point: utm to degree
    lat, lon = utm.to_latlon(projected_point[0], projected_point[1], zone_num, zone_letter)
    projected_point_deg = np.array([lon, lat])
    return projected_point_deg, distance_to_line, distance_to_start_point


def aftershock_density_along_profile(filename, start_point, end_point, swath_width, distance_max=None, depth_max=None, plot=False):
    """
    filename:
        text file of aftershocks: lon lat depth ..., if have, the comment line should start with '#'
    start_point:
        the start point of the survey line, [lon lat], the unit should be degree
    end_point:
        the end point of the survey line, [lon lat], the unit should be degree
    swath_width:
        the total width of the swath, the unit is km
    max_distance:
        maximum distance you want to output, km, default = length of start point to end point
    max_depth:
        maximum depth you want to output, km, default = maximum depth of the aftershocks within the swath
    plot:
        if plot the figure or not, default = no

    the default output file is filename.xyz

    """
    # =========================================== Read files ==========================================================
    # read the aftershock files
    data = np.loadtxt(filename, comments='#')
    start_point = np.array(start_point)
    end_point = np.array(end_point)

    # ================================ Calculate the projection point and distances ===================================
    # calculating the point coordinates after projection on the survey line (from start to end point), and the distance
    # between the point to the survey line
    data_point_projection = []
    data_point_distance = []
    data_point_to_start_distance = []

    for i in range(len(data)):
        point_projection_temp, point_distance_temp, point_to_start_distance_temp = project_point_onto_line(data[i, 0:2], start_point, end_point)
        data_point_projection.append(point_projection_temp)
        data_point_distance.append(point_distance_temp)
        data_point_to_start_distance.append(point_to_start_distance_temp)

    data_point_projection = np.array(data_point_projection)
    data_point_distance = np.array(data_point_distance)
    data_point_to_start_distance = np.array(data_point_to_start_distance)

    # ================================ Select the points within the swath ========================================
    # stack the lon, lat, distance_to_start_point, depth and distance_to_survey_line
    data_point_projection = np.hstack((data_point_projection, data_point_to_start_distance.reshape((-1, 1)), data[:, 2].reshape((-1, 1)), data_point_distance.reshape((-1, 1))))

    # firstly selection the points based on the longitude
    data_point_projection_select = (data_point_projection[(data_point_projection[:, 0] >= start_point[0]) &
                                                  (data_point_projection[:, 0] <= end_point[0]), :])
    # then select the points based on the distance between the points to the survey line
    distance_threshold = swath_width / 2
    data_point_projection_select = data_point_projection_select[data_point_projection_select[:, 4] <= distance_threshold, :]

    # now we sort the array based on the distances between projection points to the start point
    data_point_projection_select = data_point_projection_select[np.argsort(data_point_projection_select[:, 2])]

    all_eq = data_point_projection_select[:, 2:4]  # distance_to_start_point, depth_of_aftershocks

    # make statistics
    if distance_max is None:
        distance_max = math.ceil(max(all_eq[:, 0]))
    if depth_max is None:
        depth_max = math.ceil(max(all_eq[:, 1]))

    statistics_xyz = []
    for i in range(distance_max):
        for j in range(depth_max):
            temp = all_eq[(all_eq[:, 0] >= i - 1) & (all_eq[:, 0] <= i) & (all_eq[:, 1] >= j - 1) & (all_eq[:, 1] <= j), :]
            k = len(temp)
            statistics_xyz.append([i, j, k])

    statistics_xyz = np.array(statistics_xyz)

    # write to a txt file
    filename_without_extension = os.path.splitext(os.path.basename(filename))[0]
    filename_ouput = filename_without_extension + '.xyz'
    np.savetxt(filename_ouput, statistics_xyz, fmt='%d', header='distance(km) depth(km) density_per_km2')
    print(f"Now the results have been written to {filename_ouput}.")

    if plot:
        plt.scatter(all_eq[:, 0], -all_eq[:, 1])
        plt.xlim(0,distance_max)
        plt.ylim(-depth_max, 0)
        plt.xlabel('distance (km)')
        plt.ylabel('depth (km)')
        plt.show()

    return data_point_projection_select, all_eq, statistics_xyz

