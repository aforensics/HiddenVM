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

# Use -soft to fail if the tag already exists, to avoid messing up an existing release
# Note: Change to use -delete to completely replace the release if it already exists
$(go env GOPATH)/bin/ghr -soft v${HVM_VERSION} appimage/target/release
#$(go env GOPATH)/bin/ghr -delete v${HVM_VERSION} appimage/target/release

popd
