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

CLEARNET_VBOX_LIB_HOME="/home/amnesia/.clearnet-vbox"
CLEARNET_VBOX_ENV_FILE="${CLEARNET_VBOX_LIB_HOME}/env"
CLEARNET_HVM_MOUNT="/home/clearnet/HiddenVM"

# Logs a message in a standardized format to stdout
# $1 The message to log
log() {
    local MSG="${1}"
    local CMD="$(basename "${0}")"
    local TIMESTAMP=$(date -u --rfc-3339=seconds)

    echo "${TIMESTAMP} [HiddenVM] [${CMD}] ${MSG}"
}

# Logs an error message in a standardized format to stderr
# $1 The error message to log
error() {
    log "${1}" >&2
}

is_amnesia() {
    # The :- appended to SUDO_USER is so that the check works with set -u
    if [ "$(whoami)" == "amnesia" ] && [ -z "${SUDO_USER:-}" ]; then
        return 0
    else
        return 1
    fi
}

enforce_amnesia() {
    if ! is_amnesia; then
        error "This should be run directly by amnesia. Do not run as root or using sudo! Failing..."
        exit 1
    fi
}

enforce_root() {
    if [ "$(whoami)" != "root" ]; then
        log "This should be run by root (or using sudo). Failing..."
        exit 1
    fi
}

# Displays a GUI message box
# $1: Type (error, info, warning)
# $2: Title
# $3: Message
msg_box() {
    local TYPE="${1}"
    local TITLE="${2}"
    local MSG="${3}"
    zenity --width 400 --${TYPE} --title "${TITLE}" --text "${MSG}" > /dev/null 2>&1 \
        || true # Ignore failure (user dismisses without clicking OK)
    return 0
}

# Displays an info GUI message box
# $1: Title
# $2: Message
info_box() {
    msg_box "info" "${1}" "${2}"
}

# Displays an error GUI message box
# $1: Title
# $2: Message
error_box() {
    msg_box "error" "${1}" "${2}"
}

# Displays a warning GUI message box
# $1: Title
# $2: Message
warn_box() {
    msg_box "warning" "${1}" "${2}"
}

get_tails_version() {
    tails-version | head -1
}

# $1 "Supported versions" file, one version string per line
is_tails_version_supported() {
    local SUPPORTED_VERSIONS_FILE="${1}"
    local CUR_TAILS_VERSION=$(get_tails_version)

    while read SUPPORTED_VER; do
        SUPPORTED_VER=$(echo "${SUPPORTED_VER}" | sed -e 's/^[[:blank:]]*//g' -e 's/[[:blank:]]*$//g')
        if [ "${CUR_TAILS_VERSION}" == "${SUPPORTED_VER}" ]; then
            return 0;
        fi
    done < "${SUPPORTED_VERSIONS_FILE}"

    return 1
}

is_tor_ready() {
    /bin/systemctl --quiet is-active tails-tor-has-bootstrapped.target
}
