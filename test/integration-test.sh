#!/bin/bash
#
# Some basic automated tests for gruntwork-installer

set -e

readonly LOCAL_INSTALL_URL="file:///src/gruntwork-install"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Using local copy of bootstrap installer to install local copy of gruntwork-install"
./src/bootstrap-gruntwork-installer.sh --download-url "$LOCAL_INSTALL_URL" --version "ignored-for-local-install"

echo "Using gruntwork-install to install a module from the module-ecs repo"
gruntwork-install --module-name "ecs-scripts" --repo "https://github.com/gruntwork-io/module-ecs" --branch "v0.0.1"

echo "Using gruntwork-install to install a module from the module-ecs repo with --download-dir option"
gruntwork-install --module-name "ecs-scripts" --repo "https://github.com/gruntwork-io/module-ecs" --branch "v0.0.1" --download-dir ~/tmp

echo "Checking that the ecs-scripts installed correctly"
configure-ecs-instance --help

echo "Using gruntwork-install to install a module from the gruntwork-install repo and passing args to it via --module-param"
gruntwork-install --module-name "dummy-module" --repo "https://github.com/gruntwork-io/gruntwork-installer" --tag "v0.0.17" --module-param "file-to-cat=$SCRIPT_DIR/integration-test.sh"

echo "Using gruntwork-install to install a binary from the gruntkms repo"
gruntwork-install --binary-name "gruntkms" --repo "https://github.com/gruntwork-io/gruntkms" --tag "v0.0.1"

echo "Checking that gruntkms installed correctly"
gruntkms --help