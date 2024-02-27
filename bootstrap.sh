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


# Terminate if any command fails or an unbound variable is used from here
set -e
set -u

SECONDS=0 # Reset elapsed time

# Source some common variables and functions we need
. "lib/common.sh"

enforce_amnesia

HVM_VERSION_FILE="./HVM_VERSION"
HVM_VERSION_FROM_VERSION_FILE=$(cat "${HVM_VERSION_FILE}")

# Set the terminal title
echo -e "\033]0;HiddenVM v${HVM_VERSION_FROM_VERSION_FILE}\007"

log "Begin installation of HiddenVM v${HVM_VERSION_FROM_VERSION_FILE}, prog-id=1"

cat <<EOF

+-----------------------------------------------------------------------+
| This software is not affiliated with the Tails or VirtualBox projects |
+-----------------------------------------------------------------------+

EOF

# Check if the Tails version is supported and let the user decide whether to continue
if ! is_tails_version_supported "./SUPPORTED_TAILS_VERSIONS"; then
    CUR_TAILS_VERSION=$(get_tails_version)

    log "WARNING: HiddenVM v${HVM_VERSION_FROM_VERSION_FILE} might not be compatible with your version of Tails (${CUR_TAILS_VERSION}). The installation may fail."
    zenity --class="Warning" --window-icon=${HVM_ICON_COLOR} --width 400 --question --title "HiddenVM" --text "HiddenVM v${HVM_VERSION_FROM_VERSION_FILE} might not be compatible with your version of Tails (${CUR_TAILS_VERSION}).\n\nPlease visit <a href='https://github.com/aforensics/HiddenVM'>https://github.com/aforensics/HiddenVM</a> for more information. Tails emergency releases can take us by surprise. Please be patient if a new version has not yet been released.\n\nThis installation could fail. Do you want to continue?" > /dev/null 2>&1
fi

# Make sure the CLEARNET_VBOX_LIB_HOME directory exists and is clean
rm -rf "${CLEARNET_VBOX_LIB_HOME}"
mkdir -p "${CLEARNET_VBOX_LIB_HOME}"

log "Copy files to ${CLEARNET_VBOX_LIB_HOME}, prog-id=2"

# Install some scripts/libraries to CLEARNET_VBOX_LIB_HOME to support some
# HiddenVM features that can launch from outside the AppImage mount, such as
# the user manually launching Clearnet VirtualBox.
cp "lib/common.sh" "${CLEARNET_VBOX_LIB_HOME}"
cp "lib/clearnet-vbox.sh" "${CLEARNET_VBOX_LIB_HOME}"
chmod +x "${CLEARNET_VBOX_LIB_HOME}/clearnet-vbox.sh"

# Copy these files outside the AppImage mount to make them accessible to sudo.
# There's an AppImage/FUSE limitation that prevents files located within an
# AppImage mount from being accessible to sudo.  :(
cp "lib/assets/hiddenvm.list" "${CLEARNET_VBOX_LIB_HOME}"
cp "lib/never-ask-password.sh" "${CLEARNET_VBOX_LIB_HOME}"
chmod +x "${CLEARNET_VBOX_LIB_HOME}/never-ask-password.sh"

# Override the "always ask for password" Tails sudo policy. First validate the
# entered admin password, making the user retry until successful. Then override
# the policy and refresh the credentials so that future sudo commands won't
# require authentication.
while :
do
    sudo -K # clear credentials cache to force authentication
    ADMIN_PASS=$(zenity --class="Attention" --password --title "Admin password needed" 2>/dev/null)
    # Note: Not all Zenity dialog types (e.g. password, file-selection) allow custom --window-icon to be set (bug report #998491)
    echo "${ADMIN_PASS}" | sudo -S -v > /dev/null 2>&1 && break
done
echo "${ADMIN_PASS}" | sudo -S "${CLEARNET_VBOX_LIB_HOME}/never-ask-password.sh"
echo "${ADMIN_PASS}" | sudo -S -v > /dev/null 2>&1

# Give ownership of the amnesia mounts to the amnesia user+group and relax the permissions.
# For example, new Veracrypt volume mounts are initially owned by root:root.
log "Set up permissions on amnesia mounts and clearnet user environment, prog-id=3"
sudo mkdir -p /media/amnesia
sudo chown amnesia:amnesia /media/amnesia
sudo chmod 710 /media/amnesia
sudo chown amnesia:amnesia /media/amnesia/* || true # Ignore failures
sudo chmod 775 /media/amnesia/* || true # Ignore failures

# Recreate classic clearnet user environmental conditions not present by default since Tails 6.x
sudo mkdir -p /home/clearnet/
sudo chown clearnet:clearnet /home/clearnet/
sudo usermod --home /home/clearnet clearnet

log "Process configuration, prog-id=4"

# Function: Asks the user to select their HiddenVM home directory, pre-selecting
# /media/amnesia. Note that this function sets the HVM_HOME variable!
choose_hiddenvm_home_dir() {
    info_box "HiddenVM" "You must now select your HiddenVM home folder. This should be inside an encrypted volume where you store all your VMs and related files." "Attention"

    CHOSEN_HVM_HOME=$(zenity --class="Attention" --file-selection \
        --directory --filename="/media/amnesia/" \
        --title "Select your HiddenVM home folder" 2> /dev/null
    )

    # Append a hard-coded 'HiddenVM' subdir
    CHOSEN_HVM_HOME="${CHOSEN_HVM_HOME}/HiddenVM"
    mkdir -p "${CHOSEN_HVM_HOME}"

    # If the chosen dir already has an env file, source it to pick up existing settings
    if [ -f "${CHOSEN_HVM_HOME}/env" ]; then
        . "${CHOSEN_HVM_HOME}/env"
    fi

    # Ensure HVM_HOME is set to what the user actually selected
    HVM_HOME="${CHOSEN_HVM_HOME}"
}

# Expect an env file path from the first cmd line arg
PROVIDED_ENV_FILE="${1:-}" # Default arg to empty

# If we have a provided env file, source it now to get HVM_HOME and other settings
if [ -f "${PROVIDED_ENV_FILE}" ]; then
    log "Sourcing provided env file: ${PROVIDED_ENV_FILE}"
    . "${PROVIDED_ENV_FILE}"

    # If the HVM_HOME dir is no longer valid, make the user choose one now
    if [ ! -d "${HVM_HOME}" ]; then
        log "HVM_HOME dir is invalid (asking user to choose a new one): ${HVM_HOME}"
        choose_hiddenvm_home_dir
    fi
else
    # Fresh start, user must choose the HiddenVM home dir
    choose_hiddenvm_home_dir
fi

if [ -z "${INSTALL_WARN:-}" ]; then
    INSTALL_WARN=$(zenity --class="Warning" --window-icon=${HVM_ICON_COLOR} --list --hide-header --title "HiddenVM" \
        --text "HiddenVM is about to be installed. <b><u>Do NOT use the system until VirtualBox has launched\!</u></b>\n\nTo prevent a crash and potential data loss, you should wait until the installation\ncompletes before continuing to use Tails. Click OK to proceed." \
        --checklist  --column "checkbox" --column "option" FALSE "Don't show this again" 2>/dev/null
    )
fi

# Create/overwrite the main environment file.
# INSTALL_WARN defaults to empty (show warning).
# INSTALL_EXT_PACK defaults to false.
cat > "${CLEARNET_VBOX_ENV_FILE}" <<EOF
HVM_HOME="${HVM_HOME}"
HVM_VERSION="${HVM_VERSION_FROM_VERSION_FILE}"
INSTALL_WARN="${INSTALL_WARN:-}"
INSTALL_EXT_PACK="${INSTALL_EXT_PACK:-false}"
EOF

# Cache the env file to HVM_HOME
cp "${CLEARNET_VBOX_ENV_FILE}" "${HVM_HOME}/env"

# Make sure some sub-directories exist in the HiddenVM home
mkdir -p "${HVM_HOME}/logs"

# Source the libraries we need
. "lib/system.sh"
. "lib/packages.sh"
. "lib/clearnet.sh"
. "lib/virtualbox.sh"
. "lib/extras-setup.sh"

# Run setup steps in the proper order
configure_system
restore_apt_package_cache
update_package_list_for_vbox_or_restore_cache
install_packages

UNINSTALLED_PKGS_CSV_BEFORE_DOWNGRADE=
if should_prune_package_cache; then
    log "Computing list of unused cached packages before stability downgrades, prog-id=12"
    UNINSTALLED_PKGS_CSV_BEFORE_DOWNGRADE=$(get_uninstalled_cached_pkgs_name_version_file_csv)
fi

downgrade_packages_for_stability
install_extra_apt_list
update_package_list_for_other_uses_or_restore_cache
setup_clearnet
setup_vbox_persistent_config
install_vbox_ext_pack_if_enabled

# Delete the default vbox launcher to prevent user confusion
sudo rm -f /usr/share/applications/virtualbox.desktop

# Launch Clearnet VirtualBox in the background using sudo, preventing
# the parent shell from killing it (nohup) if terminated
log "Launching Clearnet VirtualBox, prog-id=20"
nohup bash -c "${CLEARNET_VBOX_LIB_HOME}/clearnet-vbox.sh < /dev/null &" \
    >/dev/null 2>&1

install_dotfiles

# Perform the extras setup. Carry on if the custom extras script fails.
set +e
set +u
run_extras
set -e
set -u

# Prune the package cache and back it up after the extras setup,
# in case there were additional package installations
if should_prune_package_cache; then
    log "Recomputing list of unused cached packages, prog-id=23"
    UNINSTALLED_PKGS_CSV=$(get_uninstalled_cached_pkgs_name_version_file_csv)
    PKGS_TO_DELETE_FROM_CACHE_CSV=$(get_common_csv_between_2_runs "${UNINSTALLED_PKGS_CSV_BEFORE_DOWNGRADE}" "${UNINSTALLED_PKGS_CSV}")
    prune_package_cache "${PKGS_TO_DELETE_FROM_CACHE_CSV}"
fi
back_up_apt_packages

# Lastly, copy some resources to HVM_HOME
log "Copy 'extras' to ${HVM_HOME}"
cp -r ./extras/ "${HVM_HOME}/"

log "Done! Runtime: ${SECONDS}s, prog-id=25"

sleep 2 # Wait for all ouput to propagate through to the log file
