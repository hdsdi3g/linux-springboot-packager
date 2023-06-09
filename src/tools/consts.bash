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

MVN="mvn";
MAVEN_OPTS=(--batch-mode -Dorg.slf4j.simpleLogger.defaultLogLevel=WARN -DskipTests -Dgpg.skip=true -Dmaven.javadoc.skip=true -Dmaven.source.skip=true)
NPM="npm";
NPM_OPTS=(install);
ARCH="noarch";
RELEASE=$(LANG="en_US.UTF-8" date '+%Y%m%d%H%M%S');
NOW=$(LANG="en_US.UTF-8" date);
SHORT_DATE=$(LANG="en_US.UTF-8" date +"%m/%d/%Y");
JAVA="/usr/bin/java";
RPM_WORKING_DIR="rpmbuild";
EXE_WORKING_DIR="exebuild";
NOT_FOUND="NOT_FOUND";

EXIT_CODE_MISSING_DEPENDENCY_COMMAND="1";
EXIT_CODE_MISSING_PROJECT="2";
EXIT_CODE_MISSING_PROJECT_DIR="3";
EXIT_CODE_MISSING_POM="4";
EXIT_CODE_MISSING_POM_ENTRY="5";
EXIT_CODE_CANT_FOUND_JAR_FILE_OUTPUT="6";
EXIT_CODE_CANT_FOUND_LIQUIBASE_FILE_OUTPUT="7";
EXIT_CODE_CANT_FOUND_DEFAULT_CONF="8";
EXIT_CODE_CANT_FOUND_LOG_CONF="9";
EXIT_CODE_CANT_FOUND_RPM_FILE_OUTPUT="10";
EXIT_CODE_CANT_FOUND_APP_LOGGER="11";
