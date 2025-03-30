#!/bin/sh
# Compile TeX with Free Pascal


help() {
    echo "Usage: $0 <action> ..."
    echo
    echo "  depend      Install dependencies (TeX source code, fpc)"
    echo "  build       Compile TeX"
    echo "  tripman     Test by building the trip manual"
    echo "  trip        Run trip test"
    echo
    echo "  all         Build tex with fpc"
    echo "  clean       Remove build files"
}

if [ $# -eq 0 ] 
then
    help
    exit 1
fi



# Check if a program ($1) is installed
check_installation() {
    $1 -h > /dev/null \
        && echo "Found $1" \
        || echo "Please install $1 (e.g sudo apt install $1)"
}



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

    check_installation fpc
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


# Compare two files and print error if not identical
compare() {
    d=$(diff $1 $2)
    if [ ! -z "$d" ]
    then
        echo "Differences between $1 and $2"
        echo "[[[ ----------------------------------"
        echo "$d"
        echo "]]] ----------------------------------"
    fi
}


# Run the trip test for TeX
trip() {
    mkdir -p build
    cd build

    # TODO: build PLtoTF and TFtoPL from .web sources

    # Step 0
    cp ../sources/dist/tex/trip.tex .

    # TODO: needless as long as PLtoTF and TFtoPL are not build from .web sources
    : '
    # Step 1: check PLtoTF and TFtoPL from .web sources
    cp ../sources/dist/tex/trip.pl .
    pltotf trip.pl trip.tfm
    tftopl trip.tfm tmp.pl
    pldiff=$(diff trip.pl tmp.pl)
    if [ ! -z "$pldiff" ]
    then
        echo "Error in PLtoTF or TFtoPL:"
        echo "$pldiff"
    fi
    '

    # Step 2: build special TeX version
    ./tangle ../sources/dist/tex/tex.web ../sources/tex-fpc/triptex.ch triptex.p tex.pool
    fpc -Fasysutils,baseunix,unix triptex.p

    # Step 3: First run of TeX
    cp ../sources/dist/tex/trip.tfm TeXfonts/
    printf "\n\\input trip\n" | ./triptex
    mv trip.log tripin.log
    compare tripin.log ../sources/dist/tex/tripin.log

    # Step 4: Second run of TeX
    rm -f 8terminal.tex
    printf " &trip  trip\n" | ./triptex > trip.fot
    compare trip.log ../sources/dist/tex/trip.log
    compare trip.fot ../sources/dist/tex/trip.fot
    [ -f 8terminal.tex ] || echo "ERROR: 8terminal.tex is missing"

    cd ..
}



while [ $# -ne 0 ]
do
    case $1 in
        help)           help ;;
        depend)         depend ;;
        build)          build ;;
        tripman)        tripman ;;
        trip)           trip ;;

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
