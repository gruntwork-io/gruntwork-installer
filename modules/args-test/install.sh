#!/bin/bash
# A dirt simple install script that expects a single argument, --test-args, and validates that it equals '1 2 3 *'
# in order to test that the --module-param args in gruntwork-install works correctly.

set -e

if [[ "${#@}" -ne "2" ]]; then
  echo "ERROR: Expected exactly two arguments to install.sh but received ${#@}"
  exit 1
fi

if [[ "$1" != "--test-args" ]]; then
  echo "ERROR: Expected first argument to be '--test-args' but received '$1'"
  exit 1
fi

if [[ "$2" != '1 2 3 *' ]]; then
  echo "ERROR: Expected second argument to be '1 2 3 *' but received '$2'"
  exit 1
fi

echo "ok"
