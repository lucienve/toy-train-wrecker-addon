#!/usr/bin/env bash
set -euo pipefail

TYPES_DIR=".types"
WOW_API_DIR="${TYPES_DIR}/wow-api"
FRAMEXML_DIR="${WOW_API_DIR}/Annotations/FrameXML"

mkdir -p "${TYPES_DIR}"

if [ ! -d "${WOW_API_DIR}/.git" ]; then
	echo "Downloading WoW API annotations from Ketho/vscode-wow-api..."
	rm -rf "${WOW_API_DIR}"
	git clone --filter=blob:none --no-checkout --depth 1 https://github.com/Ketho/vscode-wow-api.git "${WOW_API_DIR}"
	cd "${WOW_API_DIR}"
	git sparse-checkout set Annotations
	git checkout
	cd - > /dev/null
else
	echo "WoW API annotations already present."
fi

if [ ! -d "${FRAMEXML_DIR}" ]; then
	echo "Downloading FrameXML annotations from NumyAddon/FramexmlAnnotations..."
	TEMP_FRAMEXML="${TYPES_DIR}/framexml_temp"
	rm -rf "${TEMP_FRAMEXML}"
	git clone --filter=blob:none --no-checkout --depth 1 https://github.com/NumyAddon/FramexmlAnnotations.git "${TEMP_FRAMEXML}"
	cd "${TEMP_FRAMEXML}"
	git sparse-checkout set Annotations
	git checkout
	cd - > /dev/null
	mkdir -p "${FRAMEXML_DIR}"
	cp -r "${TEMP_FRAMEXML}/Annotations/"* "${FRAMEXML_DIR}/"
	rm -rf "${TEMP_FRAMEXML}"
else
	echo "FrameXML annotations already present."
fi

echo "WoW type annotations setup complete in ${TYPES_DIR}."
