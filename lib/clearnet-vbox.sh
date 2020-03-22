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

. "/home/amnesia/.clearnet-vbox/common.sh"
. "${CLEARNET_VBOX_ENV_FILE}"

enforce_amnesia

# Prevent running multiple instances of this script
CMD="$(basename "${0}")"
exec 9>"/var/lock/${CMD}"
if ! flock -x -n 9; then
    error "Another instance of ${CMD} is already running"
    warn_box "HiddenVM Clearnet VirtualBox" \
        "HiddenVM Clearnet VirtualBox is already running! If you've just closed it, please wait a few more moments for the shutdown to complete and try again."
    exit 1
fi

# Launches VirtualBox as the clearnet user with access to amnesia's display
launch_vbox() {
    log "Launch VirtualBox as the clearnet user"
    xhost "+si:localuser:clearnet"
    sudo --non-interactive -u clearnet virtualbox || true # Ignore on failure
    xhost "-si:localuser:clearnet"
}

# Self log to file from this point on
VBOX_LAUNCH_LOG_FILE="${HVM_HOME}/logs/clearnet-vbox.log"
exec &> >(tee "${VBOX_LAUNCH_LOG_FILE}")

log "HiddenVM v${HVM_VERSION}"

# Make sure the HiddenVM home is there (maybe the user ejected the drive)
if [ ! -d "${HVM_HOME}" ]; then
    error "Can't find HiddenVM home: ${HVM_HOME}"
    error_box "HiddenVM Clearnet VirtualBox" "Can't find <b><i>${HVM_HOME}</i></b>\n\nThis can happen if you renamed, moved or deleted that folder, or if you unmounted the volume where it exists. To fix this, you can either undo that action or re-run the installer to select a different folder."
    exit 1
fi

# Create a FUSE userspace mount, forcing file ownership by clearnet. Note that
# the true owner of newly created files within the target will be the mounter
# (amnesia). Only attempt to mount if not already mounted.
if ! findmnt "${CLEARNET_HVM_MOUNT}"; then
    log "Mount ${CLEARNET_HVM_MOUNT}"
    bindfs -u clearnet --resolve-symlinks "${HVM_HOME}" "${CLEARNET_HVM_MOUNT}"
else
    log "Mount point ${CLEARNET_HVM_MOUNT} already exists!"
fi

launch_vbox

# Check for VMs that were left running and relaunch VirtualBox if necessary
CHECK_CMD="pgrep -u clearnet -c -x VirtualBoxVM"
while VM_COUNT=$(${CHECK_CMD}); do
    log "VirtualBox GUI process terminated"

    log "${VM_COUNT} VM(s) still running:"
    pgrep -u clearnet -a -x VirtualBoxVM

    warn_box "HiddenVM Clearnet VirtualBox" \
        "You still have ${VM_COUNT} running VM(s). You must shut down all VMs before closing VirtualBox."
    launch_vbox
done

log "Completing tear down"

notify-send -i virtualbox \
    "HiddenVM Clearnet VirtualBox is shutting down" \
    "Please wait before launching it again or ejecting the volume"

# Lazily unmount (in case the file system is busy)
if findmnt "${CLEARNET_HVM_MOUNT}"; then
    log "Lazily unmount ${CLEARNET_HVM_MOUNT}"
    fusermount -u -z "${CLEARNET_HVM_MOUNT}"
    sleep 3
else
    log "Did not find mount point to unmount: ${CLEARNET_HVM_MOUNT}"
fi

notify-send -i virtualbox \
    "HiddenVM Clearnet VirtualBox was shut down successfully" \
    "You may re-launch it using GNOME Dash search or eject the volume"
