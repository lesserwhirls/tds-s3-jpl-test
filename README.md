# TDS and MUR on S3

This repository holds the docker and TDS configuration files related to the Unidata TDS instance in EC2 used to test accessing data stored in S3 directly.
In this case, we have two flavors of the Multiscale Ultrahigh Resolution (MUR) L4 daily analysis datasets:
  * [0.01 degree x 0.01 degree (~1 km)](https://podaac.jpl.nasa.gov/dataset/MUR-JPL-L4-GLOB-v4.1)
  * [0.25 degree x 0.25 degree](https://podaac.jpl.nasa.gov/dataset/MUR25-JPL-L4-GLOB-v04.2)

The testing period covers the entirety of 2018 and 2019 for both flavors of MUR.

## A note on object names

The Unidata S3 bucket is laid out in the following way.

Two top level prefixes:
  * `MUR/` (0.01 degree, a.k.a. 1 km)
  * `MUR25/` (0.25 degree)

Under the `MUR/` prefix, objects are named as follows:
  * *yyyy_MM_dd*_090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc

As an example, the full key to the MUR 1km analysis from 2019-02-13 would be `MUR/2018_02_13_090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc`

Similarly, Under the `MUR25/` prefix, objects are named as follows:
  * *yyyy_MM_dd*_090000-JPL-L4_GHRSST-SSTfnd-MUR25-GLOB-v02.0-fv04.2.nc

As an example, the full key to the MUR 0.25 degree analysis from 2019-02-13 would be `MUR25/2019_02_13_090000-JPL-L4_GHRSST-SSTfnd-MUR25-GLOB-v02.0-fv04.2.nc`.

These object names are a little different than the names of the files as obtained from JPL.
For example, the 2019-02-13 MUR 1km file from JPL is named `20190213090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc`
I chose to rename the objects based on how I see designing the TDS S3 `datasetScan` capibility.
I can see providing the `datasetScan` element a bucket, a prefix (e.g. `MUR/`) and a delimiter (`_` for my object names).
This will allow the user who browses the HTML catalogs the ability to "click through" by year, month, and date.
This will reduce the time needed by the TDS to generate a catalog at a given level, and will help keep the number of entries shown in any single catalog manageable (the maximum number of links you would see on any one html page would be 31, as opposed to all 1460 objects).

# What's in this repository
1) Two shell scripts to control `docker-compose`:

   * tds-start.sh (start the TDS)
   * tds-stop.sh (stop the TDS)

   Note that the underlying container is removed when the TDS is stopped.

2) `docker-compose` configuration

   The scripts above assume that the main configuration file used by docker-compose to setup the TDS container is named `docker-compose.yml`.
   `docker-compose.yml.example` is an example of what that looks like on the Unidata system.
   This example config refers to `compose.env`, which holds certain container configuration related environmental variables.
   `compose.env.example` is an example of what is used on the Unidata EC2 instance.
   The example config also refers to a few other files, namely:
     * `files/creds/aws_creds`
     * `files/creds/tomcat-users.xml`

   An example of what those files might look like can be found under `files/`.
   The root level `.gitignore` is setup to ignore anything under `files/creds/`, so it should be safe to place the files appropriate for your setup in that directory.
   Depending on how you are managing credentials, the `aws_creds` file may not be needed.

3) TDS configuration files
   
   The TDS configuration files live under `tds-configs/`.
   Perhaps the most critical at this point is the `mur-1km.xml` TDS Configuration Catalog.
   This is where we tell the TDS where to look for data, what services to expose, what metadata to add, etc.
   The critical elements related to S3 are the [`datasetRoot` element](https://github.com/lesserwhirls/tds-s3-jpl-test/blob/7b8eda967ba207dfab0c6aba88a9197cc351010f/tds-configs/mur-1km.xml#L12), and the next-to-last [dataset](https://github.com/lesserwhirls/tds-s3-jpl-test/blob/7b8eda967ba207dfab0c6aba88a9197cc351010f/tds-configs/mur-1km.xml#L79) element.
   The `datasetRoot` element essentially provides a top level alias to the S3 bucket (i.e. `mur-test` is associated with `cdms3://mur-bucket@aws/unidata-jpl-sandbox`).
   The `dataset` element then uses the `mur-test` datasetRoot name in combination with the key to the granule we with wish to serve (i.e. `MUR/2019_01_01_090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc`).

   The `mur-1km.xml` is also setup to serve a seven day NcML aggregation.
   Aggregation of S3 objects have some limitations in how they are configured.
   First, you will need to edit your `threddsConfig.xml` to [enable an experimental option](https://github.com/lesserwhirls/tds-s3-jpl-test/blob/d92bacfb17e8fdd3bfaebba7cc7546680292ba87/tds-configs/threddsConfig.xml#L77-L80), which tells the netCDF-Java library to use its new builder interface.
   Next, the aggregation needs to live in a seperate NcML file (i.e. the aggregation cannot be done in the catalog).
   In this case, the seven day aggregation lives at [tds-configs/ncml_files/mur-2019-01-01-seven-day-agg.ncml](https://github.com/lesserwhirls/tds-s3-jpl-test/blob/main/tds-configs/ncml_files/mur-2019-01-01-seven-day-agg.ncml).
   Finally, the NcML aggregation must be defined by listing the individual granules (i.e. there isn't an S3 version of `<datasetScan>` yet).

   These restrictions will be removed in future verions of the TDS, but for now, welcome to the bleeding edge of our S3 capibilities.

## A special note about `files/creds/aws_creds`

The Unidata version of `aws_creds` has a profile named `mur-bucket`, which has the credentials needed to do basic read and list object calls on the bucket.
When you look at the TDS configuration catalogs, you will see things like `cdms3://mur-bucket@aws/...` - the profile name is the `userinfo` sub-component of the `authority` component of the [cdms3 URI](https://docs.unidata.ucar.edu/netcdf-java/current/userguide/dataset_urls.html#object-stores).
