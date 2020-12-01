#!/bin/bash

SINGLE_GRANULE_LOG="logs/single_granule_benchmark.log"

BASE_URL="http://localhost:8080/thredds/dodsC"

# access_url, time max index, lat max index, lon max index
declare -A DATASETS=(
[mur-test/MUR/2019_01_01_090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc]="0 17998 35999"
[mur-test/MUR25/2019_01_01_090000-JPL-L4_GHRSST-SSTfnd-MUR25-GLOB-v02.0-fv04.2.nc]="0 719 1439"
)

for DATASET in "${!DATASETS[@]}"
do
    BASE_COMMAND="curl -G -s -w \"${DATASET} start-transfer: %{time_starttransfer}, total-time: %{time_total}\n\" -o /dev/null ${BASE_URL}/${DATASET}.dods"
    declare -a DIMS=(${DATASETS[$DATASET]})
    echo "#"
    echo "# 1D Variable Single value"
    echo "#"
    eval "${BASE_COMMAND} --data-urlencode \"lon[0]\""
    # >> ${SINGLE_GRANULE_LOG}`
    echo ""
    
    echo "#"
    echo "# 1D Variable Every 100th value"
    echo "#"
    let STRIDE=${DIMS[2]}/100;
    eval "${BASE_COMMAND} --data-urlencode \"lon[0:${STRIDE}:${DIMS[1]}]\""
    echo "time: $TIME"
    echo ""
    
    echo "#"
    echo "# 1D Variable Full read"
    echo "#"
    eval "${BASE_COMMAND} --data-urlencode \"lon\""
    echo ""
    
    echo "#"
    echo "# 3D Variable Single value"
    echo "#"
    eval "${BASE_COMMAND} --data-urlencode \"analysed_sst[0,0,0]\""
    echo ""
    
    echo "#"
    echo "# 3D Variable Outermost slice"
    echo "#"
    eval "${BASE_COMMAND} --data-urlencode \"analysed_sst[:,0,0]\""
    echo ""
    
    echo "#"
    echo "# 3D Variable Innermost slice"
    echo "#"
    eval "${BASE_COMMAND} --data-urlencode \"analysed_sst[0,0,:]\""
    echo ""

    echo "#"
    echo "# 3D Variable Inner slice"
    echo "#"
    eval "${BASE_COMMAND} --data-urlencode \"analysed_sst[0,:,0]\""
    echo ""

done

