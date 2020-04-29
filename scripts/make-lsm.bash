#!/bin/bash

set -eu

MVN_VARS="$1";
LSM_FILE="$2";

if [ -f "$LSM_FILE" ]; then
    rm "$LSM_FILE"
fi

. "$MVN_VARS"

echo "Begin3"                                                       >> $LSM_FILE
echo "Title:          $MVN_VAR_name"                                >> $LSM_FILE
echo "Version:        $MVN_VAR_version"                             >> $LSM_FILE
echo "Description:    $MVN_VAR_description"                         >> $LSM_FILE
echo "Keywords:       $MVN_VAR_organization_name"                   >> $LSM_FILE
echo "Author:         $MVN_VAR_author_name ($MVN_VAR_author_email)" >> $LSM_FILE
echo "Maintained-by:  $MVN_VAR_author_name ($MVN_VAR_author_email)" >> $LSM_FILE
echo "Original-site:  $MVN_VAR_organization_url"                    >> $LSM_FILE
echo "Platform:       Linux 64 bits kernel with SystemD"            >> $LSM_FILE
echo "Copying-policy: $MVN_VAR_license"                             >> $LSM_FILE
echo "End"                                                          >> $LSM_FILE
