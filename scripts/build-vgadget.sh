#!/usr/bin/env bash
set -euo pipefail

GADGET_NAME="Create_Tapered_Rounding_Toolpath"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
UNINSTALL_SCRIPT="${REPO_ROOT}/scripts/uninstall-windows-gadget.bat"
VERSION="${VERSION:-local}"
DEFAULT_DESTINATION="/Volumes/Shared Data/Projects/Design-and-Making/PConklin"
DEFAULT_DESTINATION2="/Volumes/BDW20250714/PConklin"
DESTINATION="${1:-${NAS_DEST:-${DEFAULT_DESTINATION}}}"
DESTINATION2="${NAS_DEST2:-${DEFAULT_DESTINATION2}}"

cd "${REPO_ROOT}"

test -f "${GADGET_NAME}/${GADGET_NAME}.lua"
test -f "${GADGET_NAME}/${GADGET_NAME}.htm"
test -f "${UNINSTALL_SCRIPT}"

rm -rf "dist/${GADGET_NAME}"
mkdir -p "dist/${GADGET_NAME}"
cp -R "${GADGET_NAME}/." "dist/${GADGET_NAME}/"

(
  cd dist
  rm -f "${GADGET_NAME}_${VERSION}.vgadget"
  zip -qr "${GADGET_NAME}_${VERSION}.vgadget" "${GADGET_NAME}"
)

VGADGET_PATH="${REPO_ROOT}/dist/${GADGET_NAME}_${VERSION}.vgadget"
echo "Built ${VGADGET_PATH}"

if [[ -d "${DESTINATION}" ]]; then
  cp "${VGADGET_PATH}" "${DESTINATION}/"
  cp "${UNINSTALL_SCRIPT}" "${DESTINATION}/"
  echo "Copied to ${DESTINATION}/$(basename "${VGADGET_PATH}")"
  echo "Copied to ${DESTINATION}/$(basename "${UNINSTALL_SCRIPT}")"
elif [[ -d "${DESTINATION2}" ]]; then
  cp "${VGADGET_PATH}" "${DESTINATION2}/"
  cp "${UNINSTALL_SCRIPT}" "${DESTINATION2}/"
  echo "Copied to ${DESTINATION2}/$(basename "${VGADGET_PATH}")"
  echo "Copied to ${DESTINATION2}/$(basename "${UNINSTALL_SCRIPT}")"
else
  echo "NAS destination not found: ${DESTINATION}"
  echo "Mount WattNAS or pass a destination path, for example:"
  echo "  $0 \"${DEFAULT_DESTINATION}\""
fi
