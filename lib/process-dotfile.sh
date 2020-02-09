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

. "/home/amnesia/.clearnet-vbox/env"
. "/home/amnesia/.clearnet-vbox/common.sh"

enforce_amnesia

DOTFILE="${1}"
DIR="$(dirname "${DOTFILE}")"
FNAME="$(basename "${DOTFILE}")"

PATH_TO_REMOVE="${HVM_HOME}/extras/dotfiles"
NEW_BASE_DIR="/home/amnesia"

SUBDIR="$(echo "${DIR}" | sed "s#${PATH_TO_REMOVE}##")"
NEWDIR="${NEW_BASE_DIR}${SUBDIR}"
NEWPATH="${NEWDIR}/${FNAME}"

log "Symlink ${DOTFILE} --> ${NEWPATH}"
mkdir -p "${NEWDIR}"
ln -sf "${DOTFILE}" "${NEWDIR}"
