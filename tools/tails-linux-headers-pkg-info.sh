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

if ! command -v jq >/dev/null; then
    echo "Must install jq"
    sudo apt-get -y -q install jq
    echo
fi


KREL=$(uname -r)
KVER=$(uname -v | cut -d' ' -f 4)
LINUX_HEADERS="linux-headers-${KREL}"
TAILS_DEB_STABLE_RELEASE=$(lsb_release -c -s)

CURL_OPTS="-s --socks5 localhost:9150"

PKG_BINFILES_URL="https://snapshot.debian.org/mr/binary/${LINUX_HEADERS}/${KVER}/binfiles"
PKG_INFO=$(curl ${CURL_OPTS} ${PKG_BINFILES_URL})
PKG_HASH=$(echo "${PKG_INFO}" | jq -r .result[0].hash)
PKG_ARCH=$(echo "${PKG_INFO}" | jq -r .result[0].architecture)

PKG_FILE_INFO_URL="https://snapshot.debian.org/mr/file/${PKG_HASH}/info"
PKG_FIRST_SEEN=$(curl ${CURL_OPTS} ${PKG_FILE_INFO_URL} | jq -r .result[0].first_seen)

echo "Tails release:  ${TAILS_DEB_STABLE_RELEASE}"
echo "Kernel release: ${KREL}"
echo "Kernel version: ${KVER}"
echo "Linux headers:  ${LINUX_HEADERS}"
echo "Architecture:   ${PKG_ARCH}"
echo "Package hash:   ${PKG_HASH}"
echo "First seen:     ${PKG_FIRST_SEEN}"

TMP_SRC_LIST="/tmp/hiddenvm-tails-src.list"

MATCHING_RELEASE=""
for RELEASE in ${TAILS_DEB_STABLE_RELEASE} testing sid experimental oldstable oldoldstable; do
    echo
    echo "Processing '${RELEASE}'"
    echo "deb [check-valid-until=no] tor+http://snapshot.debian.org/archive/debian/${PKG_FIRST_SEEN}/ ${RELEASE} main" > "${TMP_SRC_LIST}"

    sudo apt-get -y -q -o Acquire::Check-Valid-Until=false --no-list-cleanup \
        -o Dir::Etc::SourceList=${TMP_SRC_LIST} -o Dir::Etc::SourceParts=- \
        update

    if grep -q "Package: ${LINUX_HEADERS}" /var/lib/apt/lists/snapshot.debian.org_archive_debian_${PKG_FIRST_SEEN}_dists_${RELEASE}_main_binary-${PKG_ARCH}_Packages; then
        MATCHING_RELEASE=${RELEASE}
        break
    fi
done

echo
echo "Cleaning up apt lists by re-running 'apt-get update'"
# run apt-get update to clean up the lists we downloaded above
sudo apt-get -y -q -o Acquire::Check-Valid-Until=false update

echo
if [ -n "${MATCHING_RELEASE}" ]; then
    echo "Release found for ${LINUX_HEADERS}: ${MATCHING_RELEASE}"
    echo "Generated Debian sources:"
    echo

    for RELEASE in ${TAILS_DEB_STABLE_RELEASE} ${MATCHING_RELEASE}; do
        echo "deb [check-valid-until=no] tor+http://snapshot.debian.org/archive/debian/${PKG_FIRST_SEEN}/ ${RELEASE} main contrib"
    done
else
    echo "No release found for ${LINUX_HEADERS}"
fi
