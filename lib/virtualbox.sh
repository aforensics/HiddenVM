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

# Makes the VirtualBox application's config persistent
setup_vbox_persistent_config() {
    log "Set up VirtualBox persistent configuration, prog-id=17"

    # Ensure that the persistent VirtualBox application config and VM dirs exist
    local VBOX_CONFIG_CACHE_DIR="${HVM_HOME}/cache/config-vbox"
    mkdir -p "${VBOX_CONFIG_CACHE_DIR}"
    mkdir -p "${HVM_HOME}/VirtualBox VMs"

    # Make the VirtualBox application persist its configs
    local HOME_CLEARNET_CONFIG="/home/clearnet/.config"
    local HOME_CLEARNET_CONFIG_VBOX="${HOME_CLEARNET_CONFIG}/VirtualBox"
    local VBOX_CONFIG_FILE_NAME="VirtualBox.xml"
    local VBOX_CONFIG_CACHE_FILE="${VBOX_CONFIG_CACHE_DIR}/${VBOX_CONFIG_FILE_NAME}"

    sudo rm -rf "${HOME_CLEARNET_CONFIG_VBOX}"
    sudo -u clearnet mkdir -p "${HOME_CLEARNET_CONFIG}"

    # If we have a cached vbox config, copy it to the right location for updating
    if [ -f "${VBOX_CONFIG_CACHE_FILE}" ]; then
        log "Found existing VirtualBox config: ${VBOX_CONFIG_CACHE_FILE}"
        sudo -u clearnet mkdir "${HOME_CLEARNET_CONFIG_VBOX}"
        sudo cp "${VBOX_CONFIG_CACHE_FILE}" "${HOME_CLEARNET_CONFIG_VBOX}/"
        sudo chown -R clearnet:clearnet "${HOME_CLEARNET_CONFIG_VBOX}"
    fi

    # Update the machinefolder vbox config property to point to its persistent
    # location within the "HiddenVM" mount
    sudo -u clearnet vboxmanage setproperty machinefolder \
        "${CLEARNET_HVM_MOUNT}/VirtualBox VMs"

    # Copy the updated config file back to the cache
    sudo cp "${HOME_CLEARNET_CONFIG_VBOX}/${VBOX_CONFIG_FILE_NAME}" "${VBOX_CONFIG_CACHE_DIR}/"
    sudo chown -R amnesia:amnesia "${VBOX_CONFIG_CACHE_DIR}/"
    sudo rm -rf "${HOME_CLEARNET_CONFIG_VBOX}"

    # Create a symlink to the cached vbox config directory within the "HiddenVM"
    # mount. Because the mount isn't live yet, this symlink will remain broken
    # until the mount is established by the launcher.
    sudo -u clearnet ln -s "${CLEARNET_HVM_MOUNT}/cache/config-vbox" "${HOME_CLEARNET_CONFIG_VBOX}"
}

# Installs the VirtualBox Extension Pack
install_vbox_ext_pack() {
    local VBOX_VERSION=$(vboxmanage -v | cut -d 'r' -f 1)
    local VBOX_EXT_PACK_FILE="Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack"
    mkdir -p "${HVM_HOME}/downloads"
    local VBOX_EXT_PACK_FILE_LOCAL="${HVM_HOME}/downloads/${VBOX_EXT_PACK_FILE}"
    local VBOX_EXT_PACK_URL="http://download.virtualbox.org/virtualbox/${VBOX_VERSION}/${VBOX_EXT_PACK_FILE}"

    # Only download if we don't already have the file cached
    if [ ! -f "${VBOX_EXT_PACK_FILE_LOCAL}" ]; then
        log "Downloading VirtualBox Extension Pack v${VBOX_VERSION}, prog-id=18"
        curl ${VBOX_EXT_PACK_URL} --socks5 localhost:9150 -o "${VBOX_EXT_PACK_FILE_LOCAL}"
        log "Done downloading VirtualBox Extension Pack v${VBOX_VERSION}"
    fi
    
    log "Install VirtualBox Extension Pack v${VBOX_VERSION}, prog-id=19"
    sudo bash -c "echo \"y\" | vboxmanage extpack install --replace \"${VBOX_EXT_PACK_FILE_LOCAL}\""
}

install_vbox_ext_pack_if_enabled() {
    if [ "${INSTALL_EXT_PACK:-false}" == "true" ]; then
        install_vbox_ext_pack
    fi
}
