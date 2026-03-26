#!/bin/bash
# Build the exist-site-shell XAR package
set -e

VERSION="0.9.0-SNAPSHOT"
PACKAGE="exist-site-shell-${VERSION}.xar"

cd "$(dirname "$0")"

echo "Building ${PACKAGE}..."
rm -f "${PACKAGE}"

# XAR is a ZIP file containing the package contents
zip -r "${PACKAGE}" \
    expath-pkg.xml \
    repo.xml \
    controller.xq \
    content/ \
    templates/ \
    resources/ \
    data/

echo "Built: ${PACKAGE}"
ls -la "${PACKAGE}"
