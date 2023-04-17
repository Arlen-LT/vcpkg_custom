#!/bin/bash -e

usage(){
    echo "Usage: ${0##*/} [options]"
    echo "--install <port_name>      install package"
    echo "--version                  show version"
    echo "--help                     show usage infomation"
    exit 0
}

install(){

    if [[ "$1" == "python3" ]]; then
        prerequisite_python3
        #echo "Not yet support this port"
    fi

    SOURCE_DIR=$PWD
    PORT=$1
    TRIPLET=arm64-android

    # For vcpkg required
    export ANDROID_NDK_HOME=$ANDROID_NDK

    # For python3 cross-compile required
    export READELF=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf
    export CONFIG_SITE=${SOURCE_DIR}/ports/${PORT}/config_site

    # clone vcpkg and install
    pushd $VCPKG_ROOT
    ./vcpkg install ${PORT}:${TRIPLET} --overlay-ports=${SOURCE_DIR}/ports --overlay-triplets=${SOURCE_DIR}/triplets
    popd
}

prerequisite_python3(){
    # For python3 cross-compile required
    export CONFIG_SITE=${SOURCE_DIR}/ports/${PORT}/config_site
    export AR=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar
    export AS=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-as
    export LD=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/ld
    export LINK=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-link
    export NM=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-nm
    export OBJCOPY=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-objcopy
    export OBJDUMP=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-objdump
    export PROFDATA=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-profdata
    export RANLIB=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib
    export READELF=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf
    export STRIP=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip
    export YASM=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/yasm
}

options=$(getopt -n "Installing VS Code Server" -l "help,version,install:" -o "hv" -a -- "$@")
eval set -- ${options}
while true
do
    case "$1" in
    	--install) shift; install $1 ;;
    	-h | --help) usage ;;
    	--version) echo "${0##*/} worked with vcpkg:203383666e2422ed31e1faebe6efa6e306bd126d"; exit 0 ;;
    	--) shift; break;;
    esac
    shift
done


