#!/bin/bash

DATASETS=(
    "dods://localhost:8080/thredds/dodsC/mur-test/MUR/2019_01_01_090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc"
)

# 256 KiB, 1 MiB, 16 Mib
BUFFERSIZES=(
  "262144" # 256 KiB
  #"1048576"
  #"16777216"
)

for BUFFERSIZE in "${BUFFERSIZES[@]}"
do
    for DATASET in "${DATASETS[@]}"
    do
        # Do not set bufferSize for local files
        if [[ "$var" =~ ^/.*  ]]
        then
            SYSPROPS=""
        else
            SYSPROPS="-Ducar.unidata.io.s3.bufferSize=${BUFFERSIZE}"
        fi
        
        CLASS="ucar.nc2.write.Ncdump"
        JAR="toolsUI-5.4.0-SNAPSHOT.jar"
        
        DATASET_SUMMARY="# Dataset: ${DATASET}"
        LEN=${#DATASET_SUMMARY}
        BANNER_MARKER="#"
        BANNER=""
        for (( c=1; c<=${LEN}; c++ ))
        do
            BANNER="${BANNER_MARKER}${BANNER}"
        done
        echo ${BANNER}
        echo $DATASET_SUMMARY
        echo "# Buffer Size: ${BUFFERSIZE} bytes"
        echo ${BANNER}
        echo ""
        echo ""
        
        echo "#"
        echo "# 1D Variable Single value"
        echo "#"
        time (java ${SYSPROPS} -cp ${JAR} ${CLASS} ${DATASET} -v "lon(0)") > /dev/null
        echo ""
        
        echo "#"
        echo "# 1D Variable Every 5th value"
        echo "#"
        time (java -cp toolsUI-5.4.0-SNAPSHOT.jar ucar.nc2.write.Ncdump ${DATASET} -v "lon(0:10:35999)") > /dev/null
        echo ""
        
        echo "#"
        echo "# 1D Variable Full read"
        echo "#"
        time (java -cp toolsUI-5.4.0-SNAPSHOT.jar ucar.nc2.write.Ncdump ${DATASET} -v "lon") > /dev/null
        echo ""
        
        echo "#"
        echo "# 3D Variable Single value"
        echo "#"
        time (java -cp toolsUI-5.4.0-SNAPSHOT.jar ucar.nc2.write.Ncdump ${DATASET} -v "analysed_sst(0,0,0)") > /dev/null
        echo ""
        
        echo "#"
        echo "# 3D Variable Outer slice"
        echo "#"
        time (java -cp toolsUI-5.4.0-SNAPSHOT.jar ucar.nc2.write.Ncdump ${DATASET} -v "analysed_sst(:,0,0)") > /dev/null
        echo ""
        
        echo "#"
        echo "# 3D Variable Inner slice"
        echo "#"
        time (java -cp toolsUI-5.4.0-SNAPSHOT.jar ucar.nc2.write.Ncdump ${DATASET} -v "analysed_sst(0,0,:)") > /dev/null
        echo ""
    done
done

