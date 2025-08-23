Play with TeX
=============

> Experiments with the original TeX source code from Donald E. Knuth



Table of Contents
-----------------

  * [Quick compilaton of TeX](#quick-compilation-of-tex)  
    Build the original TeX source code with minimal modifications.
    The Free Pascal compiler (FPC) and pre-compiled font files are used.

  * [Compile Metafont and the metric fonts](#compile-metafont-and-the-metric-fonts)  
    Instead of using the pre-compiled .tfm font files, build Metafont from
    Don Knuth's source code and compile the fonts from scratch.

  * [Convert to modern Pascal: tach](#tach-convert-to-modern-pascal-tach)  
    Combine the WEB source and the generated FPC source to a readable,
    well-formated FPC source file with self-explanatory identifiers, comments
    and modern language features 



Quick compilation of TeX
------------------------

In CTAN [Don Knuth's source code for TeX](https://ctan.org/pkg/knuth-dist) can
be found. [Wolfgang Helbig's TeX-FPC package](https://ctan.org/pkg/tex-fpc)
provides additional files to modify and compile the sources with a current
version of Free Pascal. However, the build process is not straightforward and
TeX-FPC adds some additional features that are not necessary.

So I decided to find a way to compile TeX with minimal changes and minimal
effort. It is a mixture of TeX-FPC and the
[instructions from Heiko Theissen with FPC for Windows](https://bitbucket.org/HeikoTheissen/tex/src/master/web/)

The instructions in this README should give an impression of the necessary
steps, but some details are omitted to increase readability. For the exact
commands see the make script `make.sh` with correct paths and automatic
downloading of the CTAN packages and other dependencies.

Following are the instructions to quickly compile without Metafont. How to
build Metafont and the metric fonts is described in the next section. The exact
steps are executed by running the make script with

    ./make.sh quick

### Step 1: Bootstraping TANGLE

Knuth's programs are written in [WEB](https://en.wikipedia.org/wiki/Web_(programming_system)).
To translate them to Pascal, his program TANGLE is used. TANGLE expects a change
file that describes the Pascal dialect that should be used.

However, TANGLE is written in WEB, so you need TANGLE and a change file to
compile TANGLE. Therefore, this repository not only contains the change file,
but also the translated FPC source code of TANGLE that can be compiled with

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

    wget https://mirrors.ctan.org/fonts/cm/tfm.zip
    wget https://mirrors.ctan.org/fonts/manual.zip
    wget https://mirrors.ctan.org/fonts/mflogo.zip

extract the files

    unzip tfm.zip
    unzip manual.zip
    unzip mflogo.zip

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

The metric fonts in the CTAN packages [cm-tfm](https://ctan.org/pkg/cm-tfm) and
[manual](https://ctan.org/pkg/manual) have the extension `.tfm` and are
compiled versions of the original Metafont source files with the extension
`.mf`. To compile them yourself, the Metafont program must be build from the
WEB sources.
A complete POSIX shell script with all steps to build TeX, Metafont and the
metric fonts can be found in the make script `make.sh`. Run it with

    ./make.sh full

Steps 1, 2 and 4 are the same as in the [quick section](#quick-compilation-of-tex)
above. Only step 3 is more laborious:

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






Convert to modern Pascal: tach
------------------------------

The initial version of tach is a pretty printed version of `tex.p`:

    ptop -c ptop.cfg ../tex82/build/tex.p tach.pas

Transfer additional information from WEB file into Pascal source

  - [ ] Transfer comments
  - [ ] Re-introduce named WEB constants
  - [ ] Reverse WEB macro expansion

Translate from ISO Pascal to Free Pascal to enable modern language features
like e.g. string processing.

  - [x] Remove global GOTOs
  - [x] Replace GET/PUT file I/O by READ/WRITE
  - [x] Adjust size of integer and real datatypes, including rounding

Simplify code by using build-in string processing instead of Knuth's string pool
routines

  - [x] Integrate string pool in source code
  - [ ] Replace string pool indices by constant strings
  - [ ] Replace printing procedures by functions that return strings
  - [x] Replace selector=new_string by string operations
  - [x] Replace selector=pseudo by string operations

File handling

  - [x] Only use byte-based files
  - [x] Avoid string pool and global variables for file name construction
  - [x] Simplify file name handling

Miscellaneous

  - [ ] Remove compiler warnings
  - [ ] Remove all GOTOs
  - [ ] Reduce global variables
  - [ ] Use dynamic memory management for large arrays
  - [ ] Program arguments instead of conditional compilation for INITEX
  - [ ] Split source code into modules

Long term ideas (breaking changes)

  - UTF-8 instead of character translation tables
  - Remove built-in debugging facilities
  - Remove interactive user interface in favour of program arguments and
    fatal errors
  - Uniform error messages
