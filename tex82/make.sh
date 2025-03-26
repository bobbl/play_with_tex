#!/bin/sh
# Compile TeX with Free Pascal


help() {
    echo "Usage: $0 <action> ..."
    echo
    echo "  depend      Install dependencies (TeX source code, fpc)"
    echo
    echo "  all         Build tex with fpc"
    echo "  clean       Remove build files"
}

if [ $# -eq 0 ] 
then
    help
    exit 1
fi






# check dependencies
depend() {

    if [ -d sources -a -d sources/dist ]
    then
        echo "Found TeX sources"
    else
        echo "Download TeX sources from CTAN"
        mkdir -p sources
        cd sources
        wget https://mirrors.ctan.org/systems/knuth/dist.zip
        unzip dist.zip
        cd ..
    fi

    fpc -h > /dev/null
    if [ $? -eq 0 ]
    then
        echo "Found fpc"
    else
        echo "Please install the Free Pascal Compiler (e.g. sudo apt install fpc)"
        exit 1
    fi
}





while [ $# -ne 0 ]
do
    case $1 in
        help)           help ;;
        depend)         depend ;;

        all)
            depend
            ;;

        clean)
            rm -rf build/*
            ;;

        *)
            echo "Unknown action $1. Stop."
            exit 1
            ;;
    esac
    shift
done


# SPDX-License-Identifier: ISC
