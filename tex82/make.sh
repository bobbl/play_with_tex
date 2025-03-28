#!/bin/sh
# Compile TeX with Free Pascal


help() {
    echo "Usage: $0 <action> ..."
    echo
    echo "  depend      Install dependencies (TeX source code, fpc)"
    echo "  build       Compile TeX"
    echo "  tripman     Test by building the trip manual"
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

    cd sources
    if [ -d dist ]
    then
        echo "Found Knuth's distribution"
    else
        echo "Download Knuth's distribution from CTAN"
        wget https://mirrors.ctan.org/systems/knuth/dist.zip
        unzip dist.zip
    fi

    # Additional fonts in knuth/local/cm/
    #if [ -d local ]
    #then
    #    echo "Found Knuth's local information"
    #else
    #    echo "Download Knuth's local information from CTAN"
    #    wget https://mirrors.ctan.org/systems/knuth/local.zip
    #    unzip local.zip
    #fi

    cd ..

    fpc -h > /dev/null
    if [ $? -eq 0 ]
    then
        echo "Found fpc"
    else
        echo "Please install the Free Pascal Compiler (e.g. sudo apt install fpc)"
        exit 1
    fi
}



# Build TeX with the help of tex-fpc and fpc
# Following the steps described by Wolfgang Helbig in tex-fpc/README
build() {

    mkdir -p build
    cd build

    # 0. Compile tangle.p
    cp ../sources/tex-fpc/tangle.p .
    fpc tangle.p

    # 1. Make inimf and initex
    mkdir -p MFbases
    mkdir -p TeXformats
    ./tangle ../sources/dist/mf/mf.web ../sources/tex-fpc/inimf.ch inimf.p MFbases/mf.pool
    fpc -Fasysutils,baseunix,unix inimf.p
    ./tangle ../sources/dist/tex/tex.web ../sources/tex-fpc/initex.ch initex.p TeXformats/tex.pool
    fpc -Fasysutils,baseunix,unix initex.p

    # 2. Make plain.base
    cp ../sources/dist/lib/plain.mf .
    ./inimf plain input ../sources/tex-fpc/local dump
    #mv plain.base MFbases/


    # 3. Make mf
    ./tangle ../sources/dist/mf/mf.web ../sources/tex-fpc/mf.ch mf.p mf.pool
    fpc -Fasysutils,baseunix,unix mf.p

    # 4. Install .tfm-fonts for plain.tex
    mkdir -p TeXfonts
    cd TeXfonts
    cp ../../sources/dist/cm/* .
    cp ../../sources/dist/lib/manfnt.mf .
    #cp ../../sources/local/cm/* . # additional fonts

    # FIXME: move plain.base somewhere else by modifying mf.ch
    mkdir -p MFbases
    mv ../plain.base MFbases/

    for mf in *.mf
    do
        f=$(basename $mf .mf)
        ../mf "\\mode=localfont; batchmode; input $f"\
        && echo $f.tfm installed \
        || echo "Generation of $f.tfm failed"
    done


    rm *.mf *.log *.*gf
    cd ..


    # 5. Make plain.fmt
    cp ../sources/dist/lib/plain.tex .
    cp ../sources/dist/lib/hyphen.tex .
    ./initex plain \\dump


    # 6. Make tex
    ./tangle ../sources/dist/tex/tex.web ../sources/tex-fpc/tex.ch tex.p tex.pool.UNUSED
    fpc -Fasysutils,baseunix,unix tex.p


    # post
    cp plain.fmt TeXformats/plain.fmt

    cd ..
}


# Build the trip manual with tex
tripman() {
    mkdir -p build_tripman
    cd build_tripman
    rm -f *

    mkdir -p TeXformats
    cp  ../build/plain.fmt TeXformats/
    ln -s ../build/TeXfonts

    cp  ../sources/dist/tex/tripman.tex .
    cp  ../sources/dist/tex/trip.tex .
    cp  ../sources/dist/tex/trip.pl .
    cp  ../sources/dist/tex/tripin.log .
    cp  ../sources/dist/tex/trip.log .
    cp  ../sources/dist/tex/trip.typ .
    cp  ../sources/dist/tex/tripos.tex .
    cp  ../sources/dist/tex/trip.fot .

    ../build/tex tripman.tex
    cd ..
}




while [ $# -ne 0 ]
do
    case $1 in
        help)           help ;;
        depend)         depend ;;
        build)          build ;;
        tripman)        tripman ;;

        all)
            depend
            build
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
