% make-springboot-rpm(1) linux-springboot-packager documentation
% linux-springboot-packager

# NAME
make-springboot-rpm - make a RPM package from a Spring Boot application as a system service, or a CLI application.

# SYNOPSIS
make-springboot-rpm *&lt;PROJECT&gt;* *[&lt;TARGET&gt;]*

# DESCRIPTION
With the help of Maven, this app will compile the application jar, create man page, create and prepare SystemD service file with adduser scripts (not for CLI), prepare an configuration file sample (not for CLI), deploy a bash runner (only for CLI), in an autonomous RPM file.

It don't manage a RPM repository either a signature.

# OPTIONS
**PROJECT**

The Spring Boot source project root directory, which contain *pom.xml* file.

**TARGET**

Optionnaly, where to put the created *RPM* file. By default in the current directory.

# ENVIRONMENT
For test purposes, you can bypass some action with environment variables:

**SKIP_IMPORT_POM=1** for *skip* to compute full pom XML file if a temp version exists

**SKIP_BUILD=1** for *skip* maven build if the expected jar exists.

**SKIP_NPM=1** for *skip* npm builds.

**SKIP_CLEAN=1** for *skip* clean temp files/directories after build.

**SKIP_MAKE=1** for *skip* to make RPM file, just let ready to build.

**PREFIX=/somewhere** to *chroot* the app files search

# OPTIONS AND PREREQUISITES
The builded project must be managed by `Maven`

To run this app, you will **need** *java*, *maven*, *mktemp*, *realpath*, *basename*, *rpmbuild*, *rpmlint*, *pandoc*, *xmlstarlet* and *bash*.

It needs the Spring Boot maven plugin (you should use starter parent project).

With `log4j2` or `logback`, it will provided ready-to-use `log4j2.xml` or `logback.xml` configuration file (see below).

Your **pom.xml** file, or its ancestors (via `help:effective-pom`), *MUST* define this parameters to provide some informations to put in scripts, installers, and autogenerated man file:

 - `project/version`
 - `project/artifactId`
 - `project/name`
 - `project/description`
 - `project/url`
 - `project/organization/name`
 - `project/organization/url`
 - `project/licenses/license/name`
 - `project/developers/developer/name`
 - `project/developers/developer/email`
 - `project/issueManagement/system`
 - `project/issueManagement/url`

And should strongly define:

 - `project/properties/java.version`
 - `project/packaging`

Switch CLI mode with:

 - `project/properties/linux-springboot-packager.kind` set on `cli`

On CLI mode, you must provide an **man** file in the project directory.

Optionally with npm, if your project have a `package.json` file on main dir. It will only run `npm install` before start maven package, only if a `package.json` is founded on the main project directory. On builded project side, **npm install** *should* run an **webpack** for a **production ready version front app** (minified, etc), and *should* put finals files on *src/main/resources/static*. Maven and Spring Boot will collects these files during back building. No checks will be done on this project

Optionally, your project should have a **LICENCE(|.txt|.TXT)** file on its root path.

Optionally, you project can have a `THIRD-PARTY.txt` file, autogenerated by *org.codehaus.mojo/license-maven-plugin*.

Setup build can detect the current application logger, and manage the good xml file template. The detection is based on project `pom.xml` (precisely `effective-pom`) dependencies, as:

 - `<groupId>ch.qos.logback</groupId>`, `<artifactId>logback-classic</artifactId>` and `<scope>compile</scope>` for Logback.
 - `<groupId>org.apache.logging.log4j</groupId>`, `<artifactId>log4j-api</artifactId>` and `<scope>compile</scope>` for Log4j.

If the both are found, logback will be choosed.

# FILES
**src/usr/lib/linux-springboot-packager/include**

Bash files included and used to build the RPM file, and do all the internal operations.

The **consts.bash** script setup some vars and declare the base choices.

In the **project.bash** contain *def_files_dir_vars()* function: you will see all directories and file names used to build scripts.

**src/usr/lib/linux-springboot-packager/templates**

All used file which can be included and/or adapted in the creation of the package.

# EXIT CODES
| Error name                                 | Exit code |
| ------------------------------------------ | --------- |
| EXIT_CODE_MISSING_DEPENDENCY_COMMAND       | 1         |
| EXIT_CODE_MISSING_PROJECT                  | 2         |
| EXIT_CODE_MISSING_PROJECT_DIR              | 3         |
| EXIT_CODE_MISSING_POM                      | 4         |
| EXIT_CODE_MISSING_POM_ENTRY                | 5         |
| EXIT_CODE_CANT_FOUND_JAR_FILE_OUTPUT       | 6         |
| EXIT_CODE_CANT_FOUND_SCRIPT_FILES          | 7         |
| EXIT_CODE_CANT_FOUND_DEFAULT_CONF          | 8         |
| EXIT_CODE_CANT_FOUND_LOG_CONF              | 9         |
| EXIT_CODE_CANT_FOUND_RPM_FILE_OUTPUT       | 10        |
| EXIT_CODE_CANT_FOUND_APP_LOGGER            | 11        |
| EXIT_CODE_CANT_FOUND_DEST_DIR              | 12        |

# BUGS
Free feel to send issues to https://github.com/hdsdi3g/linux-springboot-packager/issues.

But never forget there are an infinite number of possible ways to create this type of package and I am fully aware that not all options and all scenarios are managed.

# AUTHORS
This application was writted by **hdsdi3g**; see on GitHub https://github.com/hdsdi3g/linux-springboot-packager.

# SEE ALSO
**make-springboot-deb(1)**, **make-springboot-exe(1)** and **search-winsw.bash(1)**.

# NOTES
This document was transformed by *pandoc* from the original markdown documentation file.

# COPYRIGHT
Copyright (C) hdsdi3g for hd3g.tv 2022-2023, under the **GNU General Public License v3+**
