#!/bin/bash
# Runs the automated tests for this repo

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "Building docker container for test"
docker build -t gruntwork/gruntwork-installer test

echo "Running integration tests using docker-compose"
docker-compose -f test/docker-compose.yml run installer /test/integration-test.sh