#!/bin/bash
# A dirt simple install script that expects a single argument, --file-to-cat, that it runs cat on. This is used to
# test that the --module-param args in gruntwork-install work correctly.

set -e

function assert_not_empty {
  local -r arg_name="$1"
  local -r arg_value="$2"

  if [[ -z "$arg_value" ]]; then
    echo "ERROR: The value for '$arg_name' cannot be empty"
    exit 1
  fi
}

function install {
  local file_to_cat

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --file-to-cat)
        file_to_cat="$2"
        shift
        ;;
      *)
        echo "Unrecognized argument: $key"
        exit 1
        ;;
    esac

    shift
  done

  assert_not_empty "--file-to-cat" "$file_to_cat"
  cat "$file_to_cat"
}

install "$@"