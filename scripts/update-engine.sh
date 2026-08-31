#!/usr/bin/env bash
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# update-engine.sh: re-vendors the WebAssembly engine & SDK into credentio-validator-web

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SOURCE_MODE="local"
RELEASE_TAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local)
      SOURCE_MODE="local"
      shift
      ;;
    --release)
      SOURCE_MODE="release"
      RELEASE_TAG="${2:-}"
      if [[ -z "${RELEASE_TAG}" ]]; then
        echo "Error: --release requires a tag name (e.g. --release v0.1.7)" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./scripts/update-engine.sh [options]"
      echo ""
      echo "Options:"
      echo "  --local           Re-vendor from local sibling repo ../credentio-contributions (default)"
      echo "  --release <tag>   Download and vendor from GitHub Release tag (e.g. --release v0.1.7)"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

echo "=== Updating Credentio WebAssembly Engine (${SOURCE_MODE} mode) ==="

mkdir -p "${SITE_DIR}/vendor" "${SITE_DIR}/public/wasm"

if [[ "${SOURCE_MODE}" == "local" ]]; then
  LOCAL_SDK_DIR="$(cd "${SITE_DIR}/../credentio-contributions/wasm" 2>/dev/null && pwd || true)"
  if [[ -z "${LOCAL_SDK_DIR}" || ! -d "${LOCAL_SDK_DIR}" ]]; then
    echo "Error: Local SDK directory not found at ../credentio-contributions/wasm" >&2
    echo "Use '--release <tag>' to download from GitHub Releases instead." >&2
    exit 1
  fi

  echo "==> Building and packing local SDK in ${LOCAL_SDK_DIR}..."
  (cd "${LOCAL_SDK_DIR}" && npm run build)

  TEMP_DIR="$(mktemp -d /tmp/credentio-revendor.XXXXXX)"
  trap 'rm -rf "${TEMP_DIR}"' EXIT

  TARBALL_NAME="$(cd "${LOCAL_SDK_DIR}" && npm pack --pack-destination "${TEMP_DIR}" 2>/dev/null | tail -n 1)"
  
  echo "==> Updating vendor/${TARBALL_NAME}..."
  rm -f "${SITE_DIR}/vendor"/*.tgz
  cp "${TEMP_DIR}/${TARBALL_NAME}" "${SITE_DIR}/vendor/${TARBALL_NAME}"

  echo "==> Updating public/wasm/ binaries..."
  cp -f "${LOCAL_SDK_DIR}/lib/credentio.wasm" "${SITE_DIR}/public/wasm/credentio.wasm"
  cp -f "${LOCAL_SDK_DIR}/lib/credentio.js" "${SITE_DIR}/public/wasm/credentio.js"

  # Update package.json reference
  PACKAGE_JSON="${SITE_DIR}/package.json"
  sed -i.bak -E "s|\"@ghchinoy/credentio-wasm\": \"file:\./vendor/[^\"]+\"|\"@ghchinoy/credentio-wasm\": \"file:./vendor/${TARBALL_NAME}\"|g" "${PACKAGE_JSON}"
  rm -f "${PACKAGE_JSON}.bak"

elif [[ "${SOURCE_MODE}" == "release" ]]; then
  BASE_URL="https://github.com/ghchinoy/credentio-contributions/releases/download/${RELEASE_TAG}"
  VERSION_NUM="${RELEASE_TAG#v}"
  TARBALL_NAME="ghchinoy-credentio-wasm-${VERSION_NUM}.tgz"

  echo "==> Downloading release artifacts from ${BASE_URL}..."
  TEMP_DIR="$(mktemp -d /tmp/credentio-release-download.XXXXXX)"
  trap 'rm -rf "${TEMP_DIR}"' EXIT

  curl -sSL -o "${TEMP_DIR}/${TARBALL_NAME}" "${BASE_URL}/${TARBALL_NAME}"
  curl -sSL -o "${TEMP_DIR}/credentio.wasm" "${BASE_URL}/credentio.wasm"
  curl -sSL -o "${TEMP_DIR}/credentio.js" "${BASE_URL}/credentio.js"

  rm -f "${SITE_DIR}/vendor"/*.tgz
  cp "${TEMP_DIR}/${TARBALL_NAME}" "${SITE_DIR}/vendor/${TARBALL_NAME}"

  cp -f "${TEMP_DIR}/credentio.wasm" "${SITE_DIR}/public/wasm/credentio.wasm"
  cp -f "${TEMP_DIR}/credentio.js" "${SITE_DIR}/public/wasm/credentio.js"

  PACKAGE_JSON="${SITE_DIR}/package.json"
  sed -i.bak -E "s|\"@ghchinoy/credentio-wasm\": \"file:\./vendor/[^\"]+\"|\"@ghchinoy/credentio-wasm\": \"file:./vendor/${TARBALL_NAME}\"|g" "${PACKAGE_JSON}"
  rm -f "${PACKAGE_JSON}.bak"
fi

echo "==> Reinstalling npm dependencies..."
(cd "${SITE_DIR}" && npm install)

echo "======================================================="
echo "SUCCESS: Successfully updated WebAssembly engine!"
echo "  - vendor/${TARBALL_NAME}"
echo "  - public/wasm/credentio.{wasm,js}"
echo "======================================================="
