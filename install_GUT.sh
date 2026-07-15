#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GUT_INSTALLER="$SCRIPT_DIR/addons/gut/install_gut.sh"

if [ ! -f "$GUT_INSTALLER" ]; then
	printf '%s\n' "GUT installer not found: $GUT_INSTALLER" >&2
	exit 1
fi

if ! command -v godot >/dev/null 2>&1; then
	printf '%s\n' "Required command not found: godot" >&2
	exit 1
fi

sh "$GUT_INSTALLER"

printf '%s\n' "Running all GUT tests..."
exec godot --headless --path "$SCRIPT_DIR" \
	-s addons/gut/gut_cmdln.gd \
	-gconfig=res://.gutconfig.json \
	-gexit
