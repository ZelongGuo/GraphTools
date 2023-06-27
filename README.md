# Visualization Tools 
> There is a collection of some plotting scripts I used.

- get_swath.sh:
	- this script is used for generating the files needed for plotting swath, in which you can get the mean, maximun and minimun values stacked within this swath. Usually you can use it for plotting topography and los displacements within this swath, also you can get the corner coordinates of the swath. Note one of the input parameter is **width**, this is the totoal width of the swath. For comarison, the GMT command **coupe**, the option -Aa has a sub-parameter *+w*, which means the width for **each side** of the cross section, say the total width of **gmt coupe** defined is 2*sub-parameter of +w!
