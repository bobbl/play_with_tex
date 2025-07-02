#!/bin/sh
# tach, a TeX clone in pure Free Pascal


help() {
    echo "Usage: $0 <action> ..."
    echo
    echo "  build       Build tach, a TeX clone in modern Pascal"
    echo "  ref         Build reference DVIs with original TeX82"
    echo "  check       Check if tach output is identical to TeX82 reference"
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
        mv "from/$b.dvi" "to/$b.dvi"
        mv "from/$b.log" "to/$b.log"
    done
}



build() {
    mkdir -p build
    cd build
    ln -fs ../../tex82/build/TeXfonts
    mkdir -p TeXformats
    cp ../tex.pool TeXformats/
    cp ../tach.pas .

    fpc -dinitex tach.pas -oinitach
    fpc tach.pas

    cp ../../tex82/sources/dist/lib/plain.tex .
    cp ../../tex82/sources/dist/lib/hyphen.tex .

    #./initach plain \\dump
    echo "plain \\dump" | ./initach

    cp plain.fmt TeXformats/
    cd ..
}



check() {
    cd ref

    rm -f *.dvi *.log

    # links to additional files
    ln -fs ../build/TeXformats
    ln -fs ../../tex82/build/TeXfonts

    for f in from/*.tex
    do
        b=$(basename "$f" .tex)
        echo "$b"

        #../build/tach "$f" > tmp.tach.log # || cat tmp.tach.log
        #echo "&plain $f" | ../build/initach > tmp.tach.log # || cat tmp.tach.log
        echo "$f" | ../build/tach > tmp.tach.log # || cat tmp.tach.log

        diff $b.log to/$b.log

        #dvitype "from/$b.dvi" | head -n 30000 > tmp.a
        #dvitype "to/$b.dvi"   | head -n 30000 > tmp.b
        #meld tmp.a tmp.b

        #tail -c +43 "from/$b.dvi" | od -An -tx1 -w1 -v > tmp.a
        #tail -c +43 "to/$b.dvi"   | od -An -tx1 -w1 -v > tmp.b

        #dvitype "from/$b.dvi" > tmp.a
        #dvitype "to/$b.dvi"   > tmp.b

        tail -c +43 "$b.dvi" > tmp.a
        tail -c +43 "to/$b.dvi"   > tmp.b
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
