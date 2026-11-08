#!/bin/bash

set -e
lib_path="../../lib/"
source ${lib_path}path.sh
source ${lib_path}util.sh

runner_name=$(get_runner)
root_dir=$(pwd)
bin_dir="${root_dir}/${runner_name}"
add_lib64_dir="$runner_name/lib64"
add_bin_dir="$runner_name/bin"
arch=$(uname -m)
source_dir="${root_dir}/${runner_name}-src"
publish_dir="/builds/runners/${runner_name}"
version='3.7.1'

open_cbm_source_dir="${root_dir}/OpenCBM"
disk_to_rom_source_dir="${root_dir}/Disk2Easyflash-v1"

InstallBuildDependencies() {
    deps="libxxf86vm-dev libxmu-dev libxaw7-dev libreadline-dev texinfo xfonts-utils automake bison flex xa65 libsdl2-image-dev"
    install_deps $deps
}

GetStableRelease() {
    src_archive="${runner_name}-${version}.tar.gz"
    src_url="http://sourceforge.net/projects/vice-emu/files/releases/${src_archive}/download"
    wget ${src_url} -O ${src_archive}
    tar xzf ${src_archive}
}

GetSources() {
    if [ ! -d ${source_dir} ]; then
        svn checkout svn://svn.code.sf.net/p/vice-emu/code/trunk ${source_dir}
    else
        cd $source_dir
        svn up
    fi
    cd $source_dir
    version="r$(svn info | grep "^Revision:" | cut -d" " -f 2)"
}

BuildProject() {
    cd ${source_dir}/vice
    ./autogen.sh
    ./configure --enable-sdl2ui --prefix=${bin_dir}
    make
    make install
}

PackageProject() {
    cd $root_dir
    mkdir -p $add_lib64_dir
    cp -v /usr/lib/x86_64-linux-gnu/libSDL2_image* $add_lib64_dir
    cp -v $open_cbm_source_dir/opencbm/lib/libopencbm.so* $add_lib64_dir

    cp -v bin/* $add_bin_dir
    cp -v $disk_to_rom_source_dir/disk2easyflash.py $add_bin_dir

    dest_file="${runner_name}-${version}-${arch}.tar.gz"
    echo "Packaging to file $dest_file"
    tar czf ${dest_file} ${runner_name}
    mkdir -p $publish_dir
    cp -v $dest_file $publish_dir
    rm -rf ${source_dir} ${bin_dir}
}


InstallLibOpenCBMDependencies() {
    deps="libusb-1.0-0-dev cc65"
    install_deps $deps
}

GetOpenCBMSources() {
    if [ ! -d ${open_cbm_source_dir} ]; then
        git clone https://github.com/OpenCBM/OpenCBM
    else
        cd $open_cbm_source_dir
        git pull
    fi
}

BuildOpenCBMLib() {
    cd $open_cbm_source_dir
    make -f LINUX/Makefile opencbm plugin-xum1541
}

GetDisk2EasyFlashSources() {
    if [ ! -d ${disk_to_rom_source_dir} ]; then
        git clone https://github.com/milasoft64/Disk2Easyflash-v1.git
    else
        cd $disk_to_rom_source_dir
        git pull
    fi
}


if [ $1 ]; then
    $1
else
    InstallBuildDependencies
    InstallLibOpenCBMDependencies

    GetDisk2EasyFlashSources
    GetOpenCBMSources
    BuildOpenCBMLib

    GetSources
    BuildProject
    PackageProject
fi
