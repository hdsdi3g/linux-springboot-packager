#!/bin/bash
# USAGE
# make-exe <SpringBoot project path>
# With export SKIP_IMPORT_POM=1 for skip to compute full pom XML file if a temp version exists
# With export SKIP_BUILD=1 for skip maven build if the expected jar exists.
# With export SKIP_NPM=1 for skip npm builds.
# With export SKIP_CLEAN=1 for skip clean temp files/directories after build.
# With export SKIP_MAKE=1 for skip to make EXE file, just let ready to build.

set -eu

cd "$(dirname "$0")"

# LOAD BUILD DEPS
. src/tools/consts.bash
. src/tools/checktools.bash
. src/tools/project.bash

# CHECK PARAM PRESENCE
if [ "$#" -eq 0 ]; then
    echo "Usage $0 <SpringBoot project path>" >&2;
    echo "The SpringBoot project path must be a Maven project (with pom.xml on root)" >&2;
    exit $EXIT_CODE_MISSING_PROJECT;
fi

# CHECK TOOL PRESENCE
check_maven;
check_realpath;
check_basename;
check_makensis;
check_pandoc;
check_xmlstarlet;

project_load_base_dir $1;
make_front;
load_mvn_vars;
def_windows_base_dir_vars;
def_files_dir_vars;
prepare_exe_build_dir;
make_jar;
FULL_CHANGELOG="";

extract_default_app_conf;
sed -i $'s/$/\r/' "$BUILD_DIR/$OUTPUT_APPCONF_FILE";

extract_information_files;
if [ -f "$BUILD_DIR/$OUTPUT_LICENCE_FILE" ]; then
    sed -i $'s/$/\r/' "$BUILD_DIR/$OUTPUT_LICENCE_FILE";
fi
if [ -f "$BUILD_DIR/$OUTPUT_THIRDPARTY_FILE" ]; then
    sed -i $'s/$/\r/' "$BUILD_DIR/$OUTPUT_THIRDPARTY_FILE";
fi

make_replace_list_vars;
extract_default_windows_log_conf;
# make_html_doc_page; only for linux systemd...
make_winsw_conf;
make_nsi_conf "$(bash src/tools/search-winsw.bash)";

if [ "${SKIP_MAKE:-"0"}" = "0" ]; then
    OUT_EXE_FILE="$ARTIFACTID-v$VERSION-setup.exe";
    if [ -f "$OUT_EXE_FILE" ]; then
        rm -f "$OUT_EXE_FILE";
    fi
    
    makensis \
        -DBUILD_DIR="$BUILD_DIR" \
        -DOUTPUT_DIR_APP="$OUTPUT_DIR_APP" \
        -DOUTPUT_DIR_USER="$OUTPUT_DIR_USER" \
        -INPUTCHARSET UTF8 -WX \
        "$BUILD_DIR/$OUTPUT_NSI_FILE"
    clean_after_build "$EXE_WORKING_DIR";

    if [ ! -f "$OUT_EXE_FILE" ]; then
        echo "Can't found rpm file, expect: $OUT_EXE_FILE" >&2;
        exit $EXIT_CODE_CANT_FOUND_RPM_FILE_OUTPUT;
    fi

    echo "";
    echo "Now, you can use $OUT_EXE_FILE on a Windows host."
else
    echo "You will found the nsi file to $BUILD_DIR/$OUTPUT_NSI_FILE";
    echo "Free feel to edit it, and build with makensis.";
fi
