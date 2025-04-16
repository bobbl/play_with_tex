#!/bin/sh
# tach, a TeX clone in pure Free Pascal


help() {
    echo "Usage: $0 <action> ..."
    echo
    echo "  ref         Build reference DVIs with original TeX82"
    echo
    echo "  clean       Remove build files"
}

if [ $# -eq 0 ] 
then
    help
    exit 1
fi




# Run the original tex on every file in ref/from/ and put the generated
# .dvi file in ref/to/
ref() {

    # make original TeX82
    cd ../tex82
    ./make.sh quick
    cd ../tach/ref

    # links to additional files
    ln -fs ../../tex82/build/TeXformats
    ln -fs ../../tex82/build/TeXfonts

    for f in from/*.tex
    do
        ../../tex82/build/tex "$f"
        b=$(basename "$f" .tex)
        mv "$b.dvi" "to/$b.dvi"
    done
}



build() {
    mkdir -p build
    cd build
    cp ../tach.p .
    fpc -Fasysutils,baseunix,unix tach.p
    cd ..
}



check() {
    cd ref

    # links to additional files
    ln -fs ../../tex82/build/TeXformats
    ln -fs ../../tex82/build/TeXfonts

    for f in from/*.tex
    do
        b=$(basename "$f" .tex)
        echo "$b"
        ../build/tach "$f" > /dev/null

        #tail -c +43 "$b.dvi"    | od -An -tx1 -w1 -v > tmp.a
        #tail -c +43 "to/$b.dvi" | od -An -tx1 -w1 -v > tmp.b
        tail -c +43 "$b.dvi"    > tmp.a
        tail -c +43 "to/$b.dvi" > tmp.b
        diff tmp.a tmp.b
    done

    cd ..
}



while [ $# -ne 0 ]
do
    case $1 in
        help)           help ;;

        ref)            ref ;;
        build)          build ;;
        check)          check ;;

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
