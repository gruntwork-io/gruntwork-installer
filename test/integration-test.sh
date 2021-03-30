#!/bin/bash
#
# Some basic automated tests for gruntwork-installer

set -e

readonly LOCAL_INSTALL_URL="file:///src/gruntwork-install"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Using local copy of bootstrap installer to install local copy of gruntwork-install"
./src/bootstrap-gruntwork-installer.sh --download-url "$LOCAL_INSTALL_URL" --version "ignored-for-local-install"

echo "Using gruntwork-install to install a module from the terraform-aws-ecs repo using branch"
gruntwork-install --module-name "ecs-scripts" --repo "https://github.com/gruntwork-io/terraform-aws-ecs" --branch "v0.0.1"

echo "Using gruntwork-install to install a module from the terraform-aws-ecs repo with --download-dir option"
gruntwork-install --module-name "ecs-scripts" --repo "https://github.com/gruntwork-io/terraform-aws-ecs" --branch "v0.0.1" --download-dir ~/tmp

echo "Checking that the ecs-scripts installed correctly"
configure-ecs-instance --help

echo "Using gruntwork-install to install a module from the gruntwork-install repo and passing args to it via --module-param"
gruntwork-install --module-name "dummy-module" --repo "https://github.com/gruntwork-io/gruntwork-installer" --tag "v0.0.25" --module-param "file-to-cat=$SCRIPT_DIR/integration-test.sh"

echo "Using gruntwork-install to install a module from the gruntwork-install repo with branch as ref"
gruntwork-install --module-name "dummy-module" --repo "https://github.com/gruntwork-io/gruntwork-installer" --ref "for-testing-dont-delete" --module-param "file-to-cat=$SCRIPT_DIR/integration-test.sh"

echo "Using gruntwork-install to install a module from the gruntwork-install repo with tag as ref"
gruntwork-install --module-name "dummy-module" --repo "https://github.com/gruntwork-io/gruntwork-installer" --ref "v0.0.25" --module-param "file-to-cat=$SCRIPT_DIR/integration-test.sh"

echo "Using gruntwork-install to install a test module from the gruntwork-install repo and test that it's args are maintained via --module-param"
gruntwork-install --module-name "args-test" --repo "https://github.com/gruntwork-io/gruntwork-installer" --tag "v0.0.25" --module-param 'test-args=1 2 3 *'

echo "Using gruntwork-install to install a binary from the gruntkms repo"
gruntwork-install --binary-name "gruntkms" --repo "https://github.com/gruntwork-io/gruntkms" --tag "v0.0.1"

echo "Checking that gruntkms installed correctly"
gruntkms --help

echo "Unsetting GITHUB_OAUTH_TOKEN to test installing from public repo (terragrunt)"
unset GITHUB_OAUTH_TOKEN

echo "Verifying private repo access is denied"
if gruntwork-install --binary-name "gruntkms" --repo "https://github.com/gruntwork-io/gruntkms" --tag "v0.0.1" ; then
  echo "ERROR: was able to access private repo"
  exit 1
fi

echo "Verifying public repo access is allowed"
gruntwork-install --repo 'https://github.com/gruntwork-io/terragrunt' --binary-name terragrunt --tag '~>v0.21.0'

echo "Checking that terragrunt installed correctly"
terragrunt --help
