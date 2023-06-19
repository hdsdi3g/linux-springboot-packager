# Spring Boot Linux Packager

This script collection will create:
 - a [RPM package](man-make-springboot-rpm.md)
 - a [Windows self installer](man-make-springboot-exe.md) (via [NSIS](https://sourceforge.net/projects/nsis/) and [WinSW](https://github.com/winsw/winsw))
 - a [RPM file to install this scripts collection](#how-to-make-a-rpm-installer-for-this-app)

For a **Spring Boot** project, runned as service, and build npm/front during packaging.

Via _bash_, on Linux (RHEL/Debian) and Windows/WSL, not tested on macOS.

**See the md/man files on the project root for more informations.**

[![Tests on Ubuntu](https://github.com/hdsdi3g/linux-springboot-packager/actions/workflows/tests-ubuntu.yml/badge.svg)](https://github.com/hdsdi3g/linux-springboot-packager/actions/workflows/tests-ubuntu.yml)

## make-springboot-rpm

For build RPMs files, you will need, in addition to `maven` and `java`:
 - `realpath`
 - `basename`
 - `rpmbuild`
 - `rpmlint`
 - `pandoc`
 - `xmlstarlet`
 - `mktemp`
 - and optionnaly `npm`

### Install the RPM files

The builded RPM will run some install/uninstall scripts and do a few things, apart from that, it's a classic, non-signed RPM file.

The setup script check the presence of `bash`, `man`, `useradd`, and `systemctl`, and will deploy:
 - A man file ([template here](src/usr/lib/linux-springboot-packager/templates/template-man.md)), as `man artifactId`
 - some example files:
   - An configuration file (`application.yml`)
   - An configuration log file (`log4j2.xml` or `logback.xml`)
   - An default file
 - The application `jar` file
 - A `Systemd` service file, deployed, ready to run
 - THIRD-PARTY and LICENCE files if available.
 - The Liquibase upgrade file and deploy script, if needed.
 - An user/group and home dir for this user, as service name, to run the created service.
 - A log directory ready to get log files

All templates are in the `src/usr/lib/linux-springboot-packager/templates` directory.

Java presence will _not be_ checked by the installer. The default service file will expect to found it in `/usr/bin/java`. Change it as you what after setup.

Before deploy files, the service will be stopped (if exists and if running). After deploy files, it will be enabled, at boot, but not started.

Run the setup with:

```bash
# Install / upgrade
sudo rpm -U <artifactid-version.rpm>

# Remove
sudo rpm -e <artifactid>

# Remove "all"
sudo rpm -e --allmatches <artifactid>
```

You can run manually with like:

```bash
runuser -u <SERVICE_NAME> \
  -- java -Dlogging.config=/etc/<SERVICE_NAME>/log4j2.xml|logback.xml \
  -jar /usr/lib/<SERVICE_NAME>/<artifactId>-bin.jar \
  --spring.config.location=/etc/<SERVICE_NAME>/application.yml
```

## make-springboot-exe

Executable files, and uninstaller will be placed on `C:\Program Files\<project name>`, and "variable files" like log and application.yml in `C:\ProgramData\<project name>`.

An uninstall script add an entry in "Add/Remove programs" is setup.

Setup script are crafted to be simply "over installed": the next setup will uninstall the previous one (with a service stop and remove), but keep the actual "variable files".

By default, the service run will need a valid `application.yml` and `log4j2.xml`. Samples/examples are provided.

Actually, Liquibase is not managed, and Windows builds don't support logback/log4j automatic switch as Linux does. `log4j.xml` still is here the only option now.

### Install the EXE files

Just run setup files with admin rights. If you use WinSW with a _.NET_ dependency, you should install it before.

After the setup, with the help of WinSW, a Windows service in declared, but not started and set to Manual.

Free feel to edit `servicewinsw.xml` before build the setup, or edit the production file `winsw.xml`. Please to refer to WinSW documentation.

Don't forget to setup a compatible JVM, and put java.exe directory in PATH.

## How to make a RPM installer for this app

Do a

```bash
./make-rpm.bash
```

You will need `git`, `realpath`, `man`, `pandoc`, `rpmlint`, `rpmbuild`, `rpm`.

It's fonctionnal on _Debian-like_ hosts (to build it, not run it).

Don't forget to install/setup `java`, `maven`, `pandoc`...

## Run internal self tests

Do a

```bash
./run-tests.bash
```

It will create a test RPM file for a demo java project on `test/demospringboot`, and optionnaly a EXE file.

You will need all the mandatory RPM deps, optionnaly EXE deps.

## Roadmap dev

Like for the [linux-app-packager](https://github.com/hdsdi3g/linux-app-packager) project, free feel to add corrections and/or new features (it's really not rocket science).

On day, **DEB** files will be added, like RPM here.
