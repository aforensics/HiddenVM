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

CACHE_DIR="${HVM_HOME}/cache"
APT_CACHE_BACKUP_DIR="${CACHE_DIR}/var-cache"
APT_LIST_BACKUP_DIR_FOR_VBOX="${CACHE_DIR}/var-lib-apt-for-vbox"
APT_LIST_BACKUP_DIR_FOR_OTHER="${CACHE_DIR}/var-lib-apt-for-other"
LAST_APT_UPDATE_DATE_FILE_FOR_VBOX="${CACHE_DIR}/last-apt-update-for-vbox"
LAST_APT_UPDATE_DATE_FILE_FOR_OTHER="${CACHE_DIR}/last-apt-update-for-other"
APT_UPDATE_FREQ_DAYS=7
LAST_PKG_CACHE_PRUNE_DATE_FILE="${CACHE_DIR}/last-pkg-cache-prune"
PKG_CACHE_PRUNE_FREQ_DAYS=7
LAST_TAILS_VERSION_FILE="${CACHE_DIR}/last-tails-version"
LINUX_HEADERS_PKG="linux-headers-$(uname -r)"
LINUX_HEADERS_RELEASE="sid"
VBOX_PACKAGE_NAME="virtualbox-6.1"

# SourceList is to replace /etc/apt/sources.list
# SourceParts=- is to disable /etc/apt/sources.list.d
APT_OPTS_FOR_VBOX="-o Dir::Etc::SourceList=${CLEARNET_VBOX_LIB_HOME}/assets/hiddenvm.list -o Dir::Etc::SourceParts=-"

update_package_list_for_vbox_or_restore_cache() {
    # Update + back up package indexes for linux-headers and vbox, or use the cache
    if should_apt_update_for_vbox; then
        log "Run 'apt-get update' for linux-headers and vbox, prog-id=7"
        run_apt_update_for_vbox
        back_up_apt_lists_for_vbox
    else
        log "Restore package index cache for linux-headers and vbox, prog-id=8"
        restore_apt_list_cache_for_vbox
    fi
}

install_packages() {
    # Install
    #   make: needed for building linux headers
    #   bindfs: needed for creating the "HiddenVM" FUSE userspace mount
    #   dpkg-dev: we need dpkg-scanpackages for maintaining the package cache
    log "Install packages, prog-id=9"
    sudo apt-get -q -y ${APT_OPTS_FOR_VBOX} install make bindfs dpkg-dev

    # Install linux-headers
    log "Installing ${LINUX_HEADERS_PKG} from '${LINUX_HEADERS_RELEASE}', prog-id=10"
    sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y --no-install-recommends ${APT_OPTS_FOR_VBOX} \
        -t ${LINUX_HEADERS_RELEASE} install ${LINUX_HEADERS_PKG}

    # Install VirtualBox (note that this will create the vboxusers group and
    # build/install the VirtualBox kernel drivers)
    log "Install VirtualBox, prog-id=11"
    sudo apt-get -q -y ${APT_OPTS_FOR_VBOX} install ${VBOX_PACKAGE_NAME}
}

# If system packages were upgraded by linux-headers, the system may become unstable
# (for example, gnome-shell can crash). So this downgrades those packages.
downgrade_packages_for_stability() {
    # Figure out if any packages were upgraded as a result of installing linux-headers
    # The awk command gets all log chunks for all linux-headers install instances
    local APT_HISTORY_LOG="/var/log/apt/history.log"
    if UPGRADE_TXT=$(awk '/Commandline: apt-get.*install.*linux-headers.*/','/End-Date/' \
        "${APT_HISTORY_LOG}" | grep Upgrade)
    then
        # tail:  keep latest instance only
        # sed 1: clean up
        # sed 2: clean up and split to one line per package
        # sed 3: clean up and format as <package>=<version>
        # paste: merge lines with a space for use with apt-get
        local DOWNGRADE_STR=$(echo "${UPGRADE_TXT}" \
            | tail -1 \
            | sed 's/Upgrade: //' \
            | sed 's/), /)\n/g' \
            | sed 's/:.* (\(.*\), .*/=\1/' \
            | paste -s -d' '
        )

        log "Found packages upgraded by linux-headers that must be downgraded for stability"
        log "Rollback to the following package versions: ${DOWNGRADE_STR}, prog-id=13"
        sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y --allow-downgrades ${APT_OPTS_FOR_VBOX} install ${DOWNGRADE_STR}
    else
        log "Found no packages that need downgrading"
    fi
}

update_package_list_for_other_uses_or_restore_cache() {
    # Update + back up package indexes for things other than linux-headers and vbox, or use the cache
    if should_apt_update_for_other; then
        log "Run 'apt-get update' for other uses, prog-id=14"
        run_apt_update_for_other
        back_up_apt_lists_for_other
    else
        log "Restore package index cache for other uses, prog-id=15"
        restore_apt_list_cache_for_other
    fi
}

# $1: Apt list cache dir to check
# $2: Last apt update date file to check
should_apt_update() {
    local APT_LIST_CACHE_DIR="${1}"
    local LAST_APT_UPDATE_DATE_FILE="${2}"

    if [ ! -f "${LAST_TAILS_VERSION_FILE}" ]; then
        log "Did not find previously cached Tails version - will not use apt caches"
        return 0
    fi

    local TAILS_VERSION=$(get_tails_version)
    local LAST_TAILS_VERSION=$(cat "${LAST_TAILS_VERSION_FILE}")
    log "Found previously cached Tails version: ${LAST_TAILS_VERSION}"
    log "Current Tails version: ${TAILS_VERSION}"

    if [ "${TAILS_VERSION}" != "${LAST_TAILS_VERSION}" ]; then
        log "The cached and current Tails versions do not match - will not use apt caches"
        return 0
    fi

    log "Tails versions match"

    # Do we have cached apt lists?
    if [ ! -d "${APT_LIST_CACHE_DIR}/lists" ]; then
        log "No cached apt lists found in ${APT_LIST_CACHE_DIR}"
        return 0
    fi

    log "Found cached apt lists in ${APT_LIST_CACHE_DIR}"

    # Do we have a "last apt update date" file?
    if [ ! -f "${LAST_APT_UPDATE_DATE_FILE}" ]; then
        log "No record found for the last time 'apt-get update' was run (${LAST_APT_UPDATE_DATE_FILE})"
        return 0
    fi

    local NOW=$(date +%s)
    local LAST_DATE=$(date -d "$(cat "${LAST_APT_UPDATE_DATE_FILE}")" +%s)
    local NUM_SECS=$(( NOW - LAST_DATE ))
    local NUM_DAYS=$(( NUM_SECS / (60 * 60 * 24) ))

    # Has it been too long since the last apt update?
    if [ "${NUM_DAYS}" -ge "${APT_UPDATE_FREQ_DAYS}" ]; then
        log "It's been at least ${APT_UPDATE_FREQ_DAYS} days since 'apt-get update' was last run (${LAST_APT_UPDATE_DATE_FILE})"

        if ! is_tor_ready; then
            log "Tor is not ready, will not run 'apt-get update'"
            return 1
        else
            return 0
        fi
    fi

    return 1 # no apt update needed
}

should_apt_update_for_vbox() {
    should_apt_update "${APT_LIST_BACKUP_DIR_FOR_VBOX}" "${LAST_APT_UPDATE_DATE_FILE_FOR_VBOX}"
}

should_apt_update_for_other() {
    should_apt_update "${APT_LIST_BACKUP_DIR_FOR_OTHER}" "${LAST_APT_UPDATE_DATE_FILE_FOR_OTHER}"
}

should_prune_package_cache() {
    # Do we have a "last package cache prune date" file?
    if [ ! -f "${LAST_PKG_CACHE_PRUNE_DATE_FILE}" ]; then
        log "No record found for the last time the package cache was pruned (${LAST_PKG_CACHE_PRUNE_DATE_FILE})"
        return 0
    fi

    local NOW=$(date +%s)
    local LAST_DATE=$(date -d "$(cat "${LAST_PKG_CACHE_PRUNE_DATE_FILE}")" +%s)
    local NUM_SECS=$(( NOW - LAST_DATE ))
    local NUM_DAYS=$(( NUM_SECS / (60 * 60 * 24) ))

    # Has it been too long since the last package cache prune?
    if [ "${NUM_DAYS}" -ge "${PKG_CACHE_PRUNE_FREQ_DAYS}" ]; then
        log "It's been at least ${PKG_CACHE_PRUNE_FREQ_DAYS} days since the package cache was last pruned (${LAST_PKG_CACHE_PRUNE_DATE_FILE})"
        return 0
    fi

    return 1
}

# $1: Options
# $2: 'Last apt update date' file to use
run_apt_update() {
    if ! is_tor_ready; then
        error "Tor is not ready, cannot run 'apt-get update'"
        exit 1
    fi

    local APT_OPTS="${1}"
    local LAST_APT_UPDATE_DATE_FILE="${2}"

    mkdir -p "${CACHE_DIR}"

    # apt-get update errors out if we're in the AppImage mount. It tries to
    # chdir for some reason and fails because it's being run as root (AppImage
    # only allows access to amnesia). So change to the home dir temporarily, to
    # run apt-get update.
    pushd /home/amnesia >/dev/null

    local UPDATE_CMD="sudo apt-get -y -q -o Acquire::Check-Valid-Until=false ${APT_OPTS} update"

    # Run the update command. Keep in mind that apt-get doesn't always exit with a
    # non-zero exit code for things we consider failures. So make sure WE fail if:
    #   - apt-get exits with a non-zero exit code
    #   - The right-most command (grep) exits with a non-zero exit code (pipefail)
    #
    # Regarding the grep, we are mainly looking for apt-get error messages that
    # start with "Err:" or "E:"
    #
    # If we want to treat warnings as errors, replace -e '^E:' with -e '^[WE]:'
    #
    # Lastly, use tee to send a copy of the apt-get output to the console.
    bash -o pipefail -c "${UPDATE_CMD} 2>&1 | tee /dev/stderr | ( ! grep -q -e '^Err:' -e '^E:' )"

    echo "$(date)" > "${LAST_APT_UPDATE_DATE_FILE}"
    log "Timestamp recorded for 'apt-get update' to ${LAST_APT_UPDATE_DATE_FILE}"

    popd >/dev/null
}

run_apt_update_for_vbox() {
    run_apt_update "${APT_OPTS_FOR_VBOX}" "${LAST_APT_UPDATE_DATE_FILE_FOR_VBOX}"
}

run_apt_update_for_other() {
    run_apt_update "" "${LAST_APT_UPDATE_DATE_FILE_FOR_OTHER}"
}

# $1: Path to the apt list cache dir to use
restore_apt_list_cache() {
    local APT_LIST_CACHE_DIR="${1}"

    # Do we have cached apt lists?
    if [ -d "${APT_LIST_CACHE_DIR}/lists" ]; then
        log "Restore cached apt lists from ${APT_LIST_CACHE_DIR}"
        sudo cp -r "${APT_LIST_CACHE_DIR}/lists" /var/lib/apt
    else
        log "No cached apt lists found in ${APT_LIST_CACHE_DIR}"
    fi
}

restore_apt_list_cache_for_vbox() {
    restore_apt_list_cache "${APT_LIST_BACKUP_DIR_FOR_VBOX}"
}

restore_apt_list_cache_for_other() {
    restore_apt_list_cache "${APT_LIST_BACKUP_DIR_FOR_OTHER}"
}

# $1: Path to the apt list cache dir to use
back_up_apt_lists() {
    local APT_LIST_CACHE_DIR="${1}"

    log "Back up apt lists to ${APT_LIST_CACHE_DIR}"
    if [ -d "${APT_LIST_CACHE_DIR}" ]; then
        sudo rm -rf "${APT_LIST_CACHE_DIR}"
    fi
    mkdir -p "${APT_LIST_CACHE_DIR}"
    sudo cp -r /var/lib/apt/lists "${APT_LIST_CACHE_DIR}"
    sudo chown -R amnesia:amnesia "${APT_LIST_CACHE_DIR}"
}

back_up_apt_lists_for_vbox() {
    back_up_apt_lists "${APT_LIST_BACKUP_DIR_FOR_VBOX}"
}

back_up_apt_lists_for_other() {
    back_up_apt_lists "${APT_LIST_BACKUP_DIR_FOR_OTHER}"
}

# Note that 'apt-get update' rebuilds pkgcache.bin and srcpkgcache.bin in /var/cache/apt,
# so we do't need to worry about these files being stale for too long.
restore_apt_package_cache() {
    if [ -d "${APT_CACHE_BACKUP_DIR}/apt" ]; then
        log "Restore cached apt packages from ${APT_CACHE_BACKUP_DIR}, prog-id=6"
        sudo cp -r "${APT_CACHE_BACKUP_DIR}/apt" /var/cache/
    else
        log "No cached apt packages found in ${APT_CACHE_BACKUP_DIR}"
    fi
}

back_up_apt_packages() {
    log "Back up apt packages, prog-id=24"
    if [ -d "${APT_CACHE_BACKUP_DIR}" ]; then
        sudo rm -rf "${APT_CACHE_BACKUP_DIR}"
    fi
    mkdir -p "${APT_CACHE_BACKUP_DIR}"
    sudo cp -r /var/cache/apt "${APT_CACHE_BACKUP_DIR}"
    sudo chown -R amnesia:amnesia "${APT_CACHE_BACKUP_DIR}"

    local TAILS_VERSION=$(get_tails_version)
    echo "${TAILS_VERSION}" > "${LAST_TAILS_VERSION_FILE}"
    log "Recorded Tails version ${TAILS_VERSION}"
}

get_cached_pkgs_name_version_file_csv() {
    # dpkg-scanpackages errors out if we're in the AppImage mount. It tries to
    # chdir for some reason and fails because it's being run as root (AppImage
    # only allows access to amnesia). So change to the home dir temporarily, to
    # run dpkg-scanpackages.
    pushd /home/amnesia >/dev/null

    # awk:   get chunks between 'Package' and 'Filename' lines (all inclusive). The 'Version' line should be in between.
    # grep:  keep only the 'Package', 'Version' and 'Filename' lines
    # sed:   remove the labels
    # paste: merge every 3 lines using a comma as the output delimiter
    sudo dpkg-scanpackages --multiversion "/var/cache/apt/archives" \
        2>/dev/null | \
        awk '/Package: .*/','/Filename: /' | \
        grep -E "Package: |Version: |Filename: " | \
        sed -e 's/Package: //' -e 's/Version: //' -e 's/Filename: //' | \
        paste - - - -d','

    popd >/dev/null
}

get_installed_pkgs_name_version_csv() {
    # tail: skip first line (apt prints "Listing...")
    # cut:  separate beginning of string (contains the package name) from the version
    # sed:  clean up to package name and add a comma to separate it from the version
    apt list --installed \
        2>/dev/null | \
        tail -n +2 | \
        cut -d' ' -f 1,2 | \
        sed 's#/.* #,#'
}

# $1 A CSV line containing the name and version of the package to check. For example:
#    vim,2:8.1.0875-5
# $2 CSV string containing all installed package names and versions (one package per line). For example:
#    vim,2:8.1.0875-5
#    p7zip-rar,16.02-3
is_package_installed() {
    local CACHED_PACKAGE_CSV="${1}"
    local ALL_INSTALLED_PACKAGES_CSV="${2}"

    if echo "${ALL_INSTALLED_PACKAGES_CSV}" | grep -q "^${CACHED_PACKAGE_CSV}$"; then
        return 0
    else
        return 1
    fi
}

# This method is slow because it calls apt-cache.
# $1 A CSV line containing the name and version of the package to check. For example:
#    vim,2:8.1.0875-5
is_package_installed_slow() {
    local LINE="${1}"

    echo "${LINE}" | while IFS=, read PKG_NAME PKG_VERSION; do
        local PKG_INSTALLED_VERSION=$(apt-cache policy "${PKG_NAME}" | grep Installed | sed 's/.*Installed: \(.*\)/\1/')

        if [ "${PKG_VERSION}" == "${PKG_INSTALLED_VERSION}" ]; then
            return 0
        else
            return 1
        fi
    done
}

get_uninstalled_cached_pkgs_name_version_file_csv() {
    local ALL_CACHED_PKGS_CSV=$(get_cached_pkgs_name_version_file_csv)
    local ALL_INSTALLED_PKGS_CSV=$(get_installed_pkgs_name_version_csv)

    echo "${ALL_CACHED_PKGS_CSV}" | while read LINE; do
        local CACHED_PACKAGE_CSV=$(echo "${LINE}" | cut -d , -f 1,2 --output-delimiter ,)

        #if ! is_package_installed_slow "${CACHED_PACKAGE_CSV}"; then
        if ! is_package_installed "${CACHED_PACKAGE_CSV}" "${ALL_INSTALLED_PKGS_CSV}"; then
            echo "${LINE}"
        fi
    done
}

# $1 Uninstalled cached package info CSV from run 1
# $2 Uninstalled cached package info CSV from run 2
get_common_csv_between_2_runs() {
    local CSV1="${1}"
    local CSV2="${2}"
    echo -e "${CSV1}\n${CSV2}" | sort | uniq -d
}

# $1 CSV string containing all to-be-deleted package names, versions and file path (one package per line). For example:
#    vim,2:8.1.0875-5,/var/cache/apt/archives/vim_2%3a8.1.0875-5_amd64.deb
#    p7zip-rar,16.02-3,/var/cache/apt/archives/p7zip-rar_16.02-3_amd64.deb
prune_package_cache() {
    local PKGS_TO_DELETE_CSV="${1}"

    if [ -z "${PKGS_TO_DELETE_CSV}" ]; then
        log "No unused packages to delete from cache"
    else
        log "Found unused packages to delete from cache"
        echo "${PKGS_TO_DELETE_CSV}" | while read LINE; do
            echo "${LINE}" | while IFS=, read PKG_NAME PKG_VERSION PKG_FILE; do
                if [ -f "${PKG_FILE}" ]; then
                    log "Delete unused package from cache: ${PKG_NAME}-${PKG_VERSION} (${PKG_FILE})"
                    sudo rm -f "${PKG_FILE}"
                else
                    error "Invalid package info CSV: '${LINE}'"
                fi
            done
        done
    fi

    echo "$(date)" > "${LAST_PKG_CACHE_PRUNE_DATE_FILE}"
    log "Timestamp recorded for cached package prune to ${LAST_PKG_CACHE_PRUNE_DATE_FILE}"
}
