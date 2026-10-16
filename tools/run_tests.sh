#!/usr/bin/env bash
# Runs import + the headless test suite. Fails on test failures and on any SCRIPT ERROR,
# because GDScript runtime errors inside a test do not abort the runner by themselves.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"

"$GODOT" --headless --path . --import >/dev/null 2>&1
output="$("$GODOT" --headless --path . -s res://tests/run_tests.gd 2>&1)"
status=$?
echo "$output" | grep -vE '^\s*$|ObjectDB instances were leaked|at: cleanup'
if echo "$output" | grep -qE 'SCRIPT ERROR|Parse Error'; then
	echo "Script errors detected." >&2
	exit 1
fi
exit $status
