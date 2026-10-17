#!/usr/bin/env bash
# Create a venv in DEST and install REQS into it, every hash checked:
#   bash install-python.sh DEST REQS
set -euo pipefail
[ $# -eq 2 ] || { echo "usage: install-python.sh DEST REQS" >&2; exit 2; }
python3 -m venv "$1"
"$1/bin/pip" install --quiet --disable-pip-version-check --require-hashes --only-binary :all: -r "$2"
echo "ok python dependencies ($2, every hash checked)"
