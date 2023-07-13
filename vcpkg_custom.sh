#!/bin/bash -eu

BUILD_TRIPLET=x64-linux
HOST_TRIPLET=arm64-android

SOURCE_DIR=$(dirname $(realpath $0))
INSTALL_DIR=${SOURCE_DIR}/installed

usage(){
    echo "Usage: ${0##*/} [options]"
    echo "--install <port_name>      install package"
    echo "--remove <port_name>       remove package"
    echo "--version                  show version"
    echo "--help                     show usage infomation"
    exit 0
}

install_package()
{
    PORT=$1

    if [ ! -d ${SOURCE_DIR}/ports/${PORT} ]; then
        echo "${PORT} not found, please try to search in official microsoft/vcpkg"
        exit -1
    fi

    pycode=$(cat << END

import json,sys
fp=open("${SOURCE_DIR}/ports/${PORT}/vcpkg.json")
obj=json.load(fp)
if "dependencies" not in obj:
    print(False)
    exit(0)
for item in obj["dependencies"]:
    if isinstance(item, dict) and item["name"] == "${PORT}":
        print(item["host"])
        exit(0)
    else:
        continue
print(False)
exit(0)

END
)

    if [ $(python -c "${pycode}") == "True" ] && [ -z $($VCPKG_ROOT/vcpkg list ${PORT}:${BUILD_TRIPLET}) ]; then
        echo "This script is for cross-compiling, you must need install ${PORT}:${BUILD_TRIPLET} first"
        exit -2
    fi

    export ANDROID_API_LEVEL=29
    export ANDROID_NDK_HOME=${ANDROID_NDK} # For vcpkg required
    export CC=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API_LEVEL}-clang
    export CXX=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API_LEVEL}-clang++
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
    export SYSROOT=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot

    # use overlay ports & triplets
    ${VCPKG_ROOT}/vcpkg install ${PORT}:${HOST_TRIPLET} --overlay-ports=${SOURCE_DIR}/ports --overlay-triplets=${SOURCE_DIR}/triplets --debug-env --binarysource=clear --enforce-port-checks

    if [ "${PORT}" == "python3" ]; then
        handle_python3_artifact ${INSTALL_DIR}/${PORT}
    fi
}

remove_package()
{
    PORT=$1
    rm -rf ${INSTALL_DIR}/${PORT}
    ${VCPKG_ROOT}/vcpkg remove ${PORT}:${HOST_TRIPLET}
}

handle_python3_artifact(){
    PYTHON3_ARITFACT_DIR=$1
    CROSSENV_DIR=${INSTALL_DIR}/venv

    if [ -d ${PYTHON3_ARITFACT_DIR} ]; then
        rm -rf ${PYTHON3_ARITFACT_DIR}
    fi

    if [ -d ${CROSSENV_DIR} ]; then
        rm -rf ${CROSSENV_DIR}
    fi

    # fake a common installed python directory structure to let crossenv know where to find include headers and libraries.
    mkdir -p ${INSTALL_DIR}
    cp -R ${VCPKG_ROOT}/packages/python3_${HOST_TRIPLET} ${PYTHON3_ARITFACT_DIR} \
        && mv ${PYTHON3_ARITFACT_DIR}/tools/python3 ${PYTHON3_ARITFACT_DIR}/bin

    SYSCONFIG=${PYTHON3_ARITFACT_DIR}/lib/python3.10/_sysconfigdata__linux_aarch64-linux-android.py
    sed -i -e '2,3d' -e "1a _base = \'${PYTHON3_ARITFACT_DIR}\'" ${SYSCONFIG}
    
    pyenv global 3.10.7
    pip install --upgrade pip crossenv
    python3 -m crossenv --sysconfigdata-file=${SYSCONFIG} \
        --sysroot=${SYSROOT} --env LDFLAGS="-lpython3.10" ${PYTHON3_ARITFACT_DIR}/bin/python3.10 ${CROSSENV_DIR}
    . ${CROSSENV_DIR}/bin/activate
    cross-pip install --upgrade pip yt-dlp
    cp -r ${CROSSENV_DIR}/cross/lib/python3.10/site-packages/* ${PYTHON3_ARITFACT_DIR}/lib/python3.10/site-packages/
    find ${PYTHON3_ARITFACT_DIR} -depth -name '__pycache__' -exec rm -rf {} ';'
    find ${PYTHON3_ARITFACT_DIR} -name '*.py[co]' -exec rm -f {} ';'
    7z a python3.zip ${PYTHON3_ARITFACT_DIR}/*
}

options=$(getopt -n "${0##*/}" -l "help,version,install:,remove:" -o "h" -a -- "$@")
eval set -- ${options}
while true
do
    case "$1" in
        --install) shift; install_package $1 ;;
        --remove) shift; remove_package $1 ;;
        -h | --help) usage ;;
        --version) echo "${0##*/} worked with vcpkg:a487471068f4cb1cbb4eeb340763cdcc0a75fd68"; exit 0 ;;
        --) shift; break;;
    esac
    shift
done