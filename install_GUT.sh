#!/bin/sh

set -eu

GUT_REF="${GUT_REF:-godot_4_7}"
GUT_URL="https://github.com/bitwes/Gut/archive/${GUT_REF}.tar.gz"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET_DIR="$SCRIPT_DIR/addons/gut"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/json-converter-gut.XXXXXX")

cleanup() {
	rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

if [ -f "$TARGET_DIR/plugin.cfg" ]; then
	printf '%s\n' "GUT is already installed at $TARGET_DIR"
else
	for command in curl tar godot; do
		if ! command -v "$command" >/dev/null 2>&1; then
			printf '%s\n' "Required command not found: $command" >&2
			exit 1
		fi
	done

	printf '%s\n' "Downloading GUT ref '$GUT_REF'..."
	curl --fail --location --silent --show-error "$GUT_URL" \
		--output "$TEMP_DIR/gut.tar.gz"
	tar -xzf "$TEMP_DIR/gut.tar.gz" -C "$TEMP_DIR"

	SOURCE_DIR=$(find "$TEMP_DIR" -type d -path '*/addons/gut' -print -quit)
	if [ -z "$SOURCE_DIR" ]; then
		printf '%s\n' "The downloaded archive does not contain addons/gut." >&2
		exit 1
	fi

	mkdir -p "$TARGET_DIR"
	cp -R "$SOURCE_DIR"/. "$TARGET_DIR"/
	printf '%s\n' "GUT installed at $TARGET_DIR"
fi

if ! command -v godot >/dev/null 2>&1; then
	printf '%s\n' "Required command not found: godot" >&2
	exit 1
fi

printf '%s\n' "Importing GUT scripts..."
godot --headless --path "$SCRIPT_DIR" --import

printf '%s\n' "Running all GUT tests..."
exec godot --headless --path "$SCRIPT_DIR" \
	-s addons/gut/gut_cmdln.gd \
	-gconfig=res://.gutconfig.json \
	-gexit
