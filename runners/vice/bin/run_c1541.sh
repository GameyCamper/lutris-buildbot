#!/bin/bash

bin_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

export LD_LIBRARY_PATH=/home/peter/.local/share/lutris/runners/vice/lib64

$bin_dir/c1541 "$@"
