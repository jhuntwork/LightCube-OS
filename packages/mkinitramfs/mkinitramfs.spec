Summary: mkinitramfs
Name: mkinitramfs
Version: 0.5
Release: 1
Group: System Environment/Base
License: GPLv2
Distribution: LightCube OS
Vendor: LightCube Solutions
Buildarch: noarch
URL: http://dev.lightcube.us/projects/lightcubeos
Source0: Makefile.mkinitramfs
Source1: init.in
Source2: initcd.in
Source3: mkinitramfs.orig

BuildRequires: digest(sha1:%{SOURCE0}) = 7dfa2af5c2455c3f9107103cf4f3ab2a34d3fe62
BuildRequires: digest(sha1:%{SOURCE1}) = b3b2eabb64918a03500485f188e31012b4a12b23
BuildRequires: digest(sha1:%{SOURCE2}) = 168fab370b6e1041999e7d37f1210c93db80a240
BuildRequires: digest(sha1:%{SOURCE3}) = 8ed3fced5f229bea0a8b06b38a82958c5241f5b2

Requires: base-layout
Requires: glibc
Requires: bash
Requires: gzip
Requires: cpio
Requires: mdadm
Requires: ncurses
Requires: readline
Requires: psmisc
Requires: module-init-tools
Requires: util-linux-ng
Requires: LVM2

%description
A simple script to generate an initramfs file for a specified kernel.

%prep
%setup -T -c
cp %{SOURCE0} %{SOURCE1} %{SOURCE2} %{SOURCE3} .

%build

%install
make -f %{SOURCE0} DESTDIR=%{buildroot} install

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
/usr/bin/mkinitramfs
/usr/share/mkinitramfs

%changelog
* Fri Mar 03 2011 Jeremy Huntwork <jhuntwork@lightcubesolutions.com> - 0.5-1
- Upgrade to 0.5

* Sat Sep 17 2010 Jeremy Huntwork <jhuntwork@lightcubesolutions.com> - 0.4.1-1
- Upgrade to 0.4.1
- Fixes switch_root usage, restructure to avoid repeating code.
- Make /dev a tmpfs file system, add mknod to the initramfs

* Fri Sep 17 2010 Jeremy Huntwork <jhuntwork@lightcubesolutions.com> - 0.4-1
- Upgrade to 0.4
- Add virtio drivers to initramfs
- Use switch_root instead of manual commands

* Wed Sep 15 2010 Jeremy Huntwork <jhuntwork@lightcubesolutions.com> - 0.3-1
- Upgrade to 0.3
- Name initramfs file such that grub-mkconfig autodetects it
- Add support for UUID labels as generated by grub-mkconfig

* Mon Sep 13 2010 Jeremy Huntwork <jhuntwork@lightcubesolutions.com> - 0.2-1
- Upgrade to 0.2 - add support for software raid

* Tue Aug 10 2010 Jeremy Huntwork <jhuntwork@lightcubesolutions.com> - 0.1-1
- Initial version
