

# this is better
#pdal ground 

source activate pdal

pdal ground $1 -o $2 --extract

#pdal translate -i $1 -o $2 outlier smrf range\
#   --filters.outlier.method="statistical"\ 
#   --filters.outlier.mean_k=8\ 
#   --filters.outlier.multiplier=3.0\ 
#   --filters.smrf.ignore="Classification[7:7]" \
#   --filters.range.limits="Classification[2:2]"\ 
#  --writers.las.compression=true --verbose 4