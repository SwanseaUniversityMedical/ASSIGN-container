#!/bin/bash

mkdir -p /data/logs

#set env vars
. /opt/yottadb/current/ydb_env_set

#get ASSIGN
git clone $assign_url $assign_dest
git -C $assign_dest checkout $sha
cp $assign_dest/UPRN/yottadb/* $ydb_dir/$ydb_rel/r
mkdir $abp_dir
cp $assign_dest/UPRN/codelists/* $abp_dir

#perform zlink of routines
$ydb_dist/ydb -run ^ZLINK

# extend database to hold ABP
$ydb_dist/mupip set -NULL_SUBSCRIPTS=true -region DEFAULT && \
$ydb_dist/mupip set -journal=off -region DEFAULT && \
$ydb_dist/mupip set -extension_count=500000 -region DEFAULT && \
$ydb_dist/mupip set -access_method=mm -region DEFAULT

#startup webgui
yottadb -run %ydbgui --read --port 9080 >>/data/logs/%ydbgui.log &

#drop in to ydb
exec $ydb_dist/yottadb -direct
