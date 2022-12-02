#!/bin/bash
# USAGE
# make-rpm <SpringBoot project path>
# With export SKIP_IMPORT_POM=1 for skip to compute full pom XML file if a temp version exists
# With export SKIP_BUILD=1 for skip maven build if the expected jar exists.
# With export SKIP_NPM=1 for skip npm builds.
# With export SKIP_CLEAN=1 for skip clean temp files/directories after build.
# With export SKIP_MAKE=1 for skip to make RPM file, just let ready to build.

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
check_rpmbuild;
check_rpmlint;
check_pandoc;
check_xmlstarlet;

project_load_base_dir $1;
make_front;
load_mvn_vars;
def_linux_base_dir_vars;
def_files_dir_vars;
prepare_rpm_build_dir;

make_jar;
make_liquibase_changelog;
extract_default_app_conf;
extract_information_files;
make_replace_list_vars;
extract_default_linux_log_conf;

make_man_page;
SPEC_FILE="$RPM_WORKING_DIR/SPECS/$ARTIFACTID.spec";

make_service_conf;

RPM_VERSION="${VERSION//-/.}";
{
    echo "# AUTOMATICALLY GENERATED THE "$(LANG="en_US.UTF-8" date);
    echo "%define _topdir      $(pwd)/$RPM_WORKING_DIR";
    echo "%define _arch       $ARCH";
    echo "BuildRoot:           %{buildroot}";
    echo "Summary:             $NAME: $SHORT_DESCRIPTION";
    echo "License:             $LICENCE";
    echo "Name:                $ARTIFACTID";
    echo "Version:             $RPM_VERSION";
    echo "Release:             $RELEASE";
    echo "BuildArch:           $ARCH";
    echo "Group:               System Environment/Daemons";
    echo "Vendor:              $ORG_NAME"
    echo "Requires:            bash man";
    echo "Requires(pre):       /usr/sbin/useradd";
    echo "Requires(pre):       /usr/bin/systemctl";
    echo "";
    echo "%description";
    echo "You will need Java version $JAVA_VERSION to run this software, and must be accessible from $JAVA."
    if [ -f "$FULL_CHANGELOG" ]; then
        echo "You should have a valid liquibase setup to run setup/upgrade scripts.";
    fi
    echo "Provided by $ORG_NAME ($ORG_URL), for more information, go to $URL, or contact $AUTHOR_NAME <$AUTHOR_EMAIL>.";
    echo "";

    ##########################################################################################
    ### INSTALL
    ##########################################################################################
    echo "%install";
    echo "mv * \$RPM_BUILD_ROOT/";
    echo "";

    ##########################################################################################
    ### FILES
    ##########################################################################################
    echo "%files";
    echo "%defattr(755,root,root)";

    # Man file
    echo "%doc %attr(0644,root,root) $OUTPUT_MAN_FILE";

    # Conf files
    echo "%dir $OUTPUT_DIR_CONF";
    echo "%config(noreplace) %attr(0600,$ARTIFACTID,$ARTIFACTID) $OUTPUT_APPCONF_FILE";
    echo "%config(noreplace) %attr(0600,$ARTIFACTID,$ARTIFACTID) $OUTPUT_LOGCONF_FILE";
    echo "%config(noreplace) %attr(0755,root,root) $OUTPUT_ENV_FILE";

    echo "%dir $OUTPUT_DIR_APP" | sed_usr_lib;

    # Service file
    echo "%config(noreplace) %attr(0644,root,root) $OUTPUT_SERVICE_FILE" | sed_usr_lib;

    # App files
    echo "%attr(0644,root,root) $OUTPUT_JAR_FILE" | sed_usr_lib;
    if [ -f "$FULL_CHANGELOG" ]; then
        echo "%attr(0644,root,root) $OUTPUT_LIQUIBASEXML_FILE" | sed_usr_lib;
        echo "%attr(0744,root,root) $OUTPUT_LIQUIBASESCRIPTCREDS_FILE" | sed_usr_lib;
    fi

    # Information files
    if [ -f "$BASE_DIR/LICENCE" ] || [ -f "$BASE_DIR/LICENCE.TXT" ] || [ -f "$BASE_DIR/LICENCE.txt" ]; then
        echo "%attr(0644,root,root) $OUTPUT_LICENCE_FILE" | sed_usr_lib;
    fi
    if [ -f "$BASE_DIR/THIRD-PARTY.txt" ]; then
        echo "%attr(0644,root,root) $OUTPUT_THIRDPARTY_FILE" | sed_usr_lib;
    fi

    echo "%dir %attr(0700,$ARTIFACTID,$ARTIFACTID) $OUTPUT_DIR_LOG";
    echo "";

    ##########################################################################################
    ### PRE INSTALL
    ##########################################################################################
    echo "%pre -p /usr/bin/bash";
    # install $1 == 1
    # upgrade (new) $1 == 2
    sed -e "$REPLACE/^[ \t]*#/d;/^$/d" < src/stop-service.inc.sh
    sed -e "$REPLACE/^[ \t]*#/d;/^$/d" < src/create-user.inc.sh
    echo "exit 0;";
    echo "";

    ##########################################################################################
    ### POST INSTALL
    ##########################################################################################
    echo "%post -p /usr/bin/bash";
    # install $1 == 1
    # upgrade (new) $1 == 2
    echo "[ \$1 = "1" ] && echo \"Enable service $ARTIFACTID with systemctl, but don't start it.\"";
    echo "[ \$1 = "1" ] && ln -s $OUTPUT_SERVICE_FILE $OUTPUT_SERVICE_LINK" | sed_usr_lib;
    echo "[ \$1 = "1" ] && systemctl daemon-reload";
    echo "[ \$1 = "1" ] && systemctl enable $ARTIFACTID";
    echo "mandb -q";
    echo "echo \"Use man $ARTIFACTID to get setup informations.\"";
    if [ -f "$FULL_CHANGELOG" ]; then
        sed -e "$REPLACE/^[ \t]*#/d;/^$/d" < run-liquibase.inc.sh
    fi
    echo "exit 0;";
    echo "";

    ##########################################################################################
    ### PRE UNINSTALL
    ##########################################################################################
    echo "%preun -p /usr/bin/bash";
    # upgrade (old) $1 == 1
    # remove $1 == 0
    sed -e "$REPLACE/^[ \t]*#/d;/^$/d" < src/stop-service.inc.sh
    sed -e "$REPLACE/^[ \t]*#/d;/^$/d" < src/disable-service.inc.sh
    echo "exit 0;";
    echo "";

    ##########################################################################################
    ### POST UNINSTALL
    ##########################################################################################
    echo "%postun -p /usr/bin/bash";
    # upgrade (old) $1 == 1
    # remove $1 == 0
    echo "mandb -q";
    echo "[ \$1 -eq "0" ] && echo \"To clean-up this setup, you should remove $OUTPUT_DIR_CONF, $OUTPUT_DIR_USER, $OUTPUT_DIR_LOG\"." | sed_usr_lib;
    echo "[ \$1 -eq "0" ] && echo \"And you can delete user and group $ARTIFACTID\".";
    echo "exit 0;";
    echo "";
} > "$SPEC_FILE"

if [ "${SKIP_MAKE:-"0"}" = "0" ]; then
    rpmlint "$SPEC_FILE"
    # BUILD BIN ONLY
    rpmbuild --define "_libdir /usr/lib" -bb "$SPEC_FILE"

    RPM_FILE="$RPM_WORKING_DIR/RPMS/$ARCH/$ARTIFACTID-$RPM_VERSION-$RELEASE.$ARCH.rpm";
    if [ ! -f "$RPM_FILE" ]; then
        echo "Can't found rpm file, expect: $RPM_FILE" >&2;
        exit $EXIT_CODE_CANT_FOUND_RPM_FILE_OUTPUT;
    fi
    OUT_RPM_FILE="$ARTIFACTID-$VERSION.rpm";
    mv "$RPM_FILE" "$OUT_RPM_FILE";

    clean_after_build "$RPM_WORKING_DIR";

    echo "";
    echo "About this packet:"
    rpm -qi "$OUT_RPM_FILE"
    echo "";
    echo "Now, you can use $OUT_RPM_FILE, with sudo rpm -U $OUT_RPM_FILE"
else
    echo "You will found the spec file to $SPEC_FILE";
    echo "Free feel to edit it, and build with:";
    echo "   rpmbuild --define \"_libdir /usr/lib\" -bb \"$SPEC_FILE\"";
fi
