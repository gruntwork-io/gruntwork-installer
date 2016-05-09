#!/bin/bash
#
# Some basic automated tests for gruntwork-installer

set -e

readonly LOCAL_INSTALL_URL="file:///src/gruntwork-install"

echo "Using local copy of bootstrap installer to install local copy of gruntwork-install"
./src/bootstrap-gruntwork-installer.sh --download-url "$LOCAL_INSTALL_URL" --version "ignored-for-local-install"

echo "Using gruntwork-install to install a few modules from script-modules"
gruntwork-install --module-name "vault-ssh-helper" --tag "~>0.0.21"

