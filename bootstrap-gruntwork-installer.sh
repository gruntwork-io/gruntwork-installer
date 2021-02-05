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
# curl -LsS https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh | bash /dev/stdin --version 0.0.3
#
# You can copy this one-liner into your Packer and Docker templates and immediately after, start using the
# gruntwork-install command.

set -e

readonly BIN_DIR="/usr/local/bin"
readonly USER_DATA_DIR="/etc/user-data"

readonly DEFAULT_FETCH_VERSION="v0.4.1"
readonly FETCH_DOWNLOAD_URL_BASE="https://github.com/gruntwork-io/fetch/releases/download"
readonly FETCH_INSTALL_PATH="$BIN_DIR/fetch"

readonly GRUNTWORK_INSTALLER_DOWNLOAD_URL_BASE="https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer"
readonly GRUNTWORK_INSTALLER_INSTALL_PATH="$BIN_DIR/gruntwork-install"
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
  echo -e "  --user-data-owner\tOptional. The user who shown own the $USER_DATA_DIR folder. Default: (current user)."
  echo -e "  --download-url\tOptional. The URL from where to download $GRUNTWORK_INSTALLER_SCRIPT_NAME. Mostly used for automated tests. Default: $GRUNTWORK_INSTALLER_DOWNLOAD_URL_BASE/(version)/$GRUNTWORK_INSTALLER_SCRIPT_NAME."
  echo -e "  --no-sudo\tOptional. When true, don't use sudo to install binaries. Default: false"
  echo
  echo "Examples:"
  echo
  echo "  Install version 0.0.3:"
  echo "    bootstrap-gruntwork-installer.sh --version 0.0.3"
  echo
  echo "  One-liner to download this bootstrap script from GitHub and run it to install version 0.0.3:"
  echo "    curl -Ls https://raw.githubusercontent.com/gruntwork-io/gruntwork-installer/master/bootstrap-gruntwork-installer.sh | bash /dev/stdin --version 0.0.3"
}

function maybe_sudo {
  local -r no_sudo="$1"
  shift

  if [[ "$no_sudo" == "true" ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

# http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
function command_exists {
  local -r cmd="$1"
  type "$cmd" > /dev/null 2>&1
}

function download_url_to_file {
  local -r url="$1"
  local -r file="$2"
  local -r tmp_path=$(mktemp "/tmp/gruntwork-bootstrap-download-XXXXXX")
  local -r no_sudo="$3"

  echo "Downloading $url to $tmp_path"
  if command_exists "curl"; then
    local -r status_code=$(curl -L -s -w '%{http_code}' -o "$tmp_path" "$url")
    assert_successful_status_code "$status_code" "$url"

    echo "Moving $tmp_path to $file"
    maybe_sudo "$no_sudo" mv -f "$tmp_path" "$file"
  else
    echo "ERROR: curl is not installed. Cannot download $url."
    exit 1
  fi
}

function assert_successful_status_code {
  local -r status_code="$1"
  local -r url="$2"

  if [[ "$status_code" == "200" ]]; then
    echo "Got expected status code 200"
  elif string_starts_with "$url" "file://" && [[ "$status_code" == "000" ]]; then
    echo "Got expected status code 000 for local file URL"
  else
    echo "ERROR: Expected status code 200 but got $status_code when downloading $url"
    exit 1
  fi
}

function string_starts_with {
  local -r str="$1"
  local -r prefix="$2"

  [[ "$str" == "$prefix"* ]]
}

function string_contains {
  local -r str="$1"
  local -r contains="$2"

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
  local -r arch=$(get_os_arch)

  if string_contains "$arch" "64"; then
    echo "amd64"
  elif string_contains "$arch" "386"; then
    echo "386"
  elif string_contains "$arch" "686"; then
    echo "386" # Not a typo; 686 is also 32-bit and should work with 386 binaries
  elif string_contains "$arch" "arm"; then
    echo "arm"
  fi
}

function download_and_install {
  local -r url="$1"
  local -r install_path="$2"
  local -r no_sudo="$3"

  download_url_to_file "$url" "$install_path" "$no_sudo"
  maybe_sudo "$no_sudo" chmod 0755 "$install_path"
}

function install_fetch {
  local -r install_path="$1"
  local -r version="$2"
  local -r no_sudo="$3"

  local -r os=$(get_os_name)
  local -r os_arch=$(get_os_arch_gox_format)

  if [[ -z "$os_arch" ]]; then
    echo "ERROR: Unrecognized OS architecture: $(get_os_arch)"
    exit 1
  fi

  echo "Installing fetch version $version to $install_path"
  local -r url="${FETCH_DOWNLOAD_URL_BASE}/${version}/fetch_${os}_${os_arch}"
  download_and_install "$url" "$install_path" "$no_sudo"
}

function install_gruntwork_installer {
  local -r install_path="$1"
  local -r version="$2"
  local -r download_url="$3"
  local -r no_sudo="$4"

  echo "Installing $GRUNTWORK_INSTALLER_SCRIPT_NAME version $version to $install_path"
  download_and_install "$download_url" "$install_path" "$no_sudo"
}

function assert_not_empty {
  local -r arg_name="$1"
  local -r arg_value="$2"

  if [[ -z "$arg_value" ]]; then
    echo "ERROR: The value for '$arg_name' cannot be empty"
    print_usage
    exit 1
  fi
}

function create_user_data_folder {
  local -r user_data_folder="$1"
  local -r user_data_folder_owner="$2"
  local -r user_data_folder_readme="$user_data_folder/README.txt"
  local -r no_sudo="$3"

  echo "Creating $user_data_folder as a place to store scripts intended to be run in the User Data of an EC2 instance during boot"
  maybe_sudo "$no_sudo" mkdir -p "$user_data_folder"

maybe_sudo "$no_sudo" tee "$user_data_folder_readme" > /dev/null <<EOF
The /etc/user-data folder contains scripts that should be executed while an EC2 instance is booting as part of its
User Data (http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) configuration.

This folder is not an industry standard, but a convention we use at  Gruntwork (http://www.gruntwork.io) make User Data
scripts manageable. Many of the modules in Script Modules (https://github.com/gruntwork-io/script-modules) need not
only to be installed, but also to execute while a server is booting, and instead of scattering them in random locations
all over the file system, /etc/user-data gives us a single, common place to put them all.
EOF

  maybe_sudo "$no_sudo" chown -R "$user_data_folder_owner" "$user_data_folder"
}

function bootstrap {
  local fetch_version="$DEFAULT_FETCH_VERSION"
  local installer_version=""
  local download_url=""
  local user_data_folder_owner
  user_data_folder_owner="$(id -u -n)"
  local no_sudo="false"

  while [[ $# -gt 0 ]]; do
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
      --user-data-owner)
        user_data_folder_owner="$2"
        shift
        ;;
      --download-url)
        download_url="$2"
        shift
        ;;
      --no-sudo)
        no_sudo="$2"
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
  assert_not_empty "--user-data-owner" "$user_data_folder_owner"

  if [[ -z "$download_url" ]]; then
    download_url="${GRUNTWORK_INSTALLER_DOWNLOAD_URL_BASE}/${installer_version}/${GRUNTWORK_INSTALLER_SCRIPT_NAME}"
  fi

  echo "Installing $GRUNTWORK_INSTALLER_SCRIPT_NAME..."
  install_fetch "$FETCH_INSTALL_PATH" "$fetch_version" "$no_sudo"
  install_gruntwork_installer "$GRUNTWORK_INSTALLER_INSTALL_PATH" "$installer_version" "$download_url" "$no_sudo"
  create_user_data_folder "$USER_DATA_DIR" "$user_data_folder_owner" "$no_sudo"
  echo "Success!"
}

bootstrap "$@"
