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


enforce_amnesia

configure_system() {
    log "Configure system, prog-id=5"

    # Everything in the HiddenVM home must be owned by amnesia. This is important
    # for the "HiddenVM" FUSE userspace mount that amnesia will later create for
    # the clearnet user to access. VirtualBox (running as the clearnet user)
    # will be writing to it. And even though VirtualBox will run as the
    # clearnet user, bindfs creates new files and dirs within the mount point
    # as amnesia (the mounter), so amnesia should be the actual owner!
    sudo chown -R amnesia:amnesia "${HVM_HOME}"

    # Add FUSE config needed for mounting the userspace "HiddenVM" mount using bindfs
    sudo bash -c "echo \"user_allow_other\" >> /etc/fuse.conf"

    # Create Clearnet VirtualBox system launcher
    local LAUNCHER_FILE_NAME="clearnet-virtualbox.desktop"
    # Copy to /tmp first because sudo can't access the file from within the AppImage mount
    cp "lib/assets/${LAUNCHER_FILE_NAME}" /tmp/
    sudo chown root:root "/tmp/${LAUNCHER_FILE_NAME}"
    sudo mv "/tmp/${LAUNCHER_FILE_NAME}" /usr/share/applications/
    mkdir -p /home/amnesia/.local/share/icons
    cp "lib/assets/hiddenvm-icon-color.png" /home/amnesia/.local/share/icons/
    cp "lib/assets/hiddenvm-icon-notification.svg" /home/amnesia/.local/share/icons/

    # Disable the Tails additional software apt hooks to stop notifications
    local TAILS_ADD_SOFTWARE_HOOK="/etc/apt/apt.conf.d/80tails-additional-software"
    sudo mv "${TAILS_ADD_SOFTWARE_HOOK}" "${TAILS_ADD_SOFTWARE_HOOK}.disabled" \
        2>/dev/null || true
}
