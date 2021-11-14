# SpringBoot Linux Packager

Create self Linux installer (via [Makeself](https://makeself.io/)) and create Windows installer (via [NSIS](https://sourceforge.net/projects/nsis/) and [WinSW](https://github.com/winsw/winsw)) for a SpringBoot project.

SpringBoot options:

- Managed by Maven
- With or without persistence (not for Windows)
  - If persistence, it will use _Liquibase_ with [``setupdb-maven-plugin``](https://github.com/hdsdi3g/setupdb-maven-plugin) on Maven project
- log4j2 by default

_This project can be related to the [linux-app-packager](https://github.com/hdsdi3g/linux-app-packager) project (for the Linux package side)._

## Requires

### For build, you'll need:

- Linux, Windows WSL (but not _Cygwin_ bash based like _Git Bash_)
- curl for get _Makeself_ scripts
- Java 11+
- Maven
  - bash / GNU tar / GNU find
- a SpringBoot project with the _SpringBoot maven plugin_
- [NSIS 3+ version](https://sourceforge.net/projects/nsis/), or via `apt-get install nsis`, only for build Windows executables installers.
- [WinSW 2+](https://github.com/winsw/winsw/releases), only for handled Windows services. Executable must be put on `scripts` directory.

Not tested on macOS.

### For run the builded installer, you'll need:

- Linux (Debian/Rhel Like) and WSL with
  - systemD
  - bash / GNU tar / GNU find
  - ``root`` rights for full setup
  - coreutils
  - shadow-utils (useradd)
  - diffutils (cmp)
  - Java 11+
  - Liquibase (if the project needs automatic persistence deployment).
- Windows 10 (11 not tested)
  - Requirements for WinSW, if needed
  - Admin rights
  - Java 11+

You can use [``linux-app-packager``](https://github.com/hdsdi3g/linux-app-packager) for build off-line specific installers for Java and Liquibase, only on Linux.

## Script usage

    ./make-package.bash <SpringBoot project path>

Create a new installer in current ``package`` output directory.

If you set `export SKIP_BUILD=1`, it will skip Maven build if the expected jar exists in target directory.

If you set `export SKIP_LINUX=1`, it will skip Linux build.

If WinSW *and* NSIS is setup/founded, a Windows installer will be produced.

The default Maven run will skip tests, GPG sign, jar javadoc and source packaging.

On the first packaging, it will use a sub-directory in ``package`` for keep temp files and static files, like systemD manifests.

All this static files are copied from ``template`` directory. Free feel to edit templates for all future projects, or edit the current project files in ``package``sub-directory.

The final setup script is copied from ``scripts`` directory and will be included on package during the building (Linux only).

The base name used by the package and the setup scripts is the Maven POM ``project.artifactId`` and the ``project.name``.

    ./clean-all.bash
  
Delete ``package`` output directory.

    ./extract-all.bash

Extract all builded packages founded in ``package`` on ``packages/_export`` sub directory.

    ./test-all.bash

Extract and run locally all builded packages founded in ``package`` on ``packages/_export`` sub directory: you will checks the extract file deployment without run any setups command.

## Builded package usage

### Linux setup

The package is builded by a standard [Makeself](https://makeself.io/), and will respond normally like a Makeself package.

By default, as root:

    ./myspringbootproject-1.2.3-run.sh

If Liquibase via [setupdb-maven-plugin](https://github.com/hdsdi3g/setupdb-maven-plugin) manage the database upgrades, it will be used for upgrade the current environment, after ask you the database credentials and access configuration.

Usage for a simple autoextract test/check (no needs to be root):

    ./myspringbootproject-1.2.3-run.sh --keep --target "extracted" -- -norun

Usage for deploy to another root directory:

    ./myspringbootproject-1.2.3-run.sh -- -chroot "/opt"

For update, just start the new builded package, it will detect and replace all needed files (and keep the actual log4j2 and application.yml configuration).

### Windows setup

Just run setup files with admin rights. If you use WinSW with a _.NET_ dependency, you should install it before.

Actually, Liquibase is not managed.

Executable files, and uninstaller will be placed on `C:\Program Files\<project name>`, and "variable files" like log and application.yml in `C:\ProgramData\<project name>`.

This can be changed with `windows-paths.inc.sh` (to edit before run build).

An uninstall script, and an entry in "Add/Remove programs" is setup.

Setup script are crafted to be simply "over installed": the next setup will uninstall the previous one (with a service stop and remove), but keep actual "variable files".

## After setup

### Linux run

You can run manually with like:

    runuser -u SERVICE_USER_NAME -- java -Dlogging.config=/etc/SERVICE_NAME/log4j2.xml -jar /usr/lib/SERVICE_NAME/springboot.jar --spring.config.location=/etc/SERVICE_NAME/application.yml

Replate ``SERVICE_USER_NAME`` and ``SERVICE_NAME`` by the Maven project artifactId.

You can use SystemD scripts for register service with:

    /usr/bin/SERVICE_NAME-enable

And start it with:

    /usr/bin/SERVICE_NAME-start

Use for manage the service life:

    /usr/bin/SERVICE_NAME-stop
    /usr/bin/SERVICE_NAME-disable
    /usr/bin/SERVICE_NAME-status

### Windows run

By default, the service run will need a valid `application.yml` and `log4j2.xml`. Samples/examples are provided.

After the setup, with the help of WinSW, a Windows service in declared, but not started and set to Manual.

Free feel to edit `servicewinsw.xml` before build the setup, or edit the production file `winsw.xml`. Please to refer to WinSW documentation.

Don't forget to setup a compatible JVM, and put java.exe directory in PATH.

## Roadmap dev

Like for the [linux-app-packager](https://github.com/hdsdi3g/linux-app-packager) project, free feel to add corrections and/or new features (it's really not rocket science).

Actually, there are no "uninstall script" provided for Linux. This is something that could be done if needed.
