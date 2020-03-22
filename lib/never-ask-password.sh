#!/bin/bash

# Copyright (C) 2020 HiddenVM <https://github.com/aforensics/HiddenVM>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


set -e

# Need HIDDENVM_SUDO_TIMEOUT_POLICY. Note that this script is intended to be
# run with sudo, so we must include common.sh from outside the AppImage mount.
# Otherwise this code will fail to execute due to permission issues caused by
# an AppImage/FUSE limitation.
. "/home/amnesia/.clearnet-vbox/common.sh"

enforce_root

# IMPORTANT: sudo parses files in /etc/sudoers.d in lexical order. We want this
# file to be parsed last to prevent others from overriding its settings, hence
# all the z's in the beginning of the file name.
echo "Defaults:amnesia timestamp_timeout=-1" > "${HIDDENVM_SUDO_TIMEOUT_POLICY}"
chmod 440 "${HIDDENVM_SUDO_TIMEOUT_POLICY}"
