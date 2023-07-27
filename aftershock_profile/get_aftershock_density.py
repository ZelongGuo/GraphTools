#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on 6/28/23

@author: zelong
"""

import aftershock_profile as ap
import os
import numpy as np

# -----------------------------------------------------------------
# parameters defination
start_lon, start_lat = 45.125, 34.75  # -> CC' # 45.4625, 34.536  # -> Yang SRL  # 45.325, 34.247 -> AA'
end_lon, end_lat = 46.382, 34.95  # -> CC' # 46.601, 35.4205  # -> Yang SRL  # 46.082, 35.129 -> AA'
# the total width of the swath, unit is km
swath_width = 30  # -> CC' # 16  # -> Yang SRL # 8 -> AA'
outfile = "all_relocated_eq_CC.xyz" # -> CC'  # "all_relocated_eq_Yang_16km.xyz"  # -> Yang SRL  # "all_relocated_eq_AA_8km.xyz" -> AA'
# note the distance_max and depth_max you should also change them maybe
# -----------------------------------------------------------------

start_point = np.array([start_lon, start_lat])
end_point = np.array([end_lon, end_lat])

# combine the aftershock files together: redirect to a new file: lon lat depth ...
os.system("grep '^[0-9]' ./Fathian_aftershocks.txt | awk -F ' ' '{print $1, $2, $3, $5}' > all_relocated_eq.txt")
os.system("grep '^[0-9]' ./relocated_events_sup.txt | awk -F ' ' '{print $4, $3, $5, $6}' >> all_relocated_eq.txt")

_, _, _ = ap.aftershock_density_along_profile('./all_relocated_eq.txt', start_point, end_point, swath_width, distance_max=160, depth_max=30, plot=True)
to_sys = "mv all_relocated_eq.xyz %s" % outfile
os.system(to_sys)





