#!/bin/bash

mkdir -p /data/logs

# Check if database file exists, if so try a rundown incase it was borked by container stopping
if [ -f "$ydb_dir/$ydb_rel/g/yottadb.gld" ]; then
  echo "Running rundown to restore database."
  export ydb_gbldir="$ydb_dir/$ydb_rel/g/yottadb.gld"
  /opt/yottadb/current/mupip rundown -region DEFAULT
fi

# Check if env vars need setting (not ideal, but better than checking every one
if [ -z "${ydb_dist}" ]; then
  echo "ydb_dist not set. Setting variables."
  . /opt/yottadb/current/ydb_env_set
else
  echo "ydb_dist already set. Not setting variables again."
fi

# Check if ASSIGN needs pulling
if [ ! -d "$assign_dest" ]; then
  echo "Obtaining ASSIGN routines."

  # Clone the wanted sha from github
    if [ -z "${assign_sha}" ]; then
      git clone $assign_url $assign_dest --depth 1
    else
      git clone $assign_url $assign_dest --depth 1 --branch $assign_sha
    fi

  # Put the routines to the YottaDB routines directory
  echo "Moving the routines."
  cp $assign_dest/UPRN/yottadb/* $ydb_dir/$ydb_rel/r
  cp $assign_dest/UPRN/codelists/* $abp_dir
else
  echo "$assign_dest already exists. Not cloning down ASSIGN again."
fi

# Perform zlink of routines, doesn't matter if already linked
echo "Linking ASSIGN routines, you may see warnings."
$ydb_dist/ydb -run ^ZLINK
echo "Routines linked."

# Update YottaDB database settings
$ydb_dist/mupip set -NULL_SUBSCRIPTS=true -region DEFAULT && \
$ydb_dist/mupip set -extension_count=500000 -region DEFAULT && \
$ydb_dist/mupip set -journal=off -region DEFAULT #&& \
#$ydb_dist/mupip set -access_method=mm -region DEFAULT

# Do data ingest, look at checksum for "$ydb_dir/$ydb_rel/g/yottadb.gld"
export checksum_loc=/data/import_checksum
if [ ! -f "/data/import_checksum" ]; then
  echo "Ingesting ABP from $abp_dir"
  $ydb_dist/ydb -run %XCMD 'd IMPORT^UPRN1A("/data/ABP")'
  echo "Producing checksum for $ydb_gbldir"
  sha256sum $ydb_gbldir | awk '{ print $1 }' > $checksum_loc
  cat /data/import_checksum
else
  echo "Get checksums"
  prev_checksum=$(cat $checksum_loc)
  cur_checksum=$(shasum -a 256 $ydb_gbldir | awk '{ print $1 }')
  echo "Previous checksum: $prev_checksum"
  echo "Current checksum: $cur_checksum"
  if [[ $prev_checksum != $cur_checksum ]]; then
    echo "Reproducing checksum for $ydb_gbldir"
    sha256sum $ydb_gbldir | awk '{ print $1 }' > $checksum_loc
  fi
fi

# Set the ybd env var for the TLS password hash, this can be replaced with an ENV var in the image?
#export ydb_tls_passwd_dev="$($ydb_dist/plugin/ydbcrypt/maskpass <<< $cert_pass | cut -d ":" -f2 | tr -d ' ')"

# Startup the ASSIGN TLS listener
echo "Starting listener"
yottadb -run %XCMD 'job START^VPRJREQ(9081)' &

# Startup the ASSIGN web API interface
echo "Starting ASSIGN API endpoints"
cp "/extra_scripts/ADDWEBAUTH.m" "$ydb_dir/$ydb_rel/r/ADDWEBAUTH.m"
yottadb -run INT^VUE          # File upload/download
yottadb -run SETUP^UPRNHOOK2  # UPRN retrieval
yottadb -run ^NEL             # request handling
yottadb -run ^ADDWEBAUTH      # Add creds

# Startup webgui
echo "Starting YottaDB GUI endpoint"
yottadb -run %ydbgui --readwrite --port 9080 >>/data/logs/%ydbgui.log
