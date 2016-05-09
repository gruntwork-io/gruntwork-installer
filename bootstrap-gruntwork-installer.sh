#!/bin/bash
#
# A bootstrap script to install the Gruntwork Installer.
#
# Why:
#
# The goal of the Gruntwork Installer is to make make installing Gruntwork Script Modules feel as easy as installing a
# package using apt-get, brew, or yum. However, something has to install the Gruntwork Installer first. One option is
# for each Gruntwork client to do so manually, which would basically entail copying and pasting all the code below.
# This is tedious and would give us no good way to push updates to this bootstrap script.
#
# So instead, we recommend that clients use this tiny bootstrap script as a one-liner:
#
# curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh | bash /dev/stdin --version 0.0.3
#
# You can copy this one-liner into your Packer and Docker templates and immediately after, start using the
# gruntwork-install command.

set -e

readonly DEFAULT_FETCH_VERSION="v0.0.3"
readonly FETCH_DOWNLOAD_URL_BASE="https://github.com/gruntwork-io/fetch/releases/download"
readonly FETCH_INSTALL_PATH="/usr/local/bin/fetch"

readonly GRUNTWORK_INSTALLER_DOWNLOAD_URL_BASE="https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer"
readonly GRUNTWORK_INSTALLER_INSTALL_PATH="/usr/local/bin/gruntwork-install"
readonly GRUNTWORK_INSTALLER_SCRIPT_NAME="gruntwork-install"

function print_usage {
  echo
  echo "Usage: bootstrap-gruntwork-installer.sh [OPTIONS]"
  echo
  echo "A bootstrap script to install the Gruntwork Installer ($GRUNTWORK_INSTALLER_SCRIPT_NAME)."
  echo
  echo "Options:"
  echo
  echo -e "  --version\t\tRequired. The version of $GRUNTWORK_INSTALLER_SCRIPT_NAME to install (e.g. 0.0.3)."
  echo -e "  --fetch-version\tOptional. The version of fetch to install. Default: $DEFAULT_FETCH_VERSION."
  echo
  echo "Examples:"
  echo
  echo "  Install version 0.0.3:"
  echo "    bootstrap-gruntwork-installer.sh --version 0.0.3"
  echo
  echo "  One-liner to download this bootstrap script from GitHub and run it to install version 0.0.3:"
  echo "    curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh | bash /dev/stdin --version 0.0.3"
}

function command_exists {
  local readonly cmd="$1"
  type "$cmd" > /dev/null 2>&1
}

function download_url_to_file {
  local readonly url="$1"
  local readonly file="$2"

  echo "Downloading $url to $file"
  if $(command_exists "curl"); then
    local readonly status_code=$(curl -L -s -w '%{http_code}' -o "$file" "$url")
    if [[ "$status_code" != "200" ]]; then
      echo "ERROR: Expected status code 200 but got $status_code when downloading $url"
      exit 1
    fi
  else
    echo "ERROR: curl is not installed. Cannot download $url."
    exit 1
  fi
}

function string_contains {
  local readonly str="$1"
  local readonly contains="$2"

  [[ "$str" == *"$contains"* ]]
}
# http://stackoverflow.com/a/2264537/483528
function to_lower_case {
  tr '[:upper:]' '[:lower:]'
}

function get_os_name {
  uname | to_lower_case
}

function get_os_arch {
  uname -m
}

function get_os_arch_gox_format {
  local readonly arch=$(get_os_arch)

  if $(string_contains "$arch" "64"); then
    echo "amd64"
  elif $(string_contains "$arch" "386"); then
    echo "386"
  elif $(string_contains "$arch" "arm"); then
    echo "arm"
  fi
}

function download_and_install {
  local readonly url="$1"
  local readonly install_path="$2"

  download_url_to_file "$url" "$install_path"
  chmod 0755 "$install_path"
}

function install_fetch {
  local readonly install_path="$1"
  local readonly version="$2"

  local readonly os=$(get_os_name)
  local readonly os_arch=$(get_os_arch_gox_format)

  if [[ -z "$os_arch" ]]; then
    echo "ERROR: Unrecognized OS architecture: $(get_os_arch)"
    exit 1
  fi

  echo "Installing fetch version $version to $install_path"
  local readonly url="${FETCH_DOWNLOAD_URL_BASE}/${version}/fetch_${os}_${os_arch}"
  download_and_install "$url" "$install_path"
}

function install_gruntwork_installer {
  local readonly install_path="$1"
  local readonly version="$2"

  echo "Installing $GRUNTWORK_INSTALLER_SCRIPT_NAME version $version to $install_path"
  local readonly url="${GRUNTWORK_INSTALLER_DOWNLOAD_URL_BASE}/${version}/${GRUNTWORK_INSTALLER_SCRIPT_NAME}"
  download_and_install "$url" "$install_path"
}

function assert_not_empty {
  local readonly arg_name="$1"
  local readonly arg_value="$2"

  if [[ -z "$arg_value" ]]; then
    echo "ERROR: The value for '$arg_name' cannot be empty"
    print_usage
    exit 1
  fi
}

function bootstrap {
  local fetch_version="$DEFAULT_FETCH_VERSION"
  local installer_version=""

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --version)
        installer_version="$2"
        shift
        ;;
      --fetch-version)
        fetch_version="$2"
        shift
        ;;
      --help)
        print_usage
        exit
        ;;
      *)
        echo "ERROR: Unrecognized option: $key"
        print_usage
        exit 1
        ;;
    esac

    shift
  done

  assert_not_empty "--version" "$installer_version"
  assert_not_empty "--fetch-version" "$fetch_version"

  echo "Installing $GRUNTWORK_INSTALLER_SCRIPT_NAME..."
  install_fetch "$FETCH_INSTALL_PATH" "$fetch_version"
  install_gruntwork_installer "$GRUNTWORK_INSTALLER_INSTALL_PATH" "$installer_version"
  echo "Success!"
}

bootstrap "$@"