#!/bin/bash
 
# Zelong Guo, 25.06.2023
# this script is used for calculating the stacked files and the corner coordinates of the selected swath.

version="26/06/2023"

if [ "$1" == "--help" ] || [ "$1" == "-help" ] || [ "$1" == "-h" ] || [ "$#" -lt "6"  ]; then
	cat<<END && exit 1 

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		 
	Get the maximum, minmum, mean values as well as the corner coordinates of a swath along a profile,
	based on a given grid file.
	
	Require: GMT Software

    	Program:		`basename $0`
	Written by:		Zelong Guo (GFZ, Potsdam)
        First version:		25/06/2023
	Last edited:		$version

	usage:		$(basename $0) <lon0> <lat0> <lon1> <lat1> <grdfie> <swath_width> <sample> <spacing> <plot_flag>
	                  
		<lon0>:		(input) the longitude of the STARTING point
		<lat0>:		(input) the latitude of the STARTING point
		<lon1>:		(input) the longitude of the END point
		<lat1>:		(input) the latitude of the END point
		<grdfile>: 	(input) the grid files you want to process
		<swath_width>: 	(input) the TOTAL swath width 
		<sample>:	(input) the sample spacing ALONG the survey line (from starting to end point) for every profiles (the profiles are parallel to the survey line), the unit is km,  default = 0.1
		<spacing>:	(input) the spacing for each profile ALONG the swath width (the swath width is perpendicular to the survey line), the unit is km, default = 0.3
		<plot_flag>: 	(input) if you need plotting (yes or y) or not (no or n), default is y

	output:
		swath_profile.txt: A summary file includes all segments (cross profiles) which are parallel to the survey line (from start to end point), shown as dashed gray lines in the figure
		swath_mean.txt: The file which is stacked mean value within swath width along the survey line
		swath_upper.txt:  The file which is stacked max value within swath width along the survey line
		swath_lower.txt:  The file which is stacked min value within swath width along the survey line
		swath_mean_upper_lower.dat: The final file includes stacked mean, upper and lower vaules within the swath along the survey line, for GMT plotting
		swath_mean_confidence_bounds.dat: The final file includes stacked mean, upper and lower 2-sigma confidence bounds within the swath along the survey line, for GMT plotting
		cornerCoor.dat: The corner coordinates of the swath


+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

END
fi
# =============================================================================
# Update Needed:
# Output a file including stacked mean values and the 2-sigma confidence bound 
# =============================================================================

#=================================================================
# Pre-setting
gmt set MAP_FRAME_PEN .8p
gmt set FONT_ANNOT_PRIMARY 6p
gmt set FONT_ANNOT_SECONDARY 6p
gmt set FONT_LABEL 8p
gmt set MAP_TICK_LENGTH 0.1c
gmt set MAP_FRAME_TYPE Plain
gmt set MAP_ANNOT_OFFSET_PRIMARY 1p
gmt set MAP_ANNOT_OFFSET_SECONDARY 1p
gmt set MAP_LABEL_OFFSET 1.5p
gmt set MAP_ANNOT_OBLIQUE lat_parallel
gmt set MAP_GRID_PEN 0.2p,gray
gmt set MAP_GRID_CROSS_SIZE 4p
#=================================================================

# ------------------------------------------------------------------------------------------------------------
# origial start point 
lon0=$1
lat0=$2
# origial end point
lon1=$3
lat1=$4
# the grd files you want to do the calculations
grdfile=$5
# the TOTAL width of the swath (km)
swathw=$6 
# the sample spacing along the survey line for every profiles, the unit is km,  default = 0.1 km
sample=${7:-0.1}
# the spacing for each profile along the swath width (which is parammel to the survey line), the unit is km, default = 0.3 km
spacing=${8:-0.3}
plot_flag=${9:-y}


#*******************************************************************************
echo "Calculating the lenght and azimuth from original end point to start point:(lon_endpoint lat_endpoint azimuth length)"
echo ${lon1} ${lat1} | gmt mapproject -Af${lon0}/${lat0} -G${lon0}/${lat0}+uk -je
azimuth=$(echo ${lon1} ${lat1} | gmt mapproject -Af${lon0}/${lat0} -G${lon0}/${lat0}+uk -je | awk '{print $3}')
length=$(echo ${lon1} ${lat1} | gmt mapproject -Af${lon0}/${lat0} -G${lon0}/${lat0}+uk -je | awk '{print $4}')
echo "The azimuth and length from starting point to end point is $azimuth and $length, respectively ..."

# Central Point
# We must need to find the position (cenlon,cenlat) of midpoint of the desired survey line, as the central blue circle in the figure.
cendist=$(echo "${length}/2.0" | bc -l)
cenlon=$(gmt project -C${lon0}/${lat0} -A${azimuth} -G${cendist} -L0/${cendist} -Q | tail -1 | awk '{print $1}')
cenlat=$(gmt project -C${lon0}/${lat0} -A${azimuth} -G${cendist} -L0/${cendist} -Q | tail -1 | awk '{print $2}')

# Central Point 1 (Edge)
# We find one endpoint (cen1lon,cen1lat) of the orthogonal line, as the green circle on the border in the figure.
cen1azimuth=$(echo "${azimuth}-90" | bc -l)
half_swathw=`echo $swathw | awk '{print $1/2}'`  # here we need the half of total swath width
cen1lon=$(gmt project -C${cenlon}/${cenlat} -A${cen1azimuth} -G${half_swathw} -L0/${half_swathw} -Q | tail -1 | awk '{print $1}')
cen1lat=$(gmt project -C${cenlon}/${cenlat} -A${cen1azimuth} -G${half_swathw} -L0/${half_swathw} -Q | tail -1 | awk '{print $2}')

# Central Point 2 (Edge)
# We find another endpoint (cen2lon,cen2lat) of the orthogonal line, as the green circle on the other border in the figure.
cen2azimuth=$( echo "${azimuth}+90" | bc -l )
cen2lon=$( gmt project -C${cenlon}/${cenlat} -A${cen2azimuth} -G${half_swathw} -L0/${half_swathw} -Q | tail -1 | awk '{print $1}' )
cen2lat=$( gmt project -C${cenlon}/${cenlat} -A${cen2azimuth} -G${half_swathw} -L0/${half_swathw} -Q | tail -1 | awk '{print $2}' )
 
# ******************************************************************************************************************************************

# track and stack along the cross-profiles of CENTRAL NORMAL LINE (green point1 to green point2)
Clength=${length}"k"
#*******************************************************************************
Csample="${sample}k"  # km
Cspacing="${spacing}k"  # km
profilefile="swath_profile.txt"
stackfile="swath_mean.txt" # output: dist(raletive distance, i.g.,-60km to 60 km) value std min max up_confident low_confident
stackfileupper="swath_upper.txt" 
stackfilelower="swath_lower.txt"
stackfileMUL="swath_mean_upper_lower.dat"
stackfileMCB="swath_mean_confidence_bounds.dat"

gmt grdtrack -G$grdfile -C${Clength}/${Csample}/${Cspacing}+v -Sa+s${stackfile} << EOF > ${profilefile}
${cen1lon} ${cen1lat}
${cen2lon} ${cen2lat}
EOF
gmt grdtrack -G$grdfile -C${Clength}/${Csample}/${Cspacing}+v -Su+s${stackfileupper} << EOF > ${profilefile}
${cen1lon} ${cen1lat}
${cen2lon} ${cen2lat}
EOF
gmt grdtrack -G$grdfile -C${Clength}/${Csample}/${Cspacing}+v -Sl+s${stackfilelower} << EOF > ${profilefile}
${cen1lon} ${cen1lat}
${cen2lon} ${cen2lat}
EOF

# output the coordinates of the 4 corner pointes of swath profile 
# extracr the first data segment
gmt convert $profilefile -Q0 | sed -n '2p' > cornerCoor.dat
gmt convert $profilefile -Q0 | sed -n '$p' >> cornerCoor.dat
n=`grep '>' $profilefile | wc -l`
let n=n-1
gmt convert $profilefile -Q$n | sed -n '$p' >> cornerCoor.dat
gmt convert $profilefile -Q$n | sed -n '2p' >> cornerCoor.dat


# convert the relative distance to absolute distace 
awk -v leng=${length} '{print $1+leng/2,$2,$3,$4,$5,$6,$7}' ${stackfile} > swath.temp
mv swath.temp ${stackfile}
awk -v leng=${length} '{print $1+leng/2,$2,$3,$4,$5,$6,$7}' ${stackfileupper} > swath.temp
mv swath.temp ${stackfileupper}
awk -v leng=${length} '{print $1+leng/2,$2,$3,$4,$5,$6,$7}' ${stackfilelower} > swath.temp
mv swath.temp ${stackfilelower}

awk '{print $1, $2}' $stackfile > temp0.dat
awk '{print $2}' $stackfileupper > temp1.dat
awk '{print $2}' $stackfilelower > temp2.dat
gmt convert temp0.dat temp1.dat temp2.dat -A | grep -v 'NaN' > ${stackfileMUL}
rm temp?.dat

awk '{print $1, $2, $6, $7}' $stackfile > $stackfileMCB

# add the files heads 
sed -i '1i # Distance stacked_value deviation min_value_of_all max_value_of_all lower_confidence_bound upper_confidence_bound' ${stackfile}
sed -i '1i # Distance stacked_value deviation min_value_of_all max_value_of_all' ${stackfileupper}
sed -i '1i # Distance stacked_value deviation min_value_of_all max_value_of_all' ${stackfilelower}
sed -i '1i # Distance stacked_mean_value stacked_upper_value stacked_lower_value' ${stackfileMUL}
sed -i '1i # Distance stacked_mean_value   upper/lower 2-sigma confidence bounds' ${stackfileMCB}


#------------------------------------------------------------------------------------------------------------------------
# if you want to plot it or not:
if [ "$plot_flag" == "y" ] || [ "$plot_flag" == "yes" ]; then
	gmt begin $0 png
		R1=`echo $lon0 | awk '{print $1-0.3}'`
		R2=`echo $lat0 | awk '{print $1-0.3}'`
		R3=`echo $lon1 | awk '{print $1+0.3}'`
		R4=`echo $lat1 | awk '{print $1+0.3}'`
		R=${R1}/${R3}/${R2}/${R4}

		gmt basemap -R$R -JM7c -BSWne -Bafg0

		# plot the country border and km scale
		gmt coast -N1/0.6p,black,-- -Lg$R1/$R2+c$R1+o0.5c/0.5c+w${swathw}k+lkm
		# plot the original line we want
		gmt plot -W0.6p,red,solid << EOF
		$lon0 $lat0
		$lon1 $lat1
EOF
		gmt plot -Sc0.12c -W0.8p,white -Ggray20 << EOF
		$lon0 $lat0
		$lon1 $lat1
EOF
						 
	awk '{print $1, $2}' cornerCoor.dat | gmt plot -W0.5p,red -L
	echo ${cenlon} ${cenlat} | gmt plot -Sc0.1 -W0.2p -Gblue
	echo ${cen1lon} ${cen1lat} | gmt plot -Sc0.08 -W0.2p -Ggreen
	echo ${cen2lon} ${cen2lat} | gmt plot -Sc0.08 -W0.2p -Ggreen
	gmt plot $profilefile -W0.1p,gray,-

#	gmt legend -DjBR+w2c+o0.5c/0.5c << EOF
#S 0.1 -- 0.3c - 0.5p,black 0.3c national border
#EOF

		

	gmt end show
	rm gmt*
fi

