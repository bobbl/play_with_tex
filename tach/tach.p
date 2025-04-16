{4:}{9:}{$MODE ISO}{$Q+}{$R+}{[$Q-][$R-]}{:9}

PROGRAM TEX(input,output);

LABEL {6:}1,9998,9999;{:6}

CONST {11:}memmax = 30000;
  memmin = 0;
  bufsize = 500;
  errorline = 72;
  halferrorline = 42;
  maxprintline = 79;
  stacksize = 200;
  maxinopen = 6;
  fontmax = 75;
  fontmemsize = 20000;
  paramsize = 60;
  nestsize = 40;
  maxstrings = 3000;
  stringvacancies = 8000;
  poolsize = 32000;
  savesize = 600;
  triesize = 8000;
  trieopsize = 500;
  dvibufsize = 800;
  filenamesize = 40;
  poolname = 'TeXformats/tex.pool';{:11}

TYPE {18:}ASCIIcode = 0..255;
{:18}{25:}
  eightbits = 0..255;
  alphafile = text;
  bytefile = packed file OF eightbits;
  untypedfile = file;
{:25}{38:}
  poolpointer = 0..poolsize;
  strnumber = 0..maxstrings;
  packedASCIIcode = 0..255;{:38}{101:}
  scaled = integer;
  nonnegativeinteger = 0..2147483647;
  smallnumber = 0..63;
{:101}{109:}
  glueratio = single;{:109}{113:}
  quarterword = 0..255;
  halfword = 0..65535;
  twochoices = 1..2;
  fourchoices = 1..4;
  twohalves = packed RECORD
    rh: halfword;
    CASE twochoices OF 
      1: (lh:halfword);
      2: (b0:quarterword;b1:quarterword);
  END;
  fourquarters = packed RECORD
    b0: quarterword;
    b1: quarterword;
    b2: quarterword;
    b3: quarterword;
  END;
  memoryword = RECORD
    CASE fourchoices OF 
      1: (int:integer);
      2: (gr:glueratio);
      3: (hh:twohalves);
      4: (qqqq:fourquarters);
  END;
  wordfile = file OF memoryword;
{:113}{150:}
  glueord = 0..3;
{:150}{212:}
  liststaterecord = RECORD
    modefield: -203..203;
    headfield,tailfield: halfword;
    pgfield,mlfield: integer;
    auxfield: memoryword;
  END;{:212}{269:}
  groupcode = 0..16;
{:269}{300:}
  instaterecord = RECORD
    statefield,indexfield: quarterword;
    startfield,locfield,limitfield,namefield: halfword;
  END;
{:300}{548:}
  internalfontnumber = 0..fontmax;
  fontindex = 0..fontmemsize;
{:548}{594:}
  dviindex = 0..dvibufsize;{:594}{920:}
  triepointer = 0..triesize;
{:920}{925:}
  hyphpointer = 0..307;{:925}

VAR {13:}bad: integer;
{:13}{20:}
  xord: array[char] OF ASCIIcode;
  xchr: array[ASCIIcode] OF char;
{:20}{26:}
  nameoffile: packed array[1..filenamesize] OF char;
  namelength: 0..filenamesize;
{:26}{30:}
  buffer: array[0..bufsize] OF ASCIIcode;
  first: 0..bufsize;
  last: 0..bufsize;
  maxbufstack: 0..bufsize;
{:30}{39:}
  strpool: packed array[poolpointer] OF packedASCIIcode;
  strstart: array[strnumber] OF poolpointer;
  poolptr: poolpointer;
  strptr: strnumber;
  initpoolptr: poolpointer;
  initstrptr: strnumber;
{:39}{50:}
  poolfile: alphafile;{:50}{54:}
  logfile: alphafile;
  selector: 0..21;
  dig: array[0..22] OF 0..15;
  tally: integer;
  termoffset: 0..maxprintline;
  fileoffset: 0..maxprintline;
  trickbuf: array[0..errorline] OF ASCIIcode;
  trickcount: integer;
  firstcount: integer;{:54}{73:}
  interaction: 0..3;
{:73}{76:}
  deletionsallowed: boolean;
  setboxallowed: boolean;
  history: 0..3;
  errorcount: -1..100;{:76}{79:}
  helpline: array[0..5] OF strnumber;
  helpptr: 0..6;
  useerrhelp: boolean;
  wantedit: boolean;
{:79}{96:}
  interrupt: integer;
  OKtointerrupt: boolean;
{:96}{104:}
  aritherror: boolean;
  remainder: scaled;
{:104}{115:}
  tempptr: halfword;
{:115}{116:}
  mem: array[memmin..memmax] OF memoryword;
  lomemmax: halfword;
  himemmin: halfword;{:116}{117:}
  varused,dynused: integer;
{:117}{118:}
  avail: halfword;
  memend: halfword;{:118}{124:}
  rover: halfword;
{:124}{165:}
{free:packed array[memmin..memmax]of boolean;
wasfree:packed array[memmin..memmax]of boolean;
wasmemend,waslomax,washimin:halfword;panicking:boolean;}
{:165}{173:}
  fontinshortdisplay: integer;
{:173}{181:}
  depththreshold: integer;
  breadthmax: integer;
{:181}{213:}
  nest: array[0..nestsize] OF liststaterecord;
  nestptr: 0..nestsize;
  maxneststack: 0..nestsize;
  curlist: liststaterecord;
  shownmode: -203..203;{:213}{246:}
  oldsetting: 0..21;
  systime,sysday,sysmonth,sysyear: integer;
{:246}{253:}
  eqtb: array[1..6106] OF memoryword;
  xeqlevel: array[5263..6106] OF quarterword;
{:253}{256:}
  hash: array[514..2880] OF twohalves;
  hashused: halfword;
  nonewcontrolsequence: boolean;
  cscount: integer;
{:256}{271:}
  savestack: array[0..savesize] OF memoryword;
  saveptr: 0..savesize;
  maxsavestack: 0..savesize;
  curlevel: quarterword;
  curgroup: groupcode;
  curboundary: 0..savesize;{:271}{286:}
  magset: integer;
{:286}{297:}
  curcmd: eightbits;
  curchr: halfword;
  curcs: halfword;
  curtok: halfword;
{:297}{301:}
  inputstack: array[0..stacksize] OF instaterecord;
  inputptr: 0..stacksize;
  maxinstack: 0..stacksize;
  curinput: instaterecord;
{:301}{304:}
  inopen: 0..maxinopen;
  openparens: 0..maxinopen;
  inputfile: array[1..maxinopen] OF alphafile;
  line: integer;
  linestack: array[1..maxinopen] OF integer;{:304}{305:}
  scannerstatus: 0..5;
  warningindex: halfword;
  defref: halfword;
{:305}{308:}
  paramstack: array[0..paramsize] OF halfword;
  paramptr: 0..paramsize;
  maxparamstack: integer;
{:308}{309:}
  alignstate: integer;{:309}{310:}
  baseptr: 0..stacksize;
{:310}{333:}
  parloc: halfword;
  partoken: halfword;
{:333}{361:}
  forceeof: boolean;{:361}{382:}
  curmark: array[0..4] OF halfword;
{:382}{387:}
  longstate: 111..114;
{:387}{388:}
  pstack: array[0..8] OF halfword;{:388}{410:}
  curval: integer;
  curvallevel: 0..5;{:410}{438:}
  radix: smallnumber;
{:438}{447:}
  curorder: glueord;
{:447}{480:}
  readfile: array[0..15] OF alphafile;
  readopen: array[0..16] OF 0..2;{:480}{489:}
  condptr: halfword;
  iflimit: 0..4;
  curif: smallnumber;
  ifline: integer;{:489}{493:}
  skipline: integer;
{:493}{512:}
  curname: strnumber;
  curarea: strnumber;
  curext: strnumber;
{:512}{513:}
  areadelimiter: poolpointer;
  extdelimiter: poolpointer;
{:513}{520:}
  TEXformatdefault: packed array[1..20] OF char;
{:520}{527:}
  nameinprogress: boolean;
  jobname: strnumber;
  logopened: boolean;
{:527}{532:}
  dvifile: bytefile;
  outputfilename: strnumber;
  logname: strnumber;
{:532}{539:}
  tfmfile: bytefile;
{:539}{549:}
  fontinfo: array[fontindex] OF memoryword;
  fmemptr: fontindex;
  fontptr: internalfontnumber;
  fontcheck: array[internalfontnumber] OF fourquarters;
  fontsize: array[internalfontnumber] OF scaled;
  fontdsize: array[internalfontnumber] OF scaled;
  fontparams: array[internalfontnumber] OF fontindex;
  fontname: array[internalfontnumber] OF strnumber;
  fontarea: array[internalfontnumber] OF strnumber;
  fontbc: array[internalfontnumber] OF eightbits;
  fontec: array[internalfontnumber] OF eightbits;
  fontglue: array[internalfontnumber] OF halfword;
  fontused: array[internalfontnumber] OF boolean;
  hyphenchar: array[internalfontnumber] OF integer;
  skewchar: array[internalfontnumber] OF integer;
  bcharlabel: array[internalfontnumber] OF fontindex;
  fontbchar: array[internalfontnumber] OF 0..256;
  fontfalsebchar: array[internalfontnumber] OF 0..256;
{:549}{550:}
  charbase: array[internalfontnumber] OF integer;
  widthbase: array[internalfontnumber] OF integer;
  heightbase: array[internalfontnumber] OF integer;
  depthbase: array[internalfontnumber] OF integer;
  italicbase: array[internalfontnumber] OF integer;
  ligkernbase: array[internalfontnumber] OF integer;
  kernbase: array[internalfontnumber] OF integer;
  extenbase: array[internalfontnumber] OF integer;
  parambase: array[internalfontnumber] OF integer;
{:550}{555:}
  nullcharacter: fourquarters;{:555}{592:}
  totalpages: integer;
  maxv: scaled;
  maxh: scaled;
  maxpush: integer;
  lastbop: integer;
  deadcycles: integer;
  doingleaders: boolean;
  c,f: quarterword;
  ruleht,ruledp,rulewd: scaled;
  g: halfword;
  lq,lr: integer;
{:592}{595:}
  dvibuf: array[dviindex] OF eightbits;
  halfbuf: dviindex;
  dvilimit: dviindex;
  dviptr: dviindex;
  dvioffset: integer;
  dvigone: integer;
{:595}{605:}
  downptr,rightptr: halfword;{:605}{616:}
  dvih,dviv: scaled;
  curh,curv: scaled;
  dvif: internalfontnumber;
  curs: integer;
{:616}{646:}
  totalstretch,totalshrink: array[glueord] OF scaled;
  lastbadness: integer;{:646}{647:}
  adjusttail: halfword;
{:647}{661:}
  packbeginline: integer;{:661}{684:}
  emptyfield: twohalves;
  nulldelimiter: fourquarters;{:684}{719:}
  curmlist: halfword;
  curstyle: smallnumber;
  cursize: smallnumber;
  curmu: scaled;
  mlistpenalties: boolean;{:719}{724:}
  curf: internalfontnumber;
  curc: quarterword;
  curi: fourquarters;{:724}{764:}
  magicoffset: integer;
{:764}{770:}
  curalign: halfword;
  curspan: halfword;
  curloop: halfword;
  alignptr: halfword;
  curhead,curtail: halfword;{:770}{814:}
  justbox: halfword;
{:814}{821:}
  passive: halfword;
  printednode: halfword;
  passnumber: halfword;
{:821}{823:}
  activewidth: array[1..6] OF scaled;
  curactivewidth: array[1..6] OF scaled;
  background: array[1..6] OF scaled;
  breakwidth: array[1..6] OF scaled;{:823}{825:}
  noshrinkerroryet: boolean;
{:825}{828:}
  curp: halfword;
  secondpass: boolean;
  finalpass: boolean;
  threshold: integer;{:828}{833:}
  minimaldemerits: array[0..3] OF integer;
  minimumdemerits: integer;
  bestplace: array[0..3] OF halfword;
  bestplline: array[0..3] OF halfword;{:833}{839:}
  discwidth: scaled;
{:839}{847:}
  easyline: halfword;
  lastspecialline: halfword;
  firstwidth: scaled;
  secondwidth: scaled;
  firstindent: scaled;
  secondindent: scaled;{:847}{872:}
  bestbet: halfword;
  fewestdemerits: integer;
  bestline: halfword;
  actuallooseness: integer;
  linediff: integer;
{:872}{892:}
  hc: array[0..65] OF 0..256;
  hn: 0..64;
  ha,hb: halfword;
  hf: internalfontnumber;
  hu: array[0..63] OF 0..256;
  hyfchar: integer;
  curlang,initcurlang: ASCIIcode;
  lhyf,rhyf,initlhyf,initrhyf: integer;
  hyfbchar: halfword;{:892}{900:}
  hyf: array[0..64] OF 0..9;
  initlist: halfword;
  initlig: boolean;
  initlft: boolean;{:900}{905:}
  hyphenpassed: smallnumber;
{:905}{907:}
  curl,curr: halfword;
  curq: halfword;
  ligstack: halfword;
  ligaturepresent: boolean;
  lfthit,rthit: boolean;
{:907}{921:}
  trie: array[triepointer] OF twohalves;
  hyfdistance: array[1..trieopsize] OF smallnumber;
  hyfnum: array[1..trieopsize] OF smallnumber;
  hyfnext: array[1..trieopsize] OF quarterword;
  opstart: array[ASCIIcode] OF 0..trieopsize;
{:921}{926:}
  hyphword: array[hyphpointer] OF strnumber;
  hyphlist: array[hyphpointer] OF halfword;
  hyphcount: hyphpointer;
{:926}{943:}
  trieophash: array[-trieopsize..trieopsize] OF 0..trieopsize;
  trieused: array[ASCIIcode] OF quarterword;
  trieoplang: array[1..trieopsize] OF ASCIIcode;
  trieopval: array[1..trieopsize] OF quarterword;
  trieopptr: 0..trieopsize;
{:943}{947:}
  triec: packed array[triepointer] OF packedASCIIcode;
  trieo: packed array[triepointer] OF quarterword;
  triel: packed array[triepointer] OF triepointer;
  trier: packed array[triepointer] OF triepointer;
  trieptr: triepointer;
  triehash: packed array[triepointer] OF triepointer;
{:947}{950:}
  trietaken: packed array[1..triesize] OF boolean;
  triemin: array[ASCIIcode] OF triepointer;
  triemax: triepointer;
  trienotready: boolean;{:950}{971:}
  bestheightplusdepth: scaled;
{:971}{980:}
  pagetail: halfword;
  pagecontents: 0..2;
  pagemaxdepth: scaled;
  bestpagebreak: halfword;
  leastpagecost: integer;
  bestsize: scaled;
{:980}{982:}
  pagesofar: array[0..7] OF scaled;
  lastglue: halfword;
  lastpenalty: integer;
  lastkern: scaled;
  insertpenalties: integer;
{:982}{989:}
  outputactive: boolean;{:989}{1032:}
  mainf: internalfontnumber;
  maini: fourquarters;
  mainj: fourquarters;
  maink: fontindex;
  mainp: halfword;
  mains: integer;
  bchar: halfword;
  falsebchar: halfword;
  cancelboundary: boolean;
  insdisc: boolean;{:1032}{1074:}
  curbox: halfword;
{:1074}{1266:}
  aftertoken: halfword;{:1266}{1281:}
  longhelpseen: boolean;
{:1281}{1299:}
  formatident: strnumber;{:1299}{1305:}
  fmtfile: wordfile;
{:1305}{1331:}
  readyalready: integer;
{:1331}{1342:}
  writefile: array[0..15] OF alphafile;
  writeopen: array[0..17] OF boolean;{:1342}{1345:}
  writeloc: halfword;
{:1345}{1383:}
  TeXVariation: 0..2;
  FirstArg: shortstring;
{:1383}
PROCEDURE catchsignal(i:integer);
interrupt forward;
PROCEDURE initialize;

VAR {19:}i: integer;{:19}{163:}
  k: integer;
{:163}{927:}
  z: hyphpointer;{:927}
BEGIN{8:}{21:}
  xchr[32] := ' ';
  xchr[33] := '!';
  xchr[34] := '"';
  xchr[35] := '#';
  xchr[36] := '$';
  xchr[37] := '%';
  xchr[38] := '&';
  xchr[39] := '''';
  xchr[40] := '(';
  xchr[41] := ')';
  xchr[42] := '*';
  xchr[43] := '+';
  xchr[44] := ',';
  xchr[45] := '-';
  xchr[46] := '.';
  xchr[47] := '/';
  xchr[48] := '0';
  xchr[49] := '1';
  xchr[50] := '2';
  xchr[51] := '3';
  xchr[52] := '4';
  xchr[53] := '5';
  xchr[54] := '6';
  xchr[55] := '7';
  xchr[56] := '8';
  xchr[57] := '9';
  xchr[58] := ':';
  xchr[59] := ';';
  xchr[60] := '<';
  xchr[61] := '=';
  xchr[62] := '>';
  xchr[63] := '?';
  xchr[64] := '@';
  xchr[65] := 'A';
  xchr[66] := 'B';
  xchr[67] := 'C';
  xchr[68] := 'D';
  xchr[69] := 'E';
  xchr[70] := 'F';
  xchr[71] := 'G';
  xchr[72] := 'H';
  xchr[73] := 'I';
  xchr[74] := 'J';
  xchr[75] := 'K';
  xchr[76] := 'L';
  xchr[77] := 'M';
  xchr[78] := 'N';
  xchr[79] := 'O';
  xchr[80] := 'P';
  xchr[81] := 'Q';
  xchr[82] := 'R';
  xchr[83] := 'S';
  xchr[84] := 'T';
  xchr[85] := 'U';
  xchr[86] := 'V';
  xchr[87] := 'W';
  xchr[88] := 'X';
  xchr[89] := 'Y';
  xchr[90] := 'Z';
  xchr[91] := '[';
  xchr[92] := '\';
  xchr[93] := ']';
  xchr[94] := '^';
  xchr[95] := '_';
  xchr[96] := '`';
  xchr[97] := 'a';
  xchr[98] := 'b';
  xchr[99] := 'c';
  xchr[100] := 'd';
  xchr[101] := 'e';
  xchr[102] := 'f';
  xchr[103] := 'g';
  xchr[104] := 'h';
  xchr[105] := 'i';
  xchr[106] := 'j';
  xchr[107] := 'k';
  xchr[108] := 'l';
  xchr[109] := 'm';
  xchr[110] := 'n';
  xchr[111] := 'o';
  xchr[112] := 'p';
  xchr[113] := 'q';
  xchr[114] := 'r';
  xchr[115] := 's';
  xchr[116] := 't';
  xchr[117] := 'u';
  xchr[118] := 'v';
  xchr[119] := 'w';
  xchr[120] := 'x';
  xchr[121] := 'y';
  xchr[122] := 'z';
  xchr[123] := '{';
  xchr[124] := '|';
  xchr[125] := '}';
  xchr[126] := '~';{:21}{23:}
  FOR i:=0 TO 31 DO
    xchr[i] := ' ';
  xchr[9] := chr(9);
  xchr[12] := chr(12);
  FOR i:=127 TO 255 DO
    xchr[i] := ' ';
{:23}{24:}
  FOR i:=0 TO 255 DO
    xord[chr(i)] := 127;
  FOR i:=128 TO 255 DO
    xord[xchr[i]] := i;
  FOR i:=0 TO 126 DO
    xord[xchr[i]] := i;{:24}{74:}
  interaction := 3;
{:74}{77:}
  deletionsallowed := true;
  setboxallowed := true;
  errorcount := 0;
{:77}{80:}
  helpptr := 0;
  useerrhelp := false;
  wantedit := false;
{:80}{97:}
  interrupt := 0;
  OKtointerrupt := true;
{:97}{166:}{wasmemend:=memmin;waslomax:=memmin;washimin:=memmax;
panicking:=false;}{:166}{215:}
  nestptr := 0;
  maxneststack := 0;
  curlist.modefield := 1;
  curlist.headfield := 29999;
  curlist.tailfield := 29999;
  curlist.auxfield.int := -65536000;
  curlist.mlfield := 0;
  curlist.pgfield := 0;
  shownmode := 0;{991:}
  pagecontents := 0;
  pagetail := 29998;
  mem[29998].hh.rh := 0;
  lastglue := 65535;
  lastpenalty := 0;
  lastkern := 0;
  pagesofar[7] := 0;
  pagemaxdepth := 0{:991};{:215}{254:}
  FOR k:=5263 TO 6106 DO
    xeqlevel[k] := 1;
{:254}{257:}
  nonewcontrolsequence := true;
  hash[514].lh := 0;
  hash[514].rh := 0;
  FOR k:=515 TO 2880 DO
    hash[k] := hash[514];{:257}{272:}
  saveptr := 0;
  curlevel := 1;
  curgroup := 0;
  curboundary := 0;
  maxsavestack := 0;
{:272}{287:}
  magset := 0;{:287}{383:}
  curmark[0] := 0;
  curmark[1] := 0;
  curmark[2] := 0;
  curmark[3] := 0;
  curmark[4] := 0;{:383}{439:}
  curval := 0;
  curvallevel := 0;
  radix := 0;
  curorder := 0;
{:439}{481:}
  FOR k:=0 TO 16 DO
    readopen[k] := 2;{:481}{490:}
  condptr := 0;
  iflimit := 0;
  curif := 0;
  ifline := 0;
{:490}{521:}
  TEXformatdefault := 'TeXformats/plain.fmt';
{:521}{551:}
  FOR k:=0 TO fontmax DO
    fontused[k] := false;
{:551}{556:}
  nullcharacter.b0 := 0;
  nullcharacter.b1 := 0;
  nullcharacter.b2 := 0;
  nullcharacter.b3 := 0;{:556}{593:}
  totalpages := 0;
  maxv := 0;
  maxh := 0;
  maxpush := 0;
  lastbop := -1;
  doingleaders := false;
  deadcycles := 0;
  curs := -1;
{:593}{596:}
  halfbuf := dvibufsize DIV 2;
  dvilimit := dvibufsize;
  dviptr := 0;
  dvioffset := 0;
  dvigone := 0;{:596}{606:}
  downptr := 0;
  rightptr := 0;
{:606}{648:}
  adjusttail := 0;
  lastbadness := 0;{:648}{662:}
  packbeginline := 0;
{:662}{685:}
  emptyfield.rh := 0;
  emptyfield.lh := 0;
  nulldelimiter.b0 := 0;
  nulldelimiter.b1 := 0;
  nulldelimiter.b2 := 0;
  nulldelimiter.b3 := 0;
{:685}{771:}
  alignptr := 0;
  curalign := 0;
  curspan := 0;
  curloop := 0;
  curhead := 0;
  curtail := 0;{:771}{928:}
  FOR z:=0 TO 307 DO
    BEGIN
      hyphword[z] := 0;
      hyphlist[z] := 0;
    END;
  hyphcount := 0;{:928}{990:}
  outputactive := false;
  insertpenalties := 0;{:990}{1033:}
  ligaturepresent := false;
  cancelboundary := false;
  lfthit := false;
  rthit := false;
  insdisc := false;
{:1033}{1267:}
  aftertoken := 0;{:1267}{1282:}
  longhelpseen := false;
{:1282}{1300:}
  formatident := 0;
{:1300}{1343:}
  FOR k:=0 TO 17 DO
    writeopen[k] := false;
{:1343}{1381:}
  fpsignal(SIGINT,signalhandler(catchsignal));
  IF fpgeterrno<>0 THEN writeln('Could not install signal handler:',
                                fpgeterrno);{:1381}
  IF paramcount>0 THEN
    BEGIN
      FirstArg := paramstr(1);
      IF FirstArg='-ini'THEN
        BEGIN
          TeXVariation := 1;
          writeln('INITEX detected');
        END
      ELSE IF FirstArg='-trip'THEN
             BEGIN
               writeln('TRIPTEX detected');
               TeXVariation := 2;
             END
      ELSE
        BEGIN
          writeln('TEX detected:',FirstArg);
          TeXVariation := 0;
        END;
    END
  ELSE
    BEGIN
      writeln('TEX without args detected');
      TeXVariation := 0;
    END;
  IF TeXVariation>0 THEN
    BEGIN{164:}
      FOR k:=1 TO 19 DO
        mem[k].int := 0;
      k := 0;
      WHILE k<=19 DO
        BEGIN
          mem[k].hh.rh := 1;
          mem[k].hh.b0 := 0;
          mem[k].hh.b1 := 0;
          k := k+4;
        END;
      mem[6].int := 65536;
      mem[4].hh.b0 := 1;
      mem[10].int := 65536;
      mem[8].hh.b0 := 2;
      mem[14].int := 65536;
      mem[12].hh.b0 := 1;
      mem[15].int := 65536;
      mem[12].hh.b1 := 1;
      mem[18].int := -65536;
      mem[16].hh.b0 := 1;
      rover := 20;
      mem[rover].hh.rh := 65535;
      mem[rover].hh.lh := 1000;
      mem[rover+1].hh.lh := rover;
      mem[rover+1].hh.rh := rover;
      lomemmax := rover+1000;
      mem[lomemmax].hh.rh := 0;
      mem[lomemmax].hh.lh := 0;
      FOR k:=29987 TO 30000 DO
        mem[k] := mem[lomemmax];
{790:}
      mem[29990].hh.lh := 6714;{:790}{797:}
      mem[29991].hh.rh := 256;
      mem[29991].hh.lh := 0;{:797}{820:}
      mem[29993].hh.b0 := 1;
      mem[29994].hh.lh := 65535;
      mem[29993].hh.b1 := 0;
{:820}{981:}
      mem[30000].hh.b1 := 255;
      mem[30000].hh.b0 := 1;
      mem[30000].hh.rh := 30000;{:981}{988:}
      mem[29998].hh.b0 := 10;
      mem[29998].hh.b1 := 0;{:988};
      avail := 0;
      memend := 30000;
      himemmin := 29987;
      varused := 20;
      dynused := 14;{:164}{222:}
      eqtb[2881].hh.b0 := 101;
      eqtb[2881].hh.rh := 0;
      eqtb[2881].hh.b1 := 0;
      FOR k:=1 TO 2880 DO
        eqtb[k] := eqtb[2881];{:222}{228:}
      eqtb[2882].hh.rh := 0;
      eqtb[2882].hh.b1 := 1;
      eqtb[2882].hh.b0 := 117;
      FOR k:=2883 TO 3411 DO
        eqtb[k] := eqtb[2882];
      mem[0].hh.rh := mem[0].hh.rh+530;{:228}{232:}
      eqtb[3412].hh.rh := 0;
      eqtb[3412].hh.b0 := 118;
      eqtb[3412].hh.b1 := 1;
      FOR k:=3413 TO 3677 DO
        eqtb[k] := eqtb[2881];
      eqtb[3678].hh.rh := 0;
      eqtb[3678].hh.b0 := 119;
      eqtb[3678].hh.b1 := 1;
      FOR k:=3679 TO 3933 DO
        eqtb[k] := eqtb[3678];
      eqtb[3934].hh.rh := 0;
      eqtb[3934].hh.b0 := 120;
      eqtb[3934].hh.b1 := 1;
      FOR k:=3935 TO 3982 DO
        eqtb[k] := eqtb[3934];
      eqtb[3983].hh.rh := 0;
      eqtb[3983].hh.b0 := 120;
      eqtb[3983].hh.b1 := 1;
      FOR k:=3984 TO 5262 DO
        eqtb[k] := eqtb[3983];
      FOR k:=0 TO 255 DO
        BEGIN
          eqtb[3983+k].hh.rh := 12;
          eqtb[5007+k].hh.rh := k;
          eqtb[4751+k].hh.rh := 1000;
        END;
      eqtb[3996].hh.rh := 5;
      eqtb[4015].hh.rh := 10;
      eqtb[4075].hh.rh := 0;
      eqtb[4020].hh.rh := 14;
      eqtb[4110].hh.rh := 15;
      eqtb[3983].hh.rh := 9;
      FOR k:=48 TO 57 DO
        eqtb[5007+k].hh.rh := k+28672;
      FOR k:=65 TO 90 DO
        BEGIN
          eqtb[3983+k].hh.rh := 11;
          eqtb[3983+k+32].hh.rh := 11;
          eqtb[5007+k].hh.rh := k+28928;
          eqtb[5007+k+32].hh.rh := k+28960;
          eqtb[4239+k].hh.rh := k+32;
          eqtb[4239+k+32].hh.rh := k+32;
          eqtb[4495+k].hh.rh := k;
          eqtb[4495+k+32].hh.rh := k;
          eqtb[4751+k].hh.rh := 999;
        END;
{:232}{240:}
      FOR k:=5263 TO 5573 DO
        eqtb[k].int := 0;
      eqtb[5280].int := 1000;
      eqtb[5264].int := 10000;
      eqtb[5304].int := 1;
      eqtb[5303].int := 25;
      eqtb[5308].int := 92;
      eqtb[5311].int := 13;
      FOR k:=0 TO 255 DO
        eqtb[5574+k].int := -1;
      eqtb[5620].int := 0;
{:240}{250:}
      FOR k:=5830 TO 6106 DO
        eqtb[k].int := 0;
{:250}{258:}
      hashused := 2614;
      cscount := 0;
      eqtb[2623].hh.b0 := 116;
      hash[2623].rh := 502;{:258}{552:}
      fontptr := 0;
      fmemptr := 7;
      fontname[0] := 802;
      fontarea[0] := 338;
      hyphenchar[0] := 45;
      skewchar[0] := -1;
      bcharlabel[0] := 0;
      fontbchar[0] := 256;
      fontfalsebchar[0] := 256;
      fontbc[0] := 1;
      fontec[0] := 0;
      fontsize[0] := 0;
      fontdsize[0] := 0;
      charbase[0] := 0;
      widthbase[0] := 0;
      heightbase[0] := 0;
      depthbase[0] := 0;
      italicbase[0] := 0;
      ligkernbase[0] := 0;
      kernbase[0] := 0;
      extenbase[0] := 0;
      fontglue[0] := 0;
      fontparams[0] := 7;
      parambase[0] := -1;
      FOR k:=0 TO 6 DO
        fontinfo[k].int := 0;
{:552}{946:}
      FOR k:=-trieopsize TO trieopsize DO
        trieophash[k] := 0;
      FOR k:=0 TO 255 DO
        trieused[k] := 0;
      trieopptr := 0;
{:946}{951:}
      trienotready := true;
      triel[0] := 0;
      triec[0] := 0;
      trieptr := 0;
{:951}{1216:}
      hash[2614].rh := 1191;{:1216}{1301:}
      formatident := 1258;
{:1301}{1369:}
      hash[2622].rh := 1297;
      eqtb[2622].hh.b1 := 1;
      eqtb[2622].hh.b0 := 113;
      eqtb[2622].hh.rh := 0;{:1369}
    END;{:8}
END;
{57:}
PROCEDURE println;
BEGIN
  CASE selector OF 
    19:
        BEGIN
          writeln(output);
          writeln(logfile);
          termoffset := 0;
          fileoffset := 0;
        END;
    18:
        BEGIN
          writeln(logfile);
          fileoffset := 0;
        END;
    17:
        BEGIN
          writeln(output);
          termoffset := 0;
        END;
    16,20,21:;
    ELSE writeln(writefile[selector])
  END;
END;
{:57}{58:}
PROCEDURE printchar(s:ASCIIcode);

LABEL 10;
BEGIN
  IF {244:}s=eqtb[5312].int{:244}THEN IF selector<20 THEN
                                        BEGIN
                                          println;
                                          goto 10;
                                        END;
  CASE selector OF 
    19:
        BEGIN
          write(output,xchr[s]);
          write(logfile,xchr[s]);
          termoffset := termoffset+1;
          fileoffset := fileoffset+1;
          IF termoffset=maxprintline THEN
            BEGIN
              writeln(output);
              termoffset := 0;
            END;
          IF fileoffset=maxprintline THEN
            BEGIN
              writeln(logfile);
              fileoffset := 0;
            END;
        END;
    18:
        BEGIN
          write(logfile,xchr[s]);
          fileoffset := fileoffset+1;
          IF fileoffset=maxprintline THEN println;
        END;
    17:
        BEGIN
          write(output,xchr[s]);
          termoffset := termoffset+1;
          IF termoffset=maxprintline THEN println;
        END;
    16:;
    20: IF tally<trickcount THEN trickbuf[tally mod errorline] := s;
    21:
        BEGIN
          IF poolptr<poolsize THEN
            BEGIN
              strpool[poolptr] := s;
              poolptr := poolptr+1;
            END;
        END;
    ELSE write(writefile[selector],xchr[s])
  END;
  tally := tally+1;
  10:
END;{:58}{59:}
PROCEDURE print(s:integer);

LABEL 10;

VAR j: poolpointer;
  nl: integer;
BEGIN
  IF s>=strptr THEN s := 259
  ELSE IF s<256 THEN IF s<0 THEN s := 259
  ELSE
    BEGIN
      IF selector>20 THEN
        BEGIN
          printchar(s);
          goto 10;
        END;
      IF ({244:}s=eqtb[5312].int{:244})THEN IF selector<20 THEN
                                              BEGIN
                                                println;
                                                goto 10;
                                              END;
      nl := eqtb[5312].int;
      eqtb[5312].int := -1;
      j := strstart[s];
      WHILE j<strstart[s+1] DO
        BEGIN
          printchar(strpool[j]);
          j := j+1;
        END;
      eqtb[5312].int := nl;
      goto 10;
    END;
  j := strstart[s];
  WHILE j<strstart[s+1] DO
    BEGIN
      printchar(strpool[j]);
      j := j+1;
    END;
  10:
END;
{:59}{60:}
PROCEDURE slowprint(s:integer);

VAR j: poolpointer;
BEGIN
  IF (s>=strptr)OR(s<256)THEN print(s)
  ELSE
    BEGIN
      j := strstart[s];
      WHILE j<strstart[s+1] DO
        BEGIN
          print(strpool[j]);
          j := j+1;
        END;
    END;
END;
{:60}{62:}
PROCEDURE printnl(s:strnumber);
BEGIN
  IF ((termoffset>0)AND(odd(selector)))OR((fileoffset>0)AND(selector
     >=18))THEN println;
  print(s);
END;
{:62}{63:}
PROCEDURE printesc(s:strnumber);

VAR c: integer;
BEGIN{243:}
  c := eqtb[5308].int{:243};
  IF c>=0 THEN IF c<256 THEN print(c);
  slowprint(s);
END;{:63}{64:}
PROCEDURE printthedigs(k:eightbits);
BEGIN
  WHILE k>0 DO
    BEGIN
      k := k-1;
      IF dig[k]<10 THEN printchar(48+dig[k])
      ELSE printchar(55+dig[k]);
    END;
END;
{:64}{65:}
PROCEDURE printint(n:integer);

VAR k: 0..23;
  m: integer;
BEGIN
  k := 0;
  IF n<0 THEN
    BEGIN
      printchar(45);
      IF n>-100000000 THEN n := -n
      ELSE
        BEGIN
          m := -1-n;
          n := m DIV 10;
          m := (m MOD 10)+1;
          k := 1;
          IF m<10 THEN dig[0] := m
          ELSE
            BEGIN
              dig[0] := 0;
              n := n+1;
            END;
        END;
    END;
  REPEAT
    dig[k] := n MOD 10;
    n := n DIV 10;
    k := k+1;
  UNTIL n=0;
  printthedigs(k);
END;{:65}{262:}
PROCEDURE printcs(p:integer);
BEGIN
  IF p<514 THEN IF p>=257 THEN IF p=513 THEN
                                 BEGIN
                                   printesc(504);
                                   printesc(505);
                                   printchar(32);
                                 END
  ELSE
    BEGIN
      printesc(p-257);
      IF eqtb[3983+p-257].hh.rh=11 THEN printchar(32);
    END
  ELSE IF p<1 THEN printesc(506)
  ELSE print(p-1)
  ELSE IF p>=2881 THEN
         printesc(506)
  ELSE IF (hash[p].rh<0)OR(hash[p].rh>=strptr)THEN printesc(
                                                            507)
  ELSE
    BEGIN
      printesc(hash[p].rh);
      printchar(32);
    END;
END;
{:262}{263:}
PROCEDURE sprintcs(p:halfword);
BEGIN
  IF p<514 THEN IF p<257 THEN print(p-1)
  ELSE IF p<513 THEN printesc(
                              p-257)
  ELSE
    BEGIN
      printesc(504);
      printesc(505);
    END
  ELSE printesc(hash[p].rh);
END;
{:263}{518:}
PROCEDURE printfilename(n,a,e:integer);
BEGIN
  slowprint(a);
  slowprint(n);
  slowprint(e);
END;
{:518}{699:}
PROCEDURE printsize(s:integer);
BEGIN
  IF s=0 THEN printesc(412)
  ELSE IF s=16 THEN printesc(413)
  ELSE
    printesc(414);
END;{:699}{1355:}
PROCEDURE printwritewhatsit(s:strnumber;
                            p:halfword);
BEGIN
  printesc(s);
  IF mem[p+1].hh.lh<16 THEN printint(mem[p+1].hh.lh)
  ELSE IF mem[p+1].hh.lh
          =16 THEN printchar(42)
  ELSE printchar(45);
END;
{:1355}{78:}
PROCEDURE normalizeselector;
forward;
PROCEDURE gettoken;
forward;
PROCEDURE terminput;
forward;
PROCEDURE showcontext;
forward;
PROCEDURE beginfilereading;
forward;
PROCEDURE openlogfile;
forward;
PROCEDURE closefilesandterminate;
forward;
PROCEDURE clearforerrorprompt;
forward;
PROCEDURE giveerrhelp;
forward;{procedure debughelp;forward;}
{:78}{81:}
PROCEDURE jumpout;
BEGIN
  goto 9998;
END;
{:81}{82:}
PROCEDURE error;

LABEL 22,10;

VAR c: ASCIIcode;
  s1,s2,s3,s4: integer;
BEGIN
  IF history<2 THEN history := 2;
  printchar(46);
  showcontext;
  IF interaction=3 THEN{83:}WHILE true DO
                              BEGIN
                                22: IF interaction<>3 THEN
                                      goto 10;
                                clearforerrorprompt;
                                BEGIN;
                                  print(264);
                                  terminput;
                                END;
                                IF last=first THEN goto 10;
                                c := buffer[first];
                                IF c>=97 THEN c := c-32;
{84:}
                                CASE c OF 
                                  48,49,50,51,52,53,54,55,56,57: IF deletionsallowed THEN
{88:}
                                                                   BEGIN
                                                                     s1 := curtok;
                                                                     s2 := curcmd;
                                                                     s3 := curchr;
                                                                     s4 := alignstate;
                                                                     alignstate := 1000000;
                                                                     OKtointerrupt := false;
                                                                     IF (last>first+1)AND(buffer[
                                                                        first+1]>=48)AND(buffer[
                                                                        first+1]<=57)THEN c := 
                                                                                               c*10+
                                                                                              buffer
                                                                                               [
                                                                                               first
                                                                                               +1]-
                                                                                               48*11
                                                                     ELSE c := c-48;
                                                                     WHILE c>0 DO
                                                                       BEGIN
                                                                         gettoken;
                                                                         c := c-1;
                                                                       END;
                                                                     curtok := s1;
                                                                     curcmd := s2;
                                                                     curchr := s3;
                                                                     alignstate := s4;
                                                                     OKtointerrupt := true;
                                                                     BEGIN
                                                                       helpptr := 2;
                                                                       helpline[1] := 279;
                                                                       helpline[0] := 280;
                                                                     END;
                                                                     showcontext;
                                                                     goto 22;
                                                                   END{:88};
                                  {68:begin debughelp;goto 22;end;}
                                  69: IF baseptr>0 THEN IF inputstack[baseptr].namefield>=256 THEN
                                                          BEGIN
                                                            printnl(265);
                                                            slowprint(inputstack[baseptr].namefield)
                                                            ;
                                                            print(266);
                                                            printint(line);
                                                            interaction := 2;
                                                            wantedit := true;
                                                            jumpout;
                                                          END;
                                  72:{89:}
                                      BEGIN
                                        IF useerrhelp THEN
                                          BEGIN
                                            giveerrhelp;
                                            useerrhelp := false;
                                          END
                                        ELSE
                                          BEGIN
                                            IF helpptr=0 THEN
                                              BEGIN
                                                helpptr := 2;
                                                helpline[1] := 281;
                                                helpline[0] := 282;
                                              END;
                                            REPEAT
                                              helpptr := helpptr-1;
                                              print(helpline[helpptr]);
                                              println;
                                            UNTIL helpptr=0;
                                          END;
                                        BEGIN
                                          helpptr := 4;
                                          helpline[3] := 283;
                                          helpline[2] := 282;
                                          helpline[1] := 284;
                                          helpline[0] := 285;
                                        END;
                                        goto 22;
                                      END{:89};
                                  73:{87:}
                                      BEGIN
                                        beginfilereading;
                                        IF last>first+1 THEN
                                          BEGIN
                                            curinput.locfield := first+1;
                                            buffer[first] := 32;
                                          END
                                        ELSE
                                          BEGIN
                                            BEGIN;
                                              print(278);
                                              terminput;
                                            END;
                                            curinput.locfield := first;
                                          END;
                                        first := last;
                                        curinput.limitfield := last-1;
                                        goto 10;
                                      END{:87};
                                  81,82,83:{86:}
                                            BEGIN
                                              errorcount := 0;
                                              interaction := 0+c-81;
                                              print(273);
                                              CASE c OF 
                                                81: printesc(274);
                                                82: printesc(275);
                                                83: printesc(276);
                                              END;
                                              print(277);
                                              println;
                                              flush(output);
                                              IF c=81 THEN selector := selector-1;
                                              goto 10;
                                            END{:86};
                                  88:
                                      BEGIN
                                        interaction := 2;
                                        jumpout;
                                      END;
                                  ELSE
                                END;
{85:}
                                BEGIN
                                  print(267);
                                  printnl(268);
                                  printnl(269);
                                  IF baseptr>0 THEN IF inputstack[baseptr].namefield>=256 THEN print
                                                      (270);
                                  IF deletionsallowed THEN printnl(271);
                                  printnl(272);
                                END{:85}{:84};
                              END{:83};
  errorcount := errorcount+1;
  IF errorcount=100 THEN
    BEGIN
      printnl(263);
      history := 3;
      jumpout;
    END;
{90:}
  IF interaction>0 THEN selector := selector-1;
  IF useerrhelp THEN
    BEGIN
      println;
      giveerrhelp;
    END
  ELSE WHILE helpptr>0 DO
         BEGIN
           helpptr := helpptr-1;
           printnl(helpline[helpptr]);
         END;
  println;
  IF interaction>0 THEN selector := selector+1;
  println{:90};
  10:
END;
{:82}{93:}
PROCEDURE fatalerror(s:strnumber);
BEGIN
  normalizeselector;
  BEGIN
    IF interaction=3 THEN;
    printnl(262);
    print(287);
  END;
  BEGIN
    helpptr := 1;
    helpline[0] := s;
  END;
  BEGIN
    IF interaction=3 THEN interaction := 2;
    IF logopened THEN error;
{if interaction>0 then debughelp;}
    history := 3;
    jumpout;
  END;
END;
{:93}{94:}
PROCEDURE overflow(s:strnumber;n:integer);
BEGIN
  normalizeselector;
  BEGIN
    IF interaction=3 THEN;
    printnl(262);
    print(288);
  END;
  print(s);
  printchar(61);
  printint(n);
  printchar(93);
  BEGIN
    helpptr := 2;
    helpline[1] := 289;
    helpline[0] := 290;
  END;
  BEGIN
    IF interaction=3 THEN interaction := 2;
    IF logopened THEN error;
{if interaction>0 then debughelp;}
    history := 3;
    jumpout;
  END;
END;
{:94}{95:}
PROCEDURE confusion(s:strnumber);
BEGIN
  normalizeselector;
  IF history<2 THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(291);
      END;
      print(s);
      printchar(41);
      BEGIN
        helpptr := 1;
        helpline[0] := 292;
      END;
    END
  ELSE
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(293);
      END;
      BEGIN
        helpptr := 2;
        helpline[1] := 294;
        helpline[0] := 295;
      END;
    END;
  BEGIN
    IF interaction=3 THEN interaction := 2;
    IF logopened THEN error;
{if interaction>0 then debughelp;}
    history := 3;
    jumpout;
  END;
END;
{:95}{1382:}
PROCEDURE catchsignal;
interrupt;
BEGIN
  interrupt := i;
END;
{:1382}{:4}{27:}{$I-}
FUNCTION aopenin(VAR f:alphafile): boolean;
BEGIN
  IF ioresult=0 THEN;
  assign(f,nameoffile);
  reset(f);
  aopenin := ioresult=0;
END;
FUNCTION aopenout(VAR f:alphafile): boolean;
BEGIN
  IF ioresult=0 THEN;
  assign(f,nameoffile);
  rewrite(f);
  aopenout := ioresult=0;
END;
FUNCTION bopenin(VAR f:bytefile): boolean;
BEGIN
  IF ioresult=0 THEN;
  assign(f,nameoffile);
  reset(f);
  bopenin := ioresult=0;
END;
FUNCTION bopenout(VAR f:bytefile): boolean;
BEGIN
  IF ioresult=0 THEN;
  assign(f,nameoffile);
  rewrite(f);
  bopenout := ioresult=0;
END;
FUNCTION wopenin(VAR f:wordfile): boolean;
BEGIN
  IF ioresult=0 THEN;
  assign(f,nameoffile);
  reset(f);
  wopenin := ioresult=0;
END;
FUNCTION wopenout(VAR f:wordfile): boolean;
BEGIN
  IF ioresult=0 THEN;
  assign(f,nameoffile);
  rewrite(f);
  wopenout := ioresult=0;
END;{$I+}
{:27}{28:}
PROCEDURE aclose(VAR f:alphafile);
BEGIN
  close(f);
END;
PROCEDURE bclose(VAR f:bytefile);
BEGIN
  close(f);
END;
PROCEDURE wclose(VAR f:wordfile);
BEGIN
  close(f);
END;
{:28}{31:}
FUNCTION inputln(VAR f:alphafile;bypasseoln:boolean): boolean;

VAR lastnonblank: 0..bufsize;
BEGIN
  last := first;
  IF eof(f)THEN inputln := false
  ELSE
    BEGIN
      lastnonblank := first;
      WHILE NOT eoln(f) DO
        BEGIN
          IF last>=maxbufstack THEN
            BEGIN
              maxbufstack := 
                             last+1;
              IF maxbufstack=bufsize THEN{35:}IF formatident=0 THEN
                                                BEGIN
                                                  writeln(
                                                          output,'Buffer size exceeded!');
                                                  goto 9999;
                                                END
              ELSE
                BEGIN
                  curinput.locfield := first;
                  curinput.limitfield := last-1;
                  overflow(256,bufsize);
                END{:35};
            END;
          buffer[last] := xord[f^];
          get(f);
          last := last+1;
          IF buffer[last-1]<>32 THEN lastnonblank := last;
        END;
      last := lastnonblank;
      inputln := true;
      readln(f);
    END;
END;
{:31}{36:}
PROCEDURE inputcommandln;

VAR argc: integer;
  arg: shortstring;
  cc: integer;
BEGIN
  last := first;
  IF TeXVariation=0 THEN argc := 1
  ELSE argc := 2;
  WHILE argc<=paramcount DO
    BEGIN
      cc := 1;
      arg := paramstr(argc);
      argc := argc+1;
      WHILE cc<=length(arg) DO
        BEGIN
          IF last+1>=bufsize THEN{35:}IF formatident
                                         =0 THEN
                                        BEGIN
                                          writeln(output,'Buffer size exceeded!');
                                          goto 9999;
                                        END
          ELSE
            BEGIN
              curinput.locfield := first;
              curinput.limitfield := last-1;
              overflow(256,bufsize);
            END{:35};
          IF xord[arg[cc]]<>127 THEN buffer[last] := xord[arg[cc]];
          last := last+1;
          cc := cc+1
        END;
      IF (argc<=paramcount)THEN
        BEGIN
          buffer[last] := 32;
          last := last+1
        END
    END
END;{:36}{37:}
FUNCTION initterminal: boolean;

LABEL 10;
BEGIN;
  inputcommandln;
  curinput.locfield := first;
  IF curinput.locfield<last THEN
    BEGIN
      initterminal := true;
      goto 10;
    END;
  WHILE true DO
    BEGIN
      write(output,'**');
      IF NOT inputln(input,true)THEN
        BEGIN
          writeln(output);
          initterminal := false;
          goto 10;
        END;
      curinput.locfield := first;
      WHILE (curinput.locfield<last)AND(buffer[curinput.locfield]=32) DO
        curinput.locfield := curinput.locfield+1;
      IF curinput.locfield<last THEN
        BEGIN
          initterminal := true;
          goto 10;
        END;
      writeln(output,'Please type the name of your input file or Control-D.');
    END;
  10:
END;{:37}{43:}
FUNCTION makestring: strnumber;
BEGIN
  IF strptr=maxstrings THEN overflow(258,maxstrings-initstrptr);
  strptr := strptr+1;
  strstart[strptr] := poolptr;
  makestring := strptr-1;
END;
{:43}{45:}
FUNCTION streqbuf(s:strnumber;k:integer): boolean;

LABEL 45;

VAR j: poolpointer;
  result: boolean;
BEGIN
  j := strstart[s];
  WHILE j<strstart[s+1] DO
    BEGIN
      IF strpool[j]<>buffer[k]THEN
        BEGIN
          result 
          := false;
          goto 45;
        END;
      j := j+1;
      k := k+1;
    END;
  result := true;
  45: streqbuf := result;
END;{:45}{46:}
FUNCTION streqstr(s,t:strnumber): boolean;

LABEL 45;

VAR j,k: poolpointer;
  result: boolean;
BEGIN
  result := false;
  IF (strstart[s+1]-strstart[s])<>(strstart[t+1]-strstart[t])THEN goto 45;
  j := strstart[s];
  k := strstart[t];
  WHILE j<strstart[s+1] DO
    BEGIN
      IF strpool[j]<>strpool[k]THEN goto 45;
      j := j+1;
      k := k+1;
    END;
  result := true;
  45: streqstr := result;
END;
{:46}{47:}
FUNCTION getstringsstarted: boolean;

LABEL 30,10;

VAR k,l: 0..255;
  m,n: char;
  g: strnumber;
  a: integer;
  c: boolean;
BEGIN
  poolptr := 0;
  strptr := 0;
  strstart[0] := 0;
{48:}
  FOR k:=0 TO 255 DO
    BEGIN
      IF ({49:}(k<32)OR(k>126){:49})THEN
        BEGIN
          BEGIN
            strpool[poolptr] := 94;
            poolptr := poolptr+1;
          END;
          BEGIN
            strpool[poolptr] := 94;
            poolptr := poolptr+1;
          END;
          IF k<64 THEN
            BEGIN
              strpool[poolptr] := k+64;
              poolptr := poolptr+1;
            END
          ELSE IF k<128 THEN
                 BEGIN
                   strpool[poolptr] := k-64;
                   poolptr := poolptr+1;
                 END
          ELSE
            BEGIN
              l := k DIV 16;
              IF l<10 THEN
                BEGIN
                  strpool[poolptr] := l+48;
                  poolptr := poolptr+1;
                END
              ELSE
                BEGIN
                  strpool[poolptr] := l+87;
                  poolptr := poolptr+1;
                END;
              l := k MOD 16;
              IF l<10 THEN
                BEGIN
                  strpool[poolptr] := l+48;
                  poolptr := poolptr+1;
                END
              ELSE
                BEGIN
                  strpool[poolptr] := l+87;
                  poolptr := poolptr+1;
                END;
            END;
        END
      ELSE
        BEGIN
          strpool[poolptr] := k;
          poolptr := poolptr+1;
        END;
      g := makestring;
    END{:48};{51:}
  nameoffile := poolname;
  IF aopenin(poolfile)THEN
    BEGIN
      c := false;
      REPEAT{52:}
        BEGIN
          IF eof(poolfile)THEN
            BEGIN;
              writeln(output,'! TEX.POOL has no check sum.');
              getstringsstarted := false;
              goto 10;
            END;
          read(poolfile,m,n);
          IF m='*'THEN{53:}
            BEGIN
              a := 0;
              k := 1;
              WHILE true DO
                BEGIN
                  IF (xord[n]<48)OR(xord[n]>57)THEN
                    BEGIN;
                      writeln(output,'! TEX.POOL check sum doesn''t have nine digits.');
                      getstringsstarted := false;
                      goto 10;
                    END;
                  a := 10*a+xord[n]-48;
                  IF k=9 THEN goto 30;
                  k := k+1;
                  read(poolfile,n);
                END;
              30: IF a<>305924274 THEN
                    BEGIN;
                      writeln(output,'! TeXformats/tex.pool doesn''t match. Not installed?');
                      getstringsstarted := false;
                      goto 10;
                    END;
              c := true;
            END{:53}
          ELSE
            BEGIN
              IF (xord[m]<48)OR(xord[m]>57)OR(xord[n]<48)OR(xord[n]>
                 57)THEN
                BEGIN;
                  writeln(output,'! TEX.POOL line doesn''t begin with two digits.');
                  getstringsstarted := false;
                  goto 10;
                END;
              l := xord[m]*10+xord[n]-48*11;
              IF poolptr+l+stringvacancies>poolsize THEN
                BEGIN;
                  writeln(output,'! You have to increase POOLSIZE.');
                  getstringsstarted := false;
                  goto 10;
                END;
              FOR k:=1 TO l DO
                BEGIN
                  IF eoln(poolfile)THEN m := ' '
                  ELSE read(poolfile,m)
                  ;
                  BEGIN
                    strpool[poolptr] := xord[m];
                    poolptr := poolptr+1;
                  END;
                END;
              readln(poolfile);
              g := makestring;
            END;
        END{:52};
      UNTIL c;
      aclose(poolfile);
      getstringsstarted := true;
    END
  ELSE
    BEGIN;
      writeln(output,'! I can''t read TeXformats/tex.pool.');
      getstringsstarted := false;
      goto 10;
    END{:51};
  10:
END;
{:47}{66:}
PROCEDURE printtwo(n:integer);
BEGIN
  n := abs(n)MOD 100;
  printchar(48+(n DIV 10));
  printchar(48+(n MOD 10));
END;
{:66}{67:}
PROCEDURE printhex(n:integer);

VAR k: 0..22;
BEGIN
  k := 0;
  printchar(34);
  REPEAT
    dig[k] := n MOD 16;
    n := n DIV 16;
    k := k+1;
  UNTIL n=0;
  printthedigs(k);
END;{:67}{69:}
PROCEDURE printromanint(n:integer);

LABEL 10;

VAR j,k: poolpointer;
  u,v: nonnegativeinteger;
BEGIN
  j := strstart[260];
  v := 1000;
  WHILE true DO
    BEGIN
      WHILE n>=v DO
        BEGIN
          printchar(strpool[j]);
          n := n-v;
        END;
      IF n<=0 THEN goto 10;
      k := j+2;
      u := v DIV(strpool[k-1]-48);
      IF strpool[k-1]=50 THEN
        BEGIN
          k := k+2;
          u := u DIV(strpool[k-1]-48);
        END;
      IF n+u>=v THEN
        BEGIN
          printchar(strpool[k]);
          n := n+u;
        END
      ELSE
        BEGIN
          j := j+2;
          v := v DIV(strpool[j-1]-48);
        END;
    END;
  10:
END;
{:69}{70:}
PROCEDURE printcurrentstring;

VAR j: poolpointer;
BEGIN
  j := strstart[strptr];
  WHILE j<poolptr DO
    BEGIN
      printchar(strpool[j]);
      j := j+1;
    END;
END;
{:70}{71:}
PROCEDURE terminput;

VAR k: 0..bufsize;
BEGIN
  flush(output);
  IF NOT inputln(input,true)THEN fatalerror(261);
  termoffset := 0;
  selector := selector-1;
  IF last<>first THEN FOR k:=first TO last-1 DO
                        print(buffer[k]);
  println;
  selector := selector+1;
END;{:71}{91:}
PROCEDURE interror(n:integer);
BEGIN
  print(286);
  printint(n);
  printchar(41);
  error;
END;
{:91}{92:}
PROCEDURE normalizeselector;
BEGIN
  IF logopened THEN selector := 19
  ELSE selector := 17;
  IF jobname=0 THEN openlogfile;
  IF interaction=0 THEN selector := selector-1;
END;
{:92}{98:}
PROCEDURE pauseforinstructions;
BEGIN
  IF OKtointerrupt THEN
    BEGIN
      interaction := 3;
      IF (selector=18)OR(selector=16)THEN selector := selector+1;
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(296);
      END;
      BEGIN
        helpptr := 3;
        helpline[2] := 297;
        helpline[1] := 298;
        helpline[0] := 299;
      END;
      deletionsallowed := false;
      error;
      deletionsallowed := true;
      interrupt := 0;
    END;
END;{:98}{100:}
FUNCTION half(x:integer): integer;
BEGIN
  IF odd(x)THEN half := (x+1)DIV 2
  ELSE half := x DIV 2;
END;
{:100}{102:}
FUNCTION rounddecimals(k:smallnumber): scaled;

VAR a: integer;
BEGIN
  a := 0;
  WHILE k>0 DO
    BEGIN
      k := k-1;
      a := (a+dig[k]*131072)DIV 10;
    END;
  rounddecimals := (a+1)DIV 2;
END;
{:102}{103:}
PROCEDURE printscaled(s:scaled);

VAR delta: scaled;
BEGIN
  IF s<0 THEN
    BEGIN
      printchar(45);
      s := -s;
    END;
  printint(s DIV 65536);
  printchar(46);
  s := 10*(s MOD 65536)+5;
  delta := 10;
  REPEAT
    IF delta>65536 THEN s := s-17232;
    printchar(48+(s DIV 65536));
    s := 10*(s MOD 65536);
    delta := delta*10;
  UNTIL s<=delta;
END;
{:103}{105:}
FUNCTION multandadd(n:integer;x,y,maxanswer:scaled): scaled;
BEGIN
  IF n<0 THEN
    BEGIN
      x := -x;
      n := -n;
    END;
  IF n=0 THEN multandadd := y
  ELSE IF ((x<=(maxanswer-y)DIV n)AND(-x<=(
          maxanswer+y)DIV n))THEN multandadd := n*x+y
  ELSE
    BEGIN
      aritherror := true;
      multandadd := 0;
    END;
END;{:105}{106:}
FUNCTION xovern(x:scaled;
                n:integer): scaled;

VAR negative: boolean;
BEGIN
  negative := false;
  IF n=0 THEN
    BEGIN
      aritherror := true;
      xovern := 0;
      remainder := x;
    END
  ELSE
    BEGIN
      IF n<0 THEN
        BEGIN
          x := -x;
          n := -n;
          negative := true;
        END;
      IF x>=0 THEN
        BEGIN
          xovern := x DIV n;
          remainder := x MOD n;
        END
      ELSE
        BEGIN
          xovern := -((-x)DIV n);
          remainder := -((-x)MOD n);
        END;
    END;
  IF negative THEN remainder := -remainder;
END;
{:106}{107:}
FUNCTION xnoverd(x:scaled;n,d:integer): scaled;

VAR positive: boolean;
  t,u,v: nonnegativeinteger;
BEGIN
  IF x>=0 THEN positive := true
  ELSE
    BEGIN
      x := -x;
      positive := false;
    END;
  t := (x MOD 32768)*n;
  u := (x DIV 32768)*n+(t DIV 32768);
  v := (u MOD d)*32768+(t MOD 32768);
  IF u DIV d>=32768 THEN aritherror := true
  ELSE u := 32768*(u DIV d)+(v DIV d
            );
  IF positive THEN
    BEGIN
      xnoverd := u;
      remainder := v MOD d;
    END
  ELSE
    BEGIN
      xnoverd := -u;
      remainder := -(v MOD d);
    END;
END;
{:107}{108:}
FUNCTION badness(t,s:scaled): halfword;

VAR r: integer;
BEGIN
  IF t=0 THEN badness := 0
  ELSE IF s<=0 THEN badness := 10000
  ELSE
    BEGIN
      IF t<=7230584 THEN r := (t*297)DIV s
      ELSE IF s>=1663497 THEN r := t DIV(s
                                   DIV 297)
      ELSE r := t;
      IF r>1290 THEN badness := 10000
      ELSE badness := (r*r*r+131072)DIV 262144;
    END;
END;{:108}{114:}
{procedure printword(w:memoryword);
begin printint(w.int);printchar(32);printscaled(w.int);printchar(32);
printscaled(round(65536*w.gr));println;printint(w.hh.lh);printchar(61);
printint(w.hh.b0);printchar(58);printint(w.hh.b1);printchar(59);
printint(w.hh.rh);printchar(32);printint(w.qqqq.b0);printchar(58);
printint(w.qqqq.b1);printchar(58);printint(w.qqqq.b2);printchar(58);
printint(w.qqqq.b3);end;}
{:114}{119:}{292:}
PROCEDURE showtokenlist(p,q:integer;l:integer);

LABEL 10;

VAR m,c: integer;
  matchchr: ASCIIcode;
  n: ASCIIcode;
BEGIN
  matchchr := 35;
  n := 48;
  tally := 0;
  WHILE (p<>0)AND(tally<l) DO
    BEGIN
      IF p=q THEN{320:}
        BEGIN
          firstcount := tally
          ;
          trickcount := tally+1+errorline-halferrorline;
          IF trickcount<errorline THEN trickcount := errorline;
        END{:320};
{293:}
      IF (p<himemmin)OR(p>memend)THEN
        BEGIN
          printesc(309);
          goto 10;
        END;
      IF mem[p].hh.lh>=4095 THEN printcs(mem[p].hh.lh-4095)
      ELSE
        BEGIN
          m := mem[p
               ].hh.lh DIV 256;
          c := mem[p].hh.lh MOD 256;
          IF mem[p].hh.lh<0 THEN printesc(555)
          ELSE{294:}CASE m OF 
                      1,2,3,4,7,8,10,
                      11,12: print(c);
                      6:
                         BEGIN
                           print(c);
                           print(c);
                         END;
                      5:
                         BEGIN
                           print(matchchr);
                           IF c<=9 THEN printchar(c+48)
                           ELSE
                             BEGIN
                               printchar(33);
                               goto 10;
                             END;
                         END;
                      13:
                          BEGIN
                            matchchr := c;
                            print(c);
                            n := n+1;
                            printchar(n);
                            IF n>57 THEN goto 10;
                          END;
                      14: print(556);
                      ELSE printesc(555)
            END{:294};
        END{:293};
      p := mem[p].hh.rh;
    END;
  IF p<>0 THEN printesc(554);
  10:
END;{:292}{306:}
PROCEDURE runaway;

VAR p: halfword;
BEGIN
  IF scannerstatus>1 THEN
    BEGIN
      printnl(569);
      CASE scannerstatus OF 
        2:
           BEGIN
             print(570);
             p := defref;
           END;
        3:
           BEGIN
             print(571);
             p := 29997;
           END;
        4:
           BEGIN
             print(572);
             p := 29996;
           END;
        5:
           BEGIN
             print(573);
             p := defref;
           END;
      END;
      printchar(63);
      println;
      showtokenlist(mem[p].hh.rh,0,errorline-10);
    END;
END;
{:306}{:119}{120:}
FUNCTION getavail: halfword;

VAR p: halfword;
BEGIN
  p := avail;
  IF p<>0 THEN avail := mem[avail].hh.rh
  ELSE IF memend<memmax THEN
         BEGIN
           memend := memend+1;
           p := memend;
         END
  ELSE
    BEGIN
      himemmin := himemmin-1;
      p := himemmin;
      IF himemmin<=lomemmax THEN
        BEGIN
          runaway;
          overflow(300,memmax+1-memmin);
        END;
    END;
  mem[p].hh.rh := 0;
  dynused := dynused+1;
  getavail := p;
END;
{:120}{123:}
PROCEDURE flushlist(p:halfword);

VAR q,r: halfword;
BEGIN
  IF p<>0 THEN
    BEGIN
      r := p;
      REPEAT
        q := r;
        r := mem[r].hh.rh;
        dynused := dynused-1;
      UNTIL r=0;
      mem[q].hh.rh := avail;
      avail := p;
    END;
END;
{:123}{125:}
FUNCTION getnode(s:integer): halfword;

LABEL 40,10,20;

VAR p: halfword;
  q: halfword;
  r: integer;
  t: integer;
BEGIN
  20: p := rover;
  REPEAT{127:}
    q := p+mem[p].hh.lh;
    WHILE (mem[q].hh.rh=65535) DO
      BEGIN
        t := mem[q+1].hh.rh;
        IF q=rover THEN rover := t;
        mem[t+1].hh.lh := mem[q+1].hh.lh;
        mem[mem[q+1].hh.lh+1].hh.rh := t;
        q := q+mem[q].hh.lh;
      END;
    r := q-s;
    IF r>p+1 THEN{128:}
      BEGIN
        mem[p].hh.lh := r-p;
        rover := p;
        goto 40;
      END{:128};
    IF r=p THEN IF mem[p+1].hh.rh<>p THEN{129:}
                  BEGIN
                    rover := mem[p+1].hh.rh;
                    t := mem[p+1].hh.lh;
                    mem[rover+1].hh.lh := t;
                    mem[t+1].hh.rh := rover;
                    goto 40;
                  END{:129};
    mem[p].hh.lh := q-p{:127};
    p := mem[p+1].hh.rh;
  UNTIL p=rover;
  IF s=1073741824 THEN
    BEGIN
      getnode := 65535;
      goto 10;
    END;
  IF lomemmax+2<himemmin THEN IF lomemmax+2<=65535 THEN{126:}
                                BEGIN
                                  IF 
                                     himemmin-lomemmax>=1998 THEN t := lomemmax+1000
                                  ELSE t := lomemmax+1+(
                                            himemmin-lomemmax)DIV 2;
                                  p := mem[rover+1].hh.lh;
                                  q := lomemmax;
                                  mem[p+1].hh.rh := q;
                                  mem[rover+1].hh.lh := q;
                                  IF t>65535 THEN t := 65535;
                                  mem[q+1].hh.rh := rover;
                                  mem[q+1].hh.lh := p;
                                  mem[q].hh.rh := 65535;
                                  mem[q].hh.lh := t-lomemmax;
                                  lomemmax := t;
                                  mem[lomemmax].hh.rh := 0;
                                  mem[lomemmax].hh.lh := 0;
                                  rover := q;
                                  goto 20;
                                END{:126};
  overflow(300,memmax+1-memmin);
  40: mem[r].hh.rh := 0;
  varused := varused+s;
  getnode := r;
  10:
END;{:125}{130:}
PROCEDURE freenode(p:halfword;s:halfword);

VAR q: halfword;
BEGIN
  mem[p].hh.lh := s;
  mem[p].hh.rh := 65535;
  q := mem[rover+1].hh.lh;
  mem[p+1].hh.lh := q;
  mem[p+1].hh.rh := rover;
  mem[rover+1].hh.lh := p;
  mem[q+1].hh.rh := p;
  varused := varused-s;
END;
{:130}{131:}
PROCEDURE sortavail;

VAR p,q,r: halfword;
  oldrover: halfword;
BEGIN
  p := getnode(1073741824);
  p := mem[rover+1].hh.rh;
  mem[rover+1].hh.rh := 65535;
  oldrover := rover;
  WHILE p<>oldrover DO{132:}
    IF p<rover THEN
      BEGIN
        q := p;
        p := mem[q+1].hh.rh;
        mem[q+1].hh.rh := rover;
        rover := q;
      END
    ELSE
      BEGIN
        q := rover;
        WHILE mem[q+1].hh.rh<p DO
          q := mem[q+1].hh.rh;
        r := mem[p+1].hh.rh;
        mem[p+1].hh.rh := mem[q+1].hh.rh;
        mem[q+1].hh.rh := p;
        p := r;
      END{:132};
  p := rover;
  WHILE mem[p+1].hh.rh<>65535 DO
    BEGIN
      mem[mem[p+1].hh.rh+1].hh.lh := p;
      p := mem[p+1].hh.rh;
    END;
  mem[p+1].hh.rh := rover;
  mem[rover+1].hh.lh := p;
END;
{:131}{136:}
FUNCTION newnullbox: halfword;

VAR p: halfword;
BEGIN
  p := getnode(7);
  mem[p].hh.b0 := 0;
  mem[p].hh.b1 := 0;
  mem[p+1].int := 0;
  mem[p+2].int := 0;
  mem[p+3].int := 0;
  mem[p+4].int := 0;
  mem[p+5].hh.rh := 0;
  mem[p+5].hh.b0 := 0;
  mem[p+5].hh.b1 := 0;
  mem[p+6].gr := 0.0;
  newnullbox := p;
END;
{:136}{139:}
FUNCTION newrule: halfword;

VAR p: halfword;
BEGIN
  p := getnode(4);
  mem[p].hh.b0 := 2;
  mem[p].hh.b1 := 0;
  mem[p+1].int := -1073741824;
  mem[p+2].int := -1073741824;
  mem[p+3].int := -1073741824;
  newrule := p;
END;
{:139}{144:}
FUNCTION newligature(f,c:quarterword;q:halfword): halfword;

VAR p: halfword;
BEGIN
  p := getnode(2);
  mem[p].hh.b0 := 6;
  mem[p+1].hh.b0 := f;
  mem[p+1].hh.b1 := c;
  mem[p+1].hh.rh := q;
  mem[p].hh.b1 := 0;
  newligature := p;
END;
FUNCTION newligitem(c:quarterword): halfword;

VAR p: halfword;
BEGIN
  p := getnode(2);
  mem[p].hh.b1 := c;
  mem[p+1].hh.rh := 0;
  newligitem := p;
END;
{:144}{145:}
FUNCTION newdisc: halfword;

VAR p: halfword;
BEGIN
  p := getnode(2);
  mem[p].hh.b0 := 7;
  mem[p].hh.b1 := 0;
  mem[p+1].hh.lh := 0;
  mem[p+1].hh.rh := 0;
  newdisc := p;
END;{:145}{147:}
FUNCTION newmath(w:scaled;
                 s:smallnumber): halfword;

VAR p: halfword;
BEGIN
  p := getnode(2);
  mem[p].hh.b0 := 9;
  mem[p].hh.b1 := s;
  mem[p+1].int := w;
  newmath := p;
END;
{:147}{151:}
FUNCTION newspec(p:halfword): halfword;

VAR q: halfword;
BEGIN
  q := getnode(4);
  mem[q] := mem[p];
  mem[q].hh.rh := 0;
  mem[q+1].int := mem[p+1].int;
  mem[q+2].int := mem[p+2].int;
  mem[q+3].int := mem[p+3].int;
  newspec := q;
END;
{:151}{152:}
FUNCTION newparamglue(n:smallnumber): halfword;

VAR p: halfword;
  q: halfword;
BEGIN
  p := getnode(2);
  mem[p].hh.b0 := 10;
  mem[p].hh.b1 := n+1;
  mem[p+1].hh.rh := 0;
  q := {224:}eqtb[2882+n].hh.rh{:224};
  mem[p+1].hh.lh := q;
  mem[q].hh.rh := mem[q].hh.rh+1;
  newparamglue := p;
END;
{:152}{153:}
FUNCTION newglue(q:halfword): halfword;

VAR p: halfword;
BEGIN
  p := getnode(2);
  mem[p].hh.b0 := 10;
  mem[p].hh.b1 := 0;
  mem[p+1].hh.rh := 0;
  mem[p+1].hh.lh := q;
  mem[q].hh.rh := mem[q].hh.rh+1;
  newglue := p;
END;
{:153}{154:}
FUNCTION newskipparam(n:smallnumber): halfword;

VAR p: halfword;
BEGIN
  tempptr := newspec({224:}eqtb[2882+n].hh.rh{:224});
  p := newglue(tempptr);
  mem[tempptr].hh.rh := 0;
  mem[p].hh.b1 := n+1;
  newskipparam := p;
END;{:154}{156:}
FUNCTION newkern(w:scaled): halfword;

VAR p: halfword;
BEGIN
  p := getnode(2);
  mem[p].hh.b0 := 11;
  mem[p].hh.b1 := 0;
  mem[p+1].int := w;
  newkern := p;
END;
{:156}{158:}
FUNCTION newpenalty(m:integer): halfword;

VAR p: halfword;
BEGIN
  p := getnode(2);
  mem[p].hh.b0 := 12;
  mem[p].hh.b1 := 0;
  mem[p+1].int := m;
  newpenalty := p;
END;{:158}{167:}
{procedure checkmem(printlocs:boolean);
label 31,32;var p,q:halfword;clobbered:boolean;
begin for p:=memmin to lomemmax do free[p]:=false;
for p:=himemmin to memend do free[p]:=false;[168:]p:=avail;q:=0;
clobbered:=false;
while p<>0 do begin if(p>memend)or(p<himemmin)then clobbered:=true else
if free[p]then clobbered:=true;if clobbered then begin printnl(301);
printint(q);goto 31;end;free[p]:=true;q:=p;p:=mem[q].hh.rh;end;
31:[:168];[169:]p:=rover;q:=0;clobbered:=false;
repeat if(p>=lomemmax)or(p<memmin)then clobbered:=true else if(mem[p+1].
hh.rh>=lomemmax)or(mem[p+1].hh.rh<memmin)then clobbered:=true else if
not((mem[p].hh.rh=65535))or(mem[p].hh.lh<2)or(p+mem[p].hh.lh>lomemmax)or
(mem[mem[p+1].hh.rh+1].hh.lh<>p)then clobbered:=true;
if clobbered then begin printnl(302);printint(q);goto 32;end;
for q:=p to p+mem[p].hh.lh-1 do begin if free[q]then begin printnl(303);
printint(q);goto 32;end;free[q]:=true;end;q:=p;p:=mem[p+1].hh.rh;
until p=rover;32:[:169];[170:]p:=memmin;
while p<=lomemmax do begin if(mem[p].hh.rh=65535)then begin printnl(304)
;printint(p);end;while(p<=lomemmax)and not free[p]do p:=p+1;
while(p<=lomemmax)and free[p]do p:=p+1;end[:170];
if printlocs then[171:]begin printnl(305);
for p:=memmin to lomemmax do if not free[p]and((p>waslomax)or wasfree[p]
)then begin printchar(32);printint(p);end;
for p:=himemmin to memend do if not free[p]and((p<washimin)or(p>
wasmemend)or wasfree[p])then begin printchar(32);printint(p);end;
end[:171];for p:=memmin to lomemmax do wasfree[p]:=free[p];
for p:=himemmin to memend do wasfree[p]:=free[p];wasmemend:=memend;
waslomax:=lomemmax;washimin:=himemmin;end;}
{:167}{172:}
{procedure searchmem(p:halfword);var q:integer;
begin for q:=memmin to lomemmax do begin if mem[q].hh.rh=p then begin
printnl(306);printint(q);printchar(41);end;
if mem[q].hh.lh=p then begin printnl(307);printint(q);printchar(41);end;
end;
for q:=himemmin to memend do begin if mem[q].hh.rh=p then begin printnl(
306);printint(q);printchar(41);end;
if mem[q].hh.lh=p then begin printnl(307);printint(q);printchar(41);end;
end;
[255:]for q:=1 to 3933 do begin if eqtb[q].hh.rh=p then begin printnl(
501);printint(q);printchar(41);end;end[:255];
[285:]if saveptr>0 then for q:=0 to saveptr-1 do begin if savestack[q].
hh.rh=p then begin printnl(546);printint(q);printchar(41);end;end[:285];
[933:]for q:=0 to 307 do begin if hyphlist[q]=p then begin printnl(941);
printint(q);printchar(41);end;end[:933];end;}
{:172}{174:}
PROCEDURE shortdisplay(p:integer);

VAR n: integer;
BEGIN
  WHILE p>memmin DO
    BEGIN
      IF (p>=himemmin)THEN
        BEGIN
          IF p<=memend
            THEN
            BEGIN
              IF mem[p].hh.b0<>fontinshortdisplay THEN
                BEGIN
                  IF (mem[p].hh.
                     b0<0)OR(mem[p].hh.b0>fontmax)THEN printchar(42)
                  ELSE{267:}printesc(hash[
                                     2624+mem[p].hh.b0].rh){:267};
                  printchar(32);
                  fontinshortdisplay := mem[p].hh.b0;
                END;
              print(mem[p].hh.b1);
            END;
        END
      ELSE{175:}CASE mem[p].hh.b0 OF 
                  0,1,3,8,4,5,13: print(308);
                  2: printchar(124);
                  10: IF mem[p+1].hh.lh<>0 THEN printchar(32);
                  9: printchar(36);
                  6: shortdisplay(mem[p+1].hh.rh);
                  7:
                     BEGIN
                       shortdisplay(mem[p+1].hh.lh);
                       shortdisplay(mem[p+1].hh.rh);
                       n := mem[p].hh.b1;
                       WHILE n>0 DO
                         BEGIN
                           IF mem[p].hh.rh<>0 THEN p := mem[p].hh.rh;
                           n := n-1;
                         END;
                     END;
                  ELSE
        END{:175};
      p := mem[p].hh.rh;
    END;
END;
{:174}{176:}
PROCEDURE printfontandchar(p:integer);
BEGIN
  IF p>memend THEN printesc(309)
  ELSE
    BEGIN
      IF (mem[p].hh.b0<0)OR(mem[
         p].hh.b0>fontmax)THEN printchar(42)
      ELSE{267:}printesc(hash[2624+mem[p].
                         hh.b0].rh){:267};
      printchar(32);
      print(mem[p].hh.b1);
    END;
END;
PROCEDURE printmark(p:integer);
BEGIN
  printchar(123);
  IF (p<himemmin)OR(p>memend)THEN printesc(309)
  ELSE showtokenlist(mem[p].hh
                     .rh,0,maxprintline-10);
  printchar(125);
END;
PROCEDURE printruledimen(d:scaled);
BEGIN
  IF (d=-1073741824)THEN printchar(42)
  ELSE printscaled(d);
END;
{:176}{177:}
PROCEDURE printglue(d:scaled;order:integer;s:strnumber);
BEGIN
  printscaled(d);
  IF (order<0)OR(order>3)THEN print(310)
  ELSE IF order>0 THEN
         BEGIN
           print(
                 311);
           WHILE order>1 DO
             BEGIN
               printchar(108);
               order := order-1;
             END;
         END
  ELSE IF s<>0 THEN print(s);
END;
{:177}{178:}
PROCEDURE printspec(p:integer;s:strnumber);
BEGIN
  IF (p<memmin)OR(p>=lomemmax)THEN printchar(42)
  ELSE
    BEGIN
      printscaled(mem[p+1].int);
      IF s<>0 THEN print(s);
      IF mem[p+2].int<>0 THEN
        BEGIN
          print(312);
          printglue(mem[p+2].int,mem[p].hh.b0,s);
        END;
      IF mem[p+3].int<>0 THEN
        BEGIN
          print(313);
          printglue(mem[p+3].int,mem[p].hh.b1,s);
        END;
    END;
END;
{:178}{179:}{691:}
PROCEDURE printfamandchar(p:halfword);
BEGIN
  printesc(464);
  printint(mem[p].hh.b0);
  printchar(32);
  print(mem[p].hh.b1);
END;
PROCEDURE printdelimiter(p:halfword);

VAR a: integer;
BEGIN
  a := mem[p].qqqq.b0*256+mem[p].qqqq.b1;
  a := a*4096+mem[p].qqqq.b2*256+mem[p].qqqq.b3;
  IF a<0 THEN printint(a)
  ELSE printhex(a);
END;
{:691}{692:}
PROCEDURE showinfo;
forward;
PROCEDURE printsubsidiarydata(p:halfword;c:ASCIIcode);
BEGIN
  IF (poolptr-strstart[strptr])>=depththreshold THEN
    BEGIN
      IF mem[p].
         hh.rh<>0 THEN print(314);
    END
  ELSE
    BEGIN
      BEGIN
        strpool[poolptr] := c;
        poolptr := poolptr+1;
      END;
      tempptr := p;
      CASE mem[p].hh.rh OF 
        1:
           BEGIN
             println;
             printcurrentstring;
             printfamandchar(p);
           END;
        2: showinfo;
        3: IF mem[p].hh.lh=0 THEN
             BEGIN
               println;
               printcurrentstring;
               print(861);
             END
           ELSE showinfo;
        ELSE
      END;
      poolptr := poolptr-1;
    END;
END;
{:692}{694:}
PROCEDURE printstyle(c:integer);
BEGIN
  CASE c DIV 2 OF 
    0: printesc(862);
    1: printesc(863);
    2: printesc(864);
    3: printesc(865);
    ELSE print(866)
  END;
END;
{:694}{225:}
PROCEDURE printskipparam(n:integer);
BEGIN
  CASE n OF 
    0: printesc(376);
    1: printesc(377);
    2: printesc(378);
    3: printesc(379);
    4: printesc(380);
    5: printesc(381);
    6: printesc(382);
    7: printesc(383);
    8: printesc(384);
    9: printesc(385);
    10: printesc(386);
    11: printesc(387);
    12: printesc(388);
    13: printesc(389);
    14: printesc(390);
    15: printesc(391);
    16: printesc(392);
    17: printesc(393);
    ELSE print(394)
  END;
END;{:225}{:179}{182:}
PROCEDURE shownodelist(p:integer);

LABEL 10;

VAR n: integer;
  g: real;
BEGIN
  IF (poolptr-strstart[strptr])>depththreshold THEN
    BEGIN
      IF p>0 THEN
        print(314);
      goto 10;
    END;
  n := 0;
  WHILE p>memmin DO
    BEGIN
      println;
      printcurrentstring;
      IF p>memend THEN
        BEGIN
          print(315);
          goto 10;
        END;
      n := n+1;
      IF n>breadthmax THEN
        BEGIN
          print(316);
          goto 10;
        END;
{183:}
      IF (p>=himemmin)THEN printfontandchar(p)
      ELSE CASE mem[p].hh.b0 OF 
             0
             ,1,13:{184:}
                    BEGIN
                      IF mem[p].hh.b0=0 THEN printesc(104)
                      ELSE IF mem[p].hh.
                              b0=1 THEN printesc(118)
                      ELSE printesc(318);
                      print(319);
                      printscaled(mem[p+3].int);
                      printchar(43);
                      printscaled(mem[p+2].int);
                      print(320);
                      printscaled(mem[p+1].int);
                      IF mem[p].hh.b0=13 THEN{185:}
                        BEGIN
                          IF mem[p].hh.b1<>0 THEN
                            BEGIN
                              print(
                                    286);
                              printint(mem[p].hh.b1+1);
                              print(322);
                            END;
                          IF mem[p+6].int<>0 THEN
                            BEGIN
                              print(323);
                              printglue(mem[p+6].int,mem[p+5].hh.b1,0);
                            END;
                          IF mem[p+4].int<>0 THEN
                            BEGIN
                              print(324);
                              printglue(mem[p+4].int,mem[p+5].hh.b0,0);
                            END;
                        END{:185}
                      ELSE
                        BEGIN{186:}
                          g := mem[p+6].gr;
                          IF (g<>0.0)AND(mem[p+5].hh.b0<>0)THEN
                            BEGIN
                              print(325);
                              IF mem[p+5].hh.b0=2 THEN print(326);
                              IF abs(mem[p+6].int)<1048576 THEN print(327)
                              ELSE IF abs(g)>20000.0 THEN
                                     BEGIN
                                       IF g>0.0 THEN printchar(62)
                                       ELSE print(328);
                                       printglue(20000*65536,mem[p+5].hh.b1,0);
                                     END
                              ELSE printglue(round(65536*g),mem[p+5].hh.b1,0);
                            END{:186};
                          IF mem[p+4].int<>0 THEN
                            BEGIN
                              print(321);
                              printscaled(mem[p+4].int);
                            END;
                        END;
                      BEGIN
                        BEGIN
                          strpool[poolptr] := 46;
                          poolptr := poolptr+1;
                        END;
                        shownodelist(mem[p+5].hh.rh);
                        poolptr := poolptr-1;
                      END;
                    END{:184};
             2:{187:}
                BEGIN
                  printesc(329);
                  printruledimen(mem[p+3].int);
                  printchar(43);
                  printruledimen(mem[p+2].int);
                  print(320);
                  printruledimen(mem[p+1].int);
                END{:187};
             3:{188:}
                BEGIN
                  printesc(330);
                  printint(mem[p].hh.b1);
                  print(331);
                  printscaled(mem[p+3].int);
                  print(332);
                  printspec(mem[p+4].hh.rh,0);
                  printchar(44);
                  printscaled(mem[p+2].int);
                  print(333);
                  printint(mem[p+1].int);
                  BEGIN
                    BEGIN
                      strpool[poolptr] := 46;
                      poolptr := poolptr+1;
                    END;
                    shownodelist(mem[p+4].hh.lh);
                    poolptr := poolptr-1;
                  END;
                END{:188};
             8:{1356:}CASE mem[p].hh.b1 OF 
                        0:
                           BEGIN
                             printwritewhatsit(1286,p);
                             printchar(61);
                             printfilename(mem[p+1].hh.rh,mem[p+2].hh.lh,mem[p+2].hh.rh);
                           END;
                        1:
                           BEGIN
                             printwritewhatsit(594,p);
                             printmark(mem[p+1].hh.rh);
                           END;
                        2: printwritewhatsit(1287,p);
                        3:
                           BEGIN
                             printesc(1288);
                             printmark(mem[p+1].hh.rh);
                           END;
                        4:
                           BEGIN
                             printesc(1290);
                             printint(mem[p+1].hh.rh);
                             print(1293);
                             printint(mem[p+1].hh.b0);
                             printchar(44);
                             printint(mem[p+1].hh.b1);
                             printchar(41);
                           END;
                        ELSE print(1294)
                END{:1356};
             10:{189:}IF mem[p].hh.b1>=100 THEN{190:}
                        BEGIN
                          printesc(338);
                          IF mem[p].hh.b1=101 THEN printchar(99)
                          ELSE IF mem[p].hh.b1=102 THEN
                                 printchar(120);
                          print(339);
                          printspec(mem[p+1].hh.lh,0);
                          BEGIN
                            BEGIN
                              strpool[poolptr] := 46;
                              poolptr := poolptr+1;
                            END;
                            shownodelist(mem[p+1].hh.rh);
                            poolptr := poolptr-1;
                          END;
                        END{:190}
                 ELSE
                   BEGIN
                     printesc(334);
                     IF mem[p].hh.b1<>0 THEN
                       BEGIN
                         printchar(40);
                         IF mem[p].hh.b1<98 THEN printskipparam(mem[p].hh.b1-1)
                         ELSE IF mem[p].hh.
                                 b1=98 THEN printesc(335)
                         ELSE printesc(336);
                         printchar(41);
                       END;
                     IF mem[p].hh.b1<>98 THEN
                       BEGIN
                         printchar(32);
                         IF mem[p].hh.b1<98 THEN printspec(mem[p+1].hh.lh,0)
                         ELSE printspec(mem[p
                                        +1].hh.lh,337);
                       END;
                   END{:189};
             11:{191:}IF mem[p].hh.b1<>99 THEN
                        BEGIN
                          printesc(340);
                          IF mem[p].hh.b1<>0 THEN printchar(32);
                          printscaled(mem[p+1].int);
                          IF mem[p].hh.b1=2 THEN print(341);
                        END
                 ELSE
                   BEGIN
                     printesc(342);
                     printscaled(mem[p+1].int);
                     print(337);
                   END{:191};
             9:{192:}
                BEGIN
                  printesc(343);
                  IF mem[p].hh.b1=0 THEN print(344)
                  ELSE print(345);
                  IF mem[p+1].int<>0 THEN
                    BEGIN
                      print(346);
                      printscaled(mem[p+1].int);
                    END;
                END{:192};
             6:{193:}
                BEGIN
                  printfontandchar(p+1);
                  print(347);
                  IF mem[p].hh.b1>1 THEN printchar(124);
                  fontinshortdisplay := mem[p+1].hh.b0;
                  shortdisplay(mem[p+1].hh.rh);
                  IF odd(mem[p].hh.b1)THEN printchar(124);
                  printchar(41);
                END{:193};
             12:{194:}
                 BEGIN
                   printesc(348);
                   printint(mem[p+1].int);
                 END{:194};
             7:{195:}
                BEGIN
                  printesc(349);
                  IF mem[p].hh.b1>0 THEN
                    BEGIN
                      print(350);
                      printint(mem[p].hh.b1);
                    END;
                  BEGIN
                    BEGIN
                      strpool[poolptr] := 46;
                      poolptr := poolptr+1;
                    END;
                    shownodelist(mem[p+1].hh.lh);
                    poolptr := poolptr-1;
                  END;
                  BEGIN
                    strpool[poolptr] := 124;
                    poolptr := poolptr+1;
                  END;
                  shownodelist(mem[p+1].hh.rh);
                  poolptr := poolptr-1;
                END{:195};
             4:{196:}
                BEGIN
                  printesc(351);
                  printmark(mem[p+1].int);
                END{:196};
             5:{197:}
                BEGIN
                  printesc(352);
                  BEGIN
                    BEGIN
                      strpool[poolptr] := 46;
                      poolptr := poolptr+1;
                    END;
                    shownodelist(mem[p+1].int);
                    poolptr := poolptr-1;
                  END;
                END{:197};{690:}
             14: printstyle(mem[p].hh.b1);
             15:{695:}
                 BEGIN
                   printesc(525);
                   BEGIN
                     strpool[poolptr] := 68;
                     poolptr := poolptr+1;
                   END;
                   shownodelist(mem[p+1].hh.lh);
                   poolptr := poolptr-1;
                   BEGIN
                     strpool[poolptr] := 84;
                     poolptr := poolptr+1;
                   END;
                   shownodelist(mem[p+1].hh.rh);
                   poolptr := poolptr-1;
                   BEGIN
                     strpool[poolptr] := 83;
                     poolptr := poolptr+1;
                   END;
                   shownodelist(mem[p+2].hh.lh);
                   poolptr := poolptr-1;
                   BEGIN
                     strpool[poolptr] := 115;
                     poolptr := poolptr+1;
                   END;
                   shownodelist(mem[p+2].hh.rh);
                   poolptr := poolptr-1;
                 END{:695};
             16,17,18,19,20,21,22,23,24,27,26,29,28,30,31:{696:}
                                                           BEGIN
                                                             CASE mem[p].hh.
                                                                  b0 OF 
                                                               16: printesc(867);
                                                               17: printesc(868);
                                                               18: printesc(869);
                                                               19: printesc(870);
                                                               20: printesc(871);
                                                               21: printesc(872);
                                                               22: printesc(873);
                                                               23: printesc(874);
                                                               27: printesc(875);
                                                               26: printesc(876);
                                                               29: printesc(539);
                                                               24:
                                                                   BEGIN
                                                                     printesc(533);
                                                                     printdelimiter(p+4);
                                                                   END;
                                                               28:
                                                                   BEGIN
                                                                     printesc(508);
                                                                     printfamandchar(p+4);
                                                                   END;
                                                               30:
                                                                   BEGIN
                                                                     printesc(877);
                                                                     printdelimiter(p+1);
                                                                   END;
                                                               31:
                                                                   BEGIN
                                                                     printesc(878);
                                                                     printdelimiter(p+1);
                                                                   END;
                                                             END;
                                                             IF mem[p].hh.b1<>0 THEN IF mem[p].hh.b1
                                                                                        =1 THEN
                                                                                       printesc(879)
                                                             ELSE
                                                               printesc(880);
                                                             IF mem[p].hh.b0<30 THEN
                                                               printsubsidiarydata(p+1,46);
                                                             printsubsidiarydata(p+2,94);
                                                             printsubsidiarydata(p+3,95);
                                                           END{:696};
             25:{697:}
                 BEGIN
                   printesc(881);
                   IF mem[p+1].int=1073741824 THEN print(882)
                   ELSE printscaled(mem[p+1].int)
                   ;
                   IF (mem[p+4].qqqq.b0<>0)OR(mem[p+4].qqqq.b1<>0)OR(mem[p+4].qqqq.b2<>0)OR(
                      mem[p+4].qqqq.b3<>0)THEN
                     BEGIN
                       print(883);
                       printdelimiter(p+4);
                     END;
                   IF (mem[p+5].qqqq.b0<>0)OR(mem[p+5].qqqq.b1<>0)OR(mem[p+5].qqqq.b2<>0)OR(
                      mem[p+5].qqqq.b3<>0)THEN
                     BEGIN
                       print(884);
                       printdelimiter(p+5);
                     END;
                   printsubsidiarydata(p+2,92);
                   printsubsidiarydata(p+3,47);
                 END{:697};
{:690}
             ELSE print(317)
        END{:183};
      p := mem[p].hh.rh;
    END;
  10:
END;
{:182}{198:}
PROCEDURE showbox(p:halfword);
BEGIN{236:}
  depththreshold := eqtb[5288].int;
  breadthmax := eqtb[5287].int{:236};
  IF breadthmax<=0 THEN breadthmax := 5;
  IF poolptr+depththreshold>=poolsize THEN depththreshold := poolsize-
                                                             poolptr-1;
  shownodelist(p);
  println;
END;
{:198}{200:}
PROCEDURE deletetokenref(p:halfword);
BEGIN
  IF mem[p].hh.lh=0 THEN flushlist(p)
  ELSE mem[p].hh.lh := mem[p].hh.lh
                       -1;
END;{:200}{201:}
PROCEDURE deleteglueref(p:halfword);
BEGIN
  IF mem[p].hh.rh=0 THEN freenode(p,4)
  ELSE mem[p].hh.rh := mem[p].hh.
                       rh-1;
END;{:201}{202:}
PROCEDURE flushnodelist(p:halfword);

LABEL 30;

VAR q: halfword;
BEGIN
  WHILE p<>0 DO
    BEGIN
      q := mem[p].hh.rh;
      IF (p>=himemmin)THEN
        BEGIN
          mem[p].hh.rh := avail;
          avail := p;
          dynused := dynused-1;
        END
      ELSE
        BEGIN
          CASE mem[p].hh.b0 OF 
            0,1,13:
                    BEGIN
                      flushnodelist(mem[p+5].
                                    hh.rh);
                      freenode(p,7);
                      goto 30;
                    END;
            2:
               BEGIN
                 freenode(p,4);
                 goto 30;
               END;
            3:
               BEGIN
                 flushnodelist(mem[p+4].hh.lh);
                 deleteglueref(mem[p+4].hh.rh);
                 freenode(p,5);
                 goto 30;
               END;
            8:{1358:}
               BEGIN
                 CASE mem[p].hh.b1 OF 
                   0: freenode(p,3);
                   1,3:
                        BEGIN
                          deletetokenref(mem[p+1].hh.rh);
                          freenode(p,2);
                          goto 30;
                        END;
                   2,4: freenode(p,2);
                   ELSE confusion(1296)
                 END;
                 goto 30;
               END{:1358};
            10:
                BEGIN
                  BEGIN
                    IF mem[mem[p+1].hh.lh].hh.rh=0 THEN freenode(mem[p+1].hh.
                                                                 lh,4)
                    ELSE mem[mem[p+1].hh.lh].hh.rh := mem[mem[p+1].hh.lh].hh.rh-1;
                  END;
                  IF mem[p+1].hh.rh<>0 THEN flushnodelist(mem[p+1].hh.rh);
                END;
            11,9,12:;
            6: flushnodelist(mem[p+1].hh.rh);
            4: deletetokenref(mem[p+1].int);
            7:
               BEGIN
                 flushnodelist(mem[p+1].hh.lh);
                 flushnodelist(mem[p+1].hh.rh);
               END;
            5: flushnodelist(mem[p+1].int);{698:}
            14:
                BEGIN
                  freenode(p,3);
                  goto 30;
                END;
            15:
                BEGIN
                  flushnodelist(mem[p+1].hh.lh);
                  flushnodelist(mem[p+1].hh.rh);
                  flushnodelist(mem[p+2].hh.lh);
                  flushnodelist(mem[p+2].hh.rh);
                  freenode(p,3);
                  goto 30;
                END;
            16,17,18,19,20,21,22,23,24,27,26,29,28:
                                                    BEGIN
                                                      IF mem[p+1].hh.rh>=2 THEN
                                                        flushnodelist(mem[p+1].hh.lh);
                                                      IF mem[p+2].hh.rh>=2 THEN flushnodelist(mem[p+
                                                                                              2].hh.
                                                                                              lh);
                                                      IF mem[p+3].hh.rh>=2 THEN flushnodelist(mem[p+
                                                                                              3].hh.
                                                                                              lh);
                                                      IF mem[p].hh.b0=24 THEN freenode(p,5)
                                                      ELSE IF mem[p].hh.b0=28 THEN
                                                             freenode(p,5)
                                                      ELSE freenode(p,4);
                                                      goto 30;
                                                    END;
            30,31:
                   BEGIN
                     freenode(p,4);
                     goto 30;
                   END;
            25:
                BEGIN
                  flushnodelist(mem[p+2].hh.lh);
                  flushnodelist(mem[p+3].hh.lh);
                  freenode(p,6);
                  goto 30;
                END;
{:698}
            ELSE confusion(353)
          END;
          freenode(p,2);
          30:
        END;
      p := q;
    END;
END;
{:202}{204:}
FUNCTION copynodelist(p:halfword): halfword;

VAR h: halfword;
  q: halfword;
  r: halfword;
  words: 0..5;
BEGIN
  h := getavail;
  q := h;
  WHILE p<>0 DO
    BEGIN{205:}
      words := 1;
      IF (p>=himemmin)THEN r := getavail
      ELSE{206:}CASE mem[p].hh.b0 OF 
                  0,1,13:
                          BEGIN
                            r := getnode(7);
                            mem[r+6] := mem[p+6];
                            mem[r+5] := mem[p+5];
                            mem[r+5].hh.rh := copynodelist(mem[p+5].hh.rh);
                            words := 5;
                          END;
                  2:
                     BEGIN
                       r := getnode(4);
                       words := 4;
                     END;
                  3:
                     BEGIN
                       r := getnode(5);
                       mem[r+4] := mem[p+4];
                       mem[mem[p+4].hh.rh].hh.rh := mem[mem[p+4].hh.rh].hh.rh+1;
                       mem[r+4].hh.lh := copynodelist(mem[p+4].hh.lh);
                       words := 4;
                     END;
                  8:{1357:}CASE mem[p].hh.b1 OF 
                             0:
                                BEGIN
                                  r := getnode(3);
                                  words := 3;
                                END;
                             1,3:
                                  BEGIN
                                    r := getnode(2);
                                    mem[mem[p+1].hh.rh].hh.lh := mem[mem[p+1].hh.rh].hh.lh+1;
                                    words := 2;
                                  END;
                             2,4:
                                  BEGIN
                                    r := getnode(2);
                                    words := 2;
                                  END;
                             ELSE confusion(1295)
                     END{:1357};
                  10:
                      BEGIN
                        r := getnode(2);
                        mem[mem[p+1].hh.lh].hh.rh := mem[mem[p+1].hh.lh].hh.rh+1;
                        mem[r+1].hh.lh := mem[p+1].hh.lh;
                        mem[r+1].hh.rh := copynodelist(mem[p+1].hh.rh);
                      END;
                  11,9,12:
                           BEGIN
                             r := getnode(2);
                             words := 2;
                           END;
                  6:
                     BEGIN
                       r := getnode(2);
                       mem[r+1] := mem[p+1];
                       mem[r+1].hh.rh := copynodelist(mem[p+1].hh.rh);
                     END;
                  7:
                     BEGIN
                       r := getnode(2);
                       mem[r+1].hh.lh := copynodelist(mem[p+1].hh.lh);
                       mem[r+1].hh.rh := copynodelist(mem[p+1].hh.rh);
                     END;
                  4:
                     BEGIN
                       r := getnode(2);
                       mem[mem[p+1].int].hh.lh := mem[mem[p+1].int].hh.lh+1;
                       words := 2;
                     END;
                  5:
                     BEGIN
                       r := getnode(2);
                       mem[r+1].int := copynodelist(mem[p+1].int);
                     END;
                  ELSE confusion(354)
        END{:206};
      WHILE words>0 DO
        BEGIN
          words := words-1;
          mem[r+words] := mem[p+words];
        END{:205};
      mem[q].hh.rh := r;
      q := r;
      p := mem[p].hh.rh;
    END;
  mem[q].hh.rh := 0;
  q := mem[h].hh.rh;
  BEGIN
    mem[h].hh.rh := avail;
    avail := h;
    dynused := dynused-1;
  END;
  copynodelist := q;
END;{:204}{211:}
PROCEDURE printmode(m:integer);
BEGIN
  IF m>0 THEN CASE m DIV(101) OF 
                0: print(355);
                1: print(356);
                2: print(357);
    END
  ELSE IF m=0 THEN print(358)
  ELSE CASE (-m)DIV(101) OF 
         0: print(359);
         1: print(360);
         2: print(343);
    END;
  print(361);
END;
{:211}{216:}
PROCEDURE pushnest;
BEGIN
  IF nestptr>maxneststack THEN
    BEGIN
      maxneststack := nestptr;
      IF nestptr=nestsize THEN overflow(362,nestsize);
    END;
  nest[nestptr] := curlist;
  nestptr := nestptr+1;
  curlist.headfield := getavail;
  curlist.tailfield := curlist.headfield;
  curlist.pgfield := 0;
  curlist.mlfield := line;
END;{:216}{217:}
PROCEDURE popnest;
BEGIN
  BEGIN
    mem[curlist.headfield].hh.rh := avail;
    avail := curlist.headfield;
    dynused := dynused-1;
  END;
  nestptr := nestptr-1;
  curlist := nest[nestptr];
END;{:217}{218:}
PROCEDURE printtotals;
forward;
PROCEDURE showactivities;

VAR p: 0..nestsize;
  m: -203..203;
  a: memoryword;
  q,r: halfword;
  t: integer;
BEGIN
  nest[nestptr] := curlist;
  printnl(338);
  println;
  FOR p:=nestptr DOWNTO 0 DO
    BEGIN
      m := nest[p].modefield;
      a := nest[p].auxfield;
      printnl(363);
      printmode(m);
      print(364);
      printint(abs(nest[p].mlfield));
      IF m=102 THEN IF nest[p].pgfield<>8585216 THEN
                      BEGIN
                        print(365);
                        printint(nest[p].pgfield MOD 65536);
                        print(366);
                        printint(nest[p].pgfield DIV 4194304);
                        printchar(44);
                        printint((nest[p].pgfield DIV 65536)mod 64);
                        printchar(41);
                      END;
      IF nest[p].mlfield<0 THEN print(367);
      IF p=0 THEN
        BEGIN{986:}
          IF 29998<>pagetail THEN
            BEGIN
              printnl(981);
              IF outputactive THEN print(982);
              showbox(mem[29998].hh.rh);
              IF pagecontents>0 THEN
                BEGIN
                  printnl(983);
                  printtotals;
                  printnl(984);
                  printscaled(pagesofar[0]);
                  r := mem[30000].hh.rh;
                  WHILE r<>30000 DO
                    BEGIN
                      println;
                      printesc(330);
                      t := mem[r].hh.b1;
                      printint(t);
                      print(985);
                      IF eqtb[5318+t].int=1000 THEN t := mem[r+3].int
                      ELSE t := xovern(mem[r+3].
                                int,1000)*eqtb[5318+t].int;
                      printscaled(t);
                      IF mem[r].hh.b0=1 THEN
                        BEGIN
                          q := 29998;
                          t := 0;
                          REPEAT
                            q := mem[q].hh.rh;
                            IF (mem[q].hh.b0=3)AND(mem[q].hh.b1=mem[r].hh.b1)THEN t := t+1;
                          UNTIL q=mem[r+1].hh.lh;
                          print(986);
                          printint(t);
                          print(987);
                        END;
                      r := mem[r].hh.rh;
                    END;
                END;
            END{:986};
          IF mem[29999].hh.rh<>0 THEN printnl(368);
        END;
      showbox(mem[nest[p].headfield].hh.rh);
{219:}
      CASE abs(m)DIV(101) OF 
        0:
           BEGIN
             printnl(369);
             IF a.int<=-65536000 THEN print(370)
             ELSE printscaled(a.int);
             IF nest[p].pgfield<>0 THEN
               BEGIN
                 print(371);
                 printint(nest[p].pgfield);
                 print(372);
                 IF nest[p].pgfield<>1 THEN printchar(115);
               END;
           END;
        1:
           BEGIN
             printnl(373);
             printint(a.hh.lh);
             IF m>0 THEN IF a.hh.rh>0 THEN
                           BEGIN
                             print(374);
                             printint(a.hh.rh);
                           END;
           END;
        2: IF a.int<>0 THEN
             BEGIN
               print(375);
               showbox(a.int);
             END;
      END{:219};
    END;
END;{:218}{237:}
PROCEDURE printparam(n:integer);
BEGIN
  CASE n OF 
    0: printesc(420);
    1: printesc(421);
    2: printesc(422);
    3: printesc(423);
    4: printesc(424);
    5: printesc(425);
    6: printesc(426);
    7: printesc(427);
    8: printesc(428);
    9: printesc(429);
    10: printesc(430);
    11: printesc(431);
    12: printesc(432);
    13: printesc(433);
    14: printesc(434);
    15: printesc(435);
    16: printesc(436);
    17: printesc(437);
    18: printesc(438);
    19: printesc(439);
    20: printesc(440);
    21: printesc(441);
    22: printesc(442);
    23: printesc(443);
    24: printesc(444);
    25: printesc(445);
    26: printesc(446);
    27: printesc(447);
    28: printesc(448);
    29: printesc(449);
    30: printesc(450);
    31: printesc(451);
    32: printesc(452);
    33: printesc(453);
    34: printesc(454);
    35: printesc(455);
    36: printesc(456);
    37: printesc(457);
    38: printesc(458);
    39: printesc(459);
    40: printesc(460);
    41: printesc(461);
    42: printesc(462);
    43: printesc(463);
    44: printesc(464);
    45: printesc(465);
    46: printesc(466);
    47: printesc(467);
    48: printesc(468);
    49: printesc(469);
    50: printesc(470);
    51: printesc(471);
    52: printesc(472);
    53: printesc(473);
    54: printesc(474);
    ELSE print(475)
  END;
END;{:237}{241:}
PROCEDURE fixdateandtime;

VAR yy,mm,dd: word;
  hh,ss,ms: word;
BEGIN
  decodedate(now,yy,mm,dd);
  sysday := dd;
  eqtb[5284].int := sysday;
  sysmonth := mm;
  eqtb[5285].int := sysmonth;
  sysyear := yy;
  eqtb[5286].int := sysyear;
  decodetime(now,hh,mm,ss,ms);
  systime := hh*60+mm;
  eqtb[5283].int := systime;
END;
{:241}{245:}
PROCEDURE begindiagnostic;
BEGIN
  oldsetting := selector;
  IF (eqtb[5292].int<=0)AND(selector=19)THEN
    BEGIN
      selector := selector-1;
      IF history=0 THEN history := 1;
    END;
END;
PROCEDURE enddiagnostic(blankline:boolean);
BEGIN
  printnl(338);
  IF blankline THEN println;
  selector := oldsetting;
END;
{:245}{247:}
PROCEDURE printlengthparam(n:integer);
BEGIN
  CASE n OF 
    0: printesc(478);
    1: printesc(479);
    2: printesc(480);
    3: printesc(481);
    4: printesc(482);
    5: printesc(483);
    6: printesc(484);
    7: printesc(485);
    8: printesc(486);
    9: printesc(487);
    10: printesc(488);
    11: printesc(489);
    12: printesc(490);
    13: printesc(491);
    14: printesc(492);
    15: printesc(493);
    16: printesc(494);
    17: printesc(495);
    18: printesc(496);
    19: printesc(497);
    20: printesc(498);
    ELSE print(499)
  END;
END;
{:247}{252:}{298:}
PROCEDURE printcmdchr(cmd:quarterword;
                      chrcode:halfword);
BEGIN
  CASE cmd OF 
    1:
       BEGIN
         print(557);
         print(chrcode);
       END;
    2:
       BEGIN
         print(558);
         print(chrcode);
       END;
    3:
       BEGIN
         print(559);
         print(chrcode);
       END;
    6:
       BEGIN
         print(560);
         print(chrcode);
       END;
    7:
       BEGIN
         print(561);
         print(chrcode);
       END;
    8:
       BEGIN
         print(562);
         print(chrcode);
       END;
    9: print(563);
    10:
        BEGIN
          print(564);
          print(chrcode);
        END;
    11:
        BEGIN
          print(565);
          print(chrcode);
        END;
    12:
        BEGIN
          print(566);
          print(chrcode);
        END;
{227:}
    75,76: IF chrcode<2900 THEN printskipparam(chrcode-2882)
           ELSE IF 
                   chrcode<3156 THEN
                  BEGIN
                    printesc(395);
                    printint(chrcode-2900);
                  END
           ELSE
             BEGIN
               printesc(396);
               printint(chrcode-3156);
             END;
{:227}{231:}
    72: IF chrcode>=3422 THEN
          BEGIN
            printesc(407);
            printint(chrcode-3422);
          END
        ELSE CASE chrcode OF 
               3413: printesc(398);
               3414: printesc(399);
               3415: printesc(400);
               3416: printesc(401);
               3417: printesc(402);
               3418: printesc(403);
               3419: printesc(404);
               3420: printesc(405);
               ELSE printesc(406)
          END;
{:231}{239:}
    73: IF chrcode<5318 THEN printparam(chrcode-5263)
        ELSE
          BEGIN
            printesc(476);
            printint(chrcode-5318);
          END;
{:239}{249:}
    74: IF chrcode<5851 THEN printlengthparam(chrcode-5830)
        ELSE
          BEGIN
            printesc(500);
            printint(chrcode-5851);
          END;
{:249}{266:}
    45: printesc(508);
    90: printesc(509);
    40: printesc(510);
    41: printesc(511);
    77: printesc(519);
    61: printesc(512);
    42: printesc(531);
    16: printesc(513);
    107: printesc(504);
    88: printesc(518);
    15: printesc(514);
    92: printesc(515);
    67: printesc(505);
    62: printesc(516);
    64: printesc(32);
    102: printesc(517);
    32: printesc(520);
    36: printesc(521);
    39: printesc(522);
    37: printesc(330);
    44: printesc(47);
    18: printesc(351);
    46: printesc(523);
    17: printesc(524);
    54: printesc(525);
    91: printesc(526);
    34: printesc(527);
    65: printesc(528);
    103: printesc(529);
    55: printesc(335);
    63: printesc(530);
    66: printesc(533);
    96: printesc(534);
    0: printesc(535);
    98: printesc(536);
    80: printesc(532);
    84: printesc(408);
    109: printesc(537);
    71: printesc(407);
    38: printesc(352);
    33: printesc(538);
    56: printesc(539);
    35: printesc(540);
{:266}{335:}
    13: printesc(597);
{:335}{377:}
    104: IF chrcode=0 THEN printesc(629)
         ELSE printesc(630);
{:377}{385:}
    110: CASE chrcode OF 
           1: printesc(632);
           2: printesc(633);
           3: printesc(634);
           4: printesc(635);
           ELSE printesc(631)
         END;
{:385}{412:}
    89: IF chrcode=0 THEN printesc(476)
        ELSE IF chrcode=1 THEN
               printesc(500)
        ELSE IF chrcode=2 THEN printesc(395)
        ELSE printesc(396);
{:412}{417:}
    79: IF chrcode=1 THEN printesc(669)
        ELSE printesc(668);
    82: IF chrcode=0 THEN printesc(670)
        ELSE printesc(671);
    83: IF chrcode=1 THEN printesc(672)
        ELSE IF chrcode=3 THEN printesc(673)
        ELSE printesc(674);
    70: CASE chrcode OF 
          0: printesc(675);
          1: printesc(676);
          2: printesc(677);
          3: printesc(678);
          ELSE printesc(679)
        END;
{:417}{469:}
    108: CASE chrcode OF 
           0: printesc(735);
           1: printesc(736);
           2: printesc(737);
           3: printesc(738);
           4: printesc(739);
           ELSE printesc(740)
         END;
{:469}{488:}
    105: CASE chrcode OF 
           1: printesc(758);
           2: printesc(759);
           3: printesc(760);
           4: printesc(761);
           5: printesc(762);
           6: printesc(763);
           7: printesc(764);
           8: printesc(765);
           9: printesc(766);
           10: printesc(767);
           11: printesc(768);
           12: printesc(769);
           13: printesc(770);
           14: printesc(771);
           15: printesc(772);
           16: printesc(773);
           ELSE printesc(757)
         END;
{:488}{492:}
    106: IF chrcode=2 THEN printesc(774)
         ELSE IF chrcode=4 THEN
                printesc(775)
         ELSE printesc(776);
{:492}{781:}
    4: IF chrcode=256 THEN printesc(899)
       ELSE
         BEGIN
           print(903);
           print(chrcode);
         END;
    5: IF chrcode=257 THEN printesc(900)
       ELSE printesc(901);
{:781}{984:}
    81: CASE chrcode OF 
          0: printesc(971);
          1: printesc(972);
          2: printesc(973);
          3: printesc(974);
          4: printesc(975);
          5: printesc(976);
          6: printesc(977);
          ELSE printesc(978)
        END;
{:984}{1053:}
    14: IF chrcode=1 THEN printesc(1027)
        ELSE printesc(1026);
{:1053}{1059:}
    26: CASE chrcode OF 
          4: printesc(1028);
          0: printesc(1029);
          1: printesc(1030);
          2: printesc(1031);
          ELSE printesc(1032)
        END;
    27: CASE chrcode OF 
          4: printesc(1033);
          0: printesc(1034);
          1: printesc(1035);
          2: printesc(1036);
          ELSE printesc(1037)
        END;
    28: printesc(336);
    29: printesc(340);
    30: printesc(342);
{:1059}{1072:}
    21: IF chrcode=1 THEN printesc(1055)
        ELSE printesc(1056);
    22: IF chrcode=1 THEN printesc(1057)
        ELSE printesc(1058);
    20: CASE chrcode OF 
          0: printesc(409);
          1: printesc(1059);
          2: printesc(1060);
          3: printesc(966);
          4: printesc(1061);
          5: printesc(968);
          ELSE printesc(1062)
        END;
    31: IF chrcode=100 THEN printesc(1064)
        ELSE IF chrcode=101 THEN printesc(
                                          1065)
        ELSE IF chrcode=102 THEN printesc(1066)
        ELSE printesc(1063);
{:1072}{1089:}
    43: IF chrcode=0 THEN printesc(1082)
        ELSE printesc(1081);
{:1089}{1108:}
    25: IF chrcode=10 THEN printesc(1093)
        ELSE IF chrcode=11
               THEN printesc(1092)
        ELSE printesc(1091);
    23: IF chrcode=1 THEN printesc(1095)
        ELSE printesc(1094);
    24: IF chrcode=1 THEN printesc(1097)
        ELSE printesc(1096);
{:1108}{1115:}
    47: IF chrcode=1 THEN printesc(45)
        ELSE printesc(349);
{:1115}{1143:}
    48: IF chrcode=1 THEN printesc(1129)
        ELSE printesc(1128);
{:1143}{1157:}
    50: CASE chrcode OF 
          16: printesc(867);
          17: printesc(868);
          18: printesc(869);
          19: printesc(870);
          20: printesc(871);
          21: printesc(872);
          22: printesc(873);
          23: printesc(874);
          26: printesc(876);
          ELSE printesc(875)
        END;
    51: IF chrcode=1 THEN printesc(879)
        ELSE IF chrcode=2 THEN printesc(880)
        ELSE printesc(1130);{:1157}{1170:}
    53: printstyle(chrcode);
{:1170}{1179:}
    52: CASE chrcode OF 
          1: printesc(1149);
          2: printesc(1150);
          3: printesc(1151);
          4: printesc(1152);
          5: printesc(1153);
          ELSE printesc(1148)
        END;
{:1179}{1189:}
    49: IF chrcode=30 THEN printesc(877)
        ELSE printesc(878);
{:1189}{1209:}
    93: IF chrcode=1 THEN printesc(1172)
        ELSE IF chrcode=2 THEN
               printesc(1173)
        ELSE printesc(1174);
    97: IF chrcode=0 THEN printesc(1175)
        ELSE IF chrcode=1 THEN printesc(1176)
        ELSE IF chrcode=2 THEN printesc(1177)
        ELSE printesc(1178);
{:1209}{1220:}
    94: IF chrcode<>0 THEN printesc(1193)
        ELSE printesc(1192);
{:1220}{1223:}
    95: CASE chrcode OF 
          0: printesc(1194);
          1: printesc(1195);
          2: printesc(1196);
          3: printesc(1197);
          4: printesc(1198);
          5: printesc(1199);
          ELSE printesc(1200)
        END;
    68:
        BEGIN
          printesc(513);
          printhex(chrcode);
        END;
    69:
        BEGIN
          printesc(524);
          printhex(chrcode);
        END;
{:1223}{1231:}
    85: IF chrcode=3983 THEN printesc(415)
        ELSE IF chrcode=5007
               THEN printesc(419)
        ELSE IF chrcode=4239 THEN printesc(416)
        ELSE IF chrcode
                =4495 THEN printesc(417)
        ELSE IF chrcode=4751 THEN printesc(418)
        ELSE
          printesc(477);
    86: printsize(chrcode-3935);
{:1231}{1251:}
    99: IF chrcode=1 THEN printesc(954)
        ELSE printesc(942);
{:1251}{1255:}
    78: IF chrcode=0 THEN printesc(1218)
        ELSE printesc(1219);
{:1255}{1261:}
    87:
        BEGIN
          print(1227);
          slowprint(fontname[chrcode]);
          IF fontsize[chrcode]<>fontdsize[chrcode]THEN
            BEGIN
              print(741);
              printscaled(fontsize[chrcode]);
              print(397);
            END;
        END;
{:1261}{1263:}
    100: CASE chrcode OF 
           0: printesc(274);
           1: printesc(275);
           2: printesc(276);
           ELSE printesc(1228)
         END;
{:1263}{1273:}
    60: IF chrcode=0 THEN printesc(1230)
        ELSE printesc(1229);
{:1273}{1278:}
    58: IF chrcode=0 THEN printesc(1231)
        ELSE printesc(1232);
{:1278}{1287:}
    57: IF chrcode=4239 THEN printesc(1238)
        ELSE printesc(1239);
{:1287}{1292:}
    19: CASE chrcode OF 
          1: printesc(1241);
          2: printesc(1242);
          3: printesc(1243);
          ELSE printesc(1240)
        END;{:1292}{1295:}
    101: print(1250);
    111: print(1251);
    112: printesc(1252);
    113: printesc(1253);
    114:
         BEGIN
           printesc(1172);
           printesc(1253);
         END;
    115: printesc(1254);
{:1295}{1346:}
    59: CASE chrcode OF 
          0: printesc(1286);
          1: printesc(594);
          2: printesc(1287);
          3: printesc(1288);
          4: printesc(1289);
          5: printesc(1290);
          ELSE print(1291)
        END;{:1346}
    ELSE print(567)
  END;
END;
{:298}
PROCEDURE showeqtb(n:halfword);
BEGIN
  IF n<1 THEN printchar(63)
  ELSE IF n<2882 THEN{223:}
         BEGIN
           sprintcs(n
           );
           printchar(61);
           printcmdchr(eqtb[n].hh.b0,eqtb[n].hh.rh);
           IF eqtb[n].hh.b0>=111 THEN
             BEGIN
               printchar(58);
               showtokenlist(mem[eqtb[n].hh.rh].hh.rh,0,32);
             END;
         END{:223}
  ELSE IF n<3412 THEN{229:}IF n<2900 THEN
                             BEGIN
                               printskipparam(n
                                              -2882);
                               printchar(61);
                               IF n<2897 THEN printspec(eqtb[n].hh.rh,397)
                               ELSE printspec(eqtb[n].hh.rh,
                                              337);
                             END
  ELSE IF n<3156 THEN
         BEGIN
           printesc(395);
           printint(n-2900);
           printchar(61);
           printspec(eqtb[n].hh.rh,397);
         END
  ELSE
    BEGIN
      printesc(396);
      printint(n-3156);
      printchar(61);
      printspec(eqtb[n].hh.rh,337);
    END{:229}
  ELSE IF n<5263 THEN{233:}IF n=3412 THEN
                             BEGIN
                               printesc(408);
                               printchar(61);
                               IF eqtb[3412].hh.rh=0 THEN printchar(48)
                               ELSE printint(mem[eqtb[3412].hh.
                                             rh].hh.lh);
                             END
  ELSE IF n<3422 THEN
         BEGIN
           printcmdchr(72,n);
           printchar(61);
           IF eqtb[n].hh.rh<>0 THEN showtokenlist(mem[eqtb[n].hh.rh].hh.rh,0,32);
         END
  ELSE IF n<3678 THEN
         BEGIN
           printesc(407);
           printint(n-3422);
           printchar(61);
           IF eqtb[n].hh.rh<>0 THEN showtokenlist(mem[eqtb[n].hh.rh].hh.rh,0,32);
         END
  ELSE IF n<3934 THEN
         BEGIN
           printesc(409);
           printint(n-3678);
           printchar(61);
           IF eqtb[n].hh.rh=0 THEN print(410)
           ELSE
             BEGIN
               depththreshold := 0;
               breadthmax := 1;
               shownodelist(eqtb[n].hh.rh);
             END;
         END
  ELSE IF n<3983 THEN{234:}
         BEGIN
           IF n=3934 THEN print(411)
           ELSE IF n<
                   3951 THEN
                  BEGIN
                    printesc(412);
                    printint(n-3935);
                  END
           ELSE IF n<3967 THEN
                  BEGIN
                    printesc(413);
                    printint(n-3951);
                  END
           ELSE
             BEGIN
               printesc(414);
               printint(n-3967);
             END;
           printchar(61);
           printesc(hash[2624+eqtb[n].hh.rh].rh);
         END{:234}
  ELSE{235:}IF n<5007 THEN
              BEGIN
                IF n<4239 THEN
                  BEGIN
                    printesc(
                             415);
                    printint(n-3983);
                  END
                ELSE IF n<4495 THEN
                       BEGIN
                         printesc(416);
                         printint(n-4239);
                       END
                ELSE IF n<4751 THEN
                       BEGIN
                         printesc(417);
                         printint(n-4495);
                       END
                ELSE
                  BEGIN
                    printesc(418);
                    printint(n-4751);
                  END;
                printchar(61);
                printint(eqtb[n].hh.rh);
              END
  ELSE
    BEGIN
      printesc(419);
      printint(n-5007);
      printchar(61);
      printint(eqtb[n].hh.rh);
    END{:235}{:233}
  ELSE IF n<5830 THEN{242:}
         BEGIN
           IF n<5318 THEN printparam(
                                     n-5263)
           ELSE IF n<5574 THEN
                  BEGIN
                    printesc(476);
                    printint(n-5318);
                  END
           ELSE
             BEGIN
               printesc(477);
               printint(n-5574);
             END;
           printchar(61);
           printint(eqtb[n].int);
         END{:242}
  ELSE IF n<=6106 THEN{251:}
         BEGIN
           IF n<5851 THEN printlengthparam
             (n-5830)
           ELSE
             BEGIN
               printesc(500);
               printint(n-5851);
             END;
           printchar(61);
           printscaled(eqtb[n].int);
           print(397);
         END{:251}
  ELSE printchar(63);
END;
{:252}{259:}
FUNCTION idlookup(j,l:integer): halfword;

LABEL 40;

VAR h: integer;
  d: integer;
  p: halfword;
  k: halfword;
BEGIN{261:}
  h := buffer[j];
  FOR k:=j+1 TO j+l-1 DO
    BEGIN
      h := h+h+buffer[k];
      WHILE h>=1777 DO
        h := h-1777;
    END{:261};
  p := h+514;
  WHILE true DO
    BEGIN
      IF hash[p].rh>0 THEN IF (strstart[hash[p].rh+1]-
                              strstart[hash[p].rh])=l THEN IF streqbuf(hash[p].rh,j)THEN goto 40;
      IF hash[p].lh=0 THEN
        BEGIN
          IF nonewcontrolsequence THEN p := 2881
          ELSE
{260:}
            BEGIN
              IF hash[p].rh>0 THEN
                BEGIN
                  REPEAT
                    IF (hashused=514)THEN
                      overflow(503,2100);
                    hashused := hashused-1;
                  UNTIL hash[hashused].rh=0;
                  hash[p].lh := hashused;
                  p := hashused;
                END;
              BEGIN
                IF poolptr+l>poolsize THEN overflow(257,poolsize-initpoolptr);
              END;
              d := (poolptr-strstart[strptr]);
              WHILE poolptr>strstart[strptr] DO
                BEGIN
                  poolptr := poolptr-1;
                  strpool[poolptr+l] := strpool[poolptr];
                END;
              FOR k:=j TO j+l-1 DO
                BEGIN
                  strpool[poolptr] := buffer[k];
                  poolptr := poolptr+1;
                END;
              hash[p].rh := makestring;
              poolptr := poolptr+d;
              cscount := cscount+1;
            END{:260};
          goto 40;
        END;
      p := hash[p].lh;
    END;
  40: idlookup := p;
END;{:259}{264:}
PROCEDURE primitive(s:strnumber;
                    c:quarterword;o:halfword);

VAR k: poolpointer;
  j: smallnumber;
  l: smallnumber;
BEGIN
  IF s<256 THEN curval := s+257
  ELSE
    BEGIN
      k := strstart[s];
      l := strstart[s+1]-k;
      FOR j:=0 TO l-1 DO
        buffer[j] := strpool[k+j];
      curval := idlookup(0,l);
      BEGIN
        strptr := strptr-1;
        poolptr := strstart[strptr];
      END;
      hash[curval].rh := s;
    END;
  eqtb[curval].hh.b1 := 1;
  eqtb[curval].hh.b0 := c;
  eqtb[curval].hh.rh := o;
END;
{:264}{274:}
PROCEDURE newsavelevel(c:groupcode);
BEGIN
  IF saveptr>maxsavestack THEN
    BEGIN
      maxsavestack := saveptr;
      IF maxsavestack>savesize-6 THEN overflow(541,savesize);
    END;
  savestack[saveptr].hh.b0 := 3;
  savestack[saveptr].hh.b1 := curgroup;
  savestack[saveptr].hh.rh := curboundary;
  IF curlevel=255 THEN overflow(542,255);
  curboundary := saveptr;
  curlevel := curlevel+1;
  saveptr := saveptr+1;
  curgroup := c;
END;
{:274}{275:}
PROCEDURE eqdestroy(w:memoryword);

VAR q: halfword;
BEGIN
  CASE w.hh.b0 OF 
    111,112,113,114: deletetokenref(w.hh.rh);
    117: deleteglueref(w.hh.rh);
    118:
         BEGIN
           q := w.hh.rh;
           IF q<>0 THEN freenode(q,mem[q].hh.lh+mem[q].hh.lh+1);
         END;
    119: flushnodelist(w.hh.rh);
    ELSE
  END;
END;
{:275}{276:}
PROCEDURE eqsave(p:halfword;l:quarterword);
BEGIN
  IF saveptr>maxsavestack THEN
    BEGIN
      maxsavestack := saveptr;
      IF maxsavestack>savesize-6 THEN overflow(541,savesize);
    END;
  IF l=0 THEN savestack[saveptr].hh.b0 := 1
  ELSE
    BEGIN
      savestack[saveptr] := 
                            eqtb[p];
      saveptr := saveptr+1;
      savestack[saveptr].hh.b0 := 0;
    END;
  savestack[saveptr].hh.b1 := l;
  savestack[saveptr].hh.rh := p;
  saveptr := saveptr+1;
END;{:276}{277:}
PROCEDURE eqdefine(p:halfword;
                   t:quarterword;e:halfword);
BEGIN
  IF eqtb[p].hh.b1=curlevel THEN eqdestroy(eqtb[p])
  ELSE IF curlevel>
          1 THEN eqsave(p,eqtb[p].hh.b1);
  eqtb[p].hh.b1 := curlevel;
  eqtb[p].hh.b0 := t;
  eqtb[p].hh.rh := e;
END;{:277}{278:}
PROCEDURE eqworddefine(p:halfword;
                       w:integer);
BEGIN
  IF xeqlevel[p]<>curlevel THEN
    BEGIN
      eqsave(p,xeqlevel[p]);
      xeqlevel[p] := curlevel;
    END;
  eqtb[p].int := w;
END;
{:278}{279:}
PROCEDURE geqdefine(p:halfword;t:quarterword;e:halfword);
BEGIN
  eqdestroy(eqtb[p]);
  eqtb[p].hh.b1 := 1;
  eqtb[p].hh.b0 := t;
  eqtb[p].hh.rh := e;
END;
PROCEDURE geqworddefine(p:halfword;w:integer);
BEGIN
  eqtb[p].int := w;
  xeqlevel[p] := 1;
END;
{:279}{280:}
PROCEDURE saveforafter(t:halfword);
BEGIN
  IF curlevel>1 THEN
    BEGIN
      IF saveptr>maxsavestack THEN
        BEGIN
          maxsavestack := saveptr;
          IF maxsavestack>savesize-6 THEN overflow(541,savesize);
        END;
      savestack[saveptr].hh.b0 := 2;
      savestack[saveptr].hh.b1 := 0;
      savestack[saveptr].hh.rh := t;
      saveptr := saveptr+1;
    END;
END;
{:280}{281:}{284:}
PROCEDURE restoretrace(p:halfword;s:strnumber);
BEGIN
  begindiagnostic;
  printchar(123);
  print(s);
  printchar(32);
  showeqtb(p);
  printchar(125);
  enddiagnostic(false);
END;{:284}
PROCEDURE backinput;
forward;
PROCEDURE unsave;

LABEL 30;

VAR p: halfword;
  l: quarterword;
  t: halfword;
BEGIN
  IF curlevel>1 THEN
    BEGIN
      curlevel := curlevel-1;
{282:}
      WHILE true DO
        BEGIN
          saveptr := saveptr-1;
          IF savestack[saveptr].hh.b0=3 THEN goto 30;
          p := savestack[saveptr].hh.rh;
          IF savestack[saveptr].hh.b0=2 THEN{326:}
            BEGIN
              t := curtok;
              curtok := p;
              backinput;
              curtok := t;
            END{:326}
          ELSE
            BEGIN
              IF savestack[saveptr].hh.b0=0 THEN
                BEGIN
                  l := 
                       savestack[saveptr].hh.b1;
                  saveptr := saveptr-1;
                END
              ELSE savestack[saveptr] := eqtb[2881];
{283:}
              IF p<5263 THEN IF eqtb[p].hh.b1=1 THEN
                               BEGIN
                                 eqdestroy(savestack[
                                           saveptr]);
                                 IF eqtb[5300].int>0 THEN restoretrace(p,544);
                               END
              ELSE
                BEGIN
                  eqdestroy(eqtb[p]);
                  eqtb[p] := savestack[saveptr];
                  IF eqtb[5300].int>0 THEN restoretrace(p,545);
                END
              ELSE IF xeqlevel[p]<>1 THEN
                     BEGIN
                       eqtb[p] := savestack[saveptr];
                       xeqlevel[p] := l;
                       IF eqtb[5300].int>0 THEN restoretrace(p,545);
                     END
              ELSE
                BEGIN
                  IF eqtb[5300].int>0 THEN restoretrace(p,544);
                END{:283};
            END;
        END;
      30: curgroup := savestack[saveptr].hh.b1;
      curboundary := savestack[saveptr].hh.rh{:282};
    END
  ELSE confusion(543);
END;
{:281}{288:}
PROCEDURE preparemag;
BEGIN
  IF (magset>0)AND(eqtb[5280].int<>magset)THEN
    BEGIN
      BEGIN
        IF 
           interaction=3 THEN;
        printnl(262);
        print(547);
      END;
      printint(eqtb[5280].int);
      print(548);
      printnl(549);
      BEGIN
        helpptr := 2;
        helpline[1] := 550;
        helpline[0] := 551;
      END;
      interror(magset);
      geqworddefine(5280,magset);
    END;
  IF (eqtb[5280].int<=0)OR(eqtb[5280].int>32768)THEN
    BEGIN
      BEGIN
        IF 
           interaction=3 THEN;
        printnl(262);
        print(552);
      END;
      BEGIN
        helpptr := 1;
        helpline[0] := 553;
      END;
      interror(eqtb[5280].int);
      geqworddefine(5280,1000);
    END;
  magset := eqtb[5280].int;
END;
{:288}{295:}
PROCEDURE tokenshow(p:halfword);
BEGIN
  IF p<>0 THEN showtokenlist(mem[p].hh.rh,0,10000000);
END;
{:295}{296:}
PROCEDURE printmeaning;
BEGIN
  printcmdchr(curcmd,curchr);
  IF curcmd>=111 THEN
    BEGIN
      printchar(58);
      println;
      tokenshow(curchr);
    END
  ELSE IF curcmd=110 THEN
         BEGIN
           printchar(58);
           println;
           tokenshow(curmark[curchr]);
         END;
END;{:296}{299:}
PROCEDURE showcurcmdchr;
BEGIN
  begindiagnostic;
  printnl(123);
  IF curlist.modefield<>shownmode THEN
    BEGIN
      printmode(curlist.modefield);
      print(568);
      shownmode := curlist.modefield;
    END;
  printcmdchr(curcmd,curchr);
  printchar(125);
  enddiagnostic(false);
END;
{:299}{311:}
PROCEDURE showcontext;

LABEL 30;

VAR oldsetting: 0..21;
  nn: integer;
  bottomline: boolean;{315:}
  i: 0..bufsize;
  j: 0..bufsize;
  l: 0..halferrorline;
  m: integer;
  n: 0..errorline;
  p: integer;
  q: integer;
{:315}
BEGIN
  baseptr := inputptr;
  inputstack[baseptr] := curinput;
  nn := -1;
  bottomline := false;
  WHILE true DO
    BEGIN
      curinput := inputstack[baseptr];
      IF (curinput.statefield<>0)THEN IF (curinput.namefield>17)OR(baseptr=0)
                                        THEN bottomline := true;
      IF (baseptr=inputptr)OR bottomline OR(nn<eqtb[5317].int)THEN{312:}
        BEGIN
          IF (baseptr=inputptr)OR(curinput.statefield<>0)OR(curinput.indexfield<>3)
             OR(curinput.locfield<>0)THEN
            BEGIN
              tally := 0;
              oldsetting := selector;
              IF curinput.statefield<>0 THEN
                BEGIN{313:}
                  IF curinput.namefield<=17 THEN
                    IF (curinput.namefield=0)THEN IF baseptr=0 THEN printnl(574)
                  ELSE printnl(
                               575)
                  ELSE
                    BEGIN
                      printnl(576);
                      IF curinput.namefield=17 THEN printchar(42)
                      ELSE printint(curinput.
                                    namefield-1);
                      printchar(62);
                    END
                  ELSE
                    BEGIN
                      printnl(577);
                      printint(line);
                    END;
                  printchar(32){:313};{318:}
                  BEGIN
                    l := tally;
                    tally := 0;
                    selector := 20;
                    trickcount := 1000000;
                  END;
                  IF buffer[curinput.limitfield]=eqtb[5311].int THEN j := curinput.
                                                                          limitfield
                  ELSE j := curinput.limitfield+1;
                  IF j>0 THEN FOR i:=curinput.startfield TO j-1 DO
                                BEGIN
                                  IF i=curinput.
                                     locfield THEN
                                    BEGIN
                                      firstcount := tally;
                                      trickcount := tally+1+errorline-halferrorline;
                                      IF trickcount<errorline THEN trickcount := errorline;
                                    END;
                                  print(buffer[i]);
                                END{:318};
                END
              ELSE
                BEGIN{314:}
                  CASE curinput.indexfield OF 
                    0: printnl(578);
                    1,2: printnl(579);
                    3: IF curinput.locfield=0 THEN printnl(580)
                       ELSE printnl(581);
                    4: printnl(582);
                    5:
                       BEGIN
                         println;
                         printcs(curinput.namefield);
                       END;
                    6: printnl(583);
                    7: printnl(584);
                    8: printnl(585);
                    9: printnl(586);
                    10: printnl(587);
                    11: printnl(588);
                    12: printnl(589);
                    13: printnl(590);
                    14: printnl(591);
                    15: printnl(592);
                    ELSE printnl(63)
                  END{:314};
{319:}
                  BEGIN
                    l := tally;
                    tally := 0;
                    selector := 20;
                    trickcount := 1000000;
                  END;
                  IF curinput.indexfield<5 THEN showtokenlist(curinput.startfield,curinput
                                                              .locfield,100000)
                  ELSE showtokenlist(mem[curinput.startfield].hh.rh,
                                     curinput.locfield,100000){:319};
                END;
              selector := oldsetting;
{317:}
              IF trickcount=1000000 THEN
                BEGIN
                  firstcount := tally;
                  trickcount := tally+1+errorline-halferrorline;
                  IF trickcount<errorline THEN trickcount := errorline;
                END;
              IF tally<trickcount THEN m := tally-firstcount
              ELSE m := trickcount-
                        firstcount;
              IF l+firstcount<=halferrorline THEN
                BEGIN
                  p := 0;
                  n := l+firstcount;
                END
              ELSE
                BEGIN
                  print(277);
                  p := l+firstcount-halferrorline+3;
                  n := halferrorline;
                END;
              FOR q:=p TO firstcount-1 DO
                printchar(trickbuf[q MOD errorline]);
              println;
              FOR q:=1 TO n DO
                printchar(32);
              IF m+n<=errorline THEN p := firstcount+m
              ELSE p := firstcount+(errorline-n-3
                        );
              FOR q:=firstcount TO p-1 DO
                printchar(trickbuf[q MOD errorline]);
              IF m+n>errorline THEN print(277){:317};
              nn := nn+1;
            END;
        END{:312}
      ELSE IF nn=eqtb[5317].int THEN
             BEGIN
               printnl(277);
               nn := nn+1;
             END;
      IF bottomline THEN goto 30;
      baseptr := baseptr-1;
    END;
  30: curinput := inputstack[inputptr];
END;
{:311}{323:}
PROCEDURE begintokenlist(p:halfword;t:quarterword);
BEGIN
  BEGIN
    IF inputptr>maxinstack THEN
      BEGIN
        maxinstack := inputptr;
        IF inputptr=stacksize THEN overflow(593,stacksize);
      END;
    inputstack[inputptr] := curinput;
    inputptr := inputptr+1;
  END;
  curinput.statefield := 0;
  curinput.startfield := p;
  curinput.indexfield := t;
  IF t>=5 THEN
    BEGIN
      mem[p].hh.lh := mem[p].hh.lh+1;
      IF t=5 THEN curinput.limitfield := paramptr
      ELSE
        BEGIN
          curinput.locfield := 
                               mem[p].hh.rh;
          IF eqtb[5293].int>1 THEN
            BEGIN
              begindiagnostic;
              printnl(338);
              CASE t OF 
                14: printesc(351);
                15: printesc(594);
                ELSE printcmdchr(72,t+3407)
              END;
              print(556);
              tokenshow(p);
              enddiagnostic(false);
            END;
        END;
    END
  ELSE curinput.locfield := p;
END;
{:323}{324:}
PROCEDURE endtokenlist;
BEGIN
  IF curinput.indexfield>=3 THEN
    BEGIN
      IF curinput.indexfield<=4
        THEN flushlist(curinput.startfield)
      ELSE
        BEGIN
          deletetokenref(curinput.
                         startfield);
          IF curinput.indexfield=5 THEN WHILE paramptr>curinput.limitfield DO
                                          BEGIN
                                            paramptr := paramptr-1;
                                            flushlist(paramstack[paramptr]);
                                          END;
        END;
    END
  ELSE IF curinput.indexfield=1 THEN IF alignstate>500000 THEN
                                       alignstate := 0
  ELSE fatalerror(595);
  BEGIN
    inputptr := inputptr-1;
    curinput := inputstack[inputptr];
  END;
  BEGIN
    IF interrupt<>0 THEN pauseforinstructions;
  END;
END;
{:324}{325:}
PROCEDURE backinput;

VAR p: halfword;
BEGIN
  WHILE (curinput.statefield=0)AND(curinput.locfield=0)AND(curinput.
        indexfield<>2) DO
    endtokenlist;
  p := getavail;
  mem[p].hh.lh := curtok;
  IF curtok<768 THEN IF curtok<512 THEN alignstate := alignstate-1
  ELSE
    alignstate := alignstate+1;
  BEGIN
    IF inputptr>maxinstack THEN
      BEGIN
        maxinstack := inputptr;
        IF inputptr=stacksize THEN overflow(593,stacksize);
      END;
    inputstack[inputptr] := curinput;
    inputptr := inputptr+1;
  END;
  curinput.statefield := 0;
  curinput.startfield := p;
  curinput.indexfield := 3;
  curinput.locfield := p;
END;{:325}{327:}
PROCEDURE backerror;
BEGIN
  OKtointerrupt := false;
  backinput;
  OKtointerrupt := true;
  error;
END;
PROCEDURE inserror;
BEGIN
  OKtointerrupt := false;
  backinput;
  curinput.indexfield := 4;
  OKtointerrupt := true;
  error;
END;
{:327}{328:}
PROCEDURE beginfilereading;
BEGIN
  IF inopen=maxinopen THEN overflow(596,maxinopen);
  IF first=bufsize THEN overflow(256,bufsize);
  inopen := inopen+1;
  BEGIN
    IF inputptr>maxinstack THEN
      BEGIN
        maxinstack := inputptr;
        IF inputptr=stacksize THEN overflow(593,stacksize);
      END;
    inputstack[inputptr] := curinput;
    inputptr := inputptr+1;
  END;
  curinput.indexfield := inopen;
  linestack[curinput.indexfield] := line;
  curinput.startfield := first;
  curinput.statefield := 1;
  curinput.namefield := 0;
END;{:328}{329:}
PROCEDURE endfilereading;
BEGIN
  first := curinput.startfield;
  line := linestack[curinput.indexfield];
  IF curinput.namefield>17 THEN aclose(inputfile[curinput.indexfield]);
  BEGIN
    inputptr := inputptr-1;
    curinput := inputstack[inputptr];
  END;
  inopen := inopen-1;
END;{:329}{330:}
PROCEDURE clearforerrorprompt;
BEGIN
  WHILE (curinput.statefield<>0)AND(curinput.namefield=0)AND(inputptr
        >0)AND(curinput.locfield>curinput.limitfield) DO
    endfilereading;
  println;;
END;{:330}{336:}
PROCEDURE checkoutervalidity;

VAR p: halfword;
  q: halfword;
BEGIN
  IF scannerstatus<>0 THEN
    BEGIN
      deletionsallowed := false;
{337:}
      IF curcs<>0 THEN
        BEGIN
          IF (curinput.statefield=0)OR(curinput.
             namefield<1)OR(curinput.namefield>17)THEN
            BEGIN
              p := getavail;
              mem[p].hh.lh := 4095+curcs;
              begintokenlist(p,3);
            END;
          curcmd := 10;
          curchr := 32;
        END{:337};
      IF scannerstatus>1 THEN{338:}
        BEGIN
          runaway;
          IF curcs=0 THEN
            BEGIN
              IF interaction=3 THEN;
              printnl(262);
              print(604);
            END
          ELSE
            BEGIN
              curcs := 0;
              BEGIN
                IF interaction=3 THEN;
                printnl(262);
                print(605);
              END;
            END;
          print(606);{339:}
          p := getavail;
          CASE scannerstatus OF 
            2:
               BEGIN
                 print(570);
                 mem[p].hh.lh := 637;
               END;
            3:
               BEGIN
                 print(612);
                 mem[p].hh.lh := partoken;
                 longstate := 113;
               END;
            4:
               BEGIN
                 print(572);
                 mem[p].hh.lh := 637;
                 q := p;
                 p := getavail;
                 mem[p].hh.rh := q;
                 mem[p].hh.lh := 6710;
                 alignstate := -1000000;
               END;
            5:
               BEGIN
                 print(573);
                 mem[p].hh.lh := 637;
               END;
          END;
          begintokenlist(p,4){:339};
          print(607);
          sprintcs(warningindex);
          BEGIN
            helpptr := 4;
            helpline[3] := 608;
            helpline[2] := 609;
            helpline[1] := 610;
            helpline[0] := 611;
          END;
          error;
        END{:338}
      ELSE
        BEGIN
          BEGIN
            IF interaction=3 THEN;
            printnl(262);
            print(598);
          END;
          printcmdchr(105,curif);
          print(599);
          printint(skipline);
          BEGIN
            helpptr := 3;
            helpline[2] := 600;
            helpline[1] := 601;
            helpline[0] := 602;
          END;
          IF curcs<>0 THEN curcs := 0
          ELSE helpline[2] := 603;
          curtok := 6713;
          inserror;
        END;
      deletionsallowed := true;
    END;
END;{:336}{340:}
PROCEDURE firmuptheline;
forward;{:340}{341:}
PROCEDURE getnext;

LABEL 20,25,21,26,40,10;

VAR k: 0..bufsize;
  t: halfword;
  cat: 0..15;
  c,cc: ASCIIcode;
  d: 2..3;
BEGIN
  20: curcs := 0;
  IF curinput.statefield<>0 THEN{343:}
    BEGIN
      25: IF curinput.locfield<=
             curinput.limitfield THEN
            BEGIN
              curchr := buffer[curinput.locfield];
              curinput.locfield := curinput.locfield+1;
              21: curcmd := eqtb[3983+curchr].hh.rh;
{344:}
              CASE curinput.statefield+curcmd OF {345:}
                10,26,42,27,43{:345}: goto
                                      25;
                1,17,33:{354:}
                         BEGIN
                           IF curinput.locfield>curinput.limitfield THEN curcs 
                             := 513
                           ELSE
                             BEGIN
                               26: k := curinput.locfield;
                               curchr := buffer[k];
                               cat := eqtb[3983+curchr].hh.rh;
                               k := k+1;
                               IF cat=11 THEN curinput.statefield := 17
                               ELSE IF cat=10 THEN curinput.
                                      statefield := 17
                               ELSE curinput.statefield := 1;
                               IF (cat=11)AND(k<=curinput.limitfield)THEN{356:}
                                 BEGIN
                                   REPEAT
                                     curchr := 
                                               buffer[k];
                                     cat := eqtb[3983+curchr].hh.rh;
                                     k := k+1;
                                   UNTIL (cat<>11)OR(k>curinput.limitfield);
{355:}
                                   BEGIN
                                     IF buffer[k]=curchr THEN IF cat=7 THEN IF k<curinput.
                                                                               limitfield THEN
                                                                              BEGIN
                                                                                c := buffer[k+1];
                                                                                IF c<128 THEN
                                                                                  BEGIN
                                                                                    d := 2;
                                                                                    IF (((c>=48)AND(
                                                                                       c<=57))OR((c
                                                                                       >=97)AND(c<=
                                                                                       102)))THEN IF
                                                                                                   k
                                                                                                   +
                                                                                                   2
                                                                                                  <=
                                                                                            curinput
                                                                                                   .

                                                                                          limitfield
                                                                                                THEN

                                                                                               BEGIN

                                                                                                  cc
                                                                                                  :=
                                                                                              buffer
                                                                                                   [
                                                                                                   k
                                                                                                   +
                                                                                                   2
                                                                                                   ]
                                                                                                   ;

                                                                                                  IF
                                                                                                   (
                                                                                                   (
                                                                                                   (
                                                                                                  cc
                                                                                                  >=
                                                                                                  48
                                                                                                   )
                                                                                                 AND
                                                                                                   (
                                                                                                  cc
                                                                                                  <=
                                                                                                  57
                                                                                                   )
                                                                                                   )
                                                                                                  OR
                                                                                                   (
                                                                                                   (
                                                                                                  cc
                                                                                                  >=
                                                                                                  97
                                                                                                   )
                                                                                                 AND
                                                                                                   (
                                                                                                  cc
                                                                                                  <=
                                                                                                 102
                                                                                                   )
                                                                                                   )
                                                                                                   )
                                                                                                THEN
                                                                                                   d
                                                                                                  :=
                                                                                                   d
                                                                                                   +
                                                                                                   1
                                                                                                   ;

                                                                                                 END
                                                                                    ;
                                                                                    IF d>2 THEN
                                                                                      BEGIN
                                                                                        IF c<=57
                                                                                          THEN
                                                                                          curchr := 
                                                                                                   c
                                                                                                   -
                                                                                                  48
                                                                                        ELSE curchr 
                                                                                          := c-87;
                                                                                        IF cc<=57
                                                                                          THEN
                                                                                          curchr := 
                                                                                                  16
                                                                                                   *
                                                                                              curchr
                                                                                                   +
                                                                                                  cc
                                                                                                   -
                                                                                                  48
                                                                                        ELSE curchr 
                                                                                          := 16*
                                                                                             curchr+
                                                                                             cc-87;
                                                                                        buffer[k-1] 
                                                                                        := curchr;
                                                                                      END
                                                                                    ELSE IF c<64
                                                                                           THEN
                                                                                           buffer[k-
                                                                                           1] := c+
                                                                                                 64
                                                                                    ELSE buffer[k-1]
                                                                                      := c-64;
                                                                                    curinput.
                                                                                    limitfield := 
                                                                                            curinput
                                                                                                  .
                                                                                          limitfield
                                                                                                  -d
                                                                                    ;
                                                                                    first := first-d
                                                                                    ;
                                                                                    WHILE k<=
                                                                                          curinput.
                                                                                          limitfield
                                                                                      DO
                                                                                      BEGIN
                                                                                        buffer[k] :=
                                                                                              buffer
                                                                                                   [
                                                                                                   k
                                                                                                   +
                                                                                                   d
                                                                                                   ]
                                                                                        ;
                                                                                        k := k+1;
                                                                                      END;
                                                                                    goto 26;
                                                                                  END;
                                                                              END;
                                   END{:355};
                                   IF cat<>11 THEN k := k-1;
                                   IF k>curinput.locfield+1 THEN
                                     BEGIN
                                       curcs := idlookup(curinput.locfield,k-
                                                curinput.locfield);
                                       curinput.locfield := k;
                                       goto 40;
                                     END;
                                 END{:356}
                               ELSE{355:}
                                 BEGIN
                                   IF buffer[k]=curchr THEN IF cat=7 THEN IF k<
                                                                             curinput.limitfield
                                                                            THEN
                                                                            BEGIN
                                                                              c := buffer[k+1];
                                                                              IF c<128 THEN
                                                                                BEGIN
                                                                                  d := 2;
                                                                                  IF (((c>=48)AND(c
                                                                                     <=57))OR((c>=97
                                                                                     )AND(c<=102)))
                                                                                    THEN IF k+2<=
                                                                                            curinput
                                                                                            .

                                                                                          limitfield
                                                                                           THEN
                                                                                           BEGIN
                                                                                             cc := 
                                                                                              buffer
                                                                                                   [
                                                                                                   k
                                                                                                   +
                                                                                                   2
                                                                                                   ]
                                                                                             ;
                                                                                             IF (((
                                                                                                cc>=
                                                                                                48)
                                                                                                AND(
                                                                                                cc<=
                                                                                                57))
                                                                                                OR((
                                                                                                cc>=
                                                                                                97)
                                                                                                AND(
                                                                                                cc<=
                                                                                                102)
                                                                                                ))
                                                                                               THEN
                                                                                               d := 
                                                                                                   d
                                                                                                   +
                                                                                                   1
                                                                                             ;
                                                                                           END;
                                                                                  IF d>2 THEN
                                                                                    BEGIN
                                                                                      IF c<=57 THEN
                                                                                        curchr := c-
                                                                                                  48
                                                                                      ELSE curchr :=
                                                                                                   c
                                                                                                   -
                                                                                                  87
                                                                                      ;
                                                                                      IF cc<=57 THEN
                                                                                        curchr := 16
                                                                                                  *
                                                                                              curchr
                                                                                                  +
                                                                                                  cc
                                                                                                  -
                                                                                                  48
                                                                                      ELSE curchr :=
                                                                                                  16
                                                                                                   *
                                                                                              curchr
                                                                                                   +
                                                                                                  cc
                                                                                                   -
                                                                                                  87
                                                                                      ;
                                                                                      buffer[k-1] :=
                                                                                              curchr
                                                                                      ;
                                                                                    END
                                                                                  ELSE IF c<64 THEN
                                                                                         buffer[k-1]
                                                                                         := c+64
                                                                                  ELSE buffer[k-1] 
                                                                                    := c-64;
                                                                                  curinput.
                                                                                  limitfield := 
                                                                                            curinput
                                                                                                .
                                                                                          limitfield
                                                                                                -d;
                                                                                  first := first-d;
                                                                                  WHILE k<=curinput.
                                                                                        limitfield 
                                                                                    DO
                                                                                    BEGIN
                                                                                      buffer[k] := 
                                                                                              buffer
                                                                                                   [
                                                                                                   k
                                                                                                   +
                                                                                                   d
                                                                                                   ]
                                                                                      ;
                                                                                      k := k+1;
                                                                                    END;
                                                                                  goto 26;
                                                                                END;
                                                                            END;
                                 END{:355};
                               curcs := 257+buffer[curinput.locfield];
                               curinput.locfield := curinput.locfield+1;
                             END;
                           40: curcmd := eqtb[curcs].hh.b0;
                           curchr := eqtb[curcs].hh.rh;
                           IF curcmd>=113 THEN checkoutervalidity;
                         END{:354};
                14,30,46:{353:}
                          BEGIN
                            curcs := curchr+1;
                            curcmd := eqtb[curcs].hh.b0;
                            curchr := eqtb[curcs].hh.rh;
                            curinput.statefield := 1;
                            IF curcmd>=113 THEN checkoutervalidity;
                          END{:353};
                8,24,40:{352:}
                         BEGIN
                           IF curchr=buffer[curinput.locfield]THEN IF curinput.
                                                                      locfield<curinput.limitfield
                                                                     THEN
                                                                     BEGIN
                                                                       c := buffer[curinput.locfield
                                                                            +1];
                                                                       IF c<128 THEN
                                                                         BEGIN
                                                                           curinput.locfield := 
                                                                                            curinput
                                                                                                .
                                                                                            locfield
                                                                                                +2;
                                                                           IF (((c>=48)AND(c<=57))OR
                                                                              ((c>=97)AND(c<=102)))
                                                                             THEN IF curinput.
                                                                                     locfield<=
                                                                                     curinput.
                                                                                     limitfield THEN
                                                                                    BEGIN
                                                                                      cc := buffer[
                                                                                            curinput
                                                                                            .
                                                                                            locfield
                                                                                            ];
                                                                                      IF (((cc>=48)
                                                                                         AND(cc<=57)
                                                                                         )OR((cc>=97
                                                                                         )AND(cc<=
                                                                                         102)))THEN
                                                                                        BEGIN
                                                                                          curinput.
                                                                                          locfield 
                                                                                          := 
                                                                                            curinput
                                                                                             .
                                                                                            locfield
                                                                                             +1;
                                                                                          IF c<=57
                                                                                            THEN
                                                                                            curchr 
                                                                                            := c-48
                                                                                          ELSE
                                                                                            curchr 
                                                                                            := c-87;
                                                                                          IF cc<=57
                                                                                            THEN
                                                                                            curchr 
                                                                                            := 16*
                                                                                              curchr
                                                                                               +cc-
                                                                                               48
                                                                                          ELSE
                                                                                            curchr 
                                                                                            := 16*
                                                                                              curchr
                                                                                               +cc-
                                                                                               87;
                                                                                          goto 21;
                                                                                        END;
                                                                                    END;
                                                                           IF c<64 THEN curchr := c+
                                                                                                  64
                                                                           ELSE curchr := c-64;
                                                                           goto 21;
                                                                         END;
                                                                     END;
                           curinput.statefield := 1;
                         END{:352};
                16,32,48:{346:}
                          BEGIN
                            BEGIN
                              IF interaction=3 THEN;
                              printnl(262);
                              print(613);
                            END;
                            BEGIN
                              helpptr := 2;
                              helpline[1] := 614;
                              helpline[0] := 615;
                            END;
                            deletionsallowed := false;
                            error;
                            deletionsallowed := true;
                            goto 20;
                          END{:346};
{347:}
                11:{349:}
                    BEGIN
                      curinput.statefield := 17;
                      curchr := 32;
                    END{:349};
                6:{348:}
                   BEGIN
                     curinput.locfield := curinput.limitfield+1;
                     curcmd := 10;
                     curchr := 32;
                   END{:348};
                22,15,31,47:{350:}
                             BEGIN
                               curinput.locfield := curinput.limitfield+1;
                               goto 25;
                             END{:350};
                38:{351:}
                    BEGIN
                      curinput.locfield := curinput.limitfield+1;
                      curcs := parloc;
                      curcmd := eqtb[curcs].hh.b0;
                      curchr := eqtb[curcs].hh.rh;
                      IF curcmd>=113 THEN checkoutervalidity;
                    END{:351};
                2: alignstate := alignstate+1;
                18,34:
                       BEGIN
                         curinput.statefield := 1;
                         alignstate := alignstate+1;
                       END;
                3: alignstate := alignstate-1;
                19,35:
                       BEGIN
                         curinput.statefield := 1;
                         alignstate := alignstate-1;
                       END;
                20,21,23,25,28,29,36,37,39,41,44,45: curinput.statefield := 1;
{:347}
                ELSE
              END{:344};
            END
          ELSE
            BEGIN
              curinput.statefield := 33;
{360:}
              IF curinput.namefield>17 THEN{362:}
                BEGIN
                  line := line+1;
                  first := curinput.startfield;
                  IF NOT forceeof THEN
                    BEGIN
                      IF inputln(inputfile[curinput.indexfield],
                         true)THEN firmuptheline
                      ELSE forceeof := true;
                    END;
                  IF forceeof THEN
                    BEGIN
                      printchar(41);
                      openparens := openparens-1;
                      flush(output);
                      forceeof := false;
                      endfilereading;
                      checkoutervalidity;
                      goto 20;
                    END;
                  IF (eqtb[5311].int<0)OR(eqtb[5311].int>255)THEN curinput.limitfield := 
                                                                                         curinput.
                                                                                         limitfield-
                                                                                         1
                  ELSE buffer[curinput.limitfield] := eqtb[5311].int;
                  first := curinput.limitfield+1;
                  curinput.locfield := curinput.startfield;
                END{:362}
              ELSE
                BEGIN
                  IF NOT(curinput.namefield=0)THEN
                    BEGIN
                      curcmd := 0;
                      curchr := 0;
                      goto 10;
                    END;
                  IF inputptr>0 THEN
                    BEGIN
                      endfilereading;
                      goto 20;
                    END;
                  IF selector<18 THEN openlogfile;
                  IF interaction>1 THEN
                    BEGIN
                      IF (eqtb[5311].int<0)OR(eqtb[5311].int>255)
                        THEN curinput.limitfield := curinput.limitfield+1;
                      IF curinput.limitfield=-1 THEN printnl(616);
                      printnl(338);
                      first := curinput.startfield;
                      BEGIN;
                        print(42);
                        terminput;
                      END;
                      curinput.limitfield := last;
                      IF (eqtb[5311].int<0)OR(eqtb[5311].int>255)THEN curinput.limitfield := 

                                                                                            curinput
                                                                                             .
                                                                                          limitfield
                                                                                             -1
                      ELSE buffer[curinput.limitfield] := eqtb[5311].int;
                      first := curinput.limitfield+1;
                      curinput.locfield := curinput.startfield;
                    END
                  ELSE fatalerror(617);
                END{:360};
              BEGIN
                IF interrupt<>0 THEN pauseforinstructions;
              END;
              goto 25;
            END;
    END{:343}
  ELSE{357:}IF curinput.locfield<>0 THEN
              BEGIN
                t := mem[curinput.
                     locfield].hh.lh;
                curinput.locfield := mem[curinput.locfield].hh.rh;
                IF t>=4095 THEN
                  BEGIN
                    curcs := t-4095;
                    curcmd := eqtb[curcs].hh.b0;
                    curchr := eqtb[curcs].hh.rh;
                    IF curcmd>=113 THEN IF curcmd=116 THEN{358:}
                                          BEGIN
                                            curcs := mem[curinput.
                                                     locfield].hh.lh-4095;
                                            curinput.locfield := 0;
                                            curcmd := eqtb[curcs].hh.b0;
                                            curchr := eqtb[curcs].hh.rh;
                                            IF curcmd>100 THEN
                                              BEGIN
                                                curcmd := 0;
                                                curchr := 257;
                                              END;
                                          END{:358}
                    ELSE checkoutervalidity;
                  END
                ELSE
                  BEGIN
                    curcmd := t DIV 256;
                    curchr := t MOD 256;
                    CASE curcmd OF 
                      1: alignstate := alignstate+1;
                      2: alignstate := alignstate-1;
                      5:{359:}
                         BEGIN
                           begintokenlist(paramstack[curinput.limitfield+curchr-1],0)
                           ;
                           goto 20;
                         END{:359};
                      ELSE
                    END;
                  END;
              END
  ELSE
    BEGIN
      endtokenlist;
      goto 20;
    END{:357};
{342:}
  IF curcmd<=5 THEN IF curcmd>=4 THEN IF alignstate=0 THEN{789:}
                                        BEGIN
                                          IF (scannerstatus=4)OR(curalign=0)THEN fatalerror(595);
                                          curcmd := mem[curalign+5].hh.lh;
                                          mem[curalign+5].hh.lh := curchr;
                                          IF curcmd=63 THEN begintokenlist(29990,2)
                                          ELSE begintokenlist(mem[
                                                              curalign+2].int,2);
                                          alignstate := 1000000;
                                          goto 20;
                                        END{:789}{:342};
  10:
END;
{:341}{363:}
PROCEDURE firmuptheline;

VAR k: 0..bufsize;
BEGIN
  curinput.limitfield := last;
  IF eqtb[5291].int>0 THEN IF interaction>1 THEN
                             BEGIN;
                               println;
                               IF curinput.startfield<curinput.limitfield THEN FOR k:=curinput.
                                                                                   startfield TO
                                                                                   curinput.
                                                                                   limitfield-1 DO
                                                                                 print(buffer[k]);
                               first := curinput.limitfield;
                               BEGIN;
                                 print(618);
                                 terminput;
                               END;
                               IF last>first THEN
                                 BEGIN
                                   FOR k:=first TO last-1 DO
                                     buffer[k+curinput.
                                     startfield-first] := buffer[k];
                                   curinput.limitfield := curinput.startfield+last-first;
                                 END;
                             END;
END;
{:363}{365:}
PROCEDURE gettoken;
BEGIN
  nonewcontrolsequence := false;
  getnext;
  nonewcontrolsequence := true;
  IF curcs=0 THEN curtok := (curcmd*256)+curchr
  ELSE curtok := 4095+curcs;
END;
{:365}{366:}{389:}
PROCEDURE macrocall;

LABEL 10,22,30,31,40;

VAR r: halfword;
  p: halfword;
  q: halfword;
  s: halfword;
  t: halfword;
  u,v: halfword;
  rbraceptr: halfword;
  n: smallnumber;
  unbalance: halfword;
  m: halfword;
  refcount: halfword;
  savescannerstatus: smallnumber;
  savewarningindex: halfword;
  matchchr: ASCIIcode;
BEGIN
  savescannerstatus := scannerstatus;
  savewarningindex := warningindex;
  warningindex := curcs;
  refcount := curchr;
  r := mem[refcount].hh.rh;
  n := 0;
  IF eqtb[5293].int>0 THEN{401:}
    BEGIN
      begindiagnostic;
      println;
      printcs(warningindex);
      tokenshow(refcount);
      enddiagnostic(false);
    END{:401};
  IF mem[r].hh.lh<>3584 THEN{391:}
    BEGIN
      scannerstatus := 3;
      unbalance := 0;
      longstate := eqtb[curcs].hh.b0;
      IF longstate>=113 THEN longstate := longstate-2;
      REPEAT
        mem[29997].hh.rh := 0;
        IF (mem[r].hh.lh>3583)OR(mem[r].hh.lh<3328)THEN s := 0
        ELSE
          BEGIN
            matchchr 
            := mem[r].hh.lh-3328;
            s := mem[r].hh.rh;
            r := s;
            p := 29997;
            m := 0;
          END;
{392:}
        22: gettoken;
        IF curtok=mem[r].hh.lh THEN{394:}
          BEGIN
            r := mem[r].hh.rh;
            IF (mem[r].hh.lh>=3328)AND(mem[r].hh.lh<=3584)THEN
              BEGIN
                IF curtok<512
                  THEN alignstate := alignstate-1;
                goto 40;
              END
            ELSE goto 22;
          END{:394};
{397:}
        IF s<>r THEN IF s=0 THEN{398:}
                       BEGIN
                         BEGIN
                           IF interaction=3 THEN;
                           printnl(262);
                           print(650);
                         END;
                         sprintcs(warningindex);
                         print(651);
                         BEGIN
                           helpptr := 4;
                           helpline[3] := 652;
                           helpline[2] := 653;
                           helpline[1] := 654;
                           helpline[0] := 655;
                         END;
                         error;
                         goto 10;
                       END{:398}
        ELSE
          BEGIN
            t := s;
            REPEAT
              BEGIN
                q := getavail;
                mem[p].hh.rh := q;
                mem[q].hh.lh := mem[t].hh.lh;
                p := q;
              END;
              m := m+1;
              u := mem[t].hh.rh;
              v := s;
              WHILE true DO
                BEGIN
                  IF u=r THEN IF curtok<>mem[v].hh.lh THEN goto 30
                  ELSE
                    BEGIN
                      r := mem[v].hh.rh;
                      goto 22;
                    END;
                  IF mem[u].hh.lh<>mem[v].hh.lh THEN goto 30;
                  u := mem[u].hh.rh;
                  v := mem[v].hh.rh;
                END;
              30: t := mem[t].hh.rh;
            UNTIL t=r;
            r := s;
          END{:397};
        IF curtok=partoken THEN IF longstate<>112 THEN{396:}
                                  BEGIN
                                    IF longstate=
                                       111 THEN
                                      BEGIN
                                        runaway;
                                        BEGIN
                                          IF interaction=3 THEN;
                                          printnl(262);
                                          print(645);
                                        END;
                                        sprintcs(warningindex);
                                        print(646);
                                        BEGIN
                                          helpptr := 3;
                                          helpline[2] := 647;
                                          helpline[1] := 648;
                                          helpline[0] := 649;
                                        END;
                                        backerror;
                                      END;
                                    pstack[n] := mem[29997].hh.rh;
                                    alignstate := alignstate-unbalance;
                                    FOR m:=0 TO n DO
                                      flushlist(pstack[m]);
                                    goto 10;
                                  END{:396};
        IF curtok<768 THEN IF curtok<512 THEN{399:}
                             BEGIN
                               unbalance := 1;
                               WHILE true DO
                                 BEGIN
                                   BEGIN
                                     BEGIN
                                       q := avail;
                                       IF q=0 THEN q := getavail
                                       ELSE
                                         BEGIN
                                           avail := mem[q].hh.rh;
                                           mem[q].hh.rh := 0;
                                           dynused := dynused+1;
                                         END;
                                     END;
                                     mem[p].hh.rh := q;
                                     mem[q].hh.lh := curtok;
                                     p := q;
                                   END;
                                   gettoken;
                                   IF curtok=partoken THEN IF longstate<>112 THEN{396:}
                                                             BEGIN
                                                               IF longstate=
                                                                  111 THEN
                                                                 BEGIN
                                                                   runaway;
                                                                   BEGIN
                                                                     IF interaction=3 THEN;
                                                                     printnl(262);
                                                                     print(645);
                                                                   END;
                                                                   sprintcs(warningindex);
                                                                   print(646);
                                                                   BEGIN
                                                                     helpptr := 3;
                                                                     helpline[2] := 647;
                                                                     helpline[1] := 648;
                                                                     helpline[0] := 649;
                                                                   END;
                                                                   backerror;
                                                                 END;
                                                               pstack[n] := mem[29997].hh.rh;
                                                               alignstate := alignstate-unbalance;
                                                               FOR m:=0 TO n DO
                                                                 flushlist(pstack[m]);
                                                               goto 10;
                                                             END{:396};
                                   IF curtok<768 THEN IF curtok<512 THEN unbalance := unbalance+1
                                   ELSE
                                     BEGIN
                                       unbalance := unbalance-1;
                                       IF unbalance=0 THEN goto 31;
                                     END;
                                 END;
                               31: rbraceptr := p;
                               BEGIN
                                 q := getavail;
                                 mem[p].hh.rh := q;
                                 mem[q].hh.lh := curtok;
                                 p := q;
                               END;
                             END{:399}
        ELSE{395:}
          BEGIN
            backinput;
            BEGIN
              IF interaction=3 THEN;
              printnl(262);
              print(637);
            END;
            sprintcs(warningindex);
            print(638);
            BEGIN
              helpptr := 6;
              helpline[5] := 639;
              helpline[4] := 640;
              helpline[3] := 641;
              helpline[2] := 642;
              helpline[1] := 643;
              helpline[0] := 644;
            END;
            alignstate := alignstate+1;
            longstate := 111;
            curtok := partoken;
            inserror;
            goto 22;
          END{:395}
        ELSE{393:}
          BEGIN
            IF curtok=2592 THEN IF mem[r].hh.lh<=3584 THEN
                                  IF mem[r].hh.lh>=3328 THEN goto 22;
            BEGIN
              q := getavail;
              mem[p].hh.rh := q;
              mem[q].hh.lh := curtok;
              p := q;
            END;
          END{:393};
        m := m+1;
        IF mem[r].hh.lh>3584 THEN goto 22;
        IF mem[r].hh.lh<3328 THEN goto 22;
        40: IF s<>0 THEN{400:}
              BEGIN
                IF (m=1)AND(mem[p].hh.lh<768)THEN
                  BEGIN
                    mem[
                    rbraceptr].hh.rh := 0;
                    BEGIN
                      mem[p].hh.rh := avail;
                      avail := p;
                      dynused := dynused-1;
                    END;
                    p := mem[29997].hh.rh;
                    pstack[n] := mem[p].hh.rh;
                    BEGIN
                      mem[p].hh.rh := avail;
                      avail := p;
                      dynused := dynused-1;
                    END;
                  END
                ELSE pstack[n] := mem[29997].hh.rh;
                n := n+1;
                IF eqtb[5293].int>0 THEN
                  BEGIN
                    begindiagnostic;
                    printnl(matchchr);
                    printint(n);
                    print(656);
                    showtokenlist(pstack[n-1],0,1000);
                    enddiagnostic(false);
                  END;
              END{:400}{:392};
      UNTIL mem[r].hh.lh=3584;
    END{:391};
{390:}
  WHILE (curinput.statefield=0)AND(curinput.locfield=0)AND(curinput.
        indexfield<>2) DO
    endtokenlist;
  begintokenlist(refcount,5);
  curinput.namefield := warningindex;
  curinput.locfield := mem[r].hh.rh;
  IF n>0 THEN
    BEGIN
      IF paramptr+n>maxparamstack THEN
        BEGIN
          maxparamstack := 
                           paramptr+n;
          IF maxparamstack>paramsize THEN overflow(636,paramsize);
        END;
      FOR m:=0 TO n-1 DO
        paramstack[paramptr+m] := pstack[m];
      paramptr := paramptr+n;
    END{:390};
  10: scannerstatus := savescannerstatus;
  warningindex := savewarningindex;
END;{:389}{379:}
PROCEDURE insertrelax;
BEGIN
  curtok := 4095+curcs;
  backinput;
  curtok := 6716;
  backinput;
  curinput.indexfield := 4;
END;{:379}
PROCEDURE passtext;
forward;
PROCEDURE startinput;
forward;
PROCEDURE conditional;
forward;
PROCEDURE getxtoken;
forward;
PROCEDURE convtoks;
forward;
PROCEDURE insthetoks;
forward;
PROCEDURE expand;

VAR t: halfword;
  p,q,r: halfword;
  j: 0..bufsize;
  cvbackup: integer;
  cvlbackup,radixbackup,cobackup: smallnumber;
  backupbackup: halfword;
  savescannerstatus: smallnumber;
BEGIN
  cvbackup := curval;
  cvlbackup := curvallevel;
  radixbackup := radix;
  cobackup := curorder;
  backupbackup := mem[29987].hh.rh;
  IF curcmd<111 THEN{367:}
    BEGIN
      IF eqtb[5299].int>1 THEN showcurcmdchr;
      CASE curcmd OF 
        110:{386:}
             BEGIN
               IF curmark[curchr]<>0 THEN begintokenlist
                 (curmark[curchr],14);
             END{:386};
        102:{368:}
             BEGIN
               gettoken;
               t := curtok;
               gettoken;
               IF curcmd>100 THEN expand
               ELSE backinput;
               curtok := t;
               backinput;
             END{:368};
        103:{369:}
             BEGIN
               savescannerstatus := scannerstatus;
               scannerstatus := 0;
               gettoken;
               scannerstatus := savescannerstatus;
               t := curtok;
               backinput;
               IF t>=4095 THEN
                 BEGIN
                   p := getavail;
                   mem[p].hh.lh := 6718;
                   mem[p].hh.rh := curinput.locfield;
                   curinput.startfield := p;
                   curinput.locfield := p;
                 END;
             END{:369};
        107:{372:}
             BEGIN
               r := getavail;
               p := r;
               REPEAT
                 getxtoken;
                 IF curcs=0 THEN
                   BEGIN
                     q := getavail;
                     mem[p].hh.rh := q;
                     mem[q].hh.lh := curtok;
                     p := q;
                   END;
               UNTIL curcs<>0;
               IF curcmd<>67 THEN{373:}
                 BEGIN
                   BEGIN
                     IF interaction=3 THEN;
                     printnl(262);
                     print(625);
                   END;
                   printesc(505);
                   print(626);
                   BEGIN
                     helpptr := 2;
                     helpline[1] := 627;
                     helpline[0] := 628;
                   END;
                   backerror;
                 END{:373};
{374:}
               j := first;
               p := mem[r].hh.rh;
               WHILE p<>0 DO
                 BEGIN
                   IF j>=maxbufstack THEN
                     BEGIN
                       maxbufstack := j+1;
                       IF maxbufstack=bufsize THEN overflow(256,bufsize);
                     END;
                   buffer[j] := mem[p].hh.lh MOD 256;
                   j := j+1;
                   p := mem[p].hh.rh;
                 END;
               IF j>first+1 THEN
                 BEGIN
                   nonewcontrolsequence := false;
                   curcs := idlookup(first,j-first);
                   nonewcontrolsequence := true;
                 END
               ELSE IF j=first THEN curcs := 513
               ELSE curcs := 257+buffer[first]{:374};
               flushlist(r);
               IF eqtb[curcs].hh.b0=101 THEN
                 BEGIN
                   eqdefine(curcs,0,256);
                 END;
               curtok := curcs+4095;
               backinput;
             END{:372};
        108: convtoks;
        109: insthetoks;
        105: conditional;
        106:{510:}IF curchr>iflimit THEN IF iflimit=1 THEN insertrelax
             ELSE
               BEGIN
                 BEGIN
                   IF interaction=3 THEN;
                   printnl(262);
                   print(777);
                 END;
                 printcmdchr(106,curchr);
                 BEGIN
                   helpptr := 1;
                   helpline[0] := 778;
                 END;
                 error;
               END
             ELSE
               BEGIN
                 WHILE curchr<>2 DO
                   passtext;{496:}
                 BEGIN
                   p := condptr;
                   ifline := mem[p+1].int;
                   curif := mem[p].hh.b1;
                   iflimit := mem[p].hh.b0;
                   condptr := mem[p].hh.rh;
                   freenode(p,2);
                 END{:496};
               END{:510};
        104:{378:}IF curchr>0 THEN forceeof := true
             ELSE IF nameinprogress THEN
                    insertrelax
             ELSE startinput{:378};
        ELSE{370:}
          BEGIN
            BEGIN
              IF interaction=3 THEN;
              printnl(262);
              print(619);
            END;
            BEGIN
              helpptr := 5;
              helpline[4] := 620;
              helpline[3] := 621;
              helpline[2] := 622;
              helpline[1] := 623;
              helpline[0] := 624;
            END;
            error;
          END{:370}
      END;
    END{:367}
  ELSE IF curcmd<115 THEN macrocall
  ELSE{375:}
    BEGIN
      curtok := 6715;
      backinput;
    END{:375};
  curval := cvbackup;
  curvallevel := cvlbackup;
  radix := radixbackup;
  curorder := cobackup;
  mem[29987].hh.rh := backupbackup;
END;{:366}{380:}
PROCEDURE getxtoken;

LABEL 20,30;
BEGIN
  20: getnext;
  IF curcmd<=100 THEN goto 30;
  IF curcmd>=111 THEN IF curcmd<115 THEN macrocall
  ELSE
    BEGIN
      curcs := 2620;
      curcmd := 9;
      goto 30;
    END
  ELSE expand;
  goto 20;
  30: IF curcs=0 THEN curtok := (curcmd*256)+curchr
      ELSE curtok := 4095+curcs;
END;{:380}{381:}
PROCEDURE xtoken;
BEGIN
  WHILE curcmd>100 DO
    BEGIN
      expand;
      getnext;
    END;
  IF curcs=0 THEN curtok := (curcmd*256)+curchr
  ELSE curtok := 4095+curcs;
END;
{:381}{403:}
PROCEDURE scanleftbrace;
BEGIN{404:}
  REPEAT
    getxtoken;
  UNTIL (curcmd<>10)AND(curcmd<>0){:404};
  IF curcmd<>1 THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(657);
      END;
      BEGIN
        helpptr := 4;
        helpline[3] := 658;
        helpline[2] := 659;
        helpline[1] := 660;
        helpline[0] := 661;
      END;
      backerror;
      curtok := 379;
      curcmd := 1;
      curchr := 123;
      alignstate := alignstate+1;
    END;
END;
{:403}{405:}
PROCEDURE scanoptionalequals;
BEGIN{406:}
  REPEAT
    getxtoken;
  UNTIL curcmd<>10{:406};
  IF curtok<>3133 THEN backinput;
END;
{:405}{407:}
FUNCTION scankeyword(s:strnumber): boolean;

LABEL 10;

VAR p: halfword;
  q: halfword;
  k: poolpointer;
BEGIN
  p := 29987;
  mem[p].hh.rh := 0;
  k := strstart[s];
  WHILE k<strstart[s+1] DO
    BEGIN
      getxtoken;
      IF (curcs=0)AND((curchr=strpool[k])OR(curchr=strpool[k]-32))THEN
        BEGIN
          BEGIN
            q := getavail;
            mem[p].hh.rh := q;
            mem[q].hh.lh := curtok;
            p := q;
          END;
          k := k+1;
        END
      ELSE IF (curcmd<>10)OR(p<>29987)THEN
             BEGIN
               backinput;
               IF p<>29987 THEN begintokenlist(mem[29987].hh.rh,3);
               scankeyword := false;
               goto 10;
             END;
    END;
  flushlist(mem[29987].hh.rh);
  scankeyword := true;
  10:
END;
{:407}{408:}
PROCEDURE muerror;
BEGIN
  BEGIN
    IF interaction=3 THEN;
    printnl(262);
    print(662);
  END;
  BEGIN
    helpptr := 1;
    helpline[0] := 663;
  END;
  error;
END;{:408}{409:}
PROCEDURE scanint;
forward;
{433:}
PROCEDURE scaneightbitint;
BEGIN
  scanint;
  IF (curval<0)OR(curval>255)THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(687);
      END;
      BEGIN
        helpptr := 2;
        helpline[1] := 688;
        helpline[0] := 689;
      END;
      interror(curval);
      curval := 0;
    END;
END;
{:433}{434:}
PROCEDURE scancharnum;
BEGIN
  scanint;
  IF (curval<0)OR(curval>255)THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(690);
      END;
      BEGIN
        helpptr := 2;
        helpline[1] := 691;
        helpline[0] := 689;
      END;
      interror(curval);
      curval := 0;
    END;
END;
{:434}{435:}
PROCEDURE scanfourbitint;
BEGIN
  scanint;
  IF (curval<0)OR(curval>15)THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(692);
      END;
      BEGIN
        helpptr := 2;
        helpline[1] := 693;
        helpline[0] := 689;
      END;
      interror(curval);
      curval := 0;
    END;
END;
{:435}{436:}
PROCEDURE scanfifteenbitint;
BEGIN
  scanint;
  IF (curval<0)OR(curval>32767)THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(694);
      END;
      BEGIN
        helpptr := 2;
        helpline[1] := 695;
        helpline[0] := 689;
      END;
      interror(curval);
      curval := 0;
    END;
END;
{:436}{437:}
PROCEDURE scantwentysevenbitint;
BEGIN
  scanint;
  IF (curval<0)OR(curval>134217727)THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(696);
      END;
      BEGIN
        helpptr := 2;
        helpline[1] := 697;
        helpline[0] := 689;
      END;
      interror(curval);
      curval := 0;
    END;
END;
{:437}{577:}
PROCEDURE scanfontident;

VAR f: internalfontnumber;
  m: halfword;
BEGIN{406:}
  REPEAT
    getxtoken;
  UNTIL curcmd<>10{:406};
  IF curcmd=88 THEN f := eqtb[3934].hh.rh
  ELSE IF curcmd=87 THEN f := curchr
  ELSE IF curcmd=86 THEN
         BEGIN
           m := curchr;
           scanfourbitint;
           f := eqtb[m+curval].hh.rh;
         END
  ELSE
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(818);
      END;
      BEGIN
        helpptr := 2;
        helpline[1] := 819;
        helpline[0] := 820;
      END;
      backerror;
      f := 0;
    END;
  curval := f;
END;
{:577}{578:}
PROCEDURE findfontdimen(writing:boolean);

VAR f: internalfontnumber;
  n: integer;
BEGIN
  scanint;
  n := curval;
  scanfontident;
  f := curval;
  IF n<=0 THEN curval := fmemptr
  ELSE
    BEGIN
      IF writing AND(n<=4)AND(n>=2)AND
         (fontglue[f]<>0)THEN
        BEGIN
          deleteglueref(fontglue[f]);
          fontglue[f] := 0;
        END;
      IF n>fontparams[f]THEN IF f<fontptr THEN curval := fmemptr
      ELSE{580:}
        BEGIN
          REPEAT
            IF fmemptr=fontmemsize THEN overflow(825,fontmemsize);
            fontinfo[fmemptr].int := 0;
            fmemptr := fmemptr+1;
            fontparams[f] := fontparams[f]+1;
          UNTIL n=fontparams[f];
          curval := fmemptr-1;
        END{:580}
      ELSE curval := n+parambase[f];
    END;
{579:}
  IF curval=fmemptr THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(803);
      END;
      printesc(hash[2624+f].rh);
      print(821);
      printint(fontparams[f]);
      print(822);
      BEGIN
        helpptr := 2;
        helpline[1] := 823;
        helpline[0] := 824;
      END;
      error;
    END{:579};
END;
{:578}{:409}{413:}
PROCEDURE scansomethinginternal(level:smallnumber;
                                negative:boolean);

VAR m: halfword;
  p: 0..nestsize;
BEGIN
  m := curchr;
  CASE curcmd OF 
    85:{414:}
        BEGIN
          scancharnum;
          IF m=5007 THEN
            BEGIN
              curval := eqtb[5007+curval].hh.rh;
              curvallevel := 0;
            END
          ELSE IF m<5007 THEN
                 BEGIN
                   curval := eqtb[m+curval].hh.rh;
                   curvallevel := 0;
                 END
          ELSE
            BEGIN
              curval := eqtb[m+curval].int;
              curvallevel := 0;
            END;
        END{:414};
    71,72,86,87,88:{415:}IF level<>5 THEN
                           BEGIN
                             BEGIN
                               IF interaction=3 THEN;
                               printnl(262);
                               print(664);
                             END;
                             BEGIN
                               helpptr := 3;
                               helpline[2] := 665;
                               helpline[1] := 666;
                               helpline[0] := 667;
                             END;
                             backerror;
                             BEGIN
                               curval := 0;
                               curvallevel := 1;
                             END;
                           END
                    ELSE IF curcmd<=72 THEN
                           BEGIN
                             IF curcmd<72 THEN
                               BEGIN
                                 scaneightbitint;
                                 m := 3422+curval;
                               END;
                             BEGIN
                               curval := eqtb[m].hh.rh;
                               curvallevel := 5;
                             END;
                           END
                    ELSE
                      BEGIN
                        backinput;
                        scanfontident;
                        BEGIN
                          curval := 2624+curval;
                          curvallevel := 4;
                        END;
                      END{:415};
    73:
        BEGIN
          curval := eqtb[m].int;
          curvallevel := 0;
        END;
    74:
        BEGIN
          curval := eqtb[m].int;
          curvallevel := 1;
        END;
    75:
        BEGIN
          curval := eqtb[m].hh.rh;
          curvallevel := 2;
        END;
    76:
        BEGIN
          curval := eqtb[m].hh.rh;
          curvallevel := 3;
        END;
    79:{418:}IF abs(curlist.modefield)<>m THEN
               BEGIN
                 BEGIN
                   IF interaction=3
                     THEN;
                   printnl(262);
                   print(680);
                 END;
                 printcmdchr(79,m);
                 BEGIN
                   helpptr := 4;
                   helpline[3] := 681;
                   helpline[2] := 682;
                   helpline[1] := 683;
                   helpline[0] := 684;
                 END;
                 error;
                 IF level<>5 THEN
                   BEGIN
                     curval := 0;
                     curvallevel := 1;
                   END
                 ELSE
                   BEGIN
                     curval := 0;
                     curvallevel := 0;
                   END;
               END
        ELSE IF m=1 THEN
               BEGIN
                 curval := curlist.auxfield.int;
                 curvallevel := 1;
               END
        ELSE
          BEGIN
            curval := curlist.auxfield.hh.lh;
            curvallevel := 0;
          END{:418};
    80:{422:}IF curlist.modefield=0 THEN
               BEGIN
                 curval := 0;
                 curvallevel := 0;
               END
        ELSE
          BEGIN
            nest[nestptr] := curlist;
            p := nestptr;
            WHILE abs(nest[p].modefield)<>1 DO
              p := p-1;
            BEGIN
              curval := nest[p].pgfield;
              curvallevel := 0;
            END;
          END{:422};
    82:{419:}
        BEGIN
          IF m=0 THEN curval := deadcycles
          ELSE curval := 
                         insertpenalties;
          curvallevel := 0;
        END{:419};
    81:{421:}
        BEGIN
          IF (pagecontents=0)AND(NOT outputactive)THEN IF m=0 THEN
                                                         curval := 1073741823
          ELSE curval := 0
          ELSE curval := pagesofar[m];
          curvallevel := 1;
        END{:421};
    84:{423:}
        BEGIN
          IF eqtb[3412].hh.rh=0 THEN curval := 0
          ELSE curval := mem[
                         eqtb[3412].hh.rh].hh.lh;
          curvallevel := 0;
        END{:423};
    83:{420:}
        BEGIN
          scaneightbitint;
          IF eqtb[3678+curval].hh.rh=0 THEN curval := 0
          ELSE curval := mem[eqtb[3678+
                         curval].hh.rh+m].int;
          curvallevel := 1;
        END{:420};
    68,69:
           BEGIN
             curval := curchr;
             curvallevel := 0;
           END;
    77:{425:}
        BEGIN
          findfontdimen(false);
          fontinfo[fmemptr].int := 0;
          BEGIN
            curval := fontinfo[curval].int;
            curvallevel := 1;
          END;
        END{:425};
    78:{426:}
        BEGIN
          scanfontident;
          IF m=0 THEN
            BEGIN
              curval := hyphenchar[curval];
              curvallevel := 0;
            END
          ELSE
            BEGIN
              curval := skewchar[curval];
              curvallevel := 0;
            END;
        END{:426};
    89:{427:}
        BEGIN
          scaneightbitint;
          CASE m OF 
            0: curval := eqtb[5318+curval].int;
            1: curval := eqtb[5851+curval].int;
            2: curval := eqtb[2900+curval].hh.rh;
            3: curval := eqtb[3156+curval].hh.rh;
          END;
          curvallevel := m;
        END{:427};
    70:{424:}IF curchr>2 THEN
               BEGIN
                 IF curchr=3 THEN curval := line
                 ELSE
                   curval := lastbadness;
                 curvallevel := 0;
               END
        ELSE
          BEGIN
            IF curchr=2 THEN curval := 0
            ELSE curval := 0;
            curvallevel := curchr;
            IF NOT(curlist.tailfield>=himemmin)AND(curlist.modefield<>0)THEN CASE 
                                                                                  curchr OF 
                                                                               0: IF mem[curlist.
                                                                                     tailfield].hh.
                                                                                     b0=12 THEN
                                                                                    curval := mem[
                                                                                             curlist
                                                                                              .

                                                                                           tailfield
                                                                                              +1].
                                                                                              int;
                                                                               1: IF mem[curlist.
                                                                                     tailfield].hh.
                                                                                     b0=11 THEN
                                                                                    curval := mem[
                                                                                             curlist
                                                                                              .
                                                                                           tailfield
                                                                                              +1].
                                                                                              int;
                                                                               2: IF mem[curlist.
                                                                                     tailfield].hh.
                                                                                     b0=10 THEN
                                                                                    BEGIN
                                                                                      curval := mem[
                                                                                             curlist
                                                                                                .

                                                                                           tailfield
                                                                                                +1].
                                                                                                hh.
                                                                                                lh;
                                                                                      IF mem[curlist
                                                                                         .tailfield]
                                                                                         .hh.b1=99
                                                                                        THEN
                                                                                        curvallevel 
                                                                                        := 3;
                                                                                    END;
              END
            ELSE IF (curlist.modefield=1)AND(curlist.tailfield=curlist.headfield)
                   THEN CASE curchr OF 
                          0: curval := lastpenalty;
                          1: curval := lastkern;
                          2: IF lastglue<>65535 THEN curval := lastglue;
                   END;
          END{:424};
    ELSE{428:}
      BEGIN
        BEGIN
          IF interaction=3 THEN;
          printnl(262);
          print(685);
        END;
        printcmdchr(curcmd,curchr);
        print(686);
        printesc(537);
        BEGIN
          helpptr := 1;
          helpline[0] := 684;
        END;
        error;
        IF level<>5 THEN
          BEGIN
            curval := 0;
            curvallevel := 1;
          END
        ELSE
          BEGIN
            curval := 0;
            curvallevel := 0;
          END;
      END{:428}
  END;
  WHILE curvallevel>level DO{429:}
    BEGIN
      IF curvallevel=2 THEN curval := mem[
                                      curval+1].int
      ELSE IF curvallevel=3 THEN muerror;
      curvallevel := curvallevel-1;
    END{:429};
{430:}
  IF negative THEN IF curvallevel>=2 THEN
                     BEGIN
                       curval := newspec(
                                 curval);{431:}
                       BEGIN
                         mem[curval+1].int := -mem[curval+1].int;
                         mem[curval+2].int := -mem[curval+2].int;
                         mem[curval+3].int := -mem[curval+3].int;
                       END{:431};
                     END
  ELSE curval := -curval
  ELSE IF (curvallevel>=2)AND(curvallevel<=3)THEN
         mem[curval].hh.rh := mem[curval].hh.rh+1{:430};
END;
{:413}{440:}
PROCEDURE scanint;

LABEL 30;

VAR negative: boolean;
  m: integer;
  d: smallnumber;
  vacuous: boolean;
  OKsofar: boolean;
BEGIN
  radix := 0;
  OKsofar := true;{441:}
  negative := false;
  REPEAT{406:}
    REPEAT
      getxtoken;
    UNTIL curcmd<>10{:406};
    IF curtok=3117 THEN
      BEGIN
        negative := NOT negative;
        curtok := 3115;
      END;
  UNTIL curtok<>3115{:441};
  IF curtok=3168 THEN{442:}
    BEGIN
      gettoken;
      IF curtok<4095 THEN
        BEGIN
          curval := curchr;
          IF curcmd<=2 THEN IF curcmd=2 THEN alignstate := alignstate+1
          ELSE
            alignstate := alignstate-1;
        END
      ELSE IF curtok<4352 THEN curval := curtok-4096
      ELSE curval := curtok
                     -4352;
      IF curval>255 THEN
        BEGIN
          BEGIN
            IF interaction=3 THEN;
            printnl(262);
            print(698);
          END;
          BEGIN
            helpptr := 2;
            helpline[1] := 699;
            helpline[0] := 700;
          END;
          curval := 48;
          backerror;
        END
      ELSE{443:}
        BEGIN
          getxtoken;
          IF curcmd<>10 THEN backinput;
        END{:443};
    END{:442}
  ELSE IF (curcmd>=68)AND(curcmd<=89)THEN scansomethinginternal(0,
                                                                false)
  ELSE{444:}
    BEGIN
      radix := 10;
      m := 214748364;
      IF curtok=3111 THEN
        BEGIN
          radix := 8;
          m := 268435456;
          getxtoken;
        END
      ELSE IF curtok=3106 THEN
             BEGIN
               radix := 16;
               m := 134217728;
               getxtoken;
             END;
      vacuous := true;
      curval := 0;
{445:}
      WHILE true DO
        BEGIN
          IF (curtok<3120+radix)AND(curtok>=3120)AND(
             curtok<=3129)THEN d := curtok-3120
          ELSE IF radix=16 THEN IF (curtok<=2886)
                                   AND(curtok>=2881)THEN d := curtok-2871
          ELSE IF (curtok<=3142)AND(curtok>=
                  3137)THEN d := curtok-3127
          ELSE goto 30
          ELSE goto 30;
          vacuous := false;
          IF (curval>=m)AND((curval>m)OR(d>7)OR(radix<>10))THEN
            BEGIN
              IF OKsofar
                THEN
                BEGIN
                  BEGIN
                    IF interaction=3 THEN;
                    printnl(262);
                    print(701);
                  END;
                  BEGIN
                    helpptr := 2;
                    helpline[1] := 702;
                    helpline[0] := 703;
                  END;
                  error;
                  curval := 2147483647;
                  OKsofar := false;
                END;
            END
          ELSE curval := curval*radix+d;
          getxtoken;
        END;
      30:{:445};
      IF vacuous THEN{446:}
        BEGIN
          BEGIN
            IF interaction=3 THEN;
            printnl(262);
            print(664);
          END;
          BEGIN
            helpptr := 3;
            helpline[2] := 665;
            helpline[1] := 666;
            helpline[0] := 667;
          END;
          backerror;
        END{:446}
      ELSE IF curcmd<>10 THEN backinput;
    END{:444};
  IF negative THEN curval := -curval;
END;
{:440}{448:}
PROCEDURE scandimen(mu,inf,shortcut:boolean);

LABEL 30,31,32,40,45,88,89;

VAR negative: boolean;
  f: integer;
{450:}
  num,denom: 1..65536;
  k,kk: smallnumber;
  p,q: halfword;
  v: scaled;
  savecurval: integer;{:450}
BEGIN
  f := 0;
  aritherror := false;
  curorder := 0;
  negative := false;
  IF NOT shortcut THEN
    BEGIN{441:}
      negative := false;
      REPEAT{406:}
        REPEAT
          getxtoken;
        UNTIL curcmd<>10{:406};
        IF curtok=3117 THEN
          BEGIN
            negative := NOT negative;
            curtok := 3115;
          END;
      UNTIL curtok<>3115{:441};
      IF (curcmd>=68)AND(curcmd<=89)THEN{449:}IF mu THEN
                                                BEGIN
                                                  scansomethinginternal(3,false);
{451:}
                                                  IF curvallevel>=2 THEN
                                                    BEGIN
                                                      v := mem[curval+1].int;
                                                      deleteglueref(curval);
                                                      curval := v;
                                                    END{:451};
                                                  IF curvallevel=3 THEN goto 89;
                                                  IF curvallevel<>0 THEN muerror;
                                                END
      ELSE
        BEGIN
          scansomethinginternal(1,false);
          IF curvallevel=1 THEN goto 89;
        END{:449}
      ELSE
        BEGIN
          backinput;
          IF curtok=3116 THEN curtok := 3118;
          IF curtok<>3118 THEN scanint
          ELSE
            BEGIN
              radix := 10;
              curval := 0;
            END;
          IF curtok=3116 THEN curtok := 3118;
          IF (radix=10)AND(curtok=3118)THEN{452:}
            BEGIN
              k := 0;
              p := 0;
              gettoken;
              WHILE true DO
                BEGIN
                  getxtoken;
                  IF (curtok>3129)OR(curtok<3120)THEN goto 31;
                  IF k<17 THEN
                    BEGIN
                      q := getavail;
                      mem[q].hh.rh := p;
                      mem[q].hh.lh := curtok-3120;
                      p := q;
                      k := k+1;
                    END;
                END;
              31: FOR kk:=k DOWNTO 1 DO
                    BEGIN
                      dig[kk-1] := mem[p].hh.lh;
                      q := p;
                      p := mem[p].hh.rh;
                      BEGIN
                        mem[q].hh.rh := avail;
                        avail := q;
                        dynused := dynused-1;
                      END;
                    END;
              f := rounddecimals(k);
              IF curcmd<>10 THEN backinput;
            END{:452};
        END;
    END;
  IF curval<0 THEN
    BEGIN
      negative := NOT negative;
      curval := -curval;
    END;
{453:}
  IF inf THEN{454:}IF scankeyword(311)THEN
                     BEGIN
                       curorder := 1;
                       WHILE scankeyword(108) DO
                         BEGIN
                           IF curorder=3 THEN
                             BEGIN
                               BEGIN
                                 IF 
                                    interaction=3 THEN;
                                 printnl(262);
                                 print(705);
                               END;
                               print(706);
                               BEGIN
                                 helpptr := 1;
                                 helpline[0] := 707;
                               END;
                               error;
                             END
                           ELSE curorder := curorder+1;
                         END;
                       goto 88;
                     END{:454};
{455:}
  savecurval := curval;{406:}
  REPEAT
    getxtoken;
  UNTIL curcmd<>10{:406};
  IF (curcmd<68)OR(curcmd>89)THEN backinput
  ELSE
    BEGIN
      IF mu THEN
        BEGIN
          scansomethinginternal(3,false);
{451:}
          IF curvallevel>=2 THEN
            BEGIN
              v := mem[curval+1].int;
              deleteglueref(curval);
              curval := v;
            END{:451};
          IF curvallevel<>3 THEN muerror;
        END
      ELSE scansomethinginternal(1,false);
      v := curval;
      goto 40;
    END;
  IF mu THEN goto 45;
  IF scankeyword(708)THEN v := ({558:}fontinfo[6+parambase[eqtb[3934].hh.rh]
                               ].int{:558})
  ELSE IF scankeyword(709)THEN v := ({559:}fontinfo[5+parambase[
                                    eqtb[3934].hh.rh]].int{:559})
  ELSE goto 45;{443:}
  BEGIN
    getxtoken;
    IF curcmd<>10 THEN backinput;
  END{:443};
  40: curval := multandadd(savecurval,v,xnoverd(v,f,65536),1073741823);
  goto 89;
  45:{:455};
  IF mu THEN{456:}IF scankeyword(337)THEN goto 88
  ELSE
    BEGIN
      BEGIN
        IF 
           interaction=3 THEN;
        printnl(262);
        print(705);
      END;
      print(710);
      BEGIN
        helpptr := 4;
        helpline[3] := 711;
        helpline[2] := 712;
        helpline[1] := 713;
        helpline[0] := 714;
      END;
      error;
      goto 88;
    END{:456};
  IF scankeyword(704)THEN{457:}
    BEGIN
      preparemag;
      IF eqtb[5280].int<>1000 THEN
        BEGIN
          curval := xnoverd(curval,1000,eqtb[5280
                    ].int);
          f := (1000*f+65536*remainder)DIV eqtb[5280].int;
          curval := curval+(f DIV 65536);
          f := f MOD 65536;
        END;
    END{:457};
  IF scankeyword(397)THEN goto 88;
{458:}
  IF scankeyword(715)THEN
    BEGIN
      num := 7227;
      denom := 100;
    END
  ELSE IF scankeyword(716)THEN
         BEGIN
           num := 12;
           denom := 1;
         END
  ELSE IF scankeyword(717)THEN
         BEGIN
           num := 7227;
           denom := 254;
         END
  ELSE IF scankeyword(718)THEN
         BEGIN
           num := 7227;
           denom := 2540;
         END
  ELSE IF scankeyword(719)THEN
         BEGIN
           num := 7227;
           denom := 7200;
         END
  ELSE IF scankeyword(720)THEN
         BEGIN
           num := 1238;
           denom := 1157;
         END
  ELSE IF scankeyword(721)THEN
         BEGIN
           num := 14856;
           denom := 1157;
         END
  ELSE IF scankeyword(722)THEN goto 30
  ELSE{459:}
    BEGIN
      BEGIN
        IF 
           interaction=3 THEN;
        printnl(262);
        print(705);
      END;
      print(723);
      BEGIN
        helpptr := 6;
        helpline[5] := 724;
        helpline[4] := 725;
        helpline[3] := 726;
        helpline[2] := 712;
        helpline[1] := 713;
        helpline[0] := 714;
      END;
      error;
      goto 32;
    END{:459};
  curval := xnoverd(curval,num,denom);
  f := (num*f+65536*remainder)DIV denom;
  curval := curval+(f DIV 65536);
  f := f MOD 65536;
  32:{:458};
  88: IF curval>=16384 THEN aritherror := true
      ELSE curval := curval*65536+f;
  30:{:453};{443:}
  BEGIN
    getxtoken;
    IF curcmd<>10 THEN backinput;
  END{:443};
  89: IF aritherror OR(abs(curval)>=1073741824)THEN{460:}
        BEGIN
          BEGIN
            IF 
               interaction=3 THEN;
            printnl(262);
            print(727);
          END;
          BEGIN
            helpptr := 2;
            helpline[1] := 728;
            helpline[0] := 729;
          END;
          error;
          curval := 1073741823;
          aritherror := false;
        END{:460};
  IF negative THEN curval := -curval;
END;
{:448}{461:}
PROCEDURE scanglue(level:smallnumber);

LABEL 10;

VAR negative: boolean;
  q: halfword;
  mu: boolean;
BEGIN
  mu := (level=3);
{441:}
  negative := false;
  REPEAT{406:}
    REPEAT
      getxtoken;
    UNTIL curcmd<>10{:406};
    IF curtok=3117 THEN
      BEGIN
        negative := NOT negative;
        curtok := 3115;
      END;
  UNTIL curtok<>3115{:441};
  IF (curcmd>=68)AND(curcmd<=89)THEN
    BEGIN
      scansomethinginternal(level,
                            negative);
      IF curvallevel>=2 THEN
        BEGIN
          IF curvallevel<>level THEN muerror;
          goto 10;
        END;
      IF curvallevel=0 THEN scandimen(mu,false,true)
      ELSE IF level=3 THEN
             muerror;
    END
  ELSE
    BEGIN
      backinput;
      scandimen(mu,false,false);
      IF negative THEN curval := -curval;
    END;{462:}
  q := newspec(0);
  mem[q+1].int := curval;
  IF scankeyword(730)THEN
    BEGIN
      scandimen(mu,true,false);
      mem[q+2].int := curval;
      mem[q].hh.b0 := curorder;
    END;
  IF scankeyword(731)THEN
    BEGIN
      scandimen(mu,true,false);
      mem[q+3].int := curval;
      mem[q].hh.b1 := curorder;
    END;
  curval := q{:462};
  10:
END;
{:461}{463:}
FUNCTION scanrulespec: halfword;

LABEL 21;

VAR q: halfword;
BEGIN
  q := newrule;
  IF curcmd=35 THEN mem[q+1].int := 26214
  ELSE
    BEGIN
      mem[q+3].int := 26214;
      mem[q+2].int := 0;
    END;
  21: IF scankeyword(732)THEN
        BEGIN
          scandimen(false,false,false);
          mem[q+1].int := curval;
          goto 21;
        END;
  IF scankeyword(733)THEN
    BEGIN
      scandimen(false,false,false);
      mem[q+3].int := curval;
      goto 21;
    END;
  IF scankeyword(734)THEN
    BEGIN
      scandimen(false,false,false);
      mem[q+2].int := curval;
      goto 21;
    END;
  scanrulespec := q;
END;
{:463}{464:}
FUNCTION strtoks(b:poolpointer): halfword;

VAR p: halfword;
  q: halfword;
  t: halfword;
  k: poolpointer;
BEGIN
  BEGIN
    IF poolptr+1>poolsize THEN overflow(257,poolsize-initpoolptr
      );
  END;
  p := 29997;
  mem[p].hh.rh := 0;
  k := b;
  WHILE k<poolptr DO
    BEGIN
      t := strpool[k];
      IF t=32 THEN t := 2592
      ELSE t := 3072+t;
      BEGIN
        BEGIN
          q := avail;
          IF q=0 THEN q := getavail
          ELSE
            BEGIN
              avail := mem[q].hh.rh;
              mem[q].hh.rh := 0;
              dynused := dynused+1;
            END;
        END;
        mem[p].hh.rh := q;
        mem[q].hh.lh := t;
        p := q;
      END;
      k := k+1;
    END;
  poolptr := b;
  strtoks := p;
END;
{:464}{465:}
FUNCTION thetoks: halfword;

VAR oldsetting: 0..21;
  p,q,r: halfword;
  b: poolpointer;
BEGIN
  getxtoken;
  scansomethinginternal(5,false);
  IF curvallevel>=4 THEN{466:}
    BEGIN
      p := 29997;
      mem[p].hh.rh := 0;
      IF curvallevel=4 THEN
        BEGIN
          q := getavail;
          mem[p].hh.rh := q;
          mem[q].hh.lh := 4095+curval;
          p := q;
        END
      ELSE IF curval<>0 THEN
             BEGIN
               r := mem[curval].hh.rh;
               WHILE r<>0 DO
                 BEGIN
                   BEGIN
                     BEGIN
                       q := avail;
                       IF q=0 THEN q := getavail
                       ELSE
                         BEGIN
                           avail := mem[q].hh.rh;
                           mem[q].hh.rh := 0;
                           dynused := dynused+1;
                         END;
                     END;
                     mem[p].hh.rh := q;
                     mem[q].hh.lh := mem[r].hh.lh;
                     p := q;
                   END;
                   r := mem[r].hh.rh;
                 END;
             END;
      thetoks := p;
    END{:466}
  ELSE
    BEGIN
      oldsetting := selector;
      selector := 21;
      b := poolptr;
      CASE curvallevel OF 
        0: printint(curval);
        1:
           BEGIN
             printscaled(curval);
             print(397);
           END;
        2:
           BEGIN
             printspec(curval,397);
             deleteglueref(curval);
           END;
        3:
           BEGIN
             printspec(curval,337);
             deleteglueref(curval);
           END;
      END;
      selector := oldsetting;
      thetoks := strtoks(b);
    END;
END;
{:465}{467:}
PROCEDURE insthetoks;
BEGIN
  mem[29988].hh.rh := thetoks;
  begintokenlist(mem[29997].hh.rh,4);
END;{:467}{470:}
PROCEDURE convtoks;

VAR oldsetting: 0..21;
  c: 0..5;
  savescannerstatus: smallnumber;
  b: poolpointer;
BEGIN
  c := curchr;{471:}
  CASE c OF 
    0,1: scanint;
    2,3:
         BEGIN
           savescannerstatus := scannerstatus;
           scannerstatus := 0;
           gettoken;
           scannerstatus := savescannerstatus;
         END;
    4: scanfontident;
    5: IF jobname=0 THEN openlogfile;
  END{:471};
  oldsetting := selector;
  selector := 21;
  b := poolptr;{472:}
  CASE c OF 
    0: printint(curval);
    1: printromanint(curval);
    2: IF curcs<>0 THEN sprintcs(curcs)
       ELSE printchar(curchr);
    3: printmeaning;
    4:
       BEGIN
         print(fontname[curval]);
         IF fontsize[curval]<>fontdsize[curval]THEN
           BEGIN
             print(741);
             printscaled(fontsize[curval]);
             print(397);
           END;
       END;
    5: print(jobname);
  END{:472};
  selector := oldsetting;
  mem[29988].hh.rh := strtoks(b);
  begintokenlist(mem[29997].hh.rh,4);
END;
{:470}{473:}
FUNCTION scantoks(macrodef,xpand:boolean): halfword;

LABEL 40,22,30,31,32;

VAR t: halfword;
  s: halfword;
  p: halfword;
  q: halfword;
  unbalance: halfword;
  hashbrace: halfword;
BEGIN
  IF macrodef THEN scannerstatus := 2
  ELSE scannerstatus := 5;
  warningindex := curcs;
  defref := getavail;
  mem[defref].hh.lh := 0;
  p := defref;
  hashbrace := 0;
  t := 3120;
  IF macrodef THEN{474:}
    BEGIN
      WHILE true DO
        BEGIN
          22: gettoken;
          IF curtok<768 THEN goto 31;
          IF curcmd=6 THEN{476:}
            BEGIN
              s := 3328+curchr;
              gettoken;
              IF curtok<512 THEN
                BEGIN
                  hashbrace := curtok;
                  BEGIN
                    q := getavail;
                    mem[p].hh.rh := q;
                    mem[q].hh.lh := curtok;
                    p := q;
                  END;
                  BEGIN
                    q := getavail;
                    mem[p].hh.rh := q;
                    mem[q].hh.lh := 3584;
                    p := q;
                  END;
                  goto 30;
                END;
              IF t=3129 THEN
                BEGIN
                  BEGIN
                    IF interaction=3 THEN;
                    printnl(262);
                    print(744);
                  END;
                  BEGIN
                    helpptr := 2;
                    helpline[1] := 745;
                    helpline[0] := 746;
                  END;
                  error;
                  goto 22;
                END
              ELSE
                BEGIN
                  t := t+1;
                  IF curtok<>t THEN
                    BEGIN
                      BEGIN
                        IF interaction=3 THEN;
                        printnl(262);
                        print(747);
                      END;
                      BEGIN
                        helpptr := 2;
                        helpline[1] := 748;
                        helpline[0] := 749;
                      END;
                      backerror;
                    END;
                  curtok := s;
                END;
            END{:476};
          BEGIN
            q := getavail;
            mem[p].hh.rh := q;
            mem[q].hh.lh := curtok;
            p := q;
          END;
        END;
      31:
          BEGIN
            q := getavail;
            mem[p].hh.rh := q;
            mem[q].hh.lh := 3584;
            p := q;
          END;
      IF curcmd=2 THEN{475:}
        BEGIN
          BEGIN
            IF interaction=3 THEN;
            printnl(262);
            print(657);
          END;
          alignstate := alignstate+1;
          BEGIN
            helpptr := 2;
            helpline[1] := 742;
            helpline[0] := 743;
          END;
          error;
          goto 40;
        END{:475};
      30:
    END{:474}
  ELSE scanleftbrace;{477:}
  unbalance := 1;
  WHILE true DO
    BEGIN
      IF xpand THEN{478:}
        BEGIN
          WHILE true DO
            BEGIN
              getnext
              ;
              IF curcmd<=100 THEN goto 32;
              IF curcmd<>109 THEN expand
              ELSE
                BEGIN
                  q := thetoks;
                  IF mem[29997].hh.rh<>0 THEN
                    BEGIN
                      mem[p].hh.rh := mem[29997].hh.rh;
                      p := q;
                    END;
                END;
            END;
          32: xtoken
        END{:478}
      ELSE gettoken;
      IF curtok<768 THEN IF curcmd<2 THEN unbalance := unbalance+1
      ELSE
        BEGIN
          unbalance := unbalance-1;
          IF unbalance=0 THEN goto 40;
        END
      ELSE IF curcmd=6 THEN IF macrodef THEN{479:}
                              BEGIN
                                s := curtok;
                                IF xpand THEN getxtoken
                                ELSE gettoken;
                                IF curcmd<>6 THEN IF (curtok<=3120)OR(curtok>t)THEN
                                                    BEGIN
                                                      BEGIN
                                                        IF 
                                                           interaction=3 THEN;
                                                        printnl(262);
                                                        print(750);
                                                      END;
                                                      sprintcs(warningindex);
                                                      BEGIN
                                                        helpptr := 3;
                                                        helpline[2] := 751;
                                                        helpline[1] := 752;
                                                        helpline[0] := 753;
                                                      END;
                                                      backerror;
                                                      curtok := s;
                                                    END
                                ELSE curtok := 1232+curchr;
                              END{:479};
      BEGIN
        q := getavail;
        mem[p].hh.rh := q;
        mem[q].hh.lh := curtok;
        p := q;
      END;
    END{:477};
  40: scannerstatus := 0;
  IF hashbrace<>0 THEN
    BEGIN
      q := getavail;
      mem[p].hh.rh := q;
      mem[q].hh.lh := hashbrace;
      p := q;
    END;
  scantoks := p;
END;
{:473}{482:}
PROCEDURE readtoks(n:integer;r:halfword);

LABEL 30;

VAR p: halfword;
  q: halfword;
  s: integer;
  m: smallnumber;
BEGIN
  scannerstatus := 2;
  warningindex := r;
  defref := getavail;
  mem[defref].hh.lh := 0;
  p := defref;
  BEGIN
    q := getavail;
    mem[p].hh.rh := q;
    mem[q].hh.lh := 3584;
    p := q;
  END;
  IF (n<0)OR(n>15)THEN m := 16
  ELSE m := n;
  s := alignstate;
  alignstate := 1000000;
  REPEAT{483:}
    beginfilereading;
    curinput.namefield := m+1;
    IF readopen[m]=2 THEN{484:}IF interaction>1 THEN IF n<0 THEN
                                                       BEGIN;
                                                         print(338);
                                                         terminput;
                                                       END
    ELSE
      BEGIN;
        println;
        sprintcs(r);
        BEGIN;
          print(61);
          terminput;
        END;
        n := -1;
      END
    ELSE fatalerror(754){:484}
    ELSE IF readopen[m]=1 THEN{485:}IF inputln
                                       (readfile[m],false)THEN readopen[m] := 0
    ELSE
      BEGIN
        aclose(readfile[m]);
        readopen[m] := 2;
      END{:485}
    ELSE{486:}
      BEGIN
        IF NOT inputln(readfile[m],true)THEN
          BEGIN
            aclose(readfile[m]);
            readopen[m] := 2;
            IF alignstate<>1000000 THEN
              BEGIN
                runaway;
                BEGIN
                  IF interaction=3 THEN;
                  printnl(262);
                  print(755);
                END;
                printesc(534);
                BEGIN
                  helpptr := 1;
                  helpline[0] := 756;
                END;
                alignstate := 1000000;
                curinput.limitfield := 0;
                error;
              END;
          END;
      END{:486};
    curinput.limitfield := last;
    IF (eqtb[5311].int<0)OR(eqtb[5311].int>255)THEN curinput.limitfield := 
                                                                           curinput.limitfield-1
    ELSE buffer[curinput.limitfield] := eqtb[5311].int;
    first := curinput.limitfield+1;
    curinput.locfield := curinput.startfield;
    curinput.statefield := 33;
    WHILE true DO
      BEGIN
        gettoken;
        IF curtok=0 THEN goto 30;
        IF alignstate<1000000 THEN
          BEGIN
            REPEAT
              gettoken;
            UNTIL curtok=0;
            alignstate := 1000000;
            goto 30;
          END;
        BEGIN
          q := getavail;
          mem[p].hh.rh := q;
          mem[q].hh.lh := curtok;
          p := q;
        END;
      END;
    30: endfilereading{:483};
  UNTIL alignstate=1000000;
  curval := defref;
  scannerstatus := 0;
  alignstate := s;
END;{:482}{494:}
PROCEDURE passtext;

LABEL 30;

VAR l: integer;
  savescannerstatus: smallnumber;
BEGIN
  savescannerstatus := scannerstatus;
  scannerstatus := 1;
  l := 0;
  skipline := line;
  WHILE true DO
    BEGIN
      getnext;
      IF curcmd=106 THEN
        BEGIN
          IF l=0 THEN goto 30;
          IF curchr=2 THEN l := l-1;
        END
      ELSE IF curcmd=105 THEN l := l+1;
    END;
  30: scannerstatus := savescannerstatus;
END;
{:494}{497:}
PROCEDURE changeiflimit(l:smallnumber;p:halfword);

LABEL 10;

VAR q: halfword;
BEGIN
  IF p=condptr THEN iflimit := l
  ELSE
    BEGIN
      q := condptr;
      WHILE true DO
        BEGIN
          IF q=0 THEN confusion(757);
          IF mem[q].hh.rh=p THEN
            BEGIN
              mem[q].hh.b0 := l;
              goto 10;
            END;
          q := mem[q].hh.rh;
        END;
    END;
  10:
END;{:497}{498:}
PROCEDURE conditional;

LABEL 10,50;

VAR b: boolean;
  r: 60..62;
  m,n: integer;
  p,q: halfword;
  savescannerstatus: smallnumber;
  savecondptr: halfword;
  thisif: smallnumber;
BEGIN{495:}
  BEGIN
    p := getnode(2);
    mem[p].hh.rh := condptr;
    mem[p].hh.b0 := iflimit;
    mem[p].hh.b1 := curif;
    mem[p+1].int := ifline;
    condptr := p;
    curif := curchr;
    iflimit := 1;
    ifline := line;
  END{:495};
  savecondptr := condptr;
  thisif := curchr;
{501:}
  CASE thisif OF 
    0,1:{506:}
         BEGIN
           BEGIN
             getxtoken;
             IF curcmd=0 THEN IF curchr=257 THEN
                                BEGIN
                                  curcmd := 13;
                                  curchr := curtok-4096;
                                END;
           END;
           IF (curcmd>13)OR(curchr>255)THEN
             BEGIN
               m := 0;
               n := 256;
             END
           ELSE
             BEGIN
               m := curcmd;
               n := curchr;
             END;
           BEGIN
             getxtoken;
             IF curcmd=0 THEN IF curchr=257 THEN
                                BEGIN
                                  curcmd := 13;
                                  curchr := curtok-4096;
                                END;
           END;
           IF (curcmd>13)OR(curchr>255)THEN
             BEGIN
               curcmd := 0;
               curchr := 256;
             END;
           IF thisif=0 THEN b := (n=curchr)
           ELSE b := (m=curcmd);
         END{:506};
    2,3:{503:}
         BEGIN
           IF thisif=2 THEN scanint
           ELSE scandimen(false,false,
                          false);
           n := curval;{406:}
           REPEAT
             getxtoken;
           UNTIL curcmd<>10{:406};
           IF (curtok>=3132)AND(curtok<=3134)THEN r := curtok-3072
           ELSE
             BEGIN
               BEGIN
                 IF 
                    interaction=3 THEN;
                 printnl(262);
                 print(781);
               END;
               printcmdchr(105,thisif);
               BEGIN
                 helpptr := 1;
                 helpline[0] := 782;
               END;
               backerror;
               r := 61;
             END;
           IF thisif=2 THEN scanint
           ELSE scandimen(false,false,false);
           CASE r OF 
             60: b := (n<curval);
             61: b := (n=curval);
             62: b := (n>curval);
           END;
         END{:503};
    4:{504:}
       BEGIN
         scanint;
         b := odd(curval);
       END{:504};
    5: b := (abs(curlist.modefield)=1);
    6: b := (abs(curlist.modefield)=102);
    7: b := (abs(curlist.modefield)=203);
    8: b := (curlist.modefield<0);
    9,10,11:{505:}
             BEGIN
               scaneightbitint;
               p := eqtb[3678+curval].hh.rh;
               IF thisif=9 THEN b := (p=0)
               ELSE IF p=0 THEN b := false
               ELSE IF thisif=10
                      THEN b := (mem[p].hh.b0=0)
               ELSE b := (mem[p].hh.b0=1);
             END{:505};
    12:{507:}
        BEGIN
          savescannerstatus := scannerstatus;
          scannerstatus := 0;
          getnext;
          n := curcs;
          p := curcmd;
          q := curchr;
          getnext;
          IF curcmd<>p THEN b := false
          ELSE IF curcmd<111 THEN b := (curchr=q)
          ELSE
{508:}
            BEGIN
              p := mem[curchr].hh.rh;
              q := mem[eqtb[n].hh.rh].hh.rh;
              IF p=q THEN b := true
              ELSE
                BEGIN
                  WHILE (p<>0)AND(q<>0) DO
                    IF mem[p].hh.lh<>
                       mem[q].hh.lh THEN p := 0
                    ELSE
                      BEGIN
                        p := mem[p].hh.rh;
                        q := mem[q].hh.rh;
                      END;
                  b := ((p=0)AND(q=0));
                END;
            END{:508};
          scannerstatus := savescannerstatus;
        END{:507};
    13:
        BEGIN
          scanfourbitint;
          b := (readopen[curval]=2);
        END;
    14: b := true;
    15: b := false;
    16:{509:}
        BEGIN
          scanint;
          n := curval;
          IF eqtb[5299].int>1 THEN
            BEGIN
              begindiagnostic;
              print(783);
              printint(n);
              printchar(125);
              enddiagnostic(false);
            END;
          WHILE n<>0 DO
            BEGIN
              passtext;
              IF condptr=savecondptr THEN IF curchr=4 THEN n := n-1
              ELSE goto 50
              ELSE IF 
                      curchr=2 THEN{496:}
                     BEGIN
                       p := condptr;
                       ifline := mem[p+1].int;
                       curif := mem[p].hh.b1;
                       iflimit := mem[p].hh.b0;
                       condptr := mem[p].hh.rh;
                       freenode(p,2);
                     END{:496};
            END;
          changeiflimit(4,savecondptr);
          goto 10;
        END{:509};
  END{:501};
  IF eqtb[5299].int>1 THEN{502:}
    BEGIN
      begindiagnostic;
      IF b THEN print(779)
      ELSE print(780);
      enddiagnostic(false);
    END{:502};
  IF b THEN
    BEGIN
      changeiflimit(3,savecondptr);
      goto 10;
    END;
{500:}
  WHILE true DO
    BEGIN
      passtext;
      IF condptr=savecondptr THEN
        BEGIN
          IF curchr<>4 THEN goto 50;
          BEGIN
            IF interaction=3 THEN;
            printnl(262);
            print(777);
          END;
          printesc(775);
          BEGIN
            helpptr := 1;
            helpline[0] := 778;
          END;
          error;
        END
      ELSE IF curchr=2 THEN{496:}
             BEGIN
               p := condptr;
               ifline := mem[p+1].int;
               curif := mem[p].hh.b1;
               iflimit := mem[p].hh.b0;
               condptr := mem[p].hh.rh;
               freenode(p,2);
             END{:496};
    END{:500};
  50: IF curchr=2 THEN{496:}
        BEGIN
          p := condptr;
          ifline := mem[p+1].int;
          curif := mem[p].hh.b1;
          iflimit := mem[p].hh.b0;
          condptr := mem[p].hh.rh;
          freenode(p,2);
        END{:496}
      ELSE iflimit := 2;
  10:
END;
{:498}{515:}
PROCEDURE beginname;
BEGIN
  areadelimiter := 0;
  extdelimiter := 0;
END;{:515}{516:}
FUNCTION morename(c:ASCIIcode): boolean;
BEGIN
  IF c=32 THEN morename := false
  ELSE
    BEGIN
      BEGIN
        IF poolptr+1>
           poolsize THEN overflow(257,poolsize-initpoolptr);
      END;
      BEGIN
        strpool[poolptr] := c;
        poolptr := poolptr+1;
      END;
      IF c=47 THEN
        BEGIN
          areadelimiter := (poolptr-strstart[strptr]);
          extdelimiter := 0;
        END
      ELSE IF (c=46)AND(extdelimiter=0)THEN extdelimiter := (poolptr-strstart
                                                            [strptr]);
      morename := true;
    END;
END;{:516}{517:}
PROCEDURE endname;
BEGIN
  IF strptr+3>maxstrings THEN overflow(258,maxstrings-initstrptr);
  IF areadelimiter=0 THEN curarea := 338
  ELSE
    BEGIN
      curarea := strptr;
      strstart[strptr+1] := strstart[strptr]+areadelimiter;
      strptr := strptr+1;
    END;
  IF extdelimiter=0 THEN
    BEGIN
      curext := 338;
      curname := makestring;
    END
  ELSE
    BEGIN
      curname := strptr;
      strstart[strptr+1] := strstart[strptr]+extdelimiter-areadelimiter-1;
      strptr := strptr+1;
      curext := makestring;
    END;
END;
{:517}{519:}
PROCEDURE packfilename(n,a,e:strnumber);

VAR k: integer;
  c: ASCIIcode;
  j: poolpointer;
BEGIN
  k := 0;
  FOR j:=strstart[a]TO strstart[a+1]-1 DO
    BEGIN
      c := strpool[j];
      k := k+1;
      IF k<=filenamesize THEN nameoffile[k] := xchr[c];
    END;
  FOR j:=strstart[n]TO strstart[n+1]-1 DO
    BEGIN
      c := strpool[j];
      k := k+1;
      IF k<=filenamesize THEN nameoffile[k] := xchr[c];
    END;
  FOR j:=strstart[e]TO strstart[e+1]-1 DO
    BEGIN
      c := strpool[j];
      k := k+1;
      IF k<=filenamesize THEN nameoffile[k] := xchr[c];
    END;
  IF k<=filenamesize THEN namelength := k
  ELSE namelength := filenamesize;
  FOR k:=namelength+1 TO filenamesize DO
    nameoffile[k] := chr(0);
END;
{:519}{523:}
PROCEDURE packbufferedname(n:smallnumber;a,b:integer);

VAR k: integer;
  c: ASCIIcode;
  j: integer;
BEGIN
  IF n+b-a+5>filenamesize THEN b := a+filenamesize-n-5;
  k := 0;
  FOR j:=1 TO n DO
    BEGIN
      c := xord[TEXformatdefault[j]];
      k := k+1;
      IF k<=filenamesize THEN nameoffile[k] := xchr[c];
    END;
  FOR j:=a TO b DO
    BEGIN
      c := buffer[j];
      k := k+1;
      IF k<=filenamesize THEN nameoffile[k] := xchr[c];
    END;
  FOR j:=17 TO 20 DO
    BEGIN
      c := xord[TEXformatdefault[j]];
      k := k+1;
      IF k<=filenamesize THEN nameoffile[k] := xchr[c];
    END;
  IF k<=filenamesize THEN namelength := k
  ELSE namelength := filenamesize;
  FOR k:=namelength+1 TO filenamesize DO
    nameoffile[k] := chr(0);
END;
{:523}{525:}
FUNCTION makenamestring: strnumber;

VAR k: 1..filenamesize;
BEGIN
  IF (poolptr+namelength>poolsize)OR(strptr=maxstrings)OR((poolptr-
     strstart[strptr])>0)THEN makenamestring := 63
  ELSE
    BEGIN
      FOR k:=1 TO
          namelength DO
        BEGIN
          strpool[poolptr] := xord[nameoffile[k]];
          poolptr := poolptr+1;
        END;
      makenamestring := makestring;
    END;
END;
FUNCTION amakenamestring(VAR f:alphafile): strnumber;
BEGIN
  amakenamestring := makenamestring;
END;
FUNCTION bmakenamestring(VAR f:bytefile): strnumber;
BEGIN
  bmakenamestring := makenamestring;
END;
FUNCTION wmakenamestring(VAR f:wordfile): strnumber;
BEGIN
  wmakenamestring := makenamestring;
END;
{:525}{526:}
PROCEDURE scanfilename;

LABEL 30;
BEGIN
  nameinprogress := true;
  beginname;{406:}
  REPEAT
    getxtoken;
  UNTIL curcmd<>10{:406};
  WHILE true DO
    BEGIN
      IF (curcmd>12)OR(curchr>255)THEN
        BEGIN
          backinput;
          goto 30;
        END;
      IF NOT morename(curchr)THEN goto 30;
      getxtoken;
    END;
  30: endname;
  nameinprogress := false;
END;
{:526}{529:}
PROCEDURE packjobname(s:strnumber);
BEGIN
  curarea := 338;
  curext := s;
  curname := jobname;
  packfilename(curname,curarea,curext);
END;
{:529}{530:}
PROCEDURE promptfilename(s,e:strnumber);

LABEL 30;

VAR k: 0..bufsize;
BEGIN
  IF interaction=2 THEN;
  IF s=787 THEN
    BEGIN
      IF interaction=3 THEN;
      printnl(262);
      print(788);
    END
  ELSE
    BEGIN
      IF interaction=3 THEN;
      printnl(262);
      print(789);
    END;
  printfilename(curname,curarea,curext);
  print(790);
  IF e=791 THEN showcontext;
  printnl(792);
  print(s);
  print(793);
  IF interaction<2 THEN fatalerror(794);;
  BEGIN;
    print(568);
    terminput;
  END;
{531:}
  BEGIN
    beginname;
    k := first;
    WHILE (buffer[k]=32)AND(k<last) DO
      k := k+1;
    WHILE true DO
      BEGIN
        IF k=last THEN goto 30;
        IF NOT morename(buffer[k])THEN goto 30;
        k := k+1;
      END;
    30: endname;
  END{:531};
  IF curext=338 THEN curext := e;
  packfilename(curname,curarea,curext);
END;
{:530}{534:}
PROCEDURE openlogfile;

VAR oldsetting: 0..21;
  k: 0..bufsize;
  l: 0..bufsize;
  months: packed array[1..36] OF char;
BEGIN
  oldsetting := selector;
  IF jobname=0 THEN jobname := 797;
  packjobname(798);
  WHILE NOT aopenout(logfile) DO{535:}
    BEGIN
      selector := 17;
      promptfilename(800,798);
    END{:535};
  logname := amakenamestring(logfile);
  selector := 18;
  logopened := true;
{536:}
  BEGIN
    write(logfile,'This is TeX-FPC, 4th ed.');
    slowprint(formatident);
    print(801);
    printint(sysday);
    printchar(32);
    months := 'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC';
    FOR k:=3*sysmonth-2 TO 3*sysmonth DO
      write(logfile,months[k]);
    printchar(32);
    printint(sysyear);
    printchar(32);
    printtwo(systime DIV 60);
    printchar(58);
    printtwo(systime MOD 60);
  END{:536};
  inputstack[inputptr] := curinput;
  printnl(799);
  l := inputstack[0].limitfield;
  IF buffer[l]=eqtb[5311].int THEN l := l-1;
  FOR k:=1 TO l DO
    print(buffer[k]);
  println;
  selector := oldsetting+2;
END;
{:534}{537:}
PROCEDURE startinput;

LABEL 30;
BEGIN
  scanfilename;
  IF curext=338 THEN curext := 791;
  packfilename(curname,curarea,curext);
  WHILE true DO
    BEGIN
      beginfilereading;
      IF aopenin(inputfile[curinput.indexfield])THEN goto 30;
      IF curarea=338 THEN
        BEGIN
          packfilename(curname,784,curext);
          IF aopenin(inputfile[curinput.indexfield])THEN goto 30;
        END;
      endfilereading;
      promptfilename(787,791);
    END;
  30: curinput.namefield := amakenamestring(inputfile[curinput.indexfield]);
  IF jobname=0 THEN
    BEGIN
      jobname := curname;
      openlogfile;
    END;
  IF termoffset+(strstart[curinput.namefield+1]-strstart[curinput.
     namefield])>maxprintline-2 THEN println
  ELSE IF (termoffset>0)OR(
          fileoffset>0)THEN printchar(32);
  printchar(40);
  openparens := openparens+1;
  slowprint(curinput.namefield);
  flush(output);
  curinput.statefield := 33;
{538:}
  BEGIN
    line := 1;
    IF inputln(inputfile[curinput.indexfield],false)THEN;
    firmuptheline;
    IF (eqtb[5311].int<0)OR(eqtb[5311].int>255)THEN curinput.limitfield := 
                                                                           curinput.limitfield-1
    ELSE buffer[curinput.limitfield] := eqtb[5311].int;
    first := curinput.limitfield+1;
    curinput.locfield := curinput.startfield;
  END{:538};
END;{:537}{560:}
FUNCTION readfontinfo(u:halfword;
                      nom,aire:strnumber;s:scaled): internalfontnumber;

LABEL 30,11,45;

VAR k: fontindex;
  fileopened: boolean;
  lf,lh,bc,ec,nw,nh,nd,ni,nl,nk,ne,np: halfword;
  f: internalfontnumber;
  g: internalfontnumber;
  a,b,c,d: eightbits;
  qw: fourquarters;
  sw: scaled;
  bchlabel: integer;
  bchar: 0..256;
  z: scaled;
  alpha: integer;
  beta: 1..16;
BEGIN
  g := 0;{562:}{563:}
  fileopened := false;
  IF aire=338 THEN packfilename(nom,785,812)
  ELSE packfilename(nom,aire,812
    );
  IF NOT bopenin(tfmfile)THEN goto 11;
  fileopened := true{:563};
{565:}
  BEGIN
    BEGIN
      lf := tfmfile^;
      IF lf>127 THEN goto 11;
      get(tfmfile);
      lf := lf*256+tfmfile^;
    END;
    get(tfmfile);
    BEGIN
      lh := tfmfile^;
      IF lh>127 THEN goto 11;
      get(tfmfile);
      lh := lh*256+tfmfile^;
    END;
    get(tfmfile);
    BEGIN
      bc := tfmfile^;
      IF bc>127 THEN goto 11;
      get(tfmfile);
      bc := bc*256+tfmfile^;
    END;
    get(tfmfile);
    BEGIN
      ec := tfmfile^;
      IF ec>127 THEN goto 11;
      get(tfmfile);
      ec := ec*256+tfmfile^;
    END;
    IF (bc>ec+1)OR(ec>255)THEN goto 11;
    IF bc>255 THEN
      BEGIN
        bc := 1;
        ec := 0;
      END;
    get(tfmfile);
    BEGIN
      nw := tfmfile^;
      IF nw>127 THEN goto 11;
      get(tfmfile);
      nw := nw*256+tfmfile^;
    END;
    get(tfmfile);
    BEGIN
      nh := tfmfile^;
      IF nh>127 THEN goto 11;
      get(tfmfile);
      nh := nh*256+tfmfile^;
    END;
    get(tfmfile);
    BEGIN
      nd := tfmfile^;
      IF nd>127 THEN goto 11;
      get(tfmfile);
      nd := nd*256+tfmfile^;
    END;
    get(tfmfile);
    BEGIN
      ni := tfmfile^;
      IF ni>127 THEN goto 11;
      get(tfmfile);
      ni := ni*256+tfmfile^;
    END;
    get(tfmfile);
    BEGIN
      nl := tfmfile^;
      IF nl>127 THEN goto 11;
      get(tfmfile);
      nl := nl*256+tfmfile^;
    END;
    get(tfmfile);
    BEGIN
      nk := tfmfile^;
      IF nk>127 THEN goto 11;
      get(tfmfile);
      nk := nk*256+tfmfile^;
    END;
    get(tfmfile);
    BEGIN
      ne := tfmfile^;
      IF ne>127 THEN goto 11;
      get(tfmfile);
      ne := ne*256+tfmfile^;
    END;
    get(tfmfile);
    BEGIN
      np := tfmfile^;
      IF np>127 THEN goto 11;
      get(tfmfile);
      np := np*256+tfmfile^;
    END;
    IF lf<>6+lh+(ec-bc+1)+nw+nh+nd+ni+nl+nk+ne+np THEN goto 11;
    IF (nw=0)OR(nh=0)OR(nd=0)OR(ni=0)THEN goto 11;
  END{:565};
{566:}
  lf := lf-6-lh;
  IF np<7 THEN lf := lf+7-np;
  IF (fontptr=fontmax)OR(fmemptr+lf>fontmemsize)THEN{567:}
    BEGIN
      BEGIN
        IF 
           interaction=3 THEN;
        printnl(262);
        print(803);
      END;
      sprintcs(u);
      printchar(61);
      printfilename(nom,aire,338);
      IF s>=0 THEN
        BEGIN
          print(741);
          printscaled(s);
          print(397);
        END
      ELSE IF s<>-1000 THEN
             BEGIN
               print(804);
               printint(-s);
             END;
      print(813);
      BEGIN
        helpptr := 4;
        helpline[3] := 814;
        helpline[2] := 815;
        helpline[1] := 816;
        helpline[0] := 817;
      END;
      error;
      goto 30;
    END{:567};
  f := fontptr+1;
  charbase[f] := fmemptr-bc;
  widthbase[f] := charbase[f]+ec+1;
  heightbase[f] := widthbase[f]+nw;
  depthbase[f] := heightbase[f]+nh;
  italicbase[f] := depthbase[f]+nd;
  ligkernbase[f] := italicbase[f]+ni;
  kernbase[f] := ligkernbase[f]+nl-256*(128);
  extenbase[f] := kernbase[f]+256*(128)+nk;
  parambase[f] := extenbase[f]+ne{:566};{568:}
  BEGIN
    IF lh<2 THEN goto 11;
    BEGIN
      get(tfmfile);
      a := tfmfile^;
      qw.b0 := a;
      get(tfmfile);
      b := tfmfile^;
      qw.b1 := b;
      get(tfmfile);
      c := tfmfile^;
      qw.b2 := c;
      get(tfmfile);
      d := tfmfile^;
      qw.b3 := d;
      fontcheck[f] := qw;
    END;
    get(tfmfile);
    BEGIN
      z := tfmfile^;
      IF z>127 THEN goto 11;
      get(tfmfile);
      z := z*256+tfmfile^;
    END;
    get(tfmfile);
    z := z*256+tfmfile^;
    get(tfmfile);
    z := (z*16)+(tfmfile^DIV 16);
    IF z<65536 THEN goto 11;
    WHILE lh>2 DO
      BEGIN
        get(tfmfile);
        get(tfmfile);
        get(tfmfile);
        get(tfmfile);
        lh := lh-1;
      END;
    fontdsize[f] := z;
    IF s<>-1000 THEN IF s>=0 THEN z := s
    ELSE z := xnoverd(z,-s,1000);
    fontsize[f] := z;
  END{:568};
{569:}
  FOR k:=fmemptr TO widthbase[f]-1 DO
    BEGIN
      BEGIN
        get(tfmfile);
        a := tfmfile^;
        qw.b0 := a;
        get(tfmfile);
        b := tfmfile^;
        qw.b1 := b;
        get(tfmfile);
        c := tfmfile^;
        qw.b2 := c;
        get(tfmfile);
        d := tfmfile^;
        qw.b3 := d;
        fontinfo[k].qqqq := qw;
      END;
      IF (a>=nw)OR(b DIV 16>=nh)OR(b MOD 16>=nd)OR(c DIV 4>=ni)THEN goto 11;
      CASE c MOD 4 OF 
        1: IF d>=nl THEN goto 11;
        3: IF d>=ne THEN goto 11;
        2:{570:}
           BEGIN
             BEGIN
               IF (d<bc)OR(d>ec)THEN goto 11
             END;
             WHILE d<k+bc-fmemptr DO
               BEGIN
                 qw := fontinfo[charbase[f]+d].qqqq;
                 IF ((qw.b2)MOD 4)<>2 THEN goto 45;
                 d := qw.b3;
               END;
             IF d=k+bc-fmemptr THEN goto 11;
             45:
           END{:570};
        ELSE
      END;
    END{:569};
{571:}
  BEGIN{572:}
    BEGIN
      alpha := 16;
      WHILE z>=8388608 DO
        BEGIN
          z := z DIV 2;
          alpha := alpha+alpha;
        END;
      beta := 256 DIV alpha;
      alpha := alpha*z;
    END{:572};
    FOR k:=widthbase[f]TO ligkernbase[f]-1 DO
      BEGIN
        get(tfmfile);
        a := tfmfile^;
        get(tfmfile);
        b := tfmfile^;
        get(tfmfile);
        c := tfmfile^;
        get(tfmfile);
        d := tfmfile^;
        sw := (((((d*z)DIV 256)+(c*z))DIV 256)+(b*z))DIV beta;
        IF a=0 THEN fontinfo[k].int := sw
        ELSE IF a=255 THEN fontinfo[k].int := sw-
                                              alpha
        ELSE goto 11;
      END;
    IF fontinfo[widthbase[f]].int<>0 THEN goto 11;
    IF fontinfo[heightbase[f]].int<>0 THEN goto 11;
    IF fontinfo[depthbase[f]].int<>0 THEN goto 11;
    IF fontinfo[italicbase[f]].int<>0 THEN goto 11;
  END{:571};
{573:}
  bchlabel := 32767;
  bchar := 256;
  IF nl>0 THEN
    BEGIN
      FOR k:=ligkernbase[f]TO kernbase[f]+256*(128)-1 DO
        BEGIN
          BEGIN
            get(tfmfile);
            a := tfmfile^;
            qw.b0 := a;
            get(tfmfile);
            b := tfmfile^;
            qw.b1 := b;
            get(tfmfile);
            c := tfmfile^;
            qw.b2 := c;
            get(tfmfile);
            d := tfmfile^;
            qw.b3 := d;
            fontinfo[k].qqqq := qw;
          END;
          IF a>128 THEN
            BEGIN
              IF 256*c+d>=nl THEN goto 11;
              IF a=255 THEN IF k=ligkernbase[f]THEN bchar := b;
            END
          ELSE
            BEGIN
              IF b<>bchar THEN
                BEGIN
                  BEGIN
                    IF (b<bc)OR(b>ec)THEN goto 11
                  END;
                  qw := fontinfo[charbase[f]+b].qqqq;
                  IF NOT(qw.b0>0)THEN goto 11;
                END;
              IF c<128 THEN
                BEGIN
                  BEGIN
                    IF (d<bc)OR(d>ec)THEN goto 11
                  END;
                  qw := fontinfo[charbase[f]+d].qqqq;
                  IF NOT(qw.b0>0)THEN goto 11;
                END
              ELSE IF 256*(c-128)+d>=nk THEN goto 11;
              IF a<128 THEN IF k-ligkernbase[f]+a+1>=nl THEN goto 11;
            END;
        END;
      IF a=255 THEN bchlabel := 256*c+d;
    END;
  FOR k:=kernbase[f]+256*(128)TO extenbase[f]-1 DO
    BEGIN
      get(tfmfile);
      a := tfmfile^;
      get(tfmfile);
      b := tfmfile^;
      get(tfmfile);
      c := tfmfile^;
      get(tfmfile);
      d := tfmfile^;
      sw := (((((d*z)DIV 256)+(c*z))DIV 256)+(b*z))DIV beta;
      IF a=0 THEN fontinfo[k].int := sw
      ELSE IF a=255 THEN fontinfo[k].int := sw-
                                            alpha
      ELSE goto 11;
    END;{:573};
{574:}
  FOR k:=extenbase[f]TO parambase[f]-1 DO
    BEGIN
      BEGIN
        get(tfmfile);
        a := tfmfile^;
        qw.b0 := a;
        get(tfmfile);
        b := tfmfile^;
        qw.b1 := b;
        get(tfmfile);
        c := tfmfile^;
        qw.b2 := c;
        get(tfmfile);
        d := tfmfile^;
        qw.b3 := d;
        fontinfo[k].qqqq := qw;
      END;
      IF a<>0 THEN
        BEGIN
          BEGIN
            IF (a<bc)OR(a>ec)THEN goto 11
          END;
          qw := fontinfo[charbase[f]+a].qqqq;
          IF NOT(qw.b0>0)THEN goto 11;
        END;
      IF b<>0 THEN
        BEGIN
          BEGIN
            IF (b<bc)OR(b>ec)THEN goto 11
          END;
          qw := fontinfo[charbase[f]+b].qqqq;
          IF NOT(qw.b0>0)THEN goto 11;
        END;
      IF c<>0 THEN
        BEGIN
          BEGIN
            IF (c<bc)OR(c>ec)THEN goto 11
          END;
          qw := fontinfo[charbase[f]+c].qqqq;
          IF NOT(qw.b0>0)THEN goto 11;
        END;
      BEGIN
        BEGIN
          IF (d<bc)OR(d>ec)THEN goto 11
        END;
        qw := fontinfo[charbase[f]+d].qqqq;
        IF NOT(qw.b0>0)THEN goto 11;
      END;
    END{:574};{575:}
  BEGIN
    FOR k:=1 TO np DO
      IF k=1 THEN
        BEGIN
          get(tfmfile);
          sw := tfmfile^;
          IF sw>127 THEN sw := sw-256;
          get(tfmfile);
          sw := sw*256+tfmfile^;
          get(tfmfile);
          sw := sw*256+tfmfile^;
          get(tfmfile);
          fontinfo[parambase[f]].int := (sw*16)+(tfmfile^DIV 16);
        END
      ELSE
        BEGIN
          get(tfmfile);
          a := tfmfile^;
          get(tfmfile);
          b := tfmfile^;
          get(tfmfile);
          c := tfmfile^;
          get(tfmfile);
          d := tfmfile^;
          sw := (((((d*z)DIV 256)+(c*z))DIV 256)+(b*z))DIV beta;
          IF a=0 THEN fontinfo[parambase[f]+k-1].int := sw
          ELSE IF a=255 THEN
                 fontinfo[parambase[f]+k-1].int := sw-alpha
          ELSE goto 11;
        END;
    FOR k:=np+1 TO 7 DO
      fontinfo[parambase[f]+k-1].int := 0;
  END{:575};
{576:}
  IF np>=7 THEN fontparams[f] := np
  ELSE fontparams[f] := 7;
  hyphenchar[f] := eqtb[5309].int;
  skewchar[f] := eqtb[5310].int;
  IF bchlabel<nl THEN bcharlabel[f] := bchlabel+ligkernbase[f]
  ELSE
    bcharlabel[f] := 0;
  fontbchar[f] := bchar;
  fontfalsebchar[f] := bchar;
  IF bchar<=ec THEN IF bchar>=bc THEN
                      BEGIN
                        qw := fontinfo[charbase[f]+bchar
                              ].qqqq;
                        IF (qw.b0>0)THEN fontfalsebchar[f] := 256;
                      END;
  fontname[f] := nom;
  fontarea[f] := aire;
  fontbc[f] := bc;
  fontec[f] := ec;
  fontglue[f] := 0;
  charbase[f] := charbase[f];
  widthbase[f] := widthbase[f];
  ligkernbase[f] := ligkernbase[f];
  kernbase[f] := kernbase[f];
  extenbase[f] := extenbase[f];
  parambase[f] := parambase[f]-1;
  fmemptr := fmemptr+lf;
  fontptr := f;
  g := f;
  goto 30{:576}{:562};
  11:{561:}
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(803);
      END;
  sprintcs(u);
  printchar(61);
  printfilename(nom,aire,338);
  IF s>=0 THEN
    BEGIN
      print(741);
      printscaled(s);
      print(397);
    END
  ELSE IF s<>-1000 THEN
         BEGIN
           print(804);
           printint(-s);
         END;
  IF fileopened THEN print(805)
  ELSE print(806);
  BEGIN
    helpptr := 5;
    helpline[4] := 807;
    helpline[3] := 808;
    helpline[2] := 809;
    helpline[1] := 810;
    helpline[0] := 811;
  END;
  error{:561};
  30: IF fileopened THEN bclose(tfmfile);
  readfontinfo := g;
END;
{:560}{581:}
PROCEDURE charwarning(f:internalfontnumber;c:eightbits);
BEGIN
  IF eqtb[5298].int>0 THEN
    BEGIN
      begindiagnostic;
      printnl(826);
      print(c);
      print(827);
      slowprint(fontname[f]);
      printchar(33);
      enddiagnostic(false);
    END;
END;
{:581}{582:}
FUNCTION newcharacter(f:internalfontnumber;
                      c:eightbits): halfword;

LABEL 10;

VAR p: halfword;
BEGIN
  IF fontbc[f]<=c THEN IF fontec[f]>=c THEN IF (fontinfo[charbase[f]+
                                               c].qqqq.b0>0)THEN
                                              BEGIN
                                                p := getavail;
                                                mem[p].hh.b0 := f;
                                                mem[p].hh.b1 := c;
                                                newcharacter := p;
                                                goto 10;
                                              END;
  charwarning(f,c);
  newcharacter := 0;
  10:
END;
{:582}{597:}
PROCEDURE writedvi(a,b:dviindex);
BEGIN
  blockwrite(dvifile,dvibuf[a],b-a+1);
END;
{:597}{598:}
PROCEDURE dviswap;
BEGIN
  IF dvilimit=dvibufsize THEN
    BEGIN
      writedvi(0,halfbuf-1);
      dvilimit := halfbuf;
      dvioffset := dvioffset+dvibufsize;
      dviptr := 0;
    END
  ELSE
    BEGIN
      writedvi(halfbuf,dvibufsize-1);
      dvilimit := dvibufsize;
    END;
  dvigone := dvigone+halfbuf;
END;{:598}{600:}
PROCEDURE dvifour(x:integer);
BEGIN
  IF x>=0 THEN
    BEGIN
      dvibuf[dviptr] := x DIV 16777216;
      dviptr := dviptr+1;
      IF dviptr=dvilimit THEN dviswap;
    END
  ELSE
    BEGIN
      x := x+1073741824;
      x := x+1073741824;
      BEGIN
        dvibuf[dviptr] := (x DIV 16777216)+128;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
    END;
  x := x MOD 16777216;
  BEGIN
    dvibuf[dviptr] := x DIV 65536;
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
  x := x MOD 65536;
  BEGIN
    dvibuf[dviptr] := x DIV 256;
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
  BEGIN
    dvibuf[dviptr] := x MOD 256;
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
END;
{:600}{601:}
PROCEDURE dvipop(l:integer);
BEGIN
  IF (l=dvioffset+dviptr)AND(dviptr>0)THEN dviptr := dviptr-1
  ELSE
    BEGIN
      dvibuf[dviptr] := 142;
      dviptr := dviptr+1;
      IF dviptr=dvilimit THEN dviswap;
    END;
END;
{:601}{602:}
PROCEDURE dvifontdef(f:internalfontnumber);

VAR k: poolpointer;
BEGIN
  BEGIN
    dvibuf[dviptr] := 243;
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
  BEGIN
    dvibuf[dviptr] := f-1;
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
  BEGIN
    dvibuf[dviptr] := fontcheck[f].b0;
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
  BEGIN
    dvibuf[dviptr] := fontcheck[f].b1;
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
  BEGIN
    dvibuf[dviptr] := fontcheck[f].b2;
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
  BEGIN
    dvibuf[dviptr] := fontcheck[f].b3;
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
  dvifour(fontsize[f]);
  dvifour(fontdsize[f]);
  BEGIN
    dvibuf[dviptr] := (strstart[fontarea[f]+1]-strstart[fontarea[f]]);
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
  BEGIN
    dvibuf[dviptr] := (strstart[fontname[f]+1]-strstart[fontname[f]]);
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
{603:}
  FOR k:=strstart[fontarea[f]]TO strstart[fontarea[f]+1]-1 DO
    BEGIN
      dvibuf[dviptr] := strpool[k];
      dviptr := dviptr+1;
      IF dviptr=dvilimit THEN dviswap;
    END;
  FOR k:=strstart[fontname[f]]TO strstart[fontname[f]+1]-1 DO
    BEGIN
      dvibuf
      [dviptr] := strpool[k];
      dviptr := dviptr+1;
      IF dviptr=dvilimit THEN dviswap;
    END{:603};
END;{:602}{607:}
PROCEDURE movement(w:scaled;o:eightbits);

LABEL 10,40,45,2,1;

VAR mstate: smallnumber;
  p,q: halfword;
  k: integer;
BEGIN
  q := getnode(3);
  mem[q+1].int := w;
  mem[q+2].int := dvioffset+dviptr;
  IF o=157 THEN
    BEGIN
      mem[q].hh.rh := downptr;
      downptr := q;
    END
  ELSE
    BEGIN
      mem[q].hh.rh := rightptr;
      rightptr := q;
    END;
{611:}
  p := mem[q].hh.rh;
  mstate := 0;
  WHILE p<>0 DO
    BEGIN
      IF mem[p+1].int=w THEN{612:}CASE mstate+mem[p].hh.lh 
                                    OF 
                                    3,4,15,16: IF mem[p+2].int<dvigone THEN goto 45
                                               ELSE{613:}
                                                 BEGIN
                                                   k := mem
                                                        [p+2].int-dvioffset;
                                                   IF k<0 THEN k := k+dvibufsize;
                                                   dvibuf[k] := dvibuf[k]+5;
                                                   mem[p].hh.lh := 1;
                                                   goto 40;
                                                 END{:613};
                                    5,9,11: IF mem[p+2].int<dvigone THEN goto 45
                                            ELSE{614:}
                                              BEGIN
                                                k := mem[p+2].
                                                     int-dvioffset;
                                                IF k<0 THEN k := k+dvibufsize;
                                                dvibuf[k] := dvibuf[k]+10;
                                                mem[p].hh.lh := 2;
                                                goto 40;
                                              END{:614};
                                    1,2,8,13: goto 40;
                                    ELSE
        END{:612}
      ELSE CASE mstate+mem[p].hh.lh OF 
             1: mstate := 6;
             2: mstate := 12;
             8,13: goto 45;
             ELSE
        END;
      p := mem[p].hh.rh;
    END;
  45:{:611};
{610:}
  mem[q].hh.lh := 3;
  IF abs(w)>=8388608 THEN
    BEGIN
      BEGIN
        dvibuf[dviptr] := o+3;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      dvifour(w);
      goto 10;
    END;
  IF abs(w)>=32768 THEN
    BEGIN
      BEGIN
        dvibuf[dviptr] := o+2;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      IF w<0 THEN w := w+16777216;
      BEGIN
        dvibuf[dviptr] := w DIV 65536;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      w := w MOD 65536;
      goto 2;
    END;
  IF abs(w)>=128 THEN
    BEGIN
      BEGIN
        dvibuf[dviptr] := o+1;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      IF w<0 THEN w := w+65536;
      goto 2;
    END;
  BEGIN
    dvibuf[dviptr] := o;
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
  IF w<0 THEN w := w+256;
  goto 1;
  2:
     BEGIN
       dvibuf[dviptr] := w DIV 256;
       dviptr := dviptr+1;
       IF dviptr=dvilimit THEN dviswap;
     END;
  1:
     BEGIN
       dvibuf[dviptr] := w MOD 256;
       dviptr := dviptr+1;
       IF dviptr=dvilimit THEN dviswap;
     END;
  goto 10{:610};
  40:{609:}mem[q].hh.lh := mem[p].hh.lh;
  IF mem[q].hh.lh=1 THEN
    BEGIN
      BEGIN
        dvibuf[dviptr] := o+4;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      WHILE mem[q].hh.rh<>p DO
        BEGIN
          q := mem[q].hh.rh;
          CASE mem[q].hh.lh OF 
            3: mem[q].hh.lh := 5;
            4: mem[q].hh.lh := 6;
            ELSE
          END;
        END;
    END
  ELSE
    BEGIN
      BEGIN
        dvibuf[dviptr] := o+9;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      WHILE mem[q].hh.rh<>p DO
        BEGIN
          q := mem[q].hh.rh;
          CASE mem[q].hh.lh OF 
            3: mem[q].hh.lh := 4;
            5: mem[q].hh.lh := 6;
            ELSE
          END;
        END;
    END{:609};
  10:
END;{:607}{615:}
PROCEDURE prunemovements(l:integer);

LABEL 30,10;

VAR p: halfword;
BEGIN
  WHILE downptr<>0 DO
    BEGIN
      IF mem[downptr+2].int<l THEN goto 30;
      p := downptr;
      downptr := mem[p].hh.rh;
      freenode(p,3);
    END;
  30: WHILE rightptr<>0 DO
        BEGIN
          IF mem[rightptr+2].int<l THEN goto 10;
          p := rightptr;
          rightptr := mem[p].hh.rh;
          freenode(p,3);
        END;
  10:
END;
{:615}{618:}
PROCEDURE vlistout;
forward;
{:618}{619:}{1368:}
PROCEDURE specialout(p:halfword);

VAR oldsetting: 0..21;
  k: poolpointer;
BEGIN
  IF curh<>dvih THEN
    BEGIN
      movement(curh-dvih,143);
      dvih := curh;
    END;
  IF curv<>dviv THEN
    BEGIN
      movement(curv-dviv,157);
      dviv := curv;
    END;
  oldsetting := selector;
  selector := 21;
  showtokenlist(mem[mem[p+1].hh.rh].hh.rh,0,poolsize-poolptr);
  selector := oldsetting;
  BEGIN
    IF poolptr+1>poolsize THEN overflow(257,poolsize-initpoolptr);
  END;
  IF (poolptr-strstart[strptr])<256 THEN
    BEGIN
      BEGIN
        dvibuf[dviptr] := 239;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      BEGIN
        dvibuf[dviptr] := (poolptr-strstart[strptr]);
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
    END
  ELSE
    BEGIN
      BEGIN
        dvibuf[dviptr] := 242;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      dvifour((poolptr-strstart[strptr]));
    END;
  FOR k:=strstart[strptr]TO poolptr-1 DO
    BEGIN
      dvibuf[dviptr] := strpool[k];
      dviptr := dviptr+1;
      IF dviptr=dvilimit THEN dviswap;
    END;
  poolptr := strstart[strptr];
END;
{:1368}{1370:}
PROCEDURE writeout(p:halfword);

VAR oldsetting: 0..21;
  oldmode: integer;
  j: smallnumber;
  q,r: halfword;
BEGIN{1371:}
  q := getavail;
  mem[q].hh.lh := 637;
  r := getavail;
  mem[q].hh.rh := r;
  mem[r].hh.lh := 6717;
  begintokenlist(q,4);
  begintokenlist(mem[p+1].hh.rh,15);
  q := getavail;
  mem[q].hh.lh := 379;
  begintokenlist(q,4);
  oldmode := curlist.modefield;
  curlist.modefield := 0;
  curcs := writeloc;
  q := scantoks(false,true);
  gettoken;
  IF curtok<>6717 THEN{1372:}
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(1298);
      END;
      BEGIN
        helpptr := 2;
        helpline[1] := 1299;
        helpline[0] := 1013;
      END;
      error;
      REPEAT
        gettoken;
      UNTIL curtok=6717;
    END{:1372};
  curlist.modefield := oldmode;
  endtokenlist{:1371};
  oldsetting := selector;
  j := mem[p+1].hh.lh;
  IF writeopen[j]THEN selector := j
  ELSE
    BEGIN
      IF (j=17)AND(selector=19)THEN
        selector := 18;
      printnl(338);
    END;
  tokenshow(defref);
  println;
  flushlist(defref);
  selector := oldsetting;
END;
{:1370}{1373:}
PROCEDURE outwhat(p:halfword);

VAR j: smallnumber;
BEGIN
  CASE mem[p].hh.b1 OF 
    0,1,2:{1374:}IF NOT doingleaders THEN
                   BEGIN
                     j 
                     := mem[p+1].hh.lh;
                     IF mem[p].hh.b1=1 THEN writeout(p)
                     ELSE
                       BEGIN
                         IF writeopen[j]THEN aclose(
                                                    writefile[j]);
                         IF mem[p].hh.b1=2 THEN writeopen[j] := false
                         ELSE IF j<16 THEN
                                BEGIN
                                  curname := mem[p+1].hh.rh;
                                  curarea := mem[p+2].hh.lh;
                                  curext := mem[p+2].hh.rh;
                                  IF curext=338 THEN curext := 791;
                                  packfilename(curname,curarea,curext);
                                  WHILE NOT aopenout(writefile[j]) DO
                                    promptfilename(1301,791);
                                  writeopen[j] := true;
                                END;
                       END;
                   END{:1374};
    3: specialout(p);
    4:;
    ELSE confusion(1300)
  END;
END;{:1373}
PROCEDURE hlistout;

LABEL 21,13,14,15;

VAR baseline: scaled;
  leftedge: scaled;
  saveh,savev: scaled;
  thisbox: halfword;
  gorder: glueord;
  gsign: 0..2;
  p: halfword;
  saveloc: integer;
  leaderbox: halfword;
  leaderwd: scaled;
  lx: scaled;
  outerdoingleaders: boolean;
  edge: scaled;
  gluetemp: real;
  curglue: real;
  curg: scaled;
BEGIN
  curg := 0;
  curglue := 0.0;
  thisbox := tempptr;
  gorder := mem[thisbox+5].hh.b1;
  gsign := mem[thisbox+5].hh.b0;
  p := mem[thisbox+5].hh.rh;
  curs := curs+1;
  IF curs>0 THEN
    BEGIN
      dvibuf[dviptr] := 141;
      dviptr := dviptr+1;
      IF dviptr=dvilimit THEN dviswap;
    END;
  IF curs>maxpush THEN maxpush := curs;
  saveloc := dvioffset+dviptr;
  baseline := curv;
  leftedge := curh;
  WHILE p<>0 DO{620:}
    21: IF (p>=himemmin)THEN
          BEGIN
            IF curh<>dvih THEN
              BEGIN
                movement(curh-dvih,143);
                dvih := curh;
              END;
            IF curv<>dviv THEN
              BEGIN
                movement(curv-dviv,157);
                dviv := curv;
              END;
            REPEAT
              f := mem[p].hh.b0;
              c := mem[p].hh.b1;
              IF f<>dvif THEN{621:}
                BEGIN
                  IF NOT fontused[f]THEN
                    BEGIN
                      dvifontdef(f);
                      fontused[f] := true;
                    END;
                  IF f<=64 THEN
                    BEGIN
                      dvibuf[dviptr] := f+170;
                      dviptr := dviptr+1;
                      IF dviptr=dvilimit THEN dviswap;
                    END
                  ELSE
                    BEGIN
                      BEGIN
                        dvibuf[dviptr] := 235;
                        dviptr := dviptr+1;
                        IF dviptr=dvilimit THEN dviswap;
                      END;
                      BEGIN
                        dvibuf[dviptr] := f-1;
                        dviptr := dviptr+1;
                        IF dviptr=dvilimit THEN dviswap;
                      END;
                    END;
                  dvif := f;
                END{:621};
              IF c>=128 THEN
                BEGIN
                  dvibuf[dviptr] := 128;
                  dviptr := dviptr+1;
                  IF dviptr=dvilimit THEN dviswap;
                END;
              BEGIN
                dvibuf[dviptr] := c;
                dviptr := dviptr+1;
                IF dviptr=dvilimit THEN dviswap;
              END;
              curh := curh+fontinfo[widthbase[f]+fontinfo[charbase[f]+c].qqqq.b0].int;
              p := mem[p].hh.rh;
            UNTIL NOT(p>=himemmin);
            dvih := curh;
          END
        ELSE{622:}
          BEGIN
            CASE mem[p].hh.b0 OF 
              0,1:{623:}IF mem[p+5].hh.rh=0
                          THEN curh := curh+mem[p+1].int
                   ELSE
                     BEGIN
                       saveh := dvih;
                       savev := dviv;
                       curv := baseline+mem[p+4].int;
                       tempptr := p;
                       edge := curh;
                       IF mem[p].hh.b0=1 THEN vlistout
                       ELSE hlistout;
                       dvih := saveh;
                       dviv := savev;
                       curh := edge+mem[p+1].int;
                       curv := baseline;
                     END{:623};
              2:
                 BEGIN
                   ruleht := mem[p+3].int;
                   ruledp := mem[p+2].int;
                   rulewd := mem[p+1].int;
                   goto 14;
                 END;
              8:{1367:}outwhat(p){:1367};
              10:{625:}
                  BEGIN
                    g := mem[p+1].hh.lh;
                    rulewd := mem[g+1].int-curg;
                    IF gsign<>0 THEN
                      BEGIN
                        IF gsign=1 THEN
                          BEGIN
                            IF mem[g].hh.b0=gorder THEN
                              BEGIN
                                curglue := curglue+mem[g+2].int;
                                gluetemp := mem[thisbox+6].gr*curglue;
                                IF gluetemp>1000000000.0 THEN gluetemp := 1000000000.0
                                ELSE IF gluetemp<
                                        -1000000000.0 THEN gluetemp := -1000000000.0;
                                curg := round(gluetemp);
                              END;
                          END
                        ELSE IF mem[g].hh.b1=gorder THEN
                               BEGIN
                                 curglue := curglue-mem[g+3].int
                                 ;
                                 gluetemp := mem[thisbox+6].gr*curglue;
                                 IF gluetemp>1000000000.0 THEN gluetemp := 1000000000.0
                                 ELSE IF gluetemp<
                                         -1000000000.0 THEN gluetemp := -1000000000.0;
                                 curg := round(gluetemp);
                               END;
                      END;
                    rulewd := rulewd+curg;
                    IF mem[p].hh.b1>=100 THEN{626:}
                      BEGIN
                        leaderbox := mem[p+1].hh.rh;
                        IF mem[leaderbox].hh.b0=2 THEN
                          BEGIN
                            ruleht := mem[leaderbox+3].int;
                            ruledp := mem[leaderbox+2].int;
                            goto 14;
                          END;
                        leaderwd := mem[leaderbox+1].int;
                        IF (leaderwd>0)AND(rulewd>0)THEN
                          BEGIN
                            rulewd := rulewd+10;
                            edge := curh+rulewd;
                            lx := 0;
{627:}
                            IF mem[p].hh.b1=100 THEN
                              BEGIN
                                saveh := curh;
                                curh := leftedge+leaderwd*((curh-leftedge)DIV leaderwd);
                                IF curh<saveh THEN curh := curh+leaderwd;
                              END
                            ELSE
                              BEGIN
                                lq := rulewd DIV leaderwd;
                                lr := rulewd MOD leaderwd;
                                IF mem[p].hh.b1=101 THEN curh := curh+(lr DIV 2)
                                ELSE
                                  BEGIN
                                    lx := lr DIV(lq+1
                                          );
                                    curh := curh+((lr-(lq-1)*lx)DIV 2);
                                  END;
                              END{:627};
                            WHILE curh+leaderwd<=edge DO{628:}
                              BEGIN
                                curv := baseline+mem[leaderbox+4].
                                        int;
                                IF curv<>dviv THEN
                                  BEGIN
                                    movement(curv-dviv,157);
                                    dviv := curv;
                                  END;
                                savev := dviv;
                                IF curh<>dvih THEN
                                  BEGIN
                                    movement(curh-dvih,143);
                                    dvih := curh;
                                  END;
                                saveh := dvih;
                                tempptr := leaderbox;
                                outerdoingleaders := doingleaders;
                                doingleaders := true;
                                IF mem[leaderbox].hh.b0=1 THEN vlistout
                                ELSE hlistout;
                                doingleaders := outerdoingleaders;
                                dviv := savev;
                                dvih := saveh;
                                curv := baseline;
                                curh := saveh+leaderwd+lx;
                              END{:628};
                            curh := edge-10;
                            goto 15;
                          END;
                      END{:626};
                    goto 13;
                  END{:625};
              11,9: curh := curh+mem[p+1].int;
              6:{652:}
                 BEGIN
                   mem[29988] := mem[p+1];
                   mem[29988].hh.rh := mem[p].hh.rh;
                   p := 29988;
                   goto 21;
                 END{:652};
              ELSE
            END;
            goto 15;
            14:{624:}IF (ruleht=-1073741824)THEN ruleht := mem[thisbox+3].int;
            IF (ruledp=-1073741824)THEN ruledp := mem[thisbox+2].int;
            ruleht := ruleht+ruledp;
            IF (ruleht>0)AND(rulewd>0)THEN
              BEGIN
                IF curh<>dvih THEN
                  BEGIN
                    movement(
                             curh-dvih,143);
                    dvih := curh;
                  END;
                curv := baseline+ruledp;
                IF curv<>dviv THEN
                  BEGIN
                    movement(curv-dviv,157);
                    dviv := curv;
                  END;
                BEGIN
                  dvibuf[dviptr] := 132;
                  dviptr := dviptr+1;
                  IF dviptr=dvilimit THEN dviswap;
                END;
                dvifour(ruleht);
                dvifour(rulewd);
                curv := baseline;
                dvih := dvih+rulewd;
              END{:624};
            13: curh := curh+rulewd;
            15: p := mem[p].hh.rh;
          END{:622}{:620};
  prunemovements(saveloc);
  IF curs>0 THEN dvipop(saveloc);
  curs := curs-1;
END;
{:619}{629:}
PROCEDURE vlistout;

LABEL 13,14,15;

VAR leftedge: scaled;
  topedge: scaled;
  saveh,savev: scaled;
  thisbox: halfword;
  gorder: glueord;
  gsign: 0..2;
  p: halfword;
  saveloc: integer;
  leaderbox: halfword;
  leaderht: scaled;
  lx: scaled;
  outerdoingleaders: boolean;
  edge: scaled;
  gluetemp: real;
  curglue: real;
  curg: scaled;
BEGIN
  curg := 0;
  curglue := 0.0;
  thisbox := tempptr;
  gorder := mem[thisbox+5].hh.b1;
  gsign := mem[thisbox+5].hh.b0;
  p := mem[thisbox+5].hh.rh;
  curs := curs+1;
  IF curs>0 THEN
    BEGIN
      dvibuf[dviptr] := 141;
      dviptr := dviptr+1;
      IF dviptr=dvilimit THEN dviswap;
    END;
  IF curs>maxpush THEN maxpush := curs;
  saveloc := dvioffset+dviptr;
  leftedge := curh;
  curv := curv-mem[thisbox+3].int;
  topedge := curv;
  WHILE p<>0 DO{630:}
    BEGIN
      IF (p>=himemmin)THEN confusion(829)
      ELSE{631:}
        BEGIN
          CASE mem[p].hh.b0 OF 
            0,1:{632:}IF mem[p+5].hh.rh=0 THEN curv := curv
                                                       +mem[p+3].int+mem[p+2].int
                 ELSE
                   BEGIN
                     curv := curv+mem[p+3].int;
                     IF curv<>dviv THEN
                       BEGIN
                         movement(curv-dviv,157);
                         dviv := curv;
                       END;
                     saveh := dvih;
                     savev := dviv;
                     curh := leftedge+mem[p+4].int;
                     tempptr := p;
                     IF mem[p].hh.b0=1 THEN vlistout
                     ELSE hlistout;
                     dvih := saveh;
                     dviv := savev;
                     curv := savev+mem[p+2].int;
                     curh := leftedge;
                   END{:632};
            2:
               BEGIN
                 ruleht := mem[p+3].int;
                 ruledp := mem[p+2].int;
                 rulewd := mem[p+1].int;
                 goto 14;
               END;
            8:{1366:}outwhat(p){:1366};
            10:{634:}
                BEGIN
                  g := mem[p+1].hh.lh;
                  ruleht := mem[g+1].int-curg;
                  IF gsign<>0 THEN
                    BEGIN
                      IF gsign=1 THEN
                        BEGIN
                          IF mem[g].hh.b0=gorder THEN
                            BEGIN
                              curglue := curglue+mem[g+2].int;
                              gluetemp := mem[thisbox+6].gr*curglue;
                              IF gluetemp>1000000000.0 THEN gluetemp := 1000000000.0
                              ELSE IF gluetemp<
                                      -1000000000.0 THEN gluetemp := -1000000000.0;
                              curg := round(gluetemp);
                            END;
                        END
                      ELSE IF mem[g].hh.b1=gorder THEN
                             BEGIN
                               curglue := curglue-mem[g+3].int
                               ;
                               gluetemp := mem[thisbox+6].gr*curglue;
                               IF gluetemp>1000000000.0 THEN gluetemp := 1000000000.0
                               ELSE IF gluetemp<
                                       -1000000000.0 THEN gluetemp := -1000000000.0;
                               curg := round(gluetemp);
                             END;
                    END;
                  ruleht := ruleht+curg;
                  IF mem[p].hh.b1>=100 THEN{635:}
                    BEGIN
                      leaderbox := mem[p+1].hh.rh;
                      IF mem[leaderbox].hh.b0=2 THEN
                        BEGIN
                          rulewd := mem[leaderbox+1].int;
                          ruledp := 0;
                          goto 14;
                        END;
                      leaderht := mem[leaderbox+3].int+mem[leaderbox+2].int;
                      IF (leaderht>0)AND(ruleht>0)THEN
                        BEGIN
                          ruleht := ruleht+10;
                          edge := curv+ruleht;
                          lx := 0;
{636:}
                          IF mem[p].hh.b1=100 THEN
                            BEGIN
                              savev := curv;
                              curv := topedge+leaderht*((curv-topedge)DIV leaderht);
                              IF curv<savev THEN curv := curv+leaderht;
                            END
                          ELSE
                            BEGIN
                              lq := ruleht DIV leaderht;
                              lr := ruleht MOD leaderht;
                              IF mem[p].hh.b1=101 THEN curv := curv+(lr DIV 2)
                              ELSE
                                BEGIN
                                  lx := lr DIV(lq+1
                                        );
                                  curv := curv+((lr-(lq-1)*lx)DIV 2);
                                END;
                            END{:636};
                          WHILE curv+leaderht<=edge DO{637:}
                            BEGIN
                              curh := leftedge+mem[leaderbox+4].
                                      int;
                              IF curh<>dvih THEN
                                BEGIN
                                  movement(curh-dvih,143);
                                  dvih := curh;
                                END;
                              saveh := dvih;
                              curv := curv+mem[leaderbox+3].int;
                              IF curv<>dviv THEN
                                BEGIN
                                  movement(curv-dviv,157);
                                  dviv := curv;
                                END;
                              savev := dviv;
                              tempptr := leaderbox;
                              outerdoingleaders := doingleaders;
                              doingleaders := true;
                              IF mem[leaderbox].hh.b0=1 THEN vlistout
                              ELSE hlistout;
                              doingleaders := outerdoingleaders;
                              dviv := savev;
                              dvih := saveh;
                              curh := leftedge;
                              curv := savev-mem[leaderbox+3].int+leaderht+lx;
                            END{:637};
                          curv := edge-10;
                          goto 15;
                        END;
                    END{:635};
                  goto 13;
                END{:634};
            11: curv := curv+mem[p+1].int;
            ELSE
          END;
          goto 15;
          14:{633:}IF (rulewd=-1073741824)THEN rulewd := mem[thisbox+1].int;
          ruleht := ruleht+ruledp;
          curv := curv+ruleht;
          IF (ruleht>0)AND(rulewd>0)THEN
            BEGIN
              IF curh<>dvih THEN
                BEGIN
                  movement(
                           curh-dvih,143);
                  dvih := curh;
                END;
              IF curv<>dviv THEN
                BEGIN
                  movement(curv-dviv,157);
                  dviv := curv;
                END;
              BEGIN
                dvibuf[dviptr] := 137;
                dviptr := dviptr+1;
                IF dviptr=dvilimit THEN dviswap;
              END;
              dvifour(ruleht);
              dvifour(rulewd);
            END;
          goto 15{:633};
          13: curv := curv+ruleht;
        END{:631};
      15: p := mem[p].hh.rh;
    END{:630};
  prunemovements(saveloc);
  IF curs>0 THEN dvipop(saveloc);
  curs := curs-1;
END;{:629}{638:}
PROCEDURE shipout(p:halfword);

LABEL 30;

VAR pageloc: integer;
  j,k: 0..9;
  s: poolpointer;
  oldsetting: 0..21;
BEGIN
  IF eqtb[5297].int>0 THEN
    BEGIN
      printnl(338);
      println;
      print(830);
    END;
  IF termoffset>maxprintline-9 THEN println
  ELSE IF (termoffset>0)OR(
          fileoffset>0)THEN printchar(32);
  printchar(91);
  j := 9;
  WHILE (eqtb[5318+j].int=0)AND(j>0) DO
    j := j-1;
  FOR k:=0 TO j DO
    BEGIN
      printint(eqtb[5318+k].int);
      IF k<j THEN printchar(46);
    END;
  flush(output);
  IF eqtb[5297].int>0 THEN
    BEGIN
      printchar(93);
      begindiagnostic;
      showbox(p);
      enddiagnostic(true);
    END;
{640:}{641:}
  IF (mem[p+3].int>1073741823)OR(mem[p+2].int>1073741823)OR(mem
     [p+3].int+mem[p+2].int+eqtb[5849].int>1073741823)OR(mem[p+1].int+eqtb[
     5848].int>1073741823)THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(834);
      END;
      BEGIN
        helpptr := 2;
        helpline[1] := 835;
        helpline[0] := 836;
      END;
      error;
      IF eqtb[5297].int<=0 THEN
        BEGIN
          begindiagnostic;
          printnl(837);
          showbox(p);
          enddiagnostic(true);
        END;
      goto 30;
    END;
  IF mem[p+3].int+mem[p+2].int+eqtb[5849].int>maxv THEN maxv := mem[p+3].int
                                                                +mem[p+2].int+eqtb[5849].int;
  IF mem[p+1].int+eqtb[5848].int>maxh THEN maxh := mem[p+1].int+eqtb[5848].
                                                   int{:641};{617:}
  dvih := 0;
  dviv := 0;
  curh := eqtb[5848].int;
  dvif := 0;
  IF outputfilename=0 THEN
    BEGIN
      IF jobname=0 THEN openlogfile;
      packjobname(795);
      WHILE NOT bopenout(dvifile) DO
        promptfilename(796,795);
      outputfilename := bmakenamestring(dvifile);
    END;
  IF totalpages=0 THEN
    BEGIN
      BEGIN
        dvibuf[dviptr] := 247;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      BEGIN
        dvibuf[dviptr] := 2;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      dvifour(25400000);
      dvifour(473628672);
      preparemag;
      dvifour(eqtb[5280].int);
      oldsetting := selector;
      selector := 21;
      print(828);
      printint(eqtb[5286].int);
      printchar(46);
      printtwo(eqtb[5285].int);
      printchar(46);
      printtwo(eqtb[5284].int);
      printchar(58);
      printtwo(eqtb[5283].int DIV 60);
      printtwo(eqtb[5283].int MOD 60);
      selector := oldsetting;
      BEGIN
        dvibuf[dviptr] := (poolptr-strstart[strptr]);
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      FOR s:=strstart[strptr]TO poolptr-1 DO
        BEGIN
          dvibuf[dviptr] := strpool[s];
          dviptr := dviptr+1;
          IF dviptr=dvilimit THEN dviswap;
        END;
      poolptr := strstart[strptr];
    END{:617};
  pageloc := dvioffset+dviptr;
  BEGIN
    dvibuf[dviptr] := 139;
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
  FOR k:=0 TO 9 DO
    dvifour(eqtb[5318+k].int);
  dvifour(lastbop);
  lastbop := pageloc;
  curv := mem[p+3].int+eqtb[5849].int;
  tempptr := p;
  IF mem[p].hh.b0=1 THEN vlistout
  ELSE hlistout;
  BEGIN
    dvibuf[dviptr] := 140;
    dviptr := dviptr+1;
    IF dviptr=dvilimit THEN dviswap;
  END;
  totalpages := totalpages+1;
  curs := -1;
  30:{:640};
  IF eqtb[5297].int<=0 THEN printchar(93);
  deadcycles := 0;
  flush(output);
{639:}
  IF eqtb[5294].int>1 THEN
    BEGIN
      printnl(831);
      printint(varused);
      printchar(38);
      printint(dynused);
      printchar(59);
    END;
  flushnodelist(p);
  IF eqtb[5294].int>1 THEN
    BEGIN
      print(832);
      printint(varused);
      printchar(38);
      printint(dynused);
      print(833);
      printint(himemmin-lomemmax-1);
      println;
    END;{:639};
END;
{:638}{645:}
PROCEDURE scanspec(c:groupcode;threecodes:boolean);

LABEL 40;

VAR s: integer;
  speccode: 0..1;
BEGIN
  IF threecodes THEN s := savestack[saveptr+0].int;
  IF scankeyword(843)THEN speccode := 0
  ELSE IF scankeyword(844)THEN
         speccode := 1
  ELSE
    BEGIN
      speccode := 1;
      curval := 0;
      goto 40;
    END;
  scandimen(false,false,false);
  40: IF threecodes THEN
        BEGIN
          savestack[saveptr+0].int := s;
          saveptr := saveptr+1;
        END;
  savestack[saveptr+0].int := speccode;
  savestack[saveptr+1].int := curval;
  saveptr := saveptr+2;
  newsavelevel(c);
  scanleftbrace;
END;{:645}{649:}
FUNCTION hpack(p:halfword;w:scaled;
               m:smallnumber): halfword;

LABEL 21,50,10;

VAR r: halfword;
  q: halfword;
  h,d,x: scaled;
  s: scaled;
  g: halfword;
  o: glueord;
  f: internalfontnumber;
  i: fourquarters;
  hd: eightbits;
BEGIN
  lastbadness := 0;
  r := getnode(7);
  mem[r].hh.b0 := 0;
  mem[r].hh.b1 := 0;
  mem[r+4].int := 0;
  q := r+5;
  mem[q].hh.rh := p;
  h := 0;{650:}
  d := 0;
  x := 0;
  totalstretch[0] := 0;
  totalshrink[0] := 0;
  totalstretch[1] := 0;
  totalshrink[1] := 0;
  totalstretch[2] := 0;
  totalshrink[2] := 0;
  totalstretch[3] := 0;
  totalshrink[3] := 0{:650};
  WHILE p<>0 DO{651:}
    BEGIN
      21: WHILE (p>=himemmin) DO{654:}
            BEGIN
              f := mem[p].hh
                   .b0;
              i := fontinfo[charbase[f]+mem[p].hh.b1].qqqq;
              hd := i.b1;
              x := x+fontinfo[widthbase[f]+i.b0].int;
              s := fontinfo[heightbase[f]+(hd)DIV 16].int;
              IF s>h THEN h := s;
              s := fontinfo[depthbase[f]+(hd)MOD 16].int;
              IF s>d THEN d := s;
              p := mem[p].hh.rh;
            END{:654};
      IF p<>0 THEN
        BEGIN
          CASE mem[p].hh.b0 OF 
            0,1,2,13:{653:}
                      BEGIN
                        x := x+mem[p
                             +1].int;
                        IF mem[p].hh.b0>=2 THEN s := 0
                        ELSE s := mem[p+4].int;
                        IF mem[p+3].int-s>h THEN h := mem[p+3].int-s;
                        IF mem[p+2].int+s>d THEN d := mem[p+2].int+s;
                      END{:653};
            3,4,5: IF adjusttail<>0 THEN{655:}
                     BEGIN
                       WHILE mem[q].hh.rh<>p DO
                         q := mem[q
                              ].hh.rh;
                       IF mem[p].hh.b0=5 THEN
                         BEGIN
                           mem[adjusttail].hh.rh := mem[p+1].int;
                           WHILE mem[adjusttail].hh.rh<>0 DO
                             adjusttail := mem[adjusttail].hh.rh;
                           p := mem[p].hh.rh;
                           freenode(mem[q].hh.rh,2);
                         END
                       ELSE
                         BEGIN
                           mem[adjusttail].hh.rh := p;
                           adjusttail := p;
                           p := mem[p].hh.rh;
                         END;
                       mem[q].hh.rh := p;
                       p := q;
                     END{:655};
            8:{1360:}{:1360};
            10:{656:}
                BEGIN
                  g := mem[p+1].hh.lh;
                  x := x+mem[g+1].int;
                  o := mem[g].hh.b0;
                  totalstretch[o] := totalstretch[o]+mem[g+2].int;
                  o := mem[g].hh.b1;
                  totalshrink[o] := totalshrink[o]+mem[g+3].int;
                  IF mem[p].hh.b1>=100 THEN
                    BEGIN
                      g := mem[p+1].hh.rh;
                      IF mem[g+3].int>h THEN h := mem[g+3].int;
                      IF mem[g+2].int>d THEN d := mem[g+2].int;
                    END;
                END{:656};
            11,9: x := x+mem[p+1].int;
            6:{652:}
               BEGIN
                 mem[29988] := mem[p+1];
                 mem[29988].hh.rh := mem[p].hh.rh;
                 p := 29988;
                 goto 21;
               END{:652};
            ELSE
          END;
          p := mem[p].hh.rh;
        END;
    END{:651};
  IF adjusttail<>0 THEN mem[adjusttail].hh.rh := 0;
  mem[r+3].int := h;
  mem[r+2].int := d;{657:}
  IF m=1 THEN w := x+w;
  mem[r+1].int := w;
  x := w-x;
  IF x=0 THEN
    BEGIN
      mem[r+5].hh.b0 := 0;
      mem[r+5].hh.b1 := 0;
      mem[r+6].gr := 0.0;
      goto 10;
    END
  ELSE IF x>0 THEN{658:}
         BEGIN{659:}
           IF totalstretch[3]<>0 THEN o := 3
           ELSE IF totalstretch[2]<>0 THEN o := 2
           ELSE IF totalstretch[1]<>0 THEN o := 
                                                1
           ELSE o := 0{:659};
           mem[r+5].hh.b1 := o;
           mem[r+5].hh.b0 := 1;
           IF totalstretch[o]<>0 THEN mem[r+6].gr := x/totalstretch[o]
           ELSE
             BEGIN
               mem[
               r+5].hh.b0 := 0;
               mem[r+6].gr := 0.0;
             END;
           IF o=0 THEN IF mem[r+5].hh.rh<>0 THEN{660:}
                         BEGIN
                           lastbadness := badness(x,
                                          totalstretch[0]);
                           IF lastbadness>eqtb[5289].int THEN
                             BEGIN
                               println;
                               IF lastbadness>100 THEN printnl(845)
                               ELSE printnl(846);
                               print(847);
                               printint(lastbadness);
                               goto 50;
                             END;
                         END{:660};
           goto 10;
         END{:658}
  ELSE{664:}
    BEGIN{665:}
      IF totalshrink[3]<>0 THEN o := 3
      ELSE IF 
              totalshrink[2]<>0 THEN o := 2
      ELSE IF totalshrink[1]<>0 THEN o := 1
      ELSE o := 
                0{:665};
      mem[r+5].hh.b1 := o;
      mem[r+5].hh.b0 := 2;
      IF totalshrink[o]<>0 THEN mem[r+6].gr := (-x)/totalshrink[o]
      ELSE
        BEGIN
          mem
          [r+5].hh.b0 := 0;
          mem[r+6].gr := 0.0;
        END;
      IF (totalshrink[o]<-x)AND(o=0)AND(mem[r+5].hh.rh<>0)THEN
        BEGIN
          lastbadness := 1000000;
          mem[r+6].gr := 1.0;
{666:}
          IF (-x-totalshrink[0]>eqtb[5838].int)OR(eqtb[5289].int<100)THEN
            BEGIN
              IF (eqtb[5846].int>0)AND(-x-totalshrink[0]>eqtb[5838].int)THEN
                BEGIN
                  WHILE mem[q].hh.rh<>0 DO
                    q := mem[q].hh.rh;
                  mem[q].hh.rh := newrule;
                  mem[mem[q].hh.rh+1].int := eqtb[5846].int;
                END;
              println;
              printnl(853);
              printscaled(-x-totalshrink[0]);
              print(854);
              goto 50;
            END{:666};
        END
      ELSE IF o=0 THEN IF mem[r+5].hh.rh<>0 THEN{667:}
                         BEGIN
                           lastbadness := 
                                          badness(-x,totalshrink[0]);
                           IF lastbadness>eqtb[5289].int THEN
                             BEGIN
                               println;
                               printnl(855);
                               printint(lastbadness);
                               goto 50;
                             END;
                         END{:667};
      goto 10;
    END{:664}{:657};
  50:{663:}IF outputactive THEN print(848)
      ELSE
        BEGIN
          IF packbeginline<>0
            THEN
            BEGIN
              IF packbeginline>0 THEN print(849)
              ELSE print(850);
              printint(abs(packbeginline));
              print(851);
            END
          ELSE print(852);
          printint(line);
        END;
  println;
  fontinshortdisplay := 0;
  shortdisplay(mem[r+5].hh.rh);
  println;
  begindiagnostic;
  showbox(r);
  enddiagnostic(true){:663};
  10: hpack := r;
END;
{:649}{668:}
FUNCTION vpackage(p:halfword;h:scaled;m:smallnumber;
                  l:scaled): halfword;

LABEL 50,10;

VAR r: halfword;
  w,d,x: scaled;
  s: scaled;
  g: halfword;
  o: glueord;
BEGIN
  lastbadness := 0;
  r := getnode(7);
  mem[r].hh.b0 := 1;
  mem[r].hh.b1 := 0;
  mem[r+4].int := 0;
  mem[r+5].hh.rh := p;
  w := 0;{650:}
  d := 0;
  x := 0;
  totalstretch[0] := 0;
  totalshrink[0] := 0;
  totalstretch[1] := 0;
  totalshrink[1] := 0;
  totalstretch[2] := 0;
  totalshrink[2] := 0;
  totalstretch[3] := 0;
  totalshrink[3] := 0{:650};
  WHILE p<>0 DO{669:}
    BEGIN
      IF (p>=himemmin)THEN confusion(856)
      ELSE CASE mem
                [p].hh.b0 OF 
             0,1,2,13:{670:}
                       BEGIN
                         x := x+d+mem[p+3].int;
                         d := mem[p+2].int;
                         IF mem[p].hh.b0>=2 THEN s := 0
                         ELSE s := mem[p+4].int;
                         IF mem[p+1].int+s>w THEN w := mem[p+1].int+s;
                       END{:670};
             8:{1359:}{:1359};
             10:{671:}
                 BEGIN
                   x := x+d;
                   d := 0;
                   g := mem[p+1].hh.lh;
                   x := x+mem[g+1].int;
                   o := mem[g].hh.b0;
                   totalstretch[o] := totalstretch[o]+mem[g+2].int;
                   o := mem[g].hh.b1;
                   totalshrink[o] := totalshrink[o]+mem[g+3].int;
                   IF mem[p].hh.b1>=100 THEN
                     BEGIN
                       g := mem[p+1].hh.rh;
                       IF mem[g+1].int>w THEN w := mem[g+1].int;
                     END;
                 END{:671};
             11:
                 BEGIN
                   x := x+d+mem[p+1].int;
                   d := 0;
                 END;
             ELSE
        END;
      p := mem[p].hh.rh;
    END{:669};
  mem[r+1].int := w;
  IF d>l THEN
    BEGIN
      x := x+d-l;
      mem[r+2].int := l;
    END
  ELSE mem[r+2].int := d;{672:}
  IF m=1 THEN h := x+h;
  mem[r+3].int := h;
  x := h-x;
  IF x=0 THEN
    BEGIN
      mem[r+5].hh.b0 := 0;
      mem[r+5].hh.b1 := 0;
      mem[r+6].gr := 0.0;
      goto 10;
    END
  ELSE IF x>0 THEN{673:}
         BEGIN{659:}
           IF totalstretch[3]<>0 THEN o := 3
           ELSE IF totalstretch[2]<>0 THEN o := 2
           ELSE IF totalstretch[1]<>0 THEN o := 
                                                1
           ELSE o := 0{:659};
           mem[r+5].hh.b1 := o;
           mem[r+5].hh.b0 := 1;
           IF totalstretch[o]<>0 THEN mem[r+6].gr := x/totalstretch[o]
           ELSE
             BEGIN
               mem[
               r+5].hh.b0 := 0;
               mem[r+6].gr := 0.0;
             END;
           IF o=0 THEN IF mem[r+5].hh.rh<>0 THEN{674:}
                         BEGIN
                           lastbadness := badness(x,
                                          totalstretch[0]);
                           IF lastbadness>eqtb[5290].int THEN
                             BEGIN
                               println;
                               IF lastbadness>100 THEN printnl(845)
                               ELSE printnl(846);
                               print(857);
                               printint(lastbadness);
                               goto 50;
                             END;
                         END{:674};
           goto 10;
         END{:673}
  ELSE{676:}
    BEGIN{665:}
      IF totalshrink[3]<>0 THEN o := 3
      ELSE IF 
              totalshrink[2]<>0 THEN o := 2
      ELSE IF totalshrink[1]<>0 THEN o := 1
      ELSE o := 
                0{:665};
      mem[r+5].hh.b1 := o;
      mem[r+5].hh.b0 := 2;
      IF totalshrink[o]<>0 THEN mem[r+6].gr := (-x)/totalshrink[o]
      ELSE
        BEGIN
          mem
          [r+5].hh.b0 := 0;
          mem[r+6].gr := 0.0;
        END;
      IF (totalshrink[o]<-x)AND(o=0)AND(mem[r+5].hh.rh<>0)THEN
        BEGIN
          lastbadness := 1000000;
          mem[r+6].gr := 1.0;
{677:}
          IF (-x-totalshrink[0]>eqtb[5839].int)OR(eqtb[5290].int<100)THEN
            BEGIN
              println;
              printnl(858);
              printscaled(-x-totalshrink[0]);
              print(859);
              goto 50;
            END{:677};
        END
      ELSE IF o=0 THEN IF mem[r+5].hh.rh<>0 THEN{678:}
                         BEGIN
                           lastbadness := 
                                          badness(-x,totalshrink[0]);
                           IF lastbadness>eqtb[5290].int THEN
                             BEGIN
                               println;
                               printnl(860);
                               printint(lastbadness);
                               goto 50;
                             END;
                         END{:678};
      goto 10;
    END{:676}{:672};
  50:{675:}IF outputactive THEN print(848)
      ELSE
        BEGIN
          IF packbeginline<>0
            THEN
            BEGIN
              print(850);
              printint(abs(packbeginline));
              print(851);
            END
          ELSE print(852);
          printint(line);
          println;
        END;
  begindiagnostic;
  showbox(r);
  enddiagnostic(true){:675};
  10: vpackage := r;
END;
{:668}{679:}
PROCEDURE appendtovlist(b:halfword);

VAR d: scaled;
  p: halfword;
BEGIN
  IF curlist.auxfield.int>-65536000 THEN
    BEGIN
      d := mem[eqtb[2883].hh.
           rh+1].int-curlist.auxfield.int-mem[b+3].int;
      IF d<eqtb[5832].int THEN p := newparamglue(0)
      ELSE
        BEGIN
          p := newskipparam(1)
          ;
          mem[tempptr+1].int := d;
        END;
      mem[curlist.tailfield].hh.rh := p;
      curlist.tailfield := p;
    END;
  mem[curlist.tailfield].hh.rh := b;
  curlist.tailfield := b;
  curlist.auxfield.int := mem[b+2].int;
END;
{:679}{686:}
FUNCTION newnoad: halfword;

VAR p: halfword;
BEGIN
  p := getnode(4);
  mem[p].hh.b0 := 16;
  mem[p].hh.b1 := 0;
  mem[p+1].hh := emptyfield;
  mem[p+3].hh := emptyfield;
  mem[p+2].hh := emptyfield;
  newnoad := p;
END;{:686}{688:}
FUNCTION newstyle(s:smallnumber): halfword;

VAR p: halfword;
BEGIN
  p := getnode(3);
  mem[p].hh.b0 := 14;
  mem[p].hh.b1 := s;
  mem[p+1].int := 0;
  mem[p+2].int := 0;
  newstyle := p;
END;
{:688}{689:}
FUNCTION newchoice: halfword;

VAR p: halfword;
BEGIN
  p := getnode(3);
  mem[p].hh.b0 := 15;
  mem[p].hh.b1 := 0;
  mem[p+1].hh.lh := 0;
  mem[p+1].hh.rh := 0;
  mem[p+2].hh.lh := 0;
  mem[p+2].hh.rh := 0;
  newchoice := p;
END;
{:689}{693:}
PROCEDURE showinfo;
BEGIN
  shownodelist(mem[tempptr].hh.lh);
END;{:693}{704:}
FUNCTION fractionrule(t:scaled): halfword;

VAR p: halfword;
BEGIN
  p := newrule;
  mem[p+3].int := t;
  mem[p+2].int := 0;
  fractionrule := p;
END;
{:704}{705:}
FUNCTION overbar(b:halfword;k,t:scaled): halfword;

VAR p,q: halfword;
BEGIN
  p := newkern(k);
  mem[p].hh.rh := b;
  q := fractionrule(t);
  mem[q].hh.rh := p;
  p := newkern(t);
  mem[p].hh.rh := q;
  overbar := vpackage(p,0,1,1073741823);
END;
{:705}{706:}{709:}
FUNCTION charbox(f:internalfontnumber;
                 c:quarterword): halfword;

VAR q: fourquarters;
  hd: eightbits;
  b,p: halfword;
BEGIN
  q := fontinfo[charbase[f]+c].qqqq;
  hd := q.b1;
  b := newnullbox;
  mem[b+1].int := fontinfo[widthbase[f]+q.b0].int+fontinfo[italicbase[f]+(q.
                  b2)DIV 4].int;
  mem[b+3].int := fontinfo[heightbase[f]+(hd)DIV 16].int;
  mem[b+2].int := fontinfo[depthbase[f]+(hd)MOD 16].int;
  p := getavail;
  mem[p].hh.b1 := c;
  mem[p].hh.b0 := f;
  mem[b+5].hh.rh := p;
  charbox := b;
END;
{:709}{711:}
PROCEDURE stackintobox(b:halfword;f:internalfontnumber;
                       c:quarterword);

VAR p: halfword;
BEGIN
  p := charbox(f,c);
  mem[p].hh.rh := mem[b+5].hh.rh;
  mem[b+5].hh.rh := p;
  mem[b+3].int := mem[p+3].int;
END;
{:711}{712:}
FUNCTION heightplusdepth(f:internalfontnumber;
                         c:quarterword): scaled;

VAR q: fourquarters;
  hd: eightbits;
BEGIN
  q := fontinfo[charbase[f]+c].qqqq;
  hd := q.b1;
  heightplusdepth := fontinfo[heightbase[f]+(hd)DIV 16].int+fontinfo[
                     depthbase[f]+(hd)MOD 16].int;
END;{:712}
FUNCTION vardelimiter(d:halfword;
                      s:smallnumber;v:scaled): halfword;

LABEL 40,22;

VAR b: halfword;
  f,g: internalfontnumber;
  c,x,y: quarterword;
  m,n: integer;
  u: scaled;
  w: scaled;
  q: fourquarters;
  hd: eightbits;
  r: fourquarters;
  z: smallnumber;
  largeattempt: boolean;
BEGIN
  f := 0;
  w := 0;
  largeattempt := false;
  z := mem[d].qqqq.b0;
  x := mem[d].qqqq.b1;
  WHILE true DO
    BEGIN{707:}
      IF (z<>0)OR(x<>0)THEN
        BEGIN
          z := z+s+16;
          REPEAT
            z := z-16;
            g := eqtb[3935+z].hh.rh;
            IF g<>0 THEN{708:}
              BEGIN
                y := x;
                IF (y>=fontbc[g])AND(y<=fontec[g])THEN
                  BEGIN
                    22: q := fontinfo[charbase[g]+y
                             ].qqqq;
                    IF (q.b0>0)THEN
                      BEGIN
                        IF ((q.b2)MOD 4)=3 THEN
                          BEGIN
                            f := g;
                            c := y;
                            goto 40;
                          END;
                        hd := q.b1;
                        u := fontinfo[heightbase[g]+(hd)DIV 16].int+fontinfo[depthbase[g]+(hd)MOD
                             16].int;
                        IF u>w THEN
                          BEGIN
                            f := g;
                            c := y;
                            w := u;
                            IF u>=v THEN goto 40;
                          END;
                        IF ((q.b2)MOD 4)=2 THEN
                          BEGIN
                            y := q.b3;
                            goto 22;
                          END;
                      END;
                  END;
              END{:708};
          UNTIL z<16;
        END{:707};
      IF largeattempt THEN goto 40;
      largeattempt := true;
      z := mem[d].qqqq.b2;
      x := mem[d].qqqq.b3;
    END;
  40: IF f<>0 THEN{710:}IF ((q.b2)MOD 4)=3 THEN{713:}
                          BEGIN
                            b := newnullbox;
                            mem[b].hh.b0 := 1;
                            r := fontinfo[extenbase[f]+q.b3].qqqq;{714:}
                            c := r.b3;
                            u := heightplusdepth(f,c);
                            w := 0;
                            q := fontinfo[charbase[f]+c].qqqq;
                            mem[b+1].int := fontinfo[widthbase[f]+q.b0].int+fontinfo[italicbase[f]+(
                                            q.
                                            b2)DIV 4].int;
                            c := r.b2;
                            IF c<>0 THEN w := w+heightplusdepth(f,c);
                            c := r.b1;
                            IF c<>0 THEN w := w+heightplusdepth(f,c);
                            c := r.b0;
                            IF c<>0 THEN w := w+heightplusdepth(f,c);
                            n := 0;
                            IF u>0 THEN WHILE w<v DO
                                          BEGIN
                                            w := w+u;
                                            n := n+1;
                                            IF r.b1<>0 THEN w := w+u;
                                          END{:714};
                            c := r.b2;
                            IF c<>0 THEN stackintobox(b,f,c);
                            c := r.b3;
                            FOR m:=1 TO n DO
                              stackintobox(b,f,c);
                            c := r.b1;
                            IF c<>0 THEN
                              BEGIN
                                stackintobox(b,f,c);
                                c := r.b3;
                                FOR m:=1 TO n DO
                                  stackintobox(b,f,c);
                              END;
                            c := r.b0;
                            IF c<>0 THEN stackintobox(b,f,c);
                            mem[b+2].int := w-mem[b+3].int;
                          END{:713}
      ELSE b := charbox(f,c){:710}
      ELSE
        BEGIN
          b := newnullbox;
          mem[b+1].int := eqtb[5841].int;
        END;
  mem[b+4].int := half(mem[b+3].int-mem[b+2].int)-fontinfo[22+parambase[eqtb
                  [3937+s].hh.rh]].int;
  vardelimiter := b;
END;
{:706}{715:}
FUNCTION rebox(b:halfword;w:scaled): halfword;

VAR p: halfword;
  f: internalfontnumber;
  v: scaled;
BEGIN
  IF (mem[b+1].int<>w)AND(mem[b+5].hh.rh<>0)THEN
    BEGIN
      IF mem[b].hh.
         b0=1 THEN b := hpack(b,0,1);
      p := mem[b+5].hh.rh;
      IF ((p>=himemmin))AND(mem[p].hh.rh=0)THEN
        BEGIN
          f := mem[p].hh.b0;
          v := fontinfo[widthbase[f]+fontinfo[charbase[f]+mem[p].hh.b1].qqqq.b0].int
          ;
          IF v<>mem[b+1].int THEN mem[p].hh.rh := newkern(mem[b+1].int-v);
        END;
      freenode(b,7);
      b := newglue(12);
      mem[b].hh.rh := p;
      WHILE mem[p].hh.rh<>0 DO
        p := mem[p].hh.rh;
      mem[p].hh.rh := newglue(12);
      rebox := hpack(b,w,0);
    END
  ELSE
    BEGIN
      mem[b+1].int := w;
      rebox := b;
    END;
END;
{:715}{716:}
FUNCTION mathglue(g:halfword;m:scaled): halfword;

VAR p: halfword;
  n: integer;
  f: scaled;
BEGIN
  n := xovern(m,65536);
  f := remainder;
  IF f<0 THEN
    BEGIN
      n := n-1;
      f := f+65536;
    END;
  p := getnode(4);
  mem[p+1].int := multandadd(n,mem[g+1].int,xnoverd(mem[g+1].int,f,65536),
                  1073741823);
  mem[p].hh.b0 := mem[g].hh.b0;
  IF mem[p].hh.b0=0 THEN mem[p+2].int := multandadd(n,mem[g+2].int,xnoverd(
                                         mem[g+2].int,f,65536),1073741823)
  ELSE mem[p+2].int := mem[g+2].int;
  mem[p].hh.b1 := mem[g].hh.b1;
  IF mem[p].hh.b1=0 THEN mem[p+3].int := multandadd(n,mem[g+3].int,xnoverd(
                                         mem[g+3].int,f,65536),1073741823)
  ELSE mem[p+3].int := mem[g+3].int;
  mathglue := p;
END;{:716}{717:}
PROCEDURE mathkern(p:halfword;m:scaled);

VAR n: integer;
  f: scaled;
BEGIN
  IF mem[p].hh.b1=99 THEN
    BEGIN
      n := xovern(m,65536);
      f := remainder;
      IF f<0 THEN
        BEGIN
          n := n-1;
          f := f+65536;
        END;
      mem[p+1].int := multandadd(n,mem[p+1].int,xnoverd(mem[p+1].int,f,65536),
                      1073741823);
      mem[p].hh.b1 := 1;
    END;
END;{:717}{718:}
PROCEDURE flushmath;
BEGIN
  flushnodelist(mem[curlist.headfield].hh.rh);
  flushnodelist(curlist.auxfield.int);
  mem[curlist.headfield].hh.rh := 0;
  curlist.tailfield := curlist.headfield;
  curlist.auxfield.int := 0;
END;
{:718}{720:}
PROCEDURE mlisttohlist;
forward;
FUNCTION cleanbox(p:halfword;
                  s:smallnumber): halfword;

LABEL 40;

VAR q: halfword;
  savestyle: smallnumber;
  x: halfword;
  r: halfword;
BEGIN
  CASE mem[p].hh.rh OF 
    1:
       BEGIN
         curmlist := newnoad;
         mem[curmlist+1] := mem[p];
       END;
    2:
       BEGIN
         q := mem[p].hh.lh;
         goto 40;
       END;
    3: curmlist := mem[p].hh.lh;
    ELSE
      BEGIN
        q := newnullbox;
        goto 40;
      END
  END;
  savestyle := curstyle;
  curstyle := s;
  mlistpenalties := false;
  mlisttohlist;
  q := mem[29997].hh.rh;
  curstyle := savestyle;
{703:}
  BEGIN
    IF curstyle<4 THEN cursize := 0
    ELSE cursize := 16*((curstyle-2)
                    DIV 2);
    curmu := xovern(fontinfo[6+parambase[eqtb[3937+cursize].hh.rh]].int,18);
  END{:703};
  40: IF (q>=himemmin)OR(q=0)THEN x := hpack(q,0,1)
      ELSE IF (mem[q].hh.rh=0)AND(
              mem[q].hh.b0<=1)AND(mem[q+4].int=0)THEN x := q
      ELSE x := hpack(q,0,1);
{721:}
  q := mem[x+5].hh.rh;
  IF (q>=himemmin)THEN
    BEGIN
      r := mem[q].hh.rh;
      IF r<>0 THEN IF mem[r].hh.rh=0 THEN IF NOT(r>=himemmin)THEN IF mem[r].hh
                                                                     .b0=11 THEN
                                                                    BEGIN
                                                                      freenode(r,2);
                                                                      mem[q].hh.rh := 0;
                                                                    END;
    END{:721};
  cleanbox := x;
END;{:720}{722:}
PROCEDURE fetch(a:halfword);
BEGIN
  curc := mem[a].hh.b1;
  curf := eqtb[3935+mem[a].hh.b0+cursize].hh.rh;
  IF curf=0 THEN{723:}
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(338);
      END;
      printsize(cursize);
      printchar(32);
      printint(mem[a].hh.b0);
      print(885);
      print(curc);
      printchar(41);
      BEGIN
        helpptr := 4;
        helpline[3] := 886;
        helpline[2] := 887;
        helpline[1] := 888;
        helpline[0] := 889;
      END;
      error;
      curi := nullcharacter;
      mem[a].hh.rh := 0;
    END{:723}
  ELSE
    BEGIN
      IF (curc>=fontbc[curf])AND(curc<=fontec[curf])THEN
        curi := fontinfo[charbase[curf]+curc].qqqq
      ELSE curi := nullcharacter;
      IF NOT((curi.b0>0))THEN
        BEGIN
          charwarning(curf,curc);
          mem[a].hh.rh := 0;
          curi := nullcharacter;
        END;
    END;
END;
{:722}{726:}{734:}
PROCEDURE makeover(q:halfword);
BEGIN
  mem[q+1].hh.lh := overbar(cleanbox(q+1,2*(curstyle DIV 2)+1),3*
                    fontinfo[8+parambase[eqtb[3938+cursize].hh.rh]].int,fontinfo[8+parambase
                    [eqtb[3938+cursize].hh.rh]].int);
  mem[q+1].hh.rh := 2;
END;
{:734}{735:}
PROCEDURE makeunder(q:halfword);

VAR p,x,y: halfword;
  delta: scaled;
BEGIN
  x := cleanbox(q+1,curstyle);
  p := newkern(3*fontinfo[8+parambase[eqtb[3938+cursize].hh.rh]].int);
  mem[x].hh.rh := p;
  mem[p].hh.rh := fractionrule(fontinfo[8+parambase[eqtb[3938+cursize].hh.rh
                  ]].int);
  y := vpackage(x,0,1,1073741823);
  delta := mem[y+3].int+mem[y+2].int+fontinfo[8+parambase[eqtb[3938+cursize]
           .hh.rh]].int;
  mem[y+3].int := mem[x+3].int;
  mem[y+2].int := delta-mem[y+3].int;
  mem[q+1].hh.lh := y;
  mem[q+1].hh.rh := 2;
END;{:735}{736:}
PROCEDURE makevcenter(q:halfword);

VAR v: halfword;
  delta: scaled;
BEGIN
  v := mem[q+1].hh.lh;
  IF mem[v].hh.b0<>1 THEN confusion(539);
  delta := mem[v+3].int+mem[v+2].int;
  mem[v+3].int := fontinfo[22+parambase[eqtb[3937+cursize].hh.rh]].int+half(
                  delta);
  mem[v+2].int := delta-mem[v+3].int;
END;
{:736}{737:}
PROCEDURE makeradical(q:halfword);

VAR x,y: halfword;
  delta,clr: scaled;
BEGIN
  x := cleanbox(q+1,2*(curstyle DIV 2)+1);
  IF curstyle<2 THEN clr := fontinfo[8+parambase[eqtb[3938+cursize].hh.rh]].
                            int+(abs(fontinfo[5+parambase[eqtb[3937+cursize].hh.rh]].int)DIV 4)
  ELSE
    BEGIN
      clr := fontinfo[8+parambase[eqtb[3938+cursize].hh.rh]].int;
      clr := clr+(abs(clr)DIV 4);
    END;
  y := vardelimiter(q+4,cursize,mem[x+3].int+mem[x+2].int+clr+fontinfo[8+
       parambase[eqtb[3938+cursize].hh.rh]].int);
  delta := mem[y+2].int-(mem[x+3].int+mem[x+2].int+clr);
  IF delta>0 THEN clr := clr+half(delta);
  mem[y+4].int := -(mem[x+3].int+clr);
  mem[y].hh.rh := overbar(x,clr,mem[y+3].int);
  mem[q+1].hh.lh := hpack(y,0,1);
  mem[q+1].hh.rh := 2;
END;{:737}{738:}
PROCEDURE makemathaccent(q:halfword);

LABEL 30,31;

VAR p,x,y: halfword;
  a: integer;
  c: quarterword;
  f: internalfontnumber;
  i: fourquarters;
  s: scaled;
  h: scaled;
  delta: scaled;
  w: scaled;
BEGIN
  fetch(q+4);
  IF (curi.b0>0)THEN
    BEGIN
      i := curi;
      c := curc;
      f := curf;{741:}
      s := 0;
      IF mem[q+1].hh.rh=1 THEN
        BEGIN
          fetch(q+1);
          IF ((curi.b2)MOD 4)=1 THEN
            BEGIN
              a := ligkernbase[curf]+curi.b3;
              curi := fontinfo[a].qqqq;
              IF curi.b0>128 THEN
                BEGIN
                  a := ligkernbase[curf]+256*curi.b2+curi.b3
                       +32768-256*(128);
                  curi := fontinfo[a].qqqq;
                END;
              WHILE true DO
                BEGIN
                  IF curi.b1=skewchar[curf]THEN
                    BEGIN
                      IF curi.b2>=128
                        THEN IF curi.b0<=128 THEN s := fontinfo[kernbase[curf]+256*curi.b2+curi.b3
                                                       ].int;
                      goto 31;
                    END;
                  IF curi.b0>=128 THEN goto 31;
                  a := a+curi.b0+1;
                  curi := fontinfo[a].qqqq;
                END;
            END;
        END;
      31:{:741};
      x := cleanbox(q+1,2*(curstyle DIV 2)+1);
      w := mem[x+1].int;
      h := mem[x+3].int;
{740:}
      WHILE true DO
        BEGIN
          IF ((i.b2)MOD 4)<>2 THEN goto 30;
          y := i.b3;
          i := fontinfo[charbase[f]+y].qqqq;
          IF NOT(i.b0>0)THEN goto 30;
          IF fontinfo[widthbase[f]+i.b0].int>w THEN goto 30;
          c := y;
        END;
      30:{:740};
      IF h<fontinfo[5+parambase[f]].int THEN delta := h
      ELSE delta := fontinfo[5+
                    parambase[f]].int;
      IF (mem[q+2].hh.rh<>0)OR(mem[q+3].hh.rh<>0)THEN IF mem[q+1].hh.rh=1 THEN
{742:}
                                                        BEGIN
                                                          flushnodelist(x);
                                                          x := newnoad;
                                                          mem[x+1] := mem[q+1];
                                                          mem[x+2] := mem[q+2];
                                                          mem[x+3] := mem[q+3];
                                                          mem[q+2].hh := emptyfield;
                                                          mem[q+3].hh := emptyfield;
                                                          mem[q+1].hh.rh := 3;
                                                          mem[q+1].hh.lh := x;
                                                          x := cleanbox(q+1,curstyle);
                                                          delta := delta+mem[x+3].int-h;
                                                          h := mem[x+3].int;
                                                        END{:742};
      y := charbox(f,c);
      mem[y+4].int := s+half(w-mem[y+1].int);
      mem[y+1].int := 0;
      p := newkern(-delta);
      mem[p].hh.rh := x;
      mem[y].hh.rh := p;
      y := vpackage(y,0,1,1073741823);
      mem[y+1].int := mem[x+1].int;
      IF mem[y+3].int<h THEN{739:}
        BEGIN
          p := newkern(h-mem[y+3].int);
          mem[p].hh.rh := mem[y+5].hh.rh;
          mem[y+5].hh.rh := p;
          mem[y+3].int := h;
        END{:739};
      mem[q+1].hh.lh := y;
      mem[q+1].hh.rh := 2;
    END;
END;
{:738}{743:}
PROCEDURE makefraction(q:halfword);

VAR p,v,x,y,z: halfword;
  delta,delta1,delta2,shiftup,shiftdown,clr: scaled;
BEGIN
  IF mem[q+1].int=1073741824 THEN mem[q+1].int := fontinfo[8+parambase
                                                  [eqtb[3938+cursize].hh.rh]].int;
{744:}
  x := cleanbox(q+2,curstyle+2-2*(curstyle DIV 6));
  z := cleanbox(q+3,2*(curstyle DIV 2)+3-2*(curstyle DIV 6));
  IF mem[x+1].int<mem[z+1].int THEN x := rebox(x,mem[z+1].int)
  ELSE z := rebox(
            z,mem[x+1].int);
  IF curstyle<2 THEN
    BEGIN
      shiftup := fontinfo[8+parambase[eqtb[3937+cursize
                 ].hh.rh]].int;
      shiftdown := fontinfo[11+parambase[eqtb[3937+cursize].hh.rh]].int;
    END
  ELSE
    BEGIN
      shiftdown := fontinfo[12+parambase[eqtb[3937+cursize].hh.rh
                   ]].int;
      IF mem[q+1].int<>0 THEN shiftup := fontinfo[9+parambase[eqtb[3937+cursize]
                                         .hh.rh]].int
      ELSE shiftup := fontinfo[10+parambase[eqtb[3937+cursize].hh.
                      rh]].int;
    END{:744};
  IF mem[q+1].int=0 THEN{745:}
    BEGIN
      IF curstyle<2 THEN clr := 7*fontinfo[8+
                                parambase[eqtb[3938+cursize].hh.rh]].int
      ELSE clr := 3*fontinfo[8+
                  parambase[eqtb[3938+cursize].hh.rh]].int;
      delta := half(clr-((shiftup-mem[x+2].int)-(mem[z+3].int-shiftdown)));
      IF delta>0 THEN
        BEGIN
          shiftup := shiftup+delta;
          shiftdown := shiftdown+delta;
        END;
    END{:745}
  ELSE{746:}
    BEGIN
      IF curstyle<2 THEN clr := 3*mem[q+1].int
      ELSE clr 
        := mem[q+1].int;
      delta := half(mem[q+1].int);
      delta1 := clr-((shiftup-mem[x+2].int)-(fontinfo[22+parambase[eqtb[3937+
                cursize].hh.rh]].int+delta));
      delta2 := clr-((fontinfo[22+parambase[eqtb[3937+cursize].hh.rh]].int-delta
                )-(mem[z+3].int-shiftdown));
      IF delta1>0 THEN shiftup := shiftup+delta1;
      IF delta2>0 THEN shiftdown := shiftdown+delta2;
    END{:746};
{747:}
  v := newnullbox;
  mem[v].hh.b0 := 1;
  mem[v+3].int := shiftup+mem[x+3].int;
  mem[v+2].int := mem[z+2].int+shiftdown;
  mem[v+1].int := mem[x+1].int;
  IF mem[q+1].int=0 THEN
    BEGIN
      p := newkern((shiftup-mem[x+2].int)-(mem[z+3]
           .int-shiftdown));
      mem[p].hh.rh := z;
    END
  ELSE
    BEGIN
      y := fractionrule(mem[q+1].int);
      p := newkern((fontinfo[22+parambase[eqtb[3937+cursize].hh.rh]].int-delta)-
           (mem[z+3].int-shiftdown));
      mem[y].hh.rh := p;
      mem[p].hh.rh := z;
      p := newkern((shiftup-mem[x+2].int)-(fontinfo[22+parambase[eqtb[3937+
           cursize].hh.rh]].int+delta));
      mem[p].hh.rh := y;
    END;
  mem[x].hh.rh := p;
  mem[v+5].hh.rh := x{:747};
{748:}
  IF curstyle<2 THEN delta := fontinfo[20+parambase[eqtb[3937+cursize]
                              .hh.rh]].int
  ELSE delta := fontinfo[21+parambase[eqtb[3937+cursize].hh.rh]
                ].int;
  x := vardelimiter(q+4,cursize,delta);
  mem[x].hh.rh := v;
  z := vardelimiter(q+5,cursize,delta);
  mem[v].hh.rh := z;
  mem[q+1].int := hpack(x,0,1){:748};
END;
{:743}{749:}
FUNCTION makeop(q:halfword): scaled;

VAR delta: scaled;
  p,v,x,y,z: halfword;
  c: quarterword;
  i: fourquarters;
  shiftup,shiftdown: scaled;
BEGIN
  IF (mem[q].hh.b1=0)AND(curstyle<2)THEN mem[q].hh.b1 := 1;
  IF mem[q+1].hh.rh=1 THEN
    BEGIN
      fetch(q+1);
      IF (curstyle<2)AND(((curi.b2)MOD 4)=2)THEN
        BEGIN
          c := curi.b3;
          i := fontinfo[charbase[curf]+c].qqqq;
          IF (i.b0>0)THEN
            BEGIN
              curc := c;
              curi := i;
              mem[q+1].hh.b1 := c;
            END;
        END;
      delta := fontinfo[italicbase[curf]+(curi.b2)DIV 4].int;
      x := cleanbox(q+1,curstyle);
      IF (mem[q+3].hh.rh<>0)AND(mem[q].hh.b1<>1)THEN mem[x+1].int := mem[x+1].int
                                                                     -delta;
      mem[x+4].int := half(mem[x+3].int-mem[x+2].int)-fontinfo[22+parambase[eqtb
                      [3937+cursize].hh.rh]].int;
      mem[q+1].hh.rh := 2;
      mem[q+1].hh.lh := x;
    END
  ELSE delta := 0;
  IF mem[q].hh.b1=1 THEN{750:}
    BEGIN
      x := cleanbox(q+2,2*(curstyle DIV 4)+4+(
           curstyle MOD 2));
      y := cleanbox(q+1,curstyle);
      z := cleanbox(q+3,2*(curstyle DIV 4)+5);
      v := newnullbox;
      mem[v].hh.b0 := 1;
      mem[v+1].int := mem[y+1].int;
      IF mem[x+1].int>mem[v+1].int THEN mem[v+1].int := mem[x+1].int;
      IF mem[z+1].int>mem[v+1].int THEN mem[v+1].int := mem[z+1].int;
      x := rebox(x,mem[v+1].int);
      y := rebox(y,mem[v+1].int);
      z := rebox(z,mem[v+1].int);
      mem[x+4].int := half(delta);
      mem[z+4].int := -mem[x+4].int;
      mem[v+3].int := mem[y+3].int;
      mem[v+2].int := mem[y+2].int;
{751:}
      IF mem[q+2].hh.rh=0 THEN
        BEGIN
          freenode(x,7);
          mem[v+5].hh.rh := y;
        END
      ELSE
        BEGIN
          shiftup := fontinfo[11+parambase[eqtb[3938+cursize].hh.rh]]
                     .int-mem[x+2].int;
          IF shiftup<fontinfo[9+parambase[eqtb[3938+cursize].hh.rh]].int THEN
            shiftup := fontinfo[9+parambase[eqtb[3938+cursize].hh.rh]].int;
          p := newkern(shiftup);
          mem[p].hh.rh := y;
          mem[x].hh.rh := p;
          p := newkern(fontinfo[13+parambase[eqtb[3938+cursize].hh.rh]].int);
          mem[p].hh.rh := x;
          mem[v+5].hh.rh := p;
          mem[v+3].int := mem[v+3].int+fontinfo[13+parambase[eqtb[3938+cursize].hh.
                          rh]].int+mem[x+3].int+mem[x+2].int+shiftup;
        END;
      IF mem[q+3].hh.rh=0 THEN freenode(z,7)
      ELSE
        BEGIN
          shiftdown := fontinfo[12+
                       parambase[eqtb[3938+cursize].hh.rh]].int-mem[z+3].int;
          IF shiftdown<fontinfo[10+parambase[eqtb[3938+cursize].hh.rh]].int THEN
            shiftdown := fontinfo[10+parambase[eqtb[3938+cursize].hh.rh]].int;
          p := newkern(shiftdown);
          mem[y].hh.rh := p;
          mem[p].hh.rh := z;
          p := newkern(fontinfo[13+parambase[eqtb[3938+cursize].hh.rh]].int);
          mem[z].hh.rh := p;
          mem[v+2].int := mem[v+2].int+fontinfo[13+parambase[eqtb[3938+cursize].hh.
                          rh]].int+mem[z+3].int+mem[z+2].int+shiftdown;
        END{:751};
      mem[q+1].int := v;
    END{:750};
  makeop := delta;
END;{:749}{752:}
PROCEDURE makeord(q:halfword);

LABEL 20,10;

VAR a: integer;
  p,r: halfword;
BEGIN
  20: IF mem[q+3].hh.rh=0 THEN IF mem[q+2].hh.rh=0 THEN IF mem[q+1].
                                                           hh.rh=1 THEN
                                                          BEGIN
                                                            p := mem[q].hh.rh;
                                                            IF p<>0 THEN IF (mem[p].hh.b0>=16)AND(
                                                                            mem[p].hh.b0<=22)THEN IF
                                                                                                 mem
                                                                                                   [
                                                                                                   p
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .

                                                                                                  hh
                                                                                                   .
                                                                                                  rh
                                                                                                   =
                                                                                                   1
                                                                                                THEN
                                                                                                  IF
                                                                                                 mem
                                                                                                   [
                                                                                                   p
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  b0
                                                                                                   =
                                                                                                 mem
                                                                                                   [
                                                                                                   q
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  b0
                                                                                                THEN

                                                                                               BEGIN

                                                                                                 mem
                                                                                                   [
                                                                                                   q
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  rh

                                                                                                  :=
                                                                                                   4
                                                                                                   ;

                                                                                               fetch
                                                                                                   (
                                                                                                   q
                                                                                                   +
                                                                                                   1
                                                                                                   )
                                                                                                   ;

                                                                                                  IF
                                                                                                   (
                                                                                                   (
                                                                                                curi
                                                                                                   .
                                                                                                  b2
                                                                                                   )
                                                                                                 MOD
                                                                                                   4
                                                                                                   )
                                                                                                   =
                                                                                                   1
                                                                                                THEN

                                                                                               BEGIN

                                                                                                   a
                                                                                                  :=
                                                                                         ligkernbase
                                                                                                   [
                                                                                                curf
                                                                                                   ]
                                                                                                   +
                                                                                                curi
                                                                                                   .
                                                                                                  b3
                                                                                                   ;

                                                                                                curc
                                                                                                  :=
                                                                                                 mem
                                                                                                   [
                                                                                                   p
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  b1
                                                                                                   ;

                                                                                                curi
                                                                                                  :=
                                                                                            fontinfo
                                                                                                   [
                                                                                                   a
                                                                                                   ]
                                                                                                   .
                                                                                                qqqq
                                                                                                   ;

                                                                                                  IF
                                                                                                curi
                                                                                                   .
                                                                                                  b0
                                                                                                   >
                                                                                                 128
                                                                                                THEN

                                                                                               BEGIN

                                                                                                   a
                                                                                                  :=
                                                                                         ligkernbase
                                                                                                   [
                                                                                                curf
                                                                                                   ]
                                                                                                   +
                                                                                                 256
                                                                                                   *
                                                                                                curi
                                                                                                   .
                                                                                                  b2
                                                                                                   +
                                                                                                curi
                                                                                                   .
                                                                                                  b3

                                                                                                   +
                                                                                               32768
                                                                                                   -
                                                                                                 256
                                                                                                   *
                                                                                                   (
                                                                                                 128
                                                                                                   )
                                                                                                   ;

                                                                                                curi
                                                                                                  :=
                                                                                            fontinfo
                                                                                                   [
                                                                                                   a
                                                                                                   ]
                                                                                                   .
                                                                                                qqqq
                                                                                                   ;

                                                                                                 END
                                                                                                   ;

                                                                                               WHILE
                                                                                                true
                                                                                                  DO

                                                                                               BEGIN
                                                                                              {753:}

                                                                                                  IF
                                                                                                curi
                                                                                                   .
                                                                                                  b1
                                                                                                   =
                                                                                                curc
                                                                                                THEN
                                                                                                  IF
                                                                                                curi
                                                                                                   .
                                                                                                  b0
                                                                                                  <=
                                                                                                 128
                                                                                                THEN
                                                                                                  IF

                                                                                                curi
                                                                                                   .
                                                                                                  b2
                                                                                                  >=
                                                                                                 128
                                                                                                THEN

                                                                                               BEGIN

                                                                                                   p
                                                                                                  :=
                                                                                             newkern
                                                                                                   (
                                                                                            fontinfo
                                                                                                   [
                                                                                            kernbase
                                                                                                   [
                                                                                                curf
                                                                                                   ]
                                                                                                   +
                                                                                                 256
                                                                                                   *
                                                                                                curi
                                                                                                   .
                                                                                                  b2
                                                                                                   +

                                                                                                curi
                                                                                                   .
                                                                                                  b3
                                                                                                   ]
                                                                                                   .
                                                                                                 int
                                                                                                   )
                                                                                                   ;

                                                                                                 mem
                                                                                                   [
                                                                                                   p
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  rh
                                                                                                  :=
                                                                                                 mem
                                                                                                   [
                                                                                                   q
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  rh
                                                                                                   ;

                                                                                                 mem
                                                                                                   [
                                                                                                   q
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  rh
                                                                                                  :=
                                                                                                   p
                                                                                                   ;

                                                                                                goto
                                                                                                  10
                                                                                                   ;

                                                                                                 END

                                                                                                ELSE

                                                                                               BEGIN

                                                                                               BEGIN

                                                                                                  IF
                                                                                           interrupt
                                                                                                  <>
                                                                                                   0
                                                                                                THEN
                                                                                pauseforinstructions
                                                                                                   ;

                                                                                                 END
                                                                                                   ;

                                                                                                CASE
                                                                                                curi
                                                                                                   .
                                                                                                  b2
                                                                                                  OF

                                                                                                   1
                                                                                                   ,
                                                                                                   5
                                                                                                   :
                                                                                                 mem
                                                                                                   [
                                                                                                   q
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  b1
                                                                                                  :=
                                                                                                curi
                                                                                                   .
                                                                                                  b3
                                                                                                   ;

                                                                                                   2
                                                                                                   ,
                                                                                                   6
                                                                                                   :
                                                                                                 mem
                                                                                                   [
                                                                                                   p
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  b1
                                                                                                  :=
                                                                                                curi
                                                                                                   .
                                                                                                  b3
                                                                                                   ;

                                                                                                   3
                                                                                                   ,
                                                                                                   7
                                                                                                   ,
                                                                                                  11
                                                                                                   :

                                                                                               BEGIN

                                                                                                   r
                                                                                                  :=
                                                                                             newnoad
                                                                                                   ;

                                                                                                 mem
                                                                                                   [
                                                                                                   r
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  b1
                                                                                                  :=
                                                                                                curi
                                                                                                   .
                                                                                                  b3
                                                                                                   ;

                                                                                                 mem
                                                                                                   [
                                                                                                   r
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  b0
                                                                                                  :=
                                                                                                 mem
                                                                                                   [
                                                                                                   q
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  b0
                                                                                                   ;

                                                                                                 mem
                                                                                                   [
                                                                                                   q
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  rh
                                                                                                  :=
                                                                                                   r
                                                                                                   ;

                                                                                                 mem
                                                                                                   [
                                                                                                   r
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  rh
                                                                                                  :=
                                                                                                   p
                                                                                                   ;

                                                                                                  IF
                                                                                                curi
                                                                                                   .
                                                                                                  b2
                                                                                                   <
                                                                                                  11
                                                                                                THEN
                                                                                                 mem
                                                                                                   [
                                                                                                   r
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  rh
                                                                                                  :=
                                                                                                   1

                                                                                                ELSE
                                                                                                 mem
                                                                                                   [
                                                                                                   r
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  rh
                                                                                                  :=
                                                                                                   4
                                                                                                   ;

                                                                                                 END
                                                                                                   ;

                                                                                                ELSE

                                                                                               BEGIN

                                                                                                 mem
                                                                                                   [
                                                                                                   q
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  rh
                                                                                                  :=
                                                                                                 mem
                                                                                                   [
                                                                                                   p
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  rh
                                                                                                   ;

                                                                                                 mem
                                                                                                   [
                                                                                                   q
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  b1
                                                                                                  :=
                                                                                                curi
                                                                                                   .
                                                                                                  b3
                                                                                                   ;

                                                                                                 mem
                                                                                                   [
                                                                                                   q
                                                                                                   +
                                                                                                   3
                                                                                                   ]
                                                                                                  :=
                                                                                                 mem
                                                                                                   [
                                                                                                   p
                                                                                                   +
                                                                                                   3
                                                                                                   ]
                                                                                                   ;

                                                                                                 mem
                                                                                                   [
                                                                                                   q
                                                                                                   +
                                                                                                   2
                                                                                                   ]
                                                                                                  :=
                                                                                                 mem
                                                                                                   [
                                                                                                   p
                                                                                                   +
                                                                                                   2
                                                                                                   ]
                                                                                                   ;

                                                                                            freenode
                                                                                                   (
                                                                                                   p
                                                                                                   ,
                                                                                                   4
                                                                                                   )
                                                                                                   ;

                                                                                                 END

                                                                                                 END
                                                                                                   ;

                                                                                                  IF
                                                                                                curi
                                                                                                   .
                                                                                                  b2
                                                                                                   >
                                                                                                   3
                                                                                                THEN
                                                                                                goto
                                                                                                  10
                                                                                                   ;

                                                                                                 mem
                                                                                                   [
                                                                                                   q
                                                                                                   +
                                                                                                   1
                                                                                                   ]
                                                                                                   .
                                                                                                  hh
                                                                                                   .
                                                                                                  rh
                                                                                                  :=
                                                                                                   1
                                                                                                   ;

                                                                                                goto
                                                                                                  20
                                                                                                   ;

                                                                                                 END
                                                                                              {:753}
                                                                                                   ;

                                                                                                  IF
                                                                                                curi
                                                                                                   .
                                                                                                  b0
                                                                                                  >=
                                                                                                 128
                                                                                                THEN
                                                                                                goto
                                                                                                  10
                                                                                                   ;

                                                                                                   a
                                                                                                  :=
                                                                                                   a
                                                                                                   +
                                                                                                curi
                                                                                                   .
                                                                                                  b0
                                                                                                   +
                                                                                                   1
                                                                                                   ;

                                                                                                curi
                                                                                                  :=
                                                                                            fontinfo
                                                                                                   [
                                                                                                   a
                                                                                                   ]
                                                                                                   .
                                                                                                qqqq
                                                                                                   ;

                                                                                                 END
                                                                                                   ;

                                                                                                 END
                                                                                                   ;

                                                                                                 END
                                                            ;
                                                          END;
  10:
END;{:752}{756:}
PROCEDURE makescripts(q:halfword;
                      delta:scaled);

VAR p,x,y,z: halfword;
  shiftup,shiftdown,clr: scaled;
  t: smallnumber;
BEGIN
  p := mem[q+1].int;
  IF (p>=himemmin)THEN
    BEGIN
      shiftup := 0;
      shiftdown := 0;
    END
  ELSE
    BEGIN
      z := hpack(p,0,1);
      IF curstyle<4 THEN t := 16
      ELSE t := 32;
      shiftup := mem[z+3].int-fontinfo[18+parambase[eqtb[3937+t].hh.rh]].int;
      shiftdown := mem[z+2].int+fontinfo[19+parambase[eqtb[3937+t].hh.rh]].int;
      freenode(z,7);
    END;
  IF mem[q+2].hh.rh=0 THEN{757:}
    BEGIN
      x := cleanbox(q+3,2*(curstyle DIV 4)+5
           );
      mem[x+1].int := mem[x+1].int+eqtb[5842].int;
      IF shiftdown<fontinfo[16+parambase[eqtb[3937+cursize].hh.rh]].int THEN
        shiftdown := fontinfo[16+parambase[eqtb[3937+cursize].hh.rh]].int;
      clr := mem[x+3].int-(abs(fontinfo[5+parambase[eqtb[3937+cursize].hh.rh]].
             int*4)DIV 5);
      IF shiftdown<clr THEN shiftdown := clr;
      mem[x+4].int := shiftdown;
    END{:757}
  ELSE
    BEGIN{758:}
      BEGIN
        x := cleanbox(q+2,2*(curstyle DIV 4)+4+(
             curstyle MOD 2));
        mem[x+1].int := mem[x+1].int+eqtb[5842].int;
        IF odd(curstyle)THEN clr := fontinfo[15+parambase[eqtb[3937+cursize].hh.rh
                                    ]].int
        ELSE IF curstyle<2 THEN clr := fontinfo[13+parambase[eqtb[3937+
                                       cursize].hh.rh]].int
        ELSE clr := fontinfo[14+parambase[eqtb[3937+cursize].
                    hh.rh]].int;
        IF shiftup<clr THEN shiftup := clr;
        clr := mem[x+2].int+(abs(fontinfo[5+parambase[eqtb[3937+cursize].hh.rh]].
               int)DIV 4);
        IF shiftup<clr THEN shiftup := clr;
      END{:758};
      IF mem[q+3].hh.rh=0 THEN mem[x+4].int := -shiftup
      ELSE{759:}
        BEGIN
          y := 
               cleanbox(q+3,2*(curstyle DIV 4)+5);
          mem[y+1].int := mem[y+1].int+eqtb[5842].int;
          IF shiftdown<fontinfo[17+parambase[eqtb[3937+cursize].hh.rh]].int THEN
            shiftdown := fontinfo[17+parambase[eqtb[3937+cursize].hh.rh]].int;
          clr := 4*fontinfo[8+parambase[eqtb[3938+cursize].hh.rh]].int-((shiftup-mem
                 [x+2].int)-(mem[y+3].int-shiftdown));
          IF clr>0 THEN
            BEGIN
              shiftdown := shiftdown+clr;
              clr := (abs(fontinfo[5+parambase[eqtb[3937+cursize].hh.rh]].int*4)DIV 5)-(
                     shiftup-mem[x+2].int);
              IF clr>0 THEN
                BEGIN
                  shiftup := shiftup+clr;
                  shiftdown := shiftdown-clr;
                END;
            END;
          mem[x+4].int := delta;
          p := newkern((shiftup-mem[x+2].int)-(mem[y+3].int-shiftdown));
          mem[x].hh.rh := p;
          mem[p].hh.rh := y;
          x := vpackage(x,0,1,1073741823);
          mem[x+4].int := shiftdown;
        END{:759};
    END;
  IF mem[q+1].int=0 THEN mem[q+1].int := x
  ELSE
    BEGIN
      p := mem[q+1].int;
      WHILE mem[p].hh.rh<>0 DO
        p := mem[p].hh.rh;
      mem[p].hh.rh := x;
    END;
END;
{:756}{762:}
FUNCTION makeleftright(q:halfword;style:smallnumber;
                       maxd,maxh:scaled): smallnumber;

VAR delta,delta1,delta2: scaled;
BEGIN
  IF style<4 THEN cursize := 0
  ELSE cursize := 16*((style-2)DIV 2);
  delta2 := maxd+fontinfo[22+parambase[eqtb[3937+cursize].hh.rh]].int;
  delta1 := maxh+maxd-delta2;
  IF delta2>delta1 THEN delta1 := delta2;
  delta := (delta1 DIV 500)*eqtb[5281].int;
  delta2 := delta1+delta1-eqtb[5840].int;
  IF delta<delta2 THEN delta := delta2;
  mem[q+1].int := vardelimiter(q+1,cursize,delta);
  makeleftright := mem[q].hh.b0-(10);
END;{:762}
PROCEDURE mlisttohlist;

LABEL 21,82,80,81,83,30;

VAR mlist: halfword;
  penalties: boolean;
  style: smallnumber;
  savestyle: smallnumber;
  q: halfword;
  r: halfword;
  rtype: smallnumber;
  t: smallnumber;
  p,x,y,z: halfword;
  pen: integer;
  s: smallnumber;
  maxh,maxd: scaled;
  delta: scaled;
BEGIN
  mlist := curmlist;
  penalties := mlistpenalties;
  style := curstyle;
  q := mlist;
  r := 0;
  rtype := 17;
  maxh := 0;
  maxd := 0;
{703:}
  BEGIN
    IF curstyle<4 THEN cursize := 0
    ELSE cursize := 16*((curstyle-2)
                    DIV 2);
    curmu := xovern(fontinfo[6+parambase[eqtb[3937+cursize].hh.rh]].int,18);
  END{:703};
  WHILE q<>0 DO{727:}
    BEGIN{728:}
      21: delta := 0;
      CASE mem[q].hh.b0 OF 
        18: CASE rtype OF 
              18,17,19,20,22,30:
                                 BEGIN
                                   mem[q].hh.
                                   b0 := 16;
                                   goto 21;
                                 END;
              ELSE
            END;
        19,21,22,31:
                     BEGIN{729:}
                       IF rtype=18 THEN mem[r].hh.b0 := 16{:729};
                       IF mem[q].hh.b0=31 THEN goto 80;
                     END;{733:}
        30: goto 80;
        25:
            BEGIN
              makefraction(q);
              goto 82;
            END;
        17:
            BEGIN
              delta := makeop(q);
              IF mem[q].hh.b1=1 THEN goto 82;
            END;
        16: makeord(q);
        20,23:;
        24: makeradical(q);
        27: makeover(q);
        26: makeunder(q);
        28: makemathaccent(q);
        29: makevcenter(q);{:733}{730:}
        14:
            BEGIN
              curstyle := mem[q].hh.b1;
{703:}
              BEGIN
                IF curstyle<4 THEN cursize := 0
                ELSE cursize := 16*((curstyle-2)
                                DIV 2);
                curmu := xovern(fontinfo[6+parambase[eqtb[3937+cursize].hh.rh]].int,18);
              END{:703};
              goto 81;
            END;
        15:{731:}
            BEGIN
              CASE curstyle DIV 2 OF 
                0:
                   BEGIN
                     p := mem[q+1].hh.lh;
                     mem[q+1].hh.lh := 0;
                   END;
                1:
                   BEGIN
                     p := mem[q+1].hh.rh;
                     mem[q+1].hh.rh := 0;
                   END;
                2:
                   BEGIN
                     p := mem[q+2].hh.lh;
                     mem[q+2].hh.lh := 0;
                   END;
                3:
                   BEGIN
                     p := mem[q+2].hh.rh;
                     mem[q+2].hh.rh := 0;
                   END;
              END;
              flushnodelist(mem[q+1].hh.lh);
              flushnodelist(mem[q+1].hh.rh);
              flushnodelist(mem[q+2].hh.lh);
              flushnodelist(mem[q+2].hh.rh);
              mem[q].hh.b0 := 14;
              mem[q].hh.b1 := curstyle;
              mem[q+1].int := 0;
              mem[q+2].int := 0;
              IF p<>0 THEN
                BEGIN
                  z := mem[q].hh.rh;
                  mem[q].hh.rh := p;
                  WHILE mem[p].hh.rh<>0 DO
                    p := mem[p].hh.rh;
                  mem[p].hh.rh := z;
                END;
              goto 81;
            END{:731};
        3,4,5,8,12,7: goto 81;
        2:
           BEGIN
             IF mem[q+3].int>maxh THEN maxh := mem[q+3].int;
             IF mem[q+2].int>maxd THEN maxd := mem[q+2].int;
             goto 81;
           END;
        10:
            BEGIN{732:}
              IF mem[q].hh.b1=99 THEN
                BEGIN
                  x := mem[q+1].hh.lh;
                  y := mathglue(x,curmu);
                  deleteglueref(x);
                  mem[q+1].hh.lh := y;
                  mem[q].hh.b1 := 0;
                END
              ELSE IF (cursize<>0)AND(mem[q].hh.b1=98)THEN
                     BEGIN
                       p := mem[q].hh.rh;
                       IF p<>0 THEN IF (mem[p].hh.b0=10)OR(mem[p].hh.b0=11)THEN
                                      BEGIN
                                        mem[q].hh.
                                        rh := mem[p].hh.rh;
                                        mem[p].hh.rh := 0;
                                        flushnodelist(p);
                                      END;
                     END{:732};
              goto 81;
            END;
        11:
            BEGIN
              mathkern(q,curmu);
              goto 81;
            END;{:730}
        ELSE confusion(890)
      END;
{754:}
      CASE mem[q+1].hh.rh OF 
        1,4:{755:}
             BEGIN
               fetch(q+1);
               IF (curi.b0>0)THEN
                 BEGIN
                   delta := fontinfo[italicbase[curf]+(curi.b2)DIV 4]
                            .int;
                   p := newcharacter(curf,curc);
                   IF (mem[q+1].hh.rh=4)AND(fontinfo[2+parambase[curf]].int<>0)THEN delta := 0
                   ;
                   IF (mem[q+3].hh.rh=0)AND(delta<>0)THEN
                     BEGIN
                       mem[p].hh.rh := newkern(delta)
                       ;
                       delta := 0;
                     END;
                 END
               ELSE p := 0;
             END{:755};
        0: p := 0;
        2: p := mem[q+1].hh.lh;
        3:
           BEGIN
             curmlist := mem[q+1].hh.lh;
             savestyle := curstyle;
             mlistpenalties := false;
             mlisttohlist;
             curstyle := savestyle;
{703:}
             BEGIN
               IF curstyle<4 THEN cursize := 0
               ELSE cursize := 16*((curstyle-2)
                               DIV 2);
               curmu := xovern(fontinfo[6+parambase[eqtb[3937+cursize].hh.rh]].int,18);
             END{:703};
             p := hpack(mem[29997].hh.rh,0,1);
           END;
        ELSE confusion(891)
      END;
      mem[q+1].int := p;
      IF (mem[q+3].hh.rh=0)AND(mem[q+2].hh.rh=0)THEN goto 82;
      makescripts(q,delta){:754}{:728};
      82: z := hpack(mem[q+1].int,0,1);
      IF mem[z+3].int>maxh THEN maxh := mem[z+3].int;
      IF mem[z+2].int>maxd THEN maxd := mem[z+2].int;
      freenode(z,7);
      80: r := q;
      rtype := mem[r].hh.b0;
      81: q := mem[q].hh.rh;
    END{:727};
{729:}
  IF rtype=18 THEN mem[r].hh.b0 := 16{:729};{760:}
  p := 29997;
  mem[p].hh.rh := 0;
  q := mlist;
  rtype := 0;
  curstyle := style;
{703:}
  BEGIN
    IF curstyle<4 THEN cursize := 0
    ELSE cursize := 16*((curstyle-2)
                    DIV 2);
    curmu := xovern(fontinfo[6+parambase[eqtb[3937+cursize].hh.rh]].int,18);
  END{:703};
  WHILE q<>0 DO
    BEGIN{761:}
      t := 16;
      s := 4;
      pen := 10000;
      CASE mem[q].hh.b0 OF 
        17,20,21,22,23: t := mem[q].hh.b0;
        18:
            BEGIN
              t := 18;
              pen := eqtb[5272].int;
            END;
        19:
            BEGIN
              t := 19;
              pen := eqtb[5273].int;
            END;
        16,29,27,26:;
        24: s := 5;
        28: s := 5;
        25: s := 6;
        30,31: t := makeleftright(q,style,maxd,maxh);
        14:{763:}
            BEGIN
              curstyle := mem[q].hh.b1;
              s := 3;
{703:}
              BEGIN
                IF curstyle<4 THEN cursize := 0
                ELSE cursize := 16*((curstyle-2)
                                DIV 2);
                curmu := xovern(fontinfo[6+parambase[eqtb[3937+cursize].hh.rh]].int,18);
              END{:703};
              goto 83;
            END{:763};
        8,12,2,7,5,3,4,10,11:
                              BEGIN
                                mem[p].hh.rh := q;
                                p := q;
                                q := mem[q].hh.rh;
                                mem[p].hh.rh := 0;
                                goto 30;
                              END;
        ELSE confusion(892)
      END{:761};
{766:}
      IF rtype>0 THEN
        BEGIN
          CASE strpool[rtype*8+t+magicoffset] OF 
            48: x := 
                     0;
            49: IF curstyle<4 THEN x := 15
                ELSE x := 0;
            50: x := 15;
            51: IF curstyle<4 THEN x := 16
                ELSE x := 0;
            52: IF curstyle<4 THEN x := 17
                ELSE x := 0;
            ELSE confusion(894)
          END;
          IF x<>0 THEN
            BEGIN
              y := mathglue(eqtb[2882+x].hh.rh,curmu);
              z := newglue(y);
              mem[y].hh.rh := 0;
              mem[p].hh.rh := z;
              p := z;
              mem[z].hh.b1 := x+1;
            END;
        END{:766};
{767:}
      IF mem[q+1].int<>0 THEN
        BEGIN
          mem[p].hh.rh := mem[q+1].int;
          REPEAT
            p := mem[p].hh.rh;
          UNTIL mem[p].hh.rh=0;
        END;
      IF penalties THEN IF mem[q].hh.rh<>0 THEN IF pen<10000 THEN
                                                  BEGIN
                                                    rtype 
                                                    := mem[mem[q].hh.rh].hh.b0;
                                                    IF rtype<>12 THEN IF rtype<>19 THEN
                                                                        BEGIN
                                                                          z := newpenalty(pen);
                                                                          mem[p].hh.rh := z;
                                                                          p := z;
                                                                        END;
                                                  END{:767};
      rtype := t;
      83: r := q;
      q := mem[q].hh.rh;
      freenode(r,s);
      30:
    END{:760};
END;{:726}{772:}
PROCEDURE pushalignment;

VAR p: halfword;
BEGIN
  p := getnode(5);
  mem[p].hh.rh := alignptr;
  mem[p].hh.lh := curalign;
  mem[p+1].hh.lh := mem[29992].hh.rh;
  mem[p+1].hh.rh := curspan;
  mem[p+2].int := curloop;
  mem[p+3].int := alignstate;
  mem[p+4].hh.lh := curhead;
  mem[p+4].hh.rh := curtail;
  alignptr := p;
  curhead := getavail;
END;
PROCEDURE popalignment;

VAR p: halfword;
BEGIN
  BEGIN
    mem[curhead].hh.rh := avail;
    avail := curhead;
    dynused := dynused-1;
  END;
  p := alignptr;
  curtail := mem[p+4].hh.rh;
  curhead := mem[p+4].hh.lh;
  alignstate := mem[p+3].int;
  curloop := mem[p+2].int;
  curspan := mem[p+1].hh.rh;
  mem[29992].hh.rh := mem[p+1].hh.lh;
  curalign := mem[p].hh.lh;
  alignptr := mem[p].hh.rh;
  freenode(p,5);
END;
{:772}{774:}{782:}
PROCEDURE getpreambletoken;

LABEL 20;
BEGIN
  20: gettoken;
  WHILE (curchr=256)AND(curcmd=4) DO
    BEGIN
      gettoken;
      IF curcmd>100 THEN
        BEGIN
          expand;
          gettoken;
        END;
    END;
  IF curcmd=9 THEN fatalerror(595);
  IF (curcmd=75)AND(curchr=2893)THEN
    BEGIN
      scanoptionalequals;
      scanglue(2);
      IF eqtb[5306].int>0 THEN geqdefine(2893,117,curval)
      ELSE eqdefine(2893,
                    117,curval);
      goto 20;
    END;
END;{:782}
PROCEDURE alignpeek;
forward;
PROCEDURE normalparagraph;
forward;
PROCEDURE initalign;

LABEL 30,31,32,22;

VAR savecsptr: halfword;
  p: halfword;
BEGIN
  savecsptr := curcs;
  pushalignment;
  alignstate := -1000000;
{776:}
  IF (curlist.modefield=203)AND((curlist.tailfield<>curlist.headfield
     )OR(curlist.auxfield.int<>0))THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(680);
      END;
      printesc(520);
      print(895);
      BEGIN
        helpptr := 3;
        helpline[2] := 896;
        helpline[1] := 897;
        helpline[0] := 898;
      END;
      error;
      flushmath;
    END{:776};
  pushnest;
{775:}
  IF curlist.modefield=203 THEN
    BEGIN
      curlist.modefield := -1;
      curlist.auxfield.int := nest[nestptr-2].auxfield.int;
    END
  ELSE IF curlist.modefield>0 THEN curlist.modefield := -curlist.
                                                        modefield{:775};
  scanspec(6,false);{777:}
  mem[29992].hh.rh := 0;
  curalign := 29992;
  curloop := 0;
  scannerstatus := 4;
  warningindex := savecsptr;
  alignstate := -1000000;
  WHILE true DO
    BEGIN{778:}
      mem[curalign].hh.rh := newparamglue(11);
      curalign := mem[curalign].hh.rh{:778};
      IF curcmd=5 THEN goto 30;
{779:}{783:}
      p := 29996;
      mem[p].hh.rh := 0;
      WHILE true DO
        BEGIN
          getpreambletoken;
          IF curcmd=6 THEN goto 31;
          IF (curcmd<=5)AND(curcmd>=4)AND(alignstate=-1000000)THEN IF (p=29996)AND(
                                                                      curloop=0)AND(curcmd=4)THEN
                                                                     curloop := curalign
          ELSE
            BEGIN
              BEGIN
                IF 
                   interaction=3 THEN;
                printnl(262);
                print(904);
              END;
              BEGIN
                helpptr := 3;
                helpline[2] := 905;
                helpline[1] := 906;
                helpline[0] := 907;
              END;
              backerror;
              goto 31;
            END
          ELSE IF (curcmd<>10)OR(p<>29996)THEN
                 BEGIN
                   mem[p].hh.rh := getavail;
                   p := mem[p].hh.rh;
                   mem[p].hh.lh := curtok;
                 END;
        END;
      31:{:783};
      mem[curalign].hh.rh := newnullbox;
      curalign := mem[curalign].hh.rh;
      mem[curalign].hh.lh := 29991;
      mem[curalign+1].int := -1073741824;
      mem[curalign+3].int := mem[29996].hh.rh;{784:}
      p := 29996;
      mem[p].hh.rh := 0;
      WHILE true DO
        BEGIN
          22: getpreambletoken;
          IF (curcmd<=5)AND(curcmd>=4)AND(alignstate=-1000000)THEN goto 32;
          IF curcmd=6 THEN
            BEGIN
              BEGIN
                IF interaction=3 THEN;
                printnl(262);
                print(908);
              END;
              BEGIN
                helpptr := 3;
                helpline[2] := 905;
                helpline[1] := 906;
                helpline[0] := 909;
              END;
              error;
              goto 22;
            END;
          mem[p].hh.rh := getavail;
          p := mem[p].hh.rh;
          mem[p].hh.lh := curtok;
        END;
      32: mem[p].hh.rh := getavail;
      p := mem[p].hh.rh;
      mem[p].hh.lh := 6714{:784};
      mem[curalign+2].int := mem[29996].hh.rh{:779};
    END;
  30: scannerstatus := 0{:777};
  newsavelevel(6);
  IF eqtb[3420].hh.rh<>0 THEN begintokenlist(eqtb[3420].hh.rh,13);
  alignpeek;
END;{:774}{786:}{787:}
PROCEDURE initspan(p:halfword);
BEGIN
  pushnest;
  IF curlist.modefield=-102 THEN curlist.auxfield.hh.lh := 1000
  ELSE
    BEGIN
      curlist.auxfield.int := -65536000;
      normalparagraph;
    END;
  curspan := p;
END;
{:787}
PROCEDURE initrow;
BEGIN
  pushnest;
  curlist.modefield := (-103)-curlist.modefield;
  IF curlist.modefield=-102 THEN curlist.auxfield.hh.lh := 0
  ELSE curlist.
    auxfield.int := 0;
  BEGIN
    mem[curlist.tailfield].hh.rh := newglue(mem[mem[29992].hh.rh+1].hh.
                                    lh);
    curlist.tailfield := mem[curlist.tailfield].hh.rh;
  END;
  mem[curlist.tailfield].hh.b1 := 12;
  curalign := mem[mem[29992].hh.rh].hh.rh;
  curtail := curhead;
  initspan(curalign);
END;{:786}{788:}
PROCEDURE initcol;
BEGIN
  mem[curalign+5].hh.lh := curcmd;
  IF curcmd=63 THEN alignstate := 0
  ELSE
    BEGIN
      backinput;
      begintokenlist(mem[curalign+3].int,1);
    END;
END;
{:788}{791:}
FUNCTION fincol: boolean;

LABEL 10;

VAR p: halfword;
  q,r: halfword;
  s: halfword;
  u: halfword;
  w: scaled;
  o: glueord;
  n: halfword;
BEGIN
  IF curalign=0 THEN confusion(910);
  q := mem[curalign].hh.rh;
  IF q=0 THEN confusion(910);
  IF alignstate<500000 THEN fatalerror(595);
  p := mem[q].hh.rh;
{792:}
  IF (p=0)AND(mem[curalign+5].hh.lh<257)THEN IF curloop<>0 THEN{793:}
                                               BEGIN
                                                 mem[q].hh.rh := newnullbox;
                                                 p := mem[q].hh.rh;
                                                 mem[p].hh.lh := 29991;
                                                 mem[p+1].int := -1073741824;
                                                 curloop := mem[curloop].hh.rh;{794:}
                                                 q := 29996;
                                                 r := mem[curloop+3].int;
                                                 WHILE r<>0 DO
                                                   BEGIN
                                                     mem[q].hh.rh := getavail;
                                                     q := mem[q].hh.rh;
                                                     mem[q].hh.lh := mem[r].hh.lh;
                                                     r := mem[r].hh.rh;
                                                   END;
                                                 mem[q].hh.rh := 0;
                                                 mem[p+3].int := mem[29996].hh.rh;
                                                 q := 29996;
                                                 r := mem[curloop+2].int;
                                                 WHILE r<>0 DO
                                                   BEGIN
                                                     mem[q].hh.rh := getavail;
                                                     q := mem[q].hh.rh;
                                                     mem[q].hh.lh := mem[r].hh.lh;
                                                     r := mem[r].hh.rh;
                                                   END;
                                                 mem[q].hh.rh := 0;
                                                 mem[p+2].int := mem[29996].hh.rh{:794};
                                                 curloop := mem[curloop].hh.rh;
                                                 mem[p].hh.rh := newglue(mem[curloop+1].hh.lh);
                                                 mem[mem[p].hh.rh].hh.b1 := 12;
                                               END{:793}
  ELSE
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(911);
      END;
      printesc(900);
      BEGIN
        helpptr := 3;
        helpline[2] := 912;
        helpline[1] := 913;
        helpline[0] := 914;
      END;
      mem[curalign+5].hh.lh := 257;
      error;
    END{:792};
  IF mem[curalign+5].hh.lh<>256 THEN
    BEGIN
      unsave;
      newsavelevel(6);
{796:}
      BEGIN
        IF curlist.modefield=-102 THEN
          BEGIN
            adjusttail := curtail;
            u := hpack(mem[curlist.headfield].hh.rh,0,1);
            w := mem[u+1].int;
            curtail := adjusttail;
            adjusttail := 0;
          END
        ELSE
          BEGIN
            u := vpackage(mem[curlist.headfield].hh.rh,0,1,0);
            w := mem[u+3].int;
          END;
        n := 0;
        IF curspan<>curalign THEN{798:}
          BEGIN
            q := curspan;
            REPEAT
              n := n+1;
              q := mem[mem[q].hh.rh].hh.rh;
            UNTIL q=curalign;
            IF n>255 THEN confusion(915);
            q := curspan;
            WHILE mem[mem[q].hh.lh].hh.rh<n DO
              q := mem[q].hh.lh;
            IF mem[mem[q].hh.lh].hh.rh>n THEN
              BEGIN
                s := getnode(2);
                mem[s].hh.lh := mem[q].hh.lh;
                mem[s].hh.rh := n;
                mem[q].hh.lh := s;
                mem[s+1].int := w;
              END
            ELSE IF mem[mem[q].hh.lh+1].int<w THEN mem[mem[q].hh.lh+1].int := w;
          END{:798}
        ELSE IF w>mem[curalign+1].int THEN mem[curalign+1].int := w;
        mem[u].hh.b0 := 13;
        mem[u].hh.b1 := n;
{659:}
        IF totalstretch[3]<>0 THEN o := 3
        ELSE IF totalstretch[2]<>0 THEN o 
               := 2
        ELSE IF totalstretch[1]<>0 THEN o := 1
        ELSE o := 0{:659};
        mem[u+5].hh.b1 := o;
        mem[u+6].int := totalstretch[o];
{665:}
        IF totalshrink[3]<>0 THEN o := 3
        ELSE IF totalshrink[2]<>0 THEN o := 2
        ELSE IF totalshrink[1]<>0 THEN o := 1
        ELSE o := 0{:665};
        mem[u+5].hh.b0 := o;
        mem[u+4].int := totalshrink[o];
        popnest;
        mem[curlist.tailfield].hh.rh := u;
        curlist.tailfield := u;
      END{:796};
{795:}
      BEGIN
        mem[curlist.tailfield].hh.rh := newglue(mem[mem[curalign].hh.
                                        rh+1].hh.lh);
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      mem[curlist.tailfield].hh.b1 := 12{:795};
      IF mem[curalign+5].hh.lh>=257 THEN
        BEGIN
          fincol := true;
          goto 10;
        END;
      initspan(p);
    END;
  alignstate := 1000000;{406:}
  REPEAT
    getxtoken;
  UNTIL curcmd<>10{:406};
  curalign := p;
  initcol;
  fincol := false;
  10:
END;
{:791}{799:}
PROCEDURE finrow;

VAR p: halfword;
BEGIN
  IF curlist.modefield=-102 THEN
    BEGIN
      p := hpack(mem[curlist.
           headfield].hh.rh,0,1);
      popnest;
      appendtovlist(p);
      IF curhead<>curtail THEN
        BEGIN
          mem[curlist.tailfield].hh.rh := mem[curhead
                                          ].hh.rh;
          curlist.tailfield := curtail;
        END;
    END
  ELSE
    BEGIN
      p := vpackage(mem[curlist.headfield].hh.rh,0,1,1073741823);
      popnest;
      mem[curlist.tailfield].hh.rh := p;
      curlist.tailfield := p;
      curlist.auxfield.hh.lh := 1000;
    END;
  mem[p].hh.b0 := 13;
  mem[p+6].int := 0;
  IF eqtb[3420].hh.rh<>0 THEN begintokenlist(eqtb[3420].hh.rh,13);
  alignpeek;
END;{:799}{800:}
PROCEDURE doassignments;
forward;
PROCEDURE resumeafterdisplay;
forward;
PROCEDURE buildpage;
forward;
PROCEDURE finalign;

VAR p,q,r,s,u,v: halfword;
  t,w: scaled;
  o: scaled;
  n: halfword;
  rulesave: scaled;
  auxsave: memoryword;
BEGIN
  IF curgroup<>6 THEN confusion(916);
  unsave;
  IF curgroup<>6 THEN confusion(917);
  unsave;
  IF nest[nestptr-1].modefield=203 THEN o := eqtb[5845].int
  ELSE o := 0;
{801:}
  q := mem[mem[29992].hh.rh].hh.rh;
  REPEAT
    flushlist(mem[q+3].int);
    flushlist(mem[q+2].int);
    p := mem[mem[q].hh.rh].hh.rh;
    IF mem[q+1].int=-1073741824 THEN{802:}
      BEGIN
        mem[q+1].int := 0;
        r := mem[q].hh.rh;
        s := mem[r+1].hh.lh;
        IF s<>0 THEN
          BEGIN
            mem[0].hh.rh := mem[0].hh.rh+1;
            deleteglueref(s);
            mem[r+1].hh.lh := 0;
          END;
      END{:802};
    IF mem[q].hh.lh<>29991 THEN{803:}
      BEGIN
        t := mem[q+1].int+mem[mem[mem[q].hh
             .rh+1].hh.lh+1].int;
        r := mem[q].hh.lh;
        s := 29991;
        mem[s].hh.lh := p;
        n := 1;
        REPEAT
          mem[r+1].int := mem[r+1].int-t;
          u := mem[r].hh.lh;
          WHILE mem[r].hh.rh>n DO
            BEGIN
              s := mem[s].hh.lh;
              n := mem[mem[s].hh.lh].hh.rh+1;
            END;
          IF mem[r].hh.rh<n THEN
            BEGIN
              mem[r].hh.lh := mem[s].hh.lh;
              mem[s].hh.lh := r;
              mem[r].hh.rh := mem[r].hh.rh-1;
              s := r;
            END
          ELSE
            BEGIN
              IF mem[r+1].int>mem[mem[s].hh.lh+1].int THEN mem[mem[s].
                hh.lh+1].int := mem[r+1].int;
              freenode(r,2);
            END;
          r := u;
        UNTIL r=29991;
      END{:803};
    mem[q].hh.b0 := 13;
    mem[q].hh.b1 := 0;
    mem[q+3].int := 0;
    mem[q+2].int := 0;
    mem[q+5].hh.b1 := 0;
    mem[q+5].hh.b0 := 0;
    mem[q+6].int := 0;
    mem[q+4].int := 0;
    q := p;
  UNTIL q=0{:801};{804:}
  saveptr := saveptr-2;
  packbeginline := -curlist.mlfield;
  IF curlist.modefield=-1 THEN
    BEGIN
      rulesave := eqtb[5846].int;
      eqtb[5846].int := 0;
      p := hpack(mem[29992].hh.rh,savestack[saveptr+1].int,savestack[saveptr+0].
           int);
      eqtb[5846].int := rulesave;
    END
  ELSE
    BEGIN
      q := mem[mem[29992].hh.rh].hh.rh;
      REPEAT
        mem[q+3].int := mem[q+1].int;
        mem[q+1].int := 0;
        q := mem[mem[q].hh.rh].hh.rh;
      UNTIL q=0;
      p := vpackage(mem[29992].hh.rh,savestack[saveptr+1].int,savestack[saveptr
           +0].int,1073741823);
      q := mem[mem[29992].hh.rh].hh.rh;
      REPEAT
        mem[q+1].int := mem[q+3].int;
        mem[q+3].int := 0;
        q := mem[mem[q].hh.rh].hh.rh;
      UNTIL q=0;
    END;
  packbeginline := 0{:804};
{805:}
  q := mem[curlist.headfield].hh.rh;
  s := curlist.headfield;
  WHILE q<>0 DO
    BEGIN
      IF NOT(q>=himemmin)THEN IF mem[q].hh.b0=13 THEN
{807:}
                                BEGIN
                                  IF curlist.modefield=-1 THEN
                                    BEGIN
                                      mem[q].hh.b0 := 0;
                                      mem[q+1].int := mem[p+1].int;
                                    END
                                  ELSE
                                    BEGIN
                                      mem[q].hh.b0 := 1;
                                      mem[q+3].int := mem[p+3].int;
                                    END;
                                  mem[q+5].hh.b1 := mem[p+5].hh.b1;
                                  mem[q+5].hh.b0 := mem[p+5].hh.b0;
                                  mem[q+6].gr := mem[p+6].gr;
                                  mem[q+4].int := o;
                                  r := mem[mem[q+5].hh.rh].hh.rh;
                                  s := mem[mem[p+5].hh.rh].hh.rh;
                                  REPEAT{808:}
                                    n := mem[r].hh.b1;
                                    t := mem[s+1].int;
                                    w := t;
                                    u := 29996;
                                    WHILE n>0 DO
                                      BEGIN
                                        n := n-1;{809:}
                                        s := mem[s].hh.rh;
                                        v := mem[s+1].hh.lh;
                                        mem[u].hh.rh := newglue(v);
                                        u := mem[u].hh.rh;
                                        mem[u].hh.b1 := 12;
                                        t := t+mem[v+1].int;
                                        IF mem[p+5].hh.b0=1 THEN
                                          BEGIN
                                            IF mem[v].hh.b0=mem[p+5].hh.b1 THEN t := t+
                                                                                     round(mem[p+6].
                                                                                     gr*mem[v+2].int
                                                                                     );
                                          END
                                        ELSE IF mem[p+5].hh.b0=2 THEN
                                               BEGIN
                                                 IF mem[v].hh.b1=mem[p+5].hh.b1
                                                   THEN t := t-round(mem[p+6].gr*mem[v+3].int);
                                               END;
                                        s := mem[s].hh.rh;
                                        mem[u].hh.rh := newnullbox;
                                        u := mem[u].hh.rh;
                                        t := t+mem[s+1].int;
                                        IF curlist.modefield=-1 THEN mem[u+1].int := mem[s+1].int
                                        ELSE
                                          BEGIN
                                            mem[u
                                            ].hh.b0 := 1;
                                            mem[u+3].int := mem[s+1].int;
                                          END{:809};
                                      END;
                                    IF curlist.modefield=-1 THEN{810:}
                                      BEGIN
                                        mem[r+3].int := mem[q+3].int;
                                        mem[r+2].int := mem[q+2].int;
                                        IF t=mem[r+1].int THEN
                                          BEGIN
                                            mem[r+5].hh.b0 := 0;
                                            mem[r+5].hh.b1 := 0;
                                            mem[r+6].gr := 0.0;
                                          END
                                        ELSE IF t>mem[r+1].int THEN
                                               BEGIN
                                                 mem[r+5].hh.b0 := 1;
                                                 IF mem[r+6].int=0 THEN mem[r+6].gr := 0.0
                                                 ELSE mem[r+6].gr := (t-mem[r+1].
                                                                     int)/mem[r+6].int;
                                               END
                                        ELSE
                                          BEGIN
                                            mem[r+5].hh.b1 := mem[r+5].hh.b0;
                                            mem[r+5].hh.b0 := 2;
                                            IF mem[r+4].int=0 THEN mem[r+6].gr := 0.0
                                            ELSE IF (mem[r+5].hh.b1=0)AND(mem
                                                    [r+1].int-t>mem[r+4].int)THEN mem[r+6].gr := 1.0
                                            ELSE mem[r+6].gr := (mem[r
                                                                +1].int-t)/mem[r+4].int;
                                          END;
                                        mem[r+1].int := w;
                                        mem[r].hh.b0 := 0;
                                      END{:810}
                                    ELSE{811:}
                                      BEGIN
                                        mem[r+1].int := mem[q+1].int;
                                        IF t=mem[r+3].int THEN
                                          BEGIN
                                            mem[r+5].hh.b0 := 0;
                                            mem[r+5].hh.b1 := 0;
                                            mem[r+6].gr := 0.0;
                                          END
                                        ELSE IF t>mem[r+3].int THEN
                                               BEGIN
                                                 mem[r+5].hh.b0 := 1;
                                                 IF mem[r+6].int=0 THEN mem[r+6].gr := 0.0
                                                 ELSE mem[r+6].gr := (t-mem[r+3].
                                                                     int)/mem[r+6].int;
                                               END
                                        ELSE
                                          BEGIN
                                            mem[r+5].hh.b1 := mem[r+5].hh.b0;
                                            mem[r+5].hh.b0 := 2;
                                            IF mem[r+4].int=0 THEN mem[r+6].gr := 0.0
                                            ELSE IF (mem[r+5].hh.b1=0)AND(mem
                                                    [r+3].int-t>mem[r+4].int)THEN mem[r+6].gr := 1.0
                                            ELSE mem[r+6].gr := (mem[r
                                                                +3].int-t)/mem[r+4].int;
                                          END;
                                        mem[r+3].int := w;
                                        mem[r].hh.b0 := 1;
                                      END{:811};
                                    mem[r+4].int := 0;
                                    IF u<>29996 THEN
                                      BEGIN
                                        mem[u].hh.rh := mem[r].hh.rh;
                                        mem[r].hh.rh := mem[29996].hh.rh;
                                        r := u;
                                      END{:808};
                                    r := mem[mem[r].hh.rh].hh.rh;
                                    s := mem[mem[s].hh.rh].hh.rh;
                                  UNTIL r=0;
                                END{:807}
      ELSE IF mem[q].hh.b0=2 THEN{806:}
             BEGIN
               IF (mem[q+1].int=
                  -1073741824)THEN mem[q+1].int := mem[p+1].int;
               IF (mem[q+3].int=-1073741824)THEN mem[q+3].int := mem[p+3].int;
               IF (mem[q+2].int=-1073741824)THEN mem[q+2].int := mem[p+2].int;
               IF o<>0 THEN
                 BEGIN
                   r := mem[q].hh.rh;
                   mem[q].hh.rh := 0;
                   q := hpack(q,0,1);
                   mem[q+4].int := o;
                   mem[q].hh.rh := r;
                   mem[s].hh.rh := q;
                 END;
             END{:806};
      s := q;
      q := mem[q].hh.rh;
    END{:805};
  flushnodelist(p);
  popalignment;
{812:}
  auxsave := curlist.auxfield;
  p := mem[curlist.headfield].hh.rh;
  q := curlist.tailfield;
  popnest;
  IF curlist.modefield=203 THEN{1206:}
    BEGIN
      doassignments;
      IF curcmd<>3 THEN{1207:}
        BEGIN
          BEGIN
            IF interaction=3 THEN;
            printnl(262);
            print(1171);
          END;
          BEGIN
            helpptr := 2;
            helpline[1] := 896;
            helpline[0] := 897;
          END;
          backerror;
        END{:1207}
      ELSE{1197:}
        BEGIN
          getxtoken;
          IF curcmd<>3 THEN
            BEGIN
              BEGIN
                IF interaction=3 THEN;
                printnl(262);
                print(1167);
              END;
              BEGIN
                helpptr := 2;
                helpline[1] := 1168;
                helpline[0] := 1169;
              END;
              backerror;
            END;
        END{:1197};
      popnest;
      BEGIN
        mem[curlist.tailfield].hh.rh := newpenalty(eqtb[5274].int);
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      BEGIN
        mem[curlist.tailfield].hh.rh := newparamglue(3);
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      mem[curlist.tailfield].hh.rh := p;
      IF p<>0 THEN curlist.tailfield := q;
      BEGIN
        mem[curlist.tailfield].hh.rh := newpenalty(eqtb[5275].int);
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      BEGIN
        mem[curlist.tailfield].hh.rh := newparamglue(4);
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      curlist.auxfield.int := auxsave.int;
      resumeafterdisplay;
    END{:1206}
  ELSE
    BEGIN
      curlist.auxfield := auxsave;
      mem[curlist.tailfield].hh.rh := p;
      IF p<>0 THEN curlist.tailfield := q;
      IF curlist.modefield=1 THEN buildpage;
    END{:812};
END;
{785:}
PROCEDURE alignpeek;

LABEL 20;
BEGIN
  20: alignstate := 1000000;
{406:}
  REPEAT
    getxtoken;
  UNTIL curcmd<>10{:406};
  IF curcmd=34 THEN
    BEGIN
      scanleftbrace;
      newsavelevel(7);
      IF curlist.modefield=-1 THEN normalparagraph;
    END
  ELSE IF curcmd=2 THEN finalign
  ELSE IF (curcmd=5)AND(curchr=258)THEN
         goto 20
  ELSE
    BEGIN
      initrow;
      initcol;
    END;
END;
{:785}{:800}{815:}{826:}
FUNCTION finiteshrink(p:halfword): halfword;

VAR q: halfword;
BEGIN
  IF noshrinkerroryet THEN
    BEGIN
      noshrinkerroryet := false;
      IF eqtb[5295].int>0 THEN enddiagnostic(true);
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(918);
      END;
      BEGIN
        helpptr := 5;
        helpline[4] := 919;
        helpline[3] := 920;
        helpline[2] := 921;
        helpline[1] := 922;
        helpline[0] := 923;
      END;
      error;
      IF eqtb[5295].int>0 THEN begindiagnostic;
    END;
  q := newspec(p);
  mem[q].hh.b1 := 0;
  deleteglueref(p);
  finiteshrink := q;
END;
{:826}{829:}
PROCEDURE trybreak(pi:integer;breaktype:smallnumber);

LABEL 10,30,31,22,60;

VAR r: halfword;
  prevr: halfword;
  oldl: halfword;
  nobreakyet: boolean;{830:}
  prevprevr: halfword;
  s: halfword;
  q: halfword;
  v: halfword;
  t: integer;
  f: internalfontnumber;
  l: halfword;
  noderstaysactive: boolean;
  linewidth: scaled;
  fitclass: 0..3;
  b: halfword;
  d: integer;
  artificialdemerits: boolean;
  savelink: halfword;
  shortfall: scaled;
{:830}
BEGIN{831:}
  IF abs(pi)>=10000 THEN IF pi>0 THEN goto 10
  ELSE pi := 
             -10000{:831};
  nobreakyet := true;
  prevr := 29993;
  oldl := 0;
  curactivewidth[1] := activewidth[1];
  curactivewidth[2] := activewidth[2];
  curactivewidth[3] := activewidth[3];
  curactivewidth[4] := activewidth[4];
  curactivewidth[5] := activewidth[5];
  curactivewidth[6] := activewidth[6];
  WHILE true DO
    BEGIN
      22: r := mem[prevr].hh.rh;
{832:}
      IF mem[r].hh.b0=2 THEN
        BEGIN
          curactivewidth[1] := curactivewidth[1]+
                               mem[r+1].int;
          curactivewidth[2] := curactivewidth[2]+mem[r+2].int;
          curactivewidth[3] := curactivewidth[3]+mem[r+3].int;
          curactivewidth[4] := curactivewidth[4]+mem[r+4].int;
          curactivewidth[5] := curactivewidth[5]+mem[r+5].int;
          curactivewidth[6] := curactivewidth[6]+mem[r+6].int;
          prevprevr := prevr;
          prevr := r;
          goto 22;
        END{:832};{835:}
      BEGIN
        l := mem[r+1].hh.lh;
        IF l>oldl THEN
          BEGIN
            IF (minimumdemerits<1073741823)AND((oldl<>easyline)
               OR(r=29993))THEN{836:}
              BEGIN
                IF nobreakyet THEN{837:}
                  BEGIN
                    nobreakyet := 
                                  false;
                    breakwidth[1] := background[1];
                    breakwidth[2] := background[2];
                    breakwidth[3] := background[3];
                    breakwidth[4] := background[4];
                    breakwidth[5] := background[5];
                    breakwidth[6] := background[6];
                    s := curp;
                    IF breaktype>0 THEN IF curp<>0 THEN{840:}
                                          BEGIN
                                            t := mem[curp].hh.b1;
                                            v := curp;
                                            s := mem[curp+1].hh.rh;
                                            WHILE t>0 DO
                                              BEGIN
                                                t := t-1;
                                                v := mem[v].hh.rh;
{841:}
                                                IF (v>=himemmin)THEN
                                                  BEGIN
                                                    f := mem[v].hh.b0;
                                                    breakwidth[1] := breakwidth[1]-fontinfo[
                                                                     widthbase[f]+fontinfo[charbase[
                                                                     f]+
                                                                     mem[v].hh.b1].qqqq.b0].int;
                                                  END
                                                ELSE CASE mem[v].hh.b0 OF 
                                                       6:
                                                          BEGIN
                                                            f := mem[v+1].hh.b0;
                                                            breakwidth[1] := breakwidth[1]-fontinfo[
                                                                             widthbase[f]+fontinfo[
                                                                             charbase[f]+
                                                                             mem[v+1].hh.b1].qqqq.b0
                                                                             ].int;
                                                          END;
                                                       0,1,2,11: breakwidth[1] := breakwidth[1]-mem[
                                                                                  v+1].int;
                                                       ELSE confusion(924)
                                                  END{:841};
                                              END;
                                            WHILE s<>0 DO
                                              BEGIN{842:}
                                                IF (s>=himemmin)THEN
                                                  BEGIN
                                                    f := mem[s].hh.b0;
                                                    breakwidth[1] := breakwidth[1]+fontinfo[
                                                                     widthbase[f]+fontinfo[charbase[
                                                                     f]+
                                                                     mem[s].hh.b1].qqqq.b0].int;
                                                  END
                                                ELSE CASE mem[s].hh.b0 OF 
                                                       6:
                                                          BEGIN
                                                            f := mem[s+1].hh.b0;
                                                            breakwidth[1] := breakwidth[1]+fontinfo[
                                                                             widthbase[f]+fontinfo[
                                                                             charbase[f]+
                                                                             mem[s+1].hh.b1].qqqq.b0
                                                                             ].int;
                                                          END;
                                                       0,1,2,11: breakwidth[1] := breakwidth[1]+mem[
                                                                                  s+1].int;
                                                       ELSE confusion(925)
                                                  END{:842};
                                                s := mem[s].hh.rh;
                                              END;
                                            breakwidth[1] := breakwidth[1]+discwidth;
                                            IF mem[curp+1].hh.rh=0 THEN s := mem[v].hh.rh;
                                          END{:840};
                    WHILE s<>0 DO
                      BEGIN
                        IF (s>=himemmin)THEN goto 30;
                        CASE mem[s].hh.b0 OF 
                          10:{838:}
                              BEGIN
                                v := mem[s+1].hh.lh;
                                breakwidth[1] := breakwidth[1]-mem[v+1].int;
                                breakwidth[2+mem[v].hh.b0] := breakwidth[2+mem[v].hh.b0]-mem[v+2].
                                                              int;
                                breakwidth[6] := breakwidth[6]-mem[v+3].int;
                              END{:838};
                          12:;
                          9: breakwidth[1] := breakwidth[1]-mem[s+1].int;
                          11: IF mem[s].hh.b1<>1 THEN goto 30
                              ELSE breakwidth[1] := breakwidth[1]-mem
                                                    [s+1].int;
                          ELSE goto 30
                        END;
                        s := mem[s].hh.rh;
                      END;
                    30:
                  END{:837};
{843:}
                IF mem[prevr].hh.b0=2 THEN
                  BEGIN
                    mem[prevr+1].int := mem[prevr+1].
                                        int-curactivewidth[1]+breakwidth[1];
                    mem[prevr+2].int := mem[prevr+2].int-curactivewidth[2]+breakwidth[2];
                    mem[prevr+3].int := mem[prevr+3].int-curactivewidth[3]+breakwidth[3];
                    mem[prevr+4].int := mem[prevr+4].int-curactivewidth[4]+breakwidth[4];
                    mem[prevr+5].int := mem[prevr+5].int-curactivewidth[5]+breakwidth[5];
                    mem[prevr+6].int := mem[prevr+6].int-curactivewidth[6]+breakwidth[6];
                  END
                ELSE IF prevr=29993 THEN
                       BEGIN
                         activewidth[1] := breakwidth[1];
                         activewidth[2] := breakwidth[2];
                         activewidth[3] := breakwidth[3];
                         activewidth[4] := breakwidth[4];
                         activewidth[5] := breakwidth[5];
                         activewidth[6] := breakwidth[6];
                       END
                ELSE
                  BEGIN
                    q := getnode(7);
                    mem[q].hh.rh := r;
                    mem[q].hh.b0 := 2;
                    mem[q].hh.b1 := 0;
                    mem[q+1].int := breakwidth[1]-curactivewidth[1];
                    mem[q+2].int := breakwidth[2]-curactivewidth[2];
                    mem[q+3].int := breakwidth[3]-curactivewidth[3];
                    mem[q+4].int := breakwidth[4]-curactivewidth[4];
                    mem[q+5].int := breakwidth[5]-curactivewidth[5];
                    mem[q+6].int := breakwidth[6]-curactivewidth[6];
                    mem[prevr].hh.rh := q;
                    prevprevr := prevr;
                    prevr := q;
                  END{:843};
                IF abs(eqtb[5279].int)>=1073741823-minimumdemerits THEN minimumdemerits 
                  := 1073741822
                ELSE minimumdemerits := minimumdemerits+abs(eqtb[5279].int);
                FOR fitclass:=0 TO 3 DO
                  BEGIN
                    IF minimaldemerits[fitclass]<=
                       minimumdemerits THEN{845:}
                      BEGIN
                        q := getnode(2);
                        mem[q].hh.rh := passive;
                        passive := q;
                        mem[q+1].hh.rh := curp;
                        passnumber := passnumber+1;
                        mem[q].hh.lh := passnumber;
                        mem[q+1].hh.lh := bestplace[fitclass];
                        q := getnode(3);
                        mem[q+1].hh.rh := passive;
                        mem[q+1].hh.lh := bestplline[fitclass]+1;
                        mem[q].hh.b1 := fitclass;
                        mem[q].hh.b0 := breaktype;
                        mem[q+2].int := minimaldemerits[fitclass];
                        mem[q].hh.rh := r;
                        mem[prevr].hh.rh := q;
                        prevr := q;
                        IF eqtb[5295].int>0 THEN{846:}
                          BEGIN
                            printnl(926);
                            printint(mem[passive].hh.lh);
                            print(927);
                            printint(mem[q+1].hh.lh-1);
                            printchar(46);
                            printint(fitclass);
                            IF breaktype=1 THEN printchar(45);
                            print(928);
                            printint(mem[q+2].int);
                            print(929);
                            IF mem[passive+1].hh.lh=0 THEN printchar(48)
                            ELSE printint(mem[mem[
                                          passive+1].hh.lh].hh.lh);
                          END{:846};
                      END{:845};
                    minimaldemerits[fitclass] := 1073741823;
                  END;
                minimumdemerits := 1073741823;
{844:}
                IF r<>29993 THEN
                  BEGIN
                    q := getnode(7);
                    mem[q].hh.rh := r;
                    mem[q].hh.b0 := 2;
                    mem[q].hh.b1 := 0;
                    mem[q+1].int := curactivewidth[1]-breakwidth[1];
                    mem[q+2].int := curactivewidth[2]-breakwidth[2];
                    mem[q+3].int := curactivewidth[3]-breakwidth[3];
                    mem[q+4].int := curactivewidth[4]-breakwidth[4];
                    mem[q+5].int := curactivewidth[5]-breakwidth[5];
                    mem[q+6].int := curactivewidth[6]-breakwidth[6];
                    mem[prevr].hh.rh := q;
                    prevprevr := prevr;
                    prevr := q;
                  END{:844};
              END{:836};
            IF r=29993 THEN goto 10;
{850:}
            IF l>easyline THEN
              BEGIN
                linewidth := secondwidth;
                oldl := 65534;
              END
            ELSE
              BEGIN
                oldl := l;
                IF l>lastspecialline THEN linewidth := secondwidth
                ELSE IF eqtb[3412].hh.
                        rh=0 THEN linewidth := firstwidth
                ELSE linewidth := mem[eqtb[3412].hh.rh+2*l
                                  ].int;
              END{:850};
          END;
      END{:835};{851:}
      BEGIN
        artificialdemerits := false;
        shortfall := linewidth-curactivewidth[1];
        IF shortfall>0 THEN{852:}IF (curactivewidth[3]<>0)OR(curactivewidth[4]<>0
                                    )OR(curactivewidth[5]<>0)THEN
                                   BEGIN
                                     b := 0;
                                     fitclass := 2;
                                   END
        ELSE
          BEGIN
            IF shortfall>7230584 THEN IF curactivewidth[2]<1663497
                                        THEN
                                        BEGIN
                                          b := 10000;
                                          fitclass := 0;
                                          goto 31;
                                        END;
            b := badness(shortfall,curactivewidth[2]);
            IF b>12 THEN IF b>99 THEN fitclass := 0
            ELSE fitclass := 1
            ELSE fitclass := 2;
            31:
          END{:852}
        ELSE{853:}
          BEGIN
            IF -shortfall>curactivewidth[6]THEN b := 10001
            ELSE b := badness(-shortfall,curactivewidth[6]);
            IF b>12 THEN fitclass := 3
            ELSE fitclass := 2;
          END{:853};
        IF (b>10000)OR(pi=-10000)THEN{854:}
          BEGIN
            IF finalpass AND(minimumdemerits
               =1073741823)AND(mem[r].hh.rh=29993)AND(prevr=29993)THEN
              artificialdemerits := true
            ELSE IF b>threshold THEN goto 60;
            noderstaysactive := false;
          END{:854}
        ELSE
          BEGIN
            prevr := r;
            IF b>threshold THEN goto 22;
            noderstaysactive := true;
          END;
{855:}
        IF artificialdemerits THEN d := 0
        ELSE{859:}
          BEGIN
            d := eqtb[5265].int+
                 b;
            IF abs(d)>=10000 THEN d := 100000000
            ELSE d := d*d;
            IF pi<>0 THEN IF pi>0 THEN d := d+pi*pi
            ELSE IF pi>-10000 THEN d := d-pi*pi;
            IF (breaktype=1)AND(mem[r].hh.b0=1)THEN IF curp<>0 THEN d := d+eqtb[5277].
                                                                         int
            ELSE d := d+eqtb[5278].int;
            IF abs(fitclass-mem[r].hh.b1)>1 THEN d := d+eqtb[5279].int;
          END{:859};
        IF eqtb[5295].int>0 THEN{856:}
          BEGIN
            IF printednode<>curp THEN{857:}
              BEGIN
                printnl(338);
                IF curp=0 THEN shortdisplay(mem[printednode].hh.rh)
                ELSE
                  BEGIN
                    savelink := 
                                mem[curp].hh.rh;
                    mem[curp].hh.rh := 0;
                    printnl(338);
                    shortdisplay(mem[printednode].hh.rh);
                    mem[curp].hh.rh := savelink;
                  END;
                printednode := curp;
              END{:857};
            printnl(64);
            IF curp=0 THEN printesc(597)
            ELSE IF mem[curp].hh.b0<>10 THEN
                   BEGIN
                     IF 
                        mem[curp].hh.b0=12 THEN printesc(531)
                     ELSE IF mem[curp].hh.b0=7 THEN
                            printesc(349)
                     ELSE IF mem[curp].hh.b0=11 THEN printesc(340)
                     ELSE printesc(
                                   343);
                   END;
            print(930);
            IF mem[r+1].hh.rh=0 THEN printchar(48)
            ELSE printint(mem[mem[r+1].hh.rh].
                          hh.lh);
            print(931);
            IF b>10000 THEN printchar(42)
            ELSE printint(b);
            print(932);
            printint(pi);
            print(933);
            IF artificialdemerits THEN printchar(42)
            ELSE printint(d);
          END{:856};
        d := d+mem[r+2].int;
        IF d<=minimaldemerits[fitclass]THEN
          BEGIN
            minimaldemerits[fitclass] := d;
            bestplace[fitclass] := mem[r+1].hh.rh;
            bestplline[fitclass] := l;
            IF d<minimumdemerits THEN minimumdemerits := d;
          END{:855};
        IF noderstaysactive THEN goto 22;
        60:{860:}mem[prevr].hh.rh := mem[r].hh.rh;
        freenode(r,3);
        IF prevr=29993 THEN{861:}
          BEGIN
            r := mem[29993].hh.rh;
            IF mem[r].hh.b0=2 THEN
              BEGIN
                activewidth[1] := activewidth[1]+mem[r+1].int
                ;
                activewidth[2] := activewidth[2]+mem[r+2].int;
                activewidth[3] := activewidth[3]+mem[r+3].int;
                activewidth[4] := activewidth[4]+mem[r+4].int;
                activewidth[5] := activewidth[5]+mem[r+5].int;
                activewidth[6] := activewidth[6]+mem[r+6].int;
                curactivewidth[1] := activewidth[1];
                curactivewidth[2] := activewidth[2];
                curactivewidth[3] := activewidth[3];
                curactivewidth[4] := activewidth[4];
                curactivewidth[5] := activewidth[5];
                curactivewidth[6] := activewidth[6];
                mem[29993].hh.rh := mem[r].hh.rh;
                freenode(r,7);
              END;
          END{:861}
        ELSE IF mem[prevr].hh.b0=2 THEN
               BEGIN
                 r := mem[prevr].hh.rh;
                 IF r=29993 THEN
                   BEGIN
                     curactivewidth[1] := curactivewidth[1]-mem[prevr+1].
                                          int;
                     curactivewidth[2] := curactivewidth[2]-mem[prevr+2].int;
                     curactivewidth[3] := curactivewidth[3]-mem[prevr+3].int;
                     curactivewidth[4] := curactivewidth[4]-mem[prevr+4].int;
                     curactivewidth[5] := curactivewidth[5]-mem[prevr+5].int;
                     curactivewidth[6] := curactivewidth[6]-mem[prevr+6].int;
                     mem[prevprevr].hh.rh := 29993;
                     freenode(prevr,7);
                     prevr := prevprevr;
                   END
                 ELSE IF mem[r].hh.b0=2 THEN
                        BEGIN
                          curactivewidth[1] := curactivewidth[
                                               1]+mem[r+1].int;
                          curactivewidth[2] := curactivewidth[2]+mem[r+2].int;
                          curactivewidth[3] := curactivewidth[3]+mem[r+3].int;
                          curactivewidth[4] := curactivewidth[4]+mem[r+4].int;
                          curactivewidth[5] := curactivewidth[5]+mem[r+5].int;
                          curactivewidth[6] := curactivewidth[6]+mem[r+6].int;
                          mem[prevr+1].int := mem[prevr+1].int+mem[r+1].int;
                          mem[prevr+2].int := mem[prevr+2].int+mem[r+2].int;
                          mem[prevr+3].int := mem[prevr+3].int+mem[r+3].int;
                          mem[prevr+4].int := mem[prevr+4].int+mem[r+4].int;
                          mem[prevr+5].int := mem[prevr+5].int+mem[r+5].int;
                          mem[prevr+6].int := mem[prevr+6].int+mem[r+6].int;
                          mem[prevr].hh.rh := mem[r].hh.rh;
                          freenode(r,7);
                        END;
               END{:860};
      END{:851};
    END;
  10:{858:}IF curp=printednode THEN IF curp<>0 THEN IF mem[curp].hh.b0=7
                                                      THEN
                                                      BEGIN
                                                        t := mem[curp].hh.b1;
                                                        WHILE t>0 DO
                                                          BEGIN
                                                            t := t-1;
                                                            printednode := mem[printednode].hh.rh;
                                                          END;
                                                      END{:858}
END;
{:829}{877:}
PROCEDURE postlinebreak(finalwidowpenalty:integer;
                        nonprunablep:halfword);

LABEL 30,31;

VAR q,r,s: halfword;
  discbreak: boolean;
  postdiscbreak: boolean;
  curwidth: scaled;
  curindent: scaled;
  t: quarterword;
  pen: integer;
  curline: halfword;
BEGIN{878:}
  q := mem[bestbet+1].hh.rh;
  curp := 0;
  REPEAT
    r := q;
    q := mem[q+1].hh.lh;
    mem[r+1].hh.lh := curp;
    curp := r;
  UNTIL q=0{:878};
  curline := curlist.pgfield+1;
  REPEAT{880:}{881:}
    q := mem[curp+1].hh.rh;
    discbreak := false;
    postdiscbreak := false;
    IF q<>0 THEN IF mem[q].hh.b0=10 THEN
                   BEGIN
                     deleteglueref(mem[q+1].hh.lh)
                     ;
                     mem[q+1].hh.lh := eqtb[2890].hh.rh;
                     mem[q].hh.b1 := 9;
                     mem[eqtb[2890].hh.rh].hh.rh := mem[eqtb[2890].hh.rh].hh.rh+1;
                     goto 30;
                   END
    ELSE
      BEGIN
        IF mem[q].hh.b0=7 THEN{882:}
          BEGIN
            t := mem[q].hh.b1;
{883:}
            IF t=0 THEN r := mem[q].hh.rh
            ELSE
              BEGIN
                r := q;
                WHILE t>1 DO
                  BEGIN
                    r := mem[r].hh.rh;
                    t := t-1;
                  END;
                s := mem[r].hh.rh;
                r := mem[s].hh.rh;
                mem[s].hh.rh := 0;
                flushnodelist(mem[q].hh.rh);
                mem[q].hh.b1 := 0;
              END{:883};
            IF mem[q+1].hh.rh<>0 THEN{884:}
              BEGIN
                s := mem[q+1].hh.rh;
                WHILE mem[s].hh.rh<>0 DO
                  s := mem[s].hh.rh;
                mem[s].hh.rh := r;
                r := mem[q+1].hh.rh;
                mem[q+1].hh.rh := 0;
                postdiscbreak := true;
              END{:884};
            IF mem[q+1].hh.lh<>0 THEN{885:}
              BEGIN
                s := mem[q+1].hh.lh;
                mem[q].hh.rh := s;
                WHILE mem[s].hh.rh<>0 DO
                  s := mem[s].hh.rh;
                mem[q+1].hh.lh := 0;
                q := s;
              END{:885};
            mem[q].hh.rh := r;
            discbreak := true;
          END{:882}
        ELSE IF (mem[q].hh.b0=9)OR(mem[q].hh.b0=11)THEN mem[q+1].int := 0;
      END
    ELSE
      BEGIN
        q := 29997;
        WHILE mem[q].hh.rh<>0 DO
          q := mem[q].hh.rh;
      END;
{886:}
    r := newparamglue(8);
    mem[r].hh.rh := mem[q].hh.rh;
    mem[q].hh.rh := r;
    q := r{:886};
    30:{:881};{887:}
    r := mem[q].hh.rh;
    mem[q].hh.rh := 0;
    q := mem[29997].hh.rh;
    mem[29997].hh.rh := r;
    IF eqtb[2889].hh.rh<>0 THEN
      BEGIN
        r := newparamglue(7);
        mem[r].hh.rh := q;
        q := r;
      END{:887};
{889:}
    IF curline>lastspecialline THEN
      BEGIN
        curwidth := secondwidth;
        curindent := secondindent;
      END
    ELSE IF eqtb[3412].hh.rh=0 THEN
           BEGIN
             curwidth := firstwidth;
             curindent := firstindent;
           END
    ELSE
      BEGIN
        curwidth := mem[eqtb[3412].hh.rh+2*curline].int;
        curindent := mem[eqtb[3412].hh.rh+2*curline-1].int;
      END;
    adjusttail := 29995;
    justbox := hpack(q,curwidth,0);
    mem[justbox+4].int := curindent{:889};
{888:}
    appendtovlist(justbox);
    IF 29995<>adjusttail THEN
      BEGIN
        mem[curlist.tailfield].hh.rh := mem[29995]
                                        .hh.rh;
        curlist.tailfield := adjusttail;
      END;
    adjusttail := 0{:888};
{890:}
    IF curline+1<>bestline THEN
      BEGIN
        pen := eqtb[5276].int;
        IF curline=curlist.pgfield+1 THEN pen := pen+eqtb[5268].int;
        IF curline+2=bestline THEN pen := pen+finalwidowpenalty;
        IF discbreak THEN pen := pen+eqtb[5271].int;
        IF pen<>0 THEN
          BEGIN
            r := newpenalty(pen);
            mem[curlist.tailfield].hh.rh := r;
            curlist.tailfield := r;
          END;
      END{:890}{:880};
    curline := curline+1;
    curp := mem[curp+1].hh.lh;
    IF curp<>0 THEN IF NOT postdiscbreak THEN{879:}
                      BEGIN
                        r := 29997;
                        WHILE true DO
                          BEGIN
                            q := mem[r].hh.rh;
                            IF q=mem[curp+1].hh.rh THEN goto 31;
                            IF (q>=himemmin)THEN goto 31;
                            IF (mem[q].hh.b0<9)THEN goto 31;
                            IF q=nonprunablep THEN goto 31;
                            IF mem[q].hh.b0=11 THEN IF mem[q].hh.b1<>1 THEN goto 31;
                            r := q;
                          END;
                        31: IF r<>29997 THEN
                              BEGIN
                                mem[r].hh.rh := 0;
                                flushnodelist(mem[29997].hh.rh);
                                mem[29997].hh.rh := q;
                              END;
                      END{:879};
  UNTIL curp=0;
  IF (curline<>bestline)OR(mem[29997].hh.rh<>0)THEN confusion(940);
  curlist.pgfield := bestline-1;
END;
{:877}{895:}{906:}
FUNCTION reconstitute(j,n:smallnumber;
                      bchar,hchar:halfword): smallnumber;

LABEL 22,30;

VAR p: halfword;
  t: halfword;
  q: fourquarters;
  currh: halfword;
  testchar: halfword;
  w: scaled;
  k: fontindex;
BEGIN
  hyphenpassed := 0;
  t := 29996;
  w := 0;
  mem[29996].hh.rh := 0;
{908:}
  curl := hu[j];
  curq := t;
  IF j=0 THEN
    BEGIN
      ligaturepresent := initlig;
      p := initlist;
      IF ligaturepresent THEN lfthit := initlft;
      WHILE p>0 DO
        BEGIN
          BEGIN
            mem[t].hh.rh := getavail;
            t := mem[t].hh.rh;
            mem[t].hh.b0 := hf;
            mem[t].hh.b1 := mem[p].hh.b1;
          END;
          p := mem[p].hh.rh;
        END;
    END
  ELSE IF curl<256 THEN
         BEGIN
           mem[t].hh.rh := getavail;
           t := mem[t].hh.rh;
           mem[t].hh.b0 := hf;
           mem[t].hh.b1 := curl;
         END;
  ligstack := 0;
  BEGIN
    IF j<n THEN curr := hu[j+1]
    ELSE curr := bchar;
    IF odd(hyf[j])THEN currh := hchar
    ELSE currh := 256;
  END{:908};
  22:{909:}IF curl=256 THEN
             BEGIN
               k := bcharlabel[hf];
               IF k=0 THEN goto 30
               ELSE q := fontinfo[k].qqqq;
             END
      ELSE
        BEGIN
          q := fontinfo[charbase[hf]+curl].qqqq;
          IF ((q.b2)MOD 4)<>1 THEN goto 30;
          k := ligkernbase[hf]+q.b3;
          q := fontinfo[k].qqqq;
          IF q.b0>128 THEN
            BEGIN
              k := ligkernbase[hf]+256*q.b2+q.b3+32768-256*(128);
              q := fontinfo[k].qqqq;
            END;
        END;
  IF currh<256 THEN testchar := currh
  ELSE testchar := curr;
  WHILE true DO
    BEGIN
      IF q.b1=testchar THEN IF q.b0<=128 THEN IF currh<256
                                                THEN
                                                BEGIN
                                                  hyphenpassed := j;
                                                  hchar := 256;
                                                  currh := 256;
                                                  goto 22;
                                                END
      ELSE
        BEGIN
          IF hchar<256 THEN IF odd(hyf[j])THEN
                              BEGIN
                                hyphenpassed := 
                                                j;
                                hchar := 256;
                              END;
          IF q.b2<128 THEN{911:}
            BEGIN
              IF curl=256 THEN lfthit := true;
              IF j=n THEN IF ligstack=0 THEN rthit := true;
              BEGIN
                IF interrupt<>0 THEN pauseforinstructions;
              END;
              CASE q.b2 OF 
                1,5:
                     BEGIN
                       curl := q.b3;
                       ligaturepresent := true;
                     END;
                2,6:
                     BEGIN
                       curr := q.b3;
                       IF ligstack>0 THEN mem[ligstack].hh.b1 := curr
                       ELSE
                         BEGIN
                           ligstack := 
                                       newligitem(curr);
                           IF j=n THEN bchar := 256
                           ELSE
                             BEGIN
                               p := getavail;
                               mem[ligstack+1].hh.rh := p;
                               mem[p].hh.b1 := hu[j+1];
                               mem[p].hh.b0 := hf;
                             END;
                         END;
                     END;
                3:
                   BEGIN
                     curr := q.b3;
                     p := ligstack;
                     ligstack := newligitem(curr);
                     mem[ligstack].hh.rh := p;
                   END;
                7,11:
                      BEGIN
                        IF ligaturepresent THEN
                          BEGIN
                            p := newligature(hf,curl,mem[curq
                                 ].hh.rh);
                            IF lfthit THEN
                              BEGIN
                                mem[p].hh.b1 := 2;
                                lfthit := false;
                              END;
                            IF false THEN IF ligstack=0 THEN
                                            BEGIN
                                              mem[p].hh.b1 := mem[p].hh.b1+1;
                                              rthit := false;
                                            END;
                            mem[curq].hh.rh := p;
                            t := p;
                            ligaturepresent := false;
                          END;
                        curq := t;
                        curl := q.b3;
                        ligaturepresent := true;
                      END;
                ELSE
                  BEGIN
                    curl := q.b3;
                    ligaturepresent := true;
                    IF ligstack>0 THEN
                      BEGIN
                        IF mem[ligstack+1].hh.rh>0 THEN
                          BEGIN
                            mem[t].hh
                            .rh := mem[ligstack+1].hh.rh;
                            t := mem[t].hh.rh;
                            j := j+1;
                          END;
                        p := ligstack;
                        ligstack := mem[p].hh.rh;
                        freenode(p,2);
                        IF ligstack=0 THEN
                          BEGIN
                            IF j<n THEN curr := hu[j+1]
                            ELSE curr := bchar;
                            IF odd(hyf[j])THEN currh := hchar
                            ELSE currh := 256;
                          END
                        ELSE curr := mem[ligstack].hh.b1;
                      END
                    ELSE IF j=n THEN goto 30
                    ELSE
                      BEGIN
                        BEGIN
                          mem[t].hh.rh := getavail;
                          t := mem[t].hh.rh;
                          mem[t].hh.b0 := hf;
                          mem[t].hh.b1 := curr;
                        END;
                        j := j+1;
                        BEGIN
                          IF j<n THEN curr := hu[j+1]
                          ELSE curr := bchar;
                          IF odd(hyf[j])THEN currh := hchar
                          ELSE currh := 256;
                        END;
                      END;
                  END
              END;
              IF q.b2>4 THEN IF q.b2<>7 THEN goto 30;
              goto 22;
            END{:911};
          w := fontinfo[kernbase[hf]+256*q.b2+q.b3].int;
          goto 30;
        END;
      IF q.b0>=128 THEN IF currh=256 THEN goto 30
      ELSE
        BEGIN
          currh := 256;
          goto 22;
        END;
      k := k+q.b0+1;
      q := fontinfo[k].qqqq;
    END;
  30:{:909};
{910:}
  IF ligaturepresent THEN
    BEGIN
      p := newligature(hf,curl,mem[curq].hh.
           rh);
      IF lfthit THEN
        BEGIN
          mem[p].hh.b1 := 2;
          lfthit := false;
        END;
      IF rthit THEN IF ligstack=0 THEN
                      BEGIN
                        mem[p].hh.b1 := mem[p].hh.b1+1;
                        rthit := false;
                      END;
      mem[curq].hh.rh := p;
      t := p;
      ligaturepresent := false;
    END;
  IF w<>0 THEN
    BEGIN
      mem[t].hh.rh := newkern(w);
      t := mem[t].hh.rh;
      w := 0;
    END;
  IF ligstack>0 THEN
    BEGIN
      curq := t;
      curl := mem[ligstack].hh.b1;
      ligaturepresent := true;
      BEGIN
        IF mem[ligstack+1].hh.rh>0 THEN
          BEGIN
            mem[t].hh.rh := mem[ligstack+1
                            ].hh.rh;
            t := mem[t].hh.rh;
            j := j+1;
          END;
        p := ligstack;
        ligstack := mem[p].hh.rh;
        freenode(p,2);
        IF ligstack=0 THEN
          BEGIN
            IF j<n THEN curr := hu[j+1]
            ELSE curr := bchar;
            IF odd(hyf[j])THEN currh := hchar
            ELSE currh := 256;
          END
        ELSE curr := mem[ligstack].hh.b1;
      END;
      goto 22;
    END{:910};
  reconstitute := j;
END;{:906}
PROCEDURE hyphenate;

LABEL 50,30,40,41,42,45,10;

VAR {901:}i,j,l: 0..65;
  q,r,s: halfword;
  bchar: halfword;{:901}{912:}
  majortail,minortail: halfword;
  c: ASCIIcode;
  cloc: 0..63;
  rcount: integer;
  hyfnode: halfword;{:912}{922:}
  z: triepointer;
  v: integer;{:922}{929:}
  h: hyphpointer;
  k: strnumber;
  u: poolpointer;
{:929}
BEGIN{923:}
  FOR j:=0 TO hn DO
    hyf[j] := 0;{930:}
  h := hc[1];
  hn := hn+1;
  hc[hn] := curlang;
  FOR j:=2 TO hn DO
    h := (h+h+hc[j])MOD 307;
  WHILE true DO
    BEGIN{931:}
      k := hyphword[h];
      IF k=0 THEN goto 45;
      IF (strstart[k+1]-strstart[k])<hn THEN goto 45;
      IF (strstart[k+1]-strstart[k])=hn THEN
        BEGIN
          j := 1;
          u := strstart[k];
          REPEAT
            IF strpool[u]<hc[j]THEN goto 45;
            IF strpool[u]>hc[j]THEN goto 30;
            j := j+1;
            u := u+1;
          UNTIL j>hn;{932:}
          s := hyphlist[h];
          WHILE s<>0 DO
            BEGIN
              hyf[mem[s].hh.lh] := 1;
              s := mem[s].hh.rh;
            END{:932};
          hn := hn-1;
          goto 40;
        END;
      30:{:931};
      IF h>0 THEN h := h-1
      ELSE h := 307;
    END;
  45: hn := hn-1{:930};
  IF trie[curlang+1].b1<>curlang THEN goto 10;
  hc[0] := 0;
  hc[hn+1] := 0;
  hc[hn+2] := 256;
  FOR j:=0 TO hn-rhyf+1 DO
    BEGIN
      z := trie[curlang+1].rh+hc[j];
      l := j;
      WHILE hc[l]=trie[z].b1 DO
        BEGIN
          IF trie[z].b0<>0 THEN{924:}
            BEGIN
              v := trie
                   [z].b0;
              REPEAT
                v := v+opstart[curlang];
                i := l-hyfdistance[v];
                IF hyfnum[v]>hyf[i]THEN hyf[i] := hyfnum[v];
                v := hyfnext[v];
              UNTIL v=0;
            END{:924};
          l := l+1;
          z := trie[z].rh+hc[l];
        END;
    END;
  40: FOR j:=0 TO lhyf-1 DO
        hyf[j] := 0;
  FOR j:=0 TO rhyf-1 DO
    hyf[hn-j] := 0{:923};
{902:}
  FOR j:=lhyf TO hn-rhyf DO
    IF odd(hyf[j])THEN goto 41;
  goto 10;
  41:{:902};{903:}
  q := mem[hb].hh.rh;
  mem[hb].hh.rh := 0;
  r := mem[ha].hh.rh;
  mem[ha].hh.rh := 0;
  bchar := hyfbchar;
  IF (ha>=himemmin)THEN IF mem[ha].hh.b0<>hf THEN goto 42
  ELSE
    BEGIN
      initlist := ha;
      initlig := false;
      hu[0] := mem[ha].hh.b1;
    END
  ELSE IF mem[ha].hh.b0=6 THEN IF mem[ha+1].hh.b0<>hf THEN goto 42
  ELSE
    BEGIN
      initlist := mem[ha+1].hh.rh;
      initlig := true;
      initlft := (mem[ha].hh.b1>1);
      hu[0] := mem[ha+1].hh.b1;
      IF initlist=0 THEN IF initlft THEN
                           BEGIN
                             hu[0] := 256;
                             initlig := false;
                           END;
      freenode(ha,2);
    END
  ELSE
    BEGIN
      IF NOT(r>=himemmin)THEN IF mem[r].hh.b0=6 THEN IF mem[r].
                                                        hh.b1>1 THEN goto 42;
      j := 1;
      s := ha;
      initlist := 0;
      goto 50;
    END;
  s := curp;
  WHILE mem[s].hh.rh<>ha DO
    s := mem[s].hh.rh;
  j := 0;
  goto 50;
  42: s := ha;
  j := 0;
  hu[0] := 256;
  initlig := false;
  initlist := 0;
  50: flushnodelist(r);
{913:}
  REPEAT
    l := j;
    j := reconstitute(j,hn,bchar,hyfchar)+1;
    IF hyphenpassed=0 THEN
      BEGIN
        mem[s].hh.rh := mem[29996].hh.rh;
        WHILE mem[s].hh.rh>0 DO
          s := mem[s].hh.rh;
        IF odd(hyf[j-1])THEN
          BEGIN
            l := j;
            hyphenpassed := j-1;
            mem[29996].hh.rh := 0;
          END;
      END;
    IF hyphenpassed>0 THEN{914:}REPEAT
                                  r := getnode(2);
                                  mem[r].hh.rh := mem[29996].hh.rh;
                                  mem[r].hh.b0 := 7;
                                  majortail := r;
                                  rcount := 0;
                                  WHILE mem[majortail].hh.rh>0 DO
                                    BEGIN
                                      majortail := mem[majortail].hh.rh;
                                      rcount := rcount+1;
                                    END;
                                  i := hyphenpassed;
                                  hyf[i] := 0;{915:}
                                  minortail := 0;
                                  mem[r+1].hh.lh := 0;
                                  hyfnode := newcharacter(hf,hyfchar);
                                  IF hyfnode<>0 THEN
                                    BEGIN
                                      i := i+1;
                                      c := hu[i];
                                      hu[i] := hyfchar;
                                      BEGIN
                                        mem[hyfnode].hh.rh := avail;
                                        avail := hyfnode;
                                        dynused := dynused-1;
                                      END;
                                    END;
                                  WHILE l<=i DO
                                    BEGIN
                                      l := reconstitute(l,i,fontbchar[hf],256)+1;
                                      IF mem[29996].hh.rh>0 THEN
                                        BEGIN
                                          IF minortail=0 THEN mem[r+1].hh.lh := mem
                                                                                [29996].hh.rh
                                          ELSE mem[minortail].hh.rh := mem[29996].hh.rh;
                                          minortail := mem[29996].hh.rh;
                                          WHILE mem[minortail].hh.rh>0 DO
                                            minortail := mem[minortail].hh.rh;
                                        END;
                                    END;
                                  IF hyfnode<>0 THEN
                                    BEGIN
                                      hu[i] := c;
                                      l := i;
                                      i := i-1;
                                    END{:915};
{916:}
                                  minortail := 0;
                                  mem[r+1].hh.rh := 0;
                                  cloc := 0;
                                  IF bcharlabel[hf]<>0 THEN
                                    BEGIN
                                      l := l-1;
                                      c := hu[l];
                                      cloc := l;
                                      hu[l] := 256;
                                    END;
                                  WHILE l<j DO
                                    BEGIN
                                      REPEAT
                                        l := reconstitute(l,hn,bchar,256)+1;
                                        IF cloc>0 THEN
                                          BEGIN
                                            hu[cloc] := c;
                                            cloc := 0;
                                          END;
                                        IF mem[29996].hh.rh>0 THEN
                                          BEGIN
                                            IF minortail=0 THEN mem[r+1].hh.rh := mem
                                                                                  [29996].hh.rh
                                            ELSE mem[minortail].hh.rh := mem[29996].hh.rh;
                                            minortail := mem[29996].hh.rh;
                                            WHILE mem[minortail].hh.rh>0 DO
                                              minortail := mem[minortail].hh.rh;
                                          END;
                                      UNTIL l>=j;
                                      WHILE l>j DO{917:}
                                        BEGIN
                                          j := reconstitute(j,hn,bchar,256)+1;
                                          mem[majortail].hh.rh := mem[29996].hh.rh;
                                          WHILE mem[majortail].hh.rh>0 DO
                                            BEGIN
                                              majortail := mem[majortail].hh.rh;
                                              rcount := rcount+1;
                                            END;
                                        END{:917};
                                    END{:916};
{918:}
                                  IF rcount>127 THEN
                                    BEGIN
                                      mem[s].hh.rh := mem[r].hh.rh;
                                      mem[r].hh.rh := 0;
                                      flushnodelist(r);
                                    END
                                  ELSE
                                    BEGIN
                                      mem[s].hh.rh := r;
                                      mem[r].hh.b1 := rcount;
                                    END;
                                  s := majortail{:918};
                                  hyphenpassed := j-1;
                                  mem[29996].hh.rh := 0;
      UNTIL NOT odd(hyf[j-1]){:914};
  UNTIL j>hn;
  mem[s].hh.rh := q{:913};
  flushlist(initlist){:903};
  10:
END;
{:895}{942:}{944:}
FUNCTION newtrieop(d,n:smallnumber;
                   v:quarterword): quarterword;

LABEL 10;

VAR h: -trieopsize..trieopsize;
  u: quarterword;
  l: 0..trieopsize;
BEGIN
  h := abs(n+313*d+361*v+1009*curlang)MOD(trieopsize+trieopsize)-
       trieopsize;
  WHILE true DO
    BEGIN
      l := trieophash[h];
      IF l=0 THEN
        BEGIN
          IF trieopptr=trieopsize THEN overflow(950,trieopsize);
          u := trieused[curlang];
          IF u=255 THEN overflow(951,255);
          trieopptr := trieopptr+1;
          u := u+1;
          trieused[curlang] := u;
          hyfdistance[trieopptr] := d;
          hyfnum[trieopptr] := n;
          hyfnext[trieopptr] := v;
          trieoplang[trieopptr] := curlang;
          trieophash[h] := trieopptr;
          trieopval[trieopptr] := u;
          newtrieop := u;
          goto 10;
        END;
      IF (hyfdistance[l]=d)AND(hyfnum[l]=n)AND(hyfnext[l]=v)AND(trieoplang[l]=
         curlang)THEN
        BEGIN
          newtrieop := trieopval[l];
          goto 10;
        END;
      IF h>-trieopsize THEN h := h-1
      ELSE h := trieopsize;
    END;
  10:
END;
{:944}{948:}
FUNCTION trienode(p:triepointer): triepointer;

LABEL 10;

VAR h: triepointer;
  q: triepointer;
BEGIN
  h := abs(triec[p]+1009*trieo[p]+2718*triel[p]+3142*trier[p])MOD
       triesize;
  WHILE true DO
    BEGIN
      q := triehash[h];
      IF q=0 THEN
        BEGIN
          triehash[h] := p;
          trienode := p;
          goto 10;
        END;
      IF (triec[q]=triec[p])AND(trieo[q]=trieo[p])AND(triel[q]=triel[p])AND(
         trier[q]=trier[p])THEN
        BEGIN
          trienode := q;
          goto 10;
        END;
      IF h>0 THEN h := h-1
      ELSE h := triesize;
    END;
  10:
END;
{:948}{949:}
FUNCTION compresstrie(p:triepointer): triepointer;
BEGIN
  IF p=0 THEN compresstrie := 0
  ELSE
    BEGIN
      triel[p] := compresstrie(
                  triel[p]);
      trier[p] := compresstrie(trier[p]);
      compresstrie := trienode(p);
    END;
END;{:949}{953:}
PROCEDURE firstfit(p:triepointer);

LABEL 45,40;

VAR h: triepointer;
  z: triepointer;
  q: triepointer;
  c: ASCIIcode;
  l,r: triepointer;
  ll: 1..256;
BEGIN
  c := triec[p];
  z := triemin[c];
  WHILE true DO
    BEGIN
      h := z-c;
{954:}
      IF triemax<h+256 THEN
        BEGIN
          IF triesize<=h+256 THEN overflow(952,
                                           triesize);
          REPEAT
            triemax := triemax+1;
            trietaken[triemax] := false;
            trie[triemax].rh := triemax+1;
            trie[triemax].lh := triemax-1;
          UNTIL triemax=h+256;
        END{:954};
      IF trietaken[h]THEN goto 45;
{955:}
      q := trier[p];
      WHILE q>0 DO
        BEGIN
          IF trie[h+triec[q]].rh=0 THEN goto 45;
          q := trier[q];
        END;
      goto 40{:955};
      45: z := trie[z].rh;
    END;
  40:{956:}trietaken[h] := true;
  triehash[p] := h;
  q := p;
  REPEAT
    z := h+triec[q];
    l := trie[z].lh;
    r := trie[z].rh;
    trie[r].lh := l;
    trie[l].rh := r;
    trie[z].rh := 0;
    IF l<256 THEN
      BEGIN
        IF z<256 THEN ll := z
        ELSE ll := 256;
        REPEAT
          triemin[l] := r;
          l := l+1;
        UNTIL l=ll;
      END;
    q := trier[q];
  UNTIL q=0{:956};
END;{:953}{957:}
PROCEDURE triepack(p:triepointer);

VAR q: triepointer;
BEGIN
  REPEAT
    q := triel[p];
    IF (q>0)AND(triehash[q]=0)THEN
      BEGIN
        firstfit(q);
        triepack(q);
      END;
    p := trier[p];
  UNTIL p=0;
END;{:957}{959:}
PROCEDURE triefix(p:triepointer);

VAR q: triepointer;
  c: ASCIIcode;
  z: triepointer;
BEGIN
  z := triehash[p];
  REPEAT
    q := triel[p];
    c := triec[p];
    trie[z+c].rh := triehash[q];
    trie[z+c].b1 := c;
    trie[z+c].b0 := trieo[p];
    IF q>0 THEN triefix(q);
    p := trier[p];
  UNTIL p=0;
END;{:959}{960:}
PROCEDURE newpatterns;

LABEL 30,31;

VAR k,l: 0..64;
  digitsensed: boolean;
  v: quarterword;
  p,q: triepointer;
  firstchild: boolean;
  c: ASCIIcode;
BEGIN
  IF trienotready THEN
    BEGIN
      IF eqtb[5313].int<=0 THEN curlang := 0
      ELSE IF eqtb[5313].int>255 THEN curlang := 0
      ELSE curlang := eqtb[5313].int;
      scanleftbrace;{961:}
      k := 0;
      hyf[0] := 0;
      digitsensed := false;
      WHILE true DO
        BEGIN
          getxtoken;
          CASE curcmd OF 
            11,12:{962:}IF digitsensed OR(curchr<48)OR(curchr>57)THEN
                          BEGIN
                            IF curchr=46 THEN curchr := 0
                            ELSE
                              BEGIN
                                curchr := eqtb[4239+curchr].
                                          hh.rh;
                                IF curchr=0 THEN
                                  BEGIN
                                    BEGIN
                                      IF interaction=3 THEN;
                                      printnl(262);
                                      print(958);
                                    END;
                                    BEGIN
                                      helpptr := 1;
                                      helpline[0] := 957;
                                    END;
                                    error;
                                  END;
                              END;
                            IF k<63 THEN
                              BEGIN
                                k := k+1;
                                hc[k] := curchr;
                                hyf[k] := 0;
                                digitsensed := false;
                              END;
                          END
                   ELSE IF k<63 THEN
                          BEGIN
                            hyf[k] := curchr-48;
                            digitsensed := true;
                          END{:962};
            10,2:
                  BEGIN
                    IF k>0 THEN{963:}
                      BEGIN{965:}
                        IF hc[1]=0 THEN hyf[0] := 0;
                        IF hc[k]=0 THEN hyf[k] := 0;
                        l := k;
                        v := 0;
                        WHILE true DO
                          BEGIN
                            IF hyf[l]<>0 THEN v := newtrieop(k-l,hyf[l],v);
                            IF l>0 THEN l := l-1
                            ELSE goto 31;
                          END;
                        31:{:965};
                        q := 0;
                        hc[0] := curlang;
                        WHILE l<=k DO
                          BEGIN
                            c := hc[l];
                            l := l+1;
                            p := triel[q];
                            firstchild := true;
                            WHILE (p>0)AND(c>triec[p]) DO
                              BEGIN
                                q := p;
                                p := trier[q];
                                firstchild := false;
                              END;
                            IF (p=0)OR(c<triec[p])THEN{964:}
                              BEGIN
                                IF trieptr=triesize THEN overflow(
                                                                  952,triesize);
                                trieptr := trieptr+1;
                                trier[trieptr] := p;
                                p := trieptr;
                                triel[p] := 0;
                                IF firstchild THEN triel[q] := p
                                ELSE trier[q] := p;
                                triec[p] := c;
                                trieo[p] := 0;
                              END{:964};
                            q := p;
                          END;
                        IF trieo[q]<>0 THEN
                          BEGIN
                            BEGIN
                              IF interaction=3 THEN;
                              printnl(262);
                              print(959);
                            END;
                            BEGIN
                              helpptr := 1;
                              helpline[0] := 957;
                            END;
                            error;
                          END;
                        trieo[q] := v;
                      END{:963};
                    IF curcmd=2 THEN goto 30;
                    k := 0;
                    hyf[0] := 0;
                    digitsensed := false;
                  END;
            ELSE
              BEGIN
                BEGIN
                  IF interaction=3 THEN;
                  printnl(262);
                  print(956);
                END;
                printesc(954);
                BEGIN
                  helpptr := 1;
                  helpline[0] := 957;
                END;
                error;
              END
          END;
        END;
      30:{:961};
    END
  ELSE
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(953);
      END;
      printesc(954);
      BEGIN
        helpptr := 1;
        helpline[0] := 955;
      END;
      error;
      mem[29988].hh.rh := scantoks(false,false);
      flushlist(defref);
    END;
END;
{:960}{966:}
PROCEDURE inittrie;

VAR p: triepointer;
  j,k,t: integer;
  r,s: triepointer;
  h: twohalves;
BEGIN{952:}{945:}
  opstart[0] := -0;
  FOR j:=1 TO 255 DO
    opstart[j] := opstart[j-1]+trieused[j-1];
  FOR j:=1 TO trieopptr DO
    trieophash[j] := opstart[trieoplang[j]]+trieopval
                     [j];
  FOR j:=1 TO trieopptr DO
    WHILE trieophash[j]>j DO
      BEGIN
        k := trieophash[j]
        ;
        t := hyfdistance[k];
        hyfdistance[k] := hyfdistance[j];
        hyfdistance[j] := t;
        t := hyfnum[k];
        hyfnum[k] := hyfnum[j];
        hyfnum[j] := t;
        t := hyfnext[k];
        hyfnext[k] := hyfnext[j];
        hyfnext[j] := t;
        trieophash[j] := trieophash[k];
        trieophash[k] := k;
      END{:945};
  FOR p:=0 TO triesize DO
    triehash[p] := 0;
  triel[0] := compresstrie(triel[0]);
  FOR p:=0 TO trieptr DO
    triehash[p] := 0;
  FOR p:=0 TO 255 DO
    triemin[p] := p+1;
  trie[0].rh := 1;
  triemax := 0{:952};
  IF triel[0]<>0 THEN
    BEGIN
      firstfit(triel[0]);
      triepack(triel[0]);
    END;
{958:}
  h.rh := 0;
  h.b0 := 0;
  h.b1 := 0;
  IF triel[0]=0 THEN
    BEGIN
      FOR r:=0 TO 256 DO
        trie[r] := h;
      triemax := 256;
    END
  ELSE
    BEGIN
      triefix(triel[0]);
      r := 0;
      REPEAT
        s := trie[r].rh;
        trie[r] := h;
        r := s;
      UNTIL r>triemax;
    END;
  trie[0].b1 := 63;{:958};
  trienotready := false;
END;
{:966}{:942}
PROCEDURE linebreak(finalwidowpenalty:integer);

LABEL 30,31,32,33,34,35,22;

VAR {862:}autobreaking: boolean;
  nonprunablep: halfword;
  prevp: halfword;
  q,r,s,prevs: halfword;
  f: internalfontnumber;{:862}{893:}
  j: smallnumber;
  c: 0..255;
{:893}
BEGIN
  packbeginline := curlist.mlfield;
{816:}
  mem[29997].hh.rh := mem[curlist.headfield].hh.rh;
  IF (curlist.tailfield>=himemmin)THEN
    BEGIN
      mem[curlist.tailfield].hh.rh := 
                                      newpenalty(10000);
      curlist.tailfield := mem[curlist.tailfield].hh.rh;
    END
  ELSE IF mem[curlist.tailfield].hh.b0<>10 THEN
         BEGIN
           mem[curlist.
           tailfield].hh.rh := newpenalty(10000);
           curlist.tailfield := mem[curlist.tailfield].hh.rh;
         END
  ELSE
    BEGIN
      mem[curlist.tailfield].hh.b0 := 12;
      deleteglueref(mem[curlist.tailfield+1].hh.lh);
      flushnodelist(mem[curlist.tailfield+1].hh.rh);
      mem[curlist.tailfield+1].int := 10000;
    END;
  nonprunablep := curlist.tailfield;
  mem[curlist.tailfield].hh.rh := newparamglue(14);
  initcurlang := curlist.pgfield MOD 65536;
  initlhyf := curlist.pgfield DIV 4194304;
  initrhyf := (curlist.pgfield DIV 65536)MOD 64;
  popnest;
{:816}{827:}
  noshrinkerroryet := true;
  IF (mem[eqtb[2889].hh.rh].hh.b1<>0)AND(mem[eqtb[2889].hh.rh+3].int<>0)
    THEN
    BEGIN
      eqtb[2889].hh.rh := finiteshrink(eqtb[2889].hh.rh);
    END;
  IF (mem[eqtb[2890].hh.rh].hh.b1<>0)AND(mem[eqtb[2890].hh.rh+3].int<>0)
    THEN
    BEGIN
      eqtb[2890].hh.rh := finiteshrink(eqtb[2890].hh.rh);
    END;
  q := eqtb[2889].hh.rh;
  r := eqtb[2890].hh.rh;
  background[1] := mem[q+1].int+mem[r+1].int;
  background[2] := 0;
  background[3] := 0;
  background[4] := 0;
  background[5] := 0;
  background[2+mem[q].hh.b0] := mem[q+2].int;
  background[2+mem[r].hh.b0] := background[2+mem[r].hh.b0]+mem[r+2].int;
  background[6] := mem[q+3].int+mem[r+3].int;
{:827}{834:}
  minimumdemerits := 1073741823;
  minimaldemerits[3] := 1073741823;
  minimaldemerits[2] := 1073741823;
  minimaldemerits[1] := 1073741823;
  minimaldemerits[0] := 1073741823;
{:834}{848:}
  IF eqtb[3412].hh.rh=0 THEN IF eqtb[5847].int=0 THEN
                               BEGIN
                                 lastspecialline := 0;
                                 secondwidth := eqtb[5833].int;
                                 secondindent := 0;
                               END
  ELSE{849:}
    BEGIN
      lastspecialline := abs(eqtb[5304].int);
      IF eqtb[5304].int<0 THEN
        BEGIN
          firstwidth := eqtb[5833].int-abs(eqtb[5847]
                        .int);
          IF eqtb[5847].int>=0 THEN firstindent := eqtb[5847].int
          ELSE firstindent := 
                              0;
          secondwidth := eqtb[5833].int;
          secondindent := 0;
        END
      ELSE
        BEGIN
          firstwidth := eqtb[5833].int;
          firstindent := 0;
          secondwidth := eqtb[5833].int-abs(eqtb[5847].int);
          IF eqtb[5847].int>=0 THEN secondindent := eqtb[5847].int
          ELSE secondindent 
            := 0;
        END;
    END{:849}
  ELSE
    BEGIN
      lastspecialline := mem[eqtb[3412].hh.rh].hh.lh-1;
      secondwidth := mem[eqtb[3412].hh.rh+2*(lastspecialline+1)].int;
      secondindent := mem[eqtb[3412].hh.rh+2*lastspecialline+1].int;
    END;
  IF eqtb[5282].int=0 THEN easyline := lastspecialline
  ELSE easyline := 65535
{:848};{863:}
  threshold := eqtb[5263].int;
  IF threshold>=0 THEN
    BEGIN
      IF eqtb[5295].int>0 THEN
        BEGIN
          begindiagnostic;
          printnl(934);
        END;
      secondpass := false;
      finalpass := false;
    END
  ELSE
    BEGIN
      threshold := eqtb[5264].int;
      secondpass := true;
      finalpass := (eqtb[5850].int<=0);
      IF eqtb[5295].int>0 THEN begindiagnostic;
    END;
  WHILE true DO
    BEGIN
      IF threshold>10000 THEN threshold := 10000;
      IF secondpass THEN{891:}
        BEGIN
          IF (TeXVariation>0)AND trienotready THEN
            inittrie;
          curlang := initcurlang;
          lhyf := initlhyf;
          rhyf := initrhyf;
        END{:891};
{864:}
      q := getnode(3);
      mem[q].hh.b0 := 0;
      mem[q].hh.b1 := 2;
      mem[q].hh.rh := 29993;
      mem[q+1].hh.rh := 0;
      mem[q+1].hh.lh := curlist.pgfield+1;
      mem[q+2].int := 0;
      mem[29993].hh.rh := q;
      activewidth[1] := background[1];
      activewidth[2] := background[2];
      activewidth[3] := background[3];
      activewidth[4] := background[4];
      activewidth[5] := background[5];
      activewidth[6] := background[6];
      passive := 0;
      printednode := 29997;
      passnumber := 0;
      fontinshortdisplay := 0{:864};
      curp := mem[29997].hh.rh;
      autobreaking := true;
      prevp := curp;
      WHILE (curp<>0)AND(mem[29993].hh.rh<>29993) DO{866:}
        BEGIN
          IF (curp>=
             himemmin)THEN{867:}
            BEGIN
              prevp := curp;
              REPEAT
                f := mem[curp].hh.b0;
                activewidth[1] := activewidth[1]+fontinfo[widthbase[f]+fontinfo[charbase[f
                                  ]+mem[curp].hh.b1].qqqq.b0].int;
                curp := mem[curp].hh.rh;
              UNTIL NOT(curp>=himemmin);
            END{:867};
          CASE mem[curp].hh.b0 OF 
            0,1,2: activewidth[1] := activewidth[1]+mem[curp+1]
                                     .int;
            8:{1362:}IF mem[curp].hh.b1=4 THEN
                       BEGIN
                         curlang := mem[curp+1].hh.rh;
                         lhyf := mem[curp+1].hh.b0;
                         rhyf := mem[curp+1].hh.b1;
                       END{:1362};
            10:
                BEGIN{868:}
                  IF autobreaking THEN
                    BEGIN
                      IF (prevp>=himemmin)THEN
                        trybreak(0,0)
                      ELSE IF (mem[prevp].hh.b0<9)THEN trybreak(0,0)
                      ELSE IF (mem[
                              prevp].hh.b0=11)AND(mem[prevp].hh.b1<>1)THEN trybreak(0,0);
                    END;
                  IF (mem[mem[curp+1].hh.lh].hh.b1<>0)AND(mem[mem[curp+1].hh.lh+3].int<>0)
                    THEN
                    BEGIN
                      mem[curp+1].hh.lh := finiteshrink(mem[curp+1].hh.lh);
                    END;
                  q := mem[curp+1].hh.lh;
                  activewidth[1] := activewidth[1]+mem[q+1].int;
                  activewidth[2+mem[q].hh.b0] := activewidth[2+mem[q].hh.b0]+mem[q+2].int;
                  activewidth[6] := activewidth[6]+mem[q+3].int{:868};
                  IF secondpass AND autobreaking THEN{894:}
                    BEGIN
                      prevs := curp;
                      s := mem[prevs].hh.rh;
                      IF s<>0 THEN
                        BEGIN{896:}
                          WHILE true DO
                            BEGIN
                              IF (s>=himemmin)THEN
                                BEGIN
                                  c 
                                  := mem[s].hh.b1;
                                  hf := mem[s].hh.b0;
                                END
                              ELSE IF mem[s].hh.b0=6 THEN IF mem[s+1].hh.rh=0 THEN goto 22
                              ELSE
                                BEGIN
                                  q := mem[s+1].hh.rh;
                                  c := mem[q].hh.b1;
                                  hf := mem[q].hh.b0;
                                END
                              ELSE IF (mem[s].hh.b0=11)AND(mem[s].hh.b1=0)THEN goto 22
                              ELSE IF mem[
                                      s].hh.b0=8 THEN
                                     BEGIN{1363:}
                                       IF mem[s].hh.b1=4 THEN
                                         BEGIN
                                           curlang := mem[s
                                                      +1].hh.rh;
                                           lhyf := mem[s+1].hh.b0;
                                           rhyf := mem[s+1].hh.b1;
                                         END{:1363};
                                       goto 22;
                                     END
                              ELSE goto 31;
                              IF eqtb[4239+c].hh.rh<>0 THEN IF (eqtb[4239+c].hh.rh=c)OR(eqtb[5301].
                                                               int>
                                                               0)THEN goto 32
                              ELSE goto 31;
                              22: prevs := s;
                              s := mem[prevs].hh.rh;
                            END;
                          32: hyfchar := hyphenchar[hf];
                          IF hyfchar<0 THEN goto 31;
                          IF hyfchar>255 THEN goto 31;
                          ha := prevs{:896};
                          IF lhyf+rhyf>63 THEN goto 31;{897:}
                          hn := 0;
                          WHILE true DO
                            BEGIN
                              IF (s>=himemmin)THEN
                                BEGIN
                                  IF mem[s].hh.b0<>hf THEN
                                    goto 33;
                                  hyfbchar := mem[s].hh.b1;
                                  c := hyfbchar;
                                  IF eqtb[4239+c].hh.rh=0 THEN goto 33;
                                  IF hn=63 THEN goto 33;
                                  hb := s;
                                  hn := hn+1;
                                  hu[hn] := c;
                                  hc[hn] := eqtb[4239+c].hh.rh;
                                  hyfbchar := 256;
                                END
                              ELSE IF mem[s].hh.b0=6 THEN{898:}
                                     BEGIN
                                       IF mem[s+1].hh.b0<>hf THEN
                                         goto 33;
                                       j := hn;
                                       q := mem[s+1].hh.rh;
                                       IF q>0 THEN hyfbchar := mem[q].hh.b1;
                                       WHILE q>0 DO
                                         BEGIN
                                           c := mem[q].hh.b1;
                                           IF eqtb[4239+c].hh.rh=0 THEN goto 33;
                                           IF j=63 THEN goto 33;
                                           j := j+1;
                                           hu[j] := c;
                                           hc[j] := eqtb[4239+c].hh.rh;
                                           q := mem[q].hh.rh;
                                         END;
                                       hb := s;
                                       hn := j;
                                       IF odd(mem[s].hh.b1)THEN hyfbchar := fontbchar[hf]
                                       ELSE hyfbchar := 256;
                                     END{:898}
                              ELSE IF (mem[s].hh.b0=11)AND(mem[s].hh.b1=0)THEN
                                     BEGIN
                                       hb := s;
                                       hyfbchar := fontbchar[hf];
                                     END
                              ELSE goto 33;
                              s := mem[s].hh.rh;
                            END;
                          33:{:897};
{899:}
                          IF hn<lhyf+rhyf THEN goto 31;
                          WHILE true DO
                            BEGIN
                              IF NOT((s>=himemmin))THEN CASE mem[s].hh.b0 OF 
                                                          6:;
                                                          11: IF mem[s].hh.b1<>0 THEN goto 34;
                                                          8,10,12,3,5,4: goto 34;
                                                          ELSE goto 31
                                END;
                              s := mem[s].hh.rh;
                            END;
                          34:{:899};
                          hyphenate;
                        END;
                      31:
                    END{:894};
                END;
            11: IF mem[curp].hh.b1=1 THEN
                  BEGIN
                    IF NOT(mem[curp].hh.rh>=himemmin)AND
                       autobreaking THEN IF mem[mem[curp].hh.rh].hh.b0=10 THEN trybreak(0,0);
                    activewidth[1] := activewidth[1]+mem[curp+1].int;
                  END
                ELSE activewidth[1] := activewidth[1]+mem[curp+1].int;
            6:
               BEGIN
                 f := mem[curp+1].hh.b0;
                 activewidth[1] := activewidth[1]+fontinfo[widthbase[f]+fontinfo[charbase[f
                                   ]+mem[curp+1].hh.b1].qqqq.b0].int;
               END;
            7:{869:}
               BEGIN
                 s := mem[curp+1].hh.lh;
                 discwidth := 0;
                 IF s=0 THEN trybreak(eqtb[5267].int,1)
                 ELSE
                   BEGIN
                     REPEAT{870:}
                       IF (s>=
                          himemmin)THEN
                         BEGIN
                           f := mem[s].hh.b0;
                           discwidth := discwidth+fontinfo[widthbase[f]+fontinfo[charbase[f]+mem[s].
                                        hh.b1].qqqq.b0].int;
                         END
                       ELSE CASE mem[s].hh.b0 OF 
                              6:
                                 BEGIN
                                   f := mem[s+1].hh.b0;
                                   discwidth := discwidth+fontinfo[widthbase[f]+fontinfo[charbase[f]
                                                +mem[s+1]
                                                .hh.b1].qqqq.b0].int;
                                 END;
                              0,1,2,11: discwidth := discwidth+mem[s+1].int;
                              ELSE confusion(938)
                         END{:870};
                       s := mem[s].hh.rh;
                     UNTIL s=0;
                     activewidth[1] := activewidth[1]+discwidth;
                     trybreak(eqtb[5266].int,1);
                     activewidth[1] := activewidth[1]-discwidth;
                   END;
                 r := mem[curp].hh.b1;
                 s := mem[curp].hh.rh;
                 WHILE r>0 DO
                   BEGIN{871:}
                     IF (s>=himemmin)THEN
                       BEGIN
                         f := mem[s].hh.b0;
                         activewidth[1] := activewidth[1]+fontinfo[widthbase[f]+fontinfo[charbase[f
                                           ]+mem[s].hh.b1].qqqq.b0].int;
                       END
                     ELSE CASE mem[s].hh.b0 OF 
                            6:
                               BEGIN
                                 f := mem[s+1].hh.b0;
                                 activewidth[1] := activewidth[1]+fontinfo[widthbase[f]+fontinfo[
                                                   charbase[f
                                                   ]+mem[s+1].hh.b1].qqqq.b0].int;
                               END;
                            0,1,2,11: activewidth[1] := activewidth[1]+mem[s+1].int;
                            ELSE confusion(939)
                       END{:871};
                     r := r-1;
                     s := mem[s].hh.rh;
                   END;
                 prevp := curp;
                 curp := s;
                 goto 35;
               END{:869};
            9:
               BEGIN
                 autobreaking := (mem[curp].hh.b1=1);
                 BEGIN
                   IF NOT(mem[curp].hh.rh>=himemmin)AND autobreaking THEN IF mem[mem[
                                                                             curp].hh.rh].hh.b0=10
                                                                            THEN trybreak(0,0);
                   activewidth[1] := activewidth[1]+mem[curp+1].int;
                 END;
               END;
            12: trybreak(mem[curp+1].int,0);
            4,3,5:;
            ELSE confusion(937)
          END;
          prevp := curp;
          curp := mem[curp].hh.rh;
          35:
        END{:866};
      IF curp=0 THEN{873:}
        BEGIN
          trybreak(-10000,1);
          IF mem[29993].hh.rh<>29993 THEN
            BEGIN{874:}
              r := mem[29993].hh.rh;
              fewestdemerits := 1073741823;
              REPEAT
                IF mem[r].hh.b0<>2 THEN IF mem[r+2].int<fewestdemerits THEN
                                          BEGIN
                                            fewestdemerits := mem[r+2].int;
                                            bestbet := r;
                                          END;
                r := mem[r].hh.rh;
              UNTIL r=29993;
              bestline := mem[bestbet+1].hh.lh{:874};
              IF eqtb[5282].int=0 THEN goto 30;{875:}
              BEGIN
                r := mem[29993].hh.rh;
                actuallooseness := 0;
                REPEAT
                  IF mem[r].hh.b0<>2 THEN
                    BEGIN
                      linediff := mem[r+1].hh.lh-bestline;
                      IF ((linediff<actuallooseness)AND(eqtb[5282].int<=linediff))OR((linediff>
                         actuallooseness)AND(eqtb[5282].int>=linediff))THEN
                        BEGIN
                          bestbet := r;
                          actuallooseness := linediff;
                          fewestdemerits := mem[r+2].int;
                        END
                      ELSE IF (linediff=actuallooseness)AND(mem[r+2].int<fewestdemerits)
                             THEN
                             BEGIN
                               bestbet := r;
                               fewestdemerits := mem[r+2].int;
                             END;
                    END;
                  r := mem[r].hh.rh;
                UNTIL r=29993;
                bestline := mem[bestbet+1].hh.lh;
              END{:875};
              IF (actuallooseness=eqtb[5282].int)OR finalpass THEN goto 30;
            END;
        END{:873};{865:}
      q := mem[29993].hh.rh;
      WHILE q<>29993 DO
        BEGIN
          curp := mem[q].hh.rh;
          IF mem[q].hh.b0=2 THEN freenode(q,7)
          ELSE freenode(q,3);
          q := curp;
        END;
      q := passive;
      WHILE q<>0 DO
        BEGIN
          curp := mem[q].hh.rh;
          freenode(q,2);
          q := curp;
        END{:865};
      IF NOT secondpass THEN
        BEGIN
          IF eqtb[5295].int>0 THEN printnl(935);
          threshold := eqtb[5264].int;
          secondpass := true;
          finalpass := (eqtb[5850].int<=0);
        END
      ELSE
        BEGIN
          IF eqtb[5295].int>0 THEN printnl(936);
          background[2] := background[2]+eqtb[5850].int;
          finalpass := true;
        END;
    END;
  30: IF eqtb[5295].int>0 THEN
        BEGIN
          enddiagnostic(true);
          normalizeselector;
        END;{:863};{876:}
  postlinebreak(finalwidowpenalty,nonprunablep){:876};
{865:}
  q := mem[29993].hh.rh;
  WHILE q<>29993 DO
    BEGIN
      curp := mem[q].hh.rh;
      IF mem[q].hh.b0=2 THEN freenode(q,7)
      ELSE freenode(q,3);
      q := curp;
    END;
  q := passive;
  WHILE q<>0 DO
    BEGIN
      curp := mem[q].hh.rh;
      freenode(q,2);
      q := curp;
    END{:865};
  packbeginline := 0;
END;{:815}{934:}
PROCEDURE newhyphexceptions;

LABEL 21,10,40,45;

VAR n: 0..64;
  j: 0..64;
  h: hyphpointer;
  k: strnumber;
  p: halfword;
  q: halfword;
  s,t: strnumber;
  u,v: poolpointer;
BEGIN
  scanleftbrace;
  IF eqtb[5313].int<=0 THEN curlang := 0
  ELSE IF eqtb[5313].int>255 THEN
         curlang := 0
  ELSE curlang := eqtb[5313].int;{935:}
  n := 0;
  p := 0;
  WHILE true DO
    BEGIN
      getxtoken;
      21: CASE curcmd OF 
            11,12,68:{937:}IF curchr=45 THEN{938:}
                             BEGIN
                               IF n<63
                                 THEN
                                 BEGIN
                                   q := getavail;
                                   mem[q].hh.rh := p;
                                   mem[q].hh.lh := n;
                                   p := q;
                                 END;
                             END{:938}
                      ELSE
                        BEGIN
                          IF eqtb[4239+curchr].hh.rh=0 THEN
                            BEGIN
                              BEGIN
                                IF 
                                   interaction=3 THEN;
                                printnl(262);
                                print(946);
                              END;
                              BEGIN
                                helpptr := 2;
                                helpline[1] := 947;
                                helpline[0] := 948;
                              END;
                              error;
                            END
                          ELSE IF n<63 THEN
                                 BEGIN
                                   n := n+1;
                                   hc[n] := eqtb[4239+curchr].hh.rh;
                                 END;
                        END{:937};
            16:
                BEGIN
                  scancharnum;
                  curchr := curval;
                  curcmd := 68;
                  goto 21;
                END;
            10,2:
                  BEGIN
                    IF n>1 THEN{939:}
                      BEGIN
                        n := n+1;
                        hc[n] := curlang;
                        BEGIN
                          IF poolptr+n>poolsize THEN overflow(257,poolsize-initpoolptr);
                        END;
                        h := 0;
                        FOR j:=1 TO n DO
                          BEGIN
                            h := (h+h+hc[j])MOD 307;
                            BEGIN
                              strpool[poolptr] := hc[j];
                              poolptr := poolptr+1;
                            END;
                          END;
                        s := makestring;
{940:}
                        IF hyphcount=307 THEN overflow(949,307);
                        hyphcount := hyphcount+1;
                        WHILE hyphword[h]<>0 DO
                          BEGIN{941:}
                            k := hyphword[h];
                            IF (strstart[k+1]-strstart[k])<(strstart[s+1]-strstart[s])THEN goto 40;
                            IF (strstart[k+1]-strstart[k])>(strstart[s+1]-strstart[s])THEN goto 45;
                            u := strstart[k];
                            v := strstart[s];
                            REPEAT
                              IF strpool[u]<strpool[v]THEN goto 40;
                              IF strpool[u]>strpool[v]THEN goto 45;
                              u := u+1;
                              v := v+1;
                            UNTIL u=strstart[k+1];
                            40: q := hyphlist[h];
                            hyphlist[h] := p;
                            p := q;
                            t := hyphword[h];
                            hyphword[h] := s;
                            s := t;
                            45:{:941};
                            IF h>0 THEN h := h-1
                            ELSE h := 307;
                          END;
                        hyphword[h] := s;
                        hyphlist[h] := p{:940};
                      END{:939};
                    IF curcmd=2 THEN goto 10;
                    n := 0;
                    p := 0;
                  END;
            ELSE{936:}
              BEGIN
                BEGIN
                  IF interaction=3 THEN;
                  printnl(262);
                  print(680);
                END;
                printesc(942);
                print(943);
                BEGIN
                  helpptr := 2;
                  helpline[1] := 944;
                  helpline[0] := 945;
                END;
                error;
              END{:936}
          END;
    END{:935};
  10:
END;
{:934}{968:}
FUNCTION prunepagetop(p:halfword): halfword;

VAR prevp: halfword;
  q: halfword;
BEGIN
  prevp := 29997;
  mem[29997].hh.rh := p;
  WHILE p<>0 DO
    CASE mem[p].hh.b0 OF 
      0,1,2:{969:}
             BEGIN
               q := newskipparam(10)
               ;
               mem[prevp].hh.rh := q;
               mem[q].hh.rh := p;
               IF mem[tempptr+1].int>mem[p+3].int THEN mem[tempptr+1].int := mem[tempptr
                                                                             +1].int-mem[p+3].int
               ELSE mem[tempptr+1].int := 0;
               p := 0;
             END{:969};
      8,4,3:
             BEGIN
               prevp := p;
               p := mem[prevp].hh.rh;
             END;
      10,11,12:
                BEGIN
                  q := p;
                  p := mem[q].hh.rh;
                  mem[q].hh.rh := 0;
                  mem[prevp].hh.rh := p;
                  flushnodelist(q);
                END;
      ELSE confusion(960)
    END;
  prunepagetop := mem[29997].hh.rh;
END;
{:968}{970:}
FUNCTION vertbreak(p:halfword;h,d:scaled): halfword;

LABEL 30,45,90;

VAR prevp: halfword;
  q,r: halfword;
  pi: integer;
  b: integer;
  leastcost: integer;
  bestplace: halfword;
  prevdp: scaled;
  t: smallnumber;
BEGIN
  prevp := p;
  leastcost := 1073741823;
  activewidth[1] := 0;
  activewidth[2] := 0;
  activewidth[3] := 0;
  activewidth[4] := 0;
  activewidth[5] := 0;
  activewidth[6] := 0;
  prevdp := 0;
  WHILE true DO
    BEGIN{972:}
      IF p=0 THEN pi := -10000
      ELSE{973:}CASE mem[p].hh
                     .b0 OF 
                  0,1,2:
                         BEGIN
                           activewidth[1] := activewidth[1]+prevdp+mem[p+3].int;
                           prevdp := mem[p+2].int;
                           goto 45;
                         END;
                  8:{1365:}goto 45{:1365};
                  10: IF (mem[prevp].hh.b0<9)THEN pi := 0
                      ELSE goto 90;
                  11:
                      BEGIN
                        IF mem[p].hh.rh=0 THEN t := 12
                        ELSE t := mem[mem[p].hh.rh].hh.b0;
                        IF t=10 THEN pi := 0
                        ELSE goto 90;
                      END;
                  12: pi := mem[p+1].int;
                  4,3: goto 45;
                  ELSE confusion(961)
        END{:973};
{974:}
      IF pi<10000 THEN
        BEGIN{975:}
          IF activewidth[1]<h THEN IF (
                                      activewidth[3]<>0)OR(activewidth[4]<>0)OR(activewidth[5]<>0)
                                     THEN b := 0
          ELSE b := badness(h-activewidth[1],activewidth[2])
          ELSE IF activewidth[1]-h
                  >activewidth[6]THEN b := 1073741823
          ELSE b := badness(activewidth[1]-h,
                    activewidth[6]){:975};
          IF b<1073741823 THEN IF pi<=-10000 THEN b := pi
          ELSE IF b<10000 THEN b := b+
                                    pi
          ELSE b := 100000;
          IF b<=leastcost THEN
            BEGIN
              bestplace := p;
              leastcost := b;
              bestheightplusdepth := activewidth[1]+prevdp;
            END;
          IF (b=1073741823)OR(pi<=-10000)THEN goto 30;
        END{:974};
      IF (mem[p].hh.b0<10)OR(mem[p].hh.b0>11)THEN goto 45;
      90:{976:}IF mem[p].hh.b0=11 THEN q := p
          ELSE
            BEGIN
              q := mem[p+1].hh.lh;
              activewidth[2+mem[q].hh.b0] := activewidth[2+mem[q].hh.b0]+mem[q+2].int;
              activewidth[6] := activewidth[6]+mem[q+3].int;
              IF (mem[q].hh.b1<>0)AND(mem[q+3].int<>0)THEN
                BEGIN
                  BEGIN
                    IF interaction=3
                      THEN;
                    printnl(262);
                    print(962);
                  END;
                  BEGIN
                    helpptr := 4;
                    helpline[3] := 963;
                    helpline[2] := 964;
                    helpline[1] := 965;
                    helpline[0] := 923;
                  END;
                  error;
                  r := newspec(q);
                  mem[r].hh.b1 := 0;
                  deleteglueref(q);
                  mem[p+1].hh.lh := r;
                  q := r;
                END;
            END;
      activewidth[1] := activewidth[1]+prevdp+mem[q+1].int;
      prevdp := 0{:976};
      45: IF prevdp>d THEN
            BEGIN
              activewidth[1] := activewidth[1]+prevdp-d;
              prevdp := d;
            END;{:972};
      prevp := p;
      p := mem[prevp].hh.rh;
    END;
  30: vertbreak := bestplace;
END;{:970}{977:}
FUNCTION vsplit(n:eightbits;
                h:scaled): halfword;

LABEL 10,30;

VAR v: halfword;
  p: halfword;
  q: halfword;
BEGIN
  v := eqtb[3678+n].hh.rh;
  IF curmark[3]<>0 THEN
    BEGIN
      deletetokenref(curmark[3]);
      curmark[3] := 0;
      deletetokenref(curmark[4]);
      curmark[4] := 0;
    END;
{978:}
  IF v=0 THEN
    BEGIN
      vsplit := 0;
      goto 10;
    END;
  IF mem[v].hh.b0<>1 THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(338);
      END;
      printesc(966);
      print(967);
      printesc(968);
      BEGIN
        helpptr := 2;
        helpline[1] := 969;
        helpline[0] := 970;
      END;
      error;
      vsplit := 0;
      goto 10;
    END{:978};
  q := vertbreak(mem[v+5].hh.rh,h,eqtb[5836].int);{979:}
  p := mem[v+5].hh.rh;
  IF p=q THEN mem[v+5].hh.rh := 0
  ELSE WHILE true DO
         BEGIN
           IF mem[p].hh.b0=4
             THEN IF curmark[3]=0 THEN
                    BEGIN
                      curmark[3] := mem[p+1].int;
                      curmark[4] := curmark[3];
                      mem[curmark[3]].hh.lh := mem[curmark[3]].hh.lh+2;
                    END
           ELSE
             BEGIN
               deletetokenref(curmark[4]);
               curmark[4] := mem[p+1].int;
               mem[curmark[4]].hh.lh := mem[curmark[4]].hh.lh+1;
             END;
           IF mem[p].hh.rh=q THEN
             BEGIN
               mem[p].hh.rh := 0;
               goto 30;
             END;
           p := mem[p].hh.rh;
         END;
  30:{:979};
  q := prunepagetop(q);
  p := mem[v+5].hh.rh;
  freenode(v,7);
  IF q=0 THEN eqtb[3678+n].hh.rh := 0
  ELSE eqtb[3678+n].hh.rh := vpackage(q,0,
                             1,1073741823);
  vsplit := vpackage(p,h,0,eqtb[5836].int);
  10:
END;
{:977}{985:}
PROCEDURE printtotals;
BEGIN
  printscaled(pagesofar[1]);
  IF pagesofar[2]<>0 THEN
    BEGIN
      print(312);
      printscaled(pagesofar[2]);
      print(338);
    END;
  IF pagesofar[3]<>0 THEN
    BEGIN
      print(312);
      printscaled(pagesofar[3]);
      print(311);
    END;
  IF pagesofar[4]<>0 THEN
    BEGIN
      print(312);
      printscaled(pagesofar[4]);
      print(979);
    END;
  IF pagesofar[5]<>0 THEN
    BEGIN
      print(312);
      printscaled(pagesofar[5]);
      print(980);
    END;
  IF pagesofar[6]<>0 THEN
    BEGIN
      print(313);
      printscaled(pagesofar[6]);
    END;
END;{:985}{987:}
PROCEDURE freezepagespecs(s:smallnumber);
BEGIN
  pagecontents := s;
  pagesofar[0] := eqtb[5834].int;
  pagemaxdepth := eqtb[5835].int;
  pagesofar[7] := 0;
  pagesofar[1] := 0;
  pagesofar[2] := 0;
  pagesofar[3] := 0;
  pagesofar[4] := 0;
  pagesofar[5] := 0;
  pagesofar[6] := 0;
  leastpagecost := 1073741823;
  IF eqtb[5296].int>0 THEN
    BEGIN
      begindiagnostic;
      printnl(988);
      printscaled(pagesofar[0]);
      print(989);
      printscaled(pagemaxdepth);
      enddiagnostic(false);
    END;
END;
{:987}{992:}
PROCEDURE boxerror(n:eightbits);
BEGIN
  error;
  begindiagnostic;
  printnl(837);
  showbox(eqtb[3678+n].hh.rh);
  enddiagnostic(true);
  flushnodelist(eqtb[3678+n].hh.rh);
  eqtb[3678+n].hh.rh := 0;
END;
{:992}{993:}
PROCEDURE ensurevbox(n:eightbits);

VAR p: halfword;
BEGIN
  p := eqtb[3678+n].hh.rh;
  IF p<>0 THEN IF mem[p].hh.b0=0 THEN
                 BEGIN
                   BEGIN
                     IF interaction=3 THEN;
                     printnl(262);
                     print(990);
                   END;
                   BEGIN
                     helpptr := 3;
                     helpline[2] := 991;
                     helpline[1] := 992;
                     helpline[0] := 993;
                   END;
                   boxerror(n);
                 END;
END;
{:993}{994:}{1012:}
PROCEDURE fireup(c:halfword);

LABEL 10;

VAR p,q,r,s: halfword;
  prevp: halfword;
  n: 0..255;
  wait: boolean;
  savevbadness: integer;
  savevfuzz: scaled;
  savesplittopskip: halfword;
BEGIN{1013:}
  IF mem[bestpagebreak].hh.b0=12 THEN
    BEGIN
      geqworddefine(5302
                    ,mem[bestpagebreak+1].int);
      mem[bestpagebreak+1].int := 10000;
    END
  ELSE geqworddefine(5302,10000){:1013};
  IF curmark[2]<>0 THEN
    BEGIN
      IF curmark[0]<>0 THEN deletetokenref(curmark
                                           [0]);
      curmark[0] := curmark[2];
      mem[curmark[0]].hh.lh := mem[curmark[0]].hh.lh+1;
      deletetokenref(curmark[1]);
      curmark[1] := 0;
    END;
{1014:}
  IF c=bestpagebreak THEN bestpagebreak := 0;
{1015:}
  IF eqtb[3933].hh.rh<>0 THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(338);
      END;
      printesc(409);
      print(1004);
      BEGIN
        helpptr := 2;
        helpline[1] := 1005;
        helpline[0] := 993;
      END;
      boxerror(255);
    END{:1015};
  insertpenalties := 0;
  savesplittopskip := eqtb[2892].hh.rh;
  IF eqtb[5316].int<=0 THEN{1018:}
    BEGIN
      r := mem[30000].hh.rh;
      WHILE r<>30000 DO
        BEGIN
          IF mem[r+2].hh.lh<>0 THEN
            BEGIN
              n := mem[r].hh.b1;
              ensurevbox(n);
              IF eqtb[3678+n].hh.rh=0 THEN eqtb[3678+n].hh.rh := newnullbox;
              p := eqtb[3678+n].hh.rh+5;
              WHILE mem[p].hh.rh<>0 DO
                p := mem[p].hh.rh;
              mem[r+2].hh.rh := p;
            END;
          r := mem[r].hh.rh;
        END;
    END{:1018};
  q := 29996;
  mem[q].hh.rh := 0;
  prevp := 29998;
  p := mem[prevp].hh.rh;
  WHILE p<>bestpagebreak DO
    BEGIN
      IF mem[p].hh.b0=3 THEN
        BEGIN
          IF eqtb[
             5316].int<=0 THEN{1020:}
            BEGIN
              r := mem[30000].hh.rh;
              WHILE mem[r].hh.b1<>mem[p].hh.b1 DO
                r := mem[r].hh.rh;
              IF mem[r+2].hh.lh=0 THEN wait := true
              ELSE
                BEGIN
                  wait := false;
                  s := mem[r+2].hh.rh;
                  mem[s].hh.rh := mem[p+4].hh.lh;
                  IF mem[r+2].hh.lh=p THEN{1021:}
                    BEGIN
                      IF mem[r].hh.b0=1 THEN IF (mem[r+1].
                                                hh.lh=p)AND(mem[r+1].hh.rh<>0)THEN
                                               BEGIN
                                                 WHILE mem[s].hh.rh<>mem[r+1].hh
                                                       .rh DO
                                                   s := mem[s].hh.rh;
                                                 mem[s].hh.rh := 0;
                                                 eqtb[2892].hh.rh := mem[p+4].hh.rh;
                                                 mem[p+4].hh.lh := prunepagetop(mem[r+1].hh.rh);
                                                 IF mem[p+4].hh.lh<>0 THEN
                                                   BEGIN
                                                     tempptr := vpackage(mem[p+4].hh.lh,0,1,
                                                                1073741823);
                                                     mem[p+3].int := mem[tempptr+3].int+mem[tempptr+
                                                                     2].int;
                                                     freenode(tempptr,7);
                                                     wait := true;
                                                   END;
                                               END;
                      mem[r+2].hh.lh := 0;
                      n := mem[r].hh.b1;
                      tempptr := mem[eqtb[3678+n].hh.rh+5].hh.rh;
                      freenode(eqtb[3678+n].hh.rh,7);
                      eqtb[3678+n].hh.rh := vpackage(tempptr,0,1,1073741823);
                    END{:1021}
                  ELSE
                    BEGIN
                      WHILE mem[s].hh.rh<>0 DO
                        s := mem[s].hh.rh;
                      mem[r+2].hh.rh := s;
                    END;
                END;{1022:}
              mem[prevp].hh.rh := mem[p].hh.rh;
              mem[p].hh.rh := 0;
              IF wait THEN
                BEGIN
                  mem[q].hh.rh := p;
                  q := p;
                  insertpenalties := insertpenalties+1;
                END
              ELSE
                BEGIN
                  deleteglueref(mem[p+4].hh.rh);
                  freenode(p,5);
                END;
              p := prevp{:1022};
            END{:1020};
        END
      ELSE IF mem[p].hh.b0=4 THEN{1016:}
             BEGIN
               IF curmark[1]=0 THEN
                 BEGIN
                   curmark[1] := mem[p+1].int;
                   mem[curmark[1]].hh.lh := mem[curmark[1]].hh.lh+1;
                 END;
               IF curmark[2]<>0 THEN deletetokenref(curmark[2]);
               curmark[2] := mem[p+1].int;
               mem[curmark[2]].hh.lh := mem[curmark[2]].hh.lh+1;
             END{:1016};
      prevp := p;
      p := mem[prevp].hh.rh;
    END;
  eqtb[2892].hh.rh := savesplittopskip;
{1017:}
  IF p<>0 THEN
    BEGIN
      IF mem[29999].hh.rh=0 THEN IF nestptr=0 THEN
                                   curlist.tailfield := pagetail
      ELSE nest[0].tailfield := pagetail;
      mem[pagetail].hh.rh := mem[29999].hh.rh;
      mem[29999].hh.rh := p;
      mem[prevp].hh.rh := 0;
    END;
  savevbadness := eqtb[5290].int;
  eqtb[5290].int := 10000;
  savevfuzz := eqtb[5839].int;
  eqtb[5839].int := 1073741823;
  eqtb[3933].hh.rh := vpackage(mem[29998].hh.rh,bestsize,0,pagemaxdepth);
  eqtb[5290].int := savevbadness;
  eqtb[5839].int := savevfuzz;
  IF lastglue<>65535 THEN deleteglueref(lastglue);{991:}
  pagecontents := 0;
  pagetail := 29998;
  mem[29998].hh.rh := 0;
  lastglue := 65535;
  lastpenalty := 0;
  lastkern := 0;
  pagesofar[7] := 0;
  pagemaxdepth := 0{:991};
  IF q<>29996 THEN
    BEGIN
      mem[29998].hh.rh := mem[29996].hh.rh;
      pagetail := q;
    END{:1017};{1019:}
  r := mem[30000].hh.rh;
  WHILE r<>30000 DO
    BEGIN
      q := mem[r].hh.rh;
      freenode(r,4);
      r := q;
    END;
  mem[30000].hh.rh := 30000{:1019}{:1014};
  IF (curmark[0]<>0)AND(curmark[1]=0)THEN
    BEGIN
      curmark[1] := curmark[0];
      mem[curmark[0]].hh.lh := mem[curmark[0]].hh.lh+1;
    END;
  IF eqtb[3413].hh.rh<>0 THEN IF deadcycles>=eqtb[5303].int THEN{1024:}
                                BEGIN
                                  BEGIN
                                    IF interaction=3 THEN;
                                    printnl(262);
                                    print(1006);
                                  END;
                                  printint(deadcycles);
                                  print(1007);
                                  BEGIN
                                    helpptr := 3;
                                    helpline[2] := 1008;
                                    helpline[1] := 1009;
                                    helpline[0] := 1010;
                                  END;
                                  error;
                                END{:1024}
  ELSE{1025:}
    BEGIN
      outputactive := true;
      deadcycles := deadcycles+1;
      pushnest;
      curlist.modefield := -1;
      curlist.auxfield.int := -65536000;
      curlist.mlfield := -line;
      begintokenlist(eqtb[3413].hh.rh,6);
      newsavelevel(8);
      normalparagraph;
      scanleftbrace;
      goto 10;
    END{:1025};
{1023:}
  BEGIN
    IF mem[29998].hh.rh<>0 THEN
      BEGIN
        IF mem[29999].hh.rh=0
          THEN IF nestptr=0 THEN curlist.tailfield := pagetail
        ELSE nest[0].
          tailfield := pagetail
        ELSE mem[pagetail].hh.rh := mem[29999].hh.rh;
        mem[29999].hh.rh := mem[29998].hh.rh;
        mem[29998].hh.rh := 0;
        pagetail := 29998;
      END;
    shipout(eqtb[3933].hh.rh);
    eqtb[3933].hh.rh := 0;
  END{:1023};
  10:
END;
{:1012}
PROCEDURE buildpage;

LABEL 10,30,31,22,80,90;

VAR p: halfword;
  q,r: halfword;
  b,c: integer;
  pi: integer;
  n: 0..255;
  delta,h,w: scaled;
BEGIN
  IF (mem[29999].hh.rh=0)OR outputactive THEN goto 10;
  REPEAT
    22: p := mem[29999].hh.rh;
{996:}
    IF lastglue<>65535 THEN deleteglueref(lastglue);
    lastpenalty := 0;
    lastkern := 0;
    IF mem[p].hh.b0=10 THEN
      BEGIN
        lastglue := mem[p+1].hh.lh;
        mem[lastglue].hh.rh := mem[lastglue].hh.rh+1;
      END
    ELSE
      BEGIN
        lastglue := 65535;
        IF mem[p].hh.b0=12 THEN lastpenalty := mem[p+1].int
        ELSE IF mem[p].hh.b0=
                11 THEN lastkern := mem[p+1].int;
      END{:996};
{997:}{1000:}
    CASE mem[p].hh.b0 OF 
      0,1,2: IF pagecontents<2 THEN{1001:}
               BEGIN
                 IF pagecontents=0 THEN freezepagespecs(2)
                 ELSE pagecontents := 2;
                 q := newskipparam(9);
                 IF mem[tempptr+1].int>mem[p+3].int THEN mem[tempptr+1].int := mem[tempptr
                                                                               +1].int-mem[p+3].int
                 ELSE mem[tempptr+1].int := 0;
                 mem[q].hh.rh := p;
                 mem[29999].hh.rh := q;
                 goto 22;
               END{:1001}
             ELSE{1002:}
               BEGIN
                 pagesofar[1] := pagesofar[1]+pagesofar[7]+mem[p
                                 +3].int;
                 pagesofar[7] := mem[p+2].int;
                 goto 80;
               END{:1002};
      8:{1364:}goto 80{:1364};
      10: IF pagecontents<2 THEN goto 31
          ELSE IF (mem[pagetail].hh.b0<9)THEN pi 
                 := 0
          ELSE goto 90;
      11: IF pagecontents<2 THEN goto 31
          ELSE IF mem[p].hh.rh=0 THEN goto 10
          ELSE IF mem[mem[p].hh.rh].hh.b0=10 THEN pi := 0
          ELSE goto 90;
      12: IF pagecontents<2 THEN goto 31
          ELSE pi := mem[p+1].int;
      4: goto 80;
      3:{1008:}
         BEGIN
           IF pagecontents=0 THEN freezepagespecs(1);
           n := mem[p].hh.b1;
           r := 30000;
           WHILE n>=mem[mem[r].hh.rh].hh.b1 DO
             r := mem[r].hh.rh;
           n := n;
           IF mem[r].hh.b1<>n THEN{1009:}
             BEGIN
               q := getnode(4);
               mem[q].hh.rh := mem[r].hh.rh;
               mem[r].hh.rh := q;
               r := q;
               mem[r].hh.b1 := n;
               mem[r].hh.b0 := 0;
               ensurevbox(n);
               IF eqtb[3678+n].hh.rh=0 THEN mem[r+3].int := 0
               ELSE mem[r+3].int := mem[eqtb
                                    [3678+n].hh.rh+3].int+mem[eqtb[3678+n].hh.rh+2].int;
               mem[r+2].hh.lh := 0;
               q := eqtb[2900+n].hh.rh;
               IF eqtb[5318+n].int=1000 THEN h := mem[r+3].int
               ELSE h := xovern(mem[r+3].
                         int,1000)*eqtb[5318+n].int;
               pagesofar[0] := pagesofar[0]-h-mem[q+1].int;
               pagesofar[2+mem[q].hh.b0] := pagesofar[2+mem[q].hh.b0]+mem[q+2].int;
               pagesofar[6] := pagesofar[6]+mem[q+3].int;
               IF (mem[q].hh.b1<>0)AND(mem[q+3].int<>0)THEN
                 BEGIN
                   BEGIN
                     IF interaction=3
                       THEN;
                     printnl(262);
                     print(999);
                   END;
                   printesc(395);
                   printint(n);
                   BEGIN
                     helpptr := 3;
                     helpline[2] := 1000;
                     helpline[1] := 1001;
                     helpline[0] := 923;
                   END;
                   error;
                 END;
             END{:1009};
           IF mem[r].hh.b0=1 THEN insertpenalties := insertpenalties+mem[p+1].int
           ELSE
             BEGIN
               mem[r+2].hh.rh := p;
               delta := pagesofar[0]-pagesofar[1]-pagesofar[7]+pagesofar[6];
               IF eqtb[5318+n].int=1000 THEN h := mem[p+3].int
               ELSE h := xovern(mem[p+3].
                         int,1000)*eqtb[5318+n].int;
               IF ((h<=0)OR(h<=delta))AND(mem[p+3].int+mem[r+3].int<=eqtb[5851+n].int)
                 THEN
                 BEGIN
                   pagesofar[0] := pagesofar[0]-h;
                   mem[r+3].int := mem[r+3].int+mem[p+3].int;
                 END
               ELSE{1010:}
                 BEGIN
                   IF eqtb[5318+n].int<=0 THEN w := 1073741823
                   ELSE
                     BEGIN
                       w := pagesofar[0]-pagesofar[1]-pagesofar[7];
                       IF eqtb[5318+n].int<>1000 THEN w := xovern(w,eqtb[5318+n].int)*1000;
                     END;
                   IF w>eqtb[5851+n].int-mem[r+3].int THEN w := eqtb[5851+n].int-mem[r+3].int
                   ;
                   q := vertbreak(mem[p+4].hh.lh,w,mem[p+2].int);
                   mem[r+3].int := mem[r+3].int+bestheightplusdepth;
                   IF eqtb[5296].int>0 THEN{1011:}
                     BEGIN
                       begindiagnostic;
                       printnl(1002);
                       printint(n);
                       print(1003);
                       printscaled(w);
                       printchar(44);
                       printscaled(bestheightplusdepth);
                       print(932);
                       IF q=0 THEN printint(-10000)
                       ELSE IF mem[q].hh.b0=12 THEN printint(mem[q
                                                             +1].int)
                       ELSE printchar(48);
                       enddiagnostic(false);
                     END{:1011};
                   IF eqtb[5318+n].int<>1000 THEN bestheightplusdepth := xovern(
                                                                         bestheightplusdepth,1000)*
                                                                         eqtb[5318+n].int;
                   pagesofar[0] := pagesofar[0]-bestheightplusdepth;
                   mem[r].hh.b0 := 1;
                   mem[r+1].hh.rh := q;
                   mem[r+1].hh.lh := p;
                   IF q=0 THEN insertpenalties := insertpenalties-10000
                   ELSE IF mem[q].hh.b0=
                           12 THEN insertpenalties := insertpenalties+mem[q+1].int;
                 END{:1010};
             END;
           goto 80;
         END{:1008};
      ELSE confusion(994)
    END{:1000};
{1005:}
    IF pi<10000 THEN
      BEGIN{1007:}
        IF pagesofar[1]<pagesofar[0]THEN IF (
                                            pagesofar[3]<>0)OR(pagesofar[4]<>0)OR(pagesofar[5]<>0)
                                           THEN b := 0
        ELSE b := 
                  badness(pagesofar[0]-pagesofar[1],pagesofar[2])
        ELSE IF pagesofar[1]-
                pagesofar[0]>pagesofar[6]THEN b := 1073741823
        ELSE b := badness(pagesofar[1]
                  -pagesofar[0],pagesofar[6]){:1007};
        IF b<1073741823 THEN IF pi<=-10000 THEN c := pi
        ELSE IF b<10000 THEN c := b+
                                  pi+insertpenalties
        ELSE c := 100000
        ELSE c := b;
        IF insertpenalties>=10000 THEN c := 1073741823;
        IF eqtb[5296].int>0 THEN{1006:}
          BEGIN
            begindiagnostic;
            printnl(37);
            print(928);
            printtotals;
            print(997);
            printscaled(pagesofar[0]);
            print(931);
            IF b=1073741823 THEN printchar(42)
            ELSE printint(b);
            print(932);
            printint(pi);
            print(998);
            IF c=1073741823 THEN printchar(42)
            ELSE printint(c);
            IF c<=leastpagecost THEN printchar(35);
            enddiagnostic(false);
          END{:1006};
        IF c<=leastpagecost THEN
          BEGIN
            bestpagebreak := p;
            bestsize := pagesofar[0];
            leastpagecost := c;
            r := mem[30000].hh.rh;
            WHILE r<>30000 DO
              BEGIN
                mem[r+2].hh.lh := mem[r+2].hh.rh;
                r := mem[r].hh.rh;
              END;
          END;
        IF (c=1073741823)OR(pi<=-10000)THEN
          BEGIN
            fireup(p);
            IF outputactive THEN goto 10;
            goto 30;
          END;
      END{:1005};
    IF (mem[p].hh.b0<10)OR(mem[p].hh.b0>11)THEN goto 80;
    90:{1004:}IF mem[p].hh.b0=11 THEN q := p
        ELSE
          BEGIN
            q := mem[p+1].hh.lh;
            pagesofar[2+mem[q].hh.b0] := pagesofar[2+mem[q].hh.b0]+mem[q+2].int;
            pagesofar[6] := pagesofar[6]+mem[q+3].int;
            IF (mem[q].hh.b1<>0)AND(mem[q+3].int<>0)THEN
              BEGIN
                BEGIN
                  IF interaction=3
                    THEN;
                  printnl(262);
                  print(995);
                END;
                BEGIN
                  helpptr := 4;
                  helpline[3] := 996;
                  helpline[2] := 964;
                  helpline[1] := 965;
                  helpline[0] := 923;
                END;
                error;
                r := newspec(q);
                mem[r].hh.b1 := 0;
                deleteglueref(q);
                mem[p+1].hh.lh := r;
                q := r;
              END;
          END;
    pagesofar[1] := pagesofar[1]+pagesofar[7]+mem[q+1].int;
    pagesofar[7] := 0{:1004};
    80:{1003:}IF pagesofar[7]>pagemaxdepth THEN
                BEGIN
                  pagesofar[1] := 
                                  pagesofar[1]+pagesofar[7]-pagemaxdepth;
                  pagesofar[7] := pagemaxdepth;
                END;
{:1003};{998:}
    mem[pagetail].hh.rh := p;
    pagetail := p;
    mem[29999].hh.rh := mem[p].hh.rh;
    mem[p].hh.rh := 0;
    goto 30{:998};
    31:{999:}mem[29999].hh.rh := mem[p].hh.rh;
    mem[p].hh.rh := 0;
    flushnodelist(p){:999};
    30:{:997};
  UNTIL mem[29999].hh.rh=0;
{995:}
  IF nestptr=0 THEN curlist.tailfield := 29999
  ELSE nest[0].tailfield 
    := 29999{:995};
  10:
END;{:994}{1030:}{1043:}
PROCEDURE appspace;

VAR q: halfword;
BEGIN
  IF (curlist.auxfield.hh.lh>=2000)AND(eqtb[2895].hh.rh<>0)THEN q := 
                                                                     newparamglue(13)
  ELSE
    BEGIN
      IF eqtb[2894].hh.rh<>0 THEN mainp := eqtb[2894]
                                           .hh.rh
      ELSE{1042:}
        BEGIN
          mainp := fontglue[eqtb[3934].hh.rh];
          IF mainp=0 THEN
            BEGIN
              mainp := newspec(0);
              maink := parambase[eqtb[3934].hh.rh]+2;
              mem[mainp+1].int := fontinfo[maink].int;
              mem[mainp+2].int := fontinfo[maink+1].int;
              mem[mainp+3].int := fontinfo[maink+2].int;
              fontglue[eqtb[3934].hh.rh] := mainp;
            END;
        END{:1042};
      mainp := newspec(mainp);
{1044:}
      IF curlist.auxfield.hh.lh>=2000 THEN mem[mainp+1].int := mem[mainp
                                                               +1].int+fontinfo[7+parambase[eqtb[
                                                               3934].hh.rh]].int;
      mem[mainp+2].int := xnoverd(mem[mainp+2].int,curlist.auxfield.hh.lh,1000);
      mem[mainp+3].int := xnoverd(mem[mainp+3].int,1000,curlist.auxfield.hh.lh)
{:1044};
      q := newglue(mainp);
      mem[mainp].hh.rh := 0;
    END;
  mem[curlist.tailfield].hh.rh := q;
  curlist.tailfield := q;
END;
{:1043}{1047:}
PROCEDURE insertdollarsign;
BEGIN
  backinput;
  curtok := 804;
  BEGIN
    IF interaction=3 THEN;
    printnl(262);
    print(1018);
  END;
  BEGIN
    helpptr := 2;
    helpline[1] := 1019;
    helpline[0] := 1020;
  END;
  inserror;
END;
{:1047}{1049:}
PROCEDURE youcant;
BEGIN
  BEGIN
    IF interaction=3 THEN;
    printnl(262);
    print(685);
  END;
  printcmdchr(curcmd,curchr);
  print(1021);
  printmode(curlist.modefield);
END;
{:1049}{1050:}
PROCEDURE reportillegalcase;
BEGIN
  youcant;
  BEGIN
    helpptr := 4;
    helpline[3] := 1022;
    helpline[2] := 1023;
    helpline[1] := 1024;
    helpline[0] := 1025;
  END;
  error;
END;
{:1050}{1051:}
FUNCTION privileged: boolean;
BEGIN
  IF curlist.modefield>0 THEN privileged := true
  ELSE
    BEGIN
      reportillegalcase;
      privileged := false;
    END;
END;
{:1051}{1054:}
FUNCTION itsallover: boolean;

LABEL 10;
BEGIN
  IF privileged THEN
    BEGIN
      IF (29998=pagetail)AND(curlist.headfield=
         curlist.tailfield)AND(deadcycles=0)THEN
        BEGIN
          itsallover := true;
          goto 10;
        END;
      backinput;
      BEGIN
        mem[curlist.tailfield].hh.rh := newnullbox;
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      mem[curlist.tailfield+1].int := eqtb[5833].int;
      BEGIN
        mem[curlist.tailfield].hh.rh := newglue(8);
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      BEGIN
        mem[curlist.tailfield].hh.rh := newpenalty(-1073741824);
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      buildpage;
    END;
  itsallover := false;
  10:
END;{:1054}{1060:}
PROCEDURE appendglue;

VAR s: smallnumber;
BEGIN
  s := curchr;
  CASE s OF 
    0: curval := 4;
    1: curval := 8;
    2: curval := 12;
    3: curval := 16;
    4: scanglue(2);
    5: scanglue(3);
  END;
  BEGIN
    mem[curlist.tailfield].hh.rh := newglue(curval);
    curlist.tailfield := mem[curlist.tailfield].hh.rh;
  END;
  IF s>=4 THEN
    BEGIN
      mem[curval].hh.rh := mem[curval].hh.rh-1;
      IF s>4 THEN mem[curlist.tailfield].hh.b1 := 99;
    END;
END;
{:1060}{1061:}
PROCEDURE appendkern;

VAR s: quarterword;
BEGIN
  s := curchr;
  scandimen(s=99,false,false);
  BEGIN
    mem[curlist.tailfield].hh.rh := newkern(curval);
    curlist.tailfield := mem[curlist.tailfield].hh.rh;
  END;
  mem[curlist.tailfield].hh.b1 := s;
END;{:1061}{1064:}
PROCEDURE offsave;

VAR p: halfword;
BEGIN
  IF curgroup=0 THEN{1066:}
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(777);
      END;
      printcmdchr(curcmd,curchr);
      BEGIN
        helpptr := 1;
        helpline[0] := 1044;
      END;
      error;
    END{:1066}
  ELSE
    BEGIN
      backinput;
      p := getavail;
      mem[29997].hh.rh := p;
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(625);
      END;{1065:}
      CASE curgroup OF 
        14:
            BEGIN
              mem[p].hh.lh := 6711;
              printesc(516);
            END;
        15:
            BEGIN
              mem[p].hh.lh := 804;
              printchar(36);
            END;
        16:
            BEGIN
              mem[p].hh.lh := 6712;
              mem[p].hh.rh := getavail;
              p := mem[p].hh.rh;
              mem[p].hh.lh := 3118;
              printesc(1043);
            END;
        ELSE
          BEGIN
            mem[p].hh.lh := 637;
            printchar(125);
          END
      END{:1065};
      print(626);
      begintokenlist(mem[29997].hh.rh,4);
      BEGIN
        helpptr := 5;
        helpline[4] := 1038;
        helpline[3] := 1039;
        helpline[2] := 1040;
        helpline[1] := 1041;
        helpline[0] := 1042;
      END;
      error;
    END;
END;{:1064}{1069:}
PROCEDURE extrarightbrace;
BEGIN
  BEGIN
    IF interaction=3 THEN;
    printnl(262);
    print(1049);
  END;
  CASE curgroup OF 
    14: printesc(516);
    15: printchar(36);
    16: printesc(878);
  END;
  BEGIN
    helpptr := 5;
    helpline[4] := 1050;
    helpline[3] := 1051;
    helpline[2] := 1052;
    helpline[1] := 1053;
    helpline[0] := 1054;
  END;
  error;
  alignstate := alignstate+1;
END;{:1069}{1070:}
PROCEDURE normalparagraph;
BEGIN
  IF eqtb[5282].int<>0 THEN eqworddefine(5282,0);
  IF eqtb[5847].int<>0 THEN eqworddefine(5847,0);
  IF eqtb[5304].int<>1 THEN eqworddefine(5304,1);
  IF eqtb[3412].hh.rh<>0 THEN eqdefine(3412,118,0);
END;
{:1070}{1075:}
PROCEDURE boxend(boxcontext:integer);

VAR p: halfword;
BEGIN
  IF boxcontext<1073741824 THEN{1076:}
    BEGIN
      IF curbox<>0 THEN
        BEGIN
          mem[curbox+4].int := boxcontext;
          IF abs(curlist.modefield)=1 THEN
            BEGIN
              appendtovlist(curbox);
              IF adjusttail<>0 THEN
                BEGIN
                  IF 29995<>adjusttail THEN
                    BEGIN
                      mem[curlist.
                      tailfield].hh.rh := mem[29995].hh.rh;
                      curlist.tailfield := adjusttail;
                    END;
                  adjusttail := 0;
                END;
              IF curlist.modefield>0 THEN buildpage;
            END
          ELSE
            BEGIN
              IF abs(curlist.modefield)=102 THEN curlist.auxfield.hh.lh 
                := 1000
              ELSE
                BEGIN
                  p := newnoad;
                  mem[p+1].hh.rh := 2;
                  mem[p+1].hh.lh := curbox;
                  curbox := p;
                END;
              mem[curlist.tailfield].hh.rh := curbox;
              curlist.tailfield := curbox;
            END;
        END;
    END{:1076}
  ELSE IF boxcontext<1073742336 THEN{1077:}IF boxcontext<
                                              1073742080 THEN eqdefine(-1073738146+boxcontext,119,
                                                                       curbox)
  ELSE
    geqdefine(-1073738402+boxcontext,119,curbox){:1077}
  ELSE IF curbox<>0
         THEN IF boxcontext>1073742336 THEN{1078:}
                BEGIN{404:}
                  REPEAT
                    getxtoken;
                  UNTIL (curcmd<>10)AND(curcmd<>0){:404};
                  IF ((curcmd=26)AND(abs(curlist.modefield)<>1))OR((curcmd=27)AND(abs(
                     curlist.modefield)=1))THEN
                    BEGIN
                      appendglue;
                      mem[curlist.tailfield].hh.b1 := boxcontext-(1073742237);
                      mem[curlist.tailfield+1].hh.rh := curbox;
                    END
                  ELSE
                    BEGIN
                      BEGIN
                        IF interaction=3 THEN;
                        printnl(262);
                        print(1067);
                      END;
                      BEGIN
                        helpptr := 3;
                        helpline[2] := 1068;
                        helpline[1] := 1069;
                        helpline[0] := 1070;
                      END;
                      backerror;
                      flushnodelist(curbox);
                    END;
                END{:1078}
  ELSE shipout(curbox);
END;{:1075}{1079:}
PROCEDURE beginbox(boxcontext:integer);

LABEL 10,30;

VAR p,q: halfword;
  m: quarterword;
  k: halfword;
  n: eightbits;
BEGIN
  CASE curchr OF 
    0:
       BEGIN
         scaneightbitint;
         curbox := eqtb[3678+curval].hh.rh;
         eqtb[3678+curval].hh.rh := 0;
       END;
    1:
       BEGIN
         scaneightbitint;
         curbox := copynodelist(eqtb[3678+curval].hh.rh);
       END;
    2:{1080:}
       BEGIN
         curbox := 0;
         IF abs(curlist.modefield)=203 THEN
           BEGIN
             youcant;
             BEGIN
               helpptr := 1;
               helpline[0] := 1071;
             END;
             error;
           END
         ELSE IF (curlist.modefield=1)AND(curlist.headfield=curlist.tailfield)
                THEN
                BEGIN
                  youcant;
                  BEGIN
                    helpptr := 2;
                    helpline[1] := 1072;
                    helpline[0] := 1073;
                  END;
                  error;
                END
         ELSE
           BEGIN
             IF NOT(curlist.tailfield>=himemmin)THEN IF (mem[curlist.
                                                        tailfield].hh.b0=0)OR(mem[curlist.tailfield]
                                                        .hh.b0=1)THEN{1081:}
                                                       BEGIN
                                                         q 
                                                         := curlist.headfield;
                                                         REPEAT
                                                           p := q;
                                                           IF NOT(q>=himemmin)THEN IF mem[q].hh.b0=7
                                                                                     THEN
                                                                                     BEGIN
                                                                                       FOR m:=1 TO
                                                                                           mem[q].
                                                                                           hh.b1 DO
                                                                                         p := mem[p]
                                                                                              .hh.rh
                                                                                       ;
                                                                                       IF p=curlist.
                                                                                          tailfield
                                                                                         THEN goto
                                                                                         30;
                                                                                     END;
                                                           q := mem[p].hh.rh;
                                                         UNTIL q=curlist.tailfield;
                                                         curbox := curlist.tailfield;
                                                         mem[curbox+4].int := 0;
                                                         curlist.tailfield := p;
                                                         mem[p].hh.rh := 0;
                                                         30:
                                                       END{:1081};
           END;
       END{:1080};
    3:{1082:}
       BEGIN
         scaneightbitint;
         n := curval;
         IF NOT scankeyword(843)THEN
           BEGIN
             BEGIN
               IF interaction=3 THEN;
               printnl(262);
               print(1074);
             END;
             BEGIN
               helpptr := 2;
               helpline[1] := 1075;
               helpline[0] := 1076;
             END;
             error;
           END;
         scandimen(false,false,false);
         curbox := vsplit(n,curval);
       END{:1082};
    ELSE{1083:}
      BEGIN
        k := curchr-4;
        savestack[saveptr+0].int := boxcontext;
        IF k=102 THEN IF (boxcontext<1073741824)AND(abs(curlist.modefield)=1)THEN
                        scanspec(3,true)
        ELSE scanspec(2,true)
        ELSE
          BEGIN
            IF k=1 THEN scanspec(4,
                                 true)
            ELSE
              BEGIN
                scanspec(5,true);
                k := 1;
              END;
            normalparagraph;
          END;
        pushnest;
        curlist.modefield := -k;
        IF k=1 THEN
          BEGIN
            curlist.auxfield.int := -65536000;
            IF eqtb[3418].hh.rh<>0 THEN begintokenlist(eqtb[3418].hh.rh,11);
          END
        ELSE
          BEGIN
            curlist.auxfield.hh.lh := 1000;
            IF eqtb[3417].hh.rh<>0 THEN begintokenlist(eqtb[3417].hh.rh,10);
          END;
        goto 10;
      END{:1083}
  END;
  boxend(boxcontext);
  10:
END;
{:1079}{1084:}
PROCEDURE scanbox(boxcontext:integer);
BEGIN{404:}
  REPEAT
    getxtoken;
  UNTIL (curcmd<>10)AND(curcmd<>0){:404};
  IF curcmd=20 THEN beginbox(boxcontext)
  ELSE IF (boxcontext>=1073742337)AND
          ((curcmd=36)OR(curcmd=35))THEN
         BEGIN
           curbox := scanrulespec;
           boxend(boxcontext);
         END
  ELSE
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(1077);
      END;
      BEGIN
        helpptr := 3;
        helpline[2] := 1078;
        helpline[1] := 1079;
        helpline[0] := 1080;
      END;
      backerror;
    END;
END;
{:1084}{1086:}
PROCEDURE package(c:smallnumber);

VAR h: scaled;
  p: halfword;
  d: scaled;
BEGIN
  d := eqtb[5837].int;
  unsave;
  saveptr := saveptr-3;
  IF curlist.modefield=-102 THEN curbox := hpack(mem[curlist.headfield].hh.
                                           rh,savestack[saveptr+2].int,savestack[saveptr+1].int)
  ELSE
    BEGIN
      curbox := 
                vpackage(mem[curlist.headfield].hh.rh,savestack[saveptr+2].int,savestack
                [saveptr+1].int,d);
      IF c=4 THEN{1087:}
        BEGIN
          h := 0;
          p := mem[curbox+5].hh.rh;
          IF p<>0 THEN IF mem[p].hh.b0<=2 THEN h := mem[p+3].int;
          mem[curbox+2].int := mem[curbox+2].int-h+mem[curbox+3].int;
          mem[curbox+3].int := h;
        END{:1087};
    END;
  popnest;
  boxend(savestack[saveptr+0].int);
END;
{:1086}{1091:}
FUNCTION normmin(h:integer): smallnumber;
BEGIN
  IF h<=0 THEN normmin := 1
  ELSE IF h>=63 THEN normmin := 63
  ELSE
    normmin := h;
END;
PROCEDURE newgraf(indented:boolean);
BEGIN
  curlist.pgfield := 0;
  IF (curlist.modefield=1)OR(curlist.headfield<>curlist.tailfield)THEN
    BEGIN
      mem[curlist.tailfield].hh.rh := newparamglue(2);
      curlist.tailfield := mem[curlist.tailfield].hh.rh;
    END;
  pushnest;
  curlist.modefield := 102;
  curlist.auxfield.hh.lh := 1000;
  IF eqtb[5313].int<=0 THEN curlang := 0
  ELSE IF eqtb[5313].int>255 THEN
         curlang := 0
  ELSE curlang := eqtb[5313].int;
  curlist.auxfield.hh.rh := curlang;
  curlist.pgfield := (normmin(eqtb[5314].int)*64+normmin(eqtb[5315].int))
                     *65536+curlang;
  IF indented THEN
    BEGIN
      curlist.tailfield := newnullbox;
      mem[curlist.headfield].hh.rh := curlist.tailfield;
      mem[curlist.tailfield+1].int := eqtb[5830].int;
    END;
  IF eqtb[3414].hh.rh<>0 THEN begintokenlist(eqtb[3414].hh.rh,7);
  IF nestptr=1 THEN buildpage;
END;{:1091}{1093:}
PROCEDURE indentinhmode;

VAR p,q: halfword;
BEGIN
  IF curchr>0 THEN
    BEGIN
      p := newnullbox;
      mem[p+1].int := eqtb[5830].int;
      IF abs(curlist.modefield)=102 THEN curlist.auxfield.hh.lh := 1000
      ELSE
        BEGIN
          q := newnoad;
          mem[q+1].hh.rh := 2;
          mem[q+1].hh.lh := p;
          p := q;
        END;
      BEGIN
        mem[curlist.tailfield].hh.rh := p;
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
    END;
END;
{:1093}{1095:}
PROCEDURE headforvmode;
BEGIN
  IF curlist.modefield<0 THEN IF curcmd<>36 THEN offsave
  ELSE
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(685);
      END;
      printesc(521);
      print(1083);
      BEGIN
        helpptr := 2;
        helpline[1] := 1084;
        helpline[0] := 1085;
      END;
      error;
    END
  ELSE
    BEGIN
      backinput;
      curtok := partoken;
      backinput;
      curinput.indexfield := 4;
    END;
END;{:1095}{1096:}
PROCEDURE endgraf;
BEGIN
  IF curlist.modefield=102 THEN
    BEGIN
      IF curlist.headfield=curlist.
         tailfield THEN popnest
      ELSE linebreak(eqtb[5269].int);
      normalparagraph;
      errorcount := 0;
    END;
END;{:1096}{1099:}
PROCEDURE begininsertoradjust;
BEGIN
  IF curcmd=38 THEN curval := 255
  ELSE
    BEGIN
      scaneightbitint;
      IF curval=255 THEN
        BEGIN
          BEGIN
            IF interaction=3 THEN;
            printnl(262);
            print(1086);
          END;
          printesc(330);
          printint(255);
          BEGIN
            helpptr := 1;
            helpline[0] := 1087;
          END;
          error;
          curval := 0;
        END;
    END;
  savestack[saveptr+0].int := curval;
  saveptr := saveptr+1;
  newsavelevel(11);
  scanleftbrace;
  normalparagraph;
  pushnest;
  curlist.modefield := -1;
  curlist.auxfield.int := -65536000;
END;{:1099}{1101:}
PROCEDURE makemark;

VAR p: halfword;
BEGIN
  p := scantoks(false,true);
  p := getnode(2);
  mem[p].hh.b0 := 4;
  mem[p].hh.b1 := 0;
  mem[p+1].int := defref;
  mem[curlist.tailfield].hh.rh := p;
  curlist.tailfield := p;
END;
{:1101}{1103:}
PROCEDURE appendpenalty;
BEGIN
  scanint;
  BEGIN
    mem[curlist.tailfield].hh.rh := newpenalty(curval);
    curlist.tailfield := mem[curlist.tailfield].hh.rh;
  END;
  IF curlist.modefield=1 THEN buildpage;
END;
{:1103}{1105:}
PROCEDURE deletelast;

LABEL 10;

VAR p,q: halfword;
  m: quarterword;
BEGIN
  IF (curlist.modefield=1)AND(curlist.tailfield=curlist.headfield)
    THEN{1106:}
    BEGIN
      IF (curchr<>10)OR(lastglue<>65535)THEN
        BEGIN
          youcant;
          BEGIN
            helpptr := 2;
            helpline[1] := 1072;
            helpline[0] := 1088;
          END;
          IF curchr=11 THEN helpline[0] := (1089)
          ELSE IF curchr<>10 THEN helpline[0] 
                 := (1090);
          error;
        END;
    END{:1106}
  ELSE
    BEGIN
      IF NOT(curlist.tailfield>=himemmin)THEN IF mem[
                                                 curlist.tailfield].hh.b0=curchr THEN
                                                BEGIN
                                                  q := curlist.headfield;
                                                  REPEAT
                                                    p := q;
                                                    IF NOT(q>=himemmin)THEN IF mem[q].hh.b0=7 THEN
                                                                              BEGIN
                                                                                FOR m:=1 TO mem[q].
                                                                                    hh.b1 DO
                                                                                  p := mem[p].hh.rh;
                                                                                IF p=curlist.
                                                                                   tailfield THEN
                                                                                  goto 10;
                                                                              END;
                                                    q := mem[p].hh.rh;
                                                  UNTIL q=curlist.tailfield;
                                                  mem[p].hh.rh := 0;
                                                  flushnodelist(curlist.tailfield);
                                                  curlist.tailfield := p;
                                                END;
    END;
  10:
END;
{:1105}{1110:}
PROCEDURE unpackage;

LABEL 10;

VAR p: halfword;
  c: 0..1;
BEGIN
  c := curchr;
  scaneightbitint;
  p := eqtb[3678+curval].hh.rh;
  IF p=0 THEN goto 10;
  IF (abs(curlist.modefield)=203)OR((abs(curlist.modefield)=1)AND(mem[p].hh
     .b0<>1))OR((abs(curlist.modefield)=102)AND(mem[p].hh.b0<>0))THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(1098);
      END;
      BEGIN
        helpptr := 3;
        helpline[2] := 1099;
        helpline[1] := 1100;
        helpline[0] := 1101;
      END;
      error;
      goto 10;
    END;
  IF c=1 THEN mem[curlist.tailfield].hh.rh := copynodelist(mem[p+5].hh.rh)
  ELSE
    BEGIN
      mem[curlist.tailfield].hh.rh := mem[p+5].hh.rh;
      eqtb[3678+curval].hh.rh := 0;
      freenode(p,7);
    END;
  WHILE mem[curlist.tailfield].hh.rh<>0 DO
    curlist.tailfield := mem[curlist.
                         tailfield].hh.rh;
  10:
END;{:1110}{1113:}
PROCEDURE appenditaliccorrection;

LABEL 10;

VAR p: halfword;
  f: internalfontnumber;
BEGIN
  IF curlist.tailfield<>curlist.headfield THEN
    BEGIN
      IF (curlist.
         tailfield>=himemmin)THEN p := curlist.tailfield
      ELSE IF mem[curlist.
              tailfield].hh.b0=6 THEN p := curlist.tailfield+1
      ELSE goto 10;
      f := mem[p].hh.b0;
      BEGIN
        mem[curlist.tailfield].hh.rh := newkern(fontinfo[italicbase[f]+(
                                        fontinfo[charbase[f]+mem[p].hh.b1].qqqq.b2)DIV 4].int);
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      mem[curlist.tailfield].hh.b1 := 1;
    END;
  10:
END;
{:1113}{1117:}
PROCEDURE appenddiscretionary;

VAR c: integer;
BEGIN
  BEGIN
    mem[curlist.tailfield].hh.rh := newdisc;
    curlist.tailfield := mem[curlist.tailfield].hh.rh;
  END;
  IF curchr=1 THEN
    BEGIN
      c := hyphenchar[eqtb[3934].hh.rh];
      IF c>=0 THEN IF c<256 THEN mem[curlist.tailfield+1].hh.lh := newcharacter(
                                                                   eqtb[3934].hh.rh,c);
    END
  ELSE
    BEGIN
      saveptr := saveptr+1;
      savestack[saveptr-1].int := 0;
      newsavelevel(10);
      scanleftbrace;
      pushnest;
      curlist.modefield := -102;
      curlist.auxfield.hh.lh := 1000;
    END;
END;
{:1117}{1119:}
PROCEDURE builddiscretionary;

LABEL 30,10;

VAR p,q: halfword;
  n: integer;
BEGIN
  unsave;{1121:}
  q := curlist.headfield;
  p := mem[q].hh.rh;
  n := 0;
  WHILE p<>0 DO
    BEGIN
      IF NOT(p>=himemmin)THEN IF mem[p].hh.b0>2 THEN IF 
                                                        mem[p].hh.b0<>11 THEN IF mem[p].hh.b0<>6
                                                                                THEN
                                                                                BEGIN
                                                                                  BEGIN
                                                                                    IF interaction
                                                                                       =3 THEN;
                                                                                    printnl(262);
                                                                                    print(1108);
                                                                                  END;
                                                                                  BEGIN
                                                                                    helpptr := 1;
                                                                                    helpline[0] := 
                                                                                                1109
                                                                                    ;
                                                                                  END;
                                                                                  error;
                                                                                  begindiagnostic;
                                                                                  printnl(1110);
                                                                                  showbox(p);
                                                                                  enddiagnostic(true
                                                                                  );
                                                                                  flushnodelist(p);
                                                                                  mem[q].hh.rh := 0;
                                                                                  goto 30;
                                                                                END;
      q := p;
      p := mem[q].hh.rh;
      n := n+1;
    END;
  30:{:1121};
  p := mem[curlist.headfield].hh.rh;
  popnest;
  CASE savestack[saveptr-1].int OF 
    0: mem[curlist.tailfield+1].hh.lh := p;
    1: mem[curlist.tailfield+1].hh.rh := p;
    2:{1120:}
       BEGIN
         IF (n>0)AND(abs(curlist.modefield)=203)THEN
           BEGIN
             BEGIN
               IF 
                  interaction=3 THEN;
               printnl(262);
               print(1102);
             END;
             printesc(349);
             BEGIN
               helpptr := 2;
               helpline[1] := 1103;
               helpline[0] := 1104;
             END;
             flushnodelist(p);
             n := 0;
             error;
           END
         ELSE mem[curlist.tailfield].hh.rh := p;
         IF n<=255 THEN mem[curlist.tailfield].hh.b1 := n
         ELSE
           BEGIN
             BEGIN
               IF 
                  interaction=3 THEN;
               printnl(262);
               print(1105);
             END;
             BEGIN
               helpptr := 2;
               helpline[1] := 1106;
               helpline[0] := 1107;
             END;
             error;
           END;
         IF n>0 THEN curlist.tailfield := q;
         saveptr := saveptr-1;
         goto 10;
       END{:1120};
  END;
  savestack[saveptr-1].int := savestack[saveptr-1].int+1;
  newsavelevel(10);
  scanleftbrace;
  pushnest;
  curlist.modefield := -102;
  curlist.auxfield.hh.lh := 1000;
  10:
END;{:1119}{1123:}
PROCEDURE makeaccent;

VAR s,t: real;
  p,q,r: halfword;
  f: internalfontnumber;
  a,h,x,w,delta: scaled;
  i: fourquarters;
BEGIN
  scancharnum;
  f := eqtb[3934].hh.rh;
  p := newcharacter(f,curval);
  IF p<>0 THEN
    BEGIN
      x := fontinfo[5+parambase[f]].int;
      s := fontinfo[1+parambase[f]].int/65536.0;
      a := fontinfo[widthbase[f]+fontinfo[charbase[f]+mem[p].hh.b1].qqqq.b0].int
      ;
      doassignments;{1124:}
      q := 0;
      f := eqtb[3934].hh.rh;
      IF (curcmd=11)OR(curcmd=12)OR(curcmd=68)THEN q := newcharacter(f,curchr)
      ELSE IF curcmd=16 THEN
             BEGIN
               scancharnum;
               q := newcharacter(f,curval);
             END
      ELSE backinput{:1124};
      IF q<>0 THEN{1125:}
        BEGIN
          t := fontinfo[1+parambase[f]].int/65536.0;
          i := fontinfo[charbase[f]+mem[q].hh.b1].qqqq;
          w := fontinfo[widthbase[f]+i.b0].int;
          h := fontinfo[heightbase[f]+(i.b1)DIV 16].int;
          IF h<>x THEN
            BEGIN
              p := hpack(p,0,1);
              mem[p+4].int := x-h;
            END;
          delta := round((w-a)/2.0+h*t-x*s);
          r := newkern(delta);
          mem[r].hh.b1 := 2;
          mem[curlist.tailfield].hh.rh := r;
          mem[r].hh.rh := p;
          curlist.tailfield := newkern(-a-delta);
          mem[curlist.tailfield].hh.b1 := 2;
          mem[p].hh.rh := curlist.tailfield;
          p := q;
        END{:1125};
      mem[curlist.tailfield].hh.rh := p;
      curlist.tailfield := p;
      curlist.auxfield.hh.lh := 1000;
    END;
END;{:1123}{1127:}
PROCEDURE alignerror;
BEGIN
  IF abs(alignstate)>2 THEN{1128:}
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(1115);
      END;
      printcmdchr(curcmd,curchr);
      IF curtok=1062 THEN
        BEGIN
          BEGIN
            helpptr := 6;
            helpline[5] := 1116;
            helpline[4] := 1117;
            helpline[3] := 1118;
            helpline[2] := 1119;
            helpline[1] := 1120;
            helpline[0] := 1121;
          END;
        END
      ELSE
        BEGIN
          BEGIN
            helpptr := 5;
            helpline[4] := 1116;
            helpline[3] := 1122;
            helpline[2] := 1119;
            helpline[1] := 1120;
            helpline[0] := 1121;
          END;
        END;
      error;
    END{:1128}
  ELSE
    BEGIN
      backinput;
      IF alignstate<0 THEN
        BEGIN
          BEGIN
            IF interaction=3 THEN;
            printnl(262);
            print(657);
          END;
          alignstate := alignstate+1;
          curtok := 379;
        END
      ELSE
        BEGIN
          BEGIN
            IF interaction=3 THEN;
            printnl(262);
            print(1111);
          END;
          alignstate := alignstate-1;
          curtok := 637;
        END;
      BEGIN
        helpptr := 3;
        helpline[2] := 1112;
        helpline[1] := 1113;
        helpline[0] := 1114;
      END;
      inserror;
    END;
END;{:1127}{1129:}
PROCEDURE noalignerror;
BEGIN
  BEGIN
    IF interaction=3 THEN;
    printnl(262);
    print(1115);
  END;
  printesc(527);
  BEGIN
    helpptr := 2;
    helpline[1] := 1123;
    helpline[0] := 1124;
  END;
  error;
END;
PROCEDURE omiterror;
BEGIN
  BEGIN
    IF interaction=3 THEN;
    printnl(262);
    print(1115);
  END;
  printesc(530);
  BEGIN
    helpptr := 2;
    helpline[1] := 1125;
    helpline[0] := 1124;
  END;
  error;
END;
{:1129}{1131:}
PROCEDURE doendv;
BEGIN
  baseptr := inputptr;
  inputstack[baseptr] := curinput;
  WHILE (inputstack[baseptr].indexfield<>2)AND(inputstack[baseptr].locfield
        =0)AND(inputstack[baseptr].statefield=0) DO
    baseptr := baseptr-1;
  IF (inputstack[baseptr].indexfield<>2)OR(inputstack[baseptr].locfield<>0)
     OR(inputstack[baseptr].statefield<>0)THEN fatalerror(595);
  IF curgroup=6 THEN
    BEGIN
      endgraf;
      IF fincol THEN finrow;
    END
  ELSE offsave;
END;{:1131}{1135:}
PROCEDURE cserror;
BEGIN
  BEGIN
    IF interaction=3 THEN;
    printnl(262);
    print(777);
  END;
  printesc(505);
  BEGIN
    helpptr := 1;
    helpline[0] := 1127;
  END;
  error;
END;
{:1135}{1136:}
PROCEDURE pushmath(c:groupcode);
BEGIN
  pushnest;
  curlist.modefield := -203;
  curlist.auxfield.int := 0;
  newsavelevel(c);
END;
{:1136}{1138:}
PROCEDURE initmath;

LABEL 21,40,45,30;

VAR w: scaled;
  l: scaled;
  s: scaled;
  p: halfword;
  q: halfword;
  f: internalfontnumber;
  n: integer;
  v: scaled;
  d: scaled;
BEGIN
  gettoken;
  IF (curcmd=3)AND(curlist.modefield>0)THEN{1145:}
    BEGIN
      IF curlist.
         headfield=curlist.tailfield THEN
        BEGIN
          popnest;
          w := -1073741823;
        END
      ELSE
        BEGIN
          linebreak(eqtb[5270].int);
{1146:}
          v := mem[justbox+4].int+2*fontinfo[6+parambase[eqtb[3934].hh.rh]].
               int;
          w := -1073741823;
          p := mem[justbox+5].hh.rh;
          WHILE p<>0 DO
            BEGIN{1147:}
              21: IF (p>=himemmin)THEN
                    BEGIN
                      f := mem[p].hh.b0;
                      d := fontinfo[widthbase[f]+fontinfo[charbase[f]+mem[p].hh.b1].qqqq.b0].int
                      ;
                      goto 40;
                    END;
              CASE mem[p].hh.b0 OF 
                0,1,2:
                       BEGIN
                         d := mem[p+1].int;
                         goto 40;
                       END;
                6:{652:}
                   BEGIN
                     mem[29988] := mem[p+1];
                     mem[29988].hh.rh := mem[p].hh.rh;
                     p := 29988;
                     goto 21;
                   END{:652};
                11,9: d := mem[p+1].int;
                10:{1148:}
                    BEGIN
                      q := mem[p+1].hh.lh;
                      d := mem[q+1].int;
                      IF mem[justbox+5].hh.b0=1 THEN
                        BEGIN
                          IF (mem[justbox+5].hh.b1=mem[q].hh.
                             b0)AND(mem[q+2].int<>0)THEN v := 1073741823;
                        END
                      ELSE IF mem[justbox+5].hh.b0=2 THEN
                             BEGIN
                               IF (mem[justbox+5].hh.b1=
                                  mem[q].hh.b1)AND(mem[q+3].int<>0)THEN v := 1073741823;
                             END;
                      IF mem[p].hh.b1>=100 THEN goto 40;
                    END{:1148};
                8:{1361:}d := 0{:1361};
                ELSE d := 0
              END{:1147};
              IF v<1073741823 THEN v := v+d;
              goto 45;
              40: IF v<1073741823 THEN
                    BEGIN
                      v := v+d;
                      w := v;
                    END
                  ELSE
                    BEGIN
                      w := 1073741823;
                      goto 30;
                    END;
              45: p := mem[p].hh.rh;
            END;
          30:{:1146};
        END;
{1149:}
      IF eqtb[3412].hh.rh=0 THEN IF (eqtb[5847].int<>0)AND(((eqtb[5304].
                                    int>=0)AND(curlist.pgfield+2>eqtb[5304].int))OR(curlist.pgfield+
                                    1<-eqtb[
                                    5304].int))THEN
                                   BEGIN
                                     l := eqtb[5833].int-abs(eqtb[5847].int);
                                     IF eqtb[5847].int>0 THEN s := eqtb[5847].int
                                     ELSE s := 0;
                                   END
      ELSE
        BEGIN
          l := eqtb[5833].int;
          s := 0;
        END
      ELSE
        BEGIN
          n := mem[eqtb[3412].hh.rh].hh.lh;
          IF curlist.pgfield+2>=n THEN p := eqtb[3412].hh.rh+2*n
          ELSE p := eqtb[3412].
                    hh.rh+2*(curlist.pgfield+2);
          s := mem[p-1].int;
          l := mem[p].int;
        END{:1149};
      pushmath(15);
      curlist.modefield := 203;
      eqworddefine(5307,-1);
      eqworddefine(5843,w);
      eqworddefine(5844,l);
      eqworddefine(5845,s);
      IF eqtb[3416].hh.rh<>0 THEN begintokenlist(eqtb[3416].hh.rh,9);
      IF nestptr=1 THEN buildpage;
    END{:1145}
  ELSE
    BEGIN
      backinput;
{1139:}
      BEGIN
        pushmath(15);
        eqworddefine(5307,-1);
        IF eqtb[3415].hh.rh<>0 THEN begintokenlist(eqtb[3415].hh.rh,8);
      END{:1139};
    END;
END;{:1138}{1142:}
PROCEDURE starteqno;
BEGIN
  savestack[saveptr+0].int := curchr;
  saveptr := saveptr+1;
{1139:}
  BEGIN
    pushmath(15);
    eqworddefine(5307,-1);
    IF eqtb[3415].hh.rh<>0 THEN begintokenlist(eqtb[3415].hh.rh,8);
  END{:1139};
END;{:1142}{1151:}
PROCEDURE scanmath(p:halfword);

LABEL 20,21,10;

VAR c: integer;
BEGIN
  20:{404:}REPEAT
             getxtoken;
      UNTIL (curcmd<>10)AND(curcmd<>0){:404};
  21: CASE curcmd OF 
        11,12,68:
                  BEGIN
                    c := eqtb[5007+curchr].hh.rh;
                    IF c=32768 THEN
                      BEGIN{1152:}
                        BEGIN
                          curcs := curchr+1;
                          curcmd := eqtb[curcs].hh.b0;
                          curchr := eqtb[curcs].hh.rh;
                          xtoken;
                          backinput;
                        END{:1152};
                        goto 20;
                      END;
                  END;
        16:
            BEGIN
              scancharnum;
              curchr := curval;
              curcmd := 68;
              goto 21;
            END;
        17:
            BEGIN
              scanfifteenbitint;
              c := curval;
            END;
        69: c := curchr;
        15:
            BEGIN
              scantwentysevenbitint;
              c := curval DIV 4096;
            END;
        ELSE{1153:}
          BEGIN
            backinput;
            scanleftbrace;
            savestack[saveptr+0].int := p;
            saveptr := saveptr+1;
            pushmath(9);
            goto 10;
          END{:1153}
      END;
  mem[p].hh.rh := 1;
  mem[p].hh.b1 := c MOD 256;
  IF (c>=28672)AND((eqtb[5307].int>=0)AND(eqtb[5307].int<16))THEN mem[p].hh
    .b0 := eqtb[5307].int
  ELSE mem[p].hh.b0 := (c DIV 256)MOD 16;
  10:
END;
{:1151}{1155:}
PROCEDURE setmathchar(c:integer);

VAR p: halfword;
BEGIN
  IF c>=32768 THEN{1152:}
    BEGIN
      curcs := curchr+1;
      curcmd := eqtb[curcs].hh.b0;
      curchr := eqtb[curcs].hh.rh;
      xtoken;
      backinput;
    END{:1152}
  ELSE
    BEGIN
      p := newnoad;
      mem[p+1].hh.rh := 1;
      mem[p+1].hh.b1 := c MOD 256;
      mem[p+1].hh.b0 := (c DIV 256)MOD 16;
      IF c>=28672 THEN
        BEGIN
          IF ((eqtb[5307].int>=0)AND(eqtb[5307].int<16))THEN
            mem[p+1].hh.b0 := eqtb[5307].int;
          mem[p].hh.b0 := 16;
        END
      ELSE mem[p].hh.b0 := 16+(c DIV 4096);
      mem[curlist.tailfield].hh.rh := p;
      curlist.tailfield := p;
    END;
END;{:1155}{1159:}
PROCEDURE mathlimitswitch;

LABEL 10;
BEGIN
  IF curlist.headfield<>curlist.tailfield THEN IF mem[curlist.
                                                  tailfield].hh.b0=17 THEN
                                                 BEGIN
                                                   mem[curlist.tailfield].hh.b1 := curchr;
                                                   goto 10;
                                                 END;
  BEGIN
    IF interaction=3 THEN;
    printnl(262);
    print(1131);
  END;
  BEGIN
    helpptr := 1;
    helpline[0] := 1132;
  END;
  error;
  10:
END;
{:1159}{1160:}
PROCEDURE scandelimiter(p:halfword;r:boolean);
BEGIN
  IF r THEN scantwentysevenbitint
  ELSE
    BEGIN{404:}
      REPEAT
        getxtoken;
      UNTIL (curcmd<>10)AND(curcmd<>0){:404};
      CASE curcmd OF 
        11,12: curval := eqtb[5574+curchr].int;
        15: scantwentysevenbitint;
        ELSE curval := -1
      END;
    END;
  IF curval<0 THEN{1161:}
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(1133);
      END;
      BEGIN
        helpptr := 6;
        helpline[5] := 1134;
        helpline[4] := 1135;
        helpline[3] := 1136;
        helpline[2] := 1137;
        helpline[1] := 1138;
        helpline[0] := 1139;
      END;
      backerror;
      curval := 0;
    END{:1161};
  mem[p].qqqq.b0 := (curval DIV 1048576)MOD 16;
  mem[p].qqqq.b1 := (curval DIV 4096)MOD 256;
  mem[p].qqqq.b2 := (curval DIV 256)MOD 16;
  mem[p].qqqq.b3 := curval MOD 256;
END;{:1160}{1163:}
PROCEDURE mathradical;
BEGIN
  BEGIN
    mem[curlist.tailfield].hh.rh := getnode(5);
    curlist.tailfield := mem[curlist.tailfield].hh.rh;
  END;
  mem[curlist.tailfield].hh.b0 := 24;
  mem[curlist.tailfield].hh.b1 := 0;
  mem[curlist.tailfield+1].hh := emptyfield;
  mem[curlist.tailfield+3].hh := emptyfield;
  mem[curlist.tailfield+2].hh := emptyfield;
  scandelimiter(curlist.tailfield+4,true);
  scanmath(curlist.tailfield+1);
END;{:1163}{1165:}
PROCEDURE mathac;
BEGIN
  IF curcmd=45 THEN{1166:}
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(1140);
      END;
      printesc(523);
      print(1141);
      BEGIN
        helpptr := 2;
        helpline[1] := 1142;
        helpline[0] := 1143;
      END;
      error;
    END{:1166};
  BEGIN
    mem[curlist.tailfield].hh.rh := getnode(5);
    curlist.tailfield := mem[curlist.tailfield].hh.rh;
  END;
  mem[curlist.tailfield].hh.b0 := 28;
  mem[curlist.tailfield].hh.b1 := 0;
  mem[curlist.tailfield+1].hh := emptyfield;
  mem[curlist.tailfield+3].hh := emptyfield;
  mem[curlist.tailfield+2].hh := emptyfield;
  mem[curlist.tailfield+4].hh.rh := 1;
  scanfifteenbitint;
  mem[curlist.tailfield+4].hh.b1 := curval MOD 256;
  IF (curval>=28672)AND((eqtb[5307].int>=0)AND(eqtb[5307].int<16))THEN mem[
    curlist.tailfield+4].hh.b0 := eqtb[5307].int
  ELSE mem[curlist.tailfield+4]
    .hh.b0 := (curval DIV 256)MOD 16;
  scanmath(curlist.tailfield+1);
END;
{:1165}{1172:}
PROCEDURE appendchoices;
BEGIN
  BEGIN
    mem[curlist.tailfield].hh.rh := newchoice;
    curlist.tailfield := mem[curlist.tailfield].hh.rh;
  END;
  saveptr := saveptr+1;
  savestack[saveptr-1].int := 0;
  pushmath(13);
  scanleftbrace;
END;
{:1172}{1174:}{1184:}
FUNCTION finmlist(p:halfword): halfword;

VAR q: halfword;
BEGIN
  IF curlist.auxfield.int<>0 THEN{1185:}
    BEGIN
      mem[curlist.auxfield.
      int+3].hh.rh := 3;
      mem[curlist.auxfield.int+3].hh.lh := mem[curlist.headfield].hh.rh;
      IF p=0 THEN q := curlist.auxfield.int
      ELSE
        BEGIN
          q := mem[curlist.auxfield.
               int+2].hh.lh;
          IF mem[q].hh.b0<>30 THEN confusion(878);
          mem[curlist.auxfield.int+2].hh.lh := mem[q].hh.rh;
          mem[q].hh.rh := curlist.auxfield.int;
          mem[curlist.auxfield.int].hh.rh := p;
        END;
    END{:1185}
  ELSE
    BEGIN
      mem[curlist.tailfield].hh.rh := p;
      q := mem[curlist.headfield].hh.rh;
    END;
  popnest;
  finmlist := q;
END;
{:1184}
PROCEDURE buildchoices;

LABEL 10;

VAR p: halfword;
BEGIN
  unsave;
  p := finmlist(0);
  CASE savestack[saveptr-1].int OF 
    0: mem[curlist.tailfield+1].hh.lh := p;
    1: mem[curlist.tailfield+1].hh.rh := p;
    2: mem[curlist.tailfield+2].hh.lh := p;
    3:
       BEGIN
         mem[curlist.tailfield+2].hh.rh := p;
         saveptr := saveptr-1;
         goto 10;
       END;
  END;
  savestack[saveptr-1].int := savestack[saveptr-1].int+1;
  pushmath(13);
  scanleftbrace;
  10:
END;{:1174}{1176:}
PROCEDURE subsup;

VAR t: smallnumber;
  p: halfword;
BEGIN
  t := 0;
  p := 0;
  IF curlist.tailfield<>curlist.headfield THEN IF (mem[curlist.tailfield].
                                                  hh.b0>=16)AND(mem[curlist.tailfield].hh.b0<30)THEN
                                                 BEGIN
                                                   p := curlist.
                                                        tailfield+2+curcmd-7;
                                                   t := mem[p].hh.rh;
                                                 END;
  IF (p=0)OR(t<>0)THEN{1177:}
    BEGIN
      BEGIN
        mem[curlist.tailfield].hh.rh := 
                                        newnoad;
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      p := curlist.tailfield+2+curcmd-7;
      IF t<>0 THEN
        BEGIN
          IF curcmd=7 THEN
            BEGIN
              BEGIN
                IF interaction=3 THEN;
                printnl(262);
                print(1144);
              END;
              BEGIN
                helpptr := 1;
                helpline[0] := 1145;
              END;
            END
          ELSE
            BEGIN
              BEGIN
                IF interaction=3 THEN;
                printnl(262);
                print(1146);
              END;
              BEGIN
                helpptr := 1;
                helpline[0] := 1147;
              END;
            END;
          error;
        END;
    END{:1177};
  scanmath(p);
END;{:1176}{1181:}
PROCEDURE mathfraction;

VAR c: smallnumber;
BEGIN
  c := curchr;
  IF curlist.auxfield.int<>0 THEN{1183:}
    BEGIN
      IF c>=3 THEN
        BEGIN
          scandelimiter(29988,false);
          scandelimiter(29988,false);
        END;
      IF c MOD 3=0 THEN scandimen(false,false,false);
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(1154);
      END;
      BEGIN
        helpptr := 3;
        helpline[2] := 1155;
        helpline[1] := 1156;
        helpline[0] := 1157;
      END;
      error;
    END{:1183}
  ELSE
    BEGIN
      curlist.auxfield.int := getnode(6);
      mem[curlist.auxfield.int].hh.b0 := 25;
      mem[curlist.auxfield.int].hh.b1 := 0;
      mem[curlist.auxfield.int+2].hh.rh := 3;
      mem[curlist.auxfield.int+2].hh.lh := mem[curlist.headfield].hh.rh;
      mem[curlist.auxfield.int+3].hh := emptyfield;
      mem[curlist.auxfield.int+4].qqqq := nulldelimiter;
      mem[curlist.auxfield.int+5].qqqq := nulldelimiter;
      mem[curlist.headfield].hh.rh := 0;
      curlist.tailfield := curlist.headfield;
{1182:}
      IF c>=3 THEN
        BEGIN
          scandelimiter(curlist.auxfield.int+4,false);
          scandelimiter(curlist.auxfield.int+5,false);
        END;
      CASE c MOD 3 OF 
        0:
           BEGIN
             scandimen(false,false,false);
             mem[curlist.auxfield.int+1].int := curval;
           END;
        1: mem[curlist.auxfield.int+1].int := 1073741824;
        2: mem[curlist.auxfield.int+1].int := 0;
      END{:1182};
    END;
END;
{:1181}{1191:}
PROCEDURE mathleftright;

VAR t: smallnumber;
  p: halfword;
BEGIN
  t := curchr;
  IF (t=31)AND(curgroup<>16)THEN{1192:}
    BEGIN
      IF curgroup=15 THEN
        BEGIN
          scandelimiter(29988,false);
          BEGIN
            IF interaction=3 THEN;
            printnl(262);
            print(777);
          END;
          printesc(878);
          BEGIN
            helpptr := 1;
            helpline[0] := 1158;
          END;
          error;
        END
      ELSE offsave;
    END{:1192}
  ELSE
    BEGIN
      p := newnoad;
      mem[p].hh.b0 := t;
      scandelimiter(p+1,false);
      IF t=30 THEN
        BEGIN
          pushmath(16);
          mem[curlist.headfield].hh.rh := p;
          curlist.tailfield := p;
        END
      ELSE
        BEGIN
          p := finmlist(p);
          unsave;
          BEGIN
            mem[curlist.tailfield].hh.rh := newnoad;
            curlist.tailfield := mem[curlist.tailfield].hh.rh;
          END;
          mem[curlist.tailfield].hh.b0 := 23;
          mem[curlist.tailfield+1].hh.rh := 3;
          mem[curlist.tailfield+1].hh.lh := p;
        END;
    END;
END;
{:1191}{1194:}
PROCEDURE aftermath;

VAR l: boolean;
  danger: boolean;
  m: integer;
  p: halfword;
  a: halfword;{1198:}
  b: halfword;
  w: scaled;
  z: scaled;
  e: scaled;
  q: scaled;
  d: scaled;
  s: scaled;
  g1,g2: smallnumber;
  r: halfword;
  t: halfword;{:1198}
BEGIN
  danger := false;
{1195:}
  IF (fontparams[eqtb[3937].hh.rh]<22)OR(fontparams[eqtb[3953].hh.rh
     ]<22)OR(fontparams[eqtb[3969].hh.rh]<22)THEN
    BEGIN
      BEGIN
        IF interaction=
           3 THEN;
        printnl(262);
        print(1159);
      END;
      BEGIN
        helpptr := 3;
        helpline[2] := 1160;
        helpline[1] := 1161;
        helpline[0] := 1162;
      END;
      error;
      flushmath;
      danger := true;
    END
  ELSE IF (fontparams[eqtb[3938].hh.rh]<13)OR(fontparams[eqtb[3954].hh.
          rh]<13)OR(fontparams[eqtb[3970].hh.rh]<13)THEN
         BEGIN
           BEGIN
             IF 
                interaction=3 THEN;
             printnl(262);
             print(1163);
           END;
           BEGIN
             helpptr := 3;
             helpline[2] := 1164;
             helpline[1] := 1165;
             helpline[0] := 1166;
           END;
           error;
           flushmath;
           danger := true;
         END{:1195};
  m := curlist.modefield;
  l := false;
  p := finmlist(0);
  IF curlist.modefield=-m THEN
    BEGIN{1197:}
      BEGIN
        getxtoken;
        IF curcmd<>3 THEN
          BEGIN
            BEGIN
              IF interaction=3 THEN;
              printnl(262);
              print(1167);
            END;
            BEGIN
              helpptr := 2;
              helpline[1] := 1168;
              helpline[0] := 1169;
            END;
            backerror;
          END;
      END{:1197};
      curmlist := p;
      curstyle := 2;
      mlistpenalties := false;
      mlisttohlist;
      a := hpack(mem[29997].hh.rh,0,1);
      unsave;
      saveptr := saveptr-1;
      IF savestack[saveptr+0].int=1 THEN l := true;
      danger := false;
{1195:}
      IF (fontparams[eqtb[3937].hh.rh]<22)OR(fontparams[eqtb[3953].hh.rh
         ]<22)OR(fontparams[eqtb[3969].hh.rh]<22)THEN
        BEGIN
          BEGIN
            IF interaction=
               3 THEN;
            printnl(262);
            print(1159);
          END;
          BEGIN
            helpptr := 3;
            helpline[2] := 1160;
            helpline[1] := 1161;
            helpline[0] := 1162;
          END;
          error;
          flushmath;
          danger := true;
        END
      ELSE IF (fontparams[eqtb[3938].hh.rh]<13)OR(fontparams[eqtb[3954].hh.
              rh]<13)OR(fontparams[eqtb[3970].hh.rh]<13)THEN
             BEGIN
               BEGIN
                 IF 
                    interaction=3 THEN;
                 printnl(262);
                 print(1163);
               END;
               BEGIN
                 helpptr := 3;
                 helpline[2] := 1164;
                 helpline[1] := 1165;
                 helpline[0] := 1166;
               END;
               error;
               flushmath;
               danger := true;
             END{:1195};
      m := curlist.modefield;
      p := finmlist(0);
    END
  ELSE a := 0;
  IF m<0 THEN{1196:}
    BEGIN
      BEGIN
        mem[curlist.tailfield].hh.rh := newmath(eqtb
                                        [5831].int,0);
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      curmlist := p;
      curstyle := 2;
      mlistpenalties := (curlist.modefield>0);
      mlisttohlist;
      mem[curlist.tailfield].hh.rh := mem[29997].hh.rh;
      WHILE mem[curlist.tailfield].hh.rh<>0 DO
        curlist.tailfield := mem[curlist.
                             tailfield].hh.rh;
      BEGIN
        mem[curlist.tailfield].hh.rh := newmath(eqtb[5831].int,1);
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      curlist.auxfield.hh.lh := 1000;
      unsave;
    END{:1196}
  ELSE
    BEGIN
      IF a=0 THEN{1197:}
        BEGIN
          getxtoken;
          IF curcmd<>3 THEN
            BEGIN
              BEGIN
                IF interaction=3 THEN;
                printnl(262);
                print(1167);
              END;
              BEGIN
                helpptr := 2;
                helpline[1] := 1168;
                helpline[0] := 1169;
              END;
              backerror;
            END;
        END{:1197};{1199:}
      curmlist := p;
      curstyle := 0;
      mlistpenalties := false;
      mlisttohlist;
      p := mem[29997].hh.rh;
      adjusttail := 29995;
      b := hpack(p,0,1);
      p := mem[b+5].hh.rh;
      t := adjusttail;
      adjusttail := 0;
      w := mem[b+1].int;
      z := eqtb[5844].int;
      s := eqtb[5845].int;
      IF (a=0)OR danger THEN
        BEGIN
          e := 0;
          q := 0;
        END
      ELSE
        BEGIN
          e := mem[a+1].int;
          q := e+fontinfo[6+parambase[eqtb[3937].hh.rh]].int;
        END;
      IF w+q>z THEN{1201:}
        BEGIN
          IF (e<>0)AND((w-totalshrink[0]+q<=z)OR(
             totalshrink[1]<>0)OR(totalshrink[2]<>0)OR(totalshrink[3]<>0))THEN
            BEGIN
              freenode(b,7);
              b := hpack(p,z-q,0);
            END
          ELSE
            BEGIN
              e := 0;
              IF w>z THEN
                BEGIN
                  freenode(b,7);
                  b := hpack(p,z,0);
                END;
            END;
          w := mem[b+1].int;
        END{:1201};{1202:}
      d := half(z-w);
      IF (e>0)AND(d<2*e)THEN
        BEGIN
          d := half(z-w-e);
          IF p<>0 THEN IF NOT(p>=himemmin)THEN IF mem[p].hh.b0=10 THEN d := 0;
        END{:1202};
{1203:}
      BEGIN
        mem[curlist.tailfield].hh.rh := newpenalty(eqtb[5274].int);
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      IF (d+s<=eqtb[5843].int)OR l THEN
        BEGIN
          g1 := 3;
          g2 := 4;
        END
      ELSE
        BEGIN
          g1 := 5;
          g2 := 6;
        END;
      IF l AND(e=0)THEN
        BEGIN
          mem[a+4].int := s;
          appendtovlist(a);
          BEGIN
            mem[curlist.tailfield].hh.rh := newpenalty(10000);
            curlist.tailfield := mem[curlist.tailfield].hh.rh;
          END;
        END
      ELSE
        BEGIN
          mem[curlist.tailfield].hh.rh := newparamglue(g1);
          curlist.tailfield := mem[curlist.tailfield].hh.rh;
        END{:1203};
{1204:}
      IF e<>0 THEN
        BEGIN
          r := newkern(z-w-e-d);
          IF l THEN
            BEGIN
              mem[a].hh.rh := r;
              mem[r].hh.rh := b;
              b := a;
              d := 0;
            END
          ELSE
            BEGIN
              mem[b].hh.rh := r;
              mem[r].hh.rh := a;
            END;
          b := hpack(b,0,1);
        END;
      mem[b+4].int := s+d;
      appendtovlist(b){:1204};
{1205:}
      IF (a<>0)AND(e=0)AND NOT l THEN
        BEGIN
          BEGIN
            mem[curlist.tailfield]
            .hh.rh := newpenalty(10000);
            curlist.tailfield := mem[curlist.tailfield].hh.rh;
          END;
          mem[a+4].int := s+z-mem[a+1].int;
          appendtovlist(a);
          g2 := 0;
        END;
      IF t<>29995 THEN
        BEGIN
          mem[curlist.tailfield].hh.rh := mem[29995].hh.rh;
          curlist.tailfield := t;
        END;
      BEGIN
        mem[curlist.tailfield].hh.rh := newpenalty(eqtb[5275].int);
        curlist.tailfield := mem[curlist.tailfield].hh.rh;
      END;
      IF g2>0 THEN
        BEGIN
          mem[curlist.tailfield].hh.rh := newparamglue(g2);
          curlist.tailfield := mem[curlist.tailfield].hh.rh;
        END{:1205};
      resumeafterdisplay{:1199};
    END;
END;
{:1194}{1200:}
PROCEDURE resumeafterdisplay;
BEGIN
  IF curgroup<>15 THEN confusion(1170);
  unsave;
  curlist.pgfield := curlist.pgfield+3;
  pushnest;
  curlist.modefield := 102;
  curlist.auxfield.hh.lh := 1000;
  IF eqtb[5313].int<=0 THEN curlang := 0
  ELSE IF eqtb[5313].int>255 THEN
         curlang := 0
  ELSE curlang := eqtb[5313].int;
  curlist.auxfield.hh.rh := curlang;
  curlist.pgfield := (normmin(eqtb[5314].int)*64+normmin(eqtb[5315].int))
                     *65536+curlang;{443:}
  BEGIN
    getxtoken;
    IF curcmd<>10 THEN backinput;
  END{:443};
  IF nestptr=1 THEN buildpage;
END;
{:1200}{1211:}{1215:}
PROCEDURE getrtoken;

LABEL 20;
BEGIN
  20: REPEAT
        gettoken;
      UNTIL curtok<>2592;
  IF (curcs=0)OR(curcs>2614)THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(1185);
      END;
      BEGIN
        helpptr := 5;
        helpline[4] := 1186;
        helpline[3] := 1187;
        helpline[2] := 1188;
        helpline[1] := 1189;
        helpline[0] := 1190;
      END;
      IF curcs=0 THEN backinput;
      curtok := 6709;
      inserror;
      goto 20;
    END;
END;
{:1215}{1229:}
PROCEDURE trapzeroglue;
BEGIN
  IF (mem[curval+1].int=0)AND(mem[curval+2].int=0)AND(mem[curval+3].
     int=0)THEN
    BEGIN
      mem[0].hh.rh := mem[0].hh.rh+1;
      deleteglueref(curval);
      curval := 0;
    END;
END;
{:1229}{1236:}
PROCEDURE doregistercommand(a:smallnumber);

LABEL 40,10;

VAR l,q,r,s: halfword;
  p: 0..3;
BEGIN
  q := curcmd;
{1237:}
  BEGIN
    IF q<>89 THEN
      BEGIN
        getxtoken;
        IF (curcmd>=73)AND(curcmd<=76)THEN
          BEGIN
            l := curchr;
            p := curcmd-73;
            goto 40;
          END;
        IF curcmd<>89 THEN
          BEGIN
            BEGIN
              IF interaction=3 THEN;
              printnl(262);
              print(685);
            END;
            printcmdchr(curcmd,curchr);
            print(686);
            printcmdchr(q,0);
            BEGIN
              helpptr := 1;
              helpline[0] := 1211;
            END;
            error;
            goto 10;
          END;
      END;
    p := curchr;
    scaneightbitint;
    CASE p OF 
      0: l := curval+5318;
      1: l := curval+5851;
      2: l := curval+2900;
      3: l := curval+3156;
    END;
  END;
  40:{:1237};
  IF q=89 THEN scanoptionalequals
  ELSE IF scankeyword(1207)THEN;
  aritherror := false;
  IF q<91 THEN{1238:}IF p<2 THEN
                       BEGIN
                         IF p=0 THEN scanint
                         ELSE scandimen(
                                        false,false,false);
                         IF q=90 THEN curval := curval+eqtb[l].int;
                       END
  ELSE
    BEGIN
      scanglue(p);
      IF q=90 THEN{1239:}
        BEGIN
          q := newspec(curval);
          r := eqtb[l].hh.rh;
          deleteglueref(curval);
          mem[q+1].int := mem[q+1].int+mem[r+1].int;
          IF mem[q+2].int=0 THEN mem[q].hh.b0 := 0;
          IF mem[q].hh.b0=mem[r].hh.b0 THEN mem[q+2].int := mem[q+2].int+mem[r+2].
                                                            int
          ELSE IF (mem[q].hh.b0<mem[r].hh.b0)AND(mem[r+2].int<>0)THEN
                 BEGIN
                   mem
                   [q+2].int := mem[r+2].int;
                   mem[q].hh.b0 := mem[r].hh.b0;
                 END;
          IF mem[q+3].int=0 THEN mem[q].hh.b1 := 0;
          IF mem[q].hh.b1=mem[r].hh.b1 THEN mem[q+3].int := mem[q+3].int+mem[r+3].
                                                            int
          ELSE IF (mem[q].hh.b1<mem[r].hh.b1)AND(mem[r+3].int<>0)THEN
                 BEGIN
                   mem
                   [q+3].int := mem[r+3].int;
                   mem[q].hh.b1 := mem[r].hh.b1;
                 END;
          curval := q;
        END{:1239};
    END{:1238}
  ELSE{1240:}
    BEGIN
      scanint;
      IF p<2 THEN IF q=91 THEN IF p=0 THEN curval := multandadd(eqtb[l].int,
                                                     curval,0,2147483647)
      ELSE curval := multandadd(eqtb[l].int,curval,0,
                     1073741823)
      ELSE curval := xovern(eqtb[l].int,curval)
      ELSE
        BEGIN
          s := eqtb[l].
               hh.rh;
          r := newspec(s);
          IF q=91 THEN
            BEGIN
              mem[r+1].int := multandadd(mem[s+1].int,curval,0,
                              1073741823);
              mem[r+2].int := multandadd(mem[s+2].int,curval,0,1073741823);
              mem[r+3].int := multandadd(mem[s+3].int,curval,0,1073741823);
            END
          ELSE
            BEGIN
              mem[r+1].int := xovern(mem[s+1].int,curval);
              mem[r+2].int := xovern(mem[s+2].int,curval);
              mem[r+3].int := xovern(mem[s+3].int,curval);
            END;
          curval := r;
        END;
    END{:1240};
  IF aritherror THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(1208);
      END;
      BEGIN
        helpptr := 2;
        helpline[1] := 1209;
        helpline[0] := 1210;
      END;
      IF p>=2 THEN deleteglueref(curval);
      error;
      goto 10;
    END;
  IF p<2 THEN IF (a>=4)THEN geqworddefine(l,curval)
  ELSE eqworddefine(l,
                    curval)
  ELSE
    BEGIN
      trapzeroglue;
      IF (a>=4)THEN geqdefine(l,117,curval)
      ELSE eqdefine(l,117,curval);
    END;
  10:
END;{:1236}{1243:}
PROCEDURE alteraux;

VAR c: halfword;
BEGIN
  IF curchr<>abs(curlist.modefield)THEN reportillegalcase
  ELSE
    BEGIN
      c := curchr;
      scanoptionalequals;
      IF c=1 THEN
        BEGIN
          scandimen(false,false,false);
          curlist.auxfield.int := curval;
        END
      ELSE
        BEGIN
          scanint;
          IF (curval<=0)OR(curval>32767)THEN
            BEGIN
              BEGIN
                IF interaction=3 THEN;
                printnl(262);
                print(1214);
              END;
              BEGIN
                helpptr := 1;
                helpline[0] := 1215;
              END;
              interror(curval);
            END
          ELSE curlist.auxfield.hh.lh := curval;
        END;
    END;
END;
{:1243}{1244:}
PROCEDURE alterprevgraf;

VAR p: 0..nestsize;
BEGIN
  nest[nestptr] := curlist;
  p := nestptr;
  WHILE abs(nest[p].modefield)<>1 DO
    p := p-1;
  scanoptionalequals;
  scanint;
  IF curval<0 THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(956);
      END;
      printesc(532);
      BEGIN
        helpptr := 1;
        helpline[0] := 1216;
      END;
      interror(curval);
    END
  ELSE
    BEGIN
      nest[p].pgfield := curval;
      curlist := nest[nestptr];
    END;
END;{:1244}{1245:}
PROCEDURE alterpagesofar;

VAR c: 0..7;
BEGIN
  c := curchr;
  scanoptionalequals;
  scandimen(false,false,false);
  pagesofar[c] := curval;
END;
{:1245}{1246:}
PROCEDURE alterinteger;

VAR c: 0..1;
BEGIN
  c := curchr;
  scanoptionalequals;
  scanint;
  IF c=0 THEN deadcycles := curval
  ELSE insertpenalties := curval;
END;
{:1246}{1247:}
PROCEDURE alterboxdimen;

VAR c: smallnumber;
  b: eightbits;
BEGIN
  c := curchr;
  scaneightbitint;
  b := curval;
  scanoptionalequals;
  scandimen(false,false,false);
  IF eqtb[3678+b].hh.rh<>0 THEN mem[eqtb[3678+b].hh.rh+c].int := curval;
END;
{:1247}{1257:}
PROCEDURE newfont(a:smallnumber);

LABEL 50;

VAR u: halfword;
  s: scaled;
  f: internalfontnumber;
  t: strnumber;
  oldsetting: 0..21;
  flushablestring: strnumber;
BEGIN
  IF jobname=0 THEN openlogfile;
  getrtoken;
  u := curcs;
  IF u>=514 THEN t := hash[u].rh
  ELSE IF u>=257 THEN IF u=513 THEN t := 1220
  ELSE t := u-257
  ELSE
    BEGIN
      oldsetting := selector;
      selector := 21;
      print(1220);
      print(u-1);
      selector := oldsetting;
      BEGIN
        IF poolptr+1>poolsize THEN overflow(257,poolsize-initpoolptr);
      END;
      t := makestring;
    END;
  IF (a>=4)THEN geqdefine(u,87,0)
  ELSE eqdefine(u,87,0);
  scanoptionalequals;
  scanfilename;{1258:}
  nameinprogress := true;
  IF scankeyword(1221)THEN{1259:}
    BEGIN
      scandimen(false,false,false);
      s := curval;
      IF (s<=0)OR(s>=134217728)THEN
        BEGIN
          BEGIN
            IF interaction=3 THEN;
            printnl(262);
            print(1223);
          END;
          printscaled(s);
          print(1224);
          BEGIN
            helpptr := 2;
            helpline[1] := 1225;
            helpline[0] := 1226;
          END;
          error;
          s := 10*65536;
        END;
    END{:1259}
  ELSE IF scankeyword(1222)THEN
         BEGIN
           scanint;
           s := -curval;
           IF (curval<=0)OR(curval>32768)THEN
             BEGIN
               BEGIN
                 IF interaction=3 THEN;
                 printnl(262);
                 print(552);
               END;
               BEGIN
                 helpptr := 1;
                 helpline[0] := 553;
               END;
               interror(curval);
               s := -1000;
             END;
         END
  ELSE s := -1000;
  nameinprogress := false{:1258};{1260:}
  flushablestring := strptr-1;
  FOR f:=1 TO fontptr DO
    IF streqstr(fontname[f],curname)AND streqstr(
       fontarea[f],curarea)THEN
      BEGIN
        IF curname=flushablestring THEN
          BEGIN
            BEGIN
              strptr := strptr-1;
              poolptr := strstart[strptr];
            END;
            curname := fontname[f];
          END;
        IF s>0 THEN
          BEGIN
            IF s=fontsize[f]THEN goto 50;
          END
        ELSE IF fontsize[f]=xnoverd(fontdsize[f],-s,1000)THEN goto 50;
      END{:1260};
  f := readfontinfo(u,curname,curarea,s);
  50: eqtb[u].hh.rh := f;
  eqtb[2624+f] := eqtb[u];
  hash[2624+f].rh := t;
END;
{:1257}{1265:}
PROCEDURE newinteraction;
BEGIN
  printnl(338);
  interaction := curchr;
{75:}
  IF interaction=0 THEN selector := 16
  ELSE selector := 17{:75};
  IF logopened THEN selector := selector+2;
END;
{:1265}
PROCEDURE prefixedcommand;

LABEL 30,10;

VAR a: smallnumber;
  f: internalfontnumber;
  j: halfword;
  k: fontindex;
  p,q: halfword;
  n: integer;
  e: boolean;
BEGIN
  a := 0;
  WHILE curcmd=93 DO
    BEGIN
      IF NOT odd(a DIV curchr)THEN a := a+curchr;
{404:}
      REPEAT
        getxtoken;
      UNTIL (curcmd<>10)AND(curcmd<>0){:404};
      IF curcmd<=70 THEN{1212:}
        BEGIN
          BEGIN
            IF interaction=3 THEN;
            printnl(262);
            print(1180);
          END;
          printcmdchr(curcmd,curchr);
          printchar(39);
          BEGIN
            helpptr := 1;
            helpline[0] := 1181;
          END;
          backerror;
          goto 10;
        END{:1212};
    END;
{1213:}
  IF (curcmd<>97)AND(a MOD 4<>0)THEN
    BEGIN
      BEGIN
        IF interaction=3
          THEN;
        printnl(262);
        print(685);
      END;
      printesc(1172);
      print(1182);
      printesc(1173);
      print(1183);
      printcmdchr(curcmd,curchr);
      printchar(39);
      BEGIN
        helpptr := 1;
        helpline[0] := 1184;
      END;
      error;
    END{:1213};
{1214:}
  IF eqtb[5306].int<>0 THEN IF eqtb[5306].int<0 THEN
                              BEGIN
                                IF (a>=4)
                                  THEN a := a-4;
                              END
  ELSE
    BEGIN
      IF NOT(a>=4)THEN a := a+4;
    END{:1214};
  CASE curcmd OF {1217:}
    87: IF (a>=4)THEN geqdefine(3934,120,curchr)
        ELSE
          eqdefine(3934,120,curchr);
{:1217}{1218:}
    97:
        BEGIN
          IF odd(curchr)AND NOT(a>=4)AND(eqtb[5306].int>=0)
            THEN a := a+4;
          e := (curchr>=2);
          getrtoken;
          p := curcs;
          q := scantoks(true,e);
          IF (a>=4)THEN geqdefine(p,111+(a MOD 4),defref)
          ELSE eqdefine(p,111+(a MOD
                        4),defref);
        END;{:1218}{1221:}
    94:
        BEGIN
          n := curchr;
          getrtoken;
          p := curcs;
          IF n=0 THEN
            BEGIN
              REPEAT
                gettoken;
              UNTIL curcmd<>10;
              IF curtok=3133 THEN
                BEGIN
                  gettoken;
                  IF curcmd=10 THEN gettoken;
                END;
            END
          ELSE
            BEGIN
              gettoken;
              q := curtok;
              gettoken;
              backinput;
              curtok := q;
              backinput;
            END;
          IF curcmd>=111 THEN mem[curchr].hh.lh := mem[curchr].hh.lh+1;
          IF (a>=4)THEN geqdefine(p,curcmd,curchr)
          ELSE eqdefine(p,curcmd,curchr);
        END;{:1221}{1224:}
    95:
        BEGIN
          n := curchr;
          getrtoken;
          p := curcs;
          IF (a>=4)THEN geqdefine(p,0,256)
          ELSE eqdefine(p,0,256);
          scanoptionalequals;
          CASE n OF 
            0:
               BEGIN
                 scancharnum;
                 IF (a>=4)THEN geqdefine(p,68,curval)
                 ELSE eqdefine(p,68,curval);
               END;
            1:
               BEGIN
                 scanfifteenbitint;
                 IF (a>=4)THEN geqdefine(p,69,curval)
                 ELSE eqdefine(p,69,curval);
               END;
            ELSE
              BEGIN
                scaneightbitint;
                CASE n OF 
                  2: IF (a>=4)THEN geqdefine(p,73,5318+curval)
                     ELSE eqdefine(p,73,
                                   5318+curval);
                  3: IF (a>=4)THEN geqdefine(p,74,5851+curval)
                     ELSE eqdefine(p,74,5851+curval
                       );
                  4: IF (a>=4)THEN geqdefine(p,75,2900+curval)
                     ELSE eqdefine(p,75,2900+curval
                       );
                  5: IF (a>=4)THEN geqdefine(p,76,3156+curval)
                     ELSE eqdefine(p,76,3156+curval
                       );
                  6: IF (a>=4)THEN geqdefine(p,72,3422+curval)
                     ELSE eqdefine(p,72,3422+curval
                       );
                END;
              END
          END;
        END;{:1224}{1225:}
    96:
        BEGIN
          scanint;
          n := curval;
          IF NOT scankeyword(843)THEN
            BEGIN
              BEGIN
                IF interaction=3 THEN;
                printnl(262);
                print(1074);
              END;
              BEGIN
                helpptr := 2;
                helpline[1] := 1201;
                helpline[0] := 1202;
              END;
              error;
            END;
          getrtoken;
          p := curcs;
          readtoks(n,p);
          IF (a>=4)THEN geqdefine(p,111,curval)
          ELSE eqdefine(p,111,curval);
        END;
{:1225}{1226:}
    71,72:
           BEGIN
             q := curcs;
             IF curcmd=71 THEN
               BEGIN
                 scaneightbitint;
                 p := 3422+curval;
               END
             ELSE p := curchr;
             scanoptionalequals;{404:}
             REPEAT
               getxtoken;
             UNTIL (curcmd<>10)AND(curcmd<>0){:404};
             IF curcmd<>1 THEN{1227:}
               BEGIN
                 IF curcmd=71 THEN
                   BEGIN
                     scaneightbitint;
                     curcmd := 72;
                     curchr := 3422+curval;
                   END;
                 IF curcmd=72 THEN
                   BEGIN
                     q := eqtb[curchr].hh.rh;
                     IF q=0 THEN IF (a>=4)THEN geqdefine(p,101,0)
                     ELSE eqdefine(p,101,0)
                     ELSE
                       BEGIN
                         mem[q].hh.lh := mem[q].hh.lh+1;
                         IF (a>=4)THEN geqdefine(p,111,q)
                         ELSE eqdefine(p,111,q);
                       END;
                     goto 30;
                   END;
               END{:1227};
             backinput;
             curcs := q;
             q := scantoks(false,false);
             IF mem[defref].hh.rh=0 THEN
               BEGIN
                 IF (a>=4)THEN geqdefine(p,101,0)
                 ELSE
                   eqdefine(p,101,0);
                 BEGIN
                   mem[defref].hh.rh := avail;
                   avail := defref;
                   dynused := dynused-1;
                 END;
               END
             ELSE
               BEGIN
                 IF p=3413 THEN
                   BEGIN
                     mem[q].hh.rh := getavail;
                     q := mem[q].hh.rh;
                     mem[q].hh.lh := 637;
                     q := getavail;
                     mem[q].hh.lh := 379;
                     mem[q].hh.rh := mem[defref].hh.rh;
                     mem[defref].hh.rh := q;
                   END;
                 IF (a>=4)THEN geqdefine(p,111,defref)
                 ELSE eqdefine(p,111,defref);
               END;
           END;
{:1226}{1228:}
    73:
        BEGIN
          p := curchr;
          scanoptionalequals;
          scanint;
          IF (a>=4)THEN geqworddefine(p,curval)
          ELSE eqworddefine(p,curval);
        END;
    74:
        BEGIN
          p := curchr;
          scanoptionalequals;
          scandimen(false,false,false);
          IF (a>=4)THEN geqworddefine(p,curval)
          ELSE eqworddefine(p,curval);
        END;
    75,76:
           BEGIN
             p := curchr;
             n := curcmd;
             scanoptionalequals;
             IF n=76 THEN scanglue(3)
             ELSE scanglue(2);
             trapzeroglue;
             IF (a>=4)THEN geqdefine(p,117,curval)
             ELSE eqdefine(p,117,curval);
           END;
{:1228}{1232:}
    85:
        BEGIN{1233:}
          IF curchr=3983 THEN n := 15
          ELSE IF curchr=
                  5007 THEN n := 32768
          ELSE IF curchr=4751 THEN n := 32767
          ELSE IF curchr=5574
                 THEN n := 16777215
          ELSE n := 255{:1233};
          p := curchr;
          scancharnum;
          p := p+curval;
          scanoptionalequals;
          scanint;
          IF ((curval<0)AND(p<5574))OR(curval>n)THEN
            BEGIN
              BEGIN
                IF interaction=3
                  THEN;
                printnl(262);
                print(1203);
              END;
              printint(curval);
              IF p<5574 THEN print(1204)
              ELSE print(1205);
              printint(n);
              BEGIN
                helpptr := 1;
                helpline[0] := 1206;
              END;
              error;
              curval := 0;
            END;
          IF p<5007 THEN IF (a>=4)THEN geqdefine(p,120,curval)
          ELSE eqdefine(p,120,
                        curval)
          ELSE IF p<5574 THEN IF (a>=4)THEN geqdefine(p,120,curval)
          ELSE
            eqdefine(p,120,curval)
          ELSE IF (a>=4)THEN geqworddefine(p,curval)
          ELSE
            eqworddefine(p,curval);
        END;{:1232}{1234:}
    86:
        BEGIN
          p := curchr;
          scanfourbitint;
          p := p+curval;
          scanoptionalequals;
          scanfontident;
          IF (a>=4)THEN geqdefine(p,120,curval)
          ELSE eqdefine(p,120,curval);
        END;
{:1234}{1235:}
    89,90,91,92: doregistercommand(a);
{:1235}{1241:}
    98:
        BEGIN
          scaneightbitint;
          IF (a>=4)THEN n := 256+curval
          ELSE n := curval;
          scanoptionalequals;
          IF setboxallowed THEN scanbox(1073741824+n)
          ELSE
            BEGIN
              BEGIN
                IF 
                   interaction=3 THEN;
                printnl(262);
                print(680);
              END;
              printesc(536);
              BEGIN
                helpptr := 2;
                helpline[1] := 1212;
                helpline[0] := 1213;
              END;
              error;
            END;
        END;
{:1241}{1242:}
    79: alteraux;
    80: alterprevgraf;
    81: alterpagesofar;
    82: alterinteger;
    83: alterboxdimen;
{:1242}{1248:}
    84:
        BEGIN
          scanoptionalequals;
          scanint;
          n := curval;
          IF n<=0 THEN p := 0
          ELSE
            BEGIN
              p := getnode(2*n+1);
              mem[p].hh.lh := n;
              FOR j:=1 TO n DO
                BEGIN
                  scandimen(false,false,false);
                  mem[p+2*j-1].int := curval;
                  scandimen(false,false,false);
                  mem[p+2*j].int := curval;
                END;
            END;
          IF (a>=4)THEN geqdefine(3412,118,p)
          ELSE eqdefine(3412,118,p);
        END;
{:1248}{1252:}
    99: IF curchr=1 THEN
          BEGIN
            IF TeXVariation>0 THEN
              BEGIN
                newpatterns;
                goto 30;
              END;
            BEGIN
              IF interaction=3 THEN;
              printnl(262);
              print(1217);
            END;
            helpptr := 0;
            error;
            REPEAT
              gettoken;
            UNTIL curcmd=2;
            goto 10;
          END
        ELSE
          BEGIN
            newhyphexceptions;
            goto 30;
          END;
{:1252}{1253:}
    77:
        BEGIN
          findfontdimen(true);
          k := curval;
          scanoptionalequals;
          scandimen(false,false,false);
          fontinfo[k].int := curval;
        END;
    78:
        BEGIN
          n := curchr;
          scanfontident;
          f := curval;
          scanoptionalequals;
          scanint;
          IF n=0 THEN hyphenchar[f] := curval
          ELSE skewchar[f] := curval;
        END;
{:1253}{1256:}
    88: newfont(a);{:1256}{1264:}
    100: newinteraction;
{:1264}
    ELSE confusion(1179)
  END;
  30:{1269:}IF aftertoken<>0 THEN
              BEGIN
                curtok := aftertoken;
                backinput;
                aftertoken := 0;
              END{:1269};
  10:
END;{:1211}{1270:}
PROCEDURE doassignments;

LABEL 10;
BEGIN
  WHILE true DO
    BEGIN{404:}
      REPEAT
        getxtoken;
      UNTIL (curcmd<>10)AND(curcmd<>0){:404};
      IF curcmd<=70 THEN goto 10;
      setboxallowed := false;
      prefixedcommand;
      setboxallowed := true;
    END;
  10:
END;
{:1270}{1275:}
PROCEDURE openorclosein;

VAR c: 0..1;
  n: 0..15;
BEGIN
  c := curchr;
  scanfourbitint;
  n := curval;
  IF readopen[n]<>2 THEN
    BEGIN
      aclose(readfile[n]);
      readopen[n] := 2;
    END;
  IF c<>0 THEN
    BEGIN
      scanoptionalequals;
      scanfilename;
      IF curext=338 THEN curext := 791;
      packfilename(curname,curarea,curext);
      IF aopenin(readfile[n])THEN readopen[n] := 1;
    END;
END;
{:1275}{1279:}
PROCEDURE issuemessage;

VAR oldsetting: 0..21;
  c: 0..1;
  s: strnumber;
BEGIN
  c := curchr;
  mem[29988].hh.rh := scantoks(false,true);
  oldsetting := selector;
  selector := 21;
  tokenshow(defref);
  selector := oldsetting;
  flushlist(defref);
  BEGIN
    IF poolptr+1>poolsize THEN overflow(257,poolsize-initpoolptr);
  END;
  s := makestring;
  IF c=0 THEN{1280:}
    BEGIN
      IF termoffset+(strstart[s+1]-strstart[s])>
         maxprintline-2 THEN println
      ELSE IF (termoffset>0)OR(fileoffset>0)THEN
             printchar(32);
      slowprint(s);
      flush(output);
    END{:1280}
  ELSE{1283:}
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(338);
      END;
      slowprint(s);
      IF eqtb[3421].hh.rh<>0 THEN useerrhelp := true
      ELSE IF longhelpseen THEN
             BEGIN
               helpptr := 1;
               helpline[0] := 1233;
             END
      ELSE
        BEGIN
          IF interaction<3 THEN longhelpseen := true;
          BEGIN
            helpptr := 4;
            helpline[3] := 1234;
            helpline[2] := 1235;
            helpline[1] := 1236;
            helpline[0] := 1237;
          END;
        END;
      error;
      useerrhelp := false;
    END{:1283};
  BEGIN
    strptr := strptr-1;
    poolptr := strstart[strptr];
  END;
END;
{:1279}{1288:}
PROCEDURE shiftcase;

VAR b: halfword;
  p: halfword;
  t: halfword;
  c: eightbits;
BEGIN
  b := curchr;
  p := scantoks(false,false);
  p := mem[defref].hh.rh;
  WHILE p<>0 DO
    BEGIN{1289:}
      t := mem[p].hh.lh;
      IF t<4352 THEN
        BEGIN
          c := t MOD 256;
          IF eqtb[b+c].hh.rh<>0 THEN mem[p].hh.lh := t-c+eqtb[b+c].hh.rh;
        END{:1289};
      p := mem[p].hh.rh;
    END;
  begintokenlist(mem[defref].hh.rh,3);
  BEGIN
    mem[defref].hh.rh := avail;
    avail := defref;
    dynused := dynused-1;
  END;
END;
{:1288}{1293:}
PROCEDURE showwhatever;

LABEL 50;

VAR p: halfword;
BEGIN
  CASE curchr OF 
    3:
       BEGIN
         begindiagnostic;
         showactivities;
       END;
    1:{1296:}
       BEGIN
         scaneightbitint;
         begindiagnostic;
         printnl(1255);
         printint(curval);
         printchar(61);
         IF eqtb[3678+curval].hh.rh=0 THEN print(410)
         ELSE showbox(eqtb[3678+
                      curval].hh.rh);
       END{:1296};
    0:{1294:}
       BEGIN
         gettoken;
         IF interaction=3 THEN;
         printnl(1249);
         IF curcs<>0 THEN
           BEGIN
             sprintcs(curcs);
             printchar(61);
           END;
         printmeaning;
         goto 50;
       END{:1294};
    ELSE{1297:}
      BEGIN
        p := thetoks;
        IF interaction=3 THEN;
        printnl(1249);
        tokenshow(29997);
        flushlist(mem[29997].hh.rh);
        goto 50;
      END{:1297}
  END;
{1298:}
  enddiagnostic(true);
  BEGIN
    IF interaction=3 THEN;
    printnl(262);
    print(1256);
  END;
  IF selector=19 THEN IF eqtb[5292].int<=0 THEN
                        BEGIN
                          selector := 17;
                          print(1257);
                          selector := 19;
                        END{:1298};
  50: IF interaction<3 THEN
        BEGIN
          helpptr := 0;
          errorcount := errorcount-1;
        END
      ELSE IF eqtb[5292].int>0 THEN
             BEGIN
               BEGIN
                 helpptr := 3;
                 helpline[2] := 1244;
                 helpline[1] := 1245;
                 helpline[0] := 1246;
               END;
             END
      ELSE
        BEGIN
          BEGIN
            helpptr := 5;
            helpline[4] := 1244;
            helpline[3] := 1245;
            helpline[2] := 1246;
            helpline[1] := 1247;
            helpline[0] := 1248;
          END;
        END;
  error;
END;
{:1293}{1302:}
PROCEDURE storefmtfile;

LABEL 41,42,31,32;

VAR j,k,l: integer;
  p,q: halfword;
  x: integer;
  w: fourquarters;
BEGIN{1304:}
  IF saveptr<>0 THEN
    BEGIN
      BEGIN
        IF interaction=3 THEN;
        printnl(262);
        print(1259);
      END;
      BEGIN
        helpptr := 1;
        helpline[0] := 1260;
      END;
      BEGIN
        IF interaction=3 THEN interaction := 2;
        IF logopened THEN error;
{if interaction>0 then debughelp;}
        history := 3;
        jumpout;
      END;
    END{:1304};
{1328:}
  selector := 21;
  print(1273);
  print(jobname);
  printchar(32);
  printint(eqtb[5286].int);
  printchar(46);
  printint(eqtb[5285].int);
  printchar(46);
  printint(eqtb[5284].int);
  printchar(41);
  IF interaction=0 THEN selector := 18
  ELSE selector := 19;
  BEGIN
    IF poolptr+1>poolsize THEN overflow(257,poolsize-initpoolptr);
  END;
  formatident := makestring;
  packjobname(786);
  WHILE NOT wopenout(fmtfile) DO
    promptfilename(1274,786);
  printnl(1275);
  slowprint(wmakenamestring(fmtfile));
  BEGIN
    strptr := strptr-1;
    poolptr := strstart[strptr];
  END;
  printnl(338);
  slowprint(formatident){:1328};{1307:}
  BEGIN
    fmtfile^.int := 305924274;
    put(fmtfile);
  END;
  BEGIN
    fmtfile^.int := 0;
    put(fmtfile);
  END;
  BEGIN
    fmtfile^.int := 30000;
    put(fmtfile);
  END;
  BEGIN
    fmtfile^.int := 6106;
    put(fmtfile);
  END;
  BEGIN
    fmtfile^.int := 1777;
    put(fmtfile);
  END;
  BEGIN
    fmtfile^.int := 307;
    put(fmtfile);
  END{:1307};
{1309:}
  BEGIN
    fmtfile^.int := poolptr;
    put(fmtfile);
  END;
  BEGIN
    fmtfile^.int := strptr;
    put(fmtfile);
  END;
  FOR k:=0 TO strptr DO
    BEGIN
      fmtfile^.int := strstart[k];
      put(fmtfile);
    END;
  k := 0;
  WHILE k+4<poolptr DO
    BEGIN
      w.b0 := strpool[k];
      w.b1 := strpool[k+1];
      w.b2 := strpool[k+2];
      w.b3 := strpool[k+3];
      BEGIN
        fmtfile^.qqqq := w;
        put(fmtfile);
      END;
      k := k+4;
    END;
  k := poolptr-4;
  w.b0 := strpool[k];
  w.b1 := strpool[k+1];
  w.b2 := strpool[k+2];
  w.b3 := strpool[k+3];
  BEGIN
    fmtfile^.qqqq := w;
    put(fmtfile);
  END;
  println;
  printint(strptr);
  print(1261);
  printint(poolptr){:1309};{1311:}
  sortavail;
  varused := 0;
  BEGIN
    fmtfile^.int := lomemmax;
    put(fmtfile);
  END;
  BEGIN
    fmtfile^.int := rover;
    put(fmtfile);
  END;
  p := 0;
  q := rover;
  x := 0;
  REPEAT
    FOR k:=p TO q+1 DO
      BEGIN
        fmtfile^ := mem[k];
        put(fmtfile);
      END;
    x := x+q+2-p;
    varused := varused+q-p;
    p := q+mem[q].hh.lh;
    q := mem[q+1].hh.rh;
  UNTIL q=rover;
  varused := varused+lomemmax-p;
  dynused := memend+1-himemmin;
  FOR k:=p TO lomemmax DO
    BEGIN
      fmtfile^ := mem[k];
      put(fmtfile);
    END;
  x := x+lomemmax+1-p;
  BEGIN
    fmtfile^.int := himemmin;
    put(fmtfile);
  END;
  BEGIN
    fmtfile^.int := avail;
    put(fmtfile);
  END;
  FOR k:=himemmin TO memend DO
    BEGIN
      fmtfile^ := mem[k];
      put(fmtfile);
    END;
  x := x+memend+1-himemmin;
  p := avail;
  WHILE p<>0 DO
    BEGIN
      dynused := dynused-1;
      p := mem[p].hh.rh;
    END;
  BEGIN
    fmtfile^.int := varused;
    put(fmtfile);
  END;
  BEGIN
    fmtfile^.int := dynused;
    put(fmtfile);
  END;
  println;
  printint(x);
  print(1262);
  printint(varused);
  printchar(38);
  printint(dynused){:1311};
{1313:}{1315:}
  k := 1;
  REPEAT
    j := k;
    WHILE j<5262 DO
      BEGIN
        IF (eqtb[j].hh.rh=eqtb[j+1].hh.rh)AND(eqtb[j].hh.b0
           =eqtb[j+1].hh.b0)AND(eqtb[j].hh.b1=eqtb[j+1].hh.b1)THEN goto 41;
        j := j+1;
      END;
    l := 5263;
    goto 31;
    41: j := j+1;
    l := j;
    WHILE j<5262 DO
      BEGIN
        IF (eqtb[j].hh.rh<>eqtb[j+1].hh.rh)OR(eqtb[j].hh.b0
           <>eqtb[j+1].hh.b0)OR(eqtb[j].hh.b1<>eqtb[j+1].hh.b1)THEN goto 31;
        j := j+1;
      END;
    31:
        BEGIN
          fmtfile^.int := l-k;
          put(fmtfile);
        END;
    WHILE k<l DO
      BEGIN
        BEGIN
          fmtfile^ := eqtb[k];
          put(fmtfile);
        END;
        k := k+1;
      END;
    k := j+1;
    BEGIN
      fmtfile^.int := k-l;
      put(fmtfile);
    END;
  UNTIL k=5263{:1315};
{1316:}
  REPEAT
    j := k;
    WHILE j<6106 DO
      BEGIN
        IF eqtb[j].int=eqtb[j+1].int THEN goto 42;
        j := j+1;
      END;
    l := 6107;
    goto 32;
    42: j := j+1;
    l := j;
    WHILE j<6106 DO
      BEGIN
        IF eqtb[j].int<>eqtb[j+1].int THEN goto 32;
        j := j+1;
      END;
    32:
        BEGIN
          fmtfile^.int := l-k;
          put(fmtfile);
        END;
    WHILE k<l DO
      BEGIN
        BEGIN
          fmtfile^ := eqtb[k];
          put(fmtfile);
        END;
        k := k+1;
      END;
    k := j+1;
    BEGIN
      fmtfile^.int := k-l;
      put(fmtfile);
    END;
  UNTIL k>6106{:1316};
  BEGIN
    fmtfile^.int := parloc;
    put(fmtfile);
  END;
  BEGIN
    fmtfile^.int := writeloc;
    put(fmtfile);
  END;
{1318:}
  BEGIN
    fmtfile^.int := hashused;
    put(fmtfile);
  END;
  cscount := 2613-hashused;
  FOR p:=514 TO hashused DO
    IF hash[p].rh<>0 THEN
      BEGIN
        BEGIN
          fmtfile^.int 
          := p;
          put(fmtfile);
        END;
        BEGIN
          fmtfile^.hh := hash[p];
          put(fmtfile);
        END;
        cscount := cscount+1;
      END;
  FOR p:=hashused+1 TO 2880 DO
    BEGIN
      fmtfile^.hh := hash[p];
      put(fmtfile);
    END;
  BEGIN
    fmtfile^.int := cscount;
    put(fmtfile);
  END;
  println;
  printint(cscount);
  print(1263){:1318}{:1313};
{1320:}
  BEGIN
    fmtfile^.int := fmemptr;
    put(fmtfile);
  END;
  FOR k:=0 TO fmemptr-1 DO
    BEGIN
      fmtfile^ := fontinfo[k];
      put(fmtfile);
    END;
  BEGIN
    fmtfile^.int := fontptr;
    put(fmtfile);
  END;
  FOR k:=0 TO fontptr DO{1322:}
    BEGIN
      BEGIN
        fmtfile^.qqqq := fontcheck[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := fontsize[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := fontdsize[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := fontparams[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := hyphenchar[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := skewchar[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := fontname[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := fontarea[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := fontbc[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := fontec[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := charbase[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := widthbase[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := heightbase[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := depthbase[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := italicbase[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := ligkernbase[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := kernbase[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := extenbase[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := parambase[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := fontglue[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := bcharlabel[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := fontbchar[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := fontfalsebchar[k];
        put(fmtfile);
      END;
      printnl(1266);
      printesc(hash[2624+k].rh);
      printchar(61);
      printfilename(fontname[k],fontarea[k],338);
      IF fontsize[k]<>fontdsize[k]THEN
        BEGIN
          print(741);
          printscaled(fontsize[k]);
          print(397);
        END;
    END{:1322};
  println;
  printint(fmemptr-7);
  print(1264);
  printint(fontptr-0);
  print(1265);
  IF fontptr<>1 THEN printchar(115){:1320};
{1324:}
  BEGIN
    fmtfile^.int := hyphcount;
    put(fmtfile);
  END;
  FOR k:=0 TO 307 DO
    IF hyphword[k]<>0 THEN
      BEGIN
        BEGIN
          fmtfile^.int := k;
          put(fmtfile);
        END;
        BEGIN
          fmtfile^.int := hyphword[k];
          put(fmtfile);
        END;
        BEGIN
          fmtfile^.int := hyphlist[k];
          put(fmtfile);
        END;
      END;
  println;
  printint(hyphcount);
  print(1267);
  IF hyphcount<>1 THEN printchar(115);
  IF trienotready THEN inittrie;
  BEGIN
    fmtfile^.int := triemax;
    put(fmtfile);
  END;
  FOR k:=0 TO triemax DO
    BEGIN
      fmtfile^.hh := trie[k];
      put(fmtfile);
    END;
  BEGIN
    fmtfile^.int := trieopptr;
    put(fmtfile);
  END;
  FOR k:=1 TO trieopptr DO
    BEGIN
      BEGIN
        fmtfile^.int := hyfdistance[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := hyfnum[k];
        put(fmtfile);
      END;
      BEGIN
        fmtfile^.int := hyfnext[k];
        put(fmtfile);
      END;
    END;
  printnl(1268);
  printint(triemax);
  print(1269);
  printint(trieopptr);
  print(1270);
  IF trieopptr<>1 THEN printchar(115);
  print(1271);
  printint(trieopsize);
  FOR k:=255 DOWNTO 0 DO
    IF trieused[k]>0 THEN
      BEGIN
        printnl(801);
        printint(trieused[k]);
        print(1272);
        printint(k);
        BEGIN
          fmtfile^.int := k;
          put(fmtfile);
        END;
        BEGIN
          fmtfile^.int := trieused[k];
          put(fmtfile);
        END;
      END{:1324};{1326:}
  BEGIN
    fmtfile^.int := interaction;
    put(fmtfile);
  END;
  BEGIN
    fmtfile^.int := formatident;
    put(fmtfile);
  END;
  BEGIN
    fmtfile^.int := 69069;
    put(fmtfile);
  END;
  eqtb[5294].int := 0{:1326};
{1329:}
  wclose(fmtfile){:1329};
END;
{:1302}{1348:}{1349:}
PROCEDURE newwhatsit(s:smallnumber;w:smallnumber);

VAR p: halfword;
BEGIN
  p := getnode(w);
  mem[p].hh.b0 := 8;
  mem[p].hh.b1 := s;
  mem[curlist.tailfield].hh.rh := p;
  curlist.tailfield := p;
END;
{:1349}{1350:}
PROCEDURE newwritewhatsit(w:smallnumber);
BEGIN
  newwhatsit(curchr,w);
  IF w<>2 THEN scanfourbitint
  ELSE
    BEGIN
      scanint;
      IF curval<0 THEN curval := 17
      ELSE IF curval>15 THEN curval := 16;
    END;
  mem[curlist.tailfield+1].hh.lh := curval;
END;{:1350}
PROCEDURE doextension;

VAR i,j,k: integer;
  p,q,r: halfword;
BEGIN
  CASE curchr OF 
    0:{1351:}
       BEGIN
         newwritewhatsit(3);
         scanoptionalequals;
         scanfilename;
         mem[curlist.tailfield+1].hh.rh := curname;
         mem[curlist.tailfield+2].hh.lh := curarea;
         mem[curlist.tailfield+2].hh.rh := curext;
       END{:1351};
    1:{1352:}
       BEGIN
         k := curcs;
         newwritewhatsit(2);
         curcs := k;
         p := scantoks(false,false);
         mem[curlist.tailfield+1].hh.rh := defref;
       END{:1352};
    2:{1353:}
       BEGIN
         newwritewhatsit(2);
         mem[curlist.tailfield+1].hh.rh := 0;
       END{:1353};
    3:{1354:}
       BEGIN
         newwhatsit(3,2);
         mem[curlist.tailfield+1].hh.lh := 0;
         p := scantoks(false,true);
         mem[curlist.tailfield+1].hh.rh := defref;
       END{:1354};
    4:{1375:}
       BEGIN
         getxtoken;
         IF (curcmd=59)AND(curchr<=2)THEN
           BEGIN
             p := curlist.tailfield;
             doextension;
             outwhat(curlist.tailfield);
             flushnodelist(curlist.tailfield);
             curlist.tailfield := p;
             mem[p].hh.rh := 0;
           END
         ELSE backinput;
       END{:1375};
    5:{1377:}IF abs(curlist.modefield)<>102 THEN reportillegalcase
       ELSE
         BEGIN
           newwhatsit(4,2);
           scanint;
           IF curval<=0 THEN curlist.auxfield.hh.rh := 0
           ELSE IF curval>255 THEN
                  curlist.auxfield.hh.rh := 0
           ELSE curlist.auxfield.hh.rh := curval;
           mem[curlist.tailfield+1].hh.rh := curlist.auxfield.hh.rh;
           mem[curlist.tailfield+1].hh.b0 := normmin(eqtb[5314].int);
           mem[curlist.tailfield+1].hh.b1 := normmin(eqtb[5315].int);
         END{:1377};
    ELSE confusion(1292)
  END;
END;{:1348}{1376:}
PROCEDURE fixlanguage;

VAR l: ASCIIcode;
BEGIN
  IF eqtb[5313].int<=0 THEN l := 0
  ELSE IF eqtb[5313].int>255 THEN l := 
                                       0
  ELSE l := eqtb[5313].int;
  IF l<>curlist.auxfield.hh.rh THEN
    BEGIN
      newwhatsit(4,2);
      mem[curlist.tailfield+1].hh.rh := l;
      curlist.auxfield.hh.rh := l;
      mem[curlist.tailfield+1].hh.b0 := normmin(eqtb[5314].int);
      mem[curlist.tailfield+1].hh.b1 := normmin(eqtb[5315].int);
    END;
END;
{:1376}{1068:}
PROCEDURE handlerightbrace;

VAR p,q: halfword;
  d: scaled;
  f: integer;
BEGIN
  CASE curgroup OF 
    1: unsave;
    0:
       BEGIN
         BEGIN
           IF interaction=3 THEN;
           printnl(262);
           print(1045);
         END;
         BEGIN
           helpptr := 2;
           helpline[1] := 1046;
           helpline[0] := 1047;
         END;
         error;
       END;
    14,15,16: extrarightbrace;{1085:}
    2: package(0);
    3:
       BEGIN
         adjusttail := 29995;
         package(0);
       END;
    4:
       BEGIN
         endgraf;
         package(0);
       END;
    5:
       BEGIN
         endgraf;
         package(4);
       END;{:1085}{1100:}
    11:
        BEGIN
          endgraf;
          q := eqtb[2892].hh.rh;
          mem[q].hh.rh := mem[q].hh.rh+1;
          d := eqtb[5836].int;
          f := eqtb[5305].int;
          unsave;
          saveptr := saveptr-1;
          p := vpackage(mem[curlist.headfield].hh.rh,0,1,1073741823);
          popnest;
          IF savestack[saveptr+0].int<255 THEN
            BEGIN
              BEGIN
                mem[curlist.tailfield].
                hh.rh := getnode(5);
                curlist.tailfield := mem[curlist.tailfield].hh.rh;
              END;
              mem[curlist.tailfield].hh.b0 := 3;
              mem[curlist.tailfield].hh.b1 := savestack[saveptr+0].int;
              mem[curlist.tailfield+3].int := mem[p+3].int+mem[p+2].int;
              mem[curlist.tailfield+4].hh.lh := mem[p+5].hh.rh;
              mem[curlist.tailfield+4].hh.rh := q;
              mem[curlist.tailfield+2].int := d;
              mem[curlist.tailfield+1].int := f;
            END
          ELSE
            BEGIN
              BEGIN
                mem[curlist.tailfield].hh.rh := getnode(2);
                curlist.tailfield := mem[curlist.tailfield].hh.rh;
              END;
              mem[curlist.tailfield].hh.b0 := 5;
              mem[curlist.tailfield].hh.b1 := 0;
              mem[curlist.tailfield+1].int := mem[p+5].hh.rh;
              deleteglueref(q);
            END;
          freenode(p,7);
          IF nestptr=0 THEN buildpage;
        END;
    8:{1026:}
       BEGIN
         IF (curinput.locfield<>0)OR((curinput.indexfield<>6)AND(
            curinput.indexfield<>3))THEN{1027:}
           BEGIN
             BEGIN
               IF interaction=3 THEN;
               printnl(262);
               print(1011);
             END;
             BEGIN
               helpptr := 2;
               helpline[1] := 1012;
               helpline[0] := 1013;
             END;
             error;
             REPEAT
               gettoken;
             UNTIL curinput.locfield=0;
           END{:1027};
         endtokenlist;
         endgraf;
         unsave;
         outputactive := false;
         insertpenalties := 0;
{1028:}
         IF eqtb[3933].hh.rh<>0 THEN
           BEGIN
             BEGIN
               IF interaction=3 THEN;
               printnl(262);
               print(1014);
             END;
             printesc(409);
             printint(255);
             BEGIN
               helpptr := 3;
               helpline[2] := 1015;
               helpline[1] := 1016;
               helpline[0] := 1017;
             END;
             boxerror(255);
           END{:1028};
         IF curlist.tailfield<>curlist.headfield THEN
           BEGIN
             mem[pagetail].hh.rh := 
                                    mem[curlist.headfield].hh.rh;
             pagetail := curlist.tailfield;
           END;
         IF mem[29998].hh.rh<>0 THEN
           BEGIN
             IF mem[29999].hh.rh=0 THEN nest[0].
               tailfield := pagetail;
             mem[pagetail].hh.rh := mem[29999].hh.rh;
             mem[29999].hh.rh := mem[29998].hh.rh;
             mem[29998].hh.rh := 0;
             pagetail := 29998;
           END;
         popnest;
         buildpage;
       END{:1026};{:1100}{1118:}
    10: builddiscretionary;
{:1118}{1132:}
    6:
       BEGIN
         backinput;
         curtok := 6710;
         BEGIN
           IF interaction=3 THEN;
           printnl(262);
           print(625);
         END;
         printesc(900);
         print(626);
         BEGIN
           helpptr := 1;
           helpline[0] := 1126;
         END;
         inserror;
       END;
{:1132}{1133:}
    7:
       BEGIN
         endgraf;
         unsave;
         alignpeek;
       END;
{:1133}{1168:}
    12:
        BEGIN
          endgraf;
          unsave;
          saveptr := saveptr-2;
          p := vpackage(mem[curlist.headfield].hh.rh,savestack[saveptr+1].int,
               savestack[saveptr+0].int,1073741823);
          popnest;
          BEGIN
            mem[curlist.tailfield].hh.rh := newnoad;
            curlist.tailfield := mem[curlist.tailfield].hh.rh;
          END;
          mem[curlist.tailfield].hh.b0 := 29;
          mem[curlist.tailfield+1].hh.rh := 2;
          mem[curlist.tailfield+1].hh.lh := p;
        END;{:1168}{1173:}
    13: buildchoices;
{:1173}{1186:}
    9:
       BEGIN
         unsave;
         saveptr := saveptr-1;
         mem[savestack[saveptr+0].int].hh.rh := 3;
         p := finmlist(0);
         mem[savestack[saveptr+0].int].hh.lh := p;
         IF p<>0 THEN IF mem[p].hh.rh=0 THEN IF mem[p].hh.b0=16 THEN
                                               BEGIN
                                                 IF mem
                                                    [p+3].hh.rh=0 THEN IF mem[p+2].hh.rh=0 THEN
                                                                         BEGIN
                                                                           mem[savestack[saveptr
                                                                           +0].int].hh := mem[p+1].
                                                                                          hh;
                                                                           freenode(p,4);
                                                                         END;
                                               END
         ELSE IF mem[p].hh.b0=28 THEN IF savestack[saveptr+0].int=curlist.
                                         tailfield+1 THEN IF mem[curlist.tailfield].hh.b0=16 THEN
                                                            {1187:}
                                                            BEGIN
                                                              q := 
                                                                   curlist.headfield;
                                                              WHILE mem[q].hh.rh<>curlist.tailfield 
                                                                DO
                                                                q := mem[q].hh.rh;
                                                              mem[q].hh.rh := p;
                                                              freenode(curlist.tailfield,4);
                                                              curlist.tailfield := p;
                                                            END{:1187};
       END;{:1186}
    ELSE confusion(1048)
  END;
END;
{:1068}
PROCEDURE maincontrol;

LABEL 60,21,70,80,90,91,92,95,100,101,110,111,112,120,10;

VAR t: integer;
BEGIN
  IF eqtb[3419].hh.rh<>0 THEN begintokenlist(eqtb[3419].hh.rh,12);
  60: getxtoken;
  21:{1031:}IF interrupt<>0 THEN IF OKtointerrupt THEN
                                   BEGIN
                                     backinput;
                                     BEGIN
                                       IF interrupt<>0 THEN pauseforinstructions;
                                     END;
                                     goto 60;
                                   END;
{if panicking then checkmem(false);}
  IF eqtb[5299].int>0 THEN showcurcmdchr{:1031};
  CASE abs(curlist.modefield)+curcmd OF 
    113,114,170: goto 70;
    118:
         BEGIN
           scancharnum;
           curchr := curval;
           goto 70;
         END;
    167:
         BEGIN
           getxtoken;
           IF (curcmd=11)OR(curcmd=12)OR(curcmd=68)OR(curcmd=16)THEN cancelboundary 
             := true;
           goto 21;
         END;
    112: IF curlist.auxfield.hh.lh=1000 THEN goto 120
         ELSE appspace;
    166,267: goto 120;{1045:}
    1,102,203,11,213,268:;
    40,141,242:
                BEGIN{406:}
                  REPEAT
                    getxtoken;
                  UNTIL curcmd<>10{:406};
                  goto 21;
                END;
    15: IF itsallover THEN goto 10;
{1048:}
    23,123,224,71,172,273,{:1048}{1098:}39,{:1098}{1111:}45,{:1111}
{1144:}49,150,{:1144}7,108,209: reportillegalcase;
{1046:}
    8,109,9,110,18,119,70,171,51,152,16,117,50,151,53,154,67,168,54,
    155,55,156,57,158,56,157,31,132,52,153,29,130,47,148,212,216,217,230,227
    ,236,239{:1046}: insertdollarsign;
{1056:}
    37,137,238:
                BEGIN
                  BEGIN
                    mem[curlist.tailfield].hh.rh := scanrulespec
                    ;
                    curlist.tailfield := mem[curlist.tailfield].hh.rh;
                  END;
                  IF abs(curlist.modefield)=1 THEN curlist.auxfield.int := -65536000
                  ELSE IF 
                          abs(curlist.modefield)=102 THEN curlist.auxfield.hh.lh := 1000;
                END;
{:1056}{1057:}
    28,128,229,231: appendglue;
    30,131,232,233: appendkern;
{:1057}{1063:}
    2,103: newsavelevel(1);
    62,163,264: newsavelevel(14);
    63,164,265: IF curgroup=14 THEN unsave
                ELSE offsave;
{:1063}{1067:}
    3,104,205: handlerightbrace;
{:1067}{1073:}
    22,124,225:
                BEGIN
                  t := curchr;
                  scandimen(false,false,false);
                  IF t=0 THEN scanbox(curval)
                  ELSE scanbox(-curval);
                END;
    32,133,234: scanbox(1073742237+curchr);
    21,122,223: beginbox(0);
{:1073}{1090:}
    44: newgraf(curchr>0);
    12,13,17,69,4,24,36,46,48,27,34,65,66:
                                           BEGIN
                                             backinput;
                                             newgraf(true);
                                           END;
{:1090}{1092:}
    145,246: indentinhmode;
{:1092}{1094:}
    14:
        BEGIN
          normalparagraph;
          IF curlist.modefield>0 THEN buildpage;
        END;
    115:
         BEGIN
           IF alignstate<0 THEN offsave;
           endgraf;
           IF curlist.modefield=1 THEN buildpage;
         END;
    116,129,138,126,134: headforvmode;
{:1094}{1097:}
    38,139,240,140,241: begininsertoradjust;
    19,120,221: makemark;{:1097}{1102:}
    43,144,245: appendpenalty;
{:1102}{1104:}
    26,127,228: deletelast;{:1104}{1109:}
    25,125,226: unpackage;
{:1109}{1112:}
    146: appenditaliccorrection;
    247:
         BEGIN
           mem[curlist.tailfield].hh.rh := newkern(0);
           curlist.tailfield := mem[curlist.tailfield].hh.rh;
         END;
{:1112}{1116:}
    149,250: appenddiscretionary;{:1116}{1122:}
    147: makeaccent;
{:1122}{1126:}
    6,107,208,5,106,207: alignerror;
    35,136,237: noalignerror;
    64,165,266: omiterror;{:1126}{1130:}
    33,135: initalign;
    235: IF privileged THEN IF curgroup=15 THEN initalign
         ELSE offsave;
    10,111: doendv;{:1130}{1134:}
    68,169,270: cserror;
{:1134}{1137:}
    105: initmath;
{:1137}{1140:}
    251: IF privileged THEN IF curgroup=15 THEN starteqno
         ELSE
           offsave;
{:1140}{1150:}
    204:
         BEGIN
           BEGIN
             mem[curlist.tailfield].hh.rh := newnoad;
             curlist.tailfield := mem[curlist.tailfield].hh.rh;
           END;
           backinput;
           scanmath(curlist.tailfield+1);
         END;
{:1150}{1154:}
    214,215,271: setmathchar(eqtb[5007+curchr].hh.rh);
    219:
         BEGIN
           scancharnum;
           curchr := curval;
           setmathchar(eqtb[5007+curchr].hh.rh);
         END;
    220:
         BEGIN
           scanfifteenbitint;
           setmathchar(curval);
         END;
    272: setmathchar(curchr);
    218:
         BEGIN
           scantwentysevenbitint;
           setmathchar(curval DIV 4096);
         END;
{:1154}{1158:}
    253:
         BEGIN
           BEGIN
             mem[curlist.tailfield].hh.rh := newnoad;
             curlist.tailfield := mem[curlist.tailfield].hh.rh;
           END;
           mem[curlist.tailfield].hh.b0 := curchr;
           scanmath(curlist.tailfield+1);
         END;
    254: mathlimitswitch;{:1158}{1162:}
    269: mathradical;
{:1162}{1164:}
    248,249: mathac;{:1164}{1167:}
    259:
         BEGIN
           scanspec(12,false);
           normalparagraph;
           pushnest;
           curlist.modefield := -1;
           curlist.auxfield.int := -65536000;
           IF eqtb[3418].hh.rh<>0 THEN begintokenlist(eqtb[3418].hh.rh,11);
         END;
{:1167}{1171:}
    256:
         BEGIN
           mem[curlist.tailfield].hh.rh := newstyle(curchr);
           curlist.tailfield := mem[curlist.tailfield].hh.rh;
         END;
    258:
         BEGIN
           BEGIN
             mem[curlist.tailfield].hh.rh := newglue(0);
             curlist.tailfield := mem[curlist.tailfield].hh.rh;
           END;
           mem[curlist.tailfield].hh.b1 := 98;
         END;
    257: appendchoices;
{:1171}{1175:}
    211,210: subsup;{:1175}{1180:}
    255: mathfraction;
{:1180}{1190:}
    252: mathleftright;
{:1190}{1193:}
    206: IF curgroup=15 THEN aftermath
         ELSE offsave;
{:1193}{1210:}
    72,173,274,73,174,275,74,175,276,75,176,277,76,177,278,77,
    178,279,78,179,280,79,180,281,80,181,282,81,182,283,82,183,284,83,184,
    285,84,185,286,85,186,287,86,187,288,87,188,289,88,189,290,89,190,291,90
    ,191,292,91,192,293,92,193,294,93,194,295,94,195,296,95,196,297,96,197,
    298,97,198,299,98,199,300,99,200,301,100,201,302,101,202,303:
                                                                  prefixedcommand;{:1210}{1268:}
    41,142,243:
                BEGIN
                  gettoken;
                  aftertoken := curtok;
                END;{:1268}{1271:}
    42,143,244:
                BEGIN
                  gettoken;
                  saveforafter(curtok);
                END;{:1271}{1274:}
    61,162,263: openorclosein;
{:1274}{1276:}
    59,160,261: issuemessage;
{:1276}{1285:}
    58,159,260: shiftcase;
{:1285}{1290:}
    20,121,222: showwhatever;
{:1290}{1347:}
    60,161,262: doextension;{:1347}{:1045}
  END;
  goto 60;
  70:{1034:}mains := eqtb[4751+curchr].hh.rh;
  IF mains=1000 THEN curlist.auxfield.hh.lh := 1000
  ELSE IF mains<1000 THEN
         BEGIN
           IF mains>0 THEN curlist.auxfield.hh.lh := mains;
         END
  ELSE IF curlist.auxfield.hh.lh<1000 THEN curlist.auxfield.hh.lh := 
                                                                     1000
  ELSE curlist.auxfield.hh.lh := mains;
  mainf := eqtb[3934].hh.rh;
  bchar := fontbchar[mainf];
  falsebchar := fontfalsebchar[mainf];
  IF curlist.modefield>0 THEN IF eqtb[5313].int<>curlist.auxfield.hh.rh
                                THEN fixlanguage;
  BEGIN
    ligstack := avail;
    IF ligstack=0 THEN ligstack := getavail
    ELSE
      BEGIN
        avail := mem[ligstack].hh
                 .rh;
        mem[ligstack].hh.rh := 0;
        dynused := dynused+1;
      END;
  END;
  mem[ligstack].hh.b0 := mainf;
  curl := curchr;
  mem[ligstack].hh.b1 := curl;
  curq := curlist.tailfield;
  IF cancelboundary THEN
    BEGIN
      cancelboundary := false;
      maink := 0;
    END
  ELSE maink := bcharlabel[mainf];
  IF maink=0 THEN goto 92;
  curr := curl;
  curl := 256;
  goto 111;
  80:{1035:}IF curl<256 THEN
              BEGIN
                IF mem[curq].hh.rh>0 THEN IF mem[
                                             curlist.tailfield].hh.b1=hyphenchar[mainf]THEN insdisc 
                                            := true;
                IF ligaturepresent THEN
                  BEGIN
                    mainp := newligature(mainf,curl,mem[curq].hh
                             .rh);
                    IF lfthit THEN
                      BEGIN
                        mem[mainp].hh.b1 := 2;
                        lfthit := false;
                      END;
                    IF rthit THEN IF ligstack=0 THEN
                                    BEGIN
                                      mem[mainp].hh.b1 := mem[mainp].hh.
                                                          b1+1;
                                      rthit := false;
                                    END;
                    mem[curq].hh.rh := mainp;
                    curlist.tailfield := mainp;
                    ligaturepresent := false;
                  END;
                IF insdisc THEN
                  BEGIN
                    insdisc := false;
                    IF curlist.modefield>0 THEN
                      BEGIN
                        mem[curlist.tailfield].hh.rh := newdisc;
                        curlist.tailfield := mem[curlist.tailfield].hh.rh;
                      END;
                  END;
              END{:1035};
  90:{1036:}IF ligstack=0 THEN goto 21;
  curq := curlist.tailfield;
  curl := mem[ligstack].hh.b1;
  91: IF NOT(ligstack>=himemmin)THEN goto 95;
  92: IF (curchr<fontbc[mainf])OR(curchr>fontec[mainf])THEN
        BEGIN
          charwarning(mainf,curchr);
          BEGIN
            mem[ligstack].hh.rh := avail;
            avail := ligstack;
            dynused := dynused-1;
          END;
          goto 60;
        END;
  maini := fontinfo[charbase[mainf]+curl].qqqq;
  IF NOT(maini.b0>0)THEN
    BEGIN
      charwarning(mainf,curchr);
      BEGIN
        mem[ligstack].hh.rh := avail;
        avail := ligstack;
        dynused := dynused-1;
      END;
      goto 60;
    END;
  mem[curlist.tailfield].hh.rh := ligstack;
  curlist.tailfield := ligstack{:1036};
  100:{1038:}getnext;
  IF curcmd=11 THEN goto 101;
  IF curcmd=12 THEN goto 101;
  IF curcmd=68 THEN goto 101;
  xtoken;
  IF curcmd=11 THEN goto 101;
  IF curcmd=12 THEN goto 101;
  IF curcmd=68 THEN goto 101;
  IF curcmd=16 THEN
    BEGIN
      scancharnum;
      curchr := curval;
      goto 101;
    END;
  IF curcmd=65 THEN bchar := 256;
  curr := bchar;
  ligstack := 0;
  goto 110;
  101: mains := eqtb[4751+curchr].hh.rh;
  IF mains=1000 THEN curlist.auxfield.hh.lh := 1000
  ELSE IF mains<1000 THEN
         BEGIN
           IF mains>0 THEN curlist.auxfield.hh.lh := mains;
         END
  ELSE IF curlist.auxfield.hh.lh<1000 THEN curlist.auxfield.hh.lh := 
                                                                     1000
  ELSE curlist.auxfield.hh.lh := mains;
  BEGIN
    ligstack := avail;
    IF ligstack=0 THEN ligstack := getavail
    ELSE
      BEGIN
        avail := mem[ligstack].hh
                 .rh;
        mem[ligstack].hh.rh := 0;
        dynused := dynused+1;
      END;
  END;
  mem[ligstack].hh.b0 := mainf;
  curr := curchr;
  mem[ligstack].hh.b1 := curr;
  IF curr=falsebchar THEN curr := 256{:1038};
  110:{1039:}IF ((maini.b2)MOD 4)<>1 THEN goto 80;
  IF curr=256 THEN goto 80;
  maink := ligkernbase[mainf]+maini.b3;
  mainj := fontinfo[maink].qqqq;
  IF mainj.b0<=128 THEN goto 112;
  maink := ligkernbase[mainf]+256*mainj.b2+mainj.b3+32768-256*(128);
  111: mainj := fontinfo[maink].qqqq;
  112: IF mainj.b1=curr THEN IF mainj.b0<=128 THEN{1040:}
                               BEGIN
                                 IF mainj.b2
                                    >=128 THEN
                                   BEGIN
                                     IF curl<256 THEN
                                       BEGIN
                                         IF mem[curq].hh.rh>0 THEN IF mem
                                                                      [curlist.tailfield].hh.b1=
                                                                      hyphenchar[mainf]THEN insdisc 
                                                                     := true;
                                         IF ligaturepresent THEN
                                           BEGIN
                                             mainp := newligature(mainf,curl,mem[curq].hh
                                                      .rh);
                                             IF lfthit THEN
                                               BEGIN
                                                 mem[mainp].hh.b1 := 2;
                                                 lfthit := false;
                                               END;
                                             IF rthit THEN IF ligstack=0 THEN
                                                             BEGIN
                                                               mem[mainp].hh.b1 := mem[mainp].hh.
                                                                                   b1+1;
                                                               rthit := false;
                                                             END;
                                             mem[curq].hh.rh := mainp;
                                             curlist.tailfield := mainp;
                                             ligaturepresent := false;
                                           END;
                                         IF insdisc THEN
                                           BEGIN
                                             insdisc := false;
                                             IF curlist.modefield>0 THEN
                                               BEGIN
                                                 mem[curlist.tailfield].hh.rh := newdisc;
                                                 curlist.tailfield := mem[curlist.tailfield].hh.rh;
                                               END;
                                           END;
                                       END;
                                     BEGIN
                                       mem[curlist.tailfield].hh.rh := newkern(fontinfo[kernbase[
                                                                       mainf]+256
                                                                       *mainj.b2+mainj.b3].int);
                                       curlist.tailfield := mem[curlist.tailfield].hh.rh;
                                     END;
                                     goto 90;
                                   END;
                                 IF curl=256 THEN lfthit := true
                                 ELSE IF ligstack=0 THEN rthit := true;
                                 BEGIN
                                   IF interrupt<>0 THEN pauseforinstructions;
                                 END;
                                 CASE mainj.b2 OF 
                                   1,5:
                                        BEGIN
                                          curl := mainj.b3;
                                          maini := fontinfo[charbase[mainf]+curl].qqqq;
                                          ligaturepresent := true;
                                        END;
                                   2,6:
                                        BEGIN
                                          curr := mainj.b3;
                                          IF ligstack=0 THEN
                                            BEGIN
                                              ligstack := newligitem(curr);
                                              bchar := 256;
                                            END
                                          ELSE IF (ligstack>=himemmin)THEN
                                                 BEGIN
                                                   mainp := ligstack;
                                                   ligstack := newligitem(curr);
                                                   mem[ligstack+1].hh.rh := mainp;
                                                 END
                                          ELSE mem[ligstack].hh.b1 := curr;
                                        END;
                                   3:
                                      BEGIN
                                        curr := mainj.b3;
                                        mainp := ligstack;
                                        ligstack := newligitem(curr);
                                        mem[ligstack].hh.rh := mainp;
                                      END;
                                   7,11:
                                         BEGIN
                                           IF curl<256 THEN
                                             BEGIN
                                               IF mem[curq].hh.rh>0 THEN IF mem[
                                                                            curlist.tailfield].hh.b1
                                                                            =hyphenchar[mainf]THEN
                                                                           insdisc := true;
                                               IF ligaturepresent THEN
                                                 BEGIN
                                                   mainp := newligature(mainf,curl,mem[curq].hh
                                                            .rh);
                                                   IF lfthit THEN
                                                     BEGIN
                                                       mem[mainp].hh.b1 := 2;
                                                       lfthit := false;
                                                     END;
                                                   IF false THEN IF ligstack=0 THEN
                                                                   BEGIN
                                                                     mem[mainp].hh.b1 := mem[mainp].
                                                                                         hh.
                                                                                         b1+1;
                                                                     rthit := false;
                                                                   END;
                                                   mem[curq].hh.rh := mainp;
                                                   curlist.tailfield := mainp;
                                                   ligaturepresent := false;
                                                 END;
                                               IF insdisc THEN
                                                 BEGIN
                                                   insdisc := false;
                                                   IF curlist.modefield>0 THEN
                                                     BEGIN
                                                       mem[curlist.tailfield].hh.rh := newdisc;
                                                       curlist.tailfield := mem[curlist.tailfield].
                                                                            hh.rh;
                                                     END;
                                                 END;
                                             END;
                                           curq := curlist.tailfield;
                                           curl := mainj.b3;
                                           maini := fontinfo[charbase[mainf]+curl].qqqq;
                                           ligaturepresent := true;
                                         END;
                                   ELSE
                                     BEGIN
                                       curl := mainj.b3;
                                       ligaturepresent := true;
                                       IF ligstack=0 THEN goto 80
                                       ELSE goto 91;
                                     END
                                 END;
                                 IF mainj.b2>4 THEN IF mainj.b2<>7 THEN goto 80;
                                 IF curl<256 THEN goto 110;
                                 maink := bcharlabel[mainf];
                                 goto 111;
                               END{:1040};
  IF mainj.b0=0 THEN maink := maink+1
  ELSE
    BEGIN
      IF mainj.b0>=128 THEN goto
        80;
      maink := maink+mainj.b0+1;
    END;
  goto 111{:1039};
  95:{1037:}mainp := mem[ligstack+1].hh.rh;
  IF mainp>0 THEN
    BEGIN
      mem[curlist.tailfield].hh.rh := mainp;
      curlist.tailfield := mem[curlist.tailfield].hh.rh;
    END;
  tempptr := ligstack;
  ligstack := mem[tempptr].hh.rh;
  freenode(tempptr,2);
  maini := fontinfo[charbase[mainf]+curl].qqqq;
  ligaturepresent := true;
  IF ligstack=0 THEN IF mainp>0 THEN goto 100
  ELSE curr := bchar
  ELSE curr := 
               mem[ligstack].hh.b1;
  goto 110{:1037}{:1034};
  120:{1041:}IF eqtb[2894].hh.rh=0 THEN
               BEGIN{1042:}
                 BEGIN
                   mainp := fontglue[
                            eqtb[3934].hh.rh];
                   IF mainp=0 THEN
                     BEGIN
                       mainp := newspec(0);
                       maink := parambase[eqtb[3934].hh.rh]+2;
                       mem[mainp+1].int := fontinfo[maink].int;
                       mem[mainp+2].int := fontinfo[maink+1].int;
                       mem[mainp+3].int := fontinfo[maink+2].int;
                       fontglue[eqtb[3934].hh.rh] := mainp;
                     END;
                 END{:1042};
                 tempptr := newglue(mainp);
               END
       ELSE tempptr := newparamglue(12);
  mem[curlist.tailfield].hh.rh := tempptr;
  curlist.tailfield := tempptr;
  goto 60{:1041};
  10:
END;{:1030}{1284:}
PROCEDURE giveerrhelp;
BEGIN
  tokenshow(eqtb[3421].hh.rh);
END;
{:1284}{1303:}{524:}
FUNCTION openfmtfile: boolean;

LABEL 40,10;

VAR j: 0..bufsize;
BEGIN
  j := curinput.locfield;
  IF buffer[curinput.locfield]=38 THEN
    BEGIN
      curinput.locfield := curinput.
                           locfield+1;
      j := curinput.locfield;
      buffer[last] := 32;
      WHILE buffer[j]<>32 DO
        j := j+1;
      packbufferedname(0,curinput.locfield,j-1);
      IF wopenin(fmtfile)THEN goto 40;
      packbufferedname(11,curinput.locfield,j-1);
      IF wopenin(fmtfile)THEN goto 40;;
      writeln(output,'Sorry, I can''t find that format;',' will try PLAIN.');
      flush(output);
    END;
  packbufferedname(16,1,0);
  IF NOT wopenin(fmtfile)THEN
    BEGIN;
      writeln(output,'I can''t find TeXformats/plain.fmt!');
      openfmtfile := false;
      goto 10;
    END;
  40: curinput.locfield := j;
  openfmtfile := true;
  10:
END;{:524}
FUNCTION loadfmtfile: boolean;

LABEL 6666,10;

VAR j,k: integer;
  p,q: halfword;
  x: integer;
  w: fourquarters;
BEGIN{1308:}
  x := fmtfile^.int;
  IF x<>305924274 THEN goto 6666;
  BEGIN
    get(fmtfile);
    x := fmtfile^.int;
  END;
  IF x<>0 THEN goto 6666;
  BEGIN
    get(fmtfile);
    x := fmtfile^.int;
  END;
  IF x<>30000 THEN goto 6666;
  BEGIN
    get(fmtfile);
    x := fmtfile^.int;
  END;
  IF x<>6106 THEN goto 6666;
  BEGIN
    get(fmtfile);
    x := fmtfile^.int;
  END;
  IF x<>1777 THEN goto 6666;
  BEGIN
    get(fmtfile);
    x := fmtfile^.int;
  END;
  IF x<>307 THEN goto 6666{:1308};
{1310:}
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF x<0 THEN goto 6666;
    IF x>poolsize THEN
      BEGIN;
        writeln(output,'---! Must increase the ','string pool size');
        goto 6666;
      END
    ELSE poolptr := x;
  END;
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF x<0 THEN goto 6666;
    IF x>maxstrings THEN
      BEGIN;
        writeln(output,'---! Must increase the ','max strings');
        goto 6666;
      END
    ELSE strptr := x;
  END;
  FOR k:=0 TO strptr DO
    BEGIN
      BEGIN
        get(fmtfile);
        x := fmtfile^.int;
      END;
      IF (x<0)OR(x>poolptr)THEN goto 6666
      ELSE strstart[k] := x;
    END;
  k := 0;
  WHILE k+4<poolptr DO
    BEGIN
      BEGIN
        get(fmtfile);
        w := fmtfile^.qqqq;
      END;
      strpool[k] := w.b0;
      strpool[k+1] := w.b1;
      strpool[k+2] := w.b2;
      strpool[k+3] := w.b3;
      k := k+4;
    END;
  k := poolptr-4;
  BEGIN
    get(fmtfile);
    w := fmtfile^.qqqq;
  END;
  strpool[k] := w.b0;
  strpool[k+1] := w.b1;
  strpool[k+2] := w.b2;
  strpool[k+3] := w.b3;
  initstrptr := strptr;
  initpoolptr := poolptr{:1310};{1312:}
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF (x<1019)OR(x>29986)THEN goto 6666
    ELSE lomemmax := x;
  END;
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF (x<20)OR(x>lomemmax)THEN goto 6666
    ELSE rover := x;
  END;
  p := 0;
  q := rover;
  REPEAT
    FOR k:=p TO q+1 DO
      BEGIN
        get(fmtfile);
        mem[k] := fmtfile^;
      END;
    p := q+mem[q].hh.lh;
    IF (p>lomemmax)OR((q>=mem[q+1].hh.rh)AND(mem[q+1].hh.rh<>rover))THEN goto
      6666;
    q := mem[q+1].hh.rh;
  UNTIL q=rover;
  FOR k:=p TO lomemmax DO
    BEGIN
      get(fmtfile);
      mem[k] := fmtfile^;
    END;
  IF memmin<-2 THEN
    BEGIN
      p := mem[rover+1].hh.lh;
      q := memmin+1;
      mem[memmin].hh.rh := 0;
      mem[memmin].hh.lh := 0;
      mem[p+1].hh.rh := q;
      mem[rover+1].hh.lh := q;
      mem[q+1].hh.rh := rover;
      mem[q+1].hh.lh := p;
      mem[q].hh.rh := 65535;
      mem[q].hh.lh := -0-q;
    END;
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF (x<lomemmax+1)OR(x>29987)THEN goto 6666
    ELSE himemmin := x;
  END;
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF (x<0)OR(x>30000)THEN goto 6666
    ELSE avail := x;
  END;
  memend := 30000;
  FOR k:=himemmin TO memend DO
    BEGIN
      get(fmtfile);
      mem[k] := fmtfile^;
    END;
  BEGIN
    get(fmtfile);
    varused := fmtfile^.int;
  END;
  BEGIN
    get(fmtfile);
    dynused := fmtfile^.int;
  END{:1312};{1314:}{1317:}
  k := 1;
  REPEAT
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF (x<1)OR(k+x>6107)THEN goto 6666;
    FOR j:=k TO k+x-1 DO
      BEGIN
        get(fmtfile);
        eqtb[j] := fmtfile^;
      END;
    k := k+x;
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF (x<0)OR(k+x>6107)THEN goto 6666;
    FOR j:=k TO k+x-1 DO
      eqtb[j] := eqtb[k-1];
    k := k+x;
  UNTIL k>6106{:1317};
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF (x<514)OR(x>2614)THEN goto 6666
    ELSE parloc := x;
  END;
  partoken := 4095+parloc;
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF (x<514)OR(x>2614)THEN goto 6666
    ELSE writeloc := x;
  END;
{1319:}
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF (x<514)OR(x>2614)THEN goto 6666
    ELSE hashused := x;
  END;
  p := 513;
  REPEAT
    BEGIN
      BEGIN
        get(fmtfile);
        x := fmtfile^.int;
      END;
      IF (x<p+1)OR(x>hashused)THEN goto 6666
      ELSE p := x;
    END;
    BEGIN
      get(fmtfile);
      hash[p] := fmtfile^.hh;
    END;
  UNTIL p=hashused;
  FOR p:=hashused+1 TO 2880 DO
    BEGIN
      get(fmtfile);
      hash[p] := fmtfile^.hh;
    END;
  BEGIN
    get(fmtfile);
    cscount := fmtfile^.int;
  END{:1319}{:1314};
{1321:}
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF x<7 THEN goto 6666;
    IF x>fontmemsize THEN
      BEGIN;
        writeln(output,'---! Must increase the ','font mem size');
        goto 6666;
      END
    ELSE fmemptr := x;
  END;
  FOR k:=0 TO fmemptr-1 DO
    BEGIN
      get(fmtfile);
      fontinfo[k] := fmtfile^;
    END;
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF x<0 THEN goto 6666;
    IF x>fontmax THEN
      BEGIN;
        writeln(output,'---! Must increase the ','font max');
        goto 6666;
      END
    ELSE fontptr := x;
  END;
  FOR k:=0 TO fontptr DO{1323:}
    BEGIN
      BEGIN
        get(fmtfile);
        fontcheck[k] := fmtfile^.qqqq;
      END;
      BEGIN
        get(fmtfile);
        fontsize[k] := fmtfile^.int;
      END;
      BEGIN
        get(fmtfile);
        fontdsize[k] := fmtfile^.int;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>65535)THEN goto 6666
        ELSE fontparams[k] := x;
      END;
      BEGIN
        get(fmtfile);
        hyphenchar[k] := fmtfile^.int;
      END;
      BEGIN
        get(fmtfile);
        skewchar[k] := fmtfile^.int;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>strptr)THEN goto 6666
        ELSE fontname[k] := x;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>strptr)THEN goto 6666
        ELSE fontarea[k] := x;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>255)THEN goto 6666
        ELSE fontbc[k] := x;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>255)THEN goto 6666
        ELSE fontec[k] := x;
      END;
      BEGIN
        get(fmtfile);
        charbase[k] := fmtfile^.int;
      END;
      BEGIN
        get(fmtfile);
        widthbase[k] := fmtfile^.int;
      END;
      BEGIN
        get(fmtfile);
        heightbase[k] := fmtfile^.int;
      END;
      BEGIN
        get(fmtfile);
        depthbase[k] := fmtfile^.int;
      END;
      BEGIN
        get(fmtfile);
        italicbase[k] := fmtfile^.int;
      END;
      BEGIN
        get(fmtfile);
        ligkernbase[k] := fmtfile^.int;
      END;
      BEGIN
        get(fmtfile);
        kernbase[k] := fmtfile^.int;
      END;
      BEGIN
        get(fmtfile);
        extenbase[k] := fmtfile^.int;
      END;
      BEGIN
        get(fmtfile);
        parambase[k] := fmtfile^.int;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>lomemmax)THEN goto 6666
        ELSE fontglue[k] := x;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>fmemptr-1)THEN goto 6666
        ELSE bcharlabel[k] := x;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>256)THEN goto 6666
        ELSE fontbchar[k] := x;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>256)THEN goto 6666
        ELSE fontfalsebchar[k] := x;
      END;
    END{:1323}{:1321};{1325:}
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF (x<0)OR(x>307)THEN goto 6666
    ELSE hyphcount := x;
  END;
  FOR k:=1 TO hyphcount DO
    BEGIN
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>307)THEN goto 6666
        ELSE j := x;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>strptr)THEN goto 6666
        ELSE hyphword[j] := x;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>65535)THEN goto 6666
        ELSE hyphlist[j] := x;
      END;
    END;
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF x<0 THEN goto 6666;
    IF x>triesize THEN
      BEGIN;
        writeln(output,'---! Must increase the ','trie size');
        goto 6666;
      END
    ELSE j := x;
  END;
  triemax := j;
  FOR k:=0 TO j DO
    BEGIN
      get(fmtfile);
      trie[k] := fmtfile^.hh;
    END;
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF x<0 THEN goto 6666;
    IF x>trieopsize THEN
      BEGIN;
        writeln(output,'---! Must increase the ','trie op size');
        goto 6666;
      END
    ELSE j := x;
  END;
  trieopptr := j;
  FOR k:=1 TO j DO
    BEGIN
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>63)THEN goto 6666
        ELSE hyfdistance[k] := x;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>63)THEN goto 6666
        ELSE hyfnum[k] := x;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>255)THEN goto 6666
        ELSE hyfnext[k] := x;
      END;
    END;
  FOR k:=0 TO 255 DO
    trieused[k] := 0;
  k := 256;
  WHILE j>0 DO
    BEGIN
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<0)OR(x>k-1)THEN goto 6666
        ELSE k := x;
      END;
      BEGIN
        BEGIN
          get(fmtfile);
          x := fmtfile^.int;
        END;
        IF (x<1)OR(x>j)THEN goto 6666
        ELSE x := x;
      END;
      trieused[k] := x;
      j := j-x;
      opstart[k] := j;
    END;
  trienotready := false{:1325};
{1327:}
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF (x<0)OR(x>3)THEN goto 6666
    ELSE interaction := x;
  END;
  BEGIN
    BEGIN
      get(fmtfile);
      x := fmtfile^.int;
    END;
    IF (x<0)OR(x>strptr)THEN goto 6666
    ELSE formatident := x;
  END;
  BEGIN
    get(fmtfile);
    x := fmtfile^.int;
  END;
  IF (x<>69069)THEN goto 6666{:1327};
  loadfmtfile := true;
  goto 10;
  6666:;
  writeln(output,'(Fatal format file error; I''m stymied)');
  loadfmtfile := false;
  10:
END;
{:1303}{1330:}{1333:}
PROCEDURE closefilesandterminate;

VAR k: integer;
BEGIN{1378:}
  FOR k:=0 TO 15 DO
    IF writeopen[k]THEN aclose(writefile[k])
{:1378};
  eqtb[5312].int := -1;
  IF eqtb[5294].int>0 THEN{1334:}IF logopened THEN
                                   BEGIN
                                     writeln(logfile,
                                             ' ');
                                     writeln(logfile,'Here is how much of TeX''s memory',
                                             ' you used:');
                                     write(logfile,' ',strptr-initstrptr:1,' string');
                                     IF strptr<>initstrptr+1 THEN write(logfile,'s');
                                     writeln(logfile,' out of ',maxstrings-initstrptr:1);
                                     writeln(logfile,' ',poolptr-initpoolptr:1,
                                             ' string characters out of ',
                                             poolsize-initpoolptr:1);
                                     writeln(logfile,' ',lomemmax-memmin+memend-himemmin+2:1,
                                             ' words of memory out of ',memend+1-memmin:1);
                                     writeln(logfile,' ',cscount:1,
                                             ' multiletter control sequences out of ',
                                             2100:1);
                                     write(logfile,' ',fmemptr:1,' words of font info for ',fontptr-
                                           0:1,
                                           ' font');
                                     IF fontptr<>1 THEN write(logfile,'s');
                                     writeln(logfile,', out of ',fontmemsize:1,' for ',fontmax-0:1);
                                     write(logfile,' ',hyphcount:1,' hyphenation exception');
                                     IF hyphcount<>1 THEN write(logfile,'s');
                                     writeln(logfile,' out of ',307:1);
                                     writeln(logfile,' ',maxinstack:1,'i,',maxneststack:1,'n,',
                                             maxparamstack:
                                             1,'p,',maxbufstack+1:1,'b,',maxsavestack+6:1,
                                             's stack positions out of '
                                             ,stacksize:1,'i,',nestsize:1,'n,',paramsize:1,'p,',
                                             bufsize:1,'b,',
                                             savesize:1,'s');
                                   END{:1334};;
{642:}
  WHILE curs>-1 DO
    BEGIN
      IF curs>0 THEN
        BEGIN
          dvibuf[dviptr] := 142;
          dviptr := dviptr+1;
          IF dviptr=dvilimit THEN dviswap;
        END
      ELSE
        BEGIN
          BEGIN
            dvibuf[dviptr] := 140;
            dviptr := dviptr+1;
            IF dviptr=dvilimit THEN dviswap;
          END;
          totalpages := totalpages+1;
        END;
      curs := curs-1;
    END;
  IF totalpages=0 THEN printnl(838)
  ELSE
    BEGIN
      BEGIN
        dvibuf[dviptr] := 248;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      dvifour(lastbop);
      lastbop := dvioffset+dviptr-5;
      dvifour(25400000);
      dvifour(473628672);
      preparemag;
      dvifour(eqtb[5280].int);
      dvifour(maxv);
      dvifour(maxh);
      BEGIN
        dvibuf[dviptr] := maxpush DIV 256;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      BEGIN
        dvibuf[dviptr] := maxpush MOD 256;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      BEGIN
        dvibuf[dviptr] := (totalpages DIV 256)MOD 256;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      BEGIN
        dvibuf[dviptr] := totalpages MOD 256;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
{643:}
      WHILE fontptr>0 DO
        BEGIN
          IF fontused[fontptr]THEN dvifontdef(
                                              fontptr);
          fontptr := fontptr-1;
        END{:643};
      BEGIN
        dvibuf[dviptr] := 249;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      dvifour(lastbop);
      BEGIN
        dvibuf[dviptr] := 2;
        dviptr := dviptr+1;
        IF dviptr=dvilimit THEN dviswap;
      END;
      k := 4+((dvibufsize-dviptr)MOD 4);
      WHILE k>0 DO
        BEGIN
          BEGIN
            dvibuf[dviptr] := 223;
            dviptr := dviptr+1;
            IF dviptr=dvilimit THEN dviswap;
          END;
          k := k-1;
        END;
{599:}
      IF dvilimit=halfbuf THEN writedvi(halfbuf,dvibufsize-1);
      IF dviptr>0 THEN writedvi(0,dviptr-1){:599};
      printnl(839);
      slowprint(outputfilename);
      print(286);
      printint(totalpages);
      print(840);
      IF totalpages<>1 THEN printchar(115);
      print(841);
      printint(dvioffset+dviptr);
      print(842);
      bclose(dvifile);
    END{:642};
  IF logopened THEN
    BEGIN
      writeln(logfile);
      aclose(logfile);
      selector := selector-2;
      IF selector=17 THEN
        BEGIN
          printnl(1276);
          slowprint(logname);
          printchar(46);
          println;
        END;
    END;
END;
{:1333}{1335:}
PROCEDURE finalcleanup;

LABEL 10;

VAR c: smallnumber;
BEGIN
  c := curchr;
  IF c<>1 THEN eqtb[5312].int := -1;
  IF jobname=0 THEN openlogfile;
  WHILE inputptr>0 DO
    IF curinput.statefield=0 THEN endtokenlist
    ELSE
      endfilereading;
  WHILE openparens>0 DO
    BEGIN
      print(1277);
      openparens := openparens-1;
    END;
  IF curlevel>1 THEN
    BEGIN
      printnl(40);
      printesc(1278);
      print(1279);
      printint(curlevel-1);
      printchar(41);
    END;
  WHILE condptr<>0 DO
    BEGIN
      printnl(40);
      printesc(1278);
      print(1280);
      printcmdchr(105,curif);
      IF ifline<>0 THEN
        BEGIN
          print(1281);
          printint(ifline);
        END;
      print(1282);
      ifline := mem[condptr+1].int;
      curif := mem[condptr].hh.b1;
      tempptr := condptr;
      condptr := mem[condptr].hh.rh;
      freenode(tempptr,2);
    END;
  IF history<>0 THEN IF ((history=1)OR(interaction<3))THEN IF selector=19
                                                             THEN
                                                             BEGIN
                                                               selector := 17;
                                                               printnl(1283);
                                                               selector := 19;
                                                             END;
  IF c=1 THEN
    BEGIN
      IF TeXVariation>0 THEN
        BEGIN
          FOR c:=0 TO 4 DO
            IF 
               curmark[c]<>0 THEN deletetokenref(curmark[c]);
          IF lastglue<>65535 THEN deleteglueref(lastglue);
          storefmtfile;
          goto 10;
        END;
      printnl(1284);
      goto 10;
    END;
  10:
END;{:1335}{1336:}
PROCEDURE initprim;
BEGIN
  nonewcontrolsequence := false;{226:}
  primitive(376,75,2882);
  primitive(377,75,2883);
  primitive(378,75,2884);
  primitive(379,75,2885);
  primitive(380,75,2886);
  primitive(381,75,2887);
  primitive(382,75,2888);
  primitive(383,75,2889);
  primitive(384,75,2890);
  primitive(385,75,2891);
  primitive(386,75,2892);
  primitive(387,75,2893);
  primitive(388,75,2894);
  primitive(389,75,2895);
  primitive(390,75,2896);
  primitive(391,76,2897);
  primitive(392,76,2898);
  primitive(393,76,2899);
{:226}{230:}
  primitive(398,72,3413);
  primitive(399,72,3414);
  primitive(400,72,3415);
  primitive(401,72,3416);
  primitive(402,72,3417);
  primitive(403,72,3418);
  primitive(404,72,3419);
  primitive(405,72,3420);
  primitive(406,72,3421);{:230}{238:}
  primitive(420,73,5263);
  primitive(421,73,5264);
  primitive(422,73,5265);
  primitive(423,73,5266);
  primitive(424,73,5267);
  primitive(425,73,5268);
  primitive(426,73,5269);
  primitive(427,73,5270);
  primitive(428,73,5271);
  primitive(429,73,5272);
  primitive(430,73,5273);
  primitive(431,73,5274);
  primitive(432,73,5275);
  primitive(433,73,5276);
  primitive(434,73,5277);
  primitive(435,73,5278);
  primitive(436,73,5279);
  primitive(437,73,5280);
  primitive(438,73,5281);
  primitive(439,73,5282);
  primitive(440,73,5283);
  primitive(441,73,5284);
  primitive(442,73,5285);
  primitive(443,73,5286);
  primitive(444,73,5287);
  primitive(445,73,5288);
  primitive(446,73,5289);
  primitive(447,73,5290);
  primitive(448,73,5291);
  primitive(449,73,5292);
  primitive(450,73,5293);
  primitive(451,73,5294);
  primitive(452,73,5295);
  primitive(453,73,5296);
  primitive(454,73,5297);
  primitive(455,73,5298);
  primitive(456,73,5299);
  primitive(457,73,5300);
  primitive(458,73,5301);
  primitive(459,73,5302);
  primitive(460,73,5303);
  primitive(461,73,5304);
  primitive(462,73,5305);
  primitive(463,73,5306);
  primitive(464,73,5307);
  primitive(465,73,5308);
  primitive(466,73,5309);
  primitive(467,73,5310);
  primitive(468,73,5311);
  primitive(469,73,5312);
  primitive(470,73,5313);
  primitive(471,73,5314);
  primitive(472,73,5315);
  primitive(473,73,5316);
  primitive(474,73,5317);
{:238}{248:}
  primitive(478,74,5830);
  primitive(479,74,5831);
  primitive(480,74,5832);
  primitive(481,74,5833);
  primitive(482,74,5834);
  primitive(483,74,5835);
  primitive(484,74,5836);
  primitive(485,74,5837);
  primitive(486,74,5838);
  primitive(487,74,5839);
  primitive(488,74,5840);
  primitive(489,74,5841);
  primitive(490,74,5842);
  primitive(491,74,5843);
  primitive(492,74,5844);
  primitive(493,74,5845);
  primitive(494,74,5846);
  primitive(495,74,5847);
  primitive(496,74,5848);
  primitive(497,74,5849);
  primitive(498,74,5850);{:248}{265:}
  primitive(32,64,0);
  primitive(47,44,0);
  primitive(508,45,0);
  primitive(509,90,0);
  primitive(510,40,0);
  primitive(511,41,0);
  primitive(512,61,0);
  primitive(513,16,0);
  primitive(504,107,0);
  primitive(514,15,0);
  primitive(515,92,0);
  primitive(505,67,0);
  primitive(516,62,0);
  hash[2616].rh := 516;
  eqtb[2616] := eqtb[curval];
  primitive(517,102,0);
  primitive(518,88,0);
  primitive(519,77,0);
  primitive(520,32,0);
  primitive(521,36,0);
  primitive(522,39,0);
  primitive(330,37,0);
  primitive(351,18,0);
  primitive(523,46,0);
  primitive(524,17,0);
  primitive(525,54,0);
  primitive(526,91,0);
  primitive(527,34,0);
  primitive(528,65,0);
  primitive(529,103,0);
  primitive(335,55,0);
  primitive(530,63,0);
  primitive(408,84,0);
  primitive(531,42,0);
  primitive(532,80,0);
  primitive(533,66,0);
  primitive(534,96,0);
  primitive(535,0,256);
  hash[2621].rh := 535;
  eqtb[2621] := eqtb[curval];
  primitive(536,98,0);
  primitive(537,109,0);
  primitive(407,71,0);
  primitive(352,38,0);
  primitive(538,33,0);
  primitive(539,56,0);
  primitive(540,35,0);{:265}{334:}
  primitive(597,13,256);
  parloc := curval;
  partoken := 4095+parloc;{:334}{376:}
  primitive(629,104,0);
  primitive(630,104,1);{:376}{384:}
  primitive(631,110,0);
  primitive(632,110,1);
  primitive(633,110,2);
  primitive(634,110,3);
  primitive(635,110,4);{:384}{411:}
  primitive(476,89,0);
  primitive(500,89,1);
  primitive(395,89,2);
  primitive(396,89,3);
{:411}{416:}
  primitive(668,79,102);
  primitive(669,79,1);
  primitive(670,82,0);
  primitive(671,82,1);
  primitive(672,83,1);
  primitive(673,83,3);
  primitive(674,83,2);
  primitive(675,70,0);
  primitive(676,70,1);
  primitive(677,70,2);
  primitive(678,70,3);
  primitive(679,70,4);{:416}{468:}
  primitive(735,108,0);
  primitive(736,108,1);
  primitive(737,108,2);
  primitive(738,108,3);
  primitive(739,108,4);
  primitive(740,108,5);
{:468}{487:}
  primitive(757,105,0);
  primitive(758,105,1);
  primitive(759,105,2);
  primitive(760,105,3);
  primitive(761,105,4);
  primitive(762,105,5);
  primitive(763,105,6);
  primitive(764,105,7);
  primitive(765,105,8);
  primitive(766,105,9);
  primitive(767,105,10);
  primitive(768,105,11);
  primitive(769,105,12);
  primitive(770,105,13);
  primitive(771,105,14);
  primitive(772,105,15);
  primitive(773,105,16);
{:487}{491:}
  primitive(774,106,2);
  hash[2618].rh := 774;
  eqtb[2618] := eqtb[curval];
  primitive(775,106,4);
  primitive(776,106,3);
{:491}{553:}
  primitive(802,87,0);
  hash[2624].rh := 802;
  eqtb[2624] := eqtb[curval];{:553}{780:}
  primitive(899,4,256);
  primitive(900,5,257);
  hash[2615].rh := 900;
  eqtb[2615] := eqtb[curval];
  primitive(901,5,258);
  hash[2619].rh := 902;
  hash[2620].rh := 902;
  eqtb[2620].hh.b0 := 9;
  eqtb[2620].hh.rh := 29989;
  eqtb[2620].hh.b1 := 1;
  eqtb[2619] := eqtb[2620];
  eqtb[2619].hh.b0 := 115;
{:780}{983:}
  primitive(971,81,0);
  primitive(972,81,1);
  primitive(973,81,2);
  primitive(974,81,3);
  primitive(975,81,4);
  primitive(976,81,5);
  primitive(977,81,6);
  primitive(978,81,7);
{:983}{1052:}
  primitive(1026,14,0);
  primitive(1027,14,1);
{:1052}{1058:}
  primitive(1028,26,4);
  primitive(1029,26,0);
  primitive(1030,26,1);
  primitive(1031,26,2);
  primitive(1032,26,3);
  primitive(1033,27,4);
  primitive(1034,27,0);
  primitive(1035,27,1);
  primitive(1036,27,2);
  primitive(1037,27,3);
  primitive(336,28,5);
  primitive(340,29,1);
  primitive(342,30,99);
{:1058}{1071:}
  primitive(1055,21,1);
  primitive(1056,21,0);
  primitive(1057,22,1);
  primitive(1058,22,0);
  primitive(409,20,0);
  primitive(1059,20,1);
  primitive(1060,20,2);
  primitive(966,20,3);
  primitive(1061,20,4);
  primitive(968,20,5);
  primitive(1062,20,106);
  primitive(1063,31,99);
  primitive(1064,31,100);
  primitive(1065,31,101);
  primitive(1066,31,102);{:1071}{1088:}
  primitive(1081,43,1);
  primitive(1082,43,0);{:1088}{1107:}
  primitive(1091,25,12);
  primitive(1092,25,11);
  primitive(1093,25,10);
  primitive(1094,23,0);
  primitive(1095,23,1);
  primitive(1096,24,0);
  primitive(1097,24,1);
{:1107}{1114:}
  primitive(45,47,1);
  primitive(349,47,0);
{:1114}{1141:}
  primitive(1128,48,0);
  primitive(1129,48,1);
{:1141}{1156:}
  primitive(867,50,16);
  primitive(868,50,17);
  primitive(869,50,18);
  primitive(870,50,19);
  primitive(871,50,20);
  primitive(872,50,21);
  primitive(873,50,22);
  primitive(874,50,23);
  primitive(876,50,26);
  primitive(875,50,27);
  primitive(1130,51,0);
  primitive(879,51,1);
  primitive(880,51,2);
{:1156}{1169:}
  primitive(862,53,0);
  primitive(863,53,2);
  primitive(864,53,4);
  primitive(865,53,6);
{:1169}{1178:}
  primitive(1148,52,0);
  primitive(1149,52,1);
  primitive(1150,52,2);
  primitive(1151,52,3);
  primitive(1152,52,4);
  primitive(1153,52,5);{:1178}{1188:}
  primitive(877,49,30);
  primitive(878,49,31);
  hash[2617].rh := 878;
  eqtb[2617] := eqtb[curval];
{:1188}{1208:}
  primitive(1172,93,1);
  primitive(1173,93,2);
  primitive(1174,93,4);
  primitive(1175,97,0);
  primitive(1176,97,1);
  primitive(1177,97,2);
  primitive(1178,97,3);
{:1208}{1219:}
  primitive(1192,94,0);
  primitive(1193,94,1);
{:1219}{1222:}
  primitive(1194,95,0);
  primitive(1195,95,1);
  primitive(1196,95,2);
  primitive(1197,95,3);
  primitive(1198,95,4);
  primitive(1199,95,5);
  primitive(1200,95,6);
{:1222}{1230:}
  primitive(415,85,3983);
  primitive(419,85,5007);
  primitive(416,85,4239);
  primitive(417,85,4495);
  primitive(418,85,4751);
  primitive(477,85,5574);
  primitive(412,86,3935);
  primitive(413,86,3951);
  primitive(414,86,3967);{:1230}{1250:}
  primitive(942,99,0);
  primitive(954,99,1);{:1250}{1254:}
  primitive(1218,78,0);
  primitive(1219,78,1);{:1254}{1262:}
  primitive(274,100,0);
  primitive(275,100,1);
  primitive(276,100,2);
  primitive(1228,100,3);
{:1262}{1272:}
  primitive(1229,60,1);
  primitive(1230,60,0);
{:1272}{1277:}
  primitive(1231,58,0);
  primitive(1232,58,1);
{:1277}{1286:}
  primitive(1238,57,4239);
  primitive(1239,57,4495);
{:1286}{1291:}
  primitive(1240,19,0);
  primitive(1241,19,1);
  primitive(1242,19,2);
  primitive(1243,19,3);
{:1291}{1344:}
  primitive(1286,59,0);
  primitive(594,59,1);
  writeloc := curval;
  primitive(1287,59,2);
  primitive(1288,59,3);
  primitive(1289,59,4);
  primitive(1290,59,5);{:1344};
  nonewcontrolsequence := true;
END;
{:1336}{1338:}
{procedure debughelp;label 888,10;var k,l,m,n:integer;
begin;while true do begin;printnl(1285);flush(output);
if eof(input)then goto 10;read(input,m);
if m<0 then goto 10 else if m=0 then begin goto 888;888:m:=0;
['BREAKPOINT']end else begin if eof(input)then goto 10;read(input,n);
case m of[1339:]1:printword(mem[n]);2:printint(mem[n].hh.lh);
3:printint(mem[n].hh.rh);4:printword(eqtb[n]);5:printword(fontinfo[n]);
6:printword(savestack[n]);7:showbox(n);8:begin breadthmax:=10000;
depththreshold:=poolsize-poolptr-10;shownodelist(n);end;
9:showtokenlist(n,0,1000);10:slowprint(n);11:checkmem(n>0);
12:searchmem(n);13:begin if eof(input)then goto 10;read(input,l);
printcmdchr(n,l);end;14:for k:=0 to n do print(buffer[k]);
15:begin fontinshortdisplay:=0;shortdisplay(n);end;
16:panicking:=not panicking;[:1339]else print(63)end;end;end;10:end;}
{:1338}{1380:}
PROCEDURE execeditor;

CONST argsize = 100;
  editor = 'vi';
{editor='ed';}
  editorlength = 2;

VAR i,l: integer;
  j: poolpointer;
  s: strnumber;
  sel: integer;
  editorarg,linearg,filearg: array[1..argsize] OF char;
  argv: array[0..3] OF pchar;
BEGIN
  l := editorlength;
  FOR j:=1 TO l DO
    editorarg[j] := editor[j];
  editorarg[l+1] := chr(0);
  sel := selector;
  selector := 21;
  printint(line);
  selector := sel;
  s := makestring;
  linearg[1] := '+';
  j := strstart[s];
  l := (strstart[s+1]-strstart[s])+1;
  FOR i:=2 TO l DO
    BEGIN
      linearg[i] := xchr[strpool[j]];
      j := j+1
    END;
  linearg[l+1] := chr(0);
  j := strstart[inputstack[baseptr].namefield];
  l := (strstart[inputstack[baseptr].namefield+1]-strstart[inputstack[
       baseptr].namefield]);
  IF l+1>argsize THEN
    BEGIN
      writeln(
              'File name longer than 100 bytes! Nice try!');
      halt(100);
    END;
  FOR i:=1 TO l DO
    BEGIN
      filearg[i] := xchr[strpool[j]];
      j := j+1
    END;
  filearg[l+1] := chr(0);
  argv[0] := @editorarg;
  argv[1] := @linearg;
  argv[2] := @filearg;
  argv[3] := NIL;{argv[1]:=@filearg;argv[2]:=nil;}
  fpexecvp(editor,argv);
  writeln('Sorry, executing the editor failed.');
END;{:1380}{:1330}{1332:}
BEGIN
  history := 3;;
  IF readyalready=314159 THEN goto 1;{14:}
  bad := 0;
  IF (halferrorline<30)OR(halferrorline>errorline-15)THEN bad := 1;
  IF maxprintline<60 THEN bad := 2;
  IF dvibufsize MOD 8<>0 THEN bad := 3;
  IF 1100>30000 THEN bad := 4;
  IF 1777>2100 THEN bad := 5;
  IF maxinopen>=128 THEN bad := 6;
  IF 30000<267 THEN bad := 7;
{:14}{111:}
  IF (memmin<>0)OR(memmax<>30000)THEN bad := 10;
  IF (memmin>0)OR(memmax<30000)THEN bad := 10;
  IF (0>0)OR(255<127)THEN bad := 11;
  IF (0>0)OR(65535<32767)THEN bad := 12;
  IF (0<0)OR(255>65535)THEN bad := 13;
  IF (memmin<0)OR(memmax>=65535)OR(-0-memmin>65536)THEN bad := 14;
  IF (0<0)OR(fontmax>255)THEN bad := 15;
  IF fontmax>256 THEN bad := 16;
  IF (savesize>65535)OR(maxstrings>65535)THEN bad := 17;
  IF bufsize>65535 THEN bad := 18;
  IF 255<255 THEN bad := 19;
{:111}{290:}
  IF 6976>65535 THEN bad := 21;
{:290}{522:}
  IF 20>filenamesize THEN bad := 31;
{:522}{1249:}
  IF 2*65535<30000-memmin THEN bad := 41;
{:1249}
  IF bad>0 THEN
    BEGIN
      writeln(output,
              'Ouch---my internal constants have been clobbered!','---case ',bad:1);
      goto 9999;
    END;
  initialize;
  IF TeXVariation>0 THEN
    BEGIN
      IF NOT getstringsstarted THEN goto 9999;
      initprim;
      initstrptr := strptr;
      initpoolptr := poolptr;
      fixdateandtime;
    END;
  readyalready := 314159;
  1:{55:}selector := 17;
  tally := 0;
  termoffset := 0;
  fileoffset := 0;{:55}{61:}
  write(output,'This is TeX-FPC, 4th ed.');
  IF formatident=0 THEN writeln(output,' (no format preloaded)')
  ELSE
    BEGIN
      slowprint(formatident);
      println;
    END;
  flush(output);{:61}{528:}
  jobname := 0;
  nameinprogress := false;
  logopened := false;{:528}{533:}
  outputfilename := 0;
{:533};{1337:}
  BEGIN{331:}
    BEGIN
      inputptr := 0;
      maxinstack := 0;
      inopen := 0;
      openparens := 0;
      maxbufstack := 0;
      paramptr := 0;
      maxparamstack := 0;
      first := bufsize;
      REPEAT
        buffer[first] := 0;
        first := first-1;
      UNTIL first=0;
      scannerstatus := 0;
      warningindex := 0;
      first := 1;
      curinput.statefield := 33;
      curinput.startfield := 1;
      curinput.indexfield := 0;
      line := 0;
      curinput.namefield := 0;
      forceeof := false;
      alignstate := 1000000;
      IF NOT initterminal THEN goto 9999;
      curinput.limitfield := last;
      first := last+1;
    END{:331};
    IF (formatident=0)OR(buffer[curinput.locfield]=38)THEN
      BEGIN
        IF 
           formatident<>0 THEN initialize;
        IF NOT openfmtfile THEN goto 9999;
        IF NOT loadfmtfile THEN
          BEGIN
            wclose(fmtfile);
            goto 9999;
          END;
        wclose(fmtfile);
        WHILE (curinput.locfield<curinput.limitfield)AND(buffer[curinput.locfield
              ]=32) DO
          curinput.locfield := curinput.locfield+1;
      END;
    IF (eqtb[5311].int<0)OR(eqtb[5311].int>255)THEN curinput.limitfield := 
                                                                           curinput.limitfield-1
    ELSE buffer[curinput.limitfield] := eqtb[5311].int;
    fixdateandtime;{765:}
    magicoffset := strstart[893]-9*16{:765};
{75:}
    IF interaction=0 THEN selector := 16
    ELSE selector := 17{:75};
    IF (curinput.locfield<curinput.limitfield)AND(eqtb[3983+buffer[curinput.
       locfield]].hh.rh<>0)THEN startinput;
  END{:1337};
  history := 0;
  maincontrol;
  finalcleanup;
  9998: closefilesandterminate;
  9999: IF wantedit THEN execeditor;
  halt(history);
END.{:1332}
