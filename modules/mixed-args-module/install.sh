#!/bin/bash
# A dirt simple install script that expects one madatory argument, --message-to-echo, that it echoes. The echo message can be overridden with 
# a flag, --echo-override. This is used to test that the --module-param args in gruntwork-install can handle flags without values.

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
  local echomessage

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --message-to-echo)
        echomessage="$2"
        shift
        ;;
      --echo-override)
        echomessage="Override"
        ;;
      *)
        echo "Unrecognized argument: $key"
        exit 1
        ;;
    esac

    shift
  done

  assert_not_empty "--message-to-echo" "$echomessage"
  echo "$echomessage"
}

install "$@"