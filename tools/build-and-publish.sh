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

# Default ghr option to '-soft' (fail if the tag already exists, to avoid messing up an existing release)
GHR_OPT="-soft"
while [ -n "${1-}" ]; do
    case "${1-}" in
        -recreate)
            GHR_OPT="-recreate"
            ;;

        *)
            echo "Invalid option: ${1-}"
            echo "Available options:"
            echo -e "\t-recreate\tRecreate the release if the tag already exists"
            exit
            ;;
    esac
    shift
done

pushd ../appimage
./make-appimage.sh

HVM_VERSION=$(./target/HiddenVM-*-x86_64.AppImage -version)

# Check if 'go' is installed. Install 'go' + 'ghr' automatically if not.
if ! command -v go; then
    echo "Installing 'go' ..."
    sudo apt-get -y install golang-go
    echo "Installing 'ghr' ..."
    go get -u github.com/tcnksm/ghr
fi

echo "Publishing release v${HVM_VERSION} to github"

# Run ghr from repo root. Note that you must have an API token configured.
pushd ../

$(go env GOPATH)/bin/ghr ${GHR_OPT} -n v${HVM_VERSION} v${HVM_VERSION} appimage/target/release

popd
popd
