#
# Copyright (c) 2018-2025 TUXEDO Computers GmbH <tux@tuxedocomputers.com>
#
# This file is part of tuxedo-drivers.
#
# tuxedo-drivers is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 2
# of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

.PHONY: all install clean package package-deb package-rpm

KDIR := /lib/modules/$(shell uname -r)/build

PACKAGE_NAME := $(shell grep -Pom1 '.*(?= \(.*\) .*; urgency=.*)' debian/changelog)
PACKAGE_VERSION := $(shell grep -Pom1 '.* \(\K.*(?=\) .*; urgency=.*)' debian/changelog)

all:
	make -C $(KDIR) M=$(PWD) $(MAKEFLAGS) modules

install: all
	make -C $(KDIR) M=$(PWD) $(MAKEFLAGS) modules_install
	cp -r usr /

clean:
	make -C $(KDIR) M=$(PWD) $(MAKEFLAGS) clean
	rm -f debian/*.debhelper
	rm -f debian/*.debhelper.log
	rm -f debian/*.substvars
	rm -f debian/debhelper-build-stamp
	rm -f debian/files
	rm -rf debian/tuxedo-drivers
	rm -f src/dkms.conf
	rm -f tuxedo-drivers.spec

package: package-deb package-rpm

clean:
	rm -f src/dkms.conf
	rm -f tuxedo-drivers.spec
	rm -f $(PACKAGE_NAME)-*.tar.gz
	rm -rf debian/.debhelper
	rm -f debian/*.debhelper
	rm -f debian/*.debhelper.log
	rm -f debian/*.substvars
	rm -f debian/debhelper-build-stamp
	rm -f debian/files
	rm -rf debian/tuxedo-drivers
	rm -rf debian/tuxedo-cc-wmi
	rm -rf debian/tuxedo-keyboard
	rm -rf debian/tuxedo-keyboard-dkms
	rm -rf debian/tuxedo-keyboard-ite
	rm -rf debian/tuxedo-touchpad-fix
	rm -rf debian/tuxedo-wmi-dkms
	rm -rf debian/tuxedo-xp-xc-airplane-mode-fix
	rm -rf debian/tuxedo-xp-xc-touchpad-key-fix
	make -C $(KDIR) M=$(PWD) $(MAKEFLAGS) clean

install:
	make -C $(KDIR) M=$(PWD) $(MAKEFLAGS) modules_install

dkmsinstall:
	sed 's/#MODULE_VERSION#/$(PACKAGE_VERSION)/' debian/tuxedo-drivers.dkms > src/dkms.conf
	sed 's/#MODULE_VERSION#/$(PACKAGE_VERSION)/' tuxedo-drivers.spec.in > tuxedo-drivers.spec
	echo >> tuxedo-drivers.spec
	./debian-changelog-to-rpm-changelog.awk debian/changelog >> tuxedo-drivers.spec
	if ! [ "$(shell dkms status -m tuxedo-drivers -v $(PACKAGE_VERSION))" = "" ]; then dkms remove $(PACKAGE_NAME)/$(PACKAGE_VERSION); fi
	rm -rf /usr/src/$(PACKAGE_NAME)-$(PACKAGE_VERSION)
	rsync --recursive --exclude=*.cmd --exclude=*.d --exclude=*.ko --exclude=*.mod --exclude=*.mod.c --exclude=*.o --exclude=modules.order src/ /usr/src/$(PACKAGE_NAME)-$(PACKAGE_VERSION)
	dkms install $(PACKAGE_NAME)/$(PACKAGE_VERSION)
