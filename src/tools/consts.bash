#!/bin/bash

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
