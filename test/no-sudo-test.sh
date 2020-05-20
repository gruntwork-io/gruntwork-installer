#!/bin/bash
#
# Some basic automated tests for gruntwork-installer

set -e

readonly LOCAL_INSTALL_URL="file:///src/gruntwork-install"

echo "Using local copy of bootstrap installer to install local copy of gruntwork-install"
./src/bootstrap-gruntwork-installer.sh --download-url "$LOCAL_INSTALL_URL" --version "ignored-for-local-install" --no-sudo "true"

echo "Using gruntwork-install to install a binary from the gruntkms repo into a different folder without using sudo"
gruntwork-install \
  --binary-name "gruntkms" \
  --repo "https://github.com/gruntwork-io/gruntkms" \
  --tag "v0.0.1" \
  --binary-install-dir "$HOME" \
  --no-sudo "true"

echo "Checking that gruntkms installed correctly into home dir"
"$HOME/gruntkms" --help
