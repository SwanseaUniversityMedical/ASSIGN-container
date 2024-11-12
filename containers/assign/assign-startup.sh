#!/bin/bash
#################################################################
#                                                               #
# Copyright (c) 2024 YottaDB LLC and/or its subsidiaries.  #
# All rights reserved.                                          #
#                                                               #
#       This source code contains the intellectual property     #
#       of its copyright holder(s), and is made available       #
#       under a license.  If you do not know the terms of       #
#       the license, please stop and do not read further.       #
#                                                               #
#################################################################
mkdir -p /data/logs

#set env vars
. /opt/yottadb/current/ydb_env_set

#get ASSIGN
read -p "Enter ASSIGN git repo url (https://github.com/endeavourhealth-discovery/ASSIGN.git):" assign_url
assign_url=${assign_url:-"https://github.com/endeavourhealth-discovery/ASSIGN.git"}
read -p "Enter ASSIGN install path (./ASSIGN):" assign_dest
assign_dest=${assign_dest:-"./ASSIGN"}
read -p "Enter ASSIGN commit sha ( ):" sha
sha=${sha:-""}
assign_url="https://github.com/endeavourhealth-discovery/ASSIGN.git"
assign_dest="./ASSIGN"
sha=""
git clone $assign_url $assign_dest
git -C $assign_dest checkout $sha
cp $assign_dest/UPRN/yottadb/* $ydb_dir/$ydb_rel/r
mkdir ./ABP
cp $assign_dest/UPRN/codelists/* /data/ABP

#perform zlink of routines
$ydb_dist/ydb -run ^ZLINK

# extend database to hold ABP
$ydb_dist/mupip set -NULL_SUBSCRIPTS=true -region DEFAULT && \
$ydb_dist/mupip set -journal=off -region DEFAULT && \
$ydb_dist/mupip set -extension_count=500000 -region DEFAULT && \
$ydb_dist/mupip set -access_method=mm -region DEFAULT
$ydb_dist/mupip extend DEFAULT -blocks=17000000

#startup webgui
yottadb -run %ydbgui --readwrite --port 9080 >>/data/logs/%ydbgui.log &

#load in ABP straight away, we don't do this at the moment as it takes a long time and still has issues with encoding on codelist files.
#$ydb_dist/ydb -run %XCMD 'd IMPORT^UPRN1A("/data/ABP")'

#drop in to ydb
exec $ydb_dist/yottadb -direct
