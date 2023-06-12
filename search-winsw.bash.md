% search-winsw.bash(1) linux-springboot-packager documentation
% linux-springboot-packager

# NAME
search-winsw.bash - search the presence of WinSX Windows executable for the help of make-springboot-exe(1).

# SYNOPSIS
search-winsw.bash

You will need bash and realpath.

# DESCRIPTION
This script will return the full path of WinSW executable or it will fail with an error message.

This script will search these files names:

 - *WinSW.NET461.exe*
 - *WinSW.NET4.exe*
 - *WinSW.NET2.exe*
 - *WinSW-x64.exe*
 - *WinSW-x86.exe*

In these directories:

 - *$HOME/.config/linux-springboot-packager*
 - *$HOME/.bin*
 - *$HOME/.local/bin*
 - */usr/bin*
 - */usr/lib/linux-springboot-packager/include*
 - */usr/lib/linux-springboot-packager/templates*

In this orders, the first file found will be used.

# ENVIRONMENT
As environment variable:

**PREFIX=/somewhere** to *chroot* the app files search, for test purposes.

# EXIT CODES
| Error name                                 | Exit code |
| ------------------------------------------ | --------- |
| EXIT_CODE_MISSING_DEPENDENCY_COMMAND       | 1         |

# BUGS
Free feel to send issues to https://github.com/hdsdi3g/linux-springboot-packager/issues.

# AUTHORS
This application was writted by **hdsdi3g**; see on GitHub https://github.com/hdsdi3g/linux-springboot-packager.

# SEE ALSO
**make-springboot-exe(1)**.

# NOTES
This document was transformed by *pandoc* from the original markdown documentation file.

# COPYRIGHT
Copyright (C) hdsdi3g for hd3g.tv 2022, under the **GNU General Public License v3+**
