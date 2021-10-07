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


# env file from first cmd line arg
# log file from second cmd line arg
ENV_FILE="${1}"
LOG_FILE="${2}"

PROG_REGISTRY="lib/progress-registry.csv"

# Processes stdin to filter and transform logs into progress data for Zenity
filter_and_transform_logs_for_progress() {
    # sed options used:
    #   -u: do not buffer
    #   -n: quiet
    #   -E: extended regex
    #   /p: only print matching text

    # Keep only lines that have the prog-id field in them and extract that field
    sed -u -n -E "s/^.+ \[HiddenVM\].+prog-id=([0-9]+).*/\1/p" | \
        # For each progress field ID, look up the progress message and percent
        # value in the registry and convert to the Zenity progress format:
        #     #message
        #     value
        while read PROGID; do \
            sed -u -n -E "s/^${PROGID},([0-9]+),(.+)$/#\2\n\1/p" "${PROG_REGISTRY}"; \
        done
}

# Use nested process substitution to send output from STDOUT and STDERR to:
# - The executing terminal (first tee)
# - A log file (inner tee)
# - Log line transformation and eventually the Zenity progress dialog (pipes)
exec &> >(tee >(tee "${LOG_FILE}" | \
    filter_and_transform_logs_for_progress | \
    zenity --class="HiddenVM" --window-icon=${HVM_ICON_COLOR} --width 400 --title "HiddenVM" --progress --no-cancel --auto-close 2>/dev/null
))

# Source some common variables
. "lib/common.sh"
# Unset these, which were set by common.sh. We don't want
# a failure in bootstrap.sh to terminate this process.
set +e
set +u

reset_sudo_timeout_policy() {
    # Use -n here to prevent prompt in case bootstrap.sh fails prematurely before
    # successful authentication. In such case the HiddenVM sudo timeout policy
    # file wouldn't have been installed anyway.
    log "Reset sudo timeout policy"
    sudo -n rm -f "${HIDDENVM_SUDO_TIMEOUT_POLICY}" >/dev/null 2>&1
    sudo -K
    return 0
}

# Run bootstrap.sh
if ./bootstrap.sh "${ENV_FILE}"; then
    reset_sudo_timeout_policy
    exit 0
else
    reset_sudo_timeout_policy
    # Let zenity take over this process
    exec zenity --class="Error" --window-icon=${HVM_ICON_COLOR} --width 400 --error --title "HiddenVM" \
        --text "The installation did not complete! Check the log file for details." \
        >/dev/null 2>&1
fi
