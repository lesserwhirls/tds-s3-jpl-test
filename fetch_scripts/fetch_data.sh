#!/bin/bash

# MUR -> ~400 MiB per day (~12.5 GiB per month, ~143 GiB per year)
# MUR25 -> ~2 MiB per day (~61 MiB per month, ~730 MiB per year)

BASE_URL="https://podaac-opendap.jpl.nasa.gov/opendap/allData/ghrsst/data/GDS2/L4/GLOB/JPL"
YEAR="2019"
MONTH="01"

for DAY in $(seq 1 31)
do
  DAY2=`printf "%02d" ${DAY}`
  DAY3=`printf "%03d" ${DAY}`
  MUR_URL=${BASE_URL}/MUR/v4.1/${YEAR}/${DAY3}/${YEAR}${MONTH}${DAY2}090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc
  MUR25_URL=${BASE_URL}/MUR25/v4.2/${YEAR}/${DAY3}/${YEAR}${MONTH}${DAY2}090000-JPL-L4_GHRSST-SSTfnd-MUR25-GLOB-v02.0-fv04.2.nc

  wget -P MUR ${MUR_URL}
  wget -P MUR25 ${MUR25_URL}
done

