#!/bin/sh
# Compile TeX with Free Pascal


help() {
    echo "Usage: $0 <action> ..."
    echo
    echo "  quick       Compile only TeX"
    echo "  full        Compile tangle, Metafont, font files and TeX"
    echo "  tripman     Test by building the trip manual"
    echo "  trip        Run trip test"
    echo
    echo "  clean       Remove build files"
}

if [ $# -eq 0 ] 
then
    help
    exit 1
fi



# Check if a program is installed
# $1 program name
check_installation() {
    $1 -h > /dev/null \
        && echo "Found $1" \
        ||  { echo "Please install $1 (e.g sudo apt install $1)" ; exit 100 ; }
}



# Download CTAN package, if not already done
# $1 package path
# $1 package name
check_ctan() {
    cd sources
    if [ -d "$2" ]
    then
        echo "Found CTAN package '$1$2'"
    else
        echo "Downloading CTAN package '$1$2'"
        wget "https://mirrors.ctan.org/$1$2.zip"
        unzip "$2.zip"
    fi
    cd ..
}



# Build tangle from Pascal source, if necessary
make_tangle() {
    cd build
    if [ -f tangle ]
    then
        echo "Found tangle"
    else
        cp ../tangle.p .
        fpc tangle.p
        rm tangle.o tangle.p
    fi
    cd ..
}


# Use precompiled fonts to build TeX very quickly
quick() {
    check_ctan systems/knuth/ dist
        # Knuth's distribution
    check_installation fpc
        # Free Pascal Compiler
    check_ctan fonts/cm/ tfm
        # compiled metric fonts for Computer Modern
    check_ctan fonts/ manual
        # compiled metric fonts for extra symbols

    # Step 1: bootstrap tangle
    make_tangle

    # Step 2: compile tex.web to tex
    mkdir -p build
    cd build
    mkdir -p TeXformats
    ./tangle ../sources/dist/tex/tex.web ../sources/tex-fpc/unitex.ch \
        tex.p TeXformats/tex.pool
    fpc -Fasysutils,baseunix,unix tex.p

    # Step 3: copy metric font files
    mkdir -p TeXfonts
    cp ../sources/tfm/*.tfm TeXfonts/
    cp ../sources/manual/tfm/*.tfm TeXfonts/

    # Step 4: make plain.fmt with `tex -ini`
    cp ../sources/dist/lib/plain.tex .
    cp ../sources/dist/lib/hyphen.tex .
    ./tex -ini plain \\dump
    mv plain.fmt TeXformats/plain.fmt

    cd ..
}



# Build Metafont, metric fonts and TeX with the help of tex-fpc and fpc.
# Following the steps described by Wolfgang Helbig in tex-fpc/README
full() {
    check_ctan systems/knuth/ dist
        # Knuth's distribution
    #check_ctan systems/knuth/ local
        # additional fonts in knuth/local/cm/
    check_installation fpc
        # Free Pascal Compiler

    mkdir -p build
    cd build

    # Step 1: compile tangle.p
    cp ../sources/tex-fpc/tangle.p .
    fpc tangle.p

    # Step 2: compile tex.web to tex
    mkdir -p TeXformats
    ./tangle ../sources/dist/tex/tex.web ../sources/tex-fpc/unitex.ch \
        tex.p TeXformats/tex.pool
    fpc -Fasysutils,baseunix,unix tex.p

    # Step 3.1: compile mf.web to inimf
    mkdir -p MFbases
    ./tangle ../sources/dist/mf/mf.web ../sources/tex-fpc/inimf.ch \
        inimf.p MFbases/mf.pool
    fpc -Fasysutils,baseunix,unix inimf.p

    # Step 3.2: make plain.base
    cp ../sources/dist/lib/plain.mf .
    ./inimf plain input ../sources/local dump
    #mv plain.base MFbases/

    # Step 3.3: compile mf.web to mf
    ./tangle ../sources/dist/mf/mf.web ../sources/tex-fpc/mf.ch mf.p mf.pool
    fpc -Fasysutils,baseunix,unix mf.p

    # Step 3.4: install .tfm-fonts for plain.tex
    mkdir -p TeXfonts
    cd TeXfonts
    cp ../../sources/dist/cm/* .
    cp ../../sources/dist/lib/manfnt.mf .
    #cp ../../sources/local/cm/* . # additional fonts

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

    # Step 4: make plain.fmt with `tex -ini`
    cp ../sources/dist/lib/plain.tex .
    cp ../sources/dist/lib/hyphen.tex .
    ./tex -ini plain \\dump
    mv plain.fmt TeXformats/plain.fmt

    cd ..

}



# Build the trip manual with tex
tripman() {
    mkdir -p build_tripman
    cd build_tripman
    rm -rf *

    ln -s ../build/TeXformats
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



# Relaxed comparison between two files.
# Some lines in the logs can be different, even if the result is identical.
# Therefore remove these vague lines prior to the comparison.
# If the files still differ, print an error.
relaxed_compare() {

    e='/^This is /d
        / TeX output /d
        s/ (preloaded format=trip [.0-9]*/ (preloaded format=trip/
        s/[0-9]* strings of total length [0-9]*/9999 strings of total length 99999/
        s/[0-9]* strings out of [0-9]*/99 strings out of 9999/
        s/[0-9]* string characters out of [0-9]*/999 string characters out of 9999/'

    sed -e "$e" $1 > tmp.a
    sed -e "$e" $2 > tmp.b

    d=$(diff tmp.a tmp.b)
    if [ -z "$d" ]
    then
        echo "    +++ $1 IS CORRECT +++"
    else
        echo "ERROR: Differences between $1 and $2"
        echo "[[[ ----------------------------------"
        echo "$d"
        echo "]]] ----------------------------------"
    fi
}



# Run the trip test for TeX
trip() {
    mkdir -p build
    cd build

    # Step 1: check PLtoTF and TFtoPL and build trip.tfm
    # TODO: build PLtoTF and TFtoPL from .web sources
    cp ../sources/dist/tex/trip.pl .
    pltotf trip.pl trip.tfm
    tftopl trip.tfm tmp.pl
    relaxed_compare trip.pl tmp.pl

    # Step 2: build special TeX version
    ./tangle ../sources/dist/tex/tex.web ../sources/tex-fpc/triptex.ch triptex.p tex.pool > tmp.tangle
    fpc -Fasysutils,baseunix,unix triptex.p > tmp.fpc

    # Step 3: First run of TeX
    cp ../sources/dist/tex/trip.tex .
    cp ../sources/dist/tex/trip.tfm TeXfonts/
    printf "\n\\input trip\n" | ./triptex > tmp.trip1.stdout
    mv trip.log tripin.log
    relaxed_compare tripin.log ../sources/dist/tex/tripin.log

    # Step 4: Second run of TeX
    rm -f 8terminal.tex
    printf " &trip  trip\n" | ./triptex > trip.prefot
    sed -e 's/^\*\*(trip\.tex ##/\*\* \&trip  trip \
(trip.tex ##/' trip.prefot > trip.fot

    # Step 5: Relaxed comparison of logs
    relaxed_compare trip.log ../sources/dist/tex/trip.log
    relaxed_compare trip.fot ../sources/dist/tex/trip.fot
    [ -f 8terminal.tex ] \
        && echo "    +++ 8terminal.tex FOUND +++" \
        || echo "ERROR: 8terminal.tex is missing"

    # Step 5: Check .dvi output
    cp ../sources/dist/tex/trip.tfm .
        # dvitype expects trip.tfm in current dir, not TeXfonts/

    dvitype -output-level=2 -page-start='*.*.*.*.*.*.*.*.*.*' -dpi=72.27 trip.dvi > tmp.typ
    relaxed_compare tmp.typ ../sources/dist/tex/trip.typ

    cd ..
}



while [ $# -ne 0 ]
do
    case $1 in
        help)           help ;;
        quick)          quick ;;
        full)           full ;;
        tripman)        tripman ;;
        trip)           trip ;;

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
