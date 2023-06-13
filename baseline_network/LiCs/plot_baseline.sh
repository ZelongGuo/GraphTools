#!/bin/bash

gmt set MAP_GRID_PEN_PRIMARY 0.3p,grey60,-
gmt set FORMAT_DATE_MAP=-o

J=X12c/6c
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++ Now ploting baseline ++++++++++++++++++++++++++++++++++
gmt begin baseline_network tif
	gmt subplot begin 2x1 -Fs12c/6c -M0c/0.4c

	gmt subplot set 0,0
	#--------------------------------------------- T072A -----------------------------------------------
	# s p: primary and seconderay scale, Y:year, o:month
	gmt basemap -R2017-09-01T/2022-07-25T/-215/90 -J$J -Bsxa1Y -Bpxa2of1og5o -Bya50f10g30+l'Perpendicular baseline (m)' -BSWrt
	gmt plot GMT_T072A.txt -W0.6p,gray50
	gmt plot GMT_T072A.txt -Sc0.13c -Gsienna1 -W0.6p 
	# reference point
	gmt plot -Sd0.25c -Ggreen -W1p << EOF
	2017-11-17T 0
EOF
	echo 2017-12-01 80 T072A | gmt text -Wthick,solid -Gblack -F+f12p,Helvetica-Bold,white
	echo 2019-11-17 80 Ref. image 2017.11.17 | gmt text -Wthick,solid -F+f12p,Helvetica-Bold

        #--------------------------------------------- T079D -----------------------------------------------
	gmt subplot set 1,0
	gmt basemap -R2017-09-01T/2022-02-25T/-110/200 -J$J -Bsxa1Y+l'Time' -Bpxa2of1og5o -Bya50f10g30+l'Perpendicular baseline (m)' -BSWrt
	gmt plot GMT_T079D.txt -W0.6p,gray50
	gmt plot GMT_T079D.txt -Sc0.13c -Gsienna1 -W0.6p
	# reference point
	gmt plot -Sd0.25c -Ggreen -W1p << EOF
	2018-09-26T 0
EOF
	echo 2017-12-01 190 T079D | gmt text -Wthick,solid -Gblack -F+f12p,Helvetica-Bold,white
	echo 2019-11-17 190 Ref. image 2018.09.26 | gmt text -Wthick,solid -F+f12p,Helvetica-Bold
	gmt subplot end



gmt end show
rm gmt*
