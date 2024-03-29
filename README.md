# Spring Boot Linux Packager

This script collection will create:
 - a [RPM package](man-make-springboot-rpm.md)
 - a [DEB package](man-make-springboot-deb.md)
 - a [Windows self installer](man-make-springboot-exe.md) (via [NSIS](https://sourceforge.net/projects/nsis/) and [WinSW](https://github.com/winsw/winsw))

For a **Spring Boot** project, runned as service, or as command line interface (CLI / shell), and build npm/front during packaging.

Via _bash_, on Linux (RHEL/Debian) and Windows/WSL, not tested on macOS.

**See the md/man files on the project root for more informations.**

Free feel to add corrections and/or new features (it's really not rocket science).

And you can found two others scripts (see below):

 - a RPM package to install this scripts collection
 - a DEB package to install this scripts collection

[![Tests on Ubuntu](https://github.com/hdsdi3g/linux-springboot-packager/actions/workflows/tests-ubuntu.yml/badge.svg)](https://github.com/hdsdi3g/linux-springboot-packager/actions/workflows/tests-ubuntu.yml)

[![Shellcheck analysing](https://github.com/hdsdi3g/linux-springboot-packager/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/hdsdi3g/linux-springboot-packager/actions/workflows/shellcheck.yml)

[![Install app DEB on Ubuntu](https://github.com/hdsdi3g/linux-springboot-packager/actions/workflows/install-ubuntu.yml/badge.svg)](https://github.com/hdsdi3g/linux-springboot-packager/actions/workflows/install-ubuntu.yml)

## make-springboot-deb and make-springboot-rpm

For build RPMs and/or DEB files, you will need, in addition to `maven` and `java`:
 - `realpath`
 - `basename`
 - `pandoc`
 - `xmlstarlet`
 - `mktemp`
 - `dpkg-deb` (DEB)
 - `lintian` (DEB)
 - `rpmbuild` (RPM)
 - `rpmlint` (RPM)
 - and optionnaly `npm`

### Install the DEB/RPM files

The builded DEB/RPM will run some install/uninstall scripts and do a few things, apart from that, it's a classic, non-signed DEB and RPM files.

The setup script check the presence of `bash`, `man`, `useradd` (not for CLI), and `systemctl` (idem), and will deploy:
 - A man file ([template here](src/usr/lib/linux-springboot-packager/templates/template-man.md)), as `man artifactId`
 - some example files (not for CLI):
   - An configuration file (`application.yml`)
   - An configuration log file (`log4j2.xml` or `logback.xml`)
   - An default file
 - The application `jar` file
 - A `Systemd` service file, deployed, ready to run (not for CLI)
 - A command line runner (only for CLI)
 - THIRD-PARTY and LICENCE files if available.
 - An user/group and home dir for this user, as service name, to run the created service (not for CLI).
 - A log directory ready to get log files (not for CLI)

All templates are in the `src/usr/lib/linux-springboot-packager/templates` directory.

Java presence will _not be_ checked by the installer. The default service file will expect to found it in `/usr/bin/java`. Change it as you what after setup.

Before deploy files, the service will be stopped (if exists and if running). After deploy files, it will be enabled, at boot, but not started (not for CLI).

Run the setup with:

#### DEB

```bash
# Install / upgrade
sudo dpkg -i <artifactid-version.deb>

# Remove
sudo dpkg -r <artifactid>
```

#### RPM

```bash
# Install / upgrade
sudo rpm -U <artifactid-version.rpm>

# Remove
sudo rpm -e <artifactid>

# Remove "all"
sudo rpm -e --allmatches <artifactid>
```

You can run manually service with:

```bash
runuser -u <SERVICE_NAME> \
  -- java -Dlogging.config=/etc/<SERVICE_NAME>/log4j2.xml|logback.xml \
  -jar /usr/lib/<SERVICE_NAME>/<artifactId>-bin.jar \
  --spring.config.location=/etc/<SERVICE_NAME>/application.yml
```

And can run CLI with:
```bash
<artifactId> [params] [...]
```

## CLI or Service mode

By default, all service options (systemd, user, logs...) will be setup.

To switch to CLI mode, just add a POM proprerty on project pom (or it's ancestry) as:

```xml
<properties>
  <linux-springboot-packager.kind>cli</linux-springboot-packager.kind>
</properties>
```

And you **MUST** provide a **MAN** page. Free feel to generate it as you want. The _first_ `.man` file founded on project directory will be used. This call will be done after generate JAR with Maven, so you can link `mvn package` and *man* generation.

On Service building, the man page will be provided (see `template-man.md`).

On all cases, the man page will be displayed with:

```bash
man <artifactId>
```

## make-springboot-exe

Executable files, and uninstaller will be placed on `C:\Program Files\<project name>`, and "variable files" like log and application.yml in `C:\ProgramData\<project name>`.

An uninstall script add an entry in "Add/Remove programs" is setup.

Setup script are crafted to be simply "over installed": the next setup will uninstall the previous one (with a service stop and remove), but keep the actual "variable files".

By default, the service run will need a valid `application.yml` and `log4j2.xml`. Samples/examples are provided.

Actually, Windows builds don't support logback/log4j automatic switch as Linux does. `log4j.xml` still is here the only option now.

CLI option is not setup for Windows.

### Install the EXE files

Just run setup files with admin rights. If you use WinSW with a _.NET_ dependency, you should install it before.

After the setup, with the help of WinSW, a Windows service in declared, but not started and set to Manual.

Free feel to edit `servicewinsw.xml` before build the setup, or edit the production file `winsw.xml`. Please to refer to WinSW documentation.

Don't forget to setup a compatible JVM, and put java.exe directory in PATH.

## How to make a DEB/RPM installer for this app

Do a

```bash
./make-deb.bash
./make-rpm.bash
```

You will need `git`, `realpath`, `man`, `pandoc`, `rpmlint`, `rpmbuild`, `rpm`, `dpkg-deb` and `lintian` to run it.

It's fonctionnal for RPM on _Debian-like_ hosts (to build it, not run it), and vice-versa on DEB on _RHEL-like_ hosts.

Don't forget to install/setup `java`, `maven`, `pandoc`...

## Run internal self tests

Do a

```bash
./run-tests.bash
```

It will create a test DEB and RPM files for a demo java project on `test/demospringboot` and `test/democlispringboot` for CLI option, and optionnaly a EXE file.

You will need all the mandatory DEB and RPM deps, optionnaly EXE deps.
