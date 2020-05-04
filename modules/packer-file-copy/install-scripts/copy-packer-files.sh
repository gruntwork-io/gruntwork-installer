#!/usr/bin/env bash
#
# Copy all files located in the $DEFAULT_PACKER_FILES_PATH to their corresponding location on the file systemm. For 
# example, copy /tmp/packer-files/foo/bar.txt to /foo/bar.txt.
#
# Detailed Example:
# $ DEFAULT_PACKER_FILES_PATH="/tmp/packer-files"
# $ tree /tmp/packer-files:
# .
# ├── etc
# │   └── foo.config
# └── opt
#     └── bar.sh
#
# $ ./copy-packer-files.sh
# $ ls /etc/
# foo.config
# $ ls /opt/
# bar.sh

set -e

# Declare an array of paths to which Packer uploaded files
readonly DEFAULT_PACKER_FILES_PATH="/tmp/packer-files"

function copy_packer_files {
  local -ra file_upload_paths=("$DEFAULT_PACKER_FILES_PATH")
  local -r script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # For each file upload path, if there are any files there, relocate the files to their proper directories
  for upload_path in "${file_upload_paths[@]}"; do
      if [[ -e "$upload_path" ]]; then
          # Get the length of the string that $upload_path resolves to
          local -r upload_path_length=${#upload_path}
          local file=""

          for file in $(find "$upload_path" -type f); do
              local -r absolute_filename="${file:$upload_path_length}";
              echo "The packer-file-copy module is copying $file to $absolute_filename"
              sudo mkdir -p $(dirname "$absolute_filename");
              sudo mv "$file" "$absolute_filename";
          done
      fi
  done

  # Write README in case a future user is confused about /tmp/packer-files
  if [[ -e "$DEFAULT_PACKER_FILES_PATH" ]]; then
    cp "$script_path/../README.md" "$DEFAULT_PACKER_FILES_PATH"
  fi
}

copy_packer_files