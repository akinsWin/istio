#!/bin/bash

# Copyright 2017 Istio Authors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# This script should be run on the version tag.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

function error_exit() {
    # ${BASH_SOURCE[1]} is the file name of the caller.
    echo "${BASH_SOURCE[1]}: line ${BASH_LINENO[0]}: ${1:-Unknown Error.} (exit ${2:-1})" 1>&2
    exit ${2:-1}
}

source ${ROOT}/istio.VERSION || error_exit 'Could not source istio.VERSION'
ISTIO_VERSION="$(cat ${ROOT}/istio.RELEASE)"
[[ -z "${ISTIO_VERSION}" ]] && error_exit 'ISTIO_VERSION is not set'
[[ -z "${ISTIOCTL_URL}" ]] && error_exit 'ISTIOCTL_URL is not set'

TMP_DIR="$(mktemp -d /tmp/istio.version.XXXX)"
COMMON_FILES_DIR="${TMP_DIR}/istio/istio-${ISTIO_VERSION}"
ARCHIVES_DIR="${TMP_DIR}/archives"
mkdir -p "${COMMON_FILES_DIR}/bin" "${ARCHIVES_DIR}"

function create_linux_archive() {
  local url="${ISTIOCTL_URL}/istioctl-linux"
  local istioctl_path="${COMMON_FILES_DIR}/bin/istioctl"

  wget -O "${istioctl_path}" "${url}" \
    || error_exit "Could not download ${istioctl_path}"
  chmod 755 "${istioctl_path}"

  tar --owner releng --group releng -czvf \
    "${ARCHIVES_DIR}/istio-${ISTIO_VERSION}-linux.tar.gz" . \
    || error_exit 'Could not create linux archive'
  rm -rf "${istioctl_path}"
}

function create_osx_archive() {
  local url="${ISTIOCTL_URL}/istioctl-osx"
  local istioctl_path="${COMMON_FILES_DIR}/bin/istioctl"

  wget -O "${istioctl_path}" "${url}" \
    || error_exit "Could not download ${istioctl_path}"
  chmod 755 "${istioctl_path}"

  tar --owner releng --group releng -czvf \
    "${ARCHIVES_DIR}/istio-${ISTIO_VERSION}-osx.tar.gz" . \
    || error_exit 'Could not create linux archive'
  rm -rf "${istioctl_path}"
}

function create_windows_archive() {
  local url="${ISTIOCTL_URL}/istioctl-win.exe"
  local istioctl_path="${COMMON_FILES_DIR}/bin/istioctl.exe"

  wget -O "${istioctl_path}" "${url}" \
    || error_exit "Could not download ${istioctl_path}"

  zip -r "${ARCHIVES_DIR}/istio_${ISTIO_VERSION}_win.zip" . \
    || error_exit 'Could not create linux archive'
  rm -rf "${istioctl_path}"
}

pushd ${ROOT}
cp istio.VERSION "${COMMON_FILES_DIR}"/
find samples install -type f -name "*.yaml" \
  -exec cp --parents {} "${COMMON_FILES_DIR}" \;
popd

# Changinf dir such that tar and zip files are
# created with right hiereachy
pushd "${COMMON_FILES_DIR}/.."
create_linux_archive
create_osx_archive
create_windows_archive
popd

echo "Archives are available in ${ARCHIVES_DIR}"
