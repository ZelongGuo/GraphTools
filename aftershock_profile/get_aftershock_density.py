#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on 6/28/23

@author: zelong
"""

import aftershock_profile as ap
import os
import numpy as np

# now we select the aftershocks within in the swath
start_lon, start_lat = 45.325, 34.247
end_lon, end_lat = 46.082, 35.129
start_point = np.array([start_lon, start_lat])
end_point = np.array([end_lon, end_lat])
swath_width = 8  # unit is km  # the total width of the swath

# combine the aftershock files together: redirect to a new file: lon lat depth ...
os.system("grep '^[0-9]' ./Fathian_aftershocks.txt | awk -F ' ' '{print $1, $2, $3}' > all_relocated_eq.txt")
os.system("grep '^[0-9]' ./ggac057_supplemental_file/Tabale_suplement/relocated_events_sup.txt | awk -F ' ' '{print $4, $3, $5}' >> all_relocated_eq.txt")

_, _, _ = ap.aftershock_density_along_profile('./all_relocated_eq.txt', start_point, end_point, swath_width, distance_max=120, depth_max=25, plot=True)





