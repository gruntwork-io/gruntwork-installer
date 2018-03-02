#!/bin/bash
# Runs the automated tests for this repo

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "Building docker containers for test"
docker build -t gruntwork/gruntwork-installer-ubuntu test/ubuntu
docker build -t gruntwork/gruntwork-installer-amazonlinux test/amazonlinux
docker build -t gruntwork/gruntwork-installer-centos test/centos

echo "Running integration tests using docker-compose"
docker-compose -f test/ubuntu/docker-compose.yml run installer /test/integration-test.sh
docker-compose -f test/amazonlinux/docker-compose.yml run installer /test/integration-test.sh
docker-compose -f test/centos/docker-compose.yml run installer /test/integration-test.sh
