#!/bin/bash
#
# Source: https://github.com/milasoft64/Disk2Easyflash-v1
# Tool for converting from a d64 (disk) or T64 (tape) to a crt (cartridge) format.
#
bin_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

python $bin_dir/disk2easyflash.py "$@"
