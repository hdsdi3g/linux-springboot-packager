#!/bin/bash
#    consts.bash - load all bash consts used to builds packages/setup files
#
#    Copyright (C) hdsdi3g for hd3g.tv 2022
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or any
#    later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program. If not, see <https://www.gnu.org/licenses/>.
#
#    Usage: just source consts.bash
#
#    shellcheck disable=SC2034

TEMPLATES_DIR="$PREFIX/usr/lib/linux-springboot-packager/templates";

MVN="mvn";
MAVEN_OPTS=(--batch-mode -Dagent=false -Dorg.slf4j.simpleLogger.defaultLogLevel=WARN -DskipTests -Dgpg.skip=true -Dmaven.javadoc.skip=true -Dmaven.source.skip=true -Dlicense.skipAddThirdParty=true)
NPM="npm";
NPM_OPTS=(install);
ARCH="noarch";
RPM_RELEASE=$(LANG="en_US.UTF-8" date '+%Y%m%d%H%M%S');
DEB_RELEASE=$(date +%s);
NOW=$(LANG="en_US.UTF-8" date);
DEB_CHANGELOG_DATE=$(LANG="en_US.UTF-8" date '+%a, %d %b %Y %H:%M:%S %z');
YEAR="$(date '+%Y')";
SHORT_DATE=$(LANG="en_US.UTF-8" date +"%m/%d/%Y");
JAVA="/usr/bin/java";
NOT_FOUND="NOT_FOUND";
RPM_WORKING_DIR_BASE_NAME="rpmbuild";
EXE_WORKING_DIR_BASE_NAME="exebuild";

POM_PROPS_KIND_TAG_NAME="linux-springboot-packager.kind";
POM_PROPS_KIND_CLI_VALUE="cli";
POM_PROPS_KIND_SERVICE_VALUE="service";
IS_CLI=false;

EXIT_CODE_MISSING_DEPENDENCY_COMMAND="1";
EXIT_CODE_MISSING_PROJECT="2";
EXIT_CODE_MISSING_PROJECT_DIR="3";
EXIT_CODE_MISSING_POM="4";
EXIT_CODE_MISSING_POM_ENTRY="5";
EXIT_CODE_CANT_FOUND_JAR_FILE_OUTPUT="6";
# EXIT_CODE_CANT_FOUND_SCRIPT_FILES 7
EXIT_CODE_CANT_FOUND_DEFAULT_CONF="8";
EXIT_CODE_CANT_FOUND_LOG_CONF="9";
EXIT_CODE_CANT_FOUND_RPM_FILE_OUTPUT="10";
EXIT_CODE_CANT_FOUND_APP_LOGGER="11";
EXIT_CODE_CANT_FOUND_DEST_DIR="12";
EXIT_CODE_CANT_FOUND_CLI_MAN="13";
