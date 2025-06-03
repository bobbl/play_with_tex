Play with TeX
=============

> Experiments with the original TeX source code from Donald E. Knuth

In CTAN [Don Knuth's source code for TeX](https://ctan.org/pkg/knuth-dist) can
be found. With the help of [Wolfgang Helbig's TeX-FPC package](https://ctan.org/pkg/tex-fpc)
it can be compiled with a current version of Free Pascal. Because it's not all
that simple, here are some instructions and POSIX shell scripts to download and
compile TeX on a UNIX platform that is supported py FPC.

The instructions in this README are not perfectly correct, but should give an
impression of the necessary steps. For the exact commands see the make script
`make.sh` with correct paths and automatic downloading of the CTAN packages and
other dependencies.



Quick compilation of the original TeX source code with Free Pascal
------------------------------------------------------------------

This is a short description how to compile TeX quickly without Metafont.
How to build Metafont and the metric fonts is described in the next section.
The steps for the quick compilation are executed by running the make script:

    ./make quick

### Step 1: Bootstraping TANGLE

Knuth's programs are written in [WEB](https://en.wikipedia.org/wiki/Web_(programming_system)).
To translate them to Pascal, his program TANGLE is used. TANGLE expects a change
file that describes the Pascal dialect that should be used. TeX-FPC provides
these change files for FPC.

However, TANGLE is written in WEB, so you need TANGLE to compile TANGLE.
Therefore, this repository not only contains the change file, but also the
translated FPC source code of TANGLE that can be compiled with

    fpc tangle.p

### Step 2: Compile TEX from tex.web

Use TANGLE and a change file to generate valid Free Pascal source code for TeX

    ./tangle tex.web tex.ch tex.p tex.pool

This generates not only the source code file `tex.p`, but also the string pool
file `tex.pool` that must be moved to `TeXformats/tex.pool`. Compile the source
code with FPC

    fpc tex.p

to obtain the regular version of TEX, sometimes called VIRTEX. For the
generation of `plain.fmt` in step 4, a special version called INITEX is
built by

    fpc -dinitex tex.p -oinitex

### Step 3: Download .tfm font files

TeX uses fonts in the Metafont format. To speed up compilation, the compiled
metric fonts can be downloaded from the CTAN packages
[cm-tfm](https://ctan.org/pkg/cm-tfm) and [manual](https://ctan.org/pkg/manual):

    wget "https://mirrors.ctan.org/fonts/cm/tfm.zip"
    wget "https://mirrors.ctan.org/fonts/manual.zip"

extract the files

    unzip tfm.zip
    unzip manual.zip

and copy the .tfm files to a new subdirectory `TeXfonts/`

### Step 4: Make plain.fmt

For Plain TeX some basic macros are required. They are stored as a memory dump
in `plain.fmt`. Without it TeX does not work as expected. To generate this
memory dump, a special version of TeX called INITEX is used. It was built in
step 2.
Copy `plain.tex` and `hyphen.tex` to the current directory and run INITEX:

    ./initex plain \\dump

Create a subdirectory `TeXformats/` and copy the generated `plain.fmt` to it.





Compile Metafont and the metric fonts
-------------------------------------

A complete POSIX shell script with all steps to build TeX and Metafont can be
found in the make script `make.sh` in function `full()`. Run it with

    ./make.sh full

Steps 1, 2 and 4 are the same as in the quick section above. Only step 3 is
more laborious:

### Step 3.1: Compile INIMF

INIMF is a special version of Metafont that is used to precompile the Metafont
macro base. The source code `mf.web` is from Knuth, the change file `inimf.ch`
from TeX-FPC.

    ./tangle mf.web inimf.ch inimf.p MFbases/mf.pool

TANGLE generates the FPC source code `inimf.p` and a file with the string pool
that must be put in the subdirectory `MFbases/`.
To compile the source code, some special parameters are required:

    fpc -Fasysutils,baseunix,unix initex.p

### Step 3.2: Make plain.base

Copy `plain.mf` from Knuth and `local.mf` to the current directory and run INIMF:

    ./inimf plain input

The resulting `plain.base` file must be copied to `MFbases/`.

### Step 3.3: Compile MF

Same as for INIMF, only the change file is slightly different

    ./tangle mf.web inimf.ch inimf.p MFbases/mf.pool
    fpc -Fasysutils,baseunix,unix initex.p

### Step 3.4: Make .tfm fonts from .mf files

Run MF on every .mf font file that should be converted to .tfm

    ./mf "\\mode=localfont; batchmode; input FONTNAME"

The .mf font files for the Computer Modern font can be found in the folder
`cm/` of Knuth's `dist` package. Additionally the font `lib/manfnt.mf` from
the same package must be installed. 
The CTAN Package [knuth-local](https://ctan.org/pkg/knuth-local)
contains additional optional fonts.

Copy the .tfm (*TeX font metric*) files to `TeXfonts/`. The other files can
be removed.






Convert to modern Pascal - tach
-------------------------------

The initial version of tach is a pretty printed version of `tex.p`:

    ptop -c ptop.cfg ../tex82/build/tex.p tach.pas

Translate from ISO Pascal to Free Pascal to enable modern language features
like e.g. string processing.

  - [x] Remove global GOTOs
  - [x] Replace GET/PUT file I/O by READ/WRITE
  - [x] Adjust size of integer and real datatypes, including rounding

Simplify code by using build-in string processing instead of Knuth's string pool
routines

  - [x] Integrate string pool in source code
  - [ ] Replace string pool indices by constant strings

Miscellaneous

  - [ ] Remove warnings
  - [ ] Remove all GOTOs
  - [ ] Reduce global variables
  - [ ] Use dynamic memory management for large arrays
  - [ ] Re-introduce /WEB/ constants in source code
  - [ ] Program argument instead of conditional compilation for /INITEX/

Long term ideas

  - UTF-8 instead of character translation tables
  - 
