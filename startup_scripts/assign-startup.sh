#!/bin/bash

mkdir -p /data/logs

# Set env vars
. /opt/yottadb/current/ydb_env_set

# Get ASSIGN
if [ ! -d "$assign_dest" ]; then
  echo "Obtaining ASSIGN routines."
  # Clone the wanted sha from github
  git clone $assign_url $assign_dest
  git -C $assign_dest checkout $assign_sha

  # Put the routines to the YottaDB routines directory
  echo "Moving the routines."
  cp $assign_dest/UPRN/yottadb/* $ydb_dir/$ydb_rel/r
  cp $assign_dest/UPRN/codelists/* $abp_dir

  # Perform zlink of routines
  echo "Linking ASSIGN routines."
  $ydb_dist/ydb -run ^ZLINK
else
  echo "$assign_dest already exists. Not cloning down ASSIGN again."
fi

# Update YottaDB database settings
$ydb_dist/mupip set -NULL_SUBSCRIPTS=true -region DEFAULT && \
$ydb_dist/mupip set -journal=off -region DEFAULT && \
$ydb_dist/mupip set -extension_count=500000 -region DEFAULT && \
$ydb_dist/mupip set -access_method=mm -region DEFAULT

# Startup webgui
yottadb -run %ydbgui --read --port 9080 >>/data/logs/%ydbgui.log &

# Drop in to ydb
exec $ydb_dist/yottadb -direct
