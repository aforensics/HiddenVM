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

EXTRAS_HOME="${HVM_HOME}/extras"

install_extra_apt_list() {
    local EXTRA_APT_LIST="${EXTRAS_HOME}/apt.list"

    if [ -f "${EXTRA_APT_LIST}" ]; then
        log "Install extra apt list"
        sudo cp "${EXTRA_APT_LIST}" /etc/apt/sources.list.d/hiddenvm-extras.list
    else
        log "Did not find extra apt list file: ${EXTRA_APT_LIST}"
    fi
}

install_dotfiles() {
    local DOTFILES_HOME="${EXTRAS_HOME}/dotfiles"
    local DOTFILE_PROCESS_SCRIPT="${CLEARNET_VBOX_LIB_HOME}/process-dotfile.sh"
    chmod +x "${DOTFILE_PROCESS_SCRIPT}"

    if [ -d "${DOTFILES_HOME}" ]; then
        log "Processing dotfiles, prog-id=21"
        find "${DOTFILES_HOME}" -type f -exec "${DOTFILE_PROCESS_SCRIPT}" {} \;
        log "Done processing dotfiles"
    else
        log "Did not find dotfiles directory: ${DOTFILES_HOME}"
    fi
}

run_extras() {
    local EXTRAS_SCRIPT="${EXTRAS_HOME}/extras.sh"

    if [ -f "${EXTRAS_SCRIPT}" ]; then
        pushd "${EXTRAS_HOME}" > /dev/null

        log "Running extras.sh, prog-id=22"
        # Run it in a separate process to prevent that script from terminating us with 'exit'
        bash "${EXTRAS_SCRIPT}"
        log "Done running extras.sh"

        popd > /dev/null
    else
        log "Did not find extras script: ${EXTRAS_SCRIPT}"
    fi
}
