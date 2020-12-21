#!/bin/bash

# no trailing slash
BASE_URL="http://localhost:8080/thredds"

LOG_DIR="logs/"
ITERATIONS=1

SUBSET_VAR_1D="lon"
SUBSET_VAR_3D="analysed_sst"

# Some requests can become so large that the server will refuse it. In these
# cases, we limit the number of requests to a total of 10 times.
MAX_NUMBER_TIMES=10

# We stride in time for a few difference services. Define that in one spot.
TIME_STRIDE_VAL=10

# update_dataset_array
#   (no options)
# do not run directly - run as part of update_log_file_names
declare -A DATASETS
update_dataset_array () {
    # access_url, number of times, log file
    DATASETS[mur-test/MUR25/2019_01_01_090000-JPL-L4_GHRSST-SSTfnd-MUR25-GLOB-v02.0-fv04.2.nc]="1 ${SINGLE_GRANULE_LOG}"
    DATASETS[mur-test/MUR/2019_01_01_090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc]="1 ${SINGLE_GRANULE_LOG}"
    DATASETS[aggregations/mur25-2019-01-iam.ncml]="31 ${MONTH_AGG_FILE_LOG}"
    DATASETS[aggregations/mur-2019-01-iam.ncml]="31 ${MONTH_AGG_FILE_LOG}"
    DATASETS[scan-aggregation/mur25-2019-01.nc]="31 ${MONTH_AGG_LOG}"
    DATASETS[scan-aggregation/mur-2019-01.nc]="31 ${MONTH_AGG_LOG}"
    DATASETS[scan-aggregation/mur25-2019.nc]="365 ${YEAR_AGG_LOG}"
    DATASETS[scan-aggregation/mur-2019.nc]="365 ${YEAR_AGG_LOG}"
    DATASETS[scan-aggregation/mur25.nc]="730 ${ALL_AGG_LOG}"
    DATASETS[scan-aggregation/mur.nc]="730 ${ALL_AGG_LOG}"
    DATASETS[mur-test-local/MUR25/2019_01_01_090000-JPL-L4_GHRSST-SSTfnd-MUR25-GLOB-v02.0-fv04.2.nc]="1 ${SINGLE_GRANULE_LOCAL_LOG}"
    DATASETS[mur-test-local/MUR/2019_01_01_090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc]="1 ${SINGLE_GRANULE_LOCAL_LOG}"
    DATASETS[aggregations/mur25-2019-01-local.ncml]="31 ${MONTH_AGG_FILE_LOCAL_LOG}"
    DATASETS[aggregations/mur-2019-01-local.ncml]="31 ${MONTH_AGG_FILE_LOCAL_LOG}"
    DATASETS[local-scan-aggregation/mur25-2019-01.nc]="31 ${MONTH_AGG_LOCAL_LOG}"
    DATASETS[local-scan-aggregation/mur-2019-01.nc]="31 ${MONTH_AGG_LOCAL_LOG}"
}

# Make log dir if it does not exist
if [ ! -d "${LOG_DIR}" ]
then
    mkdir ${LOG_DIR}
fi

