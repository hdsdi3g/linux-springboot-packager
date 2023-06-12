#    Linux Spring Boot packager
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

%define _topdir      %{getenv:PWD}/rpmbuild
%define _arch        noarch
%define buildroot    %{_topdir}/BUILDROOT

BuildRoot:           %{buildroot}
Summary:             Create Linux RPM packages and Windows installers for a Spring Boot project
License:             GNU General Public License, Version 3
Name:                linux-springboot-packager
Version:             %{getenv:VERSION}
Release:             %{getenv:RELEASE}
BuildArch:           noarch
Group:               Development/Tools
Vendor:              hd3g.tv
Requires:            bash man pandoc xmlstarlet git rpm-build rpmlint

%description
You will need Java, Maven, basename, realpath, and optionnally rpmbuild, rpmlint, npm, makensis.
Provided by hd3g.tv (https://hd3g.tv), for more information, go to https://github.com/hdsdi3g/linux-springboot-packager, or contact hdsdi3g <admin@hd3g.tv>.

%files
%defattr(644,root,root)
%attr(0755,root,root) %{_bindir}/make-springboot-exe
%attr(0755,root,root) %{_bindir}/make-springboot-rpm
%attr(0755,root,root) %{_bindir}/search-winsw.bash
%attr(0644, root,root) %{_libdir}/linux-springboot-packager/*
%doc %attr(0644, root,root) /usr/local/share/man/man1/*

%postun -p /usr/bin/bash
mandb -q
exit 0;
