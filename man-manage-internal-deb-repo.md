% manage-internal-deb-repo(1) linux-springboot-packager documentation
% linux-springboot-packager

# NAME
manage-internal-deb-repo - Create/manage a Debian "internal" repository, and push new deb files to it

# SYNOPSIS

manage-internal-deb-repo *[&lt;NEW_DEB_PACKAGE&gt;]*

# DESCRIPTION

CLI for automate actions with GPG, apt-ftparchive and apt to create a **local** deb/APT repository, signed with your GPG key.

It can optionnaly push it to another directory via sudo and rsync.

It's Debian package agnostic, but only works for architecture "all".

# OPTIONS
**BY DEFAULT**

Create an empty repository locally (ask on startup a path for it).

Scan new added packages in "./pool" directory and update the repository with these new packages.

**NEW_DEB_PACKAGE**

Add create/update the local repository, if needed, and add it (move) the provided package file.

# SETUP REPO

To add your new repository avaliable from your host **apt** database, update **/etc/apt/sources.list** file or create a new **/etc/apt/sources.list.d/internal-deb.list** file (the name is not important to work) with:

    deb [signed-by=<REPOSITORY_PATH>/pubkey.asc arch=all] file://<REPOSITORY_PATH> stable main

After the first run, the script can help you with a one-line command to do this.

To enable the new setup, just:

    apt-get update

And, as usual:

    apt-get dist-upgrade
    apt-get install <NEW PACKAGE>

Thanks to the magic of APT, if you push a new version, it will be automatically installed on the next upgrade action.

**BEWARE** 

From a **security** point of view, it's not wise to let a local user be able to propose packages for installation or update for the entire system. If there is an automatic update service on the machine, consider that local user has now **absolute root rights**.

Only root user (or sudoers) should be able to have the right to manage the contents of the repositories. That's why there is a secondary and optional mechanism (rootdeploy/sudo rsync) to push this repository to anther directory, with root rights.

# PREREQUISITES

You must have a functionnal gpg setup, with a default private key. It will be used to sign packages (technically, it sign manifests files). Your public key will be provided to apt to use it.

# FILES

**$HOME/.config/.debrepo**

Default configuration file: just the path to the local repo. Created directly by this script on first start.

**$HOME/.debrepo**

The default local directory. Not created if not needed.

**$HOME/.config/.debrepo-rootdeploy**

The specific rsync target to push the local repo to another directory, with root rights.

If needed, must be created by hand (just a path in a simple text file).

# EXIT CODES
| Error name                                 | Exit code |
| ------------------------------------------ | --------- |
| EXIT_CODE_MISSING_DEPENDENCY_COMMAND       | 1         |
| EXIT_CODE_MISSING_RSYNC_TARGET_DIR         | 2         |

# BUGS
Free feel to send issues to https://github.com/hdsdi3g/linux-springboot-packager/issues.

# AUTHORS
This application was writted by **hdsdi3g**; see on GitHub https://github.com/hdsdi3g/linux-springboot-packager.

# SEE ALSO
**make-springboot-deb(1)**.

https://unix.stackexchange.com/questions/403485/how-to-generate-the-release-file-on-a-local-package-repository

https://gist.github.com/aarroyoc/1a96b2f8b01fcf34221a

# NOTES
This document was transformed by *pandoc* from the original markdown documentation file.

# COPYRIGHT
Copyright (C) hdsdi3g for hd3g.tv 2024, under the **GNU General Public License v3+**
