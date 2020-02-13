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
set -u

ROOT_DIR="./AppDir"
TARGET_DIR="./target"

# Blow away and recreate the AppImage root and target directories
rm -rf "${ROOT_DIR}" "${TARGET_DIR}"
mkdir -p "${ROOT_DIR}" "${TARGET_DIR}/release"

# Copy the files we want
cp AppRun "${ROOT_DIR}/"
cp launch-log-progress.sh "${ROOT_DIR}/"
cp hiddenvm.desktop "${ROOT_DIR}/"
cp -r \
    ../bootstrap.sh \
    ../HVM_VERSION \
    ../SUPPORTED_TAILS_VERSIONS \
    ../extras \
    ../lib \
    ../LICENSE \
    "${ROOT_DIR}/"

pushd "${ROOT_DIR}"
# Use a dummy icon file for now
touch hiddenvm.svg
ln -s hiddenvm.svg .DirIcon
popd

APPIMGTOOL_NAME="appimagetool-x86_64.AppImage"
APPIMGTOOL="./${APPIMGTOOL_NAME}"
if [ ! -f "${APPIMGTOOL}" ]; then
    echo "appimagetool needs to be downloaded"
    wget "https://github.com/AppImage/AppImageKit/releases/download/continuous/${APPIMGTOOL_NAME}"
    chmod +x "${APPIMGTOOL}"
fi

APPIMG_NAME="HiddenVM-$(cat ../HVM_VERSION)-x86_64"
APPIMG_FILE="${APPIMG_NAME}.AppImage"

# Generate the AppImage and copy the LICENSE file to the target directory
ARCH=x86_64 ${APPIMGTOOL} "${ROOT_DIR}" "${TARGET_DIR}/${APPIMG_FILE}"
cp ../LICENSE "${TARGET_DIR}"

pushd "${TARGET_DIR}"

# Zip up the AppImage and LICENSE files
if [ "${1-}" != "skipzip" ]; then
    if ! command -v zip; then
        echo "Installing 'zip' ..."
        sudo apt-get -y install zip
    fi
    zip "${APPIMG_NAME}.zip" "${APPIMG_FILE}" LICENSE
fi

# Generate md5 sums
md5sum "${APPIMG_NAME}"* > "${APPIMG_NAME}.md5"

mv "${APPIMG_NAME}.zip" "${APPIMG_NAME}.md5" release/
popd
