{4:}{9:}{$C-,A+,D-}{$IFDEF DEBUGGING}{$C+,D+}{$ENDIF}
{:9}
{ $DEFINE STATS}
PROGRAM TEX;

CONST

{constants for selector}

  no_print      = 16; {|selector| setting that makes data disappear}
  term_only     = 17; {printing is destined for the terminal only}
  log_only      = 18; {printing is destined for the transcript file only}
  term_and_log  = 19; {normal |selector| setting}
  {pseudo        = 20; special |selector| setting for |show_context|}
  {new_string    = 21; printing is deflected to the string pool}
  max_selector  = 19; {highest selector setting}


{11:}
  MEMMAX = 30000;
  MEMMIN = 0;
  BUFSIZE = 500;
  ERRORLINE = 72;
  HALFERRORLIN = 42;
  MAXPRINTLINE = 79;
  STACKSIZE = 200;
  MAXINOPEN = 6;
  FONTMAX = 75;
  FONTMEMSIZE = 20000;
  PARAMSIZE = 60;
  NESTSIZE = 40;
  MAXSTRINGS = 3000;
  STRINGVACANC = 8000;
  POOLSIZE = 32000;
  SAVESIZE = 600;
  TRIESIZE = 8000;
  TRIEOPSIZE = 500;
  DVIBUFSIZE = 800;
{:11}


{@ The following parameters can be changed at compile time to extend or
reduce \TeX's capacity. They may have different values in \INITEX\ and
in production versions of \TeX\.}

  mem_max = 30000;
    {greatest index in \TeX's internal |mem| array;
     must be strictly less than |max_halfword|;
     must be equal to |mem_top| in \INITEX\, otherwise |>=mem_top|}
  mem_min = 0; 
    {smallest index in \TeX's internal |mem| array;
     must be |min_halfword| or more;
     must be equal to |mem_bot| in \INITEX\, otherwise |<=mem_bot|}
  buf_size = 500;
    {maximum number of characters simultaneously present in
     current lines of open files and in control sequences between
     \csname and \endcsname; must not exceed |max_halfword|}
  error_line = 72;
    {width of context lines on terminal error messages}
  half_error_line = 42;
    {width of first lines of contexts in terminal
     error messages; should be between 30 and |error_line-15|}
  max_print_line = 79;
    {width of longest text lines output; should be at least 60}
  stack_size = 200;
    {maximum number of simultaneous input sources}
  max_in_open = 6;
    {maximum number of input files and error insertions that
     can be going on simultaneously}
  font_max = 75;
    {maximum internal font number; must not exceed |max_quarterword|
     and must be at most |font_base+256|}
  font_mem_size = 20000;
    {number of words of |font_info| for all fonts}
  param_size = 60;
    {maximum number of simultaneous macro parameters}
  nest_size = 40;
    {maximum number of semantic levels simultaneously active}
  max_strings = 3000;
    {maximum number of strings; must not exceed |max_halfword|}
  string_vacancies = 8000;
    {the minimum number of characters that should be
     available for the user's control sequences and font names,
     after \TeX's own error messages are stored}
  pool_size = 32000;
    {maximum number of characters in strings, including all
     error messages and help texts, and the names of all fonts and
     control sequences; must exceed |string_vacancies| by the total
     length of \TeX's own strings, which is currently about 23000}
  save_size = 600;
    {space for saving values outside of current group; must be
     at most |max_halfword|}
  trie_size = 8000;
    {space for hyphenation patterns; should be larger for
     \INITEX\ than it is in production versions of \TeX\}
  trie_op_size = 500;
    {space for ``opcodes'' in the hyphenation patterns}
  dvi_buf_size = 800;
    {size of the output buffer; must be a multiple of 8}
  file_name_size = 40; {better 255 for shortstring}
    {file names shouldn't be longer than this}



{@ Like the preceding parameters, the following quantities can be changed
at compile time to extend or reduce \TeX's capacity. But if they are changed,
it is necessary to rerun the initialization program \INITEX\
to generate new tables for the production \TeX\ program.
One can't simply make helter-skelter changes to the following constants,
since certain rather complex initialization
numbers are computed from them. They are defined here using
\WEB\ macros, instead of being put into \PASCAL\'s |const| list, in order to
emphasize this distinction.}

  mem_bot = 0;
    {smallest index in the |mem| array dumped by \INITEX\;
     must not be less than |mem_min|}
  mem_top = 30000;
    {largest index in the |mem| array dumped by \INITEX\;
     must be substantially larger than |mem_bot| and not greater than |mem_max|}
  font_base = 0;
    {smallest internal font number; must not be less than |min_quarterword|}
  null_font = font_base;
    {an undefined font is represented by the internal code |font_base|}
  hash_size = 2100;
    {maximum number of control sequences; it should be at most about
     |(mem_max-mem_min)/10|}
  hash_prime = 1777;
    {a prime number equal to about 85\pct! of |hash_size|}
  hyph_size = 307;
    {another prime; the number of .\hyphenation exceptions}



{@ Many locations in |eqtb| have symbolic names. The purpose of the next
paragraphs is to define these names, and to set up the initial values of the
equivalents.

In the first region we have 256 equivalents for ``active characters'' that
act as control sequences, followed by 256 equivalents for single-character
control sequences.

Then comes region~2, which corresponds to the hash table that we will
define later.  The maximum address in this region is used for a dummy
control sequence that is perpetually undefined. There also are several
locations for control sequences that are perpetually defined
(since they are used in error recovery).}

  active_base = 1;
    {beginning of region 1, for active character equivalents}
  single_base = active_base+256;
    {equivalents of one-character control sequences}
  null_cs = single_base+256;
    {equivalent of \csname\endcsname}
  hash_base = null_cs+1;
    {beginning of region 2, for the hash table}
  frozen_control_sequence = hash_base+hash_size;
    {for error recovery}
  fcb = frozen_control_sequence;
  frozen_protection   = fcb;    {inaccessible but definable}
  frozen_cr           = fcb+1;  {permanent \cr}
  frozen_end_group    = fcb+2;  {permanent \endgroup}
  frozen_right        = fcb+3;  {permanent \right}
  frozen_fi           = fcb+4;  {permanent \fi}
  frozen_end_template = fcb+5;  {permanent \endtemplate}
  frozen_endv         = fcb+6;  {second permanent \endtemplate}
  frozen_relax        = fcb+7;  {permanent \relax}
  end_write           = fcb+8;  {permanent \endwrite}
  frozen_dont_expand  = fcb+9;  {permanent \notexpanded}
  frozen_null_font    = fcb+10; {permanent \nullfont}
  font_id_base = frozen_null_font-font_base;
    {begins table of 257 permanent font identifiers}
  undefined_control_sequence = frozen_null_font+257;
    {dummy location}
  glue_base=undefined_control_sequence+1;
    {beginning of region 3}



{Region 3 of |eqtb| contains the 256 \skip registers, as well as the
glue parameters defined here. It is important that the ``muskip''
parameters have larger numbers than the others.}

  line_skip_code = 0;                   {interline glue if |baseline_skip| is infeasible}
  baseline_skip_code=1;                 {desired glue between baselines}
  par_skip_code=2;                      {extra glue just above a paragraph}
  above_display_skip_code = 3;          {extra glue just above displayed math}
  below_display_skip_code = 4;          {extra glue just below displayed math}
  above_display_short_skip_code = 5;    {glue above displayed math following short lines}
  below_display_short_skip_code = 6;    {glue below displayed math following short lines}
  left_skip_code = 7;                   {glue at left of justified lines}
  right_skip_code = 8;                  {glue at right of justified lines}
  top_skip_code = 9;                    {glue at top of main pages}
  split_top_skip_code = 10;             {glue at top of split pages}
  tab_skip_code = 11;                   {glue between aligned entries}
  space_skip_code = 12;                 {glue between words (if not |zero_glue|)}
  xspace_skip_code = 13;                {glue after sentences (if not |zero_glue|)}
  par_fill_skip_code = 14;              {glue on last line of paragraph}
  thin_mu_skip_code = 15;               {thin space in math formula}
  med_mu_skip_code = 16;                {medium space in math formula}
  thick_mu_skip_code = 17;              {thick space in math formula}
  glue_pars = 18;                       {total number of glue parameters}
  skip_base = glue_base+glue_pars;      {table of 256 ``skip'' registers}
  mu_skip_base = skip_base+256;         {table of 256 ``muskip'' registers}
  local_base = mu_skip_base+256;        {beginning of region 4}

{@ Region 4 of |eqtb| contains the local quantities defined here. The
bulk of this region is taken up by five tables that are indexed by eight-bit
characters; these tables are important to both the syntactic and semantic
portions of \TeX. There are also a bunch of special things like font and
token parameters, as well as the tables of \Toks and \box
registers.}

  par_shape_loc      = local_base;      {specifies paragraph shape}
  output_routine_loc = local_base+1;    {points to token list for \Output}
  every_par_loc      = local_base+2;    {points to token list for \everypar}
  every_math_loc     = local_base+3;    {points to token list for \everymath}
  every_display_loc  = local_base+4;    {points to token list for \everydisplay}
  every_hbox_loc     = local_base+5;    {points to token list for \everyhbox}
  every_vbox_loc     = local_base+6;    {points to token list for \everyvbox}
  every_job_loc      = local_base+7;    {points to token list for \everyjob}
  every_cr_loc       = local_base+8;    {points to token list for \everycr}
  err_help_loc       = local_base+9;    {points to token list for \errhelp}
  toks_base          = local_base+10;   {table of 256 token list registers}
  box_base       = toks_base+256;       {table of 256 box registers}
  cur_font_loc   = box_base+256;        {internal font number outside math mode}
  math_font_base = cur_font_loc+1;      {table of 48 math font numbers}
  cat_code_base  = math_font_base+48;   {table of 256 command codes (the ``catcodes'')}
  lc_code_base   = cat_code_base+256;   {table of 256 lowercase mappings}
  uc_code_base   = lc_code_base+256;    {table of 256 uppercase mappings}
  sf_code_base   = uc_code_base+256;    {table of 256 spacefactor mappings}
  math_code_base = sf_code_base+256;    {table of 256 math mode mappings}
  int_base       = math_code_base+256;  {beginning of region 5}

{@ Region 5 of |eqtb| contains the integer parameters and registers defined
here, as well as the |del_code| table. The latter table differs from the
|cat_code..math_code| tables that precede it, since delimiter codes are
fullword integers while the other kinds of codes occupy at most a
halfword. This is what makes region~5 different from region~4. We will
store the |eq_level| information in an auxiliary array of quarterwords
that will be defined later.}

  pretolerance_code             = 0;  {badness tolerance before hyphenation}
  tolerance_code                = 1;  {badness tolerance after hyphenation}
  line_penalty_code             = 2;  {added to the badness of every line}
  hyphen_penalty_code           = 3;  {penalty for break after discretionary hyphen}
  ex_hyphen_penalty_code        = 4;  {penalty for break after explicit hyphen}
  club_penalty_code             = 5;  {penalty for creating a club line}
  widow_penalty_code            = 6;  {penalty for creating a widow line}
  display_widow_penalty_code    = 7;  {ditto, just before a display}
  broken_penalty_code           = 8;  {penalty for breaking a page at a broken line}
  bin_op_penalty_code           = 9;  {penalty for breaking after a binary operation}
  rel_penalty_code              = 10; {penalty for breaking after a relation}
  pre_display_penalty_code      = 11; {penalty for breaking just before a displayed formula}
  post_display_penalty_code     = 12; {penalty for breaking just after a displayed formula}
  inter_line_penalty_code       = 13; {additional penalty between lines}
  double_hyphen_demerits_code   = 14; {demerits for double hyphen break}
  final_hyphen_demerits_code    = 15; {demerits for final hyphen break}
  adj_demerits_code             = 16; {demerits for adjacent incompatible lines}
  mag_code                      = 17; {magnification ratio}
  delimiter_factor_code         = 18; {ratio for variable-size delimiters}
  looseness_code                = 19; {change in number of lines for a paragraph}
  time_code                     = 20; {current time of day}
  day_code                      = 21; {current day of the month}
  month_code                    = 22; {current month of the year}
  year_code                     = 23; {current year of our Lord}
  show_box_breadth_code         = 24; {nodes per level in |show_box|}
  show_box_depth_code           = 25; {maximum level in |show_box|}
  hbadness_code                 = 26; {hboxes exceeding this badness will be shown by |hpack|}
  vbadness_code                 = 27; {vboxes exceeding this badness will be shown by |vpack|}
  pausing_code                  = 28; {pause after each line is read from a file}
  tracing_online_code           = 29; {show diagnostic output on terminal}
  tracing_macros_code           = 30; {show macros as they are being expanded}
  tracing_stats_code            = 31; {show memory usage if \TeX\ knows it}
  tracing_paragraphs_code       = 32; {show line-break calculations}
  tracing_pages_code            = 33; {show page-break calculations}
  tracing_output_code           = 34; {show boxes when they are shipped out}
  tracing_lost_chars_code       = 35; {show characters that aren't in the font}
  tracing_commands_code         = 36; {show command codes at |big_switch|}
  tracing_restores_code         = 37; {show equivalents when they are restored}
  uc_hyph_code                  = 38; {hyphenate words beginning with a capital letter}
  output_penalty_code           = 39; {penalty found at current page break}
  max_dead_cycles_code          = 40; {bound on consecutive dead cycles of output}
  hang_after_code               = 41; {hanging indentation changes after this many lines}
  floating_penalty_code         = 42; {penalty for insertions held over after a split}
  global_defs_code              = 43; {override \global specifications}
  cur_fam_code                  = 44; {current family}
  escape_char_code              = 45; {escape character for token output}
  default_hyphen_char_code      = 46; {value of \hyphenchar when a font is loaded}
  default_skew_char_code        = 47; {value of \skewchar when a font is loaded}
  end_line_char_code            = 48; {character placed at the right end of the buffer}
  new_line_char_code            = 49; {character that prints as |print_ln|}
  language_code                 = 50; {current hyphenation table}
  left_hyphen_min_code          = 51; {minimum left hyphenation fragment size}
  right_hyphen_min_code         = 52; {minimum right hyphenation fragment size}
  holding_inserts_code          = 53; {do not remove insertion nodes from \box255}
  error_context_lines_code      = 54; {maximum intermediate line pairs shown}
  int_pars                      = 55; {total number of integer parameters}

  count_base = int_base+int_pars;       {256 user \count registers}
  del_code_base = count_base+256;       {256 delimiter code mappings}
  dimen_base = del_code_base+256;       {beginning of region 6}

{@ The final region of |eqtb| contains the dimension parameters defined
here, and the 256 \dimen registers.}

  par_indent_code               = 0; {indentation of paragraphs}
  math_surround_code            = 1; {space around math in text}
  line_skip_limit_code          = 2; {threshold for |line_skip| instead of |baseline_skip|}
  hsize_code=3; {line width in horizontal mode}
  vsize_code=4; {page height in vertical mode}
  max_depth_code=5; {maximum depth of boxes on main pages}
  split_max_depth_code=6; {maximum depth of boxes on split pages}
  box_max_depth_code=7; {maximum depth of explicit vboxes}
  hfuzz_code=8; {tolerance for overfull hbox messages}
  vfuzz_code=9; {tolerance for overfull vbox messages}
  delimiter_shortfall_code=10; {maximum amount uncovered by variable delimiters}
  null_delimiter_space_code=11; {blank space in null delimiters}
  script_space_code=12; {extra space after subscript or superscript}
  pre_display_size_code=13; {length of text preceding a display}
  display_width_code=14; {length of line for displayed equation}
  display_indent_code=15; {indentation of line for displayed equation}
  overfull_rule_code=16; {width of rule that identifies overfull hboxes}
  hang_indent_code=17; {amount of hanging indentation}
  h_offset_code=18; {amount of horizontal offset when shipping pages out}
  v_offset_code=19; {amount of vertical offset when shipping pages out}
  emergency_stretch_code=20; {reduces badnesses on final pass of line-breaking}
  dimen_pars=21; {total number of dimension parameters}
  scaled_base=dimen_base+dimen_pars; {table of 256 user-defined \dimen registers}
  eqtb_size=scaled_base+255; {largest subscript of |eqtb|}





  min_quarterword = 0;          {smallest allowable value in a |quarterword|}
  max_quarterword = 255;        {largest allowable value in a |quarterword|}
  min_halfword = 0;             {smallest allowable value in a |halfword|}
  max_halfword = 65535;         {largest allowable value in a |halfword|}

  non_char = 256;               {a |halfword| code that can't match a real character}
  non_address = 0;              {a spurious |bchar_label|}






  lo_mem_stat_max = 19;
  hi_mem_stat_min = 29987;
  batch_mode = 0;
  error_stop_mode = 3;


  fixUnity = $10000; {1.0 in 15.16 fixed point notation}
  fixTwo   = $20000; {2.0 in 15.16 fixed point notation}

  {|tag| field in a |char_info_word|}
  no_tag   = 0; {vanilla character}
  lig_tag  = 1; {character has a ligature/kerning program}
  list_tag = 2; {character has a successor in a charlist}
  ext_tag  = 3; {character is extensible}




{@ [15] The command codes.
Before we can go any further, we need to define symbolic names for the internal
code numbers that represent the various commands obeyed by \TeX. These codes
are somewhat arbitrary, but not completely so. For example, the command
codes for character types are fixed by the language, since a user says,
e.g., `\catcode  = 3' to make \char'44 a math delimiter,
and the command code |math_shift| is equal to~3. Some other codes have
been made adjacent so that |case| statements in the program need not consider
cases that are widely spaced, or so that |case| statements can be replaced
by |if| statements.

At any rate, here is the list, for future reference. First come the
``catcode'' commands, several of which share their numeric codes with
ordinary commands when the catcode cannot emerge from \TeX's scanning routine.}

  escape=0; {escape delimiter (called \.\\ in The \TeX book\)}
  relax=0; {do nothing ( \relax )}
  left_brace=1; {beginning of a group}
  right_brace=2; {ending of a group}
  math_shift=3; {mathematics shift character ( '$' )}
  tab_mark=4; {alignment delimiter ( \&, \span )}
  car_ret=5; {end of line ( |carriage_return|, \cr, \crcr )}
  out_param=5; {output a macro parameter}
  mac_param=6; {macro parameter symbol ( '#' )}
  sup_mark=7; {superscript ( '^' )}
  sub_mark=8; {subscript ( '_' )}
  ignore=9; {characters to ignore ( \.\^\^@@ )}
  endv=9; {end of \<v_j> list in alignment template}
  spacer=10; {characters equivalent to blank space ( \.\  )}
  letter=11; {characters regarded as letters ( \.A..Z, \.a..z )}
  other_char=12; {none of the special character types}
  active_char=13; {characters that invoke macros ( )}
  par_end=13; {end of paragraph ( \par )}
  match=13; {match a macro parameter}
  comment=14; {characters that introduce comments ( '%' )}
  end_match=14; {end of parameters to macro}
  stop=14; {end of job ( \end, \dump )}
  invalid_char=15; {characters that shouldn't appear ( ^^? )}
  delim_num=15; {specify delimiter numerically ( \delimiter )}
  max_char_code=15; {largest catcode for individual characters}

{@ Next are the ordinary run-of-the-mill command codes.  Codes that are
|min_internal| or more represent internal quantities that might be
expanded by \the.}

  char_num=16; {character specified numerically ( \char )}
  math_char_num=17; {explicit math code ( \mathchar )}
  mark=18; {mark definition ( \mark )}
  xray=19; {peek inside of \TeX\ ( \show, \showbox, etc.~)}
  make_box=20; {make a box ( \box, \copy, \hbox, etc.~)}
  hmove=21; {horizontal motion ( \moveleft, \moveright )}
  vmove=22; {vertical motion ( \raise, \lower )}
  un_hbox=23; {unglue a box ( \unhbox, \unhcopy )}
  un_vbox=24; {unglue a box ( \unvbox, \unvcopy )}
  remove_item=25; {nullify last item ( \unpenalty, \unkern, \unskip )}
  hskip=26; {horizontal glue ( \hskip, \hfil, etc.~)}
  vskip=27; {vertical glue ( \vskip, \vfil, etc.~)}
  mskip=28; {math glue ( \mskip )}
  kern=29; {fixed space ( \kern )}
  mkern=30; {math kern ( \mkern )}
  leader_ship=31; {use a box ( \shipout, \leaders, etc.~)}
  halign=32; {horizontal table alignment ( \halign )}
  valign=33; {vertical table alignment ( \valign )}
  no_align=34; {temporary escape from alignment ( \noalign )}
  vrule=35; {vertical rule ( \vrule )}
  hrule=36; {horizontal rule ( \hrule )}
  insert=37; {vlist inserted in box ( \insert )}
  vadjust=38; {vlist inserted in enclosing paragraph ( \vadjust )}
  ignore_spaces=39; {gobble |spacer| tokens ( \ignorespaces )}
  after_assignment=40; {save till assignment is done ( \afterassignment )}
  after_group=41; {save till group is done ( \aftergroup )}
  break_penalty=42; {additional badness ( \penalty )}
  start_par=43; {begin paragraph ( \indent, \noindent )}
  ital_corr=44; {italic correction ( \/ )}
  accent=45; {attach accent in text ( \accent )}
  math_accent=46; {attach accent in math ( \mathaccent )}
  discretionary=47; {discretionary texts ( \-, \discretionary )}
  eq_no=48; {equation number ( \eqno, \leqno )}
  left_right=49; {variable delimiter ( \left, \right )}
  math_comp=50; {component of formula ( \mathbin, etc.~)}
  limit_switch=51; {diddle limit conventions ( \displaylimits, etc. )}
  above=52; {generalized fraction ( \above, \atop, etc.~)}
  math_style=53; {style specification ( \displaystyle, etc.~)}
  math_choice=54; {choice specification ( \mathchoice )}
  non_script=55; {conditional math glue ( \nonscript )}
  vcenter=56; {vertically center a vbox ( \vcenter )}
  case_shift=57; {force specific case ( \lowercase, \uppercase )}
  message=58; {send to user ( \message, \errmessage )}
  extension=59; {extensions to \TeX\ ( \write, \special, etc.~)}
  in_stream=60; {files for reading ( \openin, \closein )}
  begin_group=61; {begin local grouping ( \begingroup )}
  end_group=62; {end local grouping ( \endgroup )}
  omit=63; {omit alignment template ( \omit )}
  ex_space=64; {explicit space ( \\  )}
  no_boundary=65; {suppress boundary ligatures ( \noboundary )}
  radical=66; {square root and similar signs ( \radical )}
  end_cs_name=67; {end control sequence ( \endcsname )}
  min_internal=68; {the smallest code that can follow \the}
  char_given=68; {character code defined by \chardef}
  math_given=69; {math code defined by \mathchardef}
  last_item=70; {most recent item ( \lastpenalty, \lastkern, \lastskip )}
  max_non_prefixed_command=70; {largest command code that can't be \global}

{@ The next codes are special; they all relate to mode-independent
assignment of values to \TeX's internal registers or tables.
Codes that are |max_internal| or less represent internal quantities
that might be expanded by \the.}

  toks_register=71; {token list register ( \toks )}
  assign_toks=72; {special token list ( \output, \everypar, etc.~)}
  assign_int=73; {user-defined integer ( \tolerance, \day, etc.~)}
  assign_dimen=74; {user-defined length ( \hsize, etc.~)}
  assign_glue=75; {user-defined glue ( \baselineskip, etc.~)}
  assign_mu_glue=76; {user-defined muglue ( \thinmuskip, etc.~)}
  assign_font_dimen=77; {user-defined font dimension ( \fontdimen )}
  assign_font_int=78; {user-defined font integer ( \hyphenchar,
  \skewchar )}
  set_aux=79; {specify state info ( \spacefactor, \prevdepth )}
  set_prev_graf=80; {specify state info ( \prevgraf )}
  set_page_dimen=81; {specify state info ( \pagegoal, etc.~)}
  set_page_int=82; {specify state info ( \deadcycles,
  \insertpenalties )}
  set_box_dimen=83; {change dimension of box ( \wd, \ht, \dp )}
  set_shape=84; {specify fancy paragraph shape ( \parshape )}
  def_code=85; {define a character code ( \catcode, etc.~)}
  def_family=86; {declare math fonts ( \textfont, etc.~)}
  set_font=87; {set current font ( font identifiers )}
  def_font=88; {define a font file ( \font )}
  register=89; {internal register ( \count, \dimen, etc.~)}
  max_internal=89; {the largest code that can follow \the}
  advance=90; {advance a register or parameter ( \advance )}
  multiply=91; {multiply a register or parameter ( \multiply )}
  divide=92; {divide a register or parameter ( \divide )}
  prefix=93; {qualify a definition ( \global, \long, \outer )}
  let=94; {assign a command code ( \let, \futurelet )}
  shorthand_def=95; {code definition ( \chardef, \countdef, etc.~)}
  read_to_cs=96; {read into a control sequence ( \read )}
  def=97; {macro definition ( \def, \gdef, \xdef, \edef )}
  set_box=98; {set a box ( \setbox )}
  hyph_data=99; {hyphenation data ( \hyphenation, \patterns )}
  set_interaction=100; {define level of interaction ( \batchmode, etc.~)}
  max_command=100; {the largest command code seen at |big_switch|}

{@ The remaining command codes are extra special, since they cannot get through
\TeX's scanner to the main control routine. They have been given values higher
than |max_command| so that their special nature is easily discernible.
The ``expandable'' commands come first.}

  undefined_cs=max_command+1; {initial state of most |eq_type| fields}
  expand_after=max_command+2; {special expansion ( \expandafter )}
  no_expand=max_command+3; {special nonexpansion ( \noexpand )}
  {input=max_command+4;} {input a source file ( \input, \endinput )}
  if_test=max_command+5; {conditional text ( \if, \ifcase, etc.~)}
  fi_or_else=max_command+6; {delimiters for conditionals ( \else, etc.~)}
  cs_name=max_command+7; {make a control sequence from tokens ( \csname )}
  convert=max_command+8; {convert to text ( \number, \string, etc.~)}
  the=max_command+9; {expand an internal quantity ( \the )}  
  top_bot_mark=max_command+10; {inserted mark ( \topmark, etc.~)}
  call=max_command+11; {non-long, non-outer control sequence}
  long_call=max_command+12; {long, non-outer control sequence}
  outer_call=max_command+13; {non-long, outer control sequence}
  long_outer_call=max_command+14; {long, outer control sequence}
  end_template=max_command+15; {end of an alignment template}
  dont_expand=max_command+16; {the following token was marked by \noexpand}
  glue_ref=max_command+17; {the equivalent points to a glue specification}
  shape_ref=max_command+18; {the equivalent points to a parshape specification}
  box_ref=max_command+19; {the equivalent points to a box node, or is |null|}
  data=max_command+20; {the equivalent is simply a halfword number}





{@ The codes for |output_text|, |every_par_text|, etc., are equal to a constant
plus the corresponding codes for token list parameters |output_routine_loc|,
|every_par_loc|, etc.  The token list begins with a reference count if and
only if |token_type>=macro|.}

  token_list=0; {|state| code when scanning a token list}
{  token_type==index;} {type of current token list}
{  param_start==limit;} {base of macro parameters in |param_stack|}
  parameter=0; {|token_type| code for parameter}
  u_template=1; {|token_type| code for \<u_j> template}
  v_template=2; {|token_type| code for \<v_j> template}
  backed_up=3; {|token_type| code for text to be reread}
  inserted=4; {|token_type| code for inserted texts}
  macro=5; {|token_type| code for defined control sequences}
  output_text=6; {|token_type| code for output routines}
  every_par_text=7; {|token_type| code for \everypar}
  every_math_text=8; {|token_type| code for \everymath}
  every_display_text=9; {|token_type| code for \everydisplay}
  every_hbox_text=10; {|token_type| code for \everyhbox}
  every_vbox_text=11; {|token_type| code for \everyvbox}
  every_job_text=12; {|token_type| code for \everyjob}
  every_cr_text=13; {|token_type| code for \everycr}
  mark_text=14; {|token_type| code for \topmark, etc.}
  write_text=15; {|token_type| code for \write}



{@ \[20] Token lists.
A \TeX\ token is either a character or a control sequence, and it is
represented internally in one of two ways: (1)~A character whose ASCII
code number is |c| and whose command code is |m| is represented as the
number $2^8m+c$; the command code is in the range |1<=m<=14|. (2)~A control
sequence whose |eqtb| address is |p| is represented as the number
|cs_token_flag+p|. Here |cs_token_flag=$2^12-1$| is larger than
$2^8m+c$, yet it is small enough that |cs_token_flag+p< max_halfword|;
thus, a token fits comfortably in a halfword.

A token |t| represents a |left_brace| command if and only if
|t<left_brace_limit|; it represents a |right_brace| command if and only if
we have |left_brace_limit<=t<right_brace_limit|; and it represents a |match| or
|end_match| command if and only if |match_token<=t<=end_match_token|.
The following definitions take care of these token-oriented constants
and a few others.}

  cs_token_flag         = $FFF; {amount added to the |eqtb| location in a token
                                 that stands for a control sequence; is a
                                 multiple of 256, less 1}
  left_brace_token      = $100; { $2^8\cdot|left_brace|$}
  left_brace_limit      = $200; { $2^8\cdot(|left_brace|+1)$}
  right_brace_token     = $200; { $2^8\cdot|right_brace|$}
  right_brace_limit     = $300; { $2^8\cdot(|right_brace|+1)$}
  math_shift_token      = $300; { $2^8\cdot|math_shift|$}
  tab_token             = $400; { $2^8\cdot|tab_mark|$}
  out_param_token       = $500; { $2^8\cdot|out_param|$}
  space_token           = $A20; { $2^8\cdot|spacer|+|" "|$}
  letter_token          = $B00; { $2^8\cdot|letter|$}
  other_token           = $C00; { $2^8\cdot|other_char|$}
  match_token           = $D00; { $2^8\cdot|match|$}
  end_match_token       = $E00; { $2^8\cdot|end_match|$}
























TYPE {18:}ASCIICODE = 0..255;{:18}{25:}
  EIGHTBITS = 0..255;

  alpha_file = text;
  byte_file = file of byte;
{:25}{38:}
  POOLPOINTER = 0..POOLSIZE;
  STRNUMBER = 0..MAXSTRINGS;
  PACKEDASCIIC = 0..255;{:38}{101:}
  SCALED = Int32;
  NONNEGATIVEI = 0..2147483647;
  SMALLNUMBER = 0..63;{:101}{109:}
  GLUERATIO = SINGLE;
{:109}{113:}
  QUARTERWORD = 0..255;
  HALFWORD = 0..65535;
  TWOCHOICES = 1..2;
  FOURCHOICES = 1..4;
  TWOHALVES = PACKED RECORD
    RH: HALFWORD;
    CASE TWOCHOICES OF 
      1: (LH:HALFWORD);
      2: (B0:QUARTERWORD;B1:QUARTERWORD);
  END;
  FOURQUARTERS = PACKED RECORD
    B0: QUARTERWORD;
    B1: QUARTERWORD;
    B2: QUARTERWORD;
    B3: QUARTERWORD;
  END;
  MEMORYWORD = RECORD
    CASE FOURCHOICES OF 
      1: (INT:Int32);
      2: (GR:GLUERATIO);
      3: (HH:TWOHALVES);
      4: (QQQQ:FOURQUARTERS);
  END;
{:113}{150:}
  GLUEORD = 0..3;
{:150}{212:}
  LISTSTATEREC = RECORD
    MODEFIELD: -203..203;
    HEADFIELD,TAILFIELD: HALFWORD;
    PGFIELD,MLFIELD: Int32;
    AUXFIELD: MEMORYWORD;
  END;{:212}{269:}
  GROUPCODE = 0..16;
{:269}{300:}
  INSTATERECOR = RECORD
    STATEFIELD,INDEXFIELD: QUARTERWORD;
    STARTFIELD,LOCFIELD,LIMITFIELD,NAMEFIELD: HALFWORD;
  END;
{:300}
  INTERNALFONT = 0..FONTMAX;
  FONTINDEX = 0..FONTMEMSIZE;
  DVIINDEX = 0..dvi_buf_size;
  TRIEPOINTER = 0..TRIESIZE;
  HYPHPOINTER = 0..307;


VAR
{20:}
  XORD: ARRAY[CHAR] OF ASCIICODE;
  XCHR: ARRAY[ASCIICODE] OF CHAR;
{:20}
{30:}
  BUFFER: ARRAY[0..BUFSIZE] OF ASCIICODE;
  FIRST: 0..BUFSIZE;
  LAST: 0..BUFSIZE;
  MAXBUFSTACK: 0..BUFSIZE;
{:30}{39:}
  STRPOOL: PACKED ARRAY[POOLPOINTER] OF PACKEDASCIIC;
  STRSTART: ARRAY[STRNUMBER] OF POOLPOINTER;
  POOLPTR: POOLPOINTER;
  STRPTR: STRNUMBER;
  INITPOOLPTR: POOLPOINTER;
  INITSTRPTR: STRNUMBER;
{:39}
{54:}
  LOGFILE: alpha_file;
  SELECTOR: 16..19;
  DIG: ARRAY[0..22] OF 0..15;
  TALLY: Int32;
  TERMOFFSET: 0..MAXPRINTLINE;
  FILEOFFSET: 0..MAXPRINTLINE;
  TRICKBUF: ARRAY[0..ERRORLINE] OF ASCIICODE;
  TRICKCOUNT: Int32;
  FIRSTCOUNT: Int32;{:54}{73:}
  INTERACTION: 0..3;
{:73}{76:}
  DELETIONSALL: BOOLEAN;
  SETBOXALLOWE: BOOLEAN;
  HISTORY: 0..3;
  ERRORCOUNT: -1..100;{:76}{79:}
  help_line: array[0..5] of shortstring;
  HELPPTR: 0..6;
  USEERRHELP: BOOLEAN;{:79}{96:}
  INTERRUPT: Int32;
  OKTOINTERRUP: BOOLEAN;{:96}{104:}
  ARITHERROR: BOOLEAN;
  REMAINDER: SCALED;
{:104}{115:}
  TEMPPTR: HALFWORD;
{:115}{116:}
  MEM: ARRAY[MEMMIN..MEMMAX] OF MEMORYWORD;
  LOMEMMAX: HALFWORD;
  HIMEMMIN: HALFWORD;{:116}{117:}
  VARUSED,DYNUSED: Int32;
{:117}{118:}
  AVAIL: HALFWORD;
  MEMEND: HALFWORD;{:118}{124:}
  ROVER: HALFWORD;
{:124}

{173:}
  FONTINSHORTD: Int32;{:173}{181:}
  DEPTHTHRESHO: Int32;
  BREADTHMAX: Int32;{:181}{213:}
  NEST: ARRAY[0..NESTSIZE] OF LISTSTATEREC;
  NESTPTR: 0..NESTSIZE;
  MAXNESTSTACK: 0..NESTSIZE;
  CURLIST: LISTSTATEREC;
  SHOWNMODE: -203..203;{:213}{246:}
  OLDSETTING: 0..21;
  sys_time, sys_day, sys_month, sys_year: int32;
{:246}{253:}
  EQTB: ARRAY[1..6106] OF MEMORYWORD;
  XEQLEVEL: ARRAY[5263..6106] OF QUARTERWORD;
{:253}{256:}
  HASH: ARRAY[514..2880] OF TWOHALVES;
  HASHUSED: HALFWORD;
  CSCOUNT: Int32;
{:256}{271:}
  SAVESTACK: ARRAY[0..SAVESIZE] OF MEMORYWORD;
  SAVEPTR: 0..SAVESIZE;
  MAXSAVESTACK: 0..SAVESIZE;
  CURLEVEL: QUARTERWORD;
  CURGROUP: GROUPCODE;
  CURBOUNDARY: 0..SAVESIZE;{:271}{286:}
  MAGSET: Int32;
{:286}{297:}
  CURCMD: EIGHTBITS;
  CURCHR: HALFWORD;
  CURCS: HALFWORD;
  CURTOK: HALFWORD;
{:297}{301:}
  INPUTSTACK: ARRAY[0..STACKSIZE] OF INSTATERECOR;
  INPUTPTR: 0..STACKSIZE;
  MAXINSTACK: 0..STACKSIZE;
  CURINPUT: INSTATERECOR;
{:301}{304:}
  INOPEN: 0..MAXINOPEN;
  OPENPARENS: 0..MAXINOPEN;
  INPUTFILE: ARRAY[1..MAXINOPEN] OF alpha_file;
  LINE: Int32;
  LINESTACK: ARRAY[1..MAXINOPEN] OF Int32;{:304}{305:}
  SCANNERSTATU: 0..5;
  WARNINGINDEX: HALFWORD;
  DEFREF: HALFWORD;
{:305}{308:}
  PARAMSTACK: ARRAY[0..PARAMSIZE] OF HALFWORD;
  PARAMPTR: 0..PARAMSIZE;
  MAXPARAMSTAC: Int32;
{:308}{309:}
  ALIGNSTATE: Int32;{:309}{310:}
  BASEPTR: 0..STACKSIZE;
{:310}{333:}
  PARLOC: HALFWORD;
  PARTOKEN: HALFWORD;
{:333}{361:}
  FORCEEOF: BOOLEAN;{:361}{382:}
  CURMARK: ARRAY[0..4] OF HALFWORD;
{:382}{387:}
  LONGSTATE: 111..114;
{:387}{388:}
  PSTACK: ARRAY[0..8] OF HALFWORD;{:388}{410:}
  CURVAL: Int32;
  CURVALLEVEL: 0..5;{:410}{438:}
  RADIX: SMALLNUMBER;
{:438}{447:}
  CURORDER: GLUEORD;
{:447}{480:}
  READFILE: ARRAY[0..15] OF alpha_file;
  READOPEN: ARRAY[0..16] OF 0..2;{:480}{489:}
  CONDPTR: HALFWORD;
  IFLIMIT: 0..4;
  CURIF: SMALLNUMBER;
  IFLINE: Int32;{:489}{493:}
  SKIPLINE: Int32;
{:493}
{527:}
  NAMEINPROGRE: BOOLEAN;
  job_name: shortstring;
  LOGOPENED: BOOLEAN;{:527}{532:}
  DVIFILE: byte_file;
  output_file_name: shortstring;
  LOGNAME: STRNUMBER;{:532}{539:}
{:539}{549:}
  FONTINFO: ARRAY[FONTINDEX] OF MEMORYWORD;
  FMEMPTR: FONTINDEX;
  FONTPTR: INTERNALFONT;
  FONTCHECK: ARRAY[INTERNALFONT] OF FOURQUARTERS;
  FONTSIZE: ARRAY[INTERNALFONT] OF SCALED;
  FONTDSIZE: ARRAY[INTERNALFONT] OF SCALED;
  FONTPARAMS: ARRAY[INTERNALFONT] OF FONTINDEX;
  FONTNAME: ARRAY[INTERNALFONT] OF STRNUMBER;
  FONTAREA: ARRAY[INTERNALFONT] OF STRNUMBER;
  FONTBC: ARRAY[INTERNALFONT] OF EIGHTBITS;
  FONTEC: ARRAY[INTERNALFONT] OF EIGHTBITS;
  FONTGLUE: ARRAY[INTERNALFONT] OF HALFWORD;
  FONTUSED: ARRAY[INTERNALFONT] OF BOOLEAN;
  HYPHENCHAR: ARRAY[INTERNALFONT] OF Int32;
  SKEWCHAR: ARRAY[INTERNALFONT] OF Int32;
  BCHARLABEL: ARRAY[INTERNALFONT] OF FONTINDEX;
  FONTBCHAR: ARRAY[INTERNALFONT] OF 0..256;
  FONTFALSEBCH: ARRAY[INTERNALFONT] OF 0..256;
{:549}{550:}
  CHARBASE: ARRAY[INTERNALFONT] OF Int32;
  WIDTHBASE: ARRAY[INTERNALFONT] OF Int32;
  HEIGHTBASE: ARRAY[INTERNALFONT] OF Int32;
  DEPTHBASE: ARRAY[INTERNALFONT] OF Int32;
  ITALICBASE: ARRAY[INTERNALFONT] OF Int32;
  LIGKERNBASE: ARRAY[INTERNALFONT] OF Int32;
  KERNBASE: ARRAY[INTERNALFONT] OF Int32;
  EXTENBASE: ARRAY[INTERNALFONT] OF Int32;
  PARAMBASE: ARRAY[INTERNALFONT] OF Int32;
{:550}{555:}
  NULLCHARACTE: FOURQUARTERS;{:555}{592:}
  TOTALPAGES: Int32;
  MAXV: SCALED;
  MAXH: SCALED;
  MAXPUSH: Int32;
  LASTBOP: Int32;
  DEADCYCLES: Int32;
  DOINGLEADERS: BOOLEAN;
  C,F: QUARTERWORD;
  RULEHT,RULEDP,RULEWD: SCALED;
  G: HALFWORD;
  LQ,LR: Int32;
{:592}{595:}
  DVIBUF: ARRAY[DVIINDEX] OF EIGHTBITS;
  HALFBUF: DVIINDEX;
  DVILIMIT: DVIINDEX;
  DVIPTR: DVIINDEX;
  DVIOFFSET: Int32;
  DVIGONE: Int32;
{:595}{605:}
  DOWNPTR,RIGHTPTR: HALFWORD;{:605}{616:}
  DVIH,DVIV: SCALED;
  CURH,CURV: SCALED;
  DVIF: INTERNALFONT;
  CURS: Int32;
{:616}{646:}
  TOTALSTRETCH,TOTALSHRINK: ARRAY[GLUEORD] OF SCALED;
  LASTBADNESS: Int32;{:646}{647:}
  ADJUSTTAIL: HALFWORD;
{:647}{661:}
  PACKBEGINLIN: Int32;{:661}{684:}
  EMPTYFIELD: TWOHALVES;
  NULLDELIMITE: FOURQUARTERS;{:684}{719:}
  CURMLIST: HALFWORD;
  CURSTYLE: SMALLNUMBER;
  CURSIZE: SMALLNUMBER;
  CURMU: SCALED;
  MLISTPENALTI: BOOLEAN;{:719}{724:}
  CURF: INTERNALFONT;
  CURC: QUARTERWORD;
  CURI: FOURQUARTERS;{:724}{764:}
  MAGICOFFSET: Int32;
{:764}{770:}
  CURALIGN: HALFWORD;
  CURSPAN: HALFWORD;
  CURLOOP: HALFWORD;
  ALIGNPTR: HALFWORD;
  CURHEAD,CURTAIL: HALFWORD;{:770}{814:}
  JUSTBOX: HALFWORD;
{:814}{821:}
  PASSIVE: HALFWORD;
  PRINTEDNODE: HALFWORD;
  PASSNUMBER: HALFWORD;
{:821}{823:}
  ACTIVEWIDTH: ARRAY[1..6] OF SCALED;
  CURACTIVEWID: ARRAY[1..6] OF SCALED;
  BACKGROUND: ARRAY[1..6] OF SCALED;
  BREAKWIDTH: ARRAY[1..6] OF SCALED;{:823}{825:}
  NOSHRINKERRO: BOOLEAN;
{:825}{828:}
  CURP: HALFWORD;
  SECONDPASS: BOOLEAN;
  FINALPASS: BOOLEAN;
  THRESHOLD: Int32;{:828}{833:}
  MINIMALDEMER: ARRAY[0..3] OF Int32;
  MINIMUMDEMER: Int32;
  BESTPLACE: ARRAY[0..3] OF HALFWORD;
  BESTPLLINE: ARRAY[0..3] OF HALFWORD;{:833}{839:}
  DISCWIDTH: SCALED;
{:839}{847:}
  EASYLINE: HALFWORD;
  LASTSPECIALL: HALFWORD;
  FIRSTWIDTH: SCALED;
  SECONDWIDTH: SCALED;
  FIRSTINDENT: SCALED;
  SECONDINDENT: SCALED;
{:847}{872:}
  BESTBET: HALFWORD;
  FEWESTDEMERI: Int32;
  BESTLINE: HALFWORD;
  ACTUALLOOSEN: Int32;
  LINEDIFF: Int32;
{:872}{892:}
  HC: ARRAY[0..65] OF 0..256;
  HN: 0..64;
  HA,HB: HALFWORD;
  HF: INTERNALFONT;
  HU: ARRAY[0..63] OF 0..256;
  HYFCHAR: Int32;
  CURLANG,INITCURLANG: ASCIICODE;
  LHYF,RHYF,INITLHYF,INITRHYF: Int32;
  HYFBCHAR: HALFWORD;{:892}{900:}
  HYF: ARRAY[0..64] OF 0..9;
  INITLIST: HALFWORD;
  INITLIG: BOOLEAN;
  INITLFT: BOOLEAN;{:900}{905:}
  HYPHENPASSED: SMALLNUMBER;
{:905}{907:}
  CURL,CURR: HALFWORD;
  CURQ: HALFWORD;
  LIGSTACK: HALFWORD;
  LIGATUREPRES: BOOLEAN;
  LFTHIT,RTHIT: BOOLEAN;
{:907}{921:}
  TRIE: ARRAY[TRIEPOINTER] OF TWOHALVES;
  HYFDISTANCE: ARRAY[1..TRIEOPSIZE] OF SMALLNUMBER;
  HYFNUM: ARRAY[1..TRIEOPSIZE] OF SMALLNUMBER;
  HYFNEXT: ARRAY[1..TRIEOPSIZE] OF QUARTERWORD;
  OPSTART: ARRAY[ASCIICODE] OF 0..TRIEOPSIZE;
{:921}{926:}
  HYPHWORD: ARRAY[HYPHPOINTER] OF STRNUMBER;
  HYPHLIST: ARRAY[HYPHPOINTER] OF HALFWORD;
  HYPHCOUNT: HYPHPOINTER;
{:926}

{$IFDEF INITEX}
  TRIEOPHASH: ARRAY[-TRIEOPSIZE..TRIEOPSIZE] OF 0..TRIEOPSIZE;
  TRIEUSED: ARRAY[ASCIICODE] OF QUARTERWORD;
  TRIEOPLANG: ARRAY[1..TRIEOPSIZE] OF ASCIICODE;
  TRIEOPVAL: ARRAY[1..TRIEOPSIZE] OF QUARTERWORD;
  TRIEOPPTR: 0..TRIEOPSIZE;
  TRIEC: PACKED ARRAY[TRIEPOINTER] OF PACKEDASCIIC;
  TRIEO: PACKED ARRAY[TRIEPOINTER] OF QUARTERWORD;
  TRIEL: PACKED ARRAY[TRIEPOINTER] OF TRIEPOINTER;
  TRIER: PACKED ARRAY[TRIEPOINTER] OF TRIEPOINTER;
  TRIEPTR: TRIEPOINTER;
  TRIEHASH: PACKED ARRAY[TRIEPOINTER] OF TRIEPOINTER;
  TRIETAKEN: PACKED ARRAY[1..TRIESIZE] OF BOOLEAN;
  TRIEMIN: ARRAY[ASCIICODE] OF TRIEPOINTER;
  TRIEMAX: TRIEPOINTER;
  TRIENOTREADY: BOOLEAN;
{$ENDIF}

{971:}
  BESTHEIGHTPL: SCALED;
{:971}{980:}
  PAGETAIL: HALFWORD;
  PAGECONTENTS: 0..2;
  PAGEMAXDEPTH: SCALED;
  BESTPAGEBREA: HALFWORD;
  LEASTPAGECOS: Int32;
  BESTSIZE: SCALED;
{:980}{982:}
  PAGESOFAR: ARRAY[0..7] OF SCALED;
  LASTGLUE: HALFWORD;
  LASTPENALTY: Int32;
  LASTKERN: SCALED;
  INSERTPENALT: Int32;
{:982}{989:}
  OUTPUTACTIVE: BOOLEAN;{:989}{1032:}
  MAINF: INTERNALFONT;
  MAINI: FOURQUARTERS;
  MAINJ: FOURQUARTERS;
  MAINK: FONTINDEX;
  MAINP: HALFWORD;
  MAINS: Int32;
  BCHAR: HALFWORD;
  FALSEBCHAR: HALFWORD;
  CANCELBOUNDA: BOOLEAN;
  INSDISC: BOOLEAN;{:1032}{1074:}
  CURBOX: HALFWORD;
{:1074}{1266:}
  AFTERTOKEN: HALFWORD;{:1266}{1281:}
  LONGHELPSEEN: BOOLEAN;
{:1281}{1299:}
  FORMATIDENT: STRNUMBER;{:1299}{1305:}
{:1305}{1331:}
{:1331}{1342:}
  WRITEFILE: ARRAY[0..15] OF alpha_file;
  WRITEOPEN: ARRAY[0..17] OF BOOLEAN;{:1342}{1345:}
  WRITELOC: HALFWORD;
{:1345}






{Free Pascal uses "round half to even" (bankers' rounding) in round(),
 but ISO Pascal requires "round half away from zero" (commercial rounding)}
function ISORound(x: Double) : Int32;
begin
  if x >= 0.0 then ISORound := trunc(x+0.5)
              else ISORound := trunc(x-0.5);
end;

function IntToStr02(x: Int32) : shortstring;
var s: string[2];
begin
  s := '00';
  s[1] := chr((x div 10) + 48);
  s[2] := chr((x mod 10) + 48);
  IntToStr02 := s;
end;

function print_int(x: Int32) : shortstring;
var s: shortstring;
begin
  str(x, s);
  print_int := s;
end;


procedure InitGeneral;
VAR
  I: Int32;
  K: Int32;
  Z: HYPHPOINTER;
BEGIN{21:}
  XCHR[32] := ' ';
  XCHR[33] := '!';
  XCHR[34] := '"';
  XCHR[35] := '#';
  XCHR[36] := '$';
  XCHR[37] := '%';
  XCHR[38] := '&';
  XCHR[39] := '''';
  XCHR[40] := '(';
  XCHR[41] := ')';
  XCHR[42] := '*';
  XCHR[43] := '+';
  XCHR[44] := ',';
  XCHR[45] := '-';
  XCHR[46] := '.';
  XCHR[47] := '/';
  XCHR[48] := '0';
  XCHR[49] := '1';
  XCHR[50] := '2';
  XCHR[51] := '3';
  XCHR[52] := '4';
  XCHR[53] := '5';
  XCHR[54] := '6';
  XCHR[55] := '7';
  XCHR[56] := '8';
  XCHR[57] := '9';
  XCHR[58] := ':';
  XCHR[59] := ';';
  XCHR[60] := '<';
  XCHR[61] := '=';
  XCHR[62] := '>';
  XCHR[63] := '?';
  XCHR[64] := '@';
  XCHR[65] := 'A';
  XCHR[66] := 'B';
  XCHR[67] := 'C';
  XCHR[68] := 'D';
  XCHR[69] := 'E';
  XCHR[70] := 'F';
  XCHR[71] := 'G';
  XCHR[72] := 'H';
  XCHR[73] := 'I';
  XCHR[74] := 'J';
  XCHR[75] := 'K';
  XCHR[76] := 'L';
  XCHR[77] := 'M';
  XCHR[78] := 'N';
  XCHR[79] := 'O';
  XCHR[80] := 'P';
  XCHR[81] := 'Q';
  XCHR[82] := 'R';
  XCHR[83] := 'S';
  XCHR[84] := 'T';
  XCHR[85] := 'U';
  XCHR[86] := 'V';
  XCHR[87] := 'W';
  XCHR[88] := 'X';
  XCHR[89] := 'Y';
  XCHR[90] := 'Z';
  XCHR[91] := '[';
  XCHR[92] := '\';
  XCHR[93] := ']';
  XCHR[94] := '^';
  XCHR[95] := '_';
  XCHR[96] := '`';
  XCHR[97] := 'a';
  XCHR[98] := 'b';
  XCHR[99] := 'c';
  XCHR[100] := 'd';
  XCHR[101] := 'e';
  XCHR[102] := 'f';
  XCHR[103] := 'g';
  XCHR[104] := 'h';
  XCHR[105] := 'i';
  XCHR[106] := 'j';
  XCHR[107] := 'k';
  XCHR[108] := 'l';
  XCHR[109] := 'm';
  XCHR[110] := 'n';
  XCHR[111] := 'o';
  XCHR[112] := 'p';
  XCHR[113] := 'q';
  XCHR[114] := 'r';
  XCHR[115] := 's';
  XCHR[116] := 't';
  XCHR[117] := 'u';
  XCHR[118] := 'v';
  XCHR[119] := 'w';
  XCHR[120] := 'x';
  XCHR[121] := 'y';
  XCHR[122] := 'z';
  XCHR[123] := '{';
  XCHR[124] := '|';
  XCHR[125] := '}';
  XCHR[126] := '~';{:21}{23:}
  FOR I:=0 TO 31 DO
    XCHR[I] := ' ';
  XCHR[9] := CHR(9);
  XCHR[12] := CHR(12);
  FOR I:=127 TO 255 DO
    XCHR[I] := ' ';
{:23}{24:}
  FOR I:=0 TO 255 DO
    XORD[CHR(I)] := 127;
  FOR I:=128 TO 255 DO
    XORD[XCHR[I]] := I;
  FOR I:=0 TO 126 DO
    XORD[XCHR[I]] := I;{:24}{74:}
  INTERACTION := 3;
{:74}{77:}
  DELETIONSALL := TRUE;
  SETBOXALLOWE := TRUE;
  ERRORCOUNT := 0;
{:77}{80:}
  HELPPTR := 0;
  USEERRHELP := FALSE;{:80}{97:}
  INTERRUPT := 0;
  OKTOINTERRUP := TRUE;{:97}


{215:}
  NESTPTR := 0;
  MAXNESTSTACK := 0;
  CURLIST.MODEFIELD := 1;
  CURLIST.HEADFIELD := 29999;
  CURLIST.TAILFIELD := 29999;
  CURLIST.AUXFIELD.INT := -65536000;
  CURLIST.MLFIELD := 0;
  CURLIST.PGFIELD := 0;
  SHOWNMODE := 0;{991:}
  PAGECONTENTS := 0;
  PAGETAIL := 29998;
  MEM[29998].HH.RH := 0;
  LASTGLUE := 65535;
  LASTPENALTY := 0;
  LASTKERN := 0;
  PAGESOFAR[7] := 0;
  PAGEMAXDEPTH := 0{:991};{:215}{254:}
  FOR K:=5263 TO 6106 DO
    XEQLEVEL[K] := 1;
{:254}{257:}
  HASH[514].LH := 0;
  HASH[514].RH := 0;
  FOR K:=515 TO 2880 DO
    HASH[K] := HASH[514];{:257}{272:}
  SAVEPTR := 0;
  CURLEVEL := 1;
  CURGROUP := 0;
  CURBOUNDARY := 0;
  MAXSAVESTACK := 0;
{:272}{287:}
  MAGSET := 0;{:287}{383:}
  CURMARK[0] := 0;
  CURMARK[1] := 0;
  CURMARK[2] := 0;
  CURMARK[3] := 0;
  CURMARK[4] := 0;{:383}{439:}
  CURVAL := 0;
  CURVALLEVEL := 0;
  RADIX := 0;
  CURORDER := 0;
{:439}{481:}
  FOR K:=0 TO 16 DO
    READOPEN[K] := 2;{:481}{490:}
  CONDPTR := 0;
  IFLIMIT := 0;
  CURIF := 0;
  IFLINE := 0;
{:490}
{551:}
  FOR K:=0 TO FONTMAX DO
    FONTUSED[K] := FALSE;
{:551}{556:}
  NULLCHARACTE.B0 := 0;
  NULLCHARACTE.B1 := 0;
  NULLCHARACTE.B2 := 0;
  NULLCHARACTE.B3 := 0;{:556}{593:}
  TOTALPAGES := 0;
  MAXV := 0;
  MAXH := 0;
  MAXPUSH := 0;
  LASTBOP := -1;
  DOINGLEADERS := FALSE;
  DEADCYCLES := 0;
  CURS := -1;
{:593}{596:}
  HALFBUF := dvi_buf_size DIV 2;
  DVILIMIT := dvi_buf_size;
  DVIPTR := 0;
  DVIOFFSET := 0;
  DVIGONE := 0;{:596}{606:}
  DOWNPTR := 0;
  RIGHTPTR := 0;
{:606}{648:}
  ADJUSTTAIL := 0;
  LASTBADNESS := 0;{:648}{662:}
  PACKBEGINLIN := 0;
{:662}{685:}
  EMPTYFIELD.RH := 0;
  EMPTYFIELD.LH := 0;
  NULLDELIMITE.B0 := 0;
  NULLDELIMITE.B1 := 0;
  NULLDELIMITE.B2 := 0;
  NULLDELIMITE.B3 := 0;
{:685}{771:}
  ALIGNPTR := 0;
  CURALIGN := 0;
  CURSPAN := 0;
  CURLOOP := 0;
  CURHEAD := 0;
  CURTAIL := 0;{:771}{928:}
  FOR Z:=0 TO 307 DO
    BEGIN
      HYPHWORD[Z] := 0;
      HYPHLIST[Z] := 0;
    END;
  HYPHCOUNT := 0;{:928}{990:}
  OUTPUTACTIVE := FALSE;
  INSERTPENALT := 0;{:990}{1033:}
  LIGATUREPRES := FALSE;
  CANCELBOUNDA := FALSE;
  LFTHIT := FALSE;
  RTHIT := FALSE;
  INSDISC := FALSE;{:1033}{1267:}
  AFTERTOKEN := 0;
{:1267}{1282:}
  LONGHELPSEEN := FALSE;{:1282}{1300:}
  FORMATIDENT := 0;
  STRPTR := 0; {to determine, if string pool is empty}
{:1300}{1343:}
  FOR K:=0 TO 17 DO
    WRITEOPEN[K] := FALSE;
{:1343}
end;

procedure fix_date_and_time;
begin
{In final version get real date. But for testing a fixed date is better.

  uses sysutils;

var YY, MM, DD, Hour, Min, Sec, Ms: word;

  DecodeDate(Date, YY, MM, DD);
  DecodeTime(Time, Hour, Min, Sec, Ms);
  sys_time  := Hour*60+Min;
  sys_day   := DD;
  sys_month := MM;
  sys_year  := YY;
}
  sys_time  := 12*60;
  sys_day   := 4;
  sys_month := 7;
  sys_year  := 1776;
  EQTB[int_base+time_code ].INT := sys_time;
  EQTB[int_base+day_code  ].INT := sys_day;
  EQTB[int_base+month_code].INT := sys_month;
  EQTB[int_base+year_code ].INT := sys_year;
end;





{ ----------------------------------------------------------------------
  Print to terminal and log file
  ---------------------------------------------------------------------- }

{57:}
PROCEDURE PRINTLN;
BEGIN
  CASE SELECTOR OF 
    19:
        BEGIN
          WRITELN(OUTPUT);
          WRITELN(LOGFILE);
          TERMOFFSET := 0;
          FILEOFFSET := 0;
        END;
    18:
        BEGIN
          WRITELN(LOGFILE);
          FILEOFFSET := 0;
        END;
    17:
        BEGIN
          WRITELN(OUTPUT);
          TERMOFFSET := 0;
        END;
    16:;
  END;
END;
{:57}

{58:}

PROCEDURE PRINTCHAR(S:ASCIICODE);
BEGIN
  {if @<Character |s| is the current new-line character@> then}
  IF {244:}S=EQTB[5312].INT{:244}THEN BEGIN
    PRINTLN;
    exit;
  END;
  CASE SELECTOR OF 
    19: BEGIN
          WRITE(OUTPUT,XCHR[S]);
          WRITE(LOGFILE,XCHR[S]);
          TERMOFFSET := TERMOFFSET+1;
          FILEOFFSET := FILEOFFSET+1;
          IF TERMOFFSET=MAXPRINTLINE THEN
            BEGIN
              WRITELN(OUTPUT);
              TERMOFFSET := 0;
            END;
          IF FILEOFFSET=MAXPRINTLINE THEN
            BEGIN
              WRITELN(LOGFILE);
              FILEOFFSET := 0;
            END;
        END;
    18: BEGIN
          WRITE(LOGFILE,XCHR[S]);
          FILEOFFSET := FILEOFFSET+1;
          IF FILEOFFSET=MAXPRINTLINE THEN PRINTLN;
        END;
    17: BEGIN
          WRITE(OUTPUT,XCHR[S]);
          TERMOFFSET := TERMOFFSET+1;
          IF TERMOFFSET=MAXPRINTLINE THEN PRINTLN;
        END;
    16:;
  END;
  TALLY := TALLY+1;
END;
{:58}

{59:}
procedure print_utf8str(const s: utf8string);
var i: integer;
begin
  for i := 1 to length(s) do PRINTCHAR(ord(s[i]));
end;

procedure print_str(const s: shortstring);
var i: integer;
begin
  for i := 1 to length(s) do PRINTCHAR(ord(s[i]));
end;
{:59}

{60:}
{If char is unprintable, translate to something readable}
function PrintableChar(ch: byte) : shortstring;
const
  Hex: array [0..15] of char = '0123456789abcdef';
var
  s: string[4];
begin
  if ch < 32 then begin
    s := '^^A';
    s[3] := chr(ch + 64);
  end else if ch < 127 then begin
    s := chr(ch);
  end else if ch = 127 then begin
    s := '^^?';
  end else begin
    s := '^^00';
    s[3] := Hex[ch shr 4];
    s[4] := Hex[ch and 15];
  end;
  PrintableChar := s;
end;

function PrintableStr(const s: shortstring) : shortstring;
var
  i: sizeint;
  t: shortstring;
begin
  t := '';
  for i := 1 to length(s) do t := t + PrintableChar(ord(s[i]));
  PrintableStr := t;
end;

procedure slow_print_char(ch: byte);
begin
  print_str(PrintableChar(ch));
end;

procedure slow_print_str(s: shortstring);
begin
  print_str(PrintableStr(s));
end;

procedure slow_print_utf8str(const s: utf8string);
var
  i: sizeint;
begin
  for i := 1 to length(s) do print_str(PrintableChar(ord(s[i])));
end;

PROCEDURE SLOWPRINT(S:Int32);
VAR J: POOLPOINTER;
BEGIN
  if S<256 then slow_print_char(S)
  else if S>=STRPTR then print_str('???')
  else begin
    J := STRSTART[S];
    WHILE J<STRSTART[S+1] DO BEGIN
      slow_print_char(STRPOOL[J]);
      J := J+1;
    END;
  end;
end;
{:60}

{62:}
procedure print_nl_str(s: shortstring);
begin
  IF ((TERMOFFSET>0)AND(ODD(SELECTOR))) OR
     ((FILEOFFSET>0)AND(SELECTOR>=18)) THEN PRINTLN;
  print_str(s);
end;
{:62}

{63:}
{Precede string with escape character (which is usually a backslash)}
function print_esc(Name: shortstring) : shortstring;
var ch: int32;
begin
  ch := EQTB[5308].INT; {current escape character}
  if (ch>=0) and (ch<256) then print_esc := PrintableChar(ch) + Name
                          else print_esc := Name;
end;

procedure print_esc_str(s: shortstring);
var ch: int32;
begin
  ch := EQTB[5308].INT; {current escape character}
  if (ch>=0) and (ch<256) then slow_print_char(ch);
  slow_print_str(s);
end;

PROCEDURE PRINTESC(S:STRNUMBER);
VAR C: Int32;
BEGIN{243:}
  C := EQTB[5308].INT{:243};
  IF C>=0 THEN
    IF C<256 THEN slow_print_char(C);
  SLOWPRINT(S);
END;
{:63}

{64:}
PROCEDURE PRINTTHEDIGS(K:EIGHTBITS);
BEGIN
  WHILE K>0 DO
    BEGIN
      K := K-1;
      IF DIG[K]<10 THEN PRINTCHAR(48+DIG[K])
      ELSE PRINTCHAR(55+DIG[K]);
    END;
END;
{:64}

{65:}
PROCEDURE PRINTINT(N:Int32);

VAR K: 0..23;
  M: Int32;
BEGIN
  K := 0;
  IF N<0 THEN
    BEGIN
      PRINTCHAR(45);
      IF N>-100000000 THEN N := -N
      ELSE
        BEGIN
          M := -1-N;
          N := M DIV 10;
          M := (M MOD 10)+1;
          K := 1;
          IF M<10 THEN DIG[0] := M
          ELSE
            BEGIN
              DIG[0] := 0;
              N := N+1;
            END;
        END;
    END;
  REPEAT
    DIG[K] := N MOD 10;
    N := N DIV 10;
    K := K+1;
  UNTIL N=0;
  PRINTTHEDIGS(K);
END;

{1355:}
procedure print_write_whatsit_str(s: shortstring; P: HALFWORD);
BEGIN
  print_esc_str(s);
  IF MEM[P+1].HH.LH<16 THEN PRINTINT(MEM[P+1].HH.LH)
  ELSE IF MEM[P+1].HH.LH=16 THEN PRINTCHAR(42)
  ELSE PRINTCHAR(45);
END;
{:1355}

{70:}
PROCEDURE PRINTCURRENT;

VAR J: POOLPOINTER;
BEGIN
  J := STRSTART[STRPTR];
  WHILE J<POOLPTR DO
    BEGIN
      PRINTCHAR(STRPOOL[J]);
      J := J+1;
    END;
END;
{:70}






{ ----------------------------------------------------------------------
  Error handling
  ---------------------------------------------------------------------- }


procedure print_err(Msg: string);
begin
  print_nl_str('! ' + Msg);
end;

procedure help1(Msg0: string);
begin
  HELPPTR := 1;
  help_line[0] := Msg0;
end;

procedure help2(Msg1, Msg0: string);
begin
  HELPPTR := 2;
  help_line[1] := Msg1;
  help_line[0] := Msg0;
end;

procedure help3(Msg2, Msg1, Msg0: string);
begin
  HELPPTR := 3;
  help_line[2] := Msg2;
  help_line[1] := Msg1;
  help_line[0] := Msg0;
end;

procedure help4(Msg3, Msg2, Msg1, Msg0: string);
begin
  HELPPTR := 4;
  help_line[3] := Msg3;
  help_line[2] := Msg2;
  help_line[1] := Msg1;
  help_line[0] := Msg0;
end;

procedure help5(Msg4, Msg3, Msg2, Msg1, Msg0: string);
begin
  HELPPTR := 5;
  help_line[4] := Msg4;
  help_line[3] := Msg3;
  help_line[2] := Msg2;
  help_line[1] := Msg1;
  help_line[0] := Msg0;
end;

procedure help6(Msg5, Msg4, Msg3, Msg2, Msg1, Msg0: string);
begin
  HELPPTR := 6;
  help_line[5] := Msg5;
  help_line[4] := Msg4;
  help_line[3] := Msg3;
  help_line[2] := Msg2;
  help_line[1] := Msg1;
  help_line[0] := Msg0;
end;



{78:}
PROCEDURE OPENLOGFILE; FORWARD;
PROCEDURE GIVEERRHELP; FORWARD;
PROCEDURE SHOWCONTEXT; FORWARD;
PROCEDURE close_files_and_terminate; FORWARD;

{$IFDEF DEBUGGING}
PROCEDURE DEBUGHELP; FORWARD;
{$ENDIF}
{:78}


procedure PutHelpToLog;
begin
  ERRORCOUNT := ERRORCOUNT+1;
  IF ERRORCOUNT=100 THEN BEGIN
    print_nl_str('(That makes 100 errors; please try again.)');
    HISTORY := 3;
    close_files_and_terminate;
  END;

  {@<Put help message on the transcript file@>}
  IF INTERACTION>0 THEN SELECTOR := SELECTOR-1; {avoid terminal output}
  IF USEERRHELP THEN BEGIN
    PRINTLN;
    GIVEERRHELP;
  END ELSE WHILE HELPPTR>0 DO BEGIN
    HELPPTR := HELPPTR-1;
    print_nl_str(help_line[HELPPTR]);
  END;
  PRINTLN;
  IF INTERACTION>0 THEN SELECTOR := SELECTOR+1; {re-enable terminal output}
  PRINTLN;
end;


procedure normalize_selector;
BEGIN
  IF LOGOPENED THEN SELECTOR := 19
               ELSE SELECTOR := 17;
  IF job_name='' THEN OPENLOGFILE;
  IF INTERACTION=0 THEN SELECTOR := SELECTOR-1;
END;


procedure succumb;
BEGIN
  IF INTERACTION=3 THEN INTERACTION := 2;
  IF LOGOPENED THEN begin

    {same code as in |error|, but without interaction, which is not required here}
    IF HISTORY<2 THEN HISTORY := 2;
    PRINTCHAR(ord('.'));
    SHOWCONTEXT;
    PutHelpToLog;

  end;

  {$IFDEF DEBUGGING}
  IF INTERACTION>0 THEN DEBUGHELP;
  {$ENDIF}
  HISTORY := 3;
  close_files_and_terminate;
END;


procedure fatal_error(const s: shortstring);
begin
  normalize_selector;
  print_err('Emergency stop');
  help1(s);
  succumb;
END;


procedure overflow(const s: shortstring; n: Int32);
BEGIN
  normalize_selector;
  print_err('TeX capacity exceeded, sorry [' + s + '=' + print_int(n) + ']');
  help2('If you really absolutely need more capacity,',
        'you can ask a wizard to enlarge me.');
  succumb;
END;


PROCEDURE confusion_str(s: shortstring);
BEGIN
  normalize_selector;
  IF HISTORY<2 THEN BEGIN
    print_err('This can''t happen (' + s + ')');
    help1('I''m broken. Please show this to someone who can fix can fix');
  END ELSE BEGIN
    print_err('I can''t go on meeting you like this');
    help2('One of your faux pas seems to have wounded me deeply...',
          'in fact, I''m barely conscious. Please fix it and try again.');
  END;
  succumb;
END;


PROCEDURE BEGINDIAGNOS;
BEGIN
  OLDSETTING := SELECTOR;
  IF (EQTB[5292].INT<=0)AND(SELECTOR=19)THEN
    BEGIN
      SELECTOR := SELECTOR-1;
      IF HISTORY=0 THEN HISTORY := 1;
    END;
END;


PROCEDURE ENDDIAGNOSTI(BLANKLINE:BOOLEAN);
BEGIN
  print_nl_str('');
  IF BLANKLINE THEN PRINTLN;
  SELECTOR := OLDSETTING;
END;





{ ----------------------------------------------------------------------
  String pool handling
  ---------------------------------------------------------------------- }





procedure SetString(PoolIndex: STRNUMBER; Content: shortstring);
var i: int32;
begin
  for i := 1 to length(Content) do begin
    STRPOOL[POOLPTR+i-1] := ord(Content[i]);
  end;
  STRSTART[PoolIndex] := POOLPTR;
  POOLPTR := POOLPTR + length(Content);
end;

function GetString(PoolIndex: STRNUMBER) : shortstring;
var
  Start: POOLPOINTER;
  Stop: POOLPOINTER;
  i: POOLPOINTER;
  Content: shortstring;
begin
  Start := STRSTART[PoolIndex];
  Stop  := STRSTART[PoolIndex+1];
  setlength(Content, Stop-Start);
  for i := 1 to Stop-Start do
    Content[i] := chr(STRPOOL[Start+i-1]);
  GetString := Content;
end;

function AddString(s: shortstring) : STRNUMBER;
begin
  if STRPTR>=max_strings then 
    overflow('number of strings', max_strings-INITSTRPTR);
  if POOLPTR+length(s) >= POOLSIZE then
    overflow('pool size', POOLSIZE-INITPOOLPTR);
  SetString(STRPTR, s);
  STRPTR := STRPTR + 1;
  STRSTART[STRPTR] := POOLPTR;
  AddString := STRPTR - 1;
end;


{43:}
FUNCTION MAKESTRING: STRNUMBER;
BEGIN
  IF STRPTR=MAXSTRINGS THEN overflow('number of strings', MAXSTRINGS-INITSTRPTR);
  STRPTR := STRPTR+1;
  STRSTART[STRPTR] := POOLPTR;
  MAKESTRING := STRPTR-1;
END;
{:43}

{45:}
FUNCTION STREQBUF(S:STRNUMBER;K:Int32): BOOLEAN;
VAR
  J: POOLPOINTER;
BEGIN
  J := STRSTART[S];
  WHILE J<STRSTART[S+1] DO BEGIN
    IF STRPOOL[J]<>BUFFER[K] THEN BEGIN
      STREQBUF := FALSE;
      exit;
    END;
    J := J+1;
    K := K+1;
  END;
  STREQBUF := TRUE;
END;
{:45}

procedure append_char(ch: byte);
begin
  STRPOOL[POOLPTR] := ch;
  POOLPTR := POOLPTR+1;
end;

procedure flush_char;
begin
  POOLPTR := POOLPTR-1;
end;





{ ----------------------------------------------------------------------
  File input and output
  ---------------------------------------------------------------------- }





{27:}
{$I-}
function a_open_in(var f: alpha_file; FileName: shortstring): boolean;
begin
  assign(f, FileName);
  reset(f);
  a_open_in := (ioresult=0);
END;

function a_open_out(var f: alpha_file; FileName: shortstring) : boolean;
BEGIN
  assign(f, FileName);
  rewrite(f);
  a_open_out := (ioresult=0);
END;

function b_open_in(var f: byte_file; FileName: shortstring): boolean;
begin
  assign(f, FileName);
  reset(f);
  b_open_in := (ioresult=0);
END;

function b_open_out(var f: byte_file; FileName: shortstring): boolean;
begin
  assign(f, FileName);
  rewrite(f);
  b_open_out := (ioresult=0);
end;
{$I+}
{:27}

{328:}
PROCEDURE BEGINFILEREA;
BEGIN
  IF INOPEN=MAXINOPEN THEN overflow('text input levels', MAXINOPEN);
  IF FIRST=BUFSIZE THEN overflow('buffer size', BUFSIZE);
  INOPEN := INOPEN+1;
  BEGIN
    IF INPUTPTR>MAXINSTACK THEN
      BEGIN
        MAXINSTACK := INPUTPTR;
        IF INPUTPTR=STACKSIZE THEN overflow('input stack size', STACKSIZE);
      END;
    INPUTSTACK[INPUTPTR] := CURINPUT;
    INPUTPTR := INPUTPTR+1;
  END;
  CURINPUT.INDEXFIELD := INOPEN;
  LINESTACK[CURINPUT.INDEXFIELD] := LINE;
  CURINPUT.STARTFIELD := FIRST;
  CURINPUT.STATEFIELD := 1;
  CURINPUT.NAMEFIELD := 0;
END;
{:328}

{329:}
PROCEDURE ENDFILEREADI;
BEGIN
  FIRST := CURINPUT.STARTFIELD;
  LINE := LINESTACK[CURINPUT.INDEXFIELD];
  IF CURINPUT.NAMEFIELD>17 THEN close(INPUTFILE[CURINPUT.INDEXFIELD]);
  BEGIN
    INPUTPTR := INPUTPTR-1;
    CURINPUT := INPUTSTACK[INPUTPTR];
  END;
  INOPEN := INOPEN-1;
END;
{:329}

{330:}
PROCEDURE CLEARFORERRO;
BEGIN
  WHILE (CURINPUT.STATEFIELD<>0) AND
        (CURINPUT.NAMEFIELD=0) AND
        (INPUTPTR>0) AND
        (CURINPUT.LOCFIELD>CURINPUT.LIMITFIELD) 
  DO ENDFILEREADI;
  PRINTLN;
END;
{:330}

{31:}
FUNCTION INPUTLN(VAR F:alpha_file;BYPASSEOLN:BOOLEAN): BOOLEAN;
VAR
  LASTNONBLANK: 0..BUFSIZE;
  ch: Char;
BEGIN
  LAST := FIRST;
  IF EOF(F) THEN INPUTLN := FALSE
  ELSE BEGIN
    LASTNONBLANK := FIRST;
    WHILE NOT EOLN(F) DO BEGIN
      IF LAST >= MAXBUFSTACK THEN BEGIN
        MAXBUFSTACK := LAST+1;
        IF MAXBUFSTACK = BUFSIZE THEN begin
          IF STRPTR=0 THEN BEGIN 
            WRITELN(OUTPUT,'Buffer size exceeded!');
            halt(History);
          END ELSE BEGIN
            CURINPUT.LOCFIELD := FIRST;
            CURINPUT.LIMITFIELD := LAST-1;
            overflow('buffer size', BUFSIZE);
          END;
        end;
      END;
      Read(F, ch);
      BUFFER[LAST] := XORD[ch];
      LAST := LAST+1;
      IF BUFFER[LAST-1]<>32 THEN LASTNONBLANK := LAST;
    END;
    READLN(F);
    LAST := LASTNONBLANK;
    INPUTLN := TRUE;
  END;
END;
{:31}

{37:}
procedure InitTerminal;
var
  s: shortstring;
  p, i: integer;
  len, j: sizeint;
begin

  job_name := '';
  NAMEINPROGRE := FALSE;
  LOGOPENED := FALSE;
  output_file_name := '';

  INPUTPTR := 0;
  MAXINSTACK := 0;
  INOPEN := 0;
  OPENPARENS := 0;
  MAXBUFSTACK := 0;
  PARAMPTR := 0;
  MAXPARAMSTAC := 0;

  for FIRST := 1 to BUFSIZE do BUFFER[FIRST] := 0;
  FIRST := 1;

  SCANNERSTATU := 0;
  WARNINGINDEX := 0;
  CURINPUT.STATEFIELD := 33;
  CURINPUT.STARTFIELD := 1;
  CURINPUT.INDEXFIELD := 0;
  LINE := 0;
  CURINPUT.NAMEFIELD := 0;
  FORCEEOF := FALSE;
  ALIGNSTATE := 1000000;

  if paramcount <> 0 then begin
    i := FIRST;
    for p := 1 to paramcount do begin
      s := paramstr(p);
      len := length(s);
      if i+len >= BUFSIZE then begin
        writeln(output, 'Buffer size exceeded!');
        halt(History);
      end;
      for j := 1 to len do buffer[i+j-1] := ord(s[j]);
      buffer[i+len] := ord(' ');
      i := i + len + 1;
    end;
    LAST := i-1;
    MAXBUFSTACK := LAST+1; {only for statistics?}
    CURINPUT.LOCFIELD := FIRST;
  end else begin
    RESET(INPUT);
    WHILE TRUE DO BEGIN
      WRITE(OUTPUT,'**');
      FLUSH(OUTPUT);
      IF NOT INPUTLN(INPUT, TRUE) THEN BEGIN
        WRITELN(OUTPUT);
        WRITE(OUTPUT,'! End of file on the terminal... why?');
        halt(History);
      END;
      CURINPUT.LOCFIELD := FIRST;
      WHILE (CURINPUT.LOCFIELD<LAST)AND(BUFFER[CURINPUT.LOCFIELD]=32) DO
        CURINPUT.LOCFIELD := CURINPUT.LOCFIELD+1;
      IF CURINPUT.LOCFIELD<LAST THEN break;
      WRITELN(OUTPUT,'Please type the name of your input file.');
    END;
  end;
  CURINPUT.LIMITFIELD := LAST;
  FIRST := LAST+1;
end;
{:37}

{71:}
function term_input: shortstring;
var s: shortstring;
begin
  readln(input, s);

  TERMOFFSET := 0;
  SELECTOR := SELECTOR-1;
  if s <> '' then print_str(s);
  PRINTLN;
  SELECTOR := SELECTOR+1;

  term_input := s;
end;

PROCEDURE TERMINPUT;
VAR K: 0..BUFSIZE;
BEGIN
  FLUSH(OUTPUT);
  IF NOT INPUTLN(INPUT, TRUE) THEN fatal_error('End of file on the terminal!');
  TERMOFFSET := 0;
  SELECTOR := SELECTOR-1;
  IF LAST<>FIRST THEN FOR K:=FIRST TO LAST-1 DO slow_print_char(BUFFER[K]);
  PRINTLN;
  SELECTOR := SELECTOR+1;
END;
{:71}

{363:}
{@ If the user has set the |pausing| parameter to some positive value,
and if nonstop mode has not been selected, each line of input is displayed
on the terminal and the transcript file, followed by =>.
\TeX\ waits for a response. If the response is simply |carriage_return|, the
line is accepted as it stands, otherwise the line typed is
used instead of the line in the file.}

PROCEDURE FIRMUPTHELIN;
VAR K: 0..BUFSIZE;
BEGIN
  CURINPUT.LIMITFIELD := LAST;
  IF EQTB[5291].INT>0 THEN
    IF INTERACTION>1 THEN
      BEGIN;
        PRINTLN;
        IF CURINPUT.STARTFIELD<CURINPUT.LIMITFIELD THEN
          FOR K:=CURINPUT.STARTFIELD TO CURINPUT.LIMITFIELD-1 DO
            slow_print_char(BUFFER[K]);
        FIRST := CURINPUT.LIMITFIELD;
        print_str('=>');
        TERMINPUT;
        IF LAST>FIRST THEN
          BEGIN
            FOR K:=FIRST TO LAST-1 DO
              BUFFER[K+CURINPUT.
              STARTFIELD-FIRST] := BUFFER[K];
            CURINPUT.LIMITFIELD := CURINPUT.STARTFIELD+LAST-FIRST;
          END;
      END;
END;
{:363}



{530:}
function prompt_file_name(InvalidFileName: shortstring;
                          Prompt: shortstring;
                          Extension: shortstring) : shortstring;
var
  i : SizeInt;
  Start : SizeInt;
  Line : shortstring;
BEGIN
  IF Prompt='input file name' THEN BEGIN
    print_err('I can''t find file `');
  END ELSE BEGIN
    print_err('I can''t write on file `');
  END;
  print_str(InvalidFileName + '''.');
  IF Extension='.tex' THEN SHOWCONTEXT;
  print_nl_str('Please type another ' + Prompt);
  IF INTERACTION<2 THEN fatal_error('*** (job aborted, file error in nonstop mode)');;

  print_str(': ');
  Line := term_input;

  {remove leading spaces and cut after first space after that}
  i := 1;
  while (i <= length(Line)) and (Line[i] = ' ') do i := i + 1;
  Start := i;
  while (i <= length(Line)) and (Line[i] <> ' ') do begin
    if Line[i] = '.' then Extension := ''; {don't add extension if explicitly given}
    i := i + 1;
  end;
  prompt_file_name := copy(Line, Start, i-Start) + Extension;
end;
{:530}

{534:}
PROCEDURE OPENLOGFILE;
VAR
  OLDSETTING: 0..max_selector;
  K: 0..BUFSIZE;
  L: 0..BUFSIZE;
  s: shortstring;
const 
  MonthNames: array[1..12] of string[3] =
    ('JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
     'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC');
BEGIN
  OLDSETTING := SELECTOR;
  if job_name='' then job_name := 'texput';
  SELECTOR := 17;

  s := job_name + '.log';
  while not a_open_out(LOGFILE, s) do begin
    s := prompt_file_name(s, 'transcript file name', '.log');
  end;
  LOGNAME := AddString(s);

  SELECTOR := 18;
  LOGOPENED := TRUE;

  {536:}
  WRITE(LOGFILE, 'This is TeX, Version 3.141592653 Free Pascal');
  SLOWPRINT(FORMATIDENT);
    {This is the single remaining usage for `format_ident`:
     Safe the string when reading the format file until it is printed here.
     FIXME: open the log file at a fixed point in the program execution, e.g.
            directly after loading the format file}

  s := '  '
    + print_int(sys_day) + ' '
    + MonthNames[sys_month] + ' '
    + print_int(sys_year) + ' '
    + IntToStr02(sys_time div 60) + ':'
    + IntToStr02(sys_time mod 60);
  print_str(s);
  {:536};

  INPUTSTACK[INPUTPTR] := CURINPUT;
  print_nl_str('**');
  L := INPUTSTACK[0].LIMITFIELD;
  IF BUFFER[L]=EQTB[5311].INT THEN L := L-1;
  FOR K:=1 TO L DO
    slow_print_char(BUFFER[K]);
  PRINTLN;
  SELECTOR := OLDSETTING+2;
END;
{:534}





{ ----------------------------------------------------------------------
  Convert to string
  ---------------------------------------------------------------------- }




{@ Single-character control sequences do not need to be looked up in a hash
table, since we can use the character code itself as a direct address.
The procedure |print_cs| prints the name of a control sequence, given
a pointer to its address in |eqtb|. A space is printed after the name
unless it is a single nonletter or an active character. This procedure
might be invoked with invalid data, so it is ``extra robust.'' The
individual characters must be printed one at a time using |print|, since
they may be unprintable.}

function print_cs(P:Int32) : shortstring;
begin
  if (P<1) or (P>=2881) then begin
    print_cs := print_esc('IMPOSSIBLE.');
  end else if P<257 then begin
    print_cs := PrintableChar(P-1);
  end else if P<513 then begin
    if EQTB[3983+P-257].HH.RH=11 then begin
      print_cs := print_esc(chr(P-257)) + ' ';
    end else begin
      print_cs := print_esc(chr(P-257));
    end;
  end else if P=513 then begin
    print_cs := print_esc('csname') + print_esc('endcsname') + ' ';
  end else if (HASH[P].RH<0)OR(HASH[P].RH>=STRPTR) then begin
    print_cs := print_esc('NONEXISTENT.');
  end else begin
    print_cs := print_esc(GetString(HASH[P].RH)) + ' ';
  end;
END;

{@ Here is a similar procedure; it avoids the error checks, and it never
prints a space after the control sequence.}

function sprint_cs(P:HALFWORD) : string;
begin
  if      P<257 then sprint_cs := PrintableChar(P-1)
  else if P<513 then sprint_cs := print_esc(chr(P-257))
  else if P<514 then sprint_cs := print_esc('csname') + print_esc('endcsname')
                else sprint_cs := print_esc(GetString(HASH[P].RH));
end;

{@ Hexadecimal printing of nonnegative integers is accomplished by |print_hex|.}

function print_hex(n: int32): shortstring;
var 
  s: string[9];
  i: uint32;
  Digit: uint32;
begin
  setlength(s, 9);
  i := 9;
  repeat
    Digit := n mod 16;
    n := n div 16;
    if Digit > 10 then Digit := Digit - 10 + ord('A') - ord('0');
    s[i] := chr(Digit + ord('0'));
    i := i - 1;
  until n=0;
  s[i] := '"';
  print_hex := copy(s, i, 10-i);
end;

{@ Roman numerals are produced by the |print_roman_int| routine.  Readers
who like puzzles might enjoy trying to figure out how this tricky code
works; therefore no explanation will be given. Notice that 1990 yields
"mcmxc", not "mxm".}

function print_roman_int(N: uint32) : shortstring;
const
  Letters = 'mdclxvi';
VAR
  U, V: uint32;
  i: sizeuint;
  s: shortstring;
BEGIN
  i := 1;
  s := '';

  V := 1000;
  while true do begin
    while N>=V do begin
      s := s + Letters[i];
      N := N - V;
    end;
    if N<=0 then begin
      print_roman_int := s;
      exit;
    end;

    if odd(i) then begin
      U := V div 10;
      if N+U >= V then begin
        s := s + Letters[i+2] + Letters[i];
        N := N + U - V;
      end;
      V := V div 2;
    end else begin
      U := V div 5;
      if N+U >= V then begin
        s := s + Letters[i+1] + Letters[i];
        N := N + U - V;
      end;
      V := V div 5;
    end;
    i := i + 1;
(*
    U := V div 10;
    if N+U >= V then begin
      s := s + Letters[i+2] + Letters[i];       {>900 CM XC IX}
      N := N + U - V;
    end else if N >= 5*U then begin
      s := s + Letters[i+1];                    {>500 D  L  V}
      N := N - 5*U;
    end else if N >= 4*U then begin
      s := s + Letters[i+2] + Letters[i+1];     {>400 CD XL IV}
      N := N - 4*U;
    end;
    V := U;
    i := i + 2;
*)

  end;
end;

{convert SCALED to string}
function print_scaled(Scale: SCALED) : shortstring;
VAR
  Delta: SCALED;
  st: shortstring;
BEGIN
  st := '';
  if Scale<0 then begin
    st := st + '-';
    Scale := -Scale;
  end;
  st := st + print_int(Scale shr 16) + '.';
  Scale := 10*(Scale and 65535)+5;
  Delta := 10;
  REPEAT
    IF Delta>65536 THEN Scale := Scale-17232;
    st := st + chr((Scale shr 16)+48);
    Scale := 10*(Scale and 65535);
    Delta := Delta*10;
  UNTIL Scale <= Delta;
  print_scaled := st;
END;

{119:}
{292:}
function show_token_list_simple(P: int32; MaxStrLen: int32) : utf8string;
var
  M, C: Int32;
  MATCHCHR: ASCIICODE;
  N: ASCIICODE;
  s: shortstring;
  LongStr: utf8string;
begin
  MATCHCHR := 35;
  N := 48; {'0'}
  TALLY := 0; {no longer required?}
  LongStr := '';
  while (P<>0) and (length(LongStr)<MaxStrLen) do begin
    IF (P<HIMEMMIN)OR(P>MEMEND) THEN BEGIN
      show_token_list_simple := LongStr + print_esc('CLOBBERED.');
      exit;
    END;
    IF MEM[P].HH.LH>=4095 THEN s := print_cs(MEM[P].HH.LH-4095)
    ELSE BEGIN
      M := MEM[P].HH.LH DIV 256;
      C := MEM[P].HH.LH MOD 256;
      if MEM[P].HH.LH<0 then s := print_esc('BAD.')
      else begin
        case M of
          1,2,3,4,7,8,10,11,12: s := PrintableChar(C);
          6:  s := PrintableChar(C) + PrintableChar(C);
          5:  if C>9 then begin
                show_token_list_simple := LongStr + chr(MATCHCHR) + '!';
                exit;
              end else s := chr(MATCHCHR) + chr(C+48);
          13: begin
                MATCHCHR := C;
                N := N+1;
                s := PrintableChar(C) + chr(N);
                if N>57 then begin
                  show_token_list_simple := LongStr + s;
                  exit;
                end;
              end;
          14: s := '->';
          else s := print_esc('BAD.')
        end;
      end;
    end;
    P := MEM[P].HH.RH;
    LongStr := LongStr + s;
  end;
  if P<>0 then LongStr := LongStr + print_esc('ETC.');
  show_token_list_simple := LongStr;
end;

{295:}
PROCEDURE TOKENSHOW(P:HALFWORD);
BEGIN
  IF P<>0 THEN print_utf8str(show_token_list_simple(MEM[P].HH.RH,10000000));
END;
{:295}

{1284:}
PROCEDURE GIVEERRHELP;
BEGIN
  TOKENSHOW(EQTB[3421].HH.RH);
END;
{:1284}

{Instead of `print_char` with selector=pseudo, this procedure is called}
procedure print_char_pseudo(S: ASCIICODE);
begin
  if TALLY<TRICKCOUNT then TRICKBUF[TALLY MOD ERRORLINE] := S;
  TALLY := TALLY+1;
END;

procedure print_str_pseudo(const s: shortstring);
var i: sizeuint;
begin
  for i := 1 to length(s) do print_char_pseudo(ord(s[i]));
end;

{select=pseudo is only used in `show_context`. This special version of
`show_token_list` is only called there and behaves as if select=pseudo
was set, independent of the actual value of select.}
PROCEDURE show_token_list_pseudo(P, Q: int32; L: int32);
VAR
  M,C: int32;
  MATCHCHR: ASCIICODE;
  N: ASCIICODE;
  s: shortstring;
  i: sizeuint;
BEGIN
  MATCHCHR := 35;
  N := 48;
  TALLY := 0;
  WHILE P<>0 DO BEGIN
    if TALLY>=L then begin
      print_str_pseudo(print_esc('ETC.'));
      exit;
    end;

    IF P=Q THEN BEGIN
      {320:}
      FIRSTCOUNT := TALLY;
      TRICKCOUNT := TALLY+1+ERRORLINE-HALFERRORLIN;
      IF TRICKCOUNT<ERRORLINE THEN TRICKCOUNT := ERRORLINE;
      {:320}
    END;

    {293:}
    IF (P<HIMEMMIN)OR(P>MEMEND) THEN BEGIN
      print_str_pseudo(print_esc('CLOBBERED.'));
      exit;
    END;
    IF MEM[P].HH.LH>=4095 THEN s := print_cs(MEM[P].HH.LH-4095)
    ELSE BEGIN
      M := MEM[P].HH.LH DIV 256;
      C := MEM[P].HH.LH MOD 256;
      IF MEM[P].HH.LH<0 THEN s := print_esc('BAD.')
      ELSE
        {294:}
        CASE M OF 
          1,2,3,4,7,8,10,11,12: s := PrintableChar(C);
          6:  s := PrintableChar(C) + PrintableChar(C);
          5:  if C>9 then begin
                print_str_pseudo(chr(MATCHCHR) + '!');
                exit;
              end else s := chr(MATCHCHR) + chr(C+48);
          13: begin
                MATCHCHR := C;
                N := N+1;
                s := PrintableChar(C) + chr(N);
                if N>57 then begin
                  print_str(s);
                  exit;
                end;
              end;
          14: s := '->';
          ELSE s := print_esc('BAD.');
        END;
    END;
    print_str_pseudo(s);
    P := MEM[P].HH.RH;
  END;
END;
{:292}

{311:}
PROCEDURE SHOWCONTEXT;
VAR
  NN: Int32;
  BOTTOMLINE: BOOLEAN;{315:}
  I: 0..BUFSIZE;
  J: 0..BUFSIZE;
  L: 0..HALFERRORLIN;
  M: Int32;
  N: 0..ERRORLINE;
  P: Int32;
  Q: Int32;
{:315}
BEGIN
  BASEPTR := INPUTPTR;
  INPUTSTACK[BASEPTR] := CURINPUT;
  NN := -1;
  BOTTOMLINE := FALSE;
  WHILE TRUE DO
    BEGIN
      CURINPUT := INPUTSTACK[BASEPTR];
      IF (CURINPUT.STATEFIELD<>0)THEN
        IF (CURINPUT.NAMEFIELD>17)OR(BASEPTR=0)
          THEN BOTTOMLINE := TRUE;
      IF (BASEPTR=INPUTPTR)OR BOTTOMLINE OR(NN<EQTB[5317].INT)THEN{312:}
        BEGIN
          IF (BASEPTR=INPUTPTR)OR(CURINPUT.STATEFIELD<>0)OR(CURINPUT.INDEXFIELD<>3)
             OR(CURINPUT.LOCFIELD<>0)THEN
            BEGIN
              TALLY := 0;
              IF CURINPUT.STATEFIELD<>0 THEN
                BEGIN{313:}
                  IF CURINPUT.NAMEFIELD<=17 THEN
                    IF (CURINPUT.NAMEFIELD=0)THEN
                      IF BASEPTR=0 THEN print_nl_str('<*>')
                  ELSE print_nl_str('<insert> ')
                  ELSE
                    BEGIN
                      print_nl_str('<read ');
                      IF CURINPUT.NAMEFIELD=17 THEN PRINTCHAR(42)
                      ELSE PRINTINT(CURINPUT.NAMEFIELD-1);
                      PRINTCHAR(62);
                    END
                  ELSE
                    BEGIN
                      print_nl_str('l.');
                      PRINTINT(LINE);
                    END;
                  PRINTCHAR(32){:313};

                  {318:}
                  BEGIN
                    L := TALLY;
                    TALLY := 0;
                    TRICKCOUNT := 1000000;
                  END;
                  IF BUFFER[CURINPUT.LIMITFIELD]=EQTB[5311].INT
                    THEN J := CURINPUT.LIMITFIELD
                    ELSE J := CURINPUT.LIMITFIELD+1;
                  IF J>0 THEN begin
                    FOR I:=CURINPUT.STARTFIELD TO J-1 DO BEGIN
                      IF I=CURINPUT.LOCFIELD THEN BEGIN
                        FIRSTCOUNT := TALLY;
                        TRICKCOUNT := TALLY+1+ERRORLINE-HALFERRORLIN;
                        IF TRICKCOUNT<ERRORLINE THEN TRICKCOUNT := ERRORLINE;
                      END;
                      print_char_pseudo(BUFFER[I]);
                    END;
                  end;
                  {:318}
                END
              ELSE
                BEGIN{314:}
                  CASE CURINPUT.INDEXFIELD OF 
                    0: print_nl_str('<argument> ');
                    1,2: print_nl_str('<template> ');
                    3:
                       IF CURINPUT.LOCFIELD=0 THEN print_nl_str('<recently read> ')
                       ELSE print_nl_str('<to be read again> ');
                    4: print_nl_str('<inserted text> ');
                    5: BEGIN
                         PRINTLN;
                         print_str(print_cs(CURINPUT.NAMEFIELD));
                       END;
                    6: print_nl_str('<output> ');
                    7: print_nl_str('<everypar> ');
                    8: print_nl_str('<everymath> ');
                    9: print_nl_str('<everydisplay> ');
                    10: print_nl_str('<everyhbox> ');
                    11: print_nl_str('<everyvbox> ');
                    12: print_nl_str('<everyjob> ');
                    13: print_nl_str('<everycr> ');
                    14: print_nl_str('<mark> ');
                    15: print_nl_str('<write> ');
                    ELSE print_nl_str('?')
                  END{:314};
{319:}
                  BEGIN
                    L := TALLY;
                    TALLY := 0;
                    TRICKCOUNT := 1000000;
                  END;
                  if CURINPUT.INDEXFIELD<5
                    then show_token_list_pseudo(CURINPUT.STARTFIELD,
                                                CURINPUT.LOCFIELD,
                                                100000)
                    else show_token_list_pseudo(MEM[CURINPUT.STARTFIELD].HH.RH,
                                                CURINPUT.LOCFIELD,
                                                100000);
{:319}
                END;
{317:}
              IF TRICKCOUNT=1000000 THEN
                BEGIN
                  FIRSTCOUNT := TALLY;
                  TRICKCOUNT := TALLY+1+ERRORLINE-HALFERRORLIN;
                  IF TRICKCOUNT<ERRORLINE THEN TRICKCOUNT := ERRORLINE;
                END;
              IF TALLY<TRICKCOUNT THEN M := TALLY-FIRSTCOUNT
              ELSE M := TRICKCOUNT-
                        FIRSTCOUNT;
              IF L+FIRSTCOUNT<=HALFERRORLIN THEN
                BEGIN
                  P := 0;
                  N := L+FIRSTCOUNT;
                END
              ELSE
                BEGIN
                  print_str('...');
                  P := L+FIRSTCOUNT-HALFERRORLIN+3;
                  N := HALFERRORLIN;
                END;
              FOR Q:=P TO FIRSTCOUNT-1 DO
                PRINTCHAR(TRICKBUF[Q MOD ERRORLINE]);
              PRINTLN;
              FOR Q:=1 TO N DO
                PRINTCHAR(32);
              IF M+N<=ERRORLINE THEN P := FIRSTCOUNT+M
              ELSE P := FIRSTCOUNT+(ERRORLINE-N-3);
              FOR Q:=FIRSTCOUNT TO P-1 DO
                PRINTCHAR(TRICKBUF[Q MOD ERRORLINE]);
              IF M+N>ERRORLINE THEN print_str('...'){:317};
              NN := NN+1;
            END;
        END{:312}
      ELSE
        IF NN=EQTB[5317].INT THEN
          BEGIN
            print_nl_str('...');
            NN := NN+1;
          END;
      IF BOTTOMLINE THEN break;
      BASEPTR := BASEPTR-1;
    END;
  CURINPUT := INPUTSTACK[INPUTPTR];
END;
{:311}








{174:}
PROCEDURE SHORTDISPLAY(P:Int32);

VAR N: Int32;
BEGIN
  WHILE P>MEMMIN DO
    BEGIN
      IF (P>=HIMEMMIN)THEN
        BEGIN
          IF P<=MEMEND
            THEN
            BEGIN
              IF MEM[P].HH.B0<>FONTINSHORTD THEN
                BEGIN
                  IF (MEM[P].HH.B0<0)OR
                     (MEM[P].HH.B0>FONTMAX)THEN PRINTCHAR(42)
                  ELSE{267:}PRINTESC(HASH[2624+MEM[P].HH.B0].RH){:267};
                  PRINTCHAR(32);
                  FONTINSHORTD := MEM[P].HH.B0;
                END;
              slow_print_char(MEM[P].HH.B1);
            END;
        END
      ELSE{175:}
        CASE MEM[P].HH.B0 OF 
          0,1,3,8,4,5,13: print_str('[]');
          2: PRINTCHAR(124);
          10:
              IF MEM[P+1].HH.LH<>0 THEN PRINTCHAR(32);
          9: PRINTCHAR(36);
          6: SHORTDISPLAY(MEM[P+1].HH.RH);
          7:
             BEGIN
               SHORTDISPLAY(MEM[P+1].HH.LH);
               SHORTDISPLAY(MEM[P+1].HH.RH);
               N := MEM[P].HH.B1;
               WHILE N>0 DO
                 BEGIN
                   IF MEM[P].HH.RH<>0 THEN P := MEM[P].HH.RH;
                   N := N-1;
                 END;
             END;
          ELSE
        END{:175};
      P := MEM[P].HH.RH;
    END;
END;
{:174}

{176:}
PROCEDURE PRINTFONTAND(P:Int32);
BEGIN
  IF P>MEMEND THEN print_esc_str('CLOBBERED.')
  ELSE BEGIN
    IF (MEM[P].HH.B0<0)OR(MEM[P].HH.B0>FONTMAX)
    THEN PRINTCHAR(42)
    ELSE PRINTESC(HASH[2624+MEM[P].HH.B0].RH);
    PRINTCHAR(32);
    slow_print_char(MEM[P].HH.B1);
  END;
END;


PROCEDURE PRINTMARK(P:Int32);
BEGIN
  PRINTCHAR(123);
  IF (P<HIMEMMIN)OR(P>MEMEND)THEN print_esc_str('CLOBBERED.')
  ELSE print_utf8str(show_token_list_simple(MEM[P].HH.RH,MAXPRINTLINE-10));
  PRINTCHAR(125);
END;

function RuleDimStr(Dim: SCALED): shortstring;
begin 
  if (Dim=-1073741824) then RuleDimStr := '*'
                       else RuleDimStr := print_scaled(Dim);
end;
{:176}


{glue stretch and shrink, possibly followed by the name of finite units}
function print_glue(Scale: SCALED; Order: int32; Units: shortstring) : shortstring;
var s: shortstring;
begin
  s := print_scaled(Scale);
  case Order of
    0: s := s + Units;
    1: s := s + 'fil';
    2: s := s + 'fill';
    3: s := s + 'filll';
    else s := s + 'foul';
  end;
  print_glue := s;
end;

{whole glue specification}
function print_spec(P: Int32; Units: shortstring) : shortstring;
var s: shortstring;
begin
  if (P<mem_min) or (P>=LOMEMMAX) THEN s := '*'
  ELSE BEGIN
    s := print_scaled(MEM[P+1].INT) + Units;
    IF MEM[P+2].INT<>0 THEN
      s := s + ' plus ' + print_glue(MEM[P+2].INT, MEM[P].HH.B0, Units);
    IF MEM[P+3].INT<>0 THEN 
      s := s + ' minus ' + print_glue(MEM[P+3].INT, MEM[P].HH.B1, Units);
  END;
  print_spec := s;
END;


{@<Declare procedures needed for displaying the elements of mlists@>}

function print_fam_and_char(Node: HALFWORD) : shortstring;
BEGIN
  print_fam_and_char := print_esc('fam')
                      + print_int(MEM[Node].HH.B0) + ' '
                      + GetString(MEM[Node].HH.B1-0);
END;


{prints a delimiter as 24-bit hex value}
function print_delimiter(P:HALFWORD) : shortstring;
VAR A: Int32;
BEGIN
  A := MEM[P].QQQQ.B0*256+MEM[P].QQQQ.B1-0;
  A := A*4096+MEM[P].QQQQ.B2*256+MEM[P].QQQQ.B3-0;
  IF A<0 THEN print_delimiter := print_int(A)
         ELSE print_delimiter := print_hex(A);
END;


{692:}
{@ The inelegant introduction of |show_info| in the code above seems better
than the alternative of using \PASCAL's strange |forward| declaration for a
procedure with parameters. The \PASCAL\ convention about dropping parameters
from a post-|forward| procedure is, frankly, so intolerable to the author
of \TeX\ that he would rather stoop to communication via a global temporary
variable. (A similar stoopidity occurred with respect to |hlist_out| and
|vlist_out| above, and it will occur with respect to |mlist_to_hlist| below.)}
PROCEDURE SHOWINFO; FORWARD;

PROCEDURE PRINTSUBSIDI(P:HALFWORD;C:ASCIICODE);
BEGIN
  IF (POOLPTR-STRSTART[STRPTR])>=DEPTHTHRESHO THEN BEGIN
    IF MEM[P].HH.RH<>0 THEN print_str(' []');
  END ELSE BEGIN
    append_char(C);
    TEMPPTR := P;
    CASE MEM[P].HH.RH OF 
      1:  BEGIN
            PRINTLN;
            PRINTCURRENT;
            print_str(print_fam_and_char(P));
          END;
      2:  SHOWINFO;
      3:  IF MEM[P].HH.LH=0 THEN BEGIN
            PRINTLN;
            PRINTCURRENT;
            print_str('{}');
          END ELSE SHOWINFO;
    END;
    POOLPTR := POOLPTR-1;
  END;
END;
{:692}

function print_style(Code: int32) : shortstring;
begin
  case Code div 2 of
    0: print_style := print_esc('displaystyle');
    1: print_style := print_esc('textstyle');
    2: print_style := print_esc('scriptstyle');
    3: print_style := print_esc('scriptscriptstyle');
    else print_style := 'Unknown style!';
  end;
end;

{@ Sometimes we need to convert \TeX's internal code numbers into symbolic
form. The |print_skip_param| routine gives the symbolic name of a glue
parameter.}

function print_skip_param(GlueParam: int32) : shortstring;
begin
  case GlueParam of 
    0: print_skip_param := print_esc('lineskip');
    1: print_skip_param := print_esc('baselineskip');
    2: print_skip_param := print_esc('parskip');
    3: print_skip_param := print_esc('abovedisplayskip');
    4: print_skip_param := print_esc('belowdisplayskip');
    5: print_skip_param := print_esc('abovedisplayshortskip');
    6: print_skip_param := print_esc('belowdisplayshortskip');
    7: print_skip_param := print_esc('leftskip');
    8: print_skip_param := print_esc('rightskip');
    9: print_skip_param := print_esc('topskip');
    10: print_skip_param := print_esc('splittopskip');
    11: print_skip_param := print_esc('tabskip');
    12: print_skip_param := print_esc('spaceskip');
    13: print_skip_param := print_esc('xspaceskip');
    14: print_skip_param := print_esc('parfillskip');
    15: print_skip_param := print_esc('thinmuskip');
    16: print_skip_param := print_esc('medmuskip');
    17: print_skip_param := print_esc('thickmuskip');
    ELSE print_skip_param := '[unknown glue parameter!]';
  END;
END;


{182:}
PROCEDURE SHOWNODELIST(P:Int32);
VAR N: Int32;
  G: Double;
BEGIN
  IF (POOLPTR-STRSTART[STRPTR])>DEPTHTHRESHO THEN
    BEGIN
      IF P>0 THEN
        print_str(' []');
      exit;
    END;
  N := 0;
  WHILE P>MEMMIN DO BEGIN
    PRINTLN;
    PRINTCURRENT;
    IF P>MEMEND THEN BEGIN
      print_str('Bad link, display aborted.');
      exit;
    END;
    N := N+1;
    IF N>BREADTHMAX THEN BEGIN
      print_str('etc.');
      exit;
    END;
    {183:}
    IF (P>=HIMEMMIN)
    THEN PRINTFONTAND(P)
    ELSE CASE MEM[P].HH.B0 OF 
      0,1,13:{184:}
            BEGIN
              IF MEM[P].HH.B0=0 THEN print_esc_str('h')
              ELSE IF MEM[P].HH.B0=1 THEN print_esc_str('v')
              ELSE print_esc_str('unset');
              print_str('box(' + print_scaled(MEM[P+3].INT) + '+'
                               + print_scaled(MEM[P+2].INT) + ')x'
                               + print_scaled(MEM[P+1].INT));
              IF MEM[P].HH.B0=13 THEN BEGIN
                {185:}
                IF MEM[P].HH.B1<>0 THEN
                  print_str(' (' + print_int(MEM[P].HH.B1+1) + ' columns)');
                IF MEM[P+6].INT<>0 THEN
                  print_str(', stretch ' + print_glue(MEM[P+6].INT, MEM[P+5].HH.B1, ''));
                IF MEM[P+4].INT<>0 THEN
                  print_str(', shrink ' + print_glue(MEM[P+4].INT, MEM[P+5].HH.B0, ''));
                {:185}
              END ELSE BEGIN
                {186:}
                    G := MEM[P+6].GR;
                    IF (G<>0.0)AND(MEM[P+5].HH.B0<>0)THEN
                      BEGIN
                        print_str(', glue set ');
                        IF MEM[P+5].HH.B0=2 THEN print_str('- ');
                        IF ABS(MEM[P+6].INT)<1048576 THEN print_str('?.?')
                        ELSE
                          IF ABS(G)>20000.0 THEN
                            BEGIN
                              IF G>0.0 THEN PRINTCHAR(62)
                              ELSE print_str('< -');
                              print_str(print_glue(20000*65536, MEM[P+5].HH.B1, ''));
                            END
                        ELSE print_str(print_glue(ISORound(65536*G), MEM[P+5].HH.B1, ''));
                      END{:186};
                    IF MEM[P+4].INT<>0 THEN
                        print_str(', shifted ' + print_scaled(MEM[P+4].INT));
                  END;
                BEGIN
                  append_char(ord('.'));
                  SHOWNODELIST(MEM[P+5].HH.RH);
                  POOLPTR := POOLPTR-1;
                END;
              END{:184};
      2:{187:}
             BEGIN
               print_esc_str('rule(' + RuleDimStr(MEM[P+3].INT)
                               + '+' + RuleDimStr(MEM[P+2].INT)
                              + ')x' + RuleDimStr(MEM[P+1].INT));
             END{:187};
          3:{188:}
             BEGIN
               print_esc_str('insert' + print_int(MEM[P].HH.B1-0)
                 + ', natural size ' + print_scaled(MEM[P+3].INT)
                 + '; split(' + print_spec(MEM[P+4].HH.RH, '')
                 + ',' + print_scaled(MEM[P+2].INT)
                 + '); float cost ' + print_int(MEM[P+1].INT));
               BEGIN
                 append_char(ord('.'));
                 SHOWNODELIST(MEM[P+4].HH.LH);
                 POOLPTR := POOLPTR-1;
               END;
             END{:188};
          8:{1356:}
             CASE MEM[P].HH.B1 OF 
               0:
                  BEGIN
                    print_write_whatsit_str('openout', P);
                    PRINTCHAR(61);
                    {print_file_name}
                    print_str(GetString(MEM[P+2].HH.LH) +
                              GetString(MEM[P+1].HH.RH) +
                              GetString(MEM[P+2].HH.RH));
                  END;
               1:
                  BEGIN
                    print_write_whatsit_str('write', P);
                    PRINTMARK(MEM[P+1].HH.RH);
                  END;
               2: print_write_whatsit_str('closeout', P);
               3:
                  BEGIN
                    print_esc_str('special');
                    PRINTMARK(MEM[P+1].HH.RH);
                  END;
               4:
                  BEGIN
                    print_esc_str('setlanguage');
                    PRINTINT(MEM[P+1].HH.RH);
                    print_str(' (hyphenmin ');
                    PRINTINT(MEM[P+1].HH.B0);
                    PRINTCHAR(44);
                    PRINTINT(MEM[P+1].HH.B1);
                    PRINTCHAR(41);
                  END;
               ELSE print_str('whatsit?')
             END{:1356};
          10:{189:}
              IF MEM[P].HH.B1>=100 THEN{190:}
                BEGIN
                  print_esc_str('');
                  IF MEM[P].HH.B1=101 THEN PRINTCHAR(99)
                  ELSE IF MEM[P].HH.B1=102 THEN PRINTCHAR(120);
                  print_str('leaders ' + print_spec(MEM[P+1].HH.LH, ''));
                  BEGIN
                    append_char(ord('.'));
                    SHOWNODELIST(MEM[P+1].HH.RH);
                    POOLPTR := POOLPTR-1;
                  END;
                END{:190}
              ELSE
                BEGIN
                  print_esc_str('glue');
                  IF MEM[P].HH.B1<>0 THEN
                    BEGIN
                      PRINTCHAR(40);
                      IF MEM[P].HH.B1<98 THEN print_str(print_skip_param(MEM[P].HH.B1-1))
                      ELSE IF MEM[P].HH.B1=98 THEN print_esc_str('nonscript')
                      ELSE print_esc_str('mskip');
                      PRINTCHAR(41);
                    END;
                  IF MEM[P].HH.B1<>98 THEN
                    BEGIN
                      PRINTCHAR(32);
                      IF MEM[P].HH.B1<98 THEN print_str(print_spec(MEM[P+1].HH.LH, ''))
                                         ELSE print_str(print_spec(MEM[P+1].HH.LH, 'mu'));
                    END;
                END{:189};
          11:{191:}
              IF MEM[P].HH.B1<>99 THEN
                BEGIN
                  print_esc_str('kern');
                  IF MEM[P].HH.B1<>0 THEN PRINTCHAR(32);
                  print_str(print_scaled(MEM[P+1].INT));
                  IF MEM[P].HH.B1=2 THEN print_str(' (for accent)');
                END
              ELSE print_esc_str('mkern' + print_scaled(MEM[P+1].INT) + 'mu');
            {:191}
          9:{192:}
             BEGIN
               print_esc_str('math');
               IF MEM[P].HH.B1=0 THEN print_str('on')
                                 ELSE print_str('off');
               IF MEM[P+1].INT<>0 THEN print_str(', surrounded ' + print_scaled(MEM[P+1].INT));
             END{:192};
          6:{193:}
             BEGIN
               PRINTFONTAND(P+1);
               print_str(' (ligature ');
               IF MEM[P].HH.B1>1 THEN PRINTCHAR(124);
               FONTINSHORTD := MEM[P+1].HH.B0;
               SHORTDISPLAY(MEM[P+1].HH.RH);
               IF ODD(MEM[P].HH.B1)THEN PRINTCHAR(124);
               PRINTCHAR(41);
             END{:193};
          12:{194:}
              BEGIN
                print_esc_str('penalty ');
                PRINTINT(MEM[P+1].INT);
              END{:194};
          7:{195:}
             BEGIN
               print_esc_str('discretionary');
               IF MEM[P].HH.B1>0 THEN
                 BEGIN
                   print_str(' replacing ');
                   PRINTINT(MEM[P].HH.B1);
                 END;
               BEGIN
                 append_char(ord('.'));
                 SHOWNODELIST(MEM[P+1].HH.LH);
                 POOLPTR := POOLPTR-1;
               END;
               append_char(124);
               SHOWNODELIST(MEM[P+1].HH.RH);
               POOLPTR := POOLPTR-1;
             END{:195};
          4:{196:}
             BEGIN
               print_esc_str('mark');
               PRINTMARK(MEM[P+1].INT);
             END{:196};
          5:{197:}
             BEGIN
               print_esc_str('vadjust');
               BEGIN
                 append_char(ord('.'));
                 SHOWNODELIST(MEM[P+1].INT);
                 POOLPTR := POOLPTR-1;
               END;
             END{:197};{690:}
          14: print_str(print_style(MEM[P].HH.B1));
          15:{695:}
              BEGIN
                print_esc_str('mathchoice');
                append_char(ord('D'));
                SHOWNODELIST(MEM[P+1].HH.LH);
                POOLPTR := POOLPTR-1;
                append_char(ord('T'));
                SHOWNODELIST(MEM[P+1].HH.RH);
                POOLPTR := POOLPTR-1;
                append_char(ord('S'));
                SHOWNODELIST(MEM[P+2].HH.LH);
                POOLPTR := POOLPTR-1;
                append_char(ord('s'));
                SHOWNODELIST(MEM[P+2].HH.RH);
                POOLPTR := POOLPTR-1;
              END{:695};
      16,17,18,19,20,21,22,23,24,27,26,29,28,30,31:
            {696:}
            BEGIN
              CASE MEM[P].HH.B0 OF
                16: print_esc_str('mathord');
                17: print_esc_str('mathop');
                18: print_esc_str('mathbin');
                19: print_esc_str('mathrel');
                20: print_esc_str('mathopen');
                21: print_esc_str('mathclose');
                22: print_esc_str('mathpunct');
                23: print_esc_str('mathinner');
                27: print_esc_str('overline');
                26: print_esc_str('underline');
                29: print_esc_str('vcenter');
                24: print_esc_str('radical' + print_delimiter(P+4));
                28: print_esc_str('accent' + print_fam_and_char(P+4));
                30: print_esc_str('left' + print_delimiter(P+1));
                31: print_esc_str('right' + print_delimiter(P+1));
              END;
              IF MEM[P].HH.B1<>0 THEN
                IF MEM[P].HH.B1=1 THEN print_esc_str('limits')
                                  ELSE print_esc_str('nolimits');
              IF MEM[P].HH.B0<30 THEN PRINTSUBSIDI(P+1, 46);
              PRINTSUBSIDI(P+2, 94);
              PRINTSUBSIDI(P+3, 95);
            END;
              {:696}

          25: {697:}
            BEGIN
              print_esc_str('fraction, thickness ');
              IF MEM[P+1].INT=1073741824 THEN print_str('= default')
                                         ELSE print_str(print_scaled(MEM[P+1].INT));
              IF (MEM[P+4].QQQQ.B0<>0) OR
                 (MEM[P+4].QQQQ.B1<>0) OR
                 (MEM[P+4].QQQQ.B2<>0) OR
                 (MEM[P+4].QQQQ.B3<>0)
              THEN print_str(', left-delimiter ' + print_delimiter(P+4));
              IF (MEM[P+5].QQQQ.B0<>0) OR
                 (MEM[P+5].QQQQ.B1<>0) OR
                 (MEM[P+5].QQQQ.B2<>0) OR
                 (MEM[P+5].QQQQ.B3<>0)
              THEN print_str(', right-delimiter ' + print_delimiter(P+5));
              PRINTSUBSIDI(P+2,92);
              PRINTSUBSIDI(P+3,47);
            END;
            {:697}
      ELSE  print_str('Unknown node type!')
    END{:183};
    P := MEM[P].HH.RH;
  END;
END;
{:182}

{693:}
PROCEDURE SHOWINFO;
BEGIN
  SHOWNODELIST(MEM[TEMPPTR].HH.LH);
END;
{:693}

{198:}
PROCEDURE SHOWBOX(P:HALFWORD);
BEGIN{236:}
  DEPTHTHRESHO := EQTB[5288].INT;
  BREADTHMAX := EQTB[5287].INT{:236};
  IF BREADTHMAX<=0 THEN BREADTHMAX := 5;
  IF POOLPTR+DEPTHTHRESHO>=POOLSIZE THEN DEPTHTHRESHO := POOLSIZE-POOLPTR-1;
  SHOWNODELIST(P);
  PRINTLN;
END;
{:198}


{211:}
function print_mode(M: Int32) : shortstring;
BEGIN
  IF M>0 THEN
    CASE M DIV(101) OF 
      0: print_mode := 'vertical mode';
      1: print_mode := 'horizontal mode';
      2: print_mode := 'display math mode';
      else print_mode := 'mode';
    END
  ELSE IF M=0 THEN print_mode := 'no mode'
  ELSE
    CASE (-M)DIV(101) OF 
      0: print_mode := 'internal vertical mode';
      1: print_mode := 'restricted horizontal mode';
      2: print_mode := 'math mode';
      else print_mode := 'mode';
    END;
END;
{:211}

{985:}
function print_totals : shortstring;
var s: shortstring;
BEGIN
  s := print_scaled(PAGESOFAR[1]);
  IF PAGESOFAR[2]<>0 THEN
    s := s + ' plus ' + print_scaled(PAGESOFAR[2]);
  IF PAGESOFAR[3]<>0 THEN
    s := s + ' plus ' + print_scaled(PAGESOFAR[3]) + 'fil';
  IF PAGESOFAR[4]<>0 THEN
    s := s + ' plus ' + print_scaled(PAGESOFAR[4]) + 'fill';
  IF PAGESOFAR[5]<>0 THEN
    s := s + ' plus ' + print_scaled(PAGESOFAR[5]) + 'filll';
  IF PAGESOFAR[6]<>0 THEN
    s := s + ' minus ' + print_scaled(PAGESOFAR[6]);
  print_totals := s;
END;
{:985}


{237:}
function print_param(Code: int32) : shortstring;
begin
  case Code-int_base of
    0: print_param := print_esc('pretolerance');
    1: print_param := print_esc('tolerance');
    2: print_param := print_esc('linepenalty');
    3: print_param := print_esc('hyphenpenalty');
    4: print_param := print_esc('exhyphenpenalty');
    5: print_param := print_esc('clubpenalty');
    6: print_param := print_esc('widowpenalty');
    7: print_param := print_esc('displaywidowpenalty');
    8: print_param := print_esc('brokenpenalty');
    9: print_param := print_esc('binoppenalty');
    10: print_param := print_esc('relpenalty');
    11: print_param := print_esc('predisplaypenalty');
    12: print_param := print_esc('postdisplaypenalty');
    13: print_param := print_esc('interlinepenalty');
    14: print_param := print_esc('doublehyphendemerits');
    15: print_param := print_esc('finalhyphendemerits');
    16: print_param := print_esc('adjdemerits');
    17: print_param := print_esc('mag');
    18: print_param := print_esc('delimiterfactor');
    19: print_param := print_esc('looseness');
    20: print_param := print_esc('time');
    21: print_param := print_esc('day');
    22: print_param := print_esc('month');
    23: print_param := print_esc('year');
    24: print_param := print_esc('showboxbreadth');
    25: print_param := print_esc('showboxdepth');
    26: print_param := print_esc('hbadness');
    27: print_param := print_esc('vbadness');
    28: print_param := print_esc('pausing');
    29: print_param := print_esc('tracingonline');
    30: print_param := print_esc('tracingmacros');
    31: print_param := print_esc('tracingstats');
    32: print_param := print_esc('tracingparagraphs');
    33: print_param := print_esc('tracingpages');
    34: print_param := print_esc('tracingoutput');
    35: print_param := print_esc('tracinglostchars');
    36: print_param := print_esc('tracingcommands');
    37: print_param := print_esc('tracingrestores');
    38: print_param := print_esc('uchyph');
    39: print_param := print_esc('outputpenalty');
    40: print_param := print_esc('maxdeadcycles');
    41: print_param := print_esc('hangafter');
    42: print_param := print_esc('floatingpenalty');
    43: print_param := print_esc('globaldefs');
    44: print_param := print_esc('fam');
    45: print_param := print_esc('escapechar');
    46: print_param := print_esc('defaulthyphenchar');
    47: print_param := print_esc('defaultskewchar');
    48: print_param := print_esc('endlinechar');
    49: print_param := print_esc('newlinechar');
    50: print_param := print_esc('language');
    51: print_param := print_esc('lefthyphenmin');
    52: print_param := print_esc('righthyphenmin');
    53: print_param := print_esc('holdinginserts');
    54: print_param := print_esc('errorcontextlines');
    else print_param := '[unknown integer parameter!]';
  end;
end;
{:237}

function print_length_param(Code: int32) : shortstring;
begin
  case Code-dimen_base of
    0: print_length_param := print_esc('parindent');
    1: print_length_param := print_esc('mathsurround');
    2: print_length_param := print_esc('lineskiplimit');
    3: print_length_param := print_esc('hsize');
    4: print_length_param := print_esc('vsize');
    5: print_length_param := print_esc('maxdepth');
    6: print_length_param := print_esc('splitmaxdepth');
    7: print_length_param := print_esc('boxmaxdepth');
    8: print_length_param := print_esc('hfuzz');
    9: print_length_param := print_esc('vfuzz');
    10: print_length_param := print_esc('delimitershortfall');
    11: print_length_param := print_esc('nulldelimiterspace');
    12: print_length_param := print_esc('scriptspace');
    13: print_length_param := print_esc('predisplaysize');
    14: print_length_param := print_esc('displaywidth');
    15: print_length_param := print_esc('displayindent');
    16: print_length_param := print_esc('overfullrule');
    17: print_length_param := print_esc('hangindent');
    18: print_length_param := print_esc('hoffset');
    19: print_length_param := print_esc('voffset');
    20: print_length_param := print_esc('emergencystretch');
    ELSE print_length_param := '[unknown dimen parameter!]';
  end;
end;

function chr_cmd(Name: shortstring; ChrCode: HALFWORD) : shortstring;
begin
  chr_cmd := Name + GetString(ChrCode);
end;

{@ The |print_cmd_chr| routine prints a symbolic interpretation of a
command code and its modifier. This is used in certain "'You can't"
error messages, and in the implementation of diagnostic routines like
\show.

The body of |print_cmd_chr| is a rather tedious listing of print
commands, and most of it is essentially an inverse to the |primitive|
routine that enters a \TeX\ primitive into |eqtb|. Therefore much of
this procedure appears elsewhere in the program,
together with the corresponding |primitive| calls.}

function print_cmd_chr(Cmd: QUARTERWORD; chr_code: HALFWORD) : shortstring;
var s: shortstring;
begin
  case Cmd of
    left_brace:  print_cmd_chr := chr_cmd('begin-group character ', chr_code);
    right_brace: print_cmd_chr := chr_cmd('end-group character ', chr_code);
    math_shift:  print_cmd_chr := chr_cmd('math shift character ', chr_code);
    mac_param:   print_cmd_chr := chr_cmd('macro parameter character ', chr_code);
    sup_mark:    print_cmd_chr := chr_cmd('superscript character ', chr_code);
    sub_mark:    print_cmd_chr := chr_cmd('subscript character ', chr_code);
    endv:        print_cmd_chr := 'end of alignment template';
    spacer:      print_cmd_chr := chr_cmd('blank space ', chr_code);
    letter:      print_cmd_chr := chr_cmd('the letter ', chr_code);
    other_char:  print_cmd_chr := chr_cmd('the character ', chr_code);



    0: print_cmd_chr := print_esc('relax');

    4: IF chr_code=256 THEN print_cmd_chr := print_esc('span')
                       ELSE print_cmd_chr := 'alignment tab character ' + GetString(chr_code);
    5: IF chr_code=257 THEN print_cmd_chr := print_esc('cr')
                       ELSE print_cmd_chr := print_esc('crcr');

    13: print_cmd_chr := print_esc('par');
    14: IF chr_code=1 THEN print_cmd_chr := print_esc('dump')
                      ELSE print_cmd_chr := print_esc('end');
    15: print_cmd_chr := print_esc('delimiter');
    16: print_cmd_chr := print_esc('char');
    17: print_cmd_chr := print_esc('mathchar');
    18: print_cmd_chr := print_esc('mark');
    19: CASE chr_code OF 
          1: print_cmd_chr := print_esc('showbox');
          2: print_cmd_chr := print_esc('showthe');
          3: print_cmd_chr := print_esc('showlists');
          ELSE print_cmd_chr := print_esc('show');
        end;
    20: CASE chr_code OF 
          0: print_cmd_chr := print_esc('box');
          1: print_cmd_chr := print_esc('copy');
          2: print_cmd_chr := print_esc('lastbox');
          3: print_cmd_chr := print_esc('vsplit');
          4: print_cmd_chr := print_esc('vtop');
          5: print_cmd_chr := print_esc('vbox');
          ELSE print_cmd_chr := print_esc('hbox')
        END;
    21: IF chr_code=1 THEN print_cmd_chr := print_esc('moveleft')
                      ELSE print_cmd_chr := print_esc('moveright');
    22: IF chr_code=1 THEN print_cmd_chr := print_esc('raise')
                      ELSE print_cmd_chr := print_esc('lower');
    23: IF chr_code=1 THEN print_cmd_chr := print_esc('unhcopy')
                      ELSE print_cmd_chr := print_esc('unhbox');
    24: IF chr_code=1 THEN print_cmd_chr := print_esc('unvcopy')
                      ELSE print_cmd_chr := print_esc('unvbox');
    25: IF      chr_code=10 THEN print_cmd_chr := print_esc('unskip')
        ELSE IF chr_code=11 THEN print_cmd_chr := print_esc('unkern')
                            ELSE print_cmd_chr := print_esc('unpenalty');
    26: CASE chr_code OF 
          4: print_cmd_chr := print_esc('hskip');
          0: print_cmd_chr := print_esc('hfil');
          1: print_cmd_chr := print_esc('hfill');
          2: print_cmd_chr := print_esc('hss');
          ELSE print_cmd_chr := print_esc('hfilneg')
        END;
    27: CASE chr_code OF 
          4: print_cmd_chr := print_esc('vskip');
          0: print_cmd_chr := print_esc('vfil');
          1: print_cmd_chr := print_esc('vfill');
          2: print_cmd_chr := print_esc('vss');
          ELSE print_cmd_chr := print_esc('vfilneg')
        END;
    28: print_cmd_chr := print_esc('mskip');
    29: print_cmd_chr := print_esc('kern');
    30: print_cmd_chr := print_esc('mkern');
    31: IF      chr_code=100 THEN print_cmd_chr := print_esc('leaders')
        ELSE IF chr_code=101 THEN print_cmd_chr := print_esc('cleaders')
        ELSE IF chr_code=102 THEN print_cmd_chr := print_esc('xleaders')
                             ELSE print_cmd_chr := print_esc('shipout');
    32: print_cmd_chr := print_esc('halign');
    33: print_cmd_chr := print_esc('valign');
    34: print_cmd_chr := print_esc('noalign');
    35: print_cmd_chr := print_esc('vrule');
    36: print_cmd_chr := print_esc('hrule');
    37: print_cmd_chr := print_esc('insert');
    38: print_cmd_chr := print_esc('vadjust');
    39: print_cmd_chr := print_esc('ignorespaces');
    40: print_cmd_chr := print_esc('afterassignment');
    41: print_cmd_chr := print_esc('aftergroup');
    42: print_cmd_chr := print_esc('penalty');
    43: IF chr_code=0 THEN print_cmd_chr := print_esc('noindent')
                      ELSE print_cmd_chr := print_esc('indent');
    44: print_cmd_chr := print_esc('/');
    45: print_cmd_chr := print_esc('accent');
    46: print_cmd_chr := print_esc('mathaccent');
    47: IF chr_code=1 THEN print_cmd_chr := print_esc('-')
                      ELSE print_cmd_chr := print_esc('discretionary');
    48: IF chr_code=1 THEN print_cmd_chr := print_esc('leqno')
                      ELSE print_cmd_chr := print_esc('eqno');
    49: IF chr_code=30 THEN print_cmd_chr := print_esc('left')
                       ELSE print_cmd_chr := print_esc('right');
    50: CASE chr_code OF 
          16: print_cmd_chr := print_esc('mathord');
          17: print_cmd_chr := print_esc('mathop');
          18: print_cmd_chr := print_esc('mathbin');
          19: print_cmd_chr := print_esc('mathrel');
          20: print_cmd_chr := print_esc('mathopen');
          21: print_cmd_chr := print_esc('mathclose');
          22: print_cmd_chr := print_esc('mathpunct');
          23: print_cmd_chr := print_esc('mathinner');
          26: print_cmd_chr := print_esc('underline');
          ELSE print_cmd_chr := print_esc('overline')
        END;
    51: IF      chr_code=1 THEN print_cmd_chr := print_esc('limits')
        ELSE IF chr_code=2 THEN print_cmd_chr := print_esc('nolimits')
                           ELSE print_cmd_chr := print_esc('displaylimits');
    52: CASE chr_code OF 
          1: print_cmd_chr := print_esc('over');
          2: print_cmd_chr := print_esc('atop');
          3: print_cmd_chr := print_esc('abovewithdelims');
          4: print_cmd_chr := print_esc('overwithdelims');
          5: print_cmd_chr := print_esc('atopwithdelims');
          ELSE print_cmd_chr := print_esc('above')
        END;
    53: print_cmd_chr := print_style(chr_code);
    54: print_cmd_chr := print_esc('mathchoice');
    55: print_cmd_chr := print_esc('nonscript');
    56: print_cmd_chr := print_esc('vcenter');

    58: IF chr_code=0    THEN print_cmd_chr := print_esc('message')
                         ELSE print_cmd_chr := print_esc('errmessage');
    57: IF chr_code=4239 THEN print_cmd_chr := print_esc('lowercase')
                         ELSE print_cmd_chr := print_esc('uppercase');
    59: CASE chr_code OF 
          0: print_cmd_chr := print_esc('openout');
          1: print_cmd_chr := print_esc('write');
          2: print_cmd_chr := print_esc('closeout');
          3: print_cmd_chr := print_esc('special');
          4: print_cmd_chr := print_esc('immediate');
          5: print_cmd_chr := print_esc('setlanguage');
          ELSE print_str('[unknown extension!]')
        END;
    60: IF chr_code=0 THEN print_cmd_chr := print_esc('closein')
                      ELSE print_cmd_chr := print_esc('openin');
    61: print_cmd_chr := print_esc('begingroup');
    62: print_cmd_chr := print_esc('endgroup');
    63: print_cmd_chr := print_esc('omit');
    64: print_cmd_chr := print_esc(' ');
    65: print_cmd_chr := print_esc('noboundary');
    66: print_cmd_chr := print_esc('radical');
    67: print_cmd_chr := print_esc('endcsname');
    68: print_cmd_chr := print_esc('char') + print_hex(chr_code);
    69: print_cmd_chr := print_esc('mathchar') + print_hex(chr_code);
    70: CASE chr_code OF 
          0: print_cmd_chr := print_esc('lastpenalty');
          1: print_cmd_chr := print_esc('lastkern');
          2: print_cmd_chr := print_esc('lastskip');
          3: print_cmd_chr := print_esc('inputlineno');
          ELSE print_cmd_chr := print_esc('badness')
        END;
    71: print_cmd_chr := print_esc('toks');
    assign_toks:{72} begin
        if chr_code>=toks_base then
          print_cmd_chr := print_esc('toks') + print_int(chr_code-3422)
        else case chr_code of
          output_routine_loc: print_cmd_chr := print_esc('output');
          every_par_loc:      print_cmd_chr := print_esc('everypar');
          every_math_loc:     print_cmd_chr := print_esc('everymath');
          every_display_loc:  print_cmd_chr := print_esc('everydisplay');
          every_hbox_loc:     print_cmd_chr := print_esc('everyhbox');
          every_vbox_loc:     print_cmd_chr := print_esc('everyvbox');
          every_job_loc:      print_cmd_chr := print_esc('everyjob');
          every_cr_loc:       print_cmd_chr := print_esc('everycr');
          else                print_cmd_chr := print_esc('errhelp');
        end;
      end;
    assign_int:{73} begin
        if chr_code<count_base then
          print_cmd_chr := print_param(chr_code)
        else
          print_cmd_chr := print_esc('count') + print_int(chr_code-count_base);
      end;
    assign_dimen:{74} begin
        if chr_code<scaled_base then
          print_cmd_chr := print_length_param(chr_code)
        else
          print_cmd_chr := print_esc('dimen') + print_int(chr_code-scaled_base);
      end;
    assign_glue, {75}
    assign_mu_glue:{76} begin
        if chr_code < skip_base then 
          print_cmd_chr := print_skip_param(chr_code-glue_base)
        else if chr_code < mu_skip_base then 
          print_cmd_chr := print_esc('skip') + print_int(chr_code-skip_base)
        else 
          print_cmd_chr := print_esc('skip') + print_int(chr_code-mu_skip_base);
      end;
    77: print_cmd_chr := print_esc('fontdimen');
    78: IF chr_code=0 THEN print_cmd_chr := print_esc('hyphenchar')
                      ELSE print_cmd_chr := print_esc('skewchar');
    79: IF chr_code=1 THEN print_cmd_chr := print_esc('prevdepth')
                      ELSE print_cmd_chr := print_esc('spacefactor');
    80: print_cmd_chr := print_esc('prevgraf');
    81: CASE chr_code OF 
          0: print_cmd_chr := print_esc('pagegoal');
          1: print_cmd_chr := print_esc('pagetotal');
          2: print_cmd_chr := print_esc('pagestretch');
          3: print_cmd_chr := print_esc('pagefilstretch');
          4: print_cmd_chr := print_esc('pagefillstretch');
          5: print_cmd_chr := print_esc('pagefilllstretch');
          6: print_cmd_chr := print_esc('pageshrink');
          ELSE print_cmd_chr := print_esc('pagedepth')
        END;
    82: IF chr_code=0 THEN print_cmd_chr := print_esc('deadcycles')
                      ELSE print_cmd_chr := print_esc('insertpenalties');
    83: IF      chr_code=1 THEN print_cmd_chr := print_esc('wd')
        ELSE IF chr_code=3 THEN print_cmd_chr := print_esc('ht')
                           ELSE print_cmd_chr := print_esc('dp');
    84: print_cmd_chr := print_esc('parshape');
    85: IF      chr_code=3983 THEN print_cmd_chr := print_esc('catcode')
        ELSE IF chr_code=5007 THEN print_cmd_chr := print_esc('mathcode')
        ELSE IF chr_code=4239 THEN print_cmd_chr := print_esc('lccode')
        ELSE IF chr_code=4495 THEN print_cmd_chr := print_esc('uccode')
        ELSE IF chr_code=4751 THEN print_cmd_chr := print_esc('sfcode')
                              ELSE print_cmd_chr := print_esc('delcode');
    86: if      chr_code=3935 then print_cmd_chr := print_esc('textfont')
        else if chr_code=3951 then print_cmd_chr := print_esc('scriptfont')
                              else print_cmd_chr := print_esc('scriptscriptfont');
    87: BEGIN
          s := 'select font ' + PrintableStr(GetString(FONTNAME[chr_code]));
          IF FONTSIZE[chr_code]<>FONTDSIZE[chr_code] THEN
            print_cmd_chr := s + ' at ' + print_scaled(FONTSIZE[chr_code]) + 'pt'
          ELSE
            print_cmd_chr := s;
        END;
    88: print_cmd_chr := print_esc('font');
    89: IF      chr_code=0 THEN print_cmd_chr := print_esc('count')
        ELSE IF chr_code=1 THEN print_cmd_chr := print_esc('dimen')
        ELSE IF chr_code=2 THEN print_cmd_chr := print_esc('skip')
                           ELSE print_cmd_chr := print_esc('muskip');
    90: print_cmd_chr := print_esc('advance');
    91: print_cmd_chr := print_esc('multiply');
    92: print_cmd_chr := print_esc('divide');
    93: IF      chr_code=1 THEN print_cmd_chr := print_esc('long')
        ELSE IF chr_code=2 THEN print_cmd_chr := print_esc('outer')
                           ELSE print_cmd_chr := print_esc('global');
    94: IF chr_code<>0     THEN print_cmd_chr := print_esc('futurelet')
                           ELSE print_cmd_chr := print_esc('let');
    95: CASE chr_code OF 
          0: print_cmd_chr := print_esc('chardef');
          1: print_cmd_chr := print_esc('mathchardef');
          2: print_cmd_chr := print_esc('countdef');
          3: print_cmd_chr := print_esc('dimendef');
          4: print_cmd_chr := print_esc('skipdef');
          5: print_cmd_chr := print_esc('muskipdef');
          ELSE print_cmd_chr := print_esc('toksdef')
        END;
    96: print_cmd_chr := print_esc('read');
    97: IF      chr_code=0 THEN print_cmd_chr := print_esc('def')
        ELSE IF chr_code=1 THEN print_cmd_chr := print_esc('gdef')
        ELSE IF chr_code=2 THEN print_cmd_chr := print_esc('edef')
                           ELSE print_cmd_chr := print_esc('xdef');
    98: print_cmd_chr := print_esc('setbox');
    99: IF chr_code=1      THEN print_cmd_chr := print_esc('patterns')
                           ELSE print_cmd_chr := print_esc('hyphenation');
    100: CASE chr_code OF 
           0: print_cmd_chr := print_esc('batchmode');
           1: print_cmd_chr := print_esc('nonstopmode');
           2: print_cmd_chr := print_esc('scrollmode');
           ELSE print_cmd_chr := print_esc('errorstopmode');
         END;
    101: print_cmd_chr := 'undefined';
    102: print_cmd_chr := print_esc('expandafter');
    103: print_cmd_chr := print_esc('noexpand');
    104: IF chr_code=0     THEN print_cmd_chr := print_esc('input')
                           ELSE print_cmd_chr := print_esc('endinput');
    105: CASE chr_code OF 
           1: print_cmd_chr := print_esc('ifcat');
           2: print_cmd_chr := print_esc('ifnum');
           3: print_cmd_chr := print_esc('ifdim');
           4: print_cmd_chr := print_esc('ifodd');
           5: print_cmd_chr := print_esc('ifvmode');
           6: print_cmd_chr := print_esc('ifhmode');
           7: print_cmd_chr := print_esc('ifmmode');
           8: print_cmd_chr := print_esc('ifinner');
           9: print_cmd_chr := print_esc('ifvoid');
           10: print_cmd_chr := print_esc('ifhbox');
           11: print_cmd_chr := print_esc('ifvbox');
           12: print_cmd_chr := print_esc('ifx');
           13: print_cmd_chr := print_esc('ifeof');
           14: print_cmd_chr := print_esc('iftrue');
           15: print_cmd_chr := print_esc('iffalse');
           16: print_cmd_chr := print_esc('ifcase');
           ELSE print_cmd_chr := print_esc('if')
         END;
    106: IF      chr_code=2 THEN print_cmd_chr := print_esc('fi')
         ELSE IF chr_code=4 THEN print_cmd_chr := print_esc('or')
                            ELSE print_cmd_chr := print_esc('else');
    107: print_cmd_chr := print_esc('csname');
    108: CASE chr_code OF 
           0: print_cmd_chr := print_esc('number');
           1: print_cmd_chr := print_esc('romannumeral');
           2: print_cmd_chr := print_esc('string');
           3: print_cmd_chr := print_esc('meaning');
           4: print_cmd_chr := print_esc('fontname');
           ELSE print_cmd_chr := print_esc('jobname')
         END;
    109: print_cmd_chr := print_esc('the');
    110: CASE chr_code OF 
           1: print_cmd_chr := print_esc('firstmark');
           2: print_cmd_chr := print_esc('botmark');
           3: print_cmd_chr := print_esc('splitfirstmark');
           4: print_cmd_chr := print_esc('splitbotmark');
           ELSE print_cmd_chr := print_esc('topmark')
         END;
    111: print_cmd_chr := 'macro';
    112: print_cmd_chr := print_esc('long macro');
    113: print_cmd_chr := print_esc('outer macro');
    114: print_cmd_chr := print_esc('long') + print_esc('outer macro');
    115: print_cmd_chr := print_esc('outer endtemplate');

    ELSE print_str('[unknown command code!]')
  END;
END;{:298}



{$IFDEF STATS}
PROCEDURE SHOWEQTB(N:HALFWORD);
BEGIN
  IF N<1 THEN print_str('?')
  ELSE IF N<2882 THEN BEGIN
    print_str(sprint_cs(N) + '=' + print_cmd_chr(EQTB[N].HH.B0,EQTB[N].HH.RH));
    IF EQTB[N].HH.B0>=111 THEN BEGIN
      PRINTCHAR(58);
      print_utf8str(show_token_list_simple(MEM[EQTB[N].HH.RH].HH.RH,32));
    END;
  END ELSE IF N<3412 THEN begin
    IF N<2900 THEN BEGIN
      print_str(print_skip_param(N-2882) + '=');
      IF N<2897 THEN print_str(print_spec(EQTB[N].HH.RH, 'pt'))
                ELSE print_str(print_spec(EQTB[N].HH.RH, 'mu'));
    END ELSE IF N<3156 THEN BEGIN
      print_esc_str('skip' + print_int(N-2900) + '=' + print_spec(EQTB[N].HH.RH, 'pt'));
    END ELSE BEGIN
      print_esc_str('muskip' + print_int(N-3156) + '=' + print_spec(EQTB[N].HH.RH, 'mu'));
    END
  end ELSE IF N<5263 THEN begin
    IF N=3412 THEN BEGIN
      print_esc_str('parshape=');
      IF EQTB[3412].HH.RH=0 THEN PRINTCHAR(48)
                            ELSE PRINTINT(MEM[EQTB[3412].HH.RH].HH.LH);
    END ELSE IF N<3422 THEN BEGIN
      print_str(print_cmd_chr(72,N) + '=');
      IF EQTB[N].HH.RH<>0 THEN print_utf8str(show_token_list_simple(MEM[EQTB[N].HH.RH].HH.RH,32));
    END ELSE IF N<3678 THEN BEGIN
      print_esc_str('toks');
      PRINTINT(N-3422);
      PRINTCHAR(61);
      IF EQTB[N].HH.RH<>0 THEN print_utf8str(show_token_list_simple(MEM[EQTB[N].HH.RH].HH.RH,32));
    END ELSE IF N<3934 THEN BEGIN
      print_esc_str('box');
      PRINTINT(N-3678);
      PRINTCHAR(61);
      IF EQTB[N].HH.RH=0 THEN print_str('void')
      ELSE BEGIN
        DEPTHTHRESHO := 0;
        BREADTHMAX := 1;
        SHOWNODELIST(EQTB[N].HH.RH);
      END;
    END ELSE IF N<3983 THEN BEGIN
      IF N=3934 THEN print_str('current font')
      ELSE IF N<3951 THEN BEGIN
        print_esc_str('textfont');
        PRINTINT(N-3935);
      END ELSE IF N<3967 THEN BEGIN
        print_esc_str('scriptfont');
        PRINTINT(N-3951);
      END ELSE BEGIN
        print_esc_str('scriptscriptfont');
        PRINTINT(N-3967);
      END;
      PRINTCHAR(61);
      PRINTESC(HASH[2624+EQTB[N].HH.RH].RH);
    END ELSE IF N<5007 THEN BEGIN
      IF N<4239 THEN BEGIN
        print_esc_str('catcode');
        PRINTINT(N-3983);
      END ELSE IF N<4495 THEN BEGIN
        print_esc_str('lccode');
        PRINTINT(N-4239);
      END ELSE IF N<4751 THEN BEGIN
        print_esc_str('uccode');
        PRINTINT(N-4495);
      END ELSE BEGIN
        print_esc_str('sfcode');
        PRINTINT(N-4751);
      END;
      PRINTCHAR(61);
      PRINTINT(EQTB[N].HH.RH);
    END ELSE BEGIN
      print_esc_str('mathcode');
      PRINTINT(N-5007);
      PRINTCHAR(61);
      PRINTINT(EQTB[N].HH.RH-0);
    END
  end ELSE IF N<5830 THEN BEGIN
    IF N<5318 THEN begin
      print_str(print_param(N))
    end ELSE IF N<5574 THEN BEGIN
      print_esc_str('count');
      PRINTINT(N-5318);
    END ELSE BEGIN
      print_esc_str('delcode');
      PRINTINT(N-5574);
    END;
    PRINTCHAR(61);
    PRINTINT(EQTB[N].INT);
  END ELSE IF N<=6106 THEN BEGIN
    IF N<5851 THEN print_str(print_length_param(N))
    ELSE print_str(print_esc('dimen') + print_int(N-5851));
    print_str('=' + print_scaled(EQTB[N].INT) + 'pt');
  END ELSE PRINTCHAR(63);
END;
{$ENDIF}
{:252}

{299:}
PROCEDURE SHOWCURCMDCH;
BEGIN
  BEGINDIAGNOS;
  print_nl_str('{');
  IF CURLIST.MODEFIELD<>SHOWNMODE THEN
    BEGIN
      print_str(print_mode(CURLIST.MODEFIELD));
      print_str(': ');
      SHOWNMODE := CURLIST.MODEFIELD;
    END;
  print_str(print_cmd_chr(CURCMD,CURCHR));
  PRINTCHAR(125);
  ENDDIAGNOSTI(FALSE);
END;
{:299}


















{ ----------------------------------------------------------------------
  Syntactic routines
  ---------------------------------------------------------------------- }





{306:}
PROCEDURE RUNAWAY;

VAR P: HALFWORD;
BEGIN
  IF SCANNERSTATU>1 THEN
    BEGIN
      print_nl_str('Runaway ');
      CASE SCANNERSTATU OF 
        2:
           BEGIN
             print_str('definition');
             P := DEFREF;
           END;
        3:
           BEGIN
             print_str('argument');
             P := 29997;
           END;
        4:
           BEGIN
             print_str('preamble');
             P := 29996;
           END;
        5:
           BEGIN
             print_str('text');
             P := DEFREF;
           END;
      END;
      PRINTCHAR(63);
      PRINTLN;
      print_utf8str(show_token_list_simple(MEM[P].HH.RH,ERRORLINE-10));
    END;
END;
{:306}



{:119}
{120:}
FUNCTION GETAVAIL: HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := AVAIL;
  IF P<>0 THEN AVAIL := MEM[AVAIL].HH.RH
  ELSE
    IF MEMEND<MEMMAX THEN
      BEGIN
        MEMEND := MEMEND+1;
        P := MEMEND;
      END
  ELSE
    BEGIN
      HIMEMMIN := HIMEMMIN-1;
      P := HIMEMMIN;
      IF HIMEMMIN<=LOMEMMAX THEN
        BEGIN   
          RUNAWAY;
          overflow('main memory size', MEMMAX+1-MEMMIN);
        END;
    END;
  MEM[P].HH.RH := 0;{$IFDEF STATS}
  DYNUSED := DYNUSED+1;{$ENDIF}
  GETAVAIL := P;
END;
{:120}

{125:}
FUNCTION GETNODE(S:Int32): HALFWORD;
VAR
  P: HALFWORD;
  Q: HALFWORD;
  R: Int32;
  T: Int32;
BEGIN
  while true do begin
    P := ROVER;
    REPEAT
      Q := P+MEM[P].HH.LH;
      WHILE (MEM[Q].HH.RH=65535) DO BEGIN
        T := MEM[Q+1].HH.RH;
        IF Q=ROVER THEN ROVER := T;
        MEM[T+1].HH.LH := MEM[Q+1].HH.LH;
        MEM[MEM[Q+1].HH.LH+1].HH.RH := T;
        Q := Q+MEM[Q].HH.LH;
      END;
      R := Q-S;
      IF R>P+1 THEN BEGIN
        MEM[P].HH.LH := R-P;
        ROVER := P;
        MEM[R].HH.RH := 0;
{$IFDEF STATS}
        VARUSED := VARUSED+S;
{$ENDIF}
        GETNODE := R;
        exit;
      END;
      IF R=P THEN
        IF MEM[P+1].HH.RH<>P THEN BEGIN
          ROVER := MEM[P+1].HH.RH;
          T := MEM[P+1].HH.LH;
          MEM[ROVER+1].HH.LH := T;
          MEM[T+1].HH.RH := ROVER;
          MEM[R].HH.RH := 0;
{$IFDEF STATS}
          VARUSED := VARUSED+S;
{$ENDIF}
          GETNODE := R;
          exit;
        END{:129};
      MEM[P].HH.LH := Q-P;
      P := MEM[P+1].HH.RH;
    UNTIL P=ROVER;

    IF S=1073741824 THEN BEGIN
      GETNODE := 65535;
      exit;
    END;

    IF (LOMEMMAX+2>=HIMEMMIN) or (LOMEMMAX+2>65535) THEN
      overflow('main memory size', MEMMAX+1-MEMMIN);

    IF HIMEMMIN-LOMEMMAX>=1998
      THEN T := LOMEMMAX+1000
      ELSE T := LOMEMMAX+1+(HIMEMMIN-LOMEMMAX)DIV 2;
    P := MEM[ROVER+1].HH.LH;
    Q := LOMEMMAX;
    MEM[P+1].HH.RH := Q;
    MEM[ROVER+1].HH.LH := Q;
    IF T>65535 THEN T := 65535;
    MEM[Q+1].HH.RH := ROVER;
    MEM[Q+1].HH.LH := P;
    MEM[Q].HH.RH := 65535;
    MEM[Q].HH.LH := T-LOMEMMAX;
    LOMEMMAX := T;
    MEM[LOMEMMAX].HH.RH := 0;
    MEM[LOMEMMAX].HH.LH := 0;
    ROVER := Q;
  end;
END;
{:125}


{136:}
FUNCTION NEWNULLBOX: HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(7);
  MEM[P].HH.B0 := 0;
  MEM[P].HH.B1 := 0;
  MEM[P+1].INT := 0;
  MEM[P+2].INT := 0;
  MEM[P+3].INT := 0;
  MEM[P+4].INT := 0;
  MEM[P+5].HH.RH := 0;
  MEM[P+5].HH.B0 := 0;
  MEM[P+5].HH.B1 := 0;
  MEM[P+6].GR := 0.0;
  NEWNULLBOX := P;
END;
{:136}{139:}
FUNCTION NEWRULE: HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(4);
  MEM[P].HH.B0 := 2;
  MEM[P].HH.B1 := 0;
  MEM[P+1].INT := -1073741824;
  MEM[P+2].INT := -1073741824;
  MEM[P+3].INT := -1073741824;
  NEWRULE := P;
END;
{:139}{144:}
FUNCTION NEWLIGATURE(F,C:QUARTERWORD;Q:HALFWORD): HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(2);
  MEM[P].HH.B0 := 6;
  MEM[P+1].HH.B0 := F;
  MEM[P+1].HH.B1 := C;
  MEM[P+1].HH.RH := Q;
  MEM[P].HH.B1 := 0;
  NEWLIGATURE := P;
END;
FUNCTION NEWLIGITEM(C:QUARTERWORD): HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(2);
  MEM[P].HH.B1 := C;
  MEM[P+1].HH.RH := 0;
  NEWLIGITEM := P;
END;
{:144}{145:}
FUNCTION NEWDISC: HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(2);
  MEM[P].HH.B0 := 7;
  MEM[P].HH.B1 := 0;
  MEM[P+1].HH.LH := 0;
  MEM[P+1].HH.RH := 0;
  NEWDISC := P;
END;{:145}{147:}
FUNCTION NEWMATH(W:SCALED;
                 S:SMALLNUMBER): HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(2);
  MEM[P].HH.B0 := 9;
  MEM[P].HH.B1 := S;
  MEM[P+1].INT := W;
  NEWMATH := P;
END;
{:147}{151:}
FUNCTION NEWSPEC(P:HALFWORD): HALFWORD;

VAR Q: HALFWORD;
BEGIN
  Q := GETNODE(4);
  MEM[Q] := MEM[P];
  MEM[Q].HH.RH := 0;
  MEM[Q+1].INT := MEM[P+1].INT;
  MEM[Q+2].INT := MEM[P+2].INT;
  MEM[Q+3].INT := MEM[P+3].INT;
  NEWSPEC := Q;
END;
{:151}{152:}
FUNCTION NEWPARAMGLUE(N:SMALLNUMBER): HALFWORD;

VAR P: HALFWORD;
  Q: HALFWORD;
BEGIN
  P := GETNODE(2);
  MEM[P].HH.B0 := 10;
  MEM[P].HH.B1 := N+1;
  MEM[P+1].HH.RH := 0;
  Q := {224:}EQTB[2882+N].HH.RH{:224};
  MEM[P+1].HH.LH := Q;
  MEM[Q].HH.RH := MEM[Q].HH.RH+1;
  NEWPARAMGLUE := P;
END;
{:152}{153:}
FUNCTION NEWGLUE(Q:HALFWORD): HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(2);
  MEM[P].HH.B0 := 10;
  MEM[P].HH.B1 := 0;
  MEM[P+1].HH.RH := 0;
  MEM[P+1].HH.LH := Q;
  MEM[Q].HH.RH := MEM[Q].HH.RH+1;
  NEWGLUE := P;
END;
{:153}{154:}
FUNCTION NEWSKIPPARAM(N:SMALLNUMBER): HALFWORD;

VAR P: HALFWORD;
BEGIN
  TEMPPTR := NEWSPEC({224:}EQTB[2882+N].HH.RH{:224});
  P := NEWGLUE(TEMPPTR);
  MEM[TEMPPTR].HH.RH := 0;
  MEM[P].HH.B1 := N+1;
  NEWSKIPPARAM := P;
END;{:154}{156:}
FUNCTION NEWKERN(W:SCALED): HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(2);
  MEM[P].HH.B0 := 11;
  MEM[P].HH.B1 := 0;
  MEM[P+1].INT := W;
  NEWKERN := P;
END;
{:156}{158:}
FUNCTION NEWPENALTY(M:Int32): HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(2);
  MEM[P].HH.B0 := 12;
  MEM[P].HH.B1 := 0;
  MEM[P+1].INT := M;
  NEWPENALTY := P;
END;{:158}


{@ Here is the subroutine that searches the hash table for an identifier
that matches a given string of length |l>1| appearing in |buffer[j..
(j+l-1)]|. If the identifier is found, the corresponding hash table address
is returned. Otherwise, if the global variable |no_new_control_sequence|
is |true|, the dummy address |undefined_control_sequence| is returned.
Otherwise the identifier is inserted into the hash table and its location
is returned.}

function id_lookup(no_new_control_sequence: boolean; J, L:Int32): HALFWORD;
VAR
  H: Int32;
  D: Int32;
  P: HALFWORD;
  K: HALFWORD;
BEGIN
  H := BUFFER[J];
  FOR K:=J+1 TO J+L-1 DO BEGIN
    H := H+H+BUFFER[K];
    WHILE H>=1777 DO H := H-1777;
  END;
  P := H+514;
  WHILE TRUE DO BEGIN
    IF HASH[P].RH>0 THEN
      IF (STRSTART[HASH[P].RH+1]-STRSTART[HASH[P].RH])=L THEN
        IF STREQBUF(HASH[P].RH,J) THEN break;
    IF HASH[P].LH=0 THEN BEGIN
      IF no_new_control_sequence THEN P := undefined_control_sequence{2881}
      ELSE BEGIN

        {@<Insert a new control sequence after |p|, then make |p| point to it@>}
        IF HASH[P].RH>0 THEN BEGIN
          REPEAT
            IF (HASHUSED=514) THEN overflow('hash size', 2100);
            HASHUSED := HASHUSED-1;
          UNTIL HASH[HASHUSED].RH=0;
          HASH[P].LH := HASHUSED;
          P := HASHUSED;
        END;
        IF POOLPTR+L>POOLSIZE THEN overflow('pool size', POOLSIZE-INITPOOLPTR);
        D := (POOLPTR-STRSTART[STRPTR]);
        WHILE POOLPTR>STRSTART[STRPTR] DO BEGIN
          POOLPTR := POOLPTR-1;
          STRPOOL[POOLPTR+L] := STRPOOL[POOLPTR];
        END;
        FOR K:=J TO J+L-1 DO append_char(BUFFER[K]);
        HASH[P].RH := MAKESTRING;
        POOLPTR := POOLPTR+D;
{$IFDEF STATS}
        CSCOUNT := CSCOUNT+1;
{$ENDIF}

      END;
      break;
    END;
    P := HASH[P].LH;
  END;
  id_lookup := P;
END;


{274:}
PROCEDURE NEWSAVELEVEL(C:GROUPCODE);
BEGIN
  IF SAVEPTR>MAXSAVESTACK THEN
    BEGIN
      MAXSAVESTACK := SAVEPTR;
      IF MAXSAVESTACK>SAVESIZE-6 THEN overflow('save size', SAVESIZE);
    END;
  SAVESTACK[SAVEPTR].HH.B0 := 3;
  SAVESTACK[SAVEPTR].HH.B1 := CURGROUP;
  SAVESTACK[SAVEPTR].HH.RH := CURBOUNDARY;
  IF CURLEVEL=255 THEN overflow('grouping levels', 255);
  CURBOUNDARY := SAVEPTR;
  CURLEVEL := CURLEVEL+1;
  SAVEPTR := SAVEPTR+1;
  CURGROUP := C;
END;
{:274}




{123:}
PROCEDURE FLUSHLIST(P:HALFWORD);
VAR Q,R: HALFWORD;
BEGIN
  IF P<>0 THEN
    BEGIN
      R := P;
      REPEAT
        Q := R;
        R := MEM[R].HH.RH;{$IFDEF STATS}
        DYNUSED := DYNUSED-1;{$ENDIF}
      UNTIL R=0;
      MEM[Q].HH.RH := AVAIL;
      AVAIL := P;
    END;
END;
{:123}

{200:}
PROCEDURE DELETETOKENR(P:HALFWORD);
BEGIN
  IF MEM[P].HH.LH=0 THEN FLUSHLIST(P)
  ELSE MEM[P].HH.LH := MEM[P].HH.LH-1;
END;
{:200}

{130:}
PROCEDURE FREENODE(P:HALFWORD;S:HALFWORD);
VAR Q: HALFWORD;
BEGIN
  MEM[P].HH.LH := S;
  MEM[P].HH.RH := 65535;
  Q := MEM[ROVER+1].HH.LH;
  MEM[P+1].HH.LH := Q;
  MEM[P+1].HH.RH := ROVER;
  MEM[ROVER+1].HH.LH := P;
  MEM[Q+1].HH.RH := P;{$IFDEF STATS}
  VARUSED := VARUSED-S;{$ENDIF}
END;
{:130}

{201:}
PROCEDURE DELETEGLUERE(P:HALFWORD);
BEGIN
  IF MEM[P].HH.RH=0 THEN FREENODE(P,4)
  ELSE MEM[P].HH.RH := MEM[P].HH.RH-1;
END;
{:201}

{202:}
PROCEDURE FLUSHNODELIS(P:HALFWORD);
VAR Q: HALFWORD;
BEGIN
  WHILE P<>0 DO BEGIN
    Q := MEM[P].HH.RH;
    IF (P>=HIMEMMIN) THEN BEGIN
      MEM[P].HH.RH := AVAIL;
      AVAIL := P;
{$IFDEF STATS}
      DYNUSED := DYNUSED-1;
{$ENDIF}
    END ELSE BEGIN
      CASE MEM[P].HH.B0 OF
        0,1,13: BEGIN
              FLUSHNODELIS(MEM[P+5].HH.RH);
              FREENODE(P,7);
            END;
        2:  BEGIN
              FREENODE(P,4);
            END;
        3:  BEGIN
              FLUSHNODELIS(MEM[P+4].HH.LH);
              DELETEGLUERE(MEM[P+4].HH.RH);
              FREENODE(P,5);
            END;
        8:  BEGIN
              CASE MEM[P].HH.B1 OF
                0: FREENODE(P,3);
                1,3: BEGIN
                      DELETETOKENR(MEM[P+1].HH.RH);
                      FREENODE(P,2);
                    END;
                2,4: FREENODE(P,2);
                ELSE confusion_str('ext3')
              END;
            END;
        10: BEGIN
              IF MEM[MEM[P+1].HH.LH].HH.RH=0
                THEN FREENODE(MEM[P+1].HH.LH,4)
                ELSE MEM[MEM[P+1].HH.LH].HH.RH := MEM[MEM[P+1].HH.LH].HH.RH-1;
              IF MEM[P+1].HH.RH<>0 THEN FLUSHNODELIS(MEM[P+1].HH.RH);
              FREENODE(P,2);
            END;
        11,9,12: begin
              FREENODE(P,2);
            end;
        6:  begin
              FLUSHNODELIS(MEM[P+1].HH.RH);
              FREENODE(P,2);
            end;
        4:  begin
              DELETETOKENR(MEM[P+1].INT);
              FREENODE(P,2);
            end;
        7:  BEGIN
              FLUSHNODELIS(MEM[P+1].HH.LH);
              FLUSHNODELIS(MEM[P+1].HH.RH);
              FREENODE(P,2);
            END;
        5:  begin
              FLUSHNODELIS(MEM[P+1].INT);{698:}
              FREENODE(P,2);
            end;
        14: BEGIN
              FREENODE(P,3);
            END;
        15: BEGIN
              FLUSHNODELIS(MEM[P+1].HH.LH);
              FLUSHNODELIS(MEM[P+1].HH.RH);
              FLUSHNODELIS(MEM[P+2].HH.LH);
              FLUSHNODELIS(MEM[P+2].HH.RH);
              FREENODE(P,3);
            END;
        16,17,18,19,20,21,22,23,24,27,26,29,28:
            BEGIN
              IF MEM[P+1].HH.RH>=2 THEN
                FLUSHNODELIS(MEM[P+1].HH.LH);
              IF MEM[P+2].HH.RH>=2 THEN FLUSHNODELIS(MEM[P+2].HH.LH);
              IF MEM[P+3].HH.RH>=2 THEN FLUSHNODELIS(MEM[P+3].HH.LH);
              IF MEM[P].HH.B0=24 THEN FREENODE(P,5)
              ELSE IF MEM[P].HH.B0=28 THEN FREENODE(P,5)
              ELSE FREENODE(P,4);
            END;
        30,31: BEGIN
              FREENODE(P,4);
            END;
        25: BEGIN
              FLUSHNODELIS(MEM[P+2].HH.LH);
              FLUSHNODELIS(MEM[P+3].HH.LH);
              FREENODE(P,6);
            END;
        ELSE confusion_str('flushing');
      END;
    END;
    P := Q;
  END;
END;
{:202}


{204:}
FUNCTION COPYNODELIST(P:HALFWORD): HALFWORD;
VAR
  H: HALFWORD;
  Q: HALFWORD;
  R: HALFWORD;
  WORDS: 0..5;
BEGIN
  H := GETAVAIL;
  Q := H;
  WHILE P<>0 DO
    BEGIN{205:}
      WORDS := 1;
      IF (P>=HIMEMMIN)THEN R := GETAVAIL
      ELSE{206:}
        CASE MEM[P].HH.B0 OF 
          0,1,13:
                  BEGIN
                    R := GETNODE(7);
                    MEM[R+6] := MEM[P+6];
                    MEM[R+5] := MEM[P+5];
                    MEM[R+5].HH.RH := COPYNODELIST(MEM[P+5].HH.RH);
                    WORDS := 5;
                  END;
          2:
             BEGIN
               R := GETNODE(4);
               WORDS := 4;
             END;
          3:
             BEGIN
               R := GETNODE(5);
               MEM[R+4] := MEM[P+4];
               MEM[MEM[P+4].HH.RH].HH.RH := MEM[MEM[P+4].HH.RH].HH.RH+1;
               MEM[R+4].HH.LH := COPYNODELIST(MEM[P+4].HH.LH);
               WORDS := 4;
             END;
          8:{1357:}
             CASE MEM[P].HH.B1 OF 
               0:
                  BEGIN
                    R := GETNODE(3);
                    WORDS := 3;
                  END;
               1,3:
                    BEGIN
                      R := GETNODE(2);
                      MEM[MEM[P+1].HH.RH].HH.LH := MEM[MEM[P+1].HH.RH].HH.LH+1;
                      WORDS := 2;
                    END;
               2,4:
                    BEGIN
                      R := GETNODE(2);
                      WORDS := 2;
                    END;
               ELSE confusion_str('ext2')
             END{:1357};
          10:
              BEGIN
                R := GETNODE(2);
                MEM[MEM[P+1].HH.LH].HH.RH := MEM[MEM[P+1].HH.LH].HH.RH+1;
                MEM[R+1].HH.LH := MEM[P+1].HH.LH;
                MEM[R+1].HH.RH := COPYNODELIST(MEM[P+1].HH.RH);
              END;
          11,9,12:
                   BEGIN
                     R := GETNODE(2);
                     WORDS := 2;
                   END;
          6:
             BEGIN
               R := GETNODE(2);
               MEM[R+1] := MEM[P+1];
               MEM[R+1].HH.RH := COPYNODELIST(MEM[P+1].HH.RH);
             END;
          7:
             BEGIN
               R := GETNODE(2);
               MEM[R+1].HH.LH := COPYNODELIST(MEM[P+1].HH.LH);
               MEM[R+1].HH.RH := COPYNODELIST(MEM[P+1].HH.RH);
             END;
          4:
             BEGIN
               R := GETNODE(2);
               MEM[MEM[P+1].INT].HH.LH := MEM[MEM[P+1].INT].HH.LH+1;
               WORDS := 2;
             END;
          5:
             BEGIN
               R := GETNODE(2);
               MEM[R+1].INT := COPYNODELIST(MEM[P+1].INT);
             END;
          ELSE confusion_str('copying')
        END{:206};
      WHILE WORDS>0 DO
        BEGIN
          WORDS := WORDS-1;
          MEM[R+WORDS] := MEM[P+WORDS];
        END{:205};
      MEM[Q].HH.RH := R;
      Q := R;
      P := MEM[P].HH.RH;
    END;
  MEM[Q].HH.RH := 0;
  Q := MEM[H].HH.RH;
  BEGIN
    MEM[H].HH.RH := AVAIL;
    AVAIL := H;{$IFDEF STATS}
    DYNUSED := DYNUSED-1;
{$ENDIF}
  END;
  COPYNODELIST := Q;
END;
{:204}




{275:}
PROCEDURE EQDESTROY(W:MEMORYWORD);

VAR Q: HALFWORD;
BEGIN
  CASE W.HH.B0 OF 
    111,112,113,114: DELETETOKENR(W.HH.RH);
    117: DELETEGLUERE(W.HH.RH);
    118:
         BEGIN
           Q := W.HH.RH;
           IF Q<>0 THEN FREENODE(Q,MEM[Q].HH.LH+MEM[Q].HH.LH+1);
         END;
    119: FLUSHNODELIS(W.HH.RH);
    ELSE
  END;
END;
{:275}{276:}
PROCEDURE EQSAVE(P:HALFWORD;L:QUARTERWORD);
BEGIN
  IF SAVEPTR>MAXSAVESTACK THEN
    BEGIN
      MAXSAVESTACK := SAVEPTR;
      IF MAXSAVESTACK>SAVESIZE-6 THEN overflow('save size', SAVESIZE);
    END;
  IF L=0 THEN SAVESTACK[SAVEPTR].HH.B0 := 1
  ELSE
    BEGIN
      SAVESTACK[SAVEPTR] := 
                            EQTB[P];
      SAVEPTR := SAVEPTR+1;
      SAVESTACK[SAVEPTR].HH.B0 := 0;
    END;
  SAVESTACK[SAVEPTR].HH.B1 := L;
  SAVESTACK[SAVEPTR].HH.RH := P;
  SAVEPTR := SAVEPTR+1;
END;{:276}{277:}
PROCEDURE EQDEFINE(P:HALFWORD;
                   T:QUARTERWORD;E:HALFWORD);
BEGIN
  IF EQTB[P].HH.B1=CURLEVEL THEN EQDESTROY(EQTB[P])
  ELSE
    IF CURLEVEL>
       1 THEN EQSAVE(P,EQTB[P].HH.B1);
  EQTB[P].HH.B1 := CURLEVEL;
  EQTB[P].HH.B0 := T;
  EQTB[P].HH.RH := E;
END;{:277}{278:}
PROCEDURE EQWORDDEFINE(P:HALFWORD;
                       W:Int32);
BEGIN
  IF XEQLEVEL[P]<>CURLEVEL THEN
    BEGIN
      EQSAVE(P,XEQLEVEL[P]);
      XEQLEVEL[P] := CURLEVEL;
    END;
  EQTB[P].INT := W;
END;
{:278}{279:}
PROCEDURE GEQDEFINE(P:HALFWORD;T:QUARTERWORD;E:HALFWORD);
BEGIN
  EQDESTROY(EQTB[P]);
  EQTB[P].HH.B1 := 1;
  EQTB[P].HH.B0 := T;
  EQTB[P].HH.RH := E;
END;
PROCEDURE GEQWORDDEFIN(P:HALFWORD;W:Int32);
BEGIN
  EQTB[P].INT := W;
  XEQLEVEL[P] := 1;
END;
{:279}{280:}
PROCEDURE SAVEFORAFTER(T:HALFWORD);
BEGIN
  IF CURLEVEL>1 THEN
    BEGIN
      IF SAVEPTR>MAXSAVESTACK THEN
        BEGIN
          MAXSAVESTACK := SAVEPTR;
          IF MAXSAVESTACK>SAVESIZE-6 THEN overflow('save size', SAVESIZE);
        END;
      SAVESTACK[SAVEPTR].HH.B0 := 2;
      SAVESTACK[SAVEPTR].HH.B1 := 0;
      SAVESTACK[SAVEPTR].HH.RH := T;
      SAVEPTR := SAVEPTR+1;
    END;
END;
{:280}

{281:}
{284:}
{$IFDEF STATS}
PROCEDURE restore_trace_str(P:HALFWORD; s: shortstring);
BEGIN
  BEGINDIAGNOS;
  PRINTCHAR(123);
  print_str(s);
  PRINTCHAR(32);
  SHOWEQTB(P);
  PRINTCHAR(125);
  ENDDIAGNOSTI(FALSE);
END;
{$ENDIF}
{:284}






















{ ----------------------------------------------------------------------
  Interactive error handling
  ---------------------------------------------------------------------- }


PROCEDURE GETTOKEN; FORWARD;


{82:}
PROCEDURE ERROR;
VAR
  C: ASCIICODE;
  S1,S2,S3,S4: Int32;
BEGIN
  IF HISTORY<2 THEN HISTORY := 2;
  PRINTCHAR(46);
  SHOWCONTEXT;
  IF INTERACTION=3 THEN begin
    WHILE TRUE DO BEGIN
      IF INTERACTION<>3 THEN exit;
      CLEARFORERRO;
      print_str('? ');
      TERMINPUT;
      IF LAST=FIRST THEN exit;
      C := BUFFER[FIRST];
      IF C>=97 THEN C := C-32;

{84:}
      CASE C OF 
        48,49,50,51,52,53,54,55,56,57:
            IF DELETIONSALL THEN BEGIN
              {88:}
              S1 := CURTOK;
              S2 := CURCMD;
              S3 := CURCHR;
              S4 := ALIGNSTATE;
              ALIGNSTATE := 1000000;
              OKTOINTERRUP := FALSE;
              IF (LAST>FIRST+1) AND(BUFFER[FIRST+1]>=48) AND (BUFFER[FIRST+1]<=57) 
                THEN C := C*10+BUFFER[FIRST+1]-48*11
                ELSE C := C-48;
              WHILE C>0 DO BEGIN
                GETTOKEN;
                C := C-1;
              END;
              CURTOK := S1;
              CURCMD := S2;
              CURCHR := S3;
              ALIGNSTATE := S4;
              OKTOINTERRUP := TRUE;
              help2('I have just deleted some text, as you asked.',
                    'You can now delete more, or insert, or whatever.');
              SHOWCONTEXT;
              continue;
              {:88}
            END;

{$IFDEF DEBUGGING}
        68:
          BEGIN
            DEBUGHELP;
            continue;
          END;
{$ENDIF}
        69:
          IF (BASEPTR>0) and (INPUTSTACK[BASEPTR].NAMEFIELD>=256) THEN BEGIN
            print_nl_str('You want to edit file ');
            SLOWPRINT(INPUTSTACK[BASEPTR].NAMEFIELD);
            print_str(' at line ');
            PRINTINT(LINE);
            INTERACTION := 2;
            close_files_and_terminate;
          END;

        72:{89:}
          BEGIN
            IF USEERRHELP THEN BEGIN
              GIVEERRHELP;
              USEERRHELP := FALSE;
            END ELSE BEGIN
              IF HELPPTR=0 THEN BEGIN
                help2('Sorry, I don''t know how to help in this situation.',
                      'Maybe you should try asking a human?');
              END;
              REPEAT
                HELPPTR := HELPPTR-1;
                print_str(help_line[HELPPTR]);
                PRINTLN;
              UNTIL HELPPTR=0;
            END;
            help4('Sorry, I already gave what help I could...',
                  'Maybe you should try asking a human?',
                  'An error might have occurred before I noticed any problems.',
                  '``If all else fails, read the instructions.''''');
            continue;
          END;{:89}

          73:{87:}
              BEGIN
                BEGINFILEREA;
                IF LAST>FIRST+1 THEN
                  BEGIN
                    CURINPUT.LOCFIELD := FIRST+1;
                    BUFFER[FIRST] := 32;
                  END
                ELSE
                  BEGIN
                    BEGIN;
                      print_str('insert>');
                      TERMINPUT;
                    END;
                    CURINPUT.LOCFIELD := FIRST;
                  END;
                FIRST := LAST;
                CURINPUT.LIMITFIELD := LAST-1;
                exit;
              END{:87};
          81,82,83:{86:}
                    BEGIN
                      ERRORCOUNT := 0;
                      INTERACTION := 0+C-81;
                      print_str('OK, entering ');
                      CASE C OF 
                        81:
                            BEGIN
                              print_esc_str('batchmode');
                              SELECTOR := SELECTOR-1;
                            END;
                        82: print_esc_str('nonstopmode');
                        83: print_esc_str('scrollmode');
                      END;
                      print_str('...');
                      PRINTLN;
                      FLUSH(OUTPUT);
                      exit;
                    END{:86};
          88:
              BEGIN
                INTERACTION := 2;
                close_files_and_terminate;
              END;
          ELSE
        END;
{85:}
        BEGIN
          print_str('Type <return> to proceed, S to scroll future error messages,');
          print_nl_str('R to run without stopping, Q to run quietly,');
          print_nl_str('I to insert something, ');
          IF BASEPTR>0 THEN
            IF INPUTSTACK[BASEPTR].NAMEFIELD>=256 THEN print_str('E to edit your file,');
          IF DELETIONSALL THEN print_nl_str('1 or ... or 9 to ignore the next 1 to 9 tokens of input,');
          print_nl_str('H for help, X to quit.');
        END{:85}{:84};
    END;
  end;

  PutHelpToLog;
END;
{:82}

PROCEDURE PAUSEFORINST;
BEGIN
  IF OKTOINTERRUP THEN BEGIN
    INTERACTION := 3;
    IF (SELECTOR=18)OR(SELECTOR=16)THEN SELECTOR := SELECTOR+1;
    print_err('Interruption');
    help3('You rang?',
          'Try to insert an instruction for me (e.g., `I\showlists''),',
          'unless you just want to quit by typing `X''.');
    DELETIONSALL := FALSE;
    ERROR;
    DELETIONSALL := TRUE;
    INTERRUPT := 0;
  END;
END;

PROCEDURE BEGINTOKENLI(P:HALFWORD;T:QUARTERWORD);
BEGIN
  BEGIN
    IF INPUTPTR>MAXINSTACK THEN
      BEGIN
        MAXINSTACK := INPUTPTR;
        IF INPUTPTR=STACKSIZE THEN overflow('input stack size', STACKSIZE);
      END;
    INPUTSTACK[INPUTPTR] := CURINPUT;
    INPUTPTR := INPUTPTR+1;
  END;
  CURINPUT.STATEFIELD := 0;
  CURINPUT.STARTFIELD := P;
  CURINPUT.INDEXFIELD := T;
  IF T>=5 THEN
    BEGIN
      MEM[P].HH.LH := MEM[P].HH.LH+1;
      IF T=5 THEN CURINPUT.LIMITFIELD := PARAMPTR
      ELSE
        BEGIN
          CURINPUT.LOCFIELD := MEM[P].HH.RH;
          IF EQTB[5293].INT>1 THEN
            BEGIN
              BEGINDIAGNOS;
              print_nl_str('');
              CASE T OF 
                14: print_esc_str('mark');
                15: print_esc_str('write');
                ELSE print_str(print_cmd_chr(72,T+3407));
              END;
              print_str('->');
              TOKENSHOW(P);
              ENDDIAGNOSTI(FALSE);
            END;
        END;
    END
  ELSE CURINPUT.LOCFIELD := P;
END;
{:323}

{324:}
PROCEDURE ENDTOKENLIST;
BEGIN
  IF CURINPUT.INDEXFIELD>=3 THEN
    BEGIN
      IF CURINPUT.INDEXFIELD<=4
        THEN FLUSHLIST(CURINPUT.STARTFIELD)
      ELSE
        BEGIN
          DELETETOKENR(CURINPUT.
                       STARTFIELD);
          IF CURINPUT.INDEXFIELD=5 THEN
            WHILE PARAMPTR>CURINPUT.LIMITFIELD DO
              BEGIN
                PARAMPTR := PARAMPTR-1;
                FLUSHLIST(PARAMSTACK[PARAMPTR]);
              END;
        END;
    END
  ELSE
    IF CURINPUT.INDEXFIELD=1 THEN
      IF ALIGNSTATE>500000 THEN
        ALIGNSTATE := 0
  ELSE fatal_error('(interwoven alignment preambles are not allowed)');
  BEGIN
    INPUTPTR := INPUTPTR-1;
    CURINPUT := INPUTSTACK[INPUTPTR];
  END;
  BEGIN
    IF INTERRUPT<>0 THEN PAUSEFORINST;
  END;
END;
{:324}

{325:}
PROCEDURE BACKINPUT;
var P: HALFWORD;
begin
  while (CURINPUT.STATEFIELD=token_list)
    and (CURINPUT.LOCFIELD=0)
    and (CURINPUT.INDEXFIELD<>v_template) do ENDTOKENLIST;
  P := GETAVAIL;
  MEM[P].HH.LH := CURTOK;
  if CURTOK<right_brace_limit then begin
    if CURTOK<left_brace_limit then ALIGNSTATE := ALIGNSTATE-1
                               else ALIGNSTATE := ALIGNSTATE+1;
  end;
  if INPUTPTR>MAXINSTACK then begin
    MAXINSTACK := INPUTPTR;
    if INPUTPTR=STACKSIZE then overflow('input stack size', STACKSIZE);
  end;
  INPUTSTACK[INPUTPTR] := CURINPUT;
  INPUTPTR := INPUTPTR+1;
  CURINPUT.STATEFIELD := token_list;
  CURINPUT.STARTFIELD := P;
  CURINPUT.INDEXFIELD := backed_up;
  CURINPUT.LOCFIELD := P;
end;
{:325}

{327:}
PROCEDURE BACKERROR;
BEGIN
  OKTOINTERRUP := FALSE;
  BACKINPUT;
  OKTOINTERRUP := TRUE;
  ERROR;
END;


PROCEDURE INSERROR;
BEGIN
  OKTOINTERRUP := FALSE;
  BACKINPUT;
  CURINPUT.INDEXFIELD := 4;
  OKTOINTERRUP := TRUE;
  ERROR;
END;
{:327}

procedure ReportRunawayArgument;
begin
  RUNAWAY;
  print_err('Paragraph ended before ' + sprint_cs(WARNINGINDEX) + ' was complete');
  help3('I suspect you''ve forgotten a `}'', causing me to apply this',
        'control sequence to too much text. How can we recover?',
        'My plan is to forget the whole thing and hope for the best.');
  BACKERROR;
end;

PROCEDURE MUERROR;
BEGIN
  print_err('Incompatible glue units');
  help1('I''m going to assume that 1mu=1pt when they''re mixed.');
  ERROR;
END;

PROCEDURE NOALIGNERROR;
BEGIN
  print_err('Misplaced ' + print_esc('noalign'));
  help2('I expect to see \noalign only after the \cr of',
        'an alignment. Proceed, and I''ll ignore this case.');
  ERROR;
END;

PROCEDURE OMITERROR;
BEGIN
  print_err('Misplaced ' + print_esc('omit'));
  help2('I expect to see \omit only after tab marks or the \cr of',
        'an alignment. Proceed, and I''ll ignore this case.');
  ERROR;
END;

PROCEDURE ALIGNERROR;
BEGIN
  IF ABS(ALIGNSTATE)>2 THEN BEGIN
    {1128:}
    print_err('Misplaced ' + print_cmd_chr(CURCMD,CURCHR));
    IF CURTOK=1062 THEN BEGIN
      help6('I can''t figure out why you would want to use a tab mark',
            'here. If you just want an ampersand, the remedy is',
            'simple: Just type `I\&'' now. But if some right brace',
            'up above has ended a previous alignment prematurely,',
            'you''re probably due for more error messages, and you',
            'might try typing `S'' now just to see what is salvageable.');
    END ELSE BEGIN
      help5('I can''t figure out why you would want to use a tab mark',
            'or \cr or \span just now. If something like a right brace',
            'up above has ended a previous alignment prematurely,',
            'you''re probably due for more error messages, and you',
            'might try typing `S'' now just to see what is salvageable.');
    END;
    ERROR;
    {:1128}
  END ELSE BEGIN
    BACKINPUT;
    IF ALIGNSTATE<0 THEN BEGIN
      ALIGNSTATE := ALIGNSTATE+1;
      CURTOK := 379;
      print_err('Missing { inserted');
    END ELSE BEGIN
      ALIGNSTATE := ALIGNSTATE-1;
      CURTOK := 637;
      print_err('Missing } inserted');
    END;
    help3('I''ve put in what seems to be necessary to fix',
          'the current column of the current alignment.',
          'Try to go on, since this might almost work.');
    INSERROR;
  END;
END;


PROCEDURE CSERROR;
BEGIN
  print_err('Extra ' + print_esc('endcsname'));
  help1('I''m ignoring this, since I wasn''t doing a \csname.');
  ERROR;
END;





{336:}
PROCEDURE CHECKOUTERVA;

VAR P: HALFWORD;
  Q: HALFWORD;
BEGIN
  IF SCANNERSTATU<>0 THEN
    BEGIN
      DELETIONSALL := FALSE;
{337:}
      IF CURCS<>0 THEN
        BEGIN
          IF (CURINPUT.STATEFIELD=0)OR(CURINPUT.
             NAMEFIELD<1)OR(CURINPUT.NAMEFIELD>17)THEN
            BEGIN
              P := GETAVAIL;
              MEM[P].HH.LH := 4095+CURCS;
              BEGINTOKENLI(P,3);
            END;
          CURCMD := 10;
          CURCHR := 32;
        END{:337};
      IF SCANNERSTATU>1 THEN BEGIN
          RUNAWAY;
          IF CURCS=0 THEN BEGIN
            print_err('File ended');
          END ELSE BEGIN
            CURCS := 0;
            print_err('Forbidden control sequence found');
          END;
          print_str(' while scanning ');
          P := GETAVAIL;
          CASE SCANNERSTATU OF 
            2: BEGIN
                 print_str('definition');
                 MEM[P].HH.LH := 637;
               END;
            3: BEGIN
                 print_str('use');
                 MEM[P].HH.LH := PARTOKEN;
                 LONGSTATE := 113;
               END;
            4: BEGIN
                 print_str('preamble');
                 MEM[P].HH.LH := 637;
                 Q := P;
                 P := GETAVAIL;
                 MEM[P].HH.RH := Q;
                 MEM[P].HH.LH := 6710;
                 ALIGNSTATE := -1000000;
               END;
            5: BEGIN
                 print_str('text');
                 MEM[P].HH.LH := 637;
               END;
          END;
          BEGINTOKENLI(P,4);
          print_str(' of ' + sprint_cs(WARNINGINDEX));
          help4('I suspect you have forgotten a `}'', causing me',
                'to read past where you wanted me to stop.',
                'I''ll try to recover; but if the error is serious,',
                'you''d better type `E'' or `X'' now and fix your file.');
          ERROR;
        END{:338}
      ELSE
        BEGIN
          print_err('Incomplete ' + print_cmd_chr(105, CURIF) +
            '; all text was ignored after line ' + print_int(SKIPLINE));
          if CURCS<>0 then begin
            CURCS := 0;
            help3('A forbidden control sequence occurred in skipped text.',
                  'This kind of error happens when you say `\if...'' and forget',
                  'the matching `\fi''. I''ve inserted a `\fi''; this might work.');
          end else begin
            help3('The file ended while I was skipping conditional text.',
                  'This kind of error happens when you say `\if...'' and forget',
                  'the matching `\fi''. I''ve inserted a `\fi''; this might work.');
          end;
          CURTOK := 6713;
          INSERROR;
        END;
      DELETIONSALL := TRUE;
    END;
END;
{:336}


{341:}
procedure get_next(no_new_control_sequence: boolean);
LABEL 20,25,21,26;
VAR K: 0..BUFSIZE;
  T: HALFWORD;
  CAT: 0..15;
  C,CC: ASCIICODE;
  D: 2..3;
BEGIN
20:
  CURCS := 0;
  IF CURINPUT.STATEFIELD<>0 THEN BEGIN
    {343:}
25:
    IF CURINPUT.LOCFIELD<=CURINPUT.LIMITFIELD THEN BEGIN
      CURCHR := BUFFER[CURINPUT.LOCFIELD];
      CURINPUT.LOCFIELD := CURINPUT.LOCFIELD+1;
21:
      CURCMD := EQTB[3983+CURCHR].HH.RH;
      {344:}
      CASE CURINPUT.STATEFIELD+CURCMD OF {345:}
        10,26,42,27,43{:345}: GOTO 25;
        1,17,33:{354:} BEGIN

          {@<Scan a control sequence and set |state:=skip_blanks| or |mid_line|@>}
          IF CURINPUT.LOCFIELD>CURINPUT.LIMITFIELD THEN CURCS := null_cs{513} {|state| is irrelevant in this case}
          ELSE BEGIN
26:
            K := CURINPUT.LOCFIELD;
            CURCHR := BUFFER[K];
            CAT := EQTB[3983+CURCHR].HH.RH;
            K := K+1;
            IF      CAT=11 THEN CURINPUT.STATEFIELD := 17
            ELSE IF CAT=10 THEN CURINPUT.STATEFIELD := 17
                           ELSE CURINPUT.STATEFIELD := 1;
            IF (CAT=11)AND(K<=CURINPUT.LIMITFIELD) THEN BEGIN
              {356:}
              {@<Scan ahead in the buffer until finding a nonletter;
                 if an expanded code is encountered, reduce it
                 and |goto start_cs|; otherwise if a multiletter control
                 sequence is found, adjust |cur_cs| and |loc|, and
                 |goto found|@>}

              REPEAT
                CURCHR := BUFFER[K];
                CAT := EQTB[3983+CURCHR].HH.RH;
                K := K+1;
              UNTIL (CAT<>11)OR(K>CURINPUT.LIMITFIELD);

              {@<If an expanded code is present, reduce it and |goto start_cs|@>}
              {355:}
              BEGIN
                IF BUFFER[K]=CURCHR THEN
                  IF CAT=7 THEN
                    IF K<CURINPUT.LIMITFIELD THEN
                BEGIN
                  C := BUFFER[K+1];
                  IF C<128 THEN BEGIN
                    D := 2;
                    IF (((C>=48)AND(C<=57))OR((C>=97)AND(C<=102))) THEN
                      IF K+2<=CURINPUT.LIMITFIELD THEN
                    BEGIN
                      CC := BUFFER[K+2];
                      IF (((CC>=48)AND(CC<=57))OR((CC>=97)AND(CC<=102))) THEN D := D+1;
                    END;
                    IF D>2 THEN BEGIN
                      IF C<=57  THEN CURCHR := C-48
                                ELSE CURCHR := C-87;
                      IF CC<=57 THEN CURCHR := 16*CURCHR+CC-48
                                ELSE CURCHR := 16*CURCHR+CC-87;
                      BUFFER[K-1] := CURCHR;
                    END ELSE IF C<64 THEN BUFFER[K-1] := C+64
                    ELSE BUFFER[K-1] := C-64;
                    CURINPUT.LIMITFIELD := CURINPUT.LIMITFIELD-D;
                    FIRST := FIRST-D;
                    WHILE K<=CURINPUT.LIMITFIELD DO BEGIN
                      BUFFER[K] := BUFFER[K+D];
                      K := K+1;
                    END;
                    GOTO 26;
                  END;
                END;
              END;
              {:355}

              IF CAT<>11 THEN K := K-1;
              IF K>CURINPUT.LOCFIELD+1 THEN BEGIN
                CURCS := id_lookup(no_new_control_sequence, CURINPUT.LOCFIELD, K-CURINPUT.LOCFIELD);
                CURINPUT.LOCFIELD := K;
              END else begin
                CURCS := 257+BUFFER[CURINPUT.LOCFIELD];
                CURINPUT.LOCFIELD := CURINPUT.LOCFIELD+1;
              end;
            END ELSE BEGIN

              {@<If an expanded code is present, reduce it and |goto start_cs|@>}
              {FIXME: same as above}
              IF BUFFER[K]=CURCHR THEN
                IF CAT=7 THEN
                  IF K<CURINPUT.LIMITFIELD THEN
              BEGIN
                C := BUFFER[K+1];
                IF C<128 THEN BEGIN
                  D := 2;
                  IF (((C>=48)AND(C<=57))OR((C>=97)AND(C<=102)))THEN
                    IF K+2<=CURINPUT.LIMITFIELD THEN
                  BEGIN
                    CC := BUFFER[K+2];
                    IF (((CC>=48)AND(CC<=57))OR((CC>=97)AND(CC<=102))) THEN D := D+1;
                  END;
                  IF D>2 THEN BEGIN
                    IF C<=57  THEN CURCHR := C-48
                              ELSE CURCHR := C-87;
                    IF CC<=57 THEN CURCHR := 16*CURCHR+CC-48
                              ELSE CURCHR := 16*CURCHR+CC-87;
                    BUFFER[K-1] := CURCHR;
                  END ELSE IF C<64 THEN BUFFER[K-1] := C+64
                  ELSE BUFFER[K-1] := C-64;
                  CURINPUT.LIMITFIELD := CURINPUT.LIMITFIELD-D;
                  FIRST := FIRST-D;
                  WHILE K<=CURINPUT.LIMITFIELD DO BEGIN
                    BUFFER[K] := BUFFER[K+D];
                    K := K+1;
                  END;
                  GOTO 26;
                END;
              END;

              CURCS := 257+BUFFER[CURINPUT.LOCFIELD];
              CURINPUT.LOCFIELD := CURINPUT.LOCFIELD+1;
            END;
          END;
          CURCMD := EQTB[CURCS].HH.B0;
          CURCHR := EQTB[CURCS].HH.RH;
          IF CURCMD>=113 THEN CHECKOUTERVA;
          {:354}
        END;
                14,30,46:{353:}
                          BEGIN
                            CURCS := CURCHR+1;
                            CURCMD := EQTB[CURCS].HH.B0;
                            CURCHR := EQTB[CURCS].HH.RH;
                            CURINPUT.STATEFIELD := 1;
                            IF CURCMD>=113 THEN CHECKOUTERVA;
                          END{:353};
                8,24,40:{352:}
                         BEGIN
                           IF CURCHR=BUFFER[CURINPUT.LOCFIELD]THEN
                             IF CURINPUT.
                                LOCFIELD<CURINPUT.LIMITFIELD THEN
                               BEGIN
                                 C := BUFFER[CURINPUT.LOCFIELD+1];
                                 IF C<128 THEN
                                   BEGIN
                                     CURINPUT.LOCFIELD := CURINPUT.LOCFIELD+2;
                                     IF (((C>=48)AND(C<=57))OR((C>=97)AND(C<=102)))THEN
                                       IF CURINPUT.LOCFIELD<=
                                          CURINPUT.LIMITFIELD THEN
                                         BEGIN
                                           CC := BUFFER[CURINPUT.LOCFIELD];
                                           IF (((CC>=48)AND(CC<=57))OR((CC>=97)AND(CC<=102)))THEN
                                             BEGIN
                                               CURINPUT.
                                               LOCFIELD := CURINPUT.LOCFIELD+1;
                                               IF C<=57 THEN CURCHR := C-48
                                               ELSE CURCHR := C-87;
                                               IF CC<=57 THEN CURCHR := 16*CURCHR+CC-48
                                               ELSE CURCHR := 16*CURCHR+CC-87;
                                               GOTO 21;
                                             END;
                                         END;
                                     IF C<64 THEN CURCHR := C+64
                                     ELSE CURCHR := C-64;
                                     GOTO 21;
                                   END;
                               END;
                           CURINPUT.STATEFIELD := 1;
                         END{:352};
                16,32,48:{346:}
                          BEGIN
                            print_err('Text line contains an invalid character');
                            help2('A funny symbol that I can''t read has just been input.',
                                  'Continue, and I''ll forget that it ever happened.');
                            DELETIONSALL := FALSE;
                            ERROR;
                            DELETIONSALL := TRUE;
                            GOTO 20;
                          END{:346};
{347:}
                11:{349:}
                    BEGIN
                      CURINPUT.STATEFIELD := 17;
                      CURCHR := 32;
                    END{:349};
                6:{348:}
                   BEGIN
                     CURINPUT.LOCFIELD := CURINPUT.LIMITFIELD+1;
                     CURCMD := 10;
                     CURCHR := 32;
                   END{:348};
                22,15,31,47:{350:}
                             BEGIN
                               CURINPUT.LOCFIELD := CURINPUT.LIMITFIELD+1;
                               GOTO 25;
                             END{:350};
                38:{351:}
                    BEGIN
                      CURINPUT.LOCFIELD := CURINPUT.LIMITFIELD+1;
                      CURCS := PARLOC;
                      CURCMD := EQTB[CURCS].HH.B0;
                      CURCHR := EQTB[CURCS].HH.RH;
                      IF CURCMD>=113 THEN CHECKOUTERVA;
                    END{:351};
                2: ALIGNSTATE := ALIGNSTATE+1;
                18,34:
                       BEGIN
                         CURINPUT.STATEFIELD := 1;
                         ALIGNSTATE := ALIGNSTATE+1;
                       END;
                3: ALIGNSTATE := ALIGNSTATE-1;
                19,35:
                       BEGIN
                         CURINPUT.STATEFIELD := 1;
                         ALIGNSTATE := ALIGNSTATE-1;
                       END;
        20,21,23,25,28,29,36,37,39,41,44,45: CURINPUT.STATEFIELD := 1;
{:347}
        ELSE
      END{:344};
    END ELSE BEGIN
      CURINPUT.STATEFIELD := 33;
      {360:}
      IF CURINPUT.NAMEFIELD>17 THEN BEGIN
        {362:}
        LINE := LINE+1;
        FIRST := CURINPUT.STARTFIELD;
        IF NOT FORCEEOF THEN BEGIN
          IF INPUTLN(INPUTFILE[CURINPUT.INDEXFIELD], TRUE) THEN FIRMUPTHELIN
          ELSE FORCEEOF := TRUE;
        END;
        IF FORCEEOF THEN BEGIN
          PRINTCHAR(41);
          OPENPARENS := OPENPARENS-1;
          FLUSH(OUTPUT);
          FORCEEOF := FALSE;
          ENDFILEREADI;
          CHECKOUTERVA;
          GOTO 20;
        END;
        IF (EQTB[5311].INT<0)OR(EQTB[5311].INT>255)
          THEN CURINPUT.LIMITFIELD := CURINPUT.LIMITFIELD-1
          ELSE BUFFER[CURINPUT.LIMITFIELD] := EQTB[5311].INT;
        FIRST := CURINPUT.LIMITFIELD+1;
        CURINPUT.LOCFIELD := CURINPUT.STARTFIELD;
        {:362}
      END ELSE BEGIN
        IF NOT(CURINPUT.NAMEFIELD=0) THEN BEGIN
                      CURCMD := 0;
                      CURCHR := 0;
                      exit;
                    END;
                  IF INPUTPTR>0 THEN
                    BEGIN
                      ENDFILEREADI;
                      GOTO 20;
                    END;
                  IF SELECTOR<18 THEN OPENLOGFILE;
                  IF INTERACTION>1 THEN
                    BEGIN
                      IF (EQTB[5311].INT<0)OR(EQTB[5311].INT>255)
                        THEN CURINPUT.LIMITFIELD := CURINPUT.LIMITFIELD+1;
                      IF CURINPUT.LIMITFIELD=CURINPUT.STARTFIELD
                      THEN print_nl_str('(Please type a command or say `\end'')');
                      PRINTLN;
                      FIRST := CURINPUT.STARTFIELD;
                      BEGIN;
                        PRINTCHAR(42);
                        TERMINPUT;
                      END;
                      CURINPUT.LIMITFIELD := LAST;
                      IF (EQTB[5311].INT<0)OR(EQTB[5311].INT>255)
                      THEN CURINPUT.LIMITFIELD := CURINPUT.LIMITFIELD-1
                      ELSE BUFFER[CURINPUT.LIMITFIELD] := EQTB[5311].INT;
                      FIRST := CURINPUT.LIMITFIELD+1;
                      CURINPUT.LOCFIELD := CURINPUT.STARTFIELD;
                    END
                  ELSE fatal_error('*** (job aborted, no legal \end found)');
                END{:360};
              BEGIN
                IF INTERRUPT<>0 THEN PAUSEFORINST;
              END;
              GOTO 25;
            END;
    END{:343}
  ELSE{357:}
    IF CURINPUT.LOCFIELD<>0 THEN
      BEGIN
        T := MEM[CURINPUT.
             LOCFIELD].HH.LH;
        CURINPUT.LOCFIELD := MEM[CURINPUT.LOCFIELD].HH.RH;
        IF T>=4095 THEN
          BEGIN
            CURCS := T-4095;
            CURCMD := EQTB[CURCS].HH.B0;
            CURCHR := EQTB[CURCS].HH.RH;
            IF CURCMD>=113 THEN
              IF CURCMD=116 THEN{358:}
                BEGIN
                  CURCS := MEM[CURINPUT.
                           LOCFIELD].HH.LH-4095;
                  CURINPUT.LOCFIELD := 0;
                  CURCMD := EQTB[CURCS].HH.B0;
                  CURCHR := EQTB[CURCS].HH.RH;
                  IF CURCMD>100 THEN
                    BEGIN
                      CURCMD := 0;
                      CURCHR := 257;
                    END;
                END{:358}
            ELSE CHECKOUTERVA;
          END
        ELSE
          BEGIN
            CURCMD := T DIV 256;
            CURCHR := T MOD 256;
            CASE CURCMD OF 
              1: ALIGNSTATE := ALIGNSTATE+1;
              2: ALIGNSTATE := ALIGNSTATE-1;
              5:{359:}
                 BEGIN
                   BEGINTOKENLI(PARAMSTACK[CURINPUT.LIMITFIELD+CURCHR-1],0);
                   GOTO 20;
                 END{:359};
              ELSE
            END;
          END;
      END
  ELSE
    BEGIN
      ENDTOKENLIST;
      GOTO 20;
    END{:357};
{342:}
  IF CURCMD<=5 THEN
    IF CURCMD>=4 THEN
      IF ALIGNSTATE=0 THEN{789:}
        BEGIN
          IF (SCANNERSTATU=4)OR(CURALIGN=0)THEN fatal_error('(interwoven alignment preambles are not allowed)');
          CURCMD := MEM[CURALIGN+5].HH.LH;
          MEM[CURALIGN+5].HH.LH := CURCHR;
          IF CURCMD=63 THEN BEGINTOKENLI(29990,2)
          ELSE BEGINTOKENLI(MEM[CURALIGN+2]
                            .INT,2);
          ALIGNSTATE := 1000000;
          GOTO 20;
        END{:789}{:342};
END;
{:341}

{365:}
PROCEDURE GETTOKEN;
BEGIN
  get_next(false);
  IF CURCS=0 THEN CURTOK := (CURCMD*256)+CURCHR
  ELSE CURTOK := 4095+CURCS;
END;
{:365}

procedure store_new_token(var Node: HALFWORD; Token: HALFWORD);
var q: HALFWORD;
begin
  q := GETAVAIL;
  MEM[Node].HH.RH := q;
  MEM[q].HH.LH := Token;
  Node := q;
end;


{366:}
{389:}
PROCEDURE MACROCALL;
LABEL 22,30,31,40;
VAR
  R: HALFWORD;
  P: HALFWORD;
  Q: HALFWORD;
  S: HALFWORD;
  T: HALFWORD;
  U,V: HALFWORD;
  RBRACEPTR: HALFWORD;
  N: SMALLNUMBER;
  UNBALANCE: HALFWORD;
  M: HALFWORD;
  REFCOUNT: HALFWORD;
  SAVESCANNERS: SMALLNUMBER;
  SAVEWARNINGI: HALFWORD;
  MATCHCHR: ASCIICODE;
BEGIN
  SAVESCANNERS := SCANNERSTATU;
  SAVEWARNINGI := WARNINGINDEX;
  WARNINGINDEX := CURCS;
  REFCOUNT := CURCHR;
  R := MEM[REFCOUNT].HH.RH;
  N := 0;
  IF EQTB[5293].INT>0 THEN{401:}
    BEGIN
      BEGINDIAGNOS;
      PRINTLN;
      print_str(print_cs(WARNINGINDEX));
      TOKENSHOW(REFCOUNT);
      ENDDIAGNOSTI(FALSE);
    END{:401};
  IF MEM[R].HH.LH<>3584 THEN{391:}
    BEGIN
      SCANNERSTATU := 3;
      UNBALANCE := 0;
      LONGSTATE := EQTB[CURCS].HH.B0;
      IF LONGSTATE>=113 THEN LONGSTATE := LONGSTATE-2;
      REPEAT
        MEM[29997].HH.RH := 0;
        IF (MEM[R].HH.LH>3583)OR(MEM[R].HH.LH<3328)THEN S := 0
        ELSE
          BEGIN
            MATCHCHR := MEM[R].HH.LH-3328;
            S := MEM[R].HH.RH;
            R := S;
            P := 29997;
            M := 0;
          END;
{392:}
        22: GETTOKEN;
        IF CURTOK=MEM[R].HH.LH THEN{394:}
          BEGIN
            R := MEM[R].HH.RH;
            IF (MEM[R].HH.LH>=3328)AND(MEM[R].HH.LH<=3584)THEN
              BEGIN
                IF CURTOK<512
                  THEN ALIGNSTATE := ALIGNSTATE-1;
                GOTO 40;
              END
            ELSE GOTO 22;
          END{:394};
{397:}
        IF S<>R THEN
          IF S=0 THEN BEGIN

            {@<Report an improper use of the macro and abort@>}
            print_err('Use of ' + sprint_cs(WARNINGINDEX) + ' doesn''t match its definition');
            help4('If you say, e.g., `\def\a1{...}'', then you must always',
                  'put `1'' after `\a'', since control sequence names are',
                  'made up of letters only. The macro here has not been',
                  'followed by the required stuff, so I''m ignoring it.');
            ERROR;
            SCANNERSTATU := SAVESCANNERS;
            WARNINGINDEX := SAVEWARNINGI;
            exit;

          END
        ELSE
          BEGIN
            T := S;
            REPEAT
              store_new_token(P, MEM[T].HH.LH);
              M := M+1;
              U := MEM[T].HH.RH;
              V := S;
              WHILE TRUE DO
                BEGIN
                  IF U=R THEN
                    IF CURTOK<>MEM[V].HH.LH THEN GOTO 30
                  ELSE
                    BEGIN
                      R := MEM[V].HH.RH;
                      GOTO 22;
                    END;
                  IF MEM[U].HH.LH<>MEM[V].HH.LH THEN GOTO 30;
                  U := MEM[U].HH.RH;
                  V := MEM[V].HH.RH;
                END;
              30: T := MEM[T].HH.RH;
            UNTIL T=R;
            R := S;
          END{:397};
        IF CURTOK=PARTOKEN THEN
          IF LONGSTATE<>112 THEN{396:}
            BEGIN
              IF LONGSTATE=111 THEN ReportRunawayArgument;
              PSTACK[N] := MEM[29997].HH.RH;
              ALIGNSTATE := ALIGNSTATE-UNBALANCE;
              FOR M:=0 TO N DO
                FLUSHLIST(PSTACK[M]);
              SCANNERSTATU := SAVESCANNERS;
              WARNINGINDEX := SAVEWARNINGI;
              exit;
            END{:396};
        IF CURTOK<768 THEN
          IF CURTOK<512 THEN{399:}
            BEGIN
              UNBALANCE := 1;
              WHILE TRUE DO
                BEGIN
                  BEGIN
                    BEGIN
                      Q := AVAIL;
                      IF Q=0 THEN Q := GETAVAIL
                      ELSE
                        BEGIN
                          AVAIL := MEM[Q].HH.RH;
                          MEM[Q].HH.RH := 0;
{$IFDEF STATS}
                          DYNUSED := DYNUSED+1;
{$ENDIF}
                        END;
                    END;
                    MEM[P].HH.RH := Q;
                    MEM[Q].HH.LH := CURTOK;
                    P := Q;
                  END;
                  GETTOKEN;
                  IF CURTOK=PARTOKEN THEN
                    IF LONGSTATE<>112 THEN{396:}
                      BEGIN
                        IF LONGSTATE=111 THEN ReportRunawayArgument;
                        PSTACK[N] := MEM[29997].HH.RH;
                        ALIGNSTATE := ALIGNSTATE-UNBALANCE;
                        FOR M:=0 TO N DO
                          FLUSHLIST(PSTACK[M]);
                        SCANNERSTATU := SAVESCANNERS;
                        WARNINGINDEX := SAVEWARNINGI;
                        exit;
                      END{:396};
                  IF CURTOK<768 THEN
                    IF CURTOK<512 THEN UNBALANCE := UNBALANCE+1
                  ELSE
                    BEGIN
                      UNBALANCE := UNBALANCE-1;
                      IF UNBALANCE=0 THEN GOTO 31;
                    END;
                END;
31:
              RBRACEPTR := P;
              store_new_token(P, CURTOK);
            END{:399}
        ELSE{395:}
          BEGIN
            BACKINPUT;
            print_err('Argument of ' + sprint_cs(WARNINGINDEX) + ' has an extra }');
            help6('I''ve run across a `}'' that doesn''t seem to match anything.',
                  'For example, `\def\a#1{...}'' and `\a}'' would produce',
                  'this error. If you simply proceed now, the `\par'' that',
                  'I''ve just inserted will cause me to report a runaway',
                  'argument that might be the root of the problem. But if',
                  'your `}'' was spurious, just type `2'' and it will go away.');
            ALIGNSTATE := ALIGNSTATE+1;
            LONGSTATE := 111;
            CURTOK := PARTOKEN;
            INSERROR;
            GOTO 22;
          END{:395}
        ELSE{393:}
          BEGIN
            IF CURTOK=2592 THEN
              IF MEM[R].HH.LH<=3584 THEN
                IF MEM[R].HH.LH>=3328 THEN GOTO 22;
            store_new_token(P, CURTOK);
          END{:393};
        M := M+1;
        IF MEM[R].HH.LH>3584 THEN GOTO 22;
        IF MEM[R].HH.LH<3328 THEN GOTO 22;
        40:
            IF S<>0 THEN{400:}
              BEGIN
                IF (M=1)AND(MEM[P].HH.LH<768)THEN
                  BEGIN
                    MEM[
                    RBRACEPTR].HH.RH := 0;
                    BEGIN
                      MEM[P].HH.RH := AVAIL;
                      AVAIL := P;{$IFDEF STATS}
                      DYNUSED := DYNUSED-1;{$ENDIF}
                    END;
                    P := MEM[29997].HH.RH;
                    PSTACK[N] := MEM[P].HH.RH;
                    BEGIN
                      MEM[P].HH.RH := AVAIL;
                      AVAIL := P;
{$IFDEF STATS}
                      DYNUSED := DYNUSED-1;{$ENDIF}
                    END;
                  END
                ELSE PSTACK[N] := MEM[29997].HH.RH;
                N := N+1;
                IF EQTB[5293].INT>0 THEN
                  BEGIN
                    BEGINDIAGNOS;
                    print_nl_str(GetString(MATCHCHR) + print_int(N) + '<-');
                    print_utf8str(show_token_list_simple(PSTACK[N-1],1000));
                    ENDDIAGNOSTI(FALSE);
                  END;
              END{:400}{:392};
      UNTIL MEM[R].HH.LH=3584;
    END{:391};
{390:}
  WHILE (CURINPUT.STATEFIELD=0)AND(CURINPUT.LOCFIELD=0)AND(CURINPUT.
        INDEXFIELD<>2) DO
    ENDTOKENLIST;
  BEGINTOKENLI(REFCOUNT,5);
  CURINPUT.NAMEFIELD := WARNINGINDEX;
  CURINPUT.LOCFIELD := MEM[R].HH.RH;
  IF N>0 THEN
    BEGIN
      IF PARAMPTR+N>MAXPARAMSTAC THEN
        BEGIN
          MAXPARAMSTAC := PARAMPTR+N;
          IF MAXPARAMSTAC>PARAMSIZE THEN overflow('parameter stack size', PARAMSIZE);
        END;
      FOR M:=0 TO N-1 DO
        PARAMSTACK[PARAMPTR+M] := PSTACK[M];
      PARAMPTR := PARAMPTR+N;
    END{:390};
  SCANNERSTATU := SAVESCANNERS;
  WARNINGINDEX := SAVEWARNINGI;
END;{:389}{379:}
PROCEDURE INSERTRELAX;
BEGIN
  CURTOK := 4095+CURCS;
  BACKINPUT;
  CURTOK := 6716;
  BACKINPUT;
  CURINPUT.INDEXFIELD := 4;
END;{:379}



PROCEDURE GETXTOKEN; FORWARD;


{Add .tex if no extension given}
function scan_file_name : shortstring;
var
  s: string[file_name_size];
  i: SizeInt;
  WithExtension: boolean;
BEGIN
  NAMEINPROGRE := TRUE;

  repeat
    GETXTOKEN;
  until CURCMD<>spacer;

  WithExtension := false;
  setlength(s, file_name_size);
  i := 0;
  while true do begin
    if (CURCMD>other_char) or (CURCHR>255) then begin
      BACKINPUT;
      break;
    end;
    if CURCHR=32{' '} then break;
    if CURCHR=46{'.'} then WithExtension := true;
    if i < file_name_size then begin
      i := i + 1;
      s[i] := chr(CURCHR);
    end;
    GETXTOKEN;
  end;
  setlength(s, i);
  if not WithExtension then s := s + '.tex';

  NAMEINPROGRE := FALSE;
  scan_file_name := s;
END;


function CharPosLast(Match: char; const s: shortstring) : sizeint;
var i: sizeint;
begin
  i := length(s);
  while (i > 0) and{_then} (s[i] <> Match) do i := i - 1;
  CharPosLast := i;
end;

function BaseOfFileName(FileName: shortstring) : shortstring;
var
  Slash: sizeint;
  Dot: sizeint;
begin
  Slash := CharPosLast('/', FileName);
  Dot := pos('.', FileName);
  if Dot=0 then Dot := length(FileName);
  BaseOfFileName := copy(FileName, Slash+1, Dot-Slash-1);
end;

(*
function PathOfFileName(FileName: shortstring) : shortstring;
var
  Slash: sizeint;
begin
  Slash := CharPosLast('/', FileName);
  PathOfFileName := copy(FileName, 1, Slash);
end;
*)

function RemoveFileExtension(const FileName: shortstring) : shortstring;
var i: sizeint;
begin
  i := pos('.', FileName);
  if i=0 then RemoveFileExtension := FileName
         else RemoveFileExtension := copy(FileName, 1, i-1);
end;

PROCEDURE STARTINPUT;
var
  FileName: shortstring;
  BaseName: shortstring;
begin
  FileName := scan_file_name;
  while true do begin
    BEGINFILEREA;
    if a_open_in(INPUTFILE[CURINPUT.INDEXFIELD], FileName) then break;
    if pos('/', FileName)=0 then begin
      FileName := 'TeXinputs/' + FileName;
      if a_open_in(INPUTFILE[CURINPUT.INDEXFIELD], FileName) then break;
    end;
    ENDFILEREADI;
    FileName := prompt_file_name(FileName, 'input file name', '.tex');
  end;

  BaseName := BaseOfFileName(FileName);
  CURINPUT.NAMEFIELD := AddString(BaseName); {FileName also possible?}
  if job_name='' then begin
    job_name := BaseName;
    OPENLOGFILE;
  end;

  IF TERMOFFSET + length(FileName) > MAXPRINTLINE-2 THEN PRINTLN
  ELSE IF (TERMOFFSET>0) OR (FILEOFFSET>0) THEN PRINTCHAR(32);
  PRINTCHAR(40);
  OPENPARENS := OPENPARENS+1;
  slow_print_str(FileName);
  FLUSH(OUTPUT);
  CURINPUT.STATEFIELD := 33;

  LINE := 1;
  IF INPUTLN(INPUTFILE[CURINPUT.INDEXFIELD],FALSE) THEN;
  FIRMUPTHELIN;
  IF (EQTB[5311].INT<0)OR(EQTB[5311].INT>255)
    THEN CURINPUT.LIMITFIELD := CURINPUT.LIMITFIELD-1
    ELSE BUFFER[CURINPUT.LIMITFIELD] := EQTB[5311].INT;
  FIRST := CURINPUT.LIMITFIELD+1;
  CURINPUT.LOCFIELD := CURINPUT.STARTFIELD;
END;




{ --------------- natural boundary -----------}



{494:}
PROCEDURE PASSTEXT;
VAR L: Int32;
  SAVESCANNERS: SMALLNUMBER;
BEGIN
  SAVESCANNERS := SCANNERSTATU;
  SCANNERSTATU := 1;
  L := 0;
  SKIPLINE := LINE;
  WHILE TRUE DO BEGIN
    get_next(true);
    IF CURCMD=106 THEN BEGIN
      IF L=0 THEN break;
      IF CURCHR=2 THEN L := L-1;
    END ELSE IF CURCMD=105 THEN L := L+1;
  END;
  SCANNERSTATU := SAVESCANNERS;
END;
{:494}





{403:}
PROCEDURE SCANLEFTBRAC;
BEGIN{404:}
  REPEAT
    GETXTOKEN;
  UNTIL (CURCMD<>10)AND(CURCMD<>0){:404};
  IF CURCMD<>1 THEN
    BEGIN
      print_err('Missing { inserted');
      help4('A left brace was mandatory here, so I''ve put one in.',
            'You might want to delete and/or insert some corrections',
            'so that I will find a matching right brace soon.',
            '(If you''re confused by all this, try typing `I}'' now.)');
      BACKERROR;
      CURTOK := 379;
      CURCMD := 1;
      CURCHR := 123;
      ALIGNSTATE := ALIGNSTATE+1;
    END;
END;
{:403}{405:}
PROCEDURE SCANOPTIONAL;
BEGIN{406:}
  REPEAT
    GETXTOKEN;
  UNTIL CURCMD<>10{:406};
  IF CURTOK<>3133 THEN BACKINPUT;
END;
{:405}




{@ In case you are getting bored, here is a slightly less trivial routine:
Given a string of lowercase letters, like `pt' or `plus' or
`width', the |scan_keyword| routine checks to see whether the next
tokens of input match this string. The match must be exact, except that
uppercase letters will match their lowercase counterparts; uppercase
equivalents are determined by subtracting |"a"-"A"|, rather than using the
|uc_code| table, since \TeX\ uses this routine only for its own limited
set of keywords.

If a match is found, the characters are effectively removed from the input
and |true| is returned. Otherwise |false| is returned, and the input
is left essentially unchanged (except for the fact that some macros
may have been expanded, etc.).}

function scan_keyword(const s: shortstring): boolean; {look for a given string}
VAR
  P: HALFWORD;
  Q: HALFWORD;
  i: Int32;
BEGIN
  P := 29987;
  MEM[P].HH.RH := 0;
  i := 1;
  WHILE i <= length(s) DO BEGIN
    GETXTOKEN; {recursion is possible here}
    IF (CURCS=0)AND((CURCHR=ord(s[i]))OR(CURCHR=ord(s[i])-32))THEN BEGIN
      store_new_token(P, CURTOK);
      i := i + 1;
    END ELSE IF (CURCMD<>10)OR(P<>29987) THEN BEGIN
      BACKINPUT;
      IF P<>29987 THEN BEGINTOKENLI(MEM[29987].HH.RH,3);
      scan_keyword := false;
      exit;
    END;
  END;
  FLUSHLIST(MEM[29987].HH.RH);
  scan_keyword := true;
END;


PROCEDURE SCANINT; FORWARD;{433:}


PROCEDURE SCANEIGHTBIT;
BEGIN
  SCANINT;
  IF (CURVAL<0) OR (CURVAL>255)THEN BEGIN
    print_err('Bad register code (' + print_int(CURVAL) + ')');
    help2('A register number must be between 0 and 255.',
          'I changed this one to zero.');
    ERROR;
    CURVAL := 0;
  END;
END;


PROCEDURE SCANCHARNUM;
BEGIN
  SCANINT;
  IF (CURVAL<0) OR (CURVAL>255) THEN BEGIN
    print_err('Bad character code (' + print_int(CURVAL) + ')');
    help2('A character number must be between 0 and 255.',
          'I changed this one to zero.');
    ERROR;
    CURVAL := 0;
  END;
END;


PROCEDURE SCANFOURBITI;
BEGIN
  SCANINT;
  IF (CURVAL<0) OR (CURVAL>15) THEN BEGIN
    print_err('Bad number (' + print_int(CURVAL) + ')');
    help2('Since I expected to read a number between 0 and 15,',
          'I changed this one to zero.');
    ERROR;
    CURVAL := 0;
  END;
END;


PROCEDURE SCANFIFTEENB;
BEGIN
  SCANINT;
  IF (CURVAL<0) OR (CURVAL>32767) THEN BEGIN
    print_err('Bad mathchar (' + print_int(CURVAL) + ')');
    help2('A mathchar number must be between 0 and 32767.',
          'I changed this one to zero.');
    ERROR;
    CURVAL := 0;
  END;
END;


PROCEDURE SCANTWENTYSE;
BEGIN
  SCANINT;
  IF (CURVAL<0) OR (CURVAL>134217727) THEN BEGIN
    print_err('Bad delimiter code (' + print_int(CURVAL) + ')');
    help2('A numeric delimiter code must be between 0 and 2^{27}-1.',
          'I changed this one to zero.');
    ERROR;
    CURVAL := 0;
  END;
END;


PROCEDURE SCANFONTIDEN;
VAR
  F: INTERNALFONT;
  M: HALFWORD;
BEGIN
  {406:}
  REPEAT
    GETXTOKEN;
  UNTIL CURCMD<>10;
  {:406}

  IF CURCMD=88 THEN F := EQTB[3934].HH.RH
  ELSE IF CURCMD=87 THEN F := CURCHR
  ELSE IF CURCMD=86 THEN BEGIN
    M := CURCHR;
    SCANFOURBITI;
    F := EQTB[M+CURVAL].HH.RH;
  END ELSE BEGIN
    print_err('Missing font identifier');
    help2('I was looking for a control sequence whose',
          'current meaning has been defined by \font.');
    BACKERROR;
    F := 0;
  END;
  CURVAL := F;
END;


PROCEDURE FINDFONTDIME(WRITING:BOOLEAN);
VAR F: INTERNALFONT;
  N: Int32;
BEGIN
  SCANINT;
  N := CURVAL;
  SCANFONTIDEN;
  F := CURVAL;
  IF N<=0 THEN CURVAL := FMEMPTR
  ELSE
    BEGIN
      IF WRITING AND(N<=4)AND(N>=2)AND
         (FONTGLUE[F]<>0)THEN
        BEGIN
          DELETEGLUERE(FONTGLUE[F]);
          FONTGLUE[F] := 0;
        END;
      IF N>FONTPARAMS[F]THEN
        IF F<FONTPTR THEN CURVAL := FMEMPTR
      ELSE{580:}
        BEGIN
          REPEAT
            IF FMEMPTR=FONTMEMSIZE THEN overflow('font memory', FONTMEMSIZE);
            FONTINFO[FMEMPTR].INT := 0;
            FMEMPTR := FMEMPTR+1;
            FONTPARAMS[F] := FONTPARAMS[F]+1;
          UNTIL N=FONTPARAMS[F];
          CURVAL := FMEMPTR-1;
        END{:580}
      ELSE CURVAL := N+PARAMBASE[F];
    END;

  {579:}
  IF CURVAL=FMEMPTR THEN BEGIN
    print_err('Font ' + print_esc(GetString(HASH[2624+F].RH)) + ' has only ' +
      print_int(FONTPARAMS[F]) + ' fontdimen parameters');
    help2('To increase the number of font parameters, you must',
          'use \fontdimen immediately after the \font is loaded.');
    ERROR;
  END
  {:579};
END;


PROCEDURE SCANSOMETHIN(LEVEL:SMALLNUMBER; NEGATIVE:BOOLEAN);
VAR M: HALFWORD;
  P: 0..NESTSIZE;
BEGIN
  M := CURCHR;
  CASE CURCMD OF 
    85:{414:}
        BEGIN
          SCANCHARNUM;
          IF M=5007 THEN
            BEGIN
              CURVAL := EQTB[5007+CURVAL].HH.RH-0;
              CURVALLEVEL := 0;
            END
          ELSE
            IF M<5007 THEN
              BEGIN
                CURVAL := EQTB[M+CURVAL].HH.RH;
                CURVALLEVEL := 0;
              END
          ELSE
            BEGIN
              CURVAL := EQTB[M+CURVAL].INT;
              CURVALLEVEL := 0;
            END;
        END{:414};
    71,72,86,87,88:{415:}
                    IF LEVEL<>5 THEN BEGIN
                      print_err('Missing number, treated as zero');
                      help3('A number should have been here; I inserted `0''.',
                            '(If you can''t figure out why I needed to see a number,',
                            'look up `weird error'' in the index to The TeXbook.)');
                      BACKERROR;
                      CURVAL := 0;
                      CURVALLEVEL := 1;
                    END ELSE IF CURCMD<=72 THEN BEGIN
                      IF CURCMD<72 THEN BEGIN
                        SCANEIGHTBIT;
                        M := 3422+CURVAL;
                      END;
                      CURVAL := EQTB[M].HH.RH;
                      CURVALLEVEL := 5;
                    END ELSE BEGIN
                      BACKINPUT;
                      SCANFONTIDEN;
                      CURVAL := 2624+CURVAL;
                      CURVALLEVEL := 4;
                    END;
                    {:415}
    73:
        BEGIN
          CURVAL := EQTB[M].INT;
          CURVALLEVEL := 0;
        END;
    74:
        BEGIN
          CURVAL := EQTB[M].INT;
          CURVALLEVEL := 1;
        END;
    75:
        BEGIN
          CURVAL := EQTB[M].HH.RH;
          CURVALLEVEL := 2;
        END;
    76:
        BEGIN
          CURVAL := EQTB[M].HH.RH;
          CURVALLEVEL := 3;
        END;
    79:{418:}
        IF ABS(CURLIST.MODEFIELD)<>M THEN BEGIN
          print_err('Improper ' + print_cmd_chr(79,M));
          help4('You can refer to \spacefactor only in horizontal mode;',
                'you can refer to \prevdepth only in vertical mode; and',
                'neither of these is meaningful inside \write. So',
                'I''m forgetting what you said and using zero instead.');
          ERROR;
          IF LEVEL<>5 THEN BEGIN
            CURVAL := 0;
            CURVALLEVEL := 1;
          END ELSE BEGIN
            CURVAL := 0;
            CURVALLEVEL := 0;
          END;
        END ELSE IF M=1 THEN BEGIN
          CURVAL := CURLIST.AUXFIELD.INT;
          CURVALLEVEL := 1;
        END ELSE BEGIN
          CURVAL := CURLIST.AUXFIELD.HH.LH;
          CURVALLEVEL := 0;
        END
        {:418};
    80:{422:}
        IF CURLIST.MODEFIELD=0 THEN
          BEGIN
            CURVAL := 0;
            CURVALLEVEL := 0;
          END
        ELSE
          BEGIN
            NEST[NESTPTR] := CURLIST;
            P := NESTPTR;
            WHILE ABS(NEST[P].MODEFIELD)<>1 DO
              P := P-1;
            BEGIN
              CURVAL := NEST[P].PGFIELD;
              CURVALLEVEL := 0;
            END;
          END{:422};
    82:{419:}
        BEGIN
          IF M=0 THEN CURVAL := DEADCYCLES
          ELSE CURVAL := INSERTPENALT;
          CURVALLEVEL := 0;
        END{:419};
    81:{421:}
        BEGIN
          IF (PAGECONTENTS=0)AND(NOT OUTPUTACTIVE)THEN
            IF M=0 THEN
              CURVAL := 1073741823
          ELSE CURVAL := 0
          ELSE CURVAL := PAGESOFAR[M];
          CURVALLEVEL := 1;
        END{:421};
    84:{423:}
        BEGIN
          IF EQTB[3412].HH.RH=0 THEN CURVAL := 0
          ELSE CURVAL := MEM[
                         EQTB[3412].HH.RH].HH.LH;
          CURVALLEVEL := 0;
        END{:423};
    83:{420:}
        BEGIN
          SCANEIGHTBIT;
          IF EQTB[3678+CURVAL].HH.RH=0 THEN CURVAL := 0
          ELSE CURVAL := MEM[EQTB[3678+
                         CURVAL].HH.RH+M].INT;
          CURVALLEVEL := 1;
        END{:420};
    68,69:
           BEGIN
             CURVAL := CURCHR;
             CURVALLEVEL := 0;
           END;
    77:{425:}
        BEGIN
          FINDFONTDIME(FALSE);
          FONTINFO[FMEMPTR].INT := 0;
          BEGIN
            CURVAL := FONTINFO[CURVAL].INT;
            CURVALLEVEL := 1;
          END;
        END{:425};
    78:{426:}
        BEGIN
          SCANFONTIDEN;
          IF M=0 THEN
            BEGIN
              CURVAL := HYPHENCHAR[CURVAL];
              CURVALLEVEL := 0;
            END
          ELSE
            BEGIN
              CURVAL := SKEWCHAR[CURVAL];
              CURVALLEVEL := 0;
            END;
        END{:426};
    89:{427:}
        BEGIN
          SCANEIGHTBIT;
          CASE M OF 
            0: CURVAL := EQTB[5318+CURVAL].INT;
            1: CURVAL := EQTB[5851+CURVAL].INT;
            2: CURVAL := EQTB[2900+CURVAL].HH.RH;
            3: CURVAL := EQTB[3156+CURVAL].HH.RH;
          END;
          CURVALLEVEL := M;
        END{:427};
    70:{424:}
        IF CURCHR>2 THEN BEGIN
            IF CURCHR=3 THEN CURVAL := LINE
                        ELSE CURVAL := LASTBADNESS;
            CURVALLEVEL := 0;
          END
        ELSE
          BEGIN
            IF CURCHR=2 THEN CURVAL := 0
            ELSE CURVAL := 0;
            CURVALLEVEL := CURCHR;
            IF NOT(CURLIST.TAILFIELD>=HIMEMMIN)AND(CURLIST.MODEFIELD<>0)THEN
              CASE CURCHR OF 
                0: IF MEM[CURLIST.TAILFIELD].HH.B0=12 
                     THEN CURVAL := MEM[CURLIST.TAILFIELD+1].INT;
                1: IF MEM[CURLIST.TAILFIELD].HH.B0=11
                     THEN CURVAL := MEM[CURLIST.TAILFIELD+1].INT;
                2: IF MEM[CURLIST.TAILFIELD].HH.B0=10 THEN BEGIN
                     CURVAL := MEM[CURLIST.TAILFIELD+1].HH.LH;
                     IF MEM[CURLIST.TAILFIELD].HH.B1=99 THEN CURVALLEVEL := 3;
                   END;
              END
            ELSE
              IF (CURLIST.MODEFIELD=1)AND(CURLIST.TAILFIELD=CURLIST.HEADFIELD)
                THEN
                CASE CURCHR OF 
                  0: CURVAL := LASTPENALTY;
                  1: CURVAL := LASTKERN;
                  2: IF LASTGLUE<>65535 THEN CURVAL := LASTGLUE;
                END;
          END{:424};
    ELSE BEGIN
      {428:}
      print_err('You can''t use `' + print_cmd_chr(CURCMD, CURCHR) + ''' after ' + print_esc('the'));
      help1('I''m forgetting what you said and using zero instead.');
      ERROR;
      IF LEVEL<>5 THEN BEGIN
        CURVAL := 0;
        CURVALLEVEL := 1;
      END ELSE BEGIN
        CURVAL := 0;
        CURVALLEVEL := 0;
      END;
      {:428}
    END;
  END;
  WHILE CURVALLEVEL>LEVEL DO{429:}
    BEGIN
      IF CURVALLEVEL=2 THEN CURVAL := MEM[
                                      CURVAL+1].INT
      ELSE
        IF CURVALLEVEL=3 THEN MUERROR;
      CURVALLEVEL := CURVALLEVEL-1;
    END{:429};
{430:}
  IF NEGATIVE THEN
    IF CURVALLEVEL>=2 THEN
      BEGIN
        CURVAL := NEWSPEC(
                  CURVAL);{431:}
        BEGIN
          MEM[CURVAL+1].INT := -MEM[CURVAL+1].INT;
          MEM[CURVAL+2].INT := -MEM[CURVAL+2].INT;
          MEM[CURVAL+3].INT := -MEM[CURVAL+3].INT;
        END{:431};
      END
  ELSE CURVAL := -CURVAL
  ELSE
    IF (CURVALLEVEL>=2)AND(CURVALLEVEL<=3)THEN
      MEM[CURVAL].HH.RH := MEM[CURVAL].HH.RH+1{:430};
END;
{:413}{440:}
PROCEDURE SCANINT;
VAR NEGATIVE: BOOLEAN;
  M: Int32;
  D: SMALLNUMBER;
  VACUOUS: BOOLEAN;
  OKSOFAR: BOOLEAN;
BEGIN
  RADIX := 0;
  OKSOFAR := TRUE;{441:}
  NEGATIVE := FALSE;
  REPEAT{406:}
    REPEAT
      GETXTOKEN;
    UNTIL CURCMD<>10{:406};
    IF CURTOK=3117 THEN
      BEGIN
        NEGATIVE := NOT NEGATIVE;
        CURTOK := 3115;
      END;
  UNTIL CURTOK<>3115{:441};
  IF CURTOK=3168 THEN{442:}
    BEGIN
      GETTOKEN;
      IF CURTOK<4095 THEN
        BEGIN
          CURVAL := CURCHR;
          IF CURCMD<=2 THEN
            IF CURCMD=2 THEN ALIGNSTATE := ALIGNSTATE+1
          ELSE
            ALIGNSTATE := ALIGNSTATE-1;
        END
      ELSE
        IF CURTOK<4352 THEN CURVAL := CURTOK-4096
      ELSE CURVAL := CURTOK
                     -4352;
      IF CURVAL>255 THEN BEGIN
        print_err('Improper alphabetic constant');
        help2('A one-character control sequence belongs after a ` mark.',
              'So I''m essentially inserting \0 here.');
        CURVAL := 48;
        BACKERROR;
      END ELSE BEGIN
        {443:}
        GETXTOKEN;
        IF CURCMD<>10 THEN BACKINPUT;
        {:443}
      END;
    END{:442}
  ELSE
    IF (CURCMD>=68)AND(CURCMD<=89)THEN SCANSOMETHIN(0,FALSE)
  ELSE{444:}
    BEGIN
      RADIX := 10;
      M := 214748364;
      IF CURTOK=3111 THEN
        BEGIN
          RADIX := 8;
          M := 268435456;
          GETXTOKEN;
        END
      ELSE
        IF CURTOK=3106 THEN
          BEGIN
            RADIX := 16;
            M := 134217728;
            GETXTOKEN;
          END;
      VACUOUS := TRUE;
      CURVAL := 0;
{445:}
      WHILE TRUE DO BEGIN
          IF (CURTOK<3120+RADIX)AND(CURTOK>=3120)AND(CURTOK<=3129) THEN D := CURTOK-3120
          ELSE IF RADIX=16 THEN
            IF (CURTOK<=2886) AND (CURTOK>=2881) THEN D := CURTOK-2871
            ELSE IF (CURTOK<=3142)AND(CURTOK>=3137) THEN D := CURTOK-3127
            ELSE break
          ELSE break;
          VACUOUS := FALSE;
          IF (CURVAL>=M)AND((CURVAL>M)OR(D>7)OR(RADIX<>10))THEN BEGIN
            IF OKSOFAR THEN BEGIN
              print_err('Number too big');
              help2('I can only go up to 2147483647=''17777777777="7FFFFFFF,',
                    'so I''m using that number instead of yours.');
              ERROR;
              CURVAL := 2147483647;
              OKSOFAR := FALSE;
            END;
          END ELSE CURVAL := CURVAL*RADIX+D;
          GETXTOKEN;
        END;
      {:445};
      IF VACUOUS THEN BEGIN
        {446:}
        print_err('Missing number, treated as zero');
        help3('A number should have been here; I inserted `0''.',
              '(If you can''t figure out why I needed to see a number,',
              'look up `weird error'' in the index to The TeXbook.)');
        BACKERROR;
        {:446}
      END ELSE IF CURCMD<>10 THEN BACKINPUT;
    END{:444};
  IF NEGATIVE THEN CURVAL := -CURVAL;
END;
{:440}{448:}

FUNCTION HALF(X:Int32): Int32;
BEGIN
  IF ODD(X)THEN HALF := (X+1)DIV 2
  ELSE HALF := X DIV 2;
END;

FUNCTION ROUNDDECIMAL(K:SMALLNUMBER): SCALED;
VAR A: Int32;
BEGIN
  A := 0;
  WHILE K>0 DO
    BEGIN
      K := K-1;
      A := (A+DIG[K]*131072)DIV 10;
    END;
  ROUNDDECIMAL := (A+1)DIV 2;
END;

FUNCTION MULTANDADD(N:Int32;X,Y,MAXANSWER:SCALED): SCALED;
BEGIN
  IF N<0 THEN
    BEGIN
      X := -X;
      N := -N;
    END;
  IF N=0 THEN MULTANDADD := Y
  ELSE
    IF ((X<=(MAXANSWER-Y)DIV N)AND(-X<=(
       MAXANSWER+Y)DIV N))THEN MULTANDADD := N*X+Y
  ELSE
    BEGIN
      ARITHERROR := TRUE;
      MULTANDADD := 0;
    END;
END;

FUNCTION XOVERN(X:SCALED; N:Int32): SCALED;
VAR NEGATIVE: BOOLEAN;
BEGIN
  NEGATIVE := FALSE;
  IF N=0 THEN
    BEGIN
      ARITHERROR := TRUE;
      XOVERN := 0;
      REMAINDER := X;
    END
  ELSE
    BEGIN
      IF N<0 THEN
        BEGIN
          X := -X;
          N := -N;
          NEGATIVE := TRUE;
        END;
      IF X>=0 THEN
        BEGIN
          XOVERN := X DIV N;
          REMAINDER := X MOD N;
        END
      ELSE
        BEGIN
          XOVERN := -((-X)DIV N);
          REMAINDER := -((-X)MOD N);
        END;
    END;
  IF NEGATIVE THEN REMAINDER := -REMAINDER;
END;

FUNCTION XNOVERD(X:SCALED;N,D:Int32): SCALED;
VAR POSITIVE: BOOLEAN;
  T,U,V: NONNEGATIVEI;
BEGIN
  IF X>=0 THEN POSITIVE := TRUE
  ELSE
    BEGIN
      X := -X;
      POSITIVE := FALSE;
    END;
  T := (X MOD 32768)*N;
  U := (X DIV 32768)*N+(T DIV 32768);
  V := (U MOD D)*32768+(T MOD 32768);
  IF U DIV D>=32768 THEN ARITHERROR := TRUE
  ELSE U := 32768*(U DIV D)+(V DIV D);
  IF POSITIVE THEN
    BEGIN
      XNOVERD := U;
      REMAINDER := V MOD D;
    END
  ELSE
    BEGIN
      XNOVERD := -U;
      REMAINDER := -(V MOD D);
    END;
END;


{@ The |prepare_mag| subroutine is called whenever \TeX\ wants to use |mag|
for magnification.}
PROCEDURE prepare_mag;
var Mag: int32;
BEGIN
  Mag := EQTB[5280].INT;
  IF (MAGSET>0) AND (Mag<>MAGSET) THEN BEGIN
    print_err('Incompatible magnification (' + print_int(Mag) + ');');
    print_nl_str(' the previous value will be retained (' + print_int(MAGSET) + ')');
    help2('I can handle only one magnification ratio per job. So I''ve',
          'reverted to the magnification you used earlier on this run.');
    ERROR;
    GEQWORDDEFIN(5280,MAGSET);
  END;
  IF (Mag<=0) OR (Mag>32768) THEN BEGIN
    print_err('Illegal magnification has been changed to 1000 (' + print_int(Mag) + ')');
    help1('The magnification ratio must be between 1 and 32768.');
    ERROR;
    GEQWORDDEFIN(5280,1000);
  END;
  MAGSET := EQTB[5280].INT;
END;


PROCEDURE SCANDIMEN(MU,INF,SHORTCUT:BOOLEAN);
LABEL 30,31,32,40,45,88,89;
VAR NEGATIVE: BOOLEAN;
  F: Int32;
{450:}
  NUM,DENOM: 1..65536;
  K,KK: SMALLNUMBER;
  P,Q: HALFWORD;
  V: SCALED;
  SAVECURVAL: Int32;{:450}
BEGIN
  F := 0;
  ARITHERROR := FALSE;
  CURORDER := 0;
  NEGATIVE := FALSE;
  IF NOT SHORTCUT THEN
    BEGIN{441:}
      NEGATIVE := FALSE;
      REPEAT{406:}
        REPEAT
          GETXTOKEN;
        UNTIL CURCMD<>10{:406};
        IF CURTOK=3117 THEN
          BEGIN
            NEGATIVE := NOT NEGATIVE;
            CURTOK := 3115;
          END;
      UNTIL CURTOK<>3115{:441};
      IF (CURCMD>=68)AND(CURCMD<=89)THEN{449:}
        IF MU THEN
          BEGIN
            SCANSOMETHIN(3,
                         FALSE);{451:}
            IF CURVALLEVEL>=2 THEN
              BEGIN
                V := MEM[CURVAL+1].INT;
                DELETEGLUERE(CURVAL);
                CURVAL := V;
              END{:451};
            IF CURVALLEVEL=3 THEN GOTO 89;
            IF CURVALLEVEL<>0 THEN MUERROR;
          END
      ELSE
        BEGIN
          SCANSOMETHIN(1,FALSE);
          IF CURVALLEVEL=1 THEN GOTO 89;
        END{:449}
      ELSE
        BEGIN
          BACKINPUT;
          IF CURTOK=3116 THEN CURTOK := 3118;
          IF CURTOK<>3118 THEN SCANINT
          ELSE
            BEGIN
              RADIX := 10;
              CURVAL := 0;
            END;
          IF CURTOK=3116 THEN CURTOK := 3118;
          IF (RADIX=10)AND(CURTOK=3118)THEN{452:}
            BEGIN
              K := 0;
              P := 0;
              GETTOKEN;
              WHILE TRUE DO
                BEGIN
                  GETXTOKEN;
                  IF (CURTOK>3129)OR(CURTOK<3120)THEN GOTO 31;
                  IF K<17 THEN BEGIN
                      Q := GETAVAIL;
                      MEM[Q].HH.RH := P;
                      MEM[Q].HH.LH := CURTOK-3120;
                      P := Q;
                      K := K+1;
                    END;
                END;
              31: FOR KK:=K DOWNTO 1 DO
                    BEGIN
                      DIG[KK-1] := MEM[P].HH.LH;
                      Q := P;
                      P := MEM[P].HH.RH;
                      BEGIN
                        MEM[Q].HH.RH := AVAIL;
                        AVAIL := Q;{$IFDEF STATS}
                        DYNUSED := DYNUSED-1;{$ENDIF}
                      END;
                    END;
              F := ROUNDDECIMAL(K);
              IF CURCMD<>10 THEN BACKINPUT;
            END{:452};
        END;
    END;
  IF CURVAL<0 THEN
    BEGIN
      NEGATIVE := NOT NEGATIVE;
      CURVAL := -CURVAL;
    END;
{453:}
  IF INF THEN
    {454:}
    IF scan_keyword('fil') THEN BEGIN
      CURORDER := 1;
      WHILE scan_keyword('l') DO BEGIN
        IF CURORDER=3 THEN BEGIN
          print_err('Illegal unit of measure (replaced by filll)');
          help1('I dddon''t go any higher than filll.');
          ERROR;
        END ELSE CURORDER := CURORDER+1;
      END;
      GOTO 88;
      {:454}
    END;
{455:}
  SAVECURVAL := CURVAL;{406:}
  REPEAT
    GETXTOKEN;
  UNTIL CURCMD<>10{:406};
  IF (CURCMD<68)OR(CURCMD>89)THEN BACKINPUT
  ELSE
    BEGIN
      IF MU THEN
        BEGIN
          SCANSOMETHIN(3,FALSE);
{451:}
          IF CURVALLEVEL>=2 THEN
            BEGIN
              V := MEM[CURVAL+1].INT;
              DELETEGLUERE(CURVAL);
              CURVAL := V;
            END{:451};
          IF CURVALLEVEL<>3 THEN MUERROR;
        END
      ELSE SCANSOMETHIN(1,FALSE);
      V := CURVAL;
      GOTO 40;
    END;
  IF MU THEN GOTO 45;
  IF scan_keyword('em')THEN V := ({558:}FONTINFO[6+PARAMBASE[EQTB[3934].HH.RH]
                               ].INT{:558})
  ELSE
    IF scan_keyword('ex')THEN V := ({559:}FONTINFO[5+PARAMBASE[
                                 EQTB[3934].HH.RH]].INT{:559})
  ELSE GOTO 45;{443:}
  BEGIN
    GETXTOKEN;
    IF CURCMD<>10 THEN BACKINPUT;
  END{:443};
  40: CURVAL := MULTANDADD(SAVECURVAL,V,XNOVERD(V,F,65536),1073741823);
  GOTO 89;
  45:{:455};
  IF MU THEN{456:}
    IF scan_keyword('mu')THEN GOTO 88
  ELSE
    BEGIN
      print_err('Illegal unit of measure (mu inserted)');
      help4('The unit of measurement in math glue must be mu.',
            'To recover gracefully from this error, it''s best to',
            'delete the erroneous units; e.g., type `2'' to delete',
            'two letters. (See Chapter 27 of The TeXbook.)');
      ERROR;
      GOTO 88;
    END{:456};
  IF scan_keyword('true')THEN{457:}
    BEGIN
      prepare_mag;
      IF EQTB[5280].INT<>1000 THEN
        BEGIN
          CURVAL := XNOVERD(CURVAL,1000,EQTB[5280
                    ].INT);
          F := (1000*F+65536*REMAINDER)DIV EQTB[5280].INT;
          CURVAL := CURVAL+(F DIV 65536);
          F := F MOD 65536;
        END;
    END{:457};
  IF scan_keyword('pt')THEN GOTO 88;
{458:}
  IF scan_keyword('in')THEN
    BEGIN
      NUM := 7227;
      DENOM := 100;
    END
  ELSE
    IF scan_keyword('pc')THEN
      BEGIN
        NUM := 12;
        DENOM := 1;
      END
  ELSE
    IF scan_keyword('cm')THEN
      BEGIN
        NUM := 7227;
        DENOM := 254;
      END
  ELSE
    IF scan_keyword('mm')THEN
      BEGIN
        NUM := 7227;
        DENOM := 2540;
      END
  ELSE
    IF scan_keyword('bp')THEN
      BEGIN
        NUM := 7227;
        DENOM := 7200;
      END
  ELSE
    IF scan_keyword('dd')THEN
      BEGIN
        NUM := 1238;
        DENOM := 1157;
      END
  ELSE
    IF scan_keyword('cc')THEN
      BEGIN
        NUM := 14856;
        DENOM := 1157;
      END
  ELSE
    IF scan_keyword('sp')THEN GOTO 30
  ELSE{459:}
    BEGIN
      print_err('Illegal unit of measure (pt inserted)');
      help6('Dimensions can be in units of em, ex, in, pt, pc,',
            'cm, mm, dd, cc, bp, or sp; but yours is a new one!',
            'I''ll assume that you meant to say pt, for printer''s points.',
            'To recover gracefully from this error, it''s best to',
            'delete the erroneous units; e.g., type `2'' to delete',
            'two letters. (See Chapter 27 of The TeXbook.)');
      ERROR;
      GOTO 32;
    END{:459};
  CURVAL := XNOVERD(CURVAL,NUM,DENOM);
  F := (NUM*F+65536*REMAINDER)DIV DENOM;
  CURVAL := CURVAL+(F DIV 65536);
  F := F MOD 65536;
  32:{:458};
  88:
      IF CURVAL>=16384 THEN ARITHERROR := TRUE
      ELSE CURVAL := CURVAL*65536+F;
  30:{:453};{443:}
  BEGIN
    GETXTOKEN;
    IF CURCMD<>10 THEN BACKINPUT;
  END{:443};
  89:

  IF ARITHERROR OR(ABS(CURVAL)>=1073741824) THEN BEGIN
    {460:}
    print_err('Dimension too large');
    help2('I can''t work with sizes bigger than about 19 feet.',
          'Continue and I''ll use the largest value I can.');
    ERROR;
    CURVAL := 1073741823;
    ARITHERROR := FALSE;
    {:460}
  END;
  IF NEGATIVE THEN CURVAL := -CURVAL;
END;


PROCEDURE SCANGLUE(LEVEL:SMALLNUMBER);
VAR NEGATIVE: BOOLEAN;
  Q: HALFWORD;
  MU: BOOLEAN;
BEGIN
  MU := (LEVEL=3);
{441:}
  NEGATIVE := FALSE;
  REPEAT{406:}
    REPEAT
      GETXTOKEN;
    UNTIL CURCMD<>10{:406};
    IF CURTOK=3117 THEN
      BEGIN
        NEGATIVE := NOT NEGATIVE;
        CURTOK := 3115;
      END;
  UNTIL CURTOK<>3115{:441};
  IF (CURCMD>=68)AND(CURCMD<=89)THEN
    BEGIN
      SCANSOMETHIN(LEVEL,NEGATIVE);
      IF CURVALLEVEL>=2 THEN
        BEGIN
          IF CURVALLEVEL<>LEVEL THEN MUERROR;
          exit;
        END;
      IF CURVALLEVEL=0 THEN SCANDIMEN(MU,FALSE,TRUE)
      ELSE
        IF LEVEL=3 THEN
          MUERROR;
    END
  ELSE
    BEGIN
      BACKINPUT;
      SCANDIMEN(MU,FALSE,FALSE);
      IF NEGATIVE THEN CURVAL := -CURVAL;
    END;{462:}
  Q := NEWSPEC(0);
  MEM[Q+1].INT := CURVAL;
  IF scan_keyword('plus')THEN
    BEGIN
      SCANDIMEN(MU,TRUE,FALSE);
      MEM[Q+2].INT := CURVAL;
      MEM[Q].HH.B0 := CURORDER;
    END;
  IF scan_keyword('minus')THEN
    BEGIN
      SCANDIMEN(MU,TRUE,FALSE);
      MEM[Q+3].INT := CURVAL;
      MEM[Q].HH.B1 := CURORDER;
    END;
  CURVAL := Q{:462};
END;
{:461}

{463:}
FUNCTION SCANRULESPEC: HALFWORD;
VAR Q: HALFWORD;
BEGIN
  Q := NEWRULE;
  IF CURCMD=35 THEN MEM[Q+1].INT := 26214
  ELSE BEGIN
    MEM[Q+3].INT := 26214;
    MEM[Q+2].INT := 0;
  END;

  while true do begin
    IF scan_keyword('width') THEN BEGIN
      SCANDIMEN(FALSE,FALSE,FALSE);
      MEM[Q+1].INT := CURVAL;
    end else if scan_keyword('height') THEN BEGIN
      SCANDIMEN(FALSE,FALSE,FALSE);
      MEM[Q+3].INT := CURVAL;
    end else if scan_keyword('depth') THEN BEGIN
      SCANDIMEN(FALSE,FALSE,FALSE);
      MEM[Q+2].INT := CURVAL;
    end else break;
  end;
  SCANRULESPEC := Q;
END;
{:463}

{@ There's also a |fast_get_avail| routine, which saves the procedure-call
overhead at the expense of extra programming. This routine is used in
the places that would otherwise account for the most calls of |get_avail|.}

function fast_get_avail : HALFWORD; inline;
var Node: HALFWORD;
begin
  Node := AVAIL;
  if Node=0 then Node := GETAVAIL
  else begin
    AVAIL := MEM[Node].HH.RH;   { avail := link(Node); }
    MEM[Node].HH.RH := 0;       { link(Node) := null; }
{$IFDEF STATS}
    DYNUSED := DYNUSED+1;
{$ENDIF}
  end;
  fast_get_avail := Node;
end;

function fast_store_new_token(Node: HALFWORD; Token: HALFWORD) : HALFWORD; inline;
var q: HALFWORD;
begin
  q := fast_get_avail;
  MEM[Node].HH.RH := q;         { link(Node) := q; }
  MEM[q].HH.LH := Token;        { info(q) := Token; }
  fast_store_new_token := q;
end;

{@Before we get into the details of |scan_toks|, let's consider a much
simpler task, that of converting the current string into a token list.
The |str_toks| function does this; it classifies spaces as type |spacer|
and everything else as type |other_char|.

The token list created by |str_toks| begins at |link(temp_head)| and ends
at the value |p| that is returned. (If |p=temp_head|, the list is empty.)}

function str_toks(const s: utf8string): HALFWORD;
var
  Node: HALFWORD;
  Token: HALFWORD;
  i: uint32;
BEGIN
  Node := 29997;
  MEM[Node].HH.RH := 0;
  for i := 1 to length(s) do begin
    Token := ord(s[i]);
    IF Token=32 THEN Token := 2592
                ELSE Token := 3072+Token;
    Node := fast_store_new_token(Node, Token);
  end;
  str_toks := Node;
END;

{465:}
FUNCTION THETOKS: HALFWORD;
VAR
  P,Q,R: HALFWORD;
  s: shortstring;
BEGIN
  GETXTOKEN;
  SCANSOMETHIN(5,FALSE);
  IF CURVALLEVEL>=4 THEN BEGIN

    {466:}
    P := 29997;
    MEM[P].HH.RH := 0;
    IF CURVALLEVEL=4 THEN store_new_token(P, 4095+CURVAL)
    ELSE IF CURVAL<>0 THEN BEGIN
      R := MEM[CURVAL].HH.RH;
      WHILE R<>0 DO BEGIN
        BEGIN
          BEGIN
            Q := AVAIL;
            IF Q=0 THEN Q := GETAVAIL
            ELSE BEGIN
              AVAIL := MEM[Q].HH.RH;
              MEM[Q].HH.RH := 0;
{$IFDEF STATS}
              DYNUSED := DYNUSED+1;
{$ENDIF}
            END;
          END;
          MEM[P].HH.RH := Q;
          MEM[Q].HH.LH := MEM[R].HH.LH;
          P := Q;
        END;
        R := MEM[R].HH.RH;
      END;
    END;
    THETOKS := P;
    {:466}

  END ELSE BEGIN
    case CURVALLEVEL of
      0: str(CURVAL, s);
      1: s := print_scaled(CURVAL) + 'pt';
      2: begin
           s := print_spec(CURVAL, 'pt');
           DELETEGLUERE(CURVAL);
         end;
      3: begin
           s := print_spec(CURVAL, 'mu');
           DELETEGLUERE(CURVAL);
         end;
    end;
    THETOKS := str_toks(s);
  END;
END;
{:465}

{467:}
PROCEDURE INSTHETOKS;
BEGIN
  MEM[29988].HH.RH := THETOKS;
  BEGINTOKENLI(MEM[29997].HH.RH,4);
END;
{:467}

{470:}
PROCEDURE CONVTOKS;
VAR
  C: 0..5;
  SAVESCANNERS: SMALLNUMBER;
  s: utf8string;
  Token: HALFWORD;
BEGIN
  C := CURCHR;

  {@<Scan the argument for command |c|@>}
  CASE C OF 
    0,1: SCANINT;
    2,3: BEGIN
           SAVESCANNERS := SCANNERSTATU;
           SCANNERSTATU := 0;
           GETTOKEN;
           SCANNERSTATU := SAVESCANNERS;
         END;
    4: SCANFONTIDEN;
    5: IF job_name='' THEN OPENLOGFILE;
  END;

  case C of
    0:  s := print_int(CURVAL);
    1:  s := print_roman_int(CURVAL);
    2:  if CURCS<>0 then s := sprint_cs(CURCS)
                    else s := chr(CURCHR);
    3:  begin
          s := print_cmd_chr(CURCMD,CURCHR);
          if CURCMD>=110 then begin
            s := s + ':';
            Token := CURCHR;
            if CURCMD=110 then Token := CURMARK[CURCHR];
            if Token<>0 then
              s := s + show_token_list_simple(MEM[Token].HH.RH, 10000000);
          end;
        end;
    4:  begin
          s := GetString(FONTNAME[CURVAL]);
          if FONTSIZE[CURVAL]<>FONTDSIZE[CURVAL] then
            s := s +' at ' + print_scaled(FONTSIZE[CURVAL]) + 'pt';
        end;
    5:  s := job_name;
  end;
  MEM[29988].HH.RH := str_toks(s);

  BEGINTOKENLI(MEM[29997].HH.RH,4);
END;
{:470}



{497:}
PROCEDURE CHANGEIFLIMI(L:SMALLNUMBER;P:HALFWORD);
VAR Q: HALFWORD;
BEGIN
  IF P=CONDPTR THEN IFLIMIT := L
  ELSE
    BEGIN
      Q := CONDPTR;
      WHILE TRUE DO
        BEGIN
          IF Q=0 THEN confusion_str('if');
          IF MEM[Q].HH.RH=P THEN
            BEGIN
              MEM[Q].HH.B0 := L;
              exit;
            END;
          Q := MEM[Q].HH.RH;
        END;
    END;
END;
{:497}


{@<Pop the condition stack@>}
procedure PopConditionStack;
var P: HALFWORD;
begin
  P := CONDPTR;
  IFLINE := MEM[P+1].INT;  {if_line_field(p)}
  CURIF := MEM[P].HH.B1;   {subtype(p)}
  IFLIMIT := MEM[P].HH.B0; {type(p)}
  CONDPTR := MEM[P].HH.RH; {link(p)}
  FREENODE(P, 2{if_node_size});
end;


{498:}
PROCEDURE CONDITIONAL;
VAR B: BOOLEAN;
  R: 60..62;
  M,N: Int32;
  P,Q: HALFWORD;
  SAVESCANNERS: SMALLNUMBER;
  SAVECONDPTR: HALFWORD;
  THISIF: SMALLNUMBER;
BEGIN{495:}
  BEGIN
    P := GETNODE(2);
    MEM[P].HH.RH := CONDPTR;
    MEM[P].HH.B0 := IFLIMIT;
    MEM[P].HH.B1 := CURIF;
    MEM[P+1].INT := IFLINE;
    CONDPTR := P;
    CURIF := CURCHR;
    IFLIMIT := 1;
    IFLINE := LINE;
  END{:495};
  SAVECONDPTR := CONDPTR;
  THISIF := CURCHR;
{501:}
  CASE THISIF OF 
    0,1:{506:}
         BEGIN
           BEGIN
             GETXTOKEN;
             IF CURCMD=0 THEN
               IF CURCHR=257 THEN
                 BEGIN
                   CURCMD := 13;
                   CURCHR := CURTOK-4096;
                 END;
           END;
           IF (CURCMD>13)OR(CURCHR>255)THEN
             BEGIN
               M := 0;
               N := 256;
             END
           ELSE
             BEGIN
               M := CURCMD;
               N := CURCHR;
             END;
           BEGIN
             GETXTOKEN;
             IF CURCMD=0 THEN
               IF CURCHR=257 THEN
                 BEGIN
                   CURCMD := 13;
                   CURCHR := CURTOK-4096;
                 END;
           END;
           IF (CURCMD>13)OR(CURCHR>255)THEN
             BEGIN
               CURCMD := 0;
               CURCHR := 256;
             END;
           IF THISIF=0 THEN B := (N=CURCHR)
           ELSE B := (M=CURCMD);
         END{:506};
    2,3:{503:}
         BEGIN
           IF THISIF=2 THEN SCANINT
           ELSE SCANDIMEN(FALSE,FALSE,
                          FALSE);
           N := CURVAL;{406:}
           REPEAT
             GETXTOKEN;
           UNTIL CURCMD<>10{:406};
           IF (CURTOK>=3132)AND(CURTOK<=3134)THEN R := CURTOK-3072
           ELSE
             BEGIN
               print_err('Missing = inserted for ' + print_cmd_chr(105, THISIF));
               help1('I was expecting to see `<'', `='', or `>''. Didn''t.');
               BACKERROR;
               R := 61;
             END;
           IF THISIF=2 THEN SCANINT
           ELSE SCANDIMEN(FALSE,FALSE,FALSE);
           CASE R OF 
             60: B := (N<CURVAL);
             61: B := (N=CURVAL);
             62: B := (N>CURVAL);
           END;
         END{:503};
    4:{504:}
       BEGIN
         SCANINT;
         B := ODD(CURVAL);
       END{:504};
    5: B := (ABS(CURLIST.MODEFIELD)=1);
    6: B := (ABS(CURLIST.MODEFIELD)=102);
    7: B := (ABS(CURLIST.MODEFIELD)=203);
    8: B := (CURLIST.MODEFIELD<0);
    9,10,11:{505:}
             BEGIN
               SCANEIGHTBIT;
               P := EQTB[3678+CURVAL].HH.RH;
               IF THISIF=9 THEN B := (P=0)
               ELSE
                 IF P=0 THEN B := FALSE
               ELSE
                 IF THISIF=10
                   THEN B := (MEM[P].HH.B0=0)
               ELSE B := (MEM[P].HH.B0=1);
             END{:505};
    12:{507:}
        BEGIN
          SAVESCANNERS := SCANNERSTATU;
          SCANNERSTATU := 0;
          get_next(true);
          N := CURCS;
          P := CURCMD;
          Q := CURCHR;
          get_next(true);
          IF CURCMD<>P THEN B := FALSE
          ELSE
            IF CURCMD<111 THEN B := (CURCHR=Q)
          ELSE
{508:}
            BEGIN
              P := MEM[CURCHR].HH.RH;
              Q := MEM[EQTB[N].HH.RH].HH.RH;
              IF P=Q THEN B := TRUE
              ELSE
                BEGIN
                  WHILE (P<>0)AND(Q<>0) DO
                    IF MEM[P].HH.LH<>
                       MEM[Q].HH.LH THEN P := 0
                    ELSE
                      BEGIN
                        P := MEM[P].HH.RH;
                        Q := MEM[Q].HH.RH;
                      END;
                  B := ((P=0)AND(Q=0));
                END;
            END{:508};
          SCANNERSTATU := SAVESCANNERS;
        END{:507};
    13:
        BEGIN
          SCANFOURBITI;
          B := (READOPEN[CURVAL]=2);
        END;
    14: B := TRUE;
    15: B := FALSE;
    16:
        BEGIN
          {509:}
          SCANINT;
          N := CURVAL;
          IF EQTB[5299].INT>1 THEN BEGIN
            BEGINDIAGNOS;
            print_str('{case ');
            PRINTINT(N);
            PRINTCHAR(125);
            ENDDIAGNOSTI(FALSE);
          END;
          WHILE N<>0 DO BEGIN
            PASSTEXT;
            IF CONDPTR=SAVECONDPTR
            THEN IF CURCHR=4
                 THEN N := N-1
                 ELSE IF CURCHR=2
                      THEN PopConditionStack
                      ELSE IFLIMIT := 2
            ELSE IF CURCHR=2
                 THEN PopConditionStack;
          END;
          CHANGEIFLIMI(4,SAVECONDPTR);
          exit;
          {:509}
        END;
  END{:501};
  IF EQTB[5299].INT>1 THEN{502:}
    BEGIN
      BEGINDIAGNOS;
      IF B THEN print_str('{true}')
      ELSE print_str('{false}');
      ENDDIAGNOSTI(FALSE);
    END{:502};
  IF B THEN
    BEGIN
      CHANGEIFLIMI(3,SAVECONDPTR);
      exit;
    END;
{500:}
  WHILE TRUE DO BEGIN
    PASSTEXT;
    IF CONDPTR=SAVECONDPTR THEN BEGIN
      IF CURCHR<>4 THEN break;
      print_err('Extra ' + print_esc('or'));
      help1('I''m ignoring this; it doesn''t match any \if.');
      ERROR;
    END ELSE IF CURCHR=2 THEN PopConditionStack;
  END;
  IF CURCHR=2 THEN PopConditionStack
              ELSE IFLIMIT := 2;
END;
{:498}





PROCEDURE EXPAND;
VAR T: HALFWORD;
  P,Q,R: HALFWORD;
  J: 0..BUFSIZE;
  CVBACKUP: Int32;
  CVLBACKUP,RADIXBACKUP,COBACKUP: SMALLNUMBER;
  BACKUPBACKUP: HALFWORD;
  SAVESCANNERS: SMALLNUMBER;
BEGIN
  CVBACKUP := CURVAL;
  CVLBACKUP := CURVALLEVEL;
  RADIXBACKUP := RADIX;
  COBACKUP := CURORDER;
  BACKUPBACKUP := MEM[29987].HH.RH;
  IF CURCMD<111 THEN BEGIN
    {367:}
    IF EQTB[5299].INT>1 THEN SHOWCURCMDCH;
    CASE CURCMD OF 
      110: BEGIN
            {386:}
            IF CURMARK[CURCHR]<>0 THEN BEGINTOKENLI(CURMARK[CURCHR],14);
            {:386}
           END;
      102: BEGIN
            {368:}
            GETTOKEN;
            T := CURTOK;
            GETTOKEN;
            IF CURCMD>100 THEN EXPAND
                          ELSE BACKINPUT;
            CURTOK := T;
            BACKINPUT;
            {:368}
           END;

        103:{369:}
             BEGIN
               SAVESCANNERS := SCANNERSTATU;
               SCANNERSTATU := 0;
               GETTOKEN;
               SCANNERSTATU := SAVESCANNERS;
               T := CURTOK;
               BACKINPUT;
               IF T>=4095 THEN
                 BEGIN
                   P := GETAVAIL;
                   MEM[P].HH.LH := 6718;
                   MEM[P].HH.RH := CURINPUT.LOCFIELD;
                   CURINPUT.STARTFIELD := P;
                   CURINPUT.LOCFIELD := P;
                 END;
             END{:369};
        107:{372:}
             BEGIN
               R := GETAVAIL;
               P := R;
               REPEAT
                 GETXTOKEN;
                 IF CURCS=0 THEN store_new_token(P, CURTOK);
               UNTIL CURCS<>0;
               IF CURCMD<>67 THEN BEGIN
                   {373:}
                   print_err('Missing ' + print_esc('endcsname') + ' inserted');
                   help2('The control sequence marked <to be read again> should',
                         'not appear between \csname and \endcsname.');
                   BACKERROR;
                   {:373}
                 END;
{374:}
               J := FIRST;
               P := MEM[R].HH.RH;
               WHILE P<>0 DO
                 BEGIN
                   IF J>=MAXBUFSTACK THEN
                     BEGIN
                       MAXBUFSTACK := J+1;
                       IF MAXBUFSTACK=BUFSIZE THEN overflow('buffer size', BUFSIZE);
                     END;
                   BUFFER[J] := MEM[P].HH.LH MOD 256;
                   J := J+1;
                   P := MEM[P].HH.RH;
                 END;
               IF J>FIRST+1 THEN
                 BEGIN
                   CURCS := id_lookup(false, FIRST, J-FIRST);
                 END
               ELSE
                 IF J=FIRST THEN CURCS := 513
               ELSE CURCS := 257+BUFFER[FIRST]{:374};
               FLUSHLIST(R);
               IF EQTB[CURCS].HH.B0=101 THEN
                 BEGIN
                   EQDEFINE(CURCS,0,256);
                 END;
               CURTOK := CURCS+4095;
               BACKINPUT;
             END{:372};
      108: CONVTOKS;
      109: INSTHETOKS;
      105: CONDITIONAL;
      106: begin
            {510:}
            IF CURCHR>IFLIMIT THEN begin
              IF IFLIMIT=1 THEN INSERTRELAX
              ELSE BEGIN
                print_err('Extra ' +  print_cmd_chr(106,CURCHR));
                help1('I''m ignoring this; it doesn''t match any \if.');
                ERROR;
              END
            end ELSE BEGIN
              WHILE CURCHR<>2 DO PASSTEXT;
              PopConditionStack;
            END;
            {:510}
           end;
      104: begin
            {@<Initiate or terminate input from a file@>}
            IF CURCHR>0 THEN FORCEEOF := TRUE
            ELSE IF NAMEINPROGRE THEN INSERTRELAX
            ELSE STARTINPUT;
           end;
      else begin
            {370:}
            print_err('Undefined control sequence');
            help5('The control sequence at the end of the top line',
                  'of your error message was never \def''ed. If you have',
                  'misspelled it (e.g., `\hobx''), type `I'' and the correct',
                  'spelling (e.g., `I\hbox''). Otherwise just continue,',
                  'and I''ll forget about whatever was undefined.');
            ERROR;
            {:370}
          END;
      END;
    END{:367}
  ELSE IF CURCMD<115 THEN MACROCALL
  ELSE{375:}
    BEGIN
      CURTOK := 6715;
      BACKINPUT;
    END{:375};
  CURVAL := CVBACKUP;
  CURVALLEVEL := CVLBACKUP;
  RADIX := RADIXBACKUP;
  CURORDER := COBACKUP;
  MEM[29987].HH.RH := BACKUPBACKUP;
END;
{:366}

{380:}
PROCEDURE GETXTOKEN;
BEGIN
  while true do begin
    get_next(true);
    if CURCMD<=100 then break;
    if CURCMD<111 then EXPAND
    else if CURCMD<115 then MACROCALL
    else begin
      CURCS := 2620;
      CURCMD := 9;
      break;
    end;
  end;
  IF CURCS=0 then CURTOK := (CURCMD*256)+CURCHR
             else CURTOK := 4095+CURCS;
END;
{:380}

{381:}
PROCEDURE XTOKEN;
BEGIN
  WHILE CURCMD>100 DO BEGIN
    EXPAND;
    get_next(true);
  END;
  IF CURCS=0 THEN CURTOK := (CURCMD*256)+CURCHR
             ELSE CURTOK := 4095+CURCS;
END;
{:381}


{581:}
PROCEDURE CHARWARNING(F: INTERNALFONT; C: EIGHTBITS);
BEGIN
  IF EQTB[5298].INT>0 THEN
    BEGIN
      BEGINDIAGNOS;
      print_nl_str('Missing character: There is no ');
      slow_print_char(C);
      print_str(' in font ');
      SLOWPRINT(FONTNAME[F]);
      PRINTCHAR(33);
      ENDDIAGNOSTI(FALSE);
    END;
END;
{:581}

{582:}
FUNCTION NEWCHARACTER(F:INTERNALFONT;C:EIGHTBITS): HALFWORD;
VAR P: HALFWORD;
BEGIN
  IF FONTBC[F]<=C THEN
    IF FONTEC[F]>=C THEN
      IF (FONTINFO[CHARBASE[F]+
         C+0].QQQQ.B0>0)THEN
        BEGIN
          P := GETAVAIL;
          MEM[P].HH.B0 := F;
          MEM[P].HH.B1 := C+0;
          NEWCHARACTER := P;
          exit;
        END;
  CHARWARNING(F,C);
  NEWCHARACTER := 0;
END;
{:582}


{@<Scan and build the body of the token list; |goto found| when finished@>}
procedure BuildTokenListBody(var Node: HALFWORD;
                             NumParams: HALFWORD;
                             MacroDef: boolean;
                             Xpand: boolean);
var
  S: HALFWORD;
  Q: HALFWORD;
  UNBALANCE: HALFWORD;
begin
  {477:}
  UNBALANCE := 1;
  WHILE TRUE DO BEGIN
    IF Xpand THEN BEGIN
      {478:}
      WHILE TRUE DO BEGIN
        get_next(true);
        IF CURCMD<=100 THEN break;
        IF CURCMD<>109 THEN EXPAND
        ELSE BEGIN
          Q := THETOKS;
          IF MEM[29997].HH.RH<>0 THEN BEGIN
            MEM[Node].HH.RH := MEM[29997].HH.RH;
            Node := Q;
          END;
        END;
      END;
      XTOKEN
      {:478}
    END ELSE GETTOKEN;
    IF CURTOK<768 THEN begin
      IF CURCMD<2 THEN UNBALANCE := UNBALANCE+1
      ELSE BEGIN
        UNBALANCE := UNBALANCE-1;
        IF UNBALANCE=0 THEN break;
      END
    end ELSE IF CURCMD=6 THEN begin
      IF MACRODEF THEN BEGIN
        {479:}
        S := CURTOK;
        IF XPAND THEN GETXTOKEN
                 ELSE GETTOKEN;
        IF CURCMD<>6 THEN begin
          IF (CURTOK<=3120) OR (CURTOK>NumParams) THEN BEGIN
            print_err('Illegal parameter number in definition of ' + sprint_cs(WARNINGINDEX));
            help3('You meant to type ## instead of #, right?',
                  'Or maybe a } was forgotten somewhere earlier, and things',
                  'are all screwed up? I''m going to assume that you meant ##.');
            BACKERROR;
            CURTOK := S;
          END ELSE CURTOK := 1232+CURCHR;
        end;
        {:479}
      END;
    end;
    store_new_token(Node, CURTOK);
  END;
  {:477}
end;


{473:}
FUNCTION SCANTOKS(MACRODEF,XPAND:BOOLEAN): HALFWORD;
VAR
  T: HALFWORD;
  S: HALFWORD;
  P: HALFWORD;
  HASHBRACE: HALFWORD;
BEGIN
  IF MACRODEF THEN SCANNERSTATU := 2
  ELSE SCANNERSTATU := 5;
  WARNINGINDEX := CURCS;
  DEFREF := GETAVAIL;
  MEM[DEFREF].HH.LH := 0;
  P := DEFREF;
  HASHBRACE := 0;
  T := 3120;
  IF MACRODEF THEN BEGIN
    {474:} {@<Scan and build the parameter part of the macro definition@>}
    WHILE TRUE DO BEGIN
      GETTOKEN;
      IF CURTOK<768 THEN break;
      IF CURCMD=6 THEN BEGIN
        S := 3328+CURCHR;
        GETTOKEN;
        IF CURTOK<512 THEN BEGIN
          HASHBRACE := CURTOK;
          store_new_token(P, CURTOK);
          store_new_token(P, 3584);
          BuildTokenListBody(P, T, MACRODEF, XPAND);
          SCANNERSTATU := 0; {normal}
          IF HASHBRACE<>0 THEN store_new_token(P, HASHBRACE);
          SCANTOKS := P;
          exit;
        END;
        IF T=3129 THEN BEGIN
          print_err('You already have nine parameters');
          help2('I''m going to ignore the # sign you just used,',
                'as well as the token that followed it.');
          ERROR;
        END ELSE BEGIN
          T := T+1;
          IF CURTOK<>T THEN BEGIN
            print_err('Parameters must be numbered consecutively');
            help2('I''ve inserted the digit you should have used after the #.',
                  'Type `1'' to delete what you did use.');
            BACKERROR;
          END;
          CURTOK := S;
          store_new_token(P, CURTOK);
        END;
      END else store_new_token(P, CURTOK);
    END;

    store_new_token(P, 3584);
    IF CURCMD=2 THEN BEGIN
      {475:}
      ALIGNSTATE := ALIGNSTATE+1;
      print_err('Missing { inserted');
      help2('Where was the left brace? You said something like `\def\a}'',',
            'which I''m going to interpret as `\def\a{}''.');
      ERROR;
      SCANNERSTATU := 0; {normal}
      IF HASHBRACE<>0 THEN store_new_token(P, HASHBRACE);
      SCANTOKS := P;
      exit;
      {:475}
    END;
    {:474}
  END ELSE SCANLEFTBRAC; {remove the compulsory left brace}

  BuildTokenListBody(P, T, MACRODEF, XPAND);
  SCANNERSTATU := 0; {normal}
  IF HASHBRACE<>0 THEN store_new_token(P, HASHBRACE);
  SCANTOKS := P;
END;


PROCEDURE READTOKS(N:Int32;R:HALFWORD);
VAR P: HALFWORD;
  Q: HALFWORD;
  S: Int32;
  M: SMALLNUMBER;
BEGIN
  SCANNERSTATU := 2;
  WARNINGINDEX := R;
  DEFREF := GETAVAIL;
  MEM[DEFREF].HH.LH := 0;
  P := DEFREF;
  store_new_token(P, 3584);
  IF (N<0)OR(N>15)THEN M := 16
  ELSE M := N;
  S := ALIGNSTATE;
  ALIGNSTATE := 1000000;
  REPEAT{483:}
    BEGINFILEREA;
    CURINPUT.NAMEFIELD := M+1;
    IF READOPEN[M]=2 THEN{484:}
      IF INTERACTION>1 THEN
        IF N<0 THEN
          BEGIN;
            print_str('');
            TERMINPUT;
          END
    ELSE
      BEGIN;
        PRINTLN;
        print_str(sprint_cs(R));
        BEGIN;
          PRINTCHAR(61);
          TERMINPUT;
        END;
        N := -1;
      END
    ELSE fatal_error('*** (cannot \read from terminal in nonstop modes)'){:484}
    ELSE
      IF READOPEN[M]=1 THEN{485:}
        IF INPUTLN
           (READFILE[M],FALSE)THEN READOPEN[M] := 0
    ELSE
      BEGIN
        close(READFILE[M]);
        READOPEN[M] := 2;
      END{:485}
    ELSE{486:}
      BEGIN
        IF NOT INPUTLN(READFILE[M],TRUE)THEN
          BEGIN
            close(READFILE[M]);
            READOPEN[M] := 2;
            IF ALIGNSTATE<>1000000 THEN
              BEGIN
                RUNAWAY;
                print_err('File ended within ' + print_esc('read'));
                help1('This \read has unbalanced braces.');
                ALIGNSTATE := 1000000;
                CURINPUT.LIMITFIELD := 0;
                ERROR;
              END;
          END;
      END{:486};
    CURINPUT.LIMITFIELD := LAST;
    IF (EQTB[5311].INT<0)OR(EQTB[5311].INT>255)
      THEN CURINPUT.LIMITFIELD := CURINPUT.LIMITFIELD-1
      ELSE BUFFER[CURINPUT.LIMITFIELD] := EQTB[5311].INT;
    FIRST := CURINPUT.LIMITFIELD+1;
    CURINPUT.LOCFIELD := CURINPUT.STARTFIELD;
    CURINPUT.STATEFIELD := 33;
    WHILE TRUE DO BEGIN
      GETTOKEN;
      IF CURTOK=0 THEN break;
      IF ALIGNSTATE<1000000 THEN BEGIN
        REPEAT
          GETTOKEN;
        UNTIL CURTOK=0;
        ALIGNSTATE := 1000000;
        break;
      END;
      store_new_token(P, CURTOK);
    END;
    ENDFILEREADI{:483};
  UNTIL ALIGNSTATE=1000000;
  CURVAL := DEFREF;
  SCANNERSTATU := 0;
  ALIGNSTATE := S;
END;
{:482}














{ ----------------------------------------------------------------------
  Device-independent file format
  ---------------------------------------------------------------------- }







{597:}
PROCEDURE WRITEDVI(A,B: DVIINDEX);
BEGIN
  blockwrite(DVIFILE, DVIBUF[A], B-A+1);
END;
{:597}

{598:}
PROCEDURE DVISWAP;
BEGIN
  IF DVILIMIT=dvi_buf_size THEN
    BEGIN
      WRITEDVI(0,HALFBUF-1);
      DVILIMIT := HALFBUF;
      DVIOFFSET := DVIOFFSET+dvi_buf_size;
      DVIPTR := 0;
    END
  ELSE
    BEGIN
      WRITEDVI(HALFBUF,dvi_buf_size-1);
      DVILIMIT := dvi_buf_size;
    END;
  DVIGONE := DVIGONE+HALFBUF;
END;
{:598}

procedure dvi_out(b: byte); inline;
begin
  DVIBUF[DVIPTR] := b;
  DVIPTR := DVIPTR+1;
  IF DVIPTR=DVILIMIT THEN DVISWAP;
end;

{600:}
PROCEDURE DVIFOUR(X:Int32);
BEGIN
  IF X>=0 
  THEN dvi_out(X DIV 16777216)
  ELSE BEGIN
    X := X+1073741824;
    X := X+1073741824;
    dvi_out((X DIV 16777216)+128);
  END;
  X := X MOD 16777216;
  dvi_out(X DIV 65536);
  X := X MOD 65536;
  dvi_out(X div 256);
  dvi_out(X mod 256);
END;

PROCEDURE DVIPOP(L:Int32);
BEGIN
  IF (L=DVIOFFSET+DVIPTR)AND(DVIPTR>0)THEN DVIPTR := DVIPTR-1
  ELSE dvi_out(142);
END;

PROCEDURE DVIFONTDEF(F:INTERNALFONT);
VAR K: POOLPOINTER;
BEGIN
  dvi_out(243);
  dvi_out(F-1);
  dvi_out(FONTCHECK[F].B0);
  dvi_out(FONTCHECK[F].B1);
  dvi_out(FONTCHECK[F].B2);
  dvi_out(FONTCHECK[F].B3);
  DVIFOUR(FONTSIZE[F]);
  DVIFOUR(FONTDSIZE[F]);
  dvi_out(STRSTART[FONTAREA[F]+1]-STRSTART[FONTAREA[F]]);
  dvi_out(STRSTART[FONTNAME[F]+1]-STRSTART[FONTNAME[F]]);
  FOR K:=STRSTART[FONTAREA[F]]TO STRSTART[FONTAREA[F]+1]-1 DO
    dvi_out(STRPOOL[K]);
  FOR K:=STRSTART[FONTNAME[F]]TO STRSTART[FONTNAME[F]+1]-1 DO
    dvi_out(STRPOOL[K]);
END;


{@ Here is a subroutine that produces a \DVI command for some specified
downward or rightward motion. It has two parameters: |w| is the amount
of motion, and |o| is either |down1| or |right1|. We use the fact that
the command codes have convenient arithmetic properties: |y1-down1=w1-right1|
and |z1-down1=x1-right1|.}

PROCEDURE MOVEMENT(W:SCALED;O:EIGHTBITS);
VAR
  MSTATE: SMALLNUMBER;
  P,Q: HALFWORD;
  K: Int32;
BEGIN
  Q := GETNODE(3);
  MEM[Q+1].INT := W;
  MEM[Q+2].INT := DVIOFFSET+DVIPTR;
  IF O=157 THEN BEGIN
    MEM[Q].HH.RH := DOWNPTR;
    DOWNPTR := Q;
  END ELSE BEGIN
    MEM[Q].HH.RH := RIGHTPTR;
    RIGHTPTR := Q;
  END;

  {@<Look at the other stack entries until deciding what sort of \DVI command
   to generate; |goto found| if node |p| is a ``hit''@>}
  P := MEM[Q].HH.RH;
  MSTATE := 0;
  WHILE P<>0 DO BEGIN
    IF MEM[P+1].INT=W THEN begin

      {@<Consider a node with matching width; |goto found| if it's a hit@>}
      CASE MSTATE+MEM[P].HH.LH OF 
        3,4,15,16:
            begin
              IF MEM[P+2].INT<DVIGONE THEN break; {not found}

              {@<Change buffered instruction to |y| or |w| and |goto found|@>}
              K := MEM[P+2].INT-DVIOFFSET;
              IF K<0 THEN K := K+dvi_buf_size;
              DVIBUF[K] := DVIBUF[K]+5;
              MEM[P].HH.LH := 1;
              {fallthrough to found}
            end;
        5,9,11:
            begin
              IF MEM[P+2].INT<DVIGONE THEN break; {not found}

              {@<Change buffered instruction to |z| or |x| and |goto found|@>}
              K := MEM[P+2].INT-DVIOFFSET;
              IF K<0 THEN K := K+dvi_buf_size;
              DVIBUF[K] := DVIBUF[K]+10;
              MEM[P].HH.LH := 2;
              {fallthrough to found}
            end;
        1,2,8,13: ;
              {fallthrough to found}
        else begin
              P := MEM[P].HH.RH;
              continue;
            end;
      END;

      {found:}
      {@<Generate a |y0| or |z0| command in order to reuse a previous appearance of~|w|@>}
      MEM[Q].HH.LH := MEM[P].HH.LH;
      IF MEM[Q].HH.LH=1 THEN BEGIN
        dvi_out(O+4);
        WHILE MEM[Q].HH.RH<>P DO BEGIN
          Q := MEM[Q].HH.RH;
          CASE MEM[Q].HH.LH OF 
            3: MEM[Q].HH.LH := 5;
            4: MEM[Q].HH.LH := 6;
          END;
        END;
      END ELSE BEGIN
        dvi_out(O+9);
        WHILE MEM[Q].HH.RH<>P DO BEGIN
          Q := MEM[Q].HH.RH;
          CASE MEM[Q].HH.LH OF 
            3: MEM[Q].HH.LH := 4;
            5: MEM[Q].HH.LH := 6;
          END;
        END;
      END;
      exit;

    end else begin
      CASE MSTATE+MEM[P].HH.LH OF 
        1:  MSTATE := 6;
        2:  MSTATE := 12;
        8,
        13: break; {not found}
      END;
    end;
    P := MEM[P].HH.RH;
  END;

  {not found:}
  {@<Generate a |down| or |right| command for |w| and |return|@>}
  MEM[Q].HH.LH := 3;
  IF ABS(W)>=8388608 THEN BEGIN
    dvi_out(O+3);
    DVIFOUR(W);
  end else begin
    IF ABS(W)>=32768 THEN BEGIN
      dvi_out(O+2);
      IF W<0 THEN W := W+16777216;
      dvi_out(W DIV 65536);
      W := W MOD 65536;
      dvi_out(W div 256);
    end else if ABS(W)>=128 THEN BEGIN
      dvi_out(O+1);
      IF W<0 THEN W := W+65536;
      dvi_out(W div 256);
    end else begin
      dvi_out(O);
      IF W<0 THEN W := W+256;
    end;
    dvi_out(W mod 256);
  end;
END;

procedure synch_h; inline;
begin
  IF CURH<>DVIH THEN BEGIN
    MOVEMENT(CURH-DVIH,143);
    DVIH := CURH;
  END;
end;

procedure synch_v; inline;
begin
  IF CURV<>DVIV THEN BEGIN
    MOVEMENT(CURV-DVIV,157);
    DVIV := CURV;
  END;
end;

PROCEDURE PRUNEMOVEMEN(L:Int32);
VAR P: HALFWORD;
BEGIN
  WHILE DOWNPTR<>0 DO BEGIN
    IF MEM[DOWNPTR+2].INT<L THEN break;
    P := DOWNPTR;
    DOWNPTR := MEM[P].HH.RH;
    FREENODE(P,3);
  END;
  WHILE RIGHTPTR<>0 DO BEGIN
    IF MEM[RIGHTPTR+2].INT<L THEN exit;
    P := RIGHTPTR;
    RIGHTPTR := MEM[P].HH.RH;
    FREENODE(P,3);
  END;
END;



PROCEDURE SPECIALOUT(P:HALFWORD);
var
  s: utf8string;
  i: sizeuint;
BEGIN
  synch_h;
  synch_v;

  {FIXME: maximum length not POOLSIZE}
  s := show_token_list_simple(MEM[MEM[P+1].HH.RH].HH.RH, POOLSIZE);
  if length(s)<256 then begin
    dvi_out(239);
    dvi_out(length(s));
  end else begin
    dvi_out(242);
    DVIFOUR(length(s));
  end;

  {FIXME: blockwise memory copy}
  for i := 1 to length(s) do dvi_out(ord(s[i]));
END;
{:1368}

procedure TokenShowToFile(FileNo: byte);
var
  s: utf8string;
begin
  s := show_token_list_simple(MEM[DEFREF].HH.RH, 10000000);
  writeln(WRITEFILE[FileNo], s);
  { with WRITEFILE = byte_file:
  s := show_token_list_simple(MEM[DEFREF].HH.RH, 10000000) + lineending;
  blockwrite(WRITEFILE[FileNo], s[1], length(s));
  }
end;

{1370:}
PROCEDURE WRITEOUT(P:HALFWORD);
VAR
  OLDSETTING: 16..19;
  OLDMODE: Int32;
  J: SMALLNUMBER;
  Q,R: HALFWORD;
BEGIN{1371:}
  Q := GETAVAIL;
  MEM[Q].HH.LH := 637;
  R := GETAVAIL;
  MEM[Q].HH.RH := R;
  MEM[R].HH.LH := 6717;
  BEGINTOKENLI(Q,4);
  BEGINTOKENLI(MEM[P+1].HH.RH,15);
  Q := GETAVAIL;
  MEM[Q].HH.LH := 379;
  BEGINTOKENLI(Q,4);
  OLDMODE := CURLIST.MODEFIELD;
  CURLIST.MODEFIELD := 0;
  CURCS := WRITELOC;
  Q := SCANTOKS(FALSE,TRUE);
  GETTOKEN;
  IF CURTOK<>6717 THEN{1372:}
    BEGIN
      print_err('Unbalanced write command');
      help2('On this page there''s a \write with fewer real {''s than }''s.',
            'I can''t handle that very well; good luck.');
      ERROR;
      REPEAT
        GETTOKEN;
      UNTIL CURTOK=6717;
    END{:1372};
  CURLIST.MODEFIELD := OLDMODE;
  ENDTOKENLIST{:1371};
  J := MEM[P+1].HH.LH;

  IF WRITEOPEN[J] THEN begin
    IF DEFREF<>0 THEN TokenShowToFile(J);
  end ELSE BEGIN 
    {Is this case really neccessary?}
    OLDSETTING := SELECTOR;
    IF (J=17) AND (SELECTOR=19) THEN SELECTOR := 18;
    print_nl_str('');
    IF DEFREF<>0 THEN print_utf8str(show_token_list_simple(MEM[DEFREF].HH.RH, 10000000));
    PRINTLN;
    SELECTOR := OLDSETTING;
  END;
  FLUSHLIST(DEFREF);
END;
{:1370}

{1373:}
PROCEDURE OUTWHAT(P:HALFWORD);
VAR 
  J: SMALLNUMBER;
  FileName: shortstring;
BEGIN
  CASE MEM[P].HH.B1 OF 
    0,1,2:{1374:}
           IF NOT DOINGLEADERS THEN
             BEGIN
               J 
               := MEM[P+1].HH.LH;
               IF MEM[P].HH.B1=1 THEN WRITEOUT(P)
               ELSE
                 BEGIN
                   IF WRITEOPEN[J]THEN close(WRITEFILE[J]);
                   IF MEM[P].HH.B1=2 THEN WRITEOPEN[J] := FALSE
                   ELSE
                     IF J<16 THEN
                       BEGIN
                         FileName := GetString(MEM[P+1].HH.RH);
                         while not a_open_out(WRITEFILE[J], FileName) do begin
                           FileName := prompt_file_name(FileName, 'output file name', '.tex');
                         end;

                         WRITEOPEN[J] := TRUE;
                       END;
                 END;
             END{:1374};
    3: SPECIALOUT(P);
    4:;
    ELSE confusion_str('ext4')
  END;
END;

PROCEDURE VLISTOUT; FORWARD;


PROCEDURE HLISTOUT;

LABEL 21,13,14,15;

VAR BASELINE: SCALED;
  LEFTEDGE: SCALED;
  SAVEH,SAVEV: SCALED;
  THISBOX: HALFWORD;
  GORDER: GLUEORD;
  GSIGN: 0..2;
  P: HALFWORD;
  SAVELOC: Int32;
  LEADERBOX: HALFWORD;
  LEADERWD: SCALED;
  LX: SCALED;
  OUTERDOINGLE: BOOLEAN;
  EDGE: SCALED;
  GLUETEMP: Double;
  CURGLUE: Double;
  CURG: SCALED;
BEGIN
  CURG := 0;
  CURGLUE := 0.0;
  THISBOX := TEMPPTR;
  GORDER := MEM[THISBOX+5].HH.B1;
  GSIGN := MEM[THISBOX+5].HH.B0;
  P := MEM[THISBOX+5].HH.RH;
  CURS := CURS+1;
  IF CURS>0 THEN dvi_out(141);
  IF CURS>MAXPUSH THEN MAXPUSH := CURS;
  SAVELOC := DVIOFFSET+DVIPTR;
  BASELINE := CURV;
  LEFTEDGE := CURH;
  WHILE P<>0 DO{620:}
    21:
        IF (P>=HIMEMMIN)THEN
          BEGIN
            synch_h;
            synch_v;
            REPEAT
              F := MEM[P].HH.B0;
              C := MEM[P].HH.B1;
              IF F<>DVIF THEN{621:}
                BEGIN
                  IF NOT FONTUSED[F]THEN
                    BEGIN
                      DVIFONTDEF(F);
                      FONTUSED[F] := TRUE;
                    END;
                  IF F<=64 THEN dvi_out(F+170)
                  ELSE
                    BEGIN
                      dvi_out(235);
                      dvi_out(F-1);
                    END;
                  DVIF := F;
                END{:621};
              IF C>=128 THEN dvi_out(128);
              dvi_out(C);
              CURH := CURH+FONTINFO[WIDTHBASE[F]+FONTINFO[CHARBASE[F]+C].QQQQ.B0].INT;
              P := MEM[P].HH.RH;
            UNTIL NOT(P>=HIMEMMIN);
            DVIH := CURH;
          END
        ELSE{622:}
          BEGIN
            CASE MEM[P].HH.B0 OF 
              0,1:{623:}
                   IF MEM[P+5].HH.RH=0
                     THEN CURH := CURH+MEM[P+1].INT
                   ELSE
                     BEGIN
                       SAVEH := DVIH;
                       SAVEV := DVIV;
                       CURV := BASELINE+MEM[P+4].INT;
                       TEMPPTR := P;
                       EDGE := CURH;
                       IF MEM[P].HH.B0=1 THEN VLISTOUT
                                         ELSE HLISTOUT;
                       DVIH := SAVEH;
                       DVIV := SAVEV;
                       CURH := EDGE+MEM[P+1].INT;
                       CURV := BASELINE;
                     END{:623};
              2:
                 BEGIN
                   RULEHT := MEM[P+3].INT;
                   RULEDP := MEM[P+2].INT;
                   RULEWD := MEM[P+1].INT;
                   GOTO 14;
                 END;
              8:{1367:}OUTWHAT(P){:1367};
              10:{625:}
                  BEGIN
                    G := MEM[P+1].HH.LH;
                    RULEWD := MEM[G+1].INT-CURG;
                    IF GSIGN<>0 THEN
                      BEGIN
                        IF GSIGN=1 THEN
                          BEGIN
                            IF MEM[G].HH.B0=GORDER THEN
                              BEGIN
                                CURGLUE := CURGLUE+MEM[G+2].INT;
                                GLUETEMP := MEM[THISBOX+6].GR*CURGLUE;
                                IF GLUETEMP>1000000000.0 THEN GLUETEMP := 1000000000.0
                                ELSE
                                  IF GLUETEMP<
                                     -1000000000.0 THEN GLUETEMP := -1000000000.0;
                                CURG := ISORound(GLUETEMP);
                              END;
                          END
                        ELSE
                          IF MEM[G].HH.B1=GORDER THEN
                            BEGIN
                              CURGLUE := CURGLUE-MEM[G+3].INT
                              ;
                              GLUETEMP := MEM[THISBOX+6].GR*CURGLUE;
                              IF GLUETEMP>1000000000.0 THEN GLUETEMP := 1000000000.0
                              ELSE
                                IF GLUETEMP<
                                   -1000000000.0 THEN GLUETEMP := -1000000000.0;
                              CURG := ISORound(GLUETEMP);
                            END;
                      END;
                    RULEWD := RULEWD+CURG;
                    IF MEM[P].HH.B1>=100 THEN{626:}
                      BEGIN
                        LEADERBOX := MEM[P+1].HH.RH;
                        IF MEM[LEADERBOX].HH.B0=2 THEN
                          BEGIN
                            RULEHT := MEM[LEADERBOX+3].INT;
                            RULEDP := MEM[LEADERBOX+2].INT;
                            GOTO 14;
                          END;
                        LEADERWD := MEM[LEADERBOX+1].INT;
                        IF (LEADERWD>0)AND(RULEWD>0)THEN
                          BEGIN
                            RULEWD := RULEWD+10;
                            EDGE := CURH+RULEWD;
                            LX := 0;
{627:}
                            IF MEM[P].HH.B1=100 THEN
                              BEGIN
                                SAVEH := CURH;
                                CURH := LEFTEDGE+LEADERWD*((CURH-LEFTEDGE)DIV LEADERWD);
                                IF CURH<SAVEH THEN CURH := CURH+LEADERWD;
                              END
                            ELSE
                              BEGIN
                                LQ := RULEWD DIV LEADERWD;
                                LR := RULEWD MOD LEADERWD;
                                IF MEM[P].HH.B1=101 THEN CURH := CURH+(LR DIV 2)
                                ELSE
                                  BEGIN
                                    LX := LR DIV(LQ+1
                                          );
                                    CURH := CURH+((LR-(LQ-1)*LX)DIV 2);
                                  END;
                              END{:627};
                            WHILE CURH+LEADERWD<=EDGE DO{628:}
                              BEGIN
                                CURV := BASELINE+MEM[LEADERBOX+4].INT;
                                synch_v;
                                SAVEV := DVIV;
                                synch_h;
                                SAVEH := DVIH;
                                TEMPPTR := LEADERBOX;
                                OUTERDOINGLE := DOINGLEADERS;
                                DOINGLEADERS := TRUE;
                                IF MEM[LEADERBOX].HH.B0=1 THEN VLISTOUT
                                                          ELSE HLISTOUT;
                                DOINGLEADERS := OUTERDOINGLE;
                                DVIV := SAVEV;
                                DVIH := SAVEH;
                                CURV := BASELINE;
                                CURH := SAVEH+LEADERWD+LX;
                              END{:628};
                            CURH := EDGE-10;
                            GOTO 15;
                          END;
                      END{:626};
                    GOTO 13;
                  END{:625};
              11,9: CURH := CURH+MEM[P+1].INT;
              6:{652:}
                 BEGIN
                   MEM[29988] := MEM[P+1];
                   MEM[29988].HH.RH := MEM[P].HH.RH;
                   P := 29988;
                   GOTO 21;
                 END{:652};
              ELSE
            END;
            GOTO 15;
            14:{624:}
                IF (RULEHT=-1073741824)THEN RULEHT := MEM[THISBOX+3].INT;
            IF (RULEDP=-1073741824)THEN RULEDP := MEM[THISBOX+2].INT;
            RULEHT := RULEHT+RULEDP;
            IF (RULEHT>0)AND(RULEWD>0)THEN
              BEGIN
                synch_h;
                CURV := BASELINE+RULEDP;
                synch_v;
                dvi_out(132);
                DVIFOUR(RULEHT);
                DVIFOUR(RULEWD);
                CURV := BASELINE;
                DVIH := DVIH+RULEWD;
              END{:624};
            13: CURH := CURH+RULEWD;
            15: P := MEM[P].HH.RH;
          END{:622}{:620};
  PRUNEMOVEMEN(SAVELOC);
  IF CURS>0 THEN DVIPOP(SAVELOC);
  CURS := CURS-1;
END;
{:619}{629:}
PROCEDURE VLISTOUT;

LABEL 13,14,15;

VAR LEFTEDGE: SCALED;
  TOPEDGE: SCALED;
  SAVEH,SAVEV: SCALED;
  THISBOX: HALFWORD;
  GORDER: GLUEORD;
  GSIGN: 0..2;
  P: HALFWORD;
  SAVELOC: Int32;
  LEADERBOX: HALFWORD;
  LEADERHT: SCALED;
  LX: SCALED;
  OUTERDOINGLE: BOOLEAN;
  EDGE: SCALED;
  GLUETEMP: Double;
  CURGLUE: Double;
  CURG: SCALED;
BEGIN
  CURG := 0;
  CURGLUE := 0.0;
  THISBOX := TEMPPTR;
  GORDER := MEM[THISBOX+5].HH.B1;
  GSIGN := MEM[THISBOX+5].HH.B0;
  P := MEM[THISBOX+5].HH.RH;
  CURS := CURS+1;
  IF CURS>0 THEN dvi_out(141);
  IF CURS>MAXPUSH THEN MAXPUSH := CURS;
  SAVELOC := DVIOFFSET+DVIPTR;
  LEFTEDGE := CURH;
  CURV := CURV-MEM[THISBOX+3].INT;
  TOPEDGE := CURV;
  WHILE P<>0 DO{630:}
    BEGIN
      IF (P>=HIMEMMIN)THEN confusion_str('vlistout')
      ELSE{631:}
        BEGIN
          CASE MEM[P].HH.B0 OF 
            0,1:{632:}
                 IF MEM[P+5].HH.RH=0 THEN
                   CURV := CURV+MEM[P+3].INT+MEM[P+2].INT
                 ELSE
                   BEGIN
                     CURV := CURV+MEM[P+3].INT;
                     synch_v;
                     SAVEH := DVIH;
                     SAVEV := DVIV;
                     CURH := LEFTEDGE+MEM[P+4].INT;
                     TEMPPTR := P;
                     IF MEM[P].HH.B0=1 THEN VLISTOUT
                                       ELSE HLISTOUT;
                     DVIH := SAVEH;
                     DVIV := SAVEV;
                     CURV := SAVEV+MEM[P+2].INT;
                     CURH := LEFTEDGE;
                   END{:632};
            2:
               BEGIN
                 RULEHT := MEM[P+3].INT;
                 RULEDP := MEM[P+2].INT;
                 RULEWD := MEM[P+1].INT;
                 GOTO 14;
               END;
            8:{1366:}OUTWHAT(P){:1366};
            10:{634:}
                BEGIN
                  G := MEM[P+1].HH.LH;
                  RULEHT := MEM[G+1].INT-CURG;
                  IF GSIGN<>0 THEN
                    BEGIN
                      IF GSIGN=1 THEN
                        BEGIN
                          IF MEM[G].HH.B0=GORDER THEN
                            BEGIN
                              CURGLUE := CURGLUE+MEM[G+2].INT;
                              GLUETEMP := MEM[THISBOX+6].GR*CURGLUE;
                              IF GLUETEMP>1000000000.0 THEN GLUETEMP := 1000000000.0
                              ELSE
                                IF GLUETEMP<
                                   -1000000000.0 THEN GLUETEMP := -1000000000.0;
                              CURG := ISORound(GLUETEMP);
                            END;
                        END
                      ELSE
                        IF MEM[G].HH.B1=GORDER THEN
                          BEGIN
                            CURGLUE := CURGLUE-MEM[G+3].INT
                            ;
                            GLUETEMP := MEM[THISBOX+6].GR*CURGLUE;
                            IF GLUETEMP>1000000000.0 THEN GLUETEMP := 1000000000.0
                            ELSE
                              IF GLUETEMP<
                                 -1000000000.0 THEN GLUETEMP := -1000000000.0;
                            CURG := ISORound(GLUETEMP);
                          END;
                    END;
                  RULEHT := RULEHT+CURG;
                  IF MEM[P].HH.B1>=100 THEN{635:}
                    BEGIN
                      LEADERBOX := MEM[P+1].HH.RH;
                      IF MEM[LEADERBOX].HH.B0=2 THEN
                        BEGIN
                          RULEWD := MEM[LEADERBOX+1].INT;
                          RULEDP := 0;
                          GOTO 14;
                        END;
                      LEADERHT := MEM[LEADERBOX+3].INT+MEM[LEADERBOX+2].INT;
                      IF (LEADERHT>0)AND(RULEHT>0)THEN
                        BEGIN
                          RULEHT := RULEHT+10;
                          EDGE := CURV+RULEHT;
                          LX := 0;
{636:}
                          IF MEM[P].HH.B1=100 THEN
                            BEGIN
                              SAVEV := CURV;
                              CURV := TOPEDGE+LEADERHT*((CURV-TOPEDGE)DIV LEADERHT);
                              IF CURV<SAVEV THEN CURV := CURV+LEADERHT;
                            END
                          ELSE
                            BEGIN
                              LQ := RULEHT DIV LEADERHT;
                              LR := RULEHT MOD LEADERHT;
                              IF MEM[P].HH.B1=101 THEN CURV := CURV+(LR DIV 2)
                              ELSE
                                BEGIN
                                  LX := LR DIV(LQ+1
                                        );
                                  CURV := CURV+((LR-(LQ-1)*LX)DIV 2);
                                END;
                            END{:636};
                          WHILE CURV+LEADERHT<=EDGE DO{637:}
                            BEGIN
                              CURH := LEFTEDGE+MEM[LEADERBOX+4].INT;
                              synch_h;
                              SAVEH := DVIH;
                              CURV := CURV+MEM[LEADERBOX+3].INT;
                              synch_v;
                              SAVEV := DVIV;
                              TEMPPTR := LEADERBOX;
                              OUTERDOINGLE := DOINGLEADERS;
                              DOINGLEADERS := TRUE;
                              IF MEM[LEADERBOX].HH.B0=1 THEN VLISTOUT
                                                        ELSE HLISTOUT;
                              DOINGLEADERS := OUTERDOINGLE;
                              DVIV := SAVEV;
                              DVIH := SAVEH;
                              CURH := LEFTEDGE;
                              CURV := SAVEV-MEM[LEADERBOX+3].INT+LEADERHT+LX;
                            END{:637};
                          CURV := EDGE-10;
                          GOTO 15;
                        END;
                    END{:635};
                  GOTO 13;
                END{:634};
            11: CURV := CURV+MEM[P+1].INT;
            ELSE
          END;
          GOTO 15;
          14:{633:}
              IF (RULEWD=-1073741824)THEN RULEWD := MEM[THISBOX+1].INT;
          RULEHT := RULEHT+RULEDP;
          CURV := CURV+RULEHT;
          IF (RULEHT>0)AND(RULEWD>0)THEN
            BEGIN
              synch_h;
              synch_v;
              dvi_out(137);
              DVIFOUR(RULEHT);
              DVIFOUR(RULEWD);
            END;
          GOTO 15{:633};
          13: CURV := CURV+RULEHT;
        END{:631};
      15: P := MEM[P].HH.RH;
    END{:630};
  PRUNEMOVEMEN(SAVELOC);
  IF CURS>0 THEN DVIPOP(SAVELOC);
  CURS := CURS-1;
END;{:629}{638:}
PROCEDURE SHIPOUT(P:HALFWORD);
VAR
  PAGELOC: Int32;
  J,K: 0..9;
  s: shortstring;
  i: uint32;
BEGIN
  IF EQTB[5297].INT>0 THEN
    BEGIN
      print_nl_str('');
      PRINTLN;
      print_str('Completed box being shipped out');
    END;
  IF TERMOFFSET>MAXPRINTLINE-9 THEN PRINTLN
  ELSE
    IF (TERMOFFSET>0)OR(
       FILEOFFSET>0)THEN PRINTCHAR(32);
  PRINTCHAR(91);
  J := 9;
  WHILE (EQTB[5318+J].INT=0)AND(J>0) DO J := J-1;
  FOR K:=0 TO J DO BEGIN
    PRINTINT(EQTB[5318+K].INT);
    IF K<J THEN PRINTCHAR(46);
  END;
  FLUSH(OUTPUT);
  IF EQTB[5297].INT>0 THEN BEGIN
    PRINTCHAR(93);
    BEGINDIAGNOS;
    SHOWBOX(P);
    ENDDIAGNOSTI(TRUE);
  END;

  IF (MEM[P+3].INT>1073741823) OR
     (MEM[P+2].INT>1073741823) OR
     (MEM[P+3].INT+MEM[P+2].INT+EQTB[5849].INT>1073741823) OR 
     (MEM[P+1].INT+EQTB[5848].INT>1073741823) THEN 
  BEGIN
    print_err('Huge page cannot be shipped out');
    help2('The page just created is more than 18 feet tall or',
          'more than 18 feet wide, so I suspect something went wrong.');
    ERROR;
    IF EQTB[5297].INT<=0 THEN BEGIN
      BEGINDIAGNOS;
      print_nl_str('The following box has been deleted:');
      SHOWBOX(P);
      ENDDIAGNOSTI(TRUE);
    END;
  END else begin
    IF MEM[P+3].INT+MEM[P+2].INT+EQTB[5849].INT>MAXV
      THEN MAXV := MEM[P+3].INT+MEM[P+2].INT+EQTB[5849].INT;
    IF MEM[P+1].INT+EQTB[5848].INT>MAXH
      THEN MAXH := MEM[P+1].INT+EQTB[5848].INT;
    DVIH := 0;
    DVIV := 0;
    CURH := EQTB[5848].INT;
    DVIF := 0;

    if output_file_name='' then begin
      if job_name='' then OPENLOGFILE;
      output_file_name := job_name + '.dvi';
      while not b_open_out(DVIFILE, output_file_name) do begin
        prompt_file_name(output_file_name, 'file name for output', '.dvi');
      end;
    end;

    IF TOTALPAGES=0 THEN BEGIN
      dvi_out(247);
      dvi_out(2);
      DVIFOUR(25400000);
      DVIFOUR(473628672);
      prepare_mag;
      DVIFOUR(EQTB[5280].INT);

      s := ' TeX output ' + print_int(EQTB[int_base+year_code].INT) + '.'
                          + IntToStr02(EQTB[int_base+month_code].INT) + '.'
                          + IntToStr02(EQTB[int_base+day_code].INT) + ':'
                          + IntToStr02(EQTB[int_base+time_code].INT DIV 60)
                          + IntToStr02(EQTB[int_base+time_code].INT MOD 60);
      dvi_out(length(s));
      for i := 1 to length(s) do dvi_out(ord(s[i]));
    END;
    PAGELOC := DVIOFFSET+DVIPTR;
    dvi_out(139);
    FOR K:=0 TO 9 DO DVIFOUR(EQTB[5318+K].INT);
    DVIFOUR(LASTBOP);
    LASTBOP := PAGELOC;
    CURV := MEM[P+3].INT+EQTB[5849].INT;
    TEMPPTR := P;
    IF MEM[P].HH.B0=1 THEN VLISTOUT
                      ELSE HLISTOUT;
    dvi_out(140);
    TOTALPAGES := TOTALPAGES+1;
    CURS := -1;
  end;

  IF EQTB[5297].INT<=0 THEN PRINTCHAR(93);
  DEADCYCLES := 0;
  FLUSH(OUTPUT);
{$IFDEF STATS}
  IF EQTB[5294].INT>1 THEN
    print_nl_str('Memory usage before: '
                  + print_int(VARUSED) + '&'
                  + print_int(DYNUSED) + ';');
{$ENDIF}
  FLUSHNODELIS(P);
{$IFDEF STATS}
  IF EQTB[5294].INT>1 THEN BEGIN
    print_str(' after: '
                  + print_int(VARUSED) + '&'
                  + print_int(DYNUSED) + '; still untouched: '
                  + print_int(HIMEMMIN-LOMEMMAX-1));
    PRINTLN;
  END;
{$ENDIF}
END;









{ ----------------------------------------------------------------------
  Packaging
  ---------------------------------------------------------------------- }







{108:}
FUNCTION BADNESS(T,S:SCALED): HALFWORD;
VAR R: Int32;
BEGIN
  IF T=0 THEN BADNESS := 0
  ELSE IF S<=0 THEN BADNESS := 10000
  ELSE BEGIN
    IF      T<=7230584 THEN R := (T*297) DIV S
    ELSE IF S>=1663497 THEN R := T DIV (S DIV 297)
                       ELSE R := T;
    IF R>1290 THEN BADNESS := 10000
              ELSE BADNESS := (R*R*R+131072) DIV 262144;
  END;
END;
{:108}

{645:}
PROCEDURE SCANSPEC(C:GROUPCODE;THREECODES:BOOLEAN);
VAR
  S: Int32;
  SPECCODE: 0..1;
BEGIN
  IF THREECODES THEN S := SAVESTACK[SAVEPTR+0].INT;

  IF scan_keyword('to') THEN begin
    SPECCODE := 0;
    SCANDIMEN(FALSE,FALSE,FALSE);
  end ELSE IF scan_keyword('spread') THEN begin
    SPECCODE := 1;
    SCANDIMEN(FALSE,FALSE,FALSE);
  end ELSE BEGIN
    SPECCODE := 1;
    CURVAL := 0;
  END;

  IF THREECODES THEN BEGIN
    SAVESTACK[SAVEPTR+0].INT := S;
    SAVEPTR := SAVEPTR+1;
  END;
  SAVESTACK[SAVEPTR+0].INT := SPECCODE;
  SAVESTACK[SAVEPTR+1].INT := CURVAL;
  SAVEPTR := SAVEPTR+2;
  NEWSAVELEVEL(C);
  SCANLEFTBRAC;
END;
{:645}

{649:}
FUNCTION HPACK(P:HALFWORD;W:SCALED;
               M:SMALLNUMBER): HALFWORD;

LABEL 21,50,10;

VAR R: HALFWORD;
  Q: HALFWORD;
  H,D,X: SCALED;
  S: SCALED;
  G: HALFWORD;
  O: GLUEORD;
  F: INTERNALFONT;
  I: FOURQUARTERS;
  HD: EIGHTBITS;
BEGIN
  LASTBADNESS := 0;
  R := GETNODE(7);
  MEM[R].HH.B0 := 0;
  MEM[R].HH.B1 := 0;
  MEM[R+4].INT := 0;
  Q := R+5;
  MEM[Q].HH.RH := P;
  H := 0;{650:}
  D := 0;
  X := 0;
  TOTALSTRETCH[0] := 0;
  TOTALSHRINK[0] := 0;
  TOTALSTRETCH[1] := 0;
  TOTALSHRINK[1] := 0;
  TOTALSTRETCH[2] := 0;
  TOTALSHRINK[2] := 0;
  TOTALSTRETCH[3] := 0;
  TOTALSHRINK[3] := 0{:650};
  WHILE P<>0 DO{651:}
    BEGIN
      21:
          WHILE (P>=HIMEMMIN) DO{654:}
            BEGIN
              F := MEM[P].HH
                   .B0;
              I := FONTINFO[CHARBASE[F]+MEM[P].HH.B1].QQQQ;
              HD := I.B1-0;
              X := X+FONTINFO[WIDTHBASE[F]+I.B0].INT;
              S := FONTINFO[HEIGHTBASE[F]+(HD)DIV 16].INT;
              IF S>H THEN H := S;
              S := FONTINFO[DEPTHBASE[F]+(HD)MOD 16].INT;
              IF S>D THEN D := S;
              P := MEM[P].HH.RH;
            END{:654};
      IF P<>0 THEN
        BEGIN
          CASE MEM[P].HH.B0 OF 
            0,1,2,13:{653:}
                      BEGIN
                        X := X+MEM[P
                             +1].INT;
                        IF MEM[P].HH.B0>=2 THEN S := 0
                        ELSE S := MEM[P+4].INT;
                        IF MEM[P+3].INT-S>H THEN H := MEM[P+3].INT-S;
                        IF MEM[P+2].INT+S>D THEN D := MEM[P+2].INT+S;
                      END{:653};
            3,4,5:
                   IF ADJUSTTAIL<>0 THEN{655:}
                     BEGIN
                       WHILE MEM[Q].HH.RH<>P DO
                         Q := MEM[Q
                              ].HH.RH;
                       IF MEM[P].HH.B0=5 THEN
                         BEGIN
                           MEM[ADJUSTTAIL].HH.RH := MEM[P+1].INT;
                           WHILE MEM[ADJUSTTAIL].HH.RH<>0 DO
                             ADJUSTTAIL := MEM[ADJUSTTAIL].HH.RH;
                           P := MEM[P].HH.RH;
                           FREENODE(MEM[Q].HH.RH,2);
                         END
                       ELSE
                         BEGIN
                           MEM[ADJUSTTAIL].HH.RH := P;
                           ADJUSTTAIL := P;
                           P := MEM[P].HH.RH;
                         END;
                       MEM[Q].HH.RH := P;
                       P := Q;
                     END{:655};
            8:{1360:}{:1360};
            10:{656:}
                BEGIN
                  G := MEM[P+1].HH.LH;
                  X := X+MEM[G+1].INT;
                  O := MEM[G].HH.B0;
                  TOTALSTRETCH[O] := TOTALSTRETCH[O]+MEM[G+2].INT;
                  O := MEM[G].HH.B1;
                  TOTALSHRINK[O] := TOTALSHRINK[O]+MEM[G+3].INT;
                  IF MEM[P].HH.B1>=100 THEN
                    BEGIN
                      G := MEM[P+1].HH.RH;
                      IF MEM[G+3].INT>H THEN H := MEM[G+3].INT;
                      IF MEM[G+2].INT>D THEN D := MEM[G+2].INT;
                    END;
                END{:656};
            11,9: X := X+MEM[P+1].INT;
            6:{652:}
               BEGIN
                 MEM[29988] := MEM[P+1];
                 MEM[29988].HH.RH := MEM[P].HH.RH;
                 P := 29988;
                 GOTO 21;
               END{:652};
            ELSE
          END;
          P := MEM[P].HH.RH;
        END;
    END{:651};
  IF ADJUSTTAIL<>0 THEN MEM[ADJUSTTAIL].HH.RH := 0;
  MEM[R+3].INT := H;
  MEM[R+2].INT := D;{657:}
  IF M=1 THEN W := X+W;
  MEM[R+1].INT := W;
  X := W-X;
  IF X=0 THEN
    BEGIN
      MEM[R+5].HH.B0 := 0;
      MEM[R+5].HH.B1 := 0;
      MEM[R+6].GR := 0.0;
      goto 10;
    END
  ELSE
    IF X>0 THEN{658:}
      BEGIN{659:}
        IF TOTALSTRETCH[3]<>0 THEN O := 3
        ELSE
          IF TOTALSTRETCH[2]<>0 THEN O := 2
        ELSE
          IF TOTALSTRETCH[1]<>0 THEN O := 
                                          1
        ELSE O := 0{:659};
        MEM[R+5].HH.B1 := O;
        MEM[R+5].HH.B0 := 1;
        IF TOTALSTRETCH[O]<>0 THEN MEM[R+6].GR := X/TOTALSTRETCH[O]
        ELSE
          BEGIN
            MEM[
            R+5].HH.B0 := 0;
            MEM[R+6].GR := 0.0;
          END;
        IF O=0 THEN
          IF MEM[R+5].HH.RH<>0 THEN{660:}
            BEGIN
              LASTBADNESS := BADNESS(X,
                             TOTALSTRETCH[0]);
              IF LASTBADNESS>EQTB[5289].INT THEN
                BEGIN
                  PRINTLN;
                  IF LASTBADNESS>100 THEN print_nl_str('Underfull')
                  ELSE print_nl_str('Loose');
                  print_str(' \hbox (badness ');
                  PRINTINT(LASTBADNESS);
                  GOTO 50;
                END;
            END{:660};
        goto 10;
      END{:658}
  ELSE{664:}
    BEGIN{665:}
      IF TOTALSHRINK[3]<>0 THEN O := 3
      ELSE
        IF 
           TOTALSHRINK[2]<>0 THEN O := 2
      ELSE
        IF TOTALSHRINK[1]<>0 THEN O := 1
      ELSE O := 
                0{:665};
      MEM[R+5].HH.B1 := O;
      MEM[R+5].HH.B0 := 2;
      IF TOTALSHRINK[O]<>0 THEN MEM[R+6].GR := (-X)/TOTALSHRINK[O]
      ELSE
        BEGIN
          MEM
          [R+5].HH.B0 := 0;
          MEM[R+6].GR := 0.0;
        END;
      IF (TOTALSHRINK[O]<-X)AND(O=0)AND(MEM[R+5].HH.RH<>0)THEN
        BEGIN
          LASTBADNESS := 1000000;
          MEM[R+6].GR := 1.0;
{666:}
          IF (-X-TOTALSHRINK[0]>EQTB[5838].INT)OR(EQTB[5289].INT<100)THEN
            BEGIN
              IF (EQTB[5846].INT>0)AND(-X-TOTALSHRINK[0]>EQTB[5838].INT)THEN
                BEGIN
                  WHILE MEM[Q].HH.RH<>0 DO
                    Q := MEM[Q].HH.RH;
                  MEM[Q].HH.RH := NEWRULE;
                  MEM[MEM[Q].HH.RH+1].INT := EQTB[5846].INT;
                END;
              PRINTLN;
              print_nl_str('Overfull \hbox (' + print_scaled(-X-TOTALSHRINK[0]) + 'pt too wide');
              GOTO 50;
            END{:666};
        END
      ELSE
        IF O=0 THEN
          IF MEM[R+5].HH.RH<>0 THEN{667:}
            BEGIN
              LASTBADNESS := 
                             BADNESS(-X,TOTALSHRINK[0]);
              IF LASTBADNESS>EQTB[5289].INT THEN
                BEGIN
                  PRINTLN;
                  print_nl_str('Tight \hbox (badness ');
                  PRINTINT(LASTBADNESS);
                  GOTO 50;
                END;
            END{:667};
      goto 10;
    END{:664}{:657};
  50:{663:}
      IF OUTPUTACTIVE THEN print_str(') has occurred while output is active')
      ELSE
        BEGIN
          IF PACKBEGINLIN<>0
            THEN
            BEGIN
              IF PACKBEGINLIN>0 THEN print_str(') in paragraph at lines ')
              ELSE print_str(') in alignment at lines ');
              PRINTINT(ABS(PACKBEGINLIN));
              print_str('--');
            END
          ELSE print_str(') detected at line ');
          PRINTINT(LINE);
        END;
  PRINTLN;
  FONTINSHORTD := 0;
  SHORTDISPLAY(MEM[R+5].HH.RH);
  PRINTLN;
  BEGINDIAGNOS;
  SHOWBOX(R);
  ENDDIAGNOSTI(TRUE){:663};
  10: HPACK := R;
END;{:649}{668:}
FUNCTION VPACKAGE(P:HALFWORD;H:SCALED;M:SMALLNUMBER;
                  L:SCALED): HALFWORD;

LABEL 50,10;

VAR R: HALFWORD;
  W,D,X: SCALED;
  S: SCALED;
  G: HALFWORD;
  O: GLUEORD;
BEGIN
  LASTBADNESS := 0;
  R := GETNODE(7);
  MEM[R].HH.B0 := 1;
  MEM[R].HH.B1 := 0;
  MEM[R+4].INT := 0;
  MEM[R+5].HH.RH := P;
  W := 0;{650:}
  D := 0;
  X := 0;
  TOTALSTRETCH[0] := 0;
  TOTALSHRINK[0] := 0;
  TOTALSTRETCH[1] := 0;
  TOTALSHRINK[1] := 0;
  TOTALSTRETCH[2] := 0;
  TOTALSHRINK[2] := 0;
  TOTALSTRETCH[3] := 0;
  TOTALSHRINK[3] := 0{:650};
  WHILE P<>0 DO{669:}
    BEGIN
      IF (P>=HIMEMMIN)THEN confusion_str('vpack')
      ELSE
        CASE MEM
             [P].HH.B0 OF 
          0,1,2,13:{670:}
                    BEGIN
                      X := X+D+MEM[P+3].INT;
                      D := MEM[P+2].INT;
                      IF MEM[P].HH.B0>=2 THEN S := 0
                      ELSE S := MEM[P+4].INT;
                      IF MEM[P+1].INT+S>W THEN W := MEM[P+1].INT+S;
                    END{:670};
          8:{1359:}{:1359};
          10:{671:}
              BEGIN
                X := X+D;
                D := 0;
                G := MEM[P+1].HH.LH;
                X := X+MEM[G+1].INT;
                O := MEM[G].HH.B0;
                TOTALSTRETCH[O] := TOTALSTRETCH[O]+MEM[G+2].INT;
                O := MEM[G].HH.B1;
                TOTALSHRINK[O] := TOTALSHRINK[O]+MEM[G+3].INT;
                IF MEM[P].HH.B1>=100 THEN
                  BEGIN
                    G := MEM[P+1].HH.RH;
                    IF MEM[G+1].INT>W THEN W := MEM[G+1].INT;
                  END;
              END{:671};
          11:
              BEGIN
                X := X+D+MEM[P+1].INT;
                D := 0;
              END;
          ELSE
        END;
      P := MEM[P].HH.RH;
    END{:669};
  MEM[R+1].INT := W;
  IF D>L THEN
    BEGIN
      X := X+D-L;
      MEM[R+2].INT := L;
    END
  ELSE MEM[R+2].INT := D;{672:}
  IF M=1 THEN H := X+H;
  MEM[R+3].INT := H;
  X := H-X;
  IF X=0 THEN
    BEGIN
      MEM[R+5].HH.B0 := 0;
      MEM[R+5].HH.B1 := 0;
      MEM[R+6].GR := 0.0;
      goto 10;
    END
  ELSE
    IF X>0 THEN{673:}
      BEGIN{659:}
        IF TOTALSTRETCH[3]<>0 THEN O := 3
        ELSE
          IF TOTALSTRETCH[2]<>0 THEN O := 2
        ELSE
          IF TOTALSTRETCH[1]<>0 THEN O := 
                                          1
        ELSE O := 0{:659};
        MEM[R+5].HH.B1 := O;
        MEM[R+5].HH.B0 := 1;
        IF TOTALSTRETCH[O]<>0 THEN MEM[R+6].GR := X/TOTALSTRETCH[O]
        ELSE
          BEGIN
            MEM[
            R+5].HH.B0 := 0;
            MEM[R+6].GR := 0.0;
          END;
        IF O=0 THEN
          IF MEM[R+5].HH.RH<>0 THEN{674:}
            BEGIN
              LASTBADNESS := BADNESS(X,
                             TOTALSTRETCH[0]);
              IF LASTBADNESS>EQTB[5290].INT THEN
                BEGIN
                  PRINTLN;
                  IF LASTBADNESS>100 THEN print_nl_str('Underfull')
                  ELSE print_nl_str('Loose');
                  print_str(' \vbox (badness ');
                  PRINTINT(LASTBADNESS);
                  GOTO 50;
                END;
            END{:674};
        goto 10;
      END{:673}
  ELSE{676:}
    BEGIN
      IF      TOTALSHRINK[3]<>0 THEN O := 3
      ELSE IF TOTALSHRINK[2]<>0 THEN O := 2
      ELSE IF TOTALSHRINK[1]<>0 THEN O := 1
      ELSE O := 0;
      MEM[R+5].HH.B1 := O;
      MEM[R+5].HH.B0 := 2;
      IF TOTALSHRINK[O]<>0 THEN MEM[R+6].GR := (-X)/TOTALSHRINK[O]
      ELSE
        BEGIN
          MEM
          [R+5].HH.B0 := 0;
          MEM[R+6].GR := 0.0;
        END;
      IF (TOTALSHRINK[O]<-X)AND(O=0)AND(MEM[R+5].HH.RH<>0)THEN
        BEGIN
          LASTBADNESS := 1000000;
          MEM[R+6].GR := 1.0;
{677:}
          IF (-X-TOTALSHRINK[0]>EQTB[5839].INT)OR(EQTB[5290].INT<100)THEN
            BEGIN
              PRINTLN;
              print_nl_str('Overfull \vbox (' + print_scaled(-X-TOTALSHRINK[0]) + 'pt too high');
              GOTO 50;
            END{:677};
        END
      ELSE
        IF O=0 THEN
          IF MEM[R+5].HH.RH<>0 THEN{678:}
            BEGIN
              LASTBADNESS := 
                             BADNESS(-X,TOTALSHRINK[0]);
              IF LASTBADNESS>EQTB[5290].INT THEN
                BEGIN
                  PRINTLN;
                  print_nl_str('Tight \vox (badness ');
                  PRINTINT(LASTBADNESS);
                  GOTO 50;
                END;
            END{:678};
      goto 10;
    END{:676}{:672};
  50:{675:}
      IF OUTPUTACTIVE THEN print_str(') has occurred while output is active')
      ELSE
        BEGIN
          IF PACKBEGINLIN<>0
            THEN
            BEGIN
              print_str(') in alignment at lines ');
              PRINTINT(ABS(PACKBEGINLIN));
              print_str('--');
            END
          ELSE print_str(') detected at line ');
          PRINTINT(LINE);
          PRINTLN;
        END;
  BEGINDIAGNOS;
  SHOWBOX(R);
  ENDDIAGNOSTI(TRUE){:675};
  10: VPACKAGE := R;
END;
{:668}{679:}
PROCEDURE APPENDTOVLIS(B:HALFWORD);

VAR D: SCALED;
  P: HALFWORD;
BEGIN
  IF CURLIST.AUXFIELD.INT>-65536000 THEN
    BEGIN
      D := MEM[EQTB[2883].HH.
           RH+1].INT-CURLIST.AUXFIELD.INT-MEM[B+3].INT;
      IF D<EQTB[5832].INT THEN P := NEWPARAMGLUE(0)
      ELSE
        BEGIN
          P := NEWSKIPPARAM(1)
          ;
          MEM[TEMPPTR+1].INT := D;
        END;
      MEM[CURLIST.TAILFIELD].HH.RH := P;
      CURLIST.TAILFIELD := P;
    END;
  MEM[CURLIST.TAILFIELD].HH.RH := B;
  CURLIST.TAILFIELD := B;
  CURLIST.AUXFIELD.INT := MEM[B+2].INT;
END;
{:679}{686:}
FUNCTION NEWNOAD: HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(4);
  MEM[P].HH.B0 := 16;
  MEM[P].HH.B1 := 0;
  MEM[P+1].HH := EMPTYFIELD;
  MEM[P+3].HH := EMPTYFIELD;
  MEM[P+2].HH := EMPTYFIELD;
  NEWNOAD := P;
END;{:686}{688:}
FUNCTION NEWSTYLE(S:SMALLNUMBER): HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(3);
  MEM[P].HH.B0 := 14;
  MEM[P].HH.B1 := S;
  MEM[P+1].INT := 0;
  MEM[P+2].INT := 0;
  NEWSTYLE := P;
END;
{:688}{689:}
FUNCTION NEWCHOICE: HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(3);
  MEM[P].HH.B0 := 15;
  MEM[P].HH.B1 := 0;
  MEM[P+1].HH.LH := 0;
  MEM[P+1].HH.RH := 0;
  MEM[P+2].HH.LH := 0;
  MEM[P+2].HH.RH := 0;
  NEWCHOICE := P;
END;
{:689}

{704:}
FUNCTION FRACTIONRULE(T:SCALED): HALFWORD;

VAR P: HALFWORD;
BEGIN
  P := NEWRULE;
  MEM[P+3].INT := T;
  MEM[P+2].INT := 0;
  FRACTIONRULE := P;
END;
{:704}{705:}
FUNCTION OVERBAR(B:HALFWORD;K,T:SCALED): HALFWORD;

VAR P,Q: HALFWORD;
BEGIN
  P := NEWKERN(K);
  MEM[P].HH.RH := B;
  Q := FRACTIONRULE(T);
  MEM[Q].HH.RH := P;
  P := NEWKERN(T);
  MEM[P].HH.RH := Q;
  OVERBAR := VPACKAGE(P,0,1,1073741823);
END;
{:705}{706:}{709:}
FUNCTION CHARBOX(F:INTERNALFONT;
                 C:QUARTERWORD): HALFWORD;

VAR Q: FOURQUARTERS;
  HD: EIGHTBITS;
  B,P: HALFWORD;
BEGIN
  Q := FONTINFO[CHARBASE[F]+C].QQQQ;
  HD := Q.B1-0;
  B := NEWNULLBOX;
  MEM[B+1].INT := FONTINFO[WIDTHBASE[F]+Q.B0].INT+FONTINFO[ITALICBASE[F]+(Q.
                  B2-0)DIV 4].INT;
  MEM[B+3].INT := FONTINFO[HEIGHTBASE[F]+(HD)DIV 16].INT;
  MEM[B+2].INT := FONTINFO[DEPTHBASE[F]+(HD)MOD 16].INT;
  P := GETAVAIL;
  MEM[P].HH.B1 := C;
  MEM[P].HH.B0 := F;
  MEM[B+5].HH.RH := P;
  CHARBOX := B;
END;
{:709}{711:}
PROCEDURE STACKINTOBOX(B:HALFWORD;F:INTERNALFONT;
                       C:QUARTERWORD);

VAR P: HALFWORD;
BEGIN
  P := CHARBOX(F,C);
  MEM[P].HH.RH := MEM[B+5].HH.RH;
  MEM[B+5].HH.RH := P;
  MEM[B+3].INT := MEM[P+3].INT;
END;
{:711}{712:}
FUNCTION HEIGHTPLUSDE(F:INTERNALFONT;C:QUARTERWORD): SCALED;

VAR Q: FOURQUARTERS;
  HD: EIGHTBITS;
BEGIN
  Q := FONTINFO[CHARBASE[F]+C].QQQQ;
  HD := Q.B1-0;
  HEIGHTPLUSDE := FONTINFO[HEIGHTBASE[F]+(HD)DIV 16].INT+FONTINFO[DEPTHBASE[
                  F]+(HD)MOD 16].INT;
END;{:712}
FUNCTION VARDELIMITER(D:HALFWORD;
                      S:SMALLNUMBER;V:SCALED): HALFWORD;

LABEL 40,22;

VAR B: HALFWORD;
  F,G: INTERNALFONT;
  C,X,Y: QUARTERWORD;
  M,N: Int32;
  U: SCALED;
  W: SCALED;
  Q: FOURQUARTERS;
  HD: EIGHTBITS;
  R: FOURQUARTERS;
  Z: SMALLNUMBER;
  LARGEATTEMPT: BOOLEAN;
BEGIN
  F := 0;
  W := 0;
  LARGEATTEMPT := FALSE;
  Z := MEM[D].QQQQ.B0;
  X := MEM[D].QQQQ.B1;
  WHILE TRUE DO
    BEGIN{707:}
      IF (Z<>0)OR(X<>0)THEN
        BEGIN
          Z := Z+S+16;
          REPEAT
            Z := Z-16;
            G := EQTB[3935+Z].HH.RH;
            IF G<>0 THEN{708:}
              BEGIN
                Y := X;
                IF (Y-0>=FONTBC[G])AND(Y-0<=FONTEC[G])THEN
                  BEGIN
                    22: Q := FONTINFO[CHARBASE[
                             G]+Y].QQQQ;
                    IF (Q.B0>0)THEN
                      BEGIN
                        IF ((Q.B2-0)MOD 4)=3 THEN
                          BEGIN
                            F := G;
                            C := Y;
                            GOTO 40;
                          END;
                        HD := Q.B1-0;
                        U := FONTINFO[HEIGHTBASE[G]+(HD)DIV 16].INT+FONTINFO[DEPTHBASE[G]+(HD)MOD
                             16].INT;
                        IF U>W THEN
                          BEGIN
                            F := G;
                            C := Y;
                            W := U;
                            IF U>=V THEN GOTO 40;
                          END;
                        IF ((Q.B2-0)MOD 4)=2 THEN
                          BEGIN
                            Y := Q.B3;
                            GOTO 22;
                          END;
                      END;
                  END;
              END{:708};
          UNTIL Z<16;
        END{:707};
      IF LARGEATTEMPT THEN GOTO 40;
      LARGEATTEMPT := TRUE;
      Z := MEM[D].QQQQ.B2;
      X := MEM[D].QQQQ.B3;
    END;
  40:
      IF F<>0 THEN{710:}
        IF ((Q.B2-0)MOD 4)=3 THEN{713:}
          BEGIN
            B := NEWNULLBOX;
            MEM[B].HH.B0 := 1;
            R := FONTINFO[EXTENBASE[F]+Q.B3].QQQQ;{714:}
            C := R.B3;
            U := HEIGHTPLUSDE(F,C);
            W := 0;
            Q := FONTINFO[CHARBASE[F]+C].QQQQ;
            MEM[B+1].INT := FONTINFO[WIDTHBASE[F]+Q.B0].INT+FONTINFO[ITALICBASE[F]+(Q.
                            B2-0)DIV 4].INT;
            C := R.B2;
            IF C<>0 THEN W := W+HEIGHTPLUSDE(F,C);
            C := R.B1;
            IF C<>0 THEN W := W+HEIGHTPLUSDE(F,C);
            C := R.B0;
            IF C<>0 THEN W := W+HEIGHTPLUSDE(F,C);
            N := 0;
            IF U>0 THEN
              WHILE W<V DO
                BEGIN
                  W := W+U;
                  N := N+1;
                  IF R.B1<>0 THEN W := W+U;
                END{:714};
            C := R.B2;
            IF C<>0 THEN STACKINTOBOX(B,F,C);
            C := R.B3;
            FOR M:=1 TO N DO
              STACKINTOBOX(B,F,C);
            C := R.B1;
            IF C<>0 THEN
              BEGIN
                STACKINTOBOX(B,F,C);
                C := R.B3;
                FOR M:=1 TO N DO
                  STACKINTOBOX(B,F,C);
              END;
            C := R.B0;
            IF C<>0 THEN STACKINTOBOX(B,F,C);
            MEM[B+2].INT := W-MEM[B+3].INT;
          END{:713}
      ELSE B := CHARBOX(F,C){:710}
      ELSE
        BEGIN
          B := NEWNULLBOX;
          MEM[B+1].INT := EQTB[5841].INT;
        END;
  MEM[B+4].INT := HALF(MEM[B+3].INT-MEM[B+2].INT)-FONTINFO[22+PARAMBASE[EQTB
                  [3937+S].HH.RH]].INT;
  VARDELIMITER := B;
END;
{:706}{715:}
FUNCTION REBOX(B:HALFWORD;W:SCALED): HALFWORD;

VAR P: HALFWORD;
  F: INTERNALFONT;
  V: SCALED;
BEGIN
  IF (MEM[B+1].INT<>W)AND(MEM[B+5].HH.RH<>0)THEN
    BEGIN
      IF MEM[B].HH.
         B0=1 THEN B := HPACK(B,0,1);
      P := MEM[B+5].HH.RH;
      IF ((P>=HIMEMMIN))AND(MEM[P].HH.RH=0)THEN
        BEGIN
          F := MEM[P].HH.B0;
          V := FONTINFO[WIDTHBASE[F]+FONTINFO[CHARBASE[F]+MEM[P].HH.B1].QQQQ.B0].INT
          ;
          IF V<>MEM[B+1].INT THEN MEM[P].HH.RH := NEWKERN(MEM[B+1].INT-V);
        END;
      FREENODE(B,7);
      B := NEWGLUE(12);
      MEM[B].HH.RH := P;
      WHILE MEM[P].HH.RH<>0 DO
        P := MEM[P].HH.RH;
      MEM[P].HH.RH := NEWGLUE(12);
      REBOX := HPACK(B,W,0);
    END
  ELSE
    BEGIN
      MEM[B+1].INT := W;
      REBOX := B;
    END;
END;
{:715}{716:}
FUNCTION MATHGLUE(G:HALFWORD;M:SCALED): HALFWORD;

VAR P: HALFWORD;
  N: Int32;
  F: SCALED;
BEGIN
  N := XOVERN(M,65536);
  F := REMAINDER;
  IF F<0 THEN
    BEGIN
      N := N-1;
      F := F+65536;
    END;
  P := GETNODE(4);
  MEM[P+1].INT := MULTANDADD(N,MEM[G+1].INT,XNOVERD(MEM[G+1].INT,F,65536),
                  1073741823);
  MEM[P].HH.B0 := MEM[G].HH.B0;
  IF MEM[P].HH.B0=0 THEN MEM[P+2].INT := MULTANDADD(N,MEM[G+2].INT,XNOVERD(
                                         MEM[G+2].INT,F,65536),1073741823)
  ELSE MEM[P+2].INT := MEM[G+2].INT;
  MEM[P].HH.B1 := MEM[G].HH.B1;
  IF MEM[P].HH.B1=0 THEN MEM[P+3].INT := MULTANDADD(N,MEM[G+3].INT,XNOVERD(
                                         MEM[G+3].INT,F,65536),1073741823)
  ELSE MEM[P+3].INT := MEM[G+3].INT;
  MATHGLUE := P;
END;{:716}{717:}
PROCEDURE MATHKERN(P:HALFWORD;M:SCALED);

VAR N: Int32;
  F: SCALED;
BEGIN
  IF MEM[P].HH.B1=99 THEN
    BEGIN
      N := XOVERN(M,65536);
      F := REMAINDER;
      IF F<0 THEN
        BEGIN
          N := N-1;
          F := F+65536;
        END;
      MEM[P+1].INT := MULTANDADD(N,MEM[P+1].INT,XNOVERD(MEM[P+1].INT,F,65536),
                      1073741823);
      MEM[P].HH.B1 := 1;
    END;
END;{:717}{718:}
PROCEDURE FLUSHMATH;
BEGIN
  FLUSHNODELIS(MEM[CURLIST.HEADFIELD].HH.RH);
  FLUSHNODELIS(CURLIST.AUXFIELD.INT);
  MEM[CURLIST.HEADFIELD].HH.RH := 0;
  CURLIST.TAILFIELD := CURLIST.HEADFIELD;
  CURLIST.AUXFIELD.INT := 0;
END;
{:718}{720:}
PROCEDURE MLISTTOHLIST; FORWARD;

FUNCTION CLEANBOX(P:HALFWORD; S:SMALLNUMBER): HALFWORD;
VAR 
  Q: HALFWORD;
  SAVESTYLE: SMALLNUMBER;
  X: HALFWORD;
  R: HALFWORD;
BEGIN
  X := MEM[P].HH.RH;
  if (X=1) or (X=3) then begin
    if X=1 then begin
      CURMLIST := NEWNOAD;
      MEM[CURMLIST+1] := MEM[P];
    end else begin
      CURMLIST := MEM[P].HH.LH;
    end;
    SAVESTYLE := CURSTYLE;
    CURSTYLE := S;
    MLISTPENALTI := FALSE;
    MLISTTOHLIST;
    CURSTYLE := SAVESTYLE;
    IF CURSTYLE<4 THEN CURSIZE := 0
                  ELSE CURSIZE := 16*((CURSTYLE-2) DIV 2);
    CURMU := XOVERN(FONTINFO[6+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT,18);
    Q := MEM[29997].HH.RH;
  end else begin
    if X=2 then Q := MEM[P].HH.LH
           else Q := NEWNULLBOX;
  end;

  IF (Q>=HIMEMMIN) OR (Q=0) THEN X := HPACK(Q,0,1)
  ELSE IF (MEM[Q].HH.RH=0) AND (MEM[Q].HH.B0<=1) AND (MEM[Q+4].INT=0) THEN X := Q
  ELSE X := HPACK(Q,0,1);

  Q := MEM[X+5].HH.RH;
  IF (Q>=HIMEMMIN) THEN BEGIN
    R := MEM[Q].HH.RH;
    IF R<>0 THEN
      IF MEM[R].HH.RH=0 THEN
        IF NOT(R>=HIMEMMIN)THEN
          IF MEM[R].HH.B0=11 THEN BEGIN
            FREENODE(R,2);
            MEM[Q].HH.RH := 0;
          END;
  END;
  CLEANBOX := X;
END;


{@<Complain about an undefined family and set |cur_i| null@>}
procedure ReportUndefinedFamily(FontName: shortstring; 
                                FontFamily: byte;
                                UndefChar: byte);
begin
  print_err(print_esc(FontName) + 
    ' ' + print_int(FontFamily) +
    ' is undefined (character ' + GetString(UndefChar) + ')');
  help4('Somewhere in the math formula just ended, you used the',
        'stated character from an undefined font family. For example,',
        'plain TeX doesn''t allow \it or \sl in subscripts. Proceed,',
        'and I''ll try to forget that I needed that character.');
  ERROR;
end;


PROCEDURE FETCH(A:HALFWORD);
var
  Family: byte; 
BEGIN
  CURC := MEM[A].HH.B1;
  CURF := EQTB[3935+MEM[A].HH.B0+CURSIZE].HH.RH;
  IF CURF=0 THEN BEGIN
      {723:}
      Family := MEM[A].HH.B0;
      if CURSIZE=0       then ReportUndefinedFamily('textfont', Family, CURC)
      else if CURSIZE=16 then ReportUndefinedFamily('scriptfont', Family, CURC)
                         else ReportUndefinedFamily('scriptscriptfont', Family, CURC);
      CURI := NULLCHARACTE;
      MEM[A].HH.RH := 0;
      {:723}
  END ELSE BEGIN
      IF (CURC-0>=FONTBC[CURF])AND(CURC-0<=FONTEC[CURF])
        THEN CURI := FONTINFO[CHARBASE[CURF]+CURC].QQQQ
      ELSE CURI := NULLCHARACTE;
      IF NOT((CURI.B0>0))THEN
        BEGIN
          CHARWARNING(CURF,CURC-0);
          MEM[A].HH.RH := 0;
          CURI := NULLCHARACTE;
        END;
    END;
END;
{:722}{726:}{734:}
PROCEDURE MAKEOVER(Q:HALFWORD);
BEGIN
  MEM[Q+1].HH.LH := OVERBAR(CLEANBOX(Q+1,2*(CURSTYLE DIV 2)+1),3*
                    FONTINFO[8+PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT,FONTINFO[8+PARAMBASE
                    [EQTB[3938+CURSIZE].HH.RH]].INT);
  MEM[Q+1].HH.RH := 2;
END;
{:734}{735:}
PROCEDURE MAKEUNDER(Q:HALFWORD);

VAR P,X,Y: HALFWORD;
  DELTA: SCALED;
BEGIN
  X := CLEANBOX(Q+1,CURSTYLE);
  P := NEWKERN(3*FONTINFO[8+PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT);
  MEM[X].HH.RH := P;
  MEM[P].HH.RH := FRACTIONRULE(FONTINFO[8+PARAMBASE[EQTB[3938+CURSIZE].HH.RH
                  ]].INT);
  Y := VPACKAGE(X,0,1,1073741823);
  DELTA := MEM[Y+3].INT+MEM[Y+2].INT+FONTINFO[8+PARAMBASE[EQTB[3938+CURSIZE]
           .HH.RH]].INT;
  MEM[Y+3].INT := MEM[X+3].INT;
  MEM[Y+2].INT := DELTA-MEM[Y+3].INT;
  MEM[Q+1].HH.LH := Y;
  MEM[Q+1].HH.RH := 2;
END;{:735}{736:}
PROCEDURE MAKEVCENTER(Q:HALFWORD);

VAR V: HALFWORD;
  DELTA: SCALED;
BEGIN
  V := MEM[Q+1].HH.LH;
  IF MEM[V].HH.B0<>1 THEN confusion_str('vcenter');
  DELTA := MEM[V+3].INT+MEM[V+2].INT;
  MEM[V+3].INT := FONTINFO[22+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT+HALF(
                  DELTA);
  MEM[V+2].INT := DELTA-MEM[V+3].INT;
END;
{:736}{737:}
PROCEDURE MAKERADICAL(Q:HALFWORD);

VAR X,Y: HALFWORD;
  DELTA,CLR: SCALED;
BEGIN
  X := CLEANBOX(Q+1,2*(CURSTYLE DIV 2)+1);
  IF CURSTYLE<2 THEN CLR := FONTINFO[8+PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].
                            INT+(ABS(FONTINFO[5+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT)DIV 4)
  ELSE
    BEGIN
      CLR := FONTINFO[8+PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT;
      CLR := CLR+(ABS(CLR)DIV 4);
    END;
  Y := VARDELIMITER(Q+4,CURSIZE,MEM[X+3].INT+MEM[X+2].INT+CLR+FONTINFO[8+
       PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT);
  DELTA := MEM[Y+2].INT-(MEM[X+3].INT+MEM[X+2].INT+CLR);
  IF DELTA>0 THEN CLR := CLR+HALF(DELTA);
  MEM[Y+4].INT := -(MEM[X+3].INT+CLR);
  MEM[Y].HH.RH := OVERBAR(X,CLR,MEM[Y+3].INT);
  MEM[Q+1].HH.LH := HPACK(Y,0,1);
  MEM[Q+1].HH.RH := 2;
END;{:737}{738:}
PROCEDURE MAKEMATHACCE(Q:HALFWORD);

LABEL 30,31;

VAR P,X,Y: HALFWORD;
  A: Int32;
  C: QUARTERWORD;
  F: INTERNALFONT;
  I: FOURQUARTERS;
  S: SCALED;
  H: SCALED;
  DELTA: SCALED;
  W: SCALED;
BEGIN
  FETCH(Q+4);
  IF (CURI.B0>0)THEN
    BEGIN
      I := CURI;
      C := CURC;
      F := CURF;{741:}
      S := 0;
      IF MEM[Q+1].HH.RH=1 THEN
        BEGIN
          FETCH(Q+1);
          IF ((CURI.B2-0)MOD 4)=1 THEN
            BEGIN
              A := LIGKERNBASE[CURF]+CURI.B3;
              CURI := FONTINFO[A].QQQQ;
              IF CURI.B0>128 THEN
                BEGIN
                  A := LIGKERNBASE[CURF]+256*CURI.B2+CURI.B3
                       +32768-256*(128);
                  CURI := FONTINFO[A].QQQQ;
                END;
              WHILE TRUE DO
                BEGIN
                  IF CURI.B1-0=SKEWCHAR[CURF]THEN
                    BEGIN
                      IF CURI.B2>=
                         128 THEN
                        IF CURI.B0<=128 THEN S := FONTINFO[KERNBASE[CURF]+256*CURI.B2+
                                                  CURI.B3].INT;
                      GOTO 31;
                    END;
                  IF CURI.B0>=128 THEN GOTO 31;
                  A := A+CURI.B0+1;
                  CURI := FONTINFO[A].QQQQ;
                END;
            END;
        END;
      31:{:741};
      X := CLEANBOX(Q+1,2*(CURSTYLE DIV 2)+1);
      W := MEM[X+1].INT;
      H := MEM[X+3].INT;
{740:}
      WHILE TRUE DO
        BEGIN
          IF ((I.B2-0)MOD 4)<>2 THEN GOTO 30;
          Y := I.B3;
          I := FONTINFO[CHARBASE[F]+Y].QQQQ;
          IF NOT(I.B0>0)THEN GOTO 30;
          IF FONTINFO[WIDTHBASE[F]+I.B0].INT>W THEN GOTO 30;
          C := Y;
        END;
      30:{:740};
      IF H<FONTINFO[5+PARAMBASE[F]].INT THEN DELTA := H
      ELSE DELTA := FONTINFO[5+
                    PARAMBASE[F]].INT;
      IF (MEM[Q+2].HH.RH<>0)OR(MEM[Q+3].HH.RH<>0)THEN
        IF MEM[Q+1].HH.RH=1 THEN
{742:}
          BEGIN
            FLUSHNODELIS(X);
            X := NEWNOAD;
            MEM[X+1] := MEM[Q+1];
            MEM[X+2] := MEM[Q+2];
            MEM[X+3] := MEM[Q+3];
            MEM[Q+2].HH := EMPTYFIELD;
            MEM[Q+3].HH := EMPTYFIELD;
            MEM[Q+1].HH.RH := 3;
            MEM[Q+1].HH.LH := X;
            X := CLEANBOX(Q+1,CURSTYLE);
            DELTA := DELTA+MEM[X+3].INT-H;
            H := MEM[X+3].INT;
          END{:742};
      Y := CHARBOX(F,C);
      MEM[Y+4].INT := S+HALF(W-MEM[Y+1].INT);
      MEM[Y+1].INT := 0;
      P := NEWKERN(-DELTA);
      MEM[P].HH.RH := X;
      MEM[Y].HH.RH := P;
      Y := VPACKAGE(Y,0,1,1073741823);
      MEM[Y+1].INT := MEM[X+1].INT;
      IF MEM[Y+3].INT<H THEN{739:}
        BEGIN
          P := NEWKERN(H-MEM[Y+3].INT);
          MEM[P].HH.RH := MEM[Y+5].HH.RH;
          MEM[Y+5].HH.RH := P;
          MEM[Y+3].INT := H;
        END{:739};
      MEM[Q+1].HH.LH := Y;
      MEM[Q+1].HH.RH := 2;
    END;
END;
{:738}{743:}
PROCEDURE MAKEFRACTION(Q:HALFWORD);

VAR P,V,X,Y,Z: HALFWORD;
  DELTA,DELTA1,DELTA2,SHIFTUP,SHIFTDOWN,CLR: SCALED;
BEGIN
  IF MEM[Q+1].INT=1073741824 THEN MEM[Q+1].INT := FONTINFO[8+PARAMBASE
                                                  [EQTB[3938+CURSIZE].HH.RH]].INT;
{744:}
  X := CLEANBOX(Q+2,CURSTYLE+2-2*(CURSTYLE DIV 6));
  Z := CLEANBOX(Q+3,2*(CURSTYLE DIV 2)+3-2*(CURSTYLE DIV 6));
  IF MEM[X+1].INT<MEM[Z+1].INT THEN X := REBOX(X,MEM[Z+1].INT)
  ELSE Z := REBOX(
            Z,MEM[X+1].INT);
  IF CURSTYLE<2 THEN
    BEGIN
      SHIFTUP := FONTINFO[8+PARAMBASE[EQTB[3937+CURSIZE
                 ].HH.RH]].INT;
      SHIFTDOWN := FONTINFO[11+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT;
    END
  ELSE
    BEGIN
      SHIFTDOWN := FONTINFO[12+PARAMBASE[EQTB[3937+CURSIZE].HH.RH
                   ]].INT;
      IF MEM[Q+1].INT<>0 THEN SHIFTUP := FONTINFO[9+PARAMBASE[EQTB[3937+CURSIZE]
                                         .HH.RH]].INT
      ELSE SHIFTUP := FONTINFO[10+PARAMBASE[EQTB[3937+CURSIZE].HH.
                      RH]].INT;
    END{:744};
  IF MEM[Q+1].INT=0 THEN{745:}
    BEGIN
      IF CURSTYLE<2 THEN CLR := 7*FONTINFO[8+
                                PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT
      ELSE CLR := 3*FONTINFO[8+
                  PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT;
      DELTA := HALF(CLR-((SHIFTUP-MEM[X+2].INT)-(MEM[Z+3].INT-SHIFTDOWN)));
      IF DELTA>0 THEN
        BEGIN
          SHIFTUP := SHIFTUP+DELTA;
          SHIFTDOWN := SHIFTDOWN+DELTA;
        END;
    END{:745}
  ELSE{746:}
    BEGIN
      IF CURSTYLE<2 THEN CLR := 3*MEM[Q+1].INT
      ELSE CLR 
        := MEM[Q+1].INT;
      DELTA := HALF(MEM[Q+1].INT);
      DELTA1 := CLR-((SHIFTUP-MEM[X+2].INT)-(FONTINFO[22+PARAMBASE[EQTB[3937+
                CURSIZE].HH.RH]].INT+DELTA));
      DELTA2 := CLR-((FONTINFO[22+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT-DELTA
                )-(MEM[Z+3].INT-SHIFTDOWN));
      IF DELTA1>0 THEN SHIFTUP := SHIFTUP+DELTA1;
      IF DELTA2>0 THEN SHIFTDOWN := SHIFTDOWN+DELTA2;
    END{:746};
{747:}
  V := NEWNULLBOX;
  MEM[V].HH.B0 := 1;
  MEM[V+3].INT := SHIFTUP+MEM[X+3].INT;
  MEM[V+2].INT := MEM[Z+2].INT+SHIFTDOWN;
  MEM[V+1].INT := MEM[X+1].INT;
  IF MEM[Q+1].INT=0 THEN
    BEGIN
      P := NEWKERN((SHIFTUP-MEM[X+2].INT)-(MEM[Z+3]
           .INT-SHIFTDOWN));
      MEM[P].HH.RH := Z;
    END
  ELSE
    BEGIN
      Y := FRACTIONRULE(MEM[Q+1].INT);
      P := NEWKERN((FONTINFO[22+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT-DELTA)-
           (MEM[Z+3].INT-SHIFTDOWN));
      MEM[Y].HH.RH := P;
      MEM[P].HH.RH := Z;
      P := NEWKERN((SHIFTUP-MEM[X+2].INT)-(FONTINFO[22+PARAMBASE[EQTB[3937+
           CURSIZE].HH.RH]].INT+DELTA));
      MEM[P].HH.RH := Y;
    END;
  MEM[X].HH.RH := P;
  MEM[V+5].HH.RH := X{:747};
{748:}
  IF CURSTYLE<2 THEN DELTA := FONTINFO[20+PARAMBASE[EQTB[3937+CURSIZE]
                              .HH.RH]].INT
  ELSE DELTA := FONTINFO[21+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]
                ].INT;
  X := VARDELIMITER(Q+4,CURSIZE,DELTA);
  MEM[X].HH.RH := V;
  Z := VARDELIMITER(Q+5,CURSIZE,DELTA);
  MEM[V].HH.RH := Z;
  MEM[Q+1].INT := HPACK(X,0,1){:748};
END;
{:743}{749:}
FUNCTION MAKEOP(Q:HALFWORD): SCALED;

VAR DELTA: SCALED;
  P,V,X,Y,Z: HALFWORD;
  C: QUARTERWORD;
  I: FOURQUARTERS;
  SHIFTUP,SHIFTDOWN: SCALED;
BEGIN
  IF (MEM[Q].HH.B1=0)AND(CURSTYLE<2)THEN MEM[Q].HH.B1 := 1;
  IF MEM[Q+1].HH.RH=1 THEN
    BEGIN
      FETCH(Q+1);
      IF (CURSTYLE<2)AND(((CURI.B2-0)MOD 4)=2)THEN
        BEGIN
          C := CURI.B3;
          I := FONTINFO[CHARBASE[CURF]+C].QQQQ;
          IF (I.B0>0)THEN
            BEGIN
              CURC := C;
              CURI := I;
              MEM[Q+1].HH.B1 := C;
            END;
        END;
      DELTA := FONTINFO[ITALICBASE[CURF]+(CURI.B2-0)DIV 4].INT;
      X := CLEANBOX(Q+1,CURSTYLE);
      IF (MEM[Q+3].HH.RH<>0)AND(MEM[Q].HH.B1<>1)THEN MEM[X+1].INT := MEM[X+1].INT
                                                                     -DELTA;
      MEM[X+4].INT := HALF(MEM[X+3].INT-MEM[X+2].INT)-FONTINFO[22+PARAMBASE[EQTB
                      [3937+CURSIZE].HH.RH]].INT;
      MEM[Q+1].HH.RH := 2;
      MEM[Q+1].HH.LH := X;
    END
  ELSE DELTA := 0;
  IF MEM[Q].HH.B1=1 THEN{750:}
    BEGIN
      X := CLEANBOX(Q+2,2*(CURSTYLE DIV 4)+4+(
           CURSTYLE MOD 2));
      Y := CLEANBOX(Q+1,CURSTYLE);
      Z := CLEANBOX(Q+3,2*(CURSTYLE DIV 4)+5);
      V := NEWNULLBOX;
      MEM[V].HH.B0 := 1;
      MEM[V+1].INT := MEM[Y+1].INT;
      IF MEM[X+1].INT>MEM[V+1].INT THEN MEM[V+1].INT := MEM[X+1].INT;
      IF MEM[Z+1].INT>MEM[V+1].INT THEN MEM[V+1].INT := MEM[Z+1].INT;
      X := REBOX(X,MEM[V+1].INT);
      Y := REBOX(Y,MEM[V+1].INT);
      Z := REBOX(Z,MEM[V+1].INT);
      MEM[X+4].INT := HALF(DELTA);
      MEM[Z+4].INT := -MEM[X+4].INT;
      MEM[V+3].INT := MEM[Y+3].INT;
      MEM[V+2].INT := MEM[Y+2].INT;
{751:}
      IF MEM[Q+2].HH.RH=0 THEN
        BEGIN
          FREENODE(X,7);
          MEM[V+5].HH.RH := Y;
        END
      ELSE
        BEGIN
          SHIFTUP := FONTINFO[11+PARAMBASE[EQTB[3938+CURSIZE].HH.RH]]
                     .INT-MEM[X+2].INT;
          IF SHIFTUP<FONTINFO[9+PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT THEN
            SHIFTUP := FONTINFO[9+PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT;
          P := NEWKERN(SHIFTUP);
          MEM[P].HH.RH := Y;
          MEM[X].HH.RH := P;
          P := NEWKERN(FONTINFO[13+PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT);
          MEM[P].HH.RH := X;
          MEM[V+5].HH.RH := P;
          MEM[V+3].INT := MEM[V+3].INT+FONTINFO[13+PARAMBASE[EQTB[3938+CURSIZE].HH.
                          RH]].INT+MEM[X+3].INT+MEM[X+2].INT+SHIFTUP;
        END;
      IF MEM[Q+3].HH.RH=0 THEN FREENODE(Z,7)
      ELSE
        BEGIN
          SHIFTDOWN := FONTINFO[12+
                       PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT-MEM[Z+3].INT;
          IF SHIFTDOWN<FONTINFO[10+PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT THEN
            SHIFTDOWN := FONTINFO[10+PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT;
          P := NEWKERN(SHIFTDOWN);
          MEM[Y].HH.RH := P;
          MEM[P].HH.RH := Z;
          P := NEWKERN(FONTINFO[13+PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT);
          MEM[Z].HH.RH := P;
          MEM[V+2].INT := MEM[V+2].INT+FONTINFO[13+PARAMBASE[EQTB[3938+CURSIZE].HH.
                          RH]].INT+MEM[Z+3].INT+MEM[Z+2].INT+SHIFTDOWN;
        END{:751};
      MEM[Q+1].INT := V;
    END{:750};
  MAKEOP := DELTA;
END;{:749}{752:}
PROCEDURE MAKEORD(Q:HALFWORD);

LABEL 20;

VAR A: Int32;
  P,R: HALFWORD;
BEGIN
  20:
      IF MEM[Q+3].HH.RH=0 THEN
        IF MEM[Q+2].HH.RH=0 THEN
          IF MEM[Q+1].
             HH.RH=1 THEN
            BEGIN
              P := MEM[Q].HH.RH;
              IF P<>0 THEN
                IF (MEM[P].HH.B0>=16)AND(MEM[P].HH.B0<=22)THEN
                  IF MEM[P+1].
                     HH.RH=1 THEN
                    IF MEM[P+1].HH.B0=MEM[Q+1].HH.B0 THEN
                      BEGIN
                        MEM[Q+1].HH.RH 
                        := 4;
                        FETCH(Q+1);
                        IF ((CURI.B2-0)MOD 4)=1 THEN
                          BEGIN
                            A := LIGKERNBASE[CURF]+CURI.B3;
                            CURC := MEM[P+1].HH.B1;
                            CURI := FONTINFO[A].QQQQ;
                            IF CURI.B0>128 THEN
                              BEGIN
                                A := LIGKERNBASE[CURF]+256*CURI.B2+CURI.B3
                                     +32768-256*(128);
                                CURI := FONTINFO[A].QQQQ;
                              END;
                            WHILE TRUE DO
                              BEGIN{753:}
                                IF CURI.B1=CURC THEN
                                  IF CURI.B0<=128 THEN
                                    IF 
                                       CURI.B2>=128 THEN
                                      BEGIN
                                        P := NEWKERN(FONTINFO[KERNBASE[CURF]+256*CURI.B2+
                                             CURI.B3].INT);
                                        MEM[P].HH.RH := MEM[Q].HH.RH;
                                        MEM[Q].HH.RH := P;
                                        exit;
                                      END
                                ELSE
                                  BEGIN
                                    BEGIN
                                      IF INTERRUPT<>0 THEN PAUSEFORINST;
                                    END;
                                    CASE CURI.B2 OF 
                                      1,5: MEM[Q+1].HH.B1 := CURI.B3;
                                      2,6: MEM[P+1].HH.B1 := CURI.B3;
                                      3,7,11:
                                              BEGIN
                                                R := NEWNOAD;
                                                MEM[R+1].HH.B1 := CURI.B3;
                                                MEM[R+1].HH.B0 := MEM[Q+1].HH.B0;
                                                MEM[Q].HH.RH := R;
                                                MEM[R].HH.RH := P;
                                                IF CURI.B2<11 THEN MEM[R+1].HH.RH := 1
                                                ELSE MEM[R+1].HH.RH := 4;
                                              END;
                                      ELSE
                                        BEGIN
                                          MEM[Q].HH.RH := MEM[P].HH.RH;
                                          MEM[Q+1].HH.B1 := CURI.B3;
                                          MEM[Q+3] := MEM[P+3];
                                          MEM[Q+2] := MEM[P+2];
                                          FREENODE(P,4);
                                        END
                                    END;
                                    IF CURI.B2>3 THEN exit;
                                    MEM[Q+1].HH.RH := 1;
                                    GOTO 20;
                                  END{:753};
                                IF CURI.B0>=128 THEN exit;
                                A := A+CURI.B0+1;
                                CURI := FONTINFO[A].QQQQ;
                              END;
                          END;
                      END;
            END;
END;{:752}{756:}
PROCEDURE MAKESCRIPTS(Q:HALFWORD;
                      DELTA:SCALED);

VAR P,X,Y,Z: HALFWORD;
  SHIFTUP,SHIFTDOWN,CLR: SCALED;
  T: SMALLNUMBER;
BEGIN
  P := MEM[Q+1].INT;
  IF (P>=HIMEMMIN)THEN
    BEGIN
      SHIFTUP := 0;
      SHIFTDOWN := 0;
    END
  ELSE
    BEGIN
      Z := HPACK(P,0,1);
      IF CURSTYLE<4 THEN T := 16
      ELSE T := 32;
      SHIFTUP := MEM[Z+3].INT-FONTINFO[18+PARAMBASE[EQTB[3937+T].HH.RH]].INT;
      SHIFTDOWN := MEM[Z+2].INT+FONTINFO[19+PARAMBASE[EQTB[3937+T].HH.RH]].INT;
      FREENODE(Z,7);
    END;
  IF MEM[Q+2].HH.RH=0 THEN{757:}
    BEGIN
      X := CLEANBOX(Q+3,2*(CURSTYLE DIV 4)+5
           );
      MEM[X+1].INT := MEM[X+1].INT+EQTB[5842].INT;
      IF SHIFTDOWN<FONTINFO[16+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT THEN
        SHIFTDOWN := FONTINFO[16+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT;
      CLR := MEM[X+3].INT-(ABS(FONTINFO[5+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].
             INT*4)DIV 5);
      IF SHIFTDOWN<CLR THEN SHIFTDOWN := CLR;
      MEM[X+4].INT := SHIFTDOWN;
    END{:757}
  ELSE
    BEGIN{758:}
      BEGIN
        X := CLEANBOX(Q+2,2*(CURSTYLE DIV 4)+4+(
             CURSTYLE MOD 2));
        MEM[X+1].INT := MEM[X+1].INT+EQTB[5842].INT;
        IF ODD(CURSTYLE)THEN CLR := FONTINFO[15+PARAMBASE[EQTB[3937+CURSIZE].HH.RH
                                    ]].INT
        ELSE
          IF CURSTYLE<2 THEN CLR := FONTINFO[13+PARAMBASE[EQTB[3937+
                                    CURSIZE].HH.RH]].INT
        ELSE CLR := FONTINFO[14+PARAMBASE[EQTB[3937+CURSIZE].
                    HH.RH]].INT;
        IF SHIFTUP<CLR THEN SHIFTUP := CLR;
        CLR := MEM[X+2].INT+(ABS(FONTINFO[5+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].
               INT)DIV 4);
        IF SHIFTUP<CLR THEN SHIFTUP := CLR;
      END{:758};
      IF MEM[Q+3].HH.RH=0 THEN MEM[X+4].INT := -SHIFTUP
      ELSE{759:}
        BEGIN
          Y := 
               CLEANBOX(Q+3,2*(CURSTYLE DIV 4)+5);
          MEM[Y+1].INT := MEM[Y+1].INT+EQTB[5842].INT;
          IF SHIFTDOWN<FONTINFO[17+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT THEN
            SHIFTDOWN := FONTINFO[17+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT;
          CLR := 4*FONTINFO[8+PARAMBASE[EQTB[3938+CURSIZE].HH.RH]].INT-((SHIFTUP-MEM
                 [X+2].INT)-(MEM[Y+3].INT-SHIFTDOWN));
          IF CLR>0 THEN
            BEGIN
              SHIFTDOWN := SHIFTDOWN+CLR;
              CLR := (ABS(FONTINFO[5+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT*4)DIV 5)-(
                     SHIFTUP-MEM[X+2].INT);
              IF CLR>0 THEN
                BEGIN
                  SHIFTUP := SHIFTUP+CLR;
                  SHIFTDOWN := SHIFTDOWN-CLR;
                END;
            END;
          MEM[X+4].INT := DELTA;
          P := NEWKERN((SHIFTUP-MEM[X+2].INT)-(MEM[Y+3].INT-SHIFTDOWN));
          MEM[X].HH.RH := P;
          MEM[P].HH.RH := Y;
          X := VPACKAGE(X,0,1,1073741823);
          MEM[X+4].INT := SHIFTDOWN;
        END{:759};
    END;
  IF MEM[Q+1].INT=0 THEN MEM[Q+1].INT := X
  ELSE
    BEGIN
      P := MEM[Q+1].INT;
      WHILE MEM[P].HH.RH<>0 DO
        P := MEM[P].HH.RH;
      MEM[P].HH.RH := X;
    END;
END;
{:756}{762:}
FUNCTION MAKELEFTRIGH(Q:HALFWORD;STYLE:SMALLNUMBER;
                      MAXD,MAXH:SCALED): SMALLNUMBER;

VAR DELTA,DELTA1,DELTA2: SCALED;
BEGIN
  IF STYLE<4 THEN CURSIZE := 0
  ELSE CURSIZE := 16*((STYLE-2)DIV 2);
  DELTA2 := MAXD+FONTINFO[22+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT;
  DELTA1 := MAXH+MAXD-DELTA2;
  IF DELTA2>DELTA1 THEN DELTA1 := DELTA2;
  DELTA := (DELTA1 DIV 500)*EQTB[5281].INT;
  DELTA2 := DELTA1+DELTA1-EQTB[5840].INT;
  IF DELTA<DELTA2 THEN DELTA := DELTA2;
  MEM[Q+1].INT := VARDELIMITER(Q+1,CURSIZE,DELTA);
  MAKELEFTRIGH := MEM[Q].HH.B0-(10);
END;{:762}
PROCEDURE MLISTTOHLIST;

LABEL 21,82,80,81,83,30;

VAR MLIST: HALFWORD;
  PENALTIES: BOOLEAN;
  STYLE: SMALLNUMBER;
  SAVESTYLE: SMALLNUMBER;
  Q: HALFWORD;
  R: HALFWORD;
  RTYPE: SMALLNUMBER;
  T: SMALLNUMBER;
  P,X,Y,Z: HALFWORD;
  PEN: Int32;
  S: SMALLNUMBER;
  MAXH,MAXD: SCALED;
  DELTA: SCALED;
BEGIN
  MLIST := CURMLIST;
  PENALTIES := MLISTPENALTI;
  STYLE := CURSTYLE;
  Q := MLIST;
  R := 0;
  RTYPE := 17;
  MAXH := 0;
  MAXD := 0;
{703:}
  BEGIN
    IF CURSTYLE<4 THEN CURSIZE := 0
    ELSE CURSIZE := 16*((CURSTYLE-2)
                    DIV 2);
    CURMU := XOVERN(FONTINFO[6+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT,18);
  END{:703};
  WHILE Q<>0 DO{727:}
    BEGIN{728:}
      21: DELTA := 0;
      CASE MEM[Q].HH.B0 OF 
        18:
            CASE RTYPE OF 
              18,17,19,20,22,30:
                                 BEGIN
                                   MEM[Q].HH.
                                   B0 := 16;
                                   GOTO 21;
                                 END;
              ELSE
            END;
        19,21,22,31:
                     BEGIN{729:}
                       IF RTYPE=18 THEN MEM[R].HH.B0 := 16{:729};
                       IF MEM[Q].HH.B0=31 THEN GOTO 80;
                     END;{733:}
        30: GOTO 80;
        25:
            BEGIN
              MAKEFRACTION(Q);
              GOTO 82;
            END;
        17:
            BEGIN
              DELTA := MAKEOP(Q);
              IF MEM[Q].HH.B1=1 THEN GOTO 82;
            END;
        16: MAKEORD(Q);
        20,23:;
        24: MAKERADICAL(Q);
        27: MAKEOVER(Q);
        26: MAKEUNDER(Q);
        28: MAKEMATHACCE(Q);
        29: MAKEVCENTER(Q);{:733}{730:}
        14:
            BEGIN
              CURSTYLE := MEM[Q].HH.B1;
{703:}
              BEGIN
                IF CURSTYLE<4 THEN CURSIZE := 0
                ELSE CURSIZE := 16*((CURSTYLE-2)
                                DIV 2);
                CURMU := XOVERN(FONTINFO[6+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT,18);
              END{:703};
              GOTO 81;
            END;
        15:{731:}
            BEGIN
              CASE CURSTYLE DIV 2 OF 
                0:
                   BEGIN
                     P := MEM[Q+1].HH.LH;
                     MEM[Q+1].HH.LH := 0;
                   END;
                1:
                   BEGIN
                     P := MEM[Q+1].HH.RH;
                     MEM[Q+1].HH.RH := 0;
                   END;
                2:
                   BEGIN
                     P := MEM[Q+2].HH.LH;
                     MEM[Q+2].HH.LH := 0;
                   END;
                3:
                   BEGIN
                     P := MEM[Q+2].HH.RH;
                     MEM[Q+2].HH.RH := 0;
                   END;
              END;
              FLUSHNODELIS(MEM[Q+1].HH.LH);
              FLUSHNODELIS(MEM[Q+1].HH.RH);
              FLUSHNODELIS(MEM[Q+2].HH.LH);
              FLUSHNODELIS(MEM[Q+2].HH.RH);
              MEM[Q].HH.B0 := 14;
              MEM[Q].HH.B1 := CURSTYLE;
              MEM[Q+1].INT := 0;
              MEM[Q+2].INT := 0;
              IF P<>0 THEN
                BEGIN
                  Z := MEM[Q].HH.RH;
                  MEM[Q].HH.RH := P;
                  WHILE MEM[P].HH.RH<>0 DO
                    P := MEM[P].HH.RH;
                  MEM[P].HH.RH := Z;
                END;
              GOTO 81;
            END{:731};
        3,4,5,8,12,7: GOTO 81;
        2:
           BEGIN
             IF MEM[Q+3].INT>MAXH THEN MAXH := MEM[Q+3].INT;
             IF MEM[Q+2].INT>MAXD THEN MAXD := MEM[Q+2].INT;
             GOTO 81;
           END;
        10:
            BEGIN{732:}
              IF MEM[Q].HH.B1=99 THEN
                BEGIN
                  X := MEM[Q+1].HH.LH;
                  Y := MATHGLUE(X,CURMU);
                  DELETEGLUERE(X);
                  MEM[Q+1].HH.LH := Y;
                  MEM[Q].HH.B1 := 0;
                END
              ELSE
                IF (CURSIZE<>0)AND(MEM[Q].HH.B1=98)THEN
                  BEGIN
                    P := MEM[Q].HH.RH;
                    IF P<>0 THEN
                      IF (MEM[P].HH.B0=10)OR(MEM[P].HH.B0=11)THEN
                        BEGIN
                          MEM[Q].HH.
                          RH := MEM[P].HH.RH;
                          MEM[P].HH.RH := 0;
                          FLUSHNODELIS(P);
                        END;
                  END{:732};
              GOTO 81;
            END;
        11:
            BEGIN
              MATHKERN(Q,CURMU);
              GOTO 81;
            END;{:730}
        ELSE confusion_str('mlist1')
      END;
{754:}
      CASE MEM[Q+1].HH.RH OF 
        1,4:{755:}
             BEGIN
               FETCH(Q+1);
               IF (CURI.B0>0)THEN
                 BEGIN
                   DELTA := FONTINFO[ITALICBASE[CURF]+(CURI.B2-0)DIV
                            4].INT;
                   P := NEWCHARACTER(CURF,CURC-0);
                   IF (MEM[Q+1].HH.RH=4)AND(FONTINFO[2+PARAMBASE[CURF]].INT<>0)THEN DELTA := 0
                   ;
                   IF (MEM[Q+3].HH.RH=0)AND(DELTA<>0)THEN
                     BEGIN
                       MEM[P].HH.RH := NEWKERN(DELTA)
                       ;
                       DELTA := 0;
                     END;
                 END
               ELSE P := 0;
             END{:755};
        0: P := 0;
        2: P := MEM[Q+1].HH.LH;
        3:
           BEGIN
             CURMLIST := MEM[Q+1].HH.LH;
             SAVESTYLE := CURSTYLE;
             MLISTPENALTI := FALSE;
             MLISTTOHLIST;
             CURSTYLE := SAVESTYLE;
{703:}
             BEGIN
               IF CURSTYLE<4 THEN CURSIZE := 0
               ELSE CURSIZE := 16*((CURSTYLE-2)
                               DIV 2);
               CURMU := XOVERN(FONTINFO[6+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT,18);
             END{:703};
             P := HPACK(MEM[29997].HH.RH,0,1);
           END;
        ELSE confusion_str('mlist2')
      END;
      MEM[Q+1].INT := P;
      IF (MEM[Q+3].HH.RH=0)AND(MEM[Q+2].HH.RH=0)THEN GOTO 82;
      MAKESCRIPTS(Q,DELTA){:754}{:728};
      82: Z := HPACK(MEM[Q+1].INT,0,1);
      IF MEM[Z+3].INT>MAXH THEN MAXH := MEM[Z+3].INT;
      IF MEM[Z+2].INT>MAXD THEN MAXD := MEM[Z+2].INT;
      FREENODE(Z,7);
      80: R := Q;
      RTYPE := MEM[R].HH.B0;
      81: Q := MEM[Q].HH.RH;
    END{:727};
{729:}
  IF RTYPE=18 THEN MEM[R].HH.B0 := 16{:729};{760:}
  P := 29997;
  MEM[P].HH.RH := 0;
  Q := MLIST;
  RTYPE := 0;
  CURSTYLE := STYLE;
{703:}
  BEGIN
    IF CURSTYLE<4 THEN CURSIZE := 0
    ELSE CURSIZE := 16*((CURSTYLE-2)
                    DIV 2);
    CURMU := XOVERN(FONTINFO[6+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT,18);
  END{:703};
  WHILE Q<>0 DO
    BEGIN{761:}
      T := 16;
      S := 4;
      PEN := 10000;
      CASE MEM[Q].HH.B0 OF 
        17,20,21,22,23: T := MEM[Q].HH.B0;
        18:
            BEGIN
              T := 18;
              PEN := EQTB[5272].INT;
            END;
        19:
            BEGIN
              T := 19;
              PEN := EQTB[5273].INT;
            END;
        16,29,27,26:;
        24: S := 5;
        28: S := 5;
        25: S := 6;
        30,31: T := MAKELEFTRIGH(Q,STYLE,MAXD,MAXH);
        14:{763:}
            BEGIN
              CURSTYLE := MEM[Q].HH.B1;
              S := 3;
{703:}
              BEGIN
                IF CURSTYLE<4 THEN CURSIZE := 0
                ELSE CURSIZE := 16*((CURSTYLE-2)
                                DIV 2);
                CURMU := XOVERN(FONTINFO[6+PARAMBASE[EQTB[3937+CURSIZE].HH.RH]].INT,18);
              END{:703};
              GOTO 83;
            END{:763};
        8,12,2,7,5,3,4,10,11:
                              BEGIN
                                MEM[P].HH.RH := Q;
                                P := Q;
                                Q := MEM[Q].HH.RH;
                                MEM[P].HH.RH := 0;
                                GOTO 30;
                              END;
        ELSE confusion_str('mlist3')
      END{:761};
{766:}
      IF RTYPE>0 THEN
        BEGIN
          CASE STRPOOL[RTYPE*8+T+MAGICOFFSET] OF 
            48: X := 
                     0;
            49:
                IF CURSTYLE<4 THEN X := 15
                ELSE X := 0;
            50: X := 15;
            51:
                IF CURSTYLE<4 THEN X := 16
                ELSE X := 0;
            52:
                IF CURSTYLE<4 THEN X := 17
                ELSE X := 0;
            ELSE confusion_str('mlist4')
          END;
          IF X<>0 THEN
            BEGIN
              Y := MATHGLUE(EQTB[2882+X].HH.RH,CURMU);
              Z := NEWGLUE(Y);
              MEM[Y].HH.RH := 0;
              MEM[P].HH.RH := Z;
              P := Z;
              MEM[Z].HH.B1 := X+1;
            END;
        END{:766};
{767:}
      IF MEM[Q+1].INT<>0 THEN
        BEGIN
          MEM[P].HH.RH := MEM[Q+1].INT;
          REPEAT
            P := MEM[P].HH.RH;
          UNTIL MEM[P].HH.RH=0;
        END;
      IF PENALTIES THEN
        IF MEM[Q].HH.RH<>0 THEN
          IF PEN<10000 THEN
            BEGIN
              RTYPE 
              := MEM[MEM[Q].HH.RH].HH.B0;
              IF RTYPE<>12 THEN
                IF RTYPE<>19 THEN
                  BEGIN
                    Z := NEWPENALTY(PEN);
                    MEM[P].HH.RH := Z;
                    P := Z;
                  END;
            END{:767};
      RTYPE := T;
      83: R := Q;
      Q := MEM[Q].HH.RH;
      FREENODE(R,S);
      30:
    END{:760};
END;{:726}{772:}
PROCEDURE PUSHALIGNMEN;

VAR P: HALFWORD;
BEGIN
  P := GETNODE(5);
  MEM[P].HH.RH := ALIGNPTR;
  MEM[P].HH.LH := CURALIGN;
  MEM[P+1].HH.LH := MEM[29992].HH.RH;
  MEM[P+1].HH.RH := CURSPAN;
  MEM[P+2].INT := CURLOOP;
  MEM[P+3].INT := ALIGNSTATE;
  MEM[P+4].HH.LH := CURHEAD;
  MEM[P+4].HH.RH := CURTAIL;
  ALIGNPTR := P;
  CURHEAD := GETAVAIL;
END;
PROCEDURE POPALIGNMENT;

VAR P: HALFWORD;
BEGIN
  BEGIN
    MEM[CURHEAD].HH.RH := AVAIL;
    AVAIL := CURHEAD;{$IFDEF STATS}
    DYNUSED := DYNUSED-1;{$ENDIF}
  END;
  P := ALIGNPTR;
  CURTAIL := MEM[P+4].HH.RH;
  CURHEAD := MEM[P+4].HH.LH;
  ALIGNSTATE := MEM[P+3].INT;
  CURLOOP := MEM[P+2].INT;
  CURSPAN := MEM[P+1].HH.RH;
  MEM[29992].HH.RH := MEM[P+1].HH.LH;
  CURALIGN := MEM[P].HH.LH;
  ALIGNPTR := MEM[P].HH.RH;
  FREENODE(P,5);
END;
{:772}{774:}{782:}
PROCEDURE GETPREAMBLET;

LABEL 20;
BEGIN
  20: GETTOKEN;
  WHILE (CURCHR=256)AND(CURCMD=4) DO
    BEGIN
      GETTOKEN;
      IF CURCMD>100 THEN
        BEGIN
          EXPAND;
          GETTOKEN;
        END;
    END;
  IF CURCMD=9 THEN fatal_error('(interwoven alignment preambles are not allowed)');
  IF (CURCMD=75)AND(CURCHR=2893)THEN
    BEGIN
      SCANOPTIONAL;
      SCANGLUE(2);
      IF EQTB[5306].INT>0 THEN GEQDEFINE(2893, 117, CURVAL)
                          ELSE EQDEFINE(2893, 117, CURVAL);
      GOTO 20;
    END;
END;
{:782}

{216:}
PROCEDURE PUSHNEST;
BEGIN
  IF NESTPTR>MAXNESTSTACK THEN BEGIN
    MAXNESTSTACK := NESTPTR;
    IF NESTPTR=NESTSIZE THEN overflow('semantic nest size', NESTSIZE);
  END;
  NEST[NESTPTR] := CURLIST;
  NESTPTR := NESTPTR+1;
  CURLIST.HEADFIELD := GETAVAIL;
  CURLIST.TAILFIELD := CURLIST.HEADFIELD;
  CURLIST.PGFIELD := 0;
  CURLIST.MLFIELD := LINE;
END;
{:216}

{217:}
PROCEDURE POPNEST;
BEGIN
  MEM[CURLIST.HEADFIELD].HH.RH := AVAIL;
  AVAIL := CURLIST.HEADFIELD;
{$IFDEF STATS}
  DYNUSED := DYNUSED-1;
{$ENDIF}
  NESTPTR := NESTPTR-1;
  CURLIST := NEST[NESTPTR];
END;
{:217}

{1070:}
PROCEDURE NORMALPARAGR;
BEGIN
  IF EQTB[5282].INT<>0 THEN EQWORDDEFINE(5282,0);
  IF EQTB[5847].INT<>0 THEN EQWORDDEFINE(5847,0);
  IF EQTB[5304].INT<>1 THEN EQWORDDEFINE(5304,1);
  IF EQTB[3412].HH.RH<>0 THEN EQDEFINE(3412,118,0);
END;
{:1070}

PROCEDURE UNSAVE;
VAR P: HALFWORD;
  L: QUARTERWORD;
  T: HALFWORD;
BEGIN
  IF CURLEVEL>1 THEN
    BEGIN
      CURLEVEL := CURLEVEL-1;
{282:}
      WHILE TRUE DO
        BEGIN
          SAVEPTR := SAVEPTR-1;
          IF SAVESTACK[SAVEPTR].HH.B0=3 THEN break;
          P := SAVESTACK[SAVEPTR].HH.RH;
          IF SAVESTACK[SAVEPTR].HH.B0=2 THEN{326:}
            BEGIN
              T := CURTOK;
              CURTOK := P;
              BACKINPUT;
              CURTOK := T;
            END{:326}
          ELSE
            BEGIN
              IF SAVESTACK[SAVEPTR].HH.B0=0 THEN
                BEGIN
                  L := 
                       SAVESTACK[SAVEPTR].HH.B1;
                  SAVEPTR := SAVEPTR-1;
                END
              ELSE SAVESTACK[SAVEPTR] := EQTB[2881];

              {283:}
              IF P<5263 THEN
                IF EQTB[P].HH.B1=1 THEN
                  BEGIN
                    EQDESTROY(SAVESTACK[SAVEPTR]);
                    {$IFDEF STATS}
                    IF EQTB[5300].INT>0 THEN restore_trace_str(P, 'retaining');
                    {$ENDIF}
                  END
              ELSE
                BEGIN
                  EQDESTROY(EQTB[P]);
                  EQTB[P] := SAVESTACK[SAVEPTR];
                  {$IFDEF STATS}
                  IF EQTB[5300].INT>0 THEN restore_trace_str(P, 'restoring');
                  {$ENDIF}
                END
              ELSE
                IF XEQLEVEL[P]<>1 THEN
                  BEGIN
                    EQTB[P] := SAVESTACK[SAVEPTR];
                    XEQLEVEL[P] := L;
                    {$IFDEF STATS}
                    IF EQTB[5300].INT>0 THEN restore_trace_str(P, 'restoring');
                    {$ENDIF}
                  END
              ELSE
                BEGIN
                  {$IFDEF STATS}
                  IF EQTB[5300].INT>0 THEN restore_trace_str(P, 'retaining');
                  {$ENDIF}
                END;
              {:283}

            END;
        END;
      CURGROUP := SAVESTACK[SAVEPTR].HH.B1;
      CURBOUNDARY := SAVESTACK[SAVEPTR].HH.RH{:282};
    END
  ELSE confusion_str('curlevel');
END;

PROCEDURE INITSPAN(P:HALFWORD);
BEGIN
  PUSHNEST;
  IF CURLIST.MODEFIELD=-102 THEN CURLIST.AUXFIELD.HH.LH := 1000
  ELSE
    BEGIN
      CURLIST.AUXFIELD.INT := -65536000;
      NORMALPARAGR;
    END;
  CURSPAN := P;
END;

PROCEDURE INITROW;
BEGIN
  PUSHNEST;
  CURLIST.MODEFIELD := (-103)-CURLIST.MODEFIELD;
  IF CURLIST.MODEFIELD=-102 THEN CURLIST.AUXFIELD.HH.LH := 0
  ELSE CURLIST.
    AUXFIELD.INT := 0;
  BEGIN
    MEM[CURLIST.TAILFIELD].HH.RH := NEWGLUE(MEM[MEM[29992].HH.RH+1].HH.
                                    LH);
    CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
  END;
  MEM[CURLIST.TAILFIELD].HH.B1 := 12;
  CURALIGN := MEM[MEM[29992].HH.RH].HH.RH;
  CURTAIL := CURHEAD;
  INITSPAN(CURALIGN);
END;

{788:}
PROCEDURE INITCOL;
BEGIN
  MEM[CURALIGN+5].HH.LH := CURCMD;
  IF CURCMD=63 THEN ALIGNSTATE := 0
  ELSE
    BEGIN
      BACKINPUT;
      BEGINTOKENLI(MEM[CURALIGN+3].INT,1);
    END;
END;
{:788}

{791:}
FUNCTION FINCOL: BOOLEAN;
VAR P: HALFWORD;
  Q,R: HALFWORD;
  S: HALFWORD;
  U: HALFWORD;
  W: SCALED;
  O: GLUEORD;
  N: HALFWORD;
BEGIN
  IF CURALIGN=0 THEN confusion_str('endv');
  Q := MEM[CURALIGN].HH.RH;
  IF Q=0 THEN confusion_str('endv');
  IF ALIGNSTATE<500000 THEN fatal_error('(interwoven alignment preambles are not allowed)');
  P := MEM[Q].HH.RH;

  {792:}
  IF (P=0)AND(MEM[CURALIGN+5].HH.LH<257)THEN
    IF CURLOOP<>0 THEN{793:}
      BEGIN
        MEM[Q].HH.RH := NEWNULLBOX;
        P := MEM[Q].HH.RH;
        MEM[P].HH.LH := 29991;
        MEM[P+1].INT := -1073741824;
        CURLOOP := MEM[CURLOOP].HH.RH;{794:}
        Q := 29996;
        R := MEM[CURLOOP+3].INT;
        WHILE R<>0 DO
          BEGIN
            MEM[Q].HH.RH := GETAVAIL;
            Q := MEM[Q].HH.RH;
            MEM[Q].HH.LH := MEM[R].HH.LH;
            R := MEM[R].HH.RH;
          END;
        MEM[Q].HH.RH := 0;
        MEM[P+3].INT := MEM[29996].HH.RH;
        Q := 29996;
        R := MEM[CURLOOP+2].INT;
        WHILE R<>0 DO
          BEGIN
            MEM[Q].HH.RH := GETAVAIL;
            Q := MEM[Q].HH.RH;
            MEM[Q].HH.LH := MEM[R].HH.LH;
            R := MEM[R].HH.RH;
          END;
        MEM[Q].HH.RH := 0;
        MEM[P+2].INT := MEM[29996].HH.RH{:794};
        CURLOOP := MEM[CURLOOP].HH.RH;
        MEM[P].HH.RH := NEWGLUE(MEM[CURLOOP+1].HH.LH);
        MEM[MEM[P].HH.RH].HH.B1 := 12;
      END
      {:793}
  ELSE BEGIN
    print_err('Extra alignment tab has been changed to ' + print_esc('cr'));
    help3('You have given more \span or & marks than there were',
          'in the preamble to the \halign or \valign now in progress.',
          'So I''ll assume that you meant to type \cr instead.');
    MEM[CURALIGN+5].HH.LH := 257;
    ERROR;
  END
  {:792};

  IF MEM[CURALIGN+5].HH.LH<>256 THEN
    BEGIN
      UNSAVE;
      NEWSAVELEVEL(6);
{796:}
      BEGIN
        IF CURLIST.MODEFIELD=-102 THEN
          BEGIN
            ADJUSTTAIL := CURTAIL;
            U := HPACK(MEM[CURLIST.HEADFIELD].HH.RH,0,1);
            W := MEM[U+1].INT;
            CURTAIL := ADJUSTTAIL;
            ADJUSTTAIL := 0;
          END
        ELSE
          BEGIN
            U := VPACKAGE(MEM[CURLIST.HEADFIELD].HH.RH,0,1,0);
            W := MEM[U+3].INT;
          END;
        N := 0;
        IF CURSPAN<>CURALIGN THEN{798:}
          BEGIN
            Q := CURSPAN;
            REPEAT
              N := N+1;
              Q := MEM[MEM[Q].HH.RH].HH.RH;
            UNTIL Q=CURALIGN;
            IF N>255 THEN confusion_str('256 spans');
            Q := CURSPAN;
            WHILE MEM[MEM[Q].HH.LH].HH.RH<N DO
              Q := MEM[Q].HH.LH;
            IF MEM[MEM[Q].HH.LH].HH.RH>N THEN
              BEGIN
                S := GETNODE(2);
                MEM[S].HH.LH := MEM[Q].HH.LH;
                MEM[S].HH.RH := N;
                MEM[Q].HH.LH := S;
                MEM[S+1].INT := W;
              END
            ELSE
              IF MEM[MEM[Q].HH.LH+1].INT<W THEN MEM[MEM[Q].HH.LH+1].INT := W;
          END{:798}
        ELSE
          IF W>MEM[CURALIGN+1].INT THEN MEM[CURALIGN+1].INT := W;
        MEM[U].HH.B0 := 13;
        MEM[U].HH.B1 := N;
{659:}
        IF TOTALSTRETCH[3]<>0 THEN O := 3
        ELSE
          IF TOTALSTRETCH[2]<>0 THEN O 
            := 2
        ELSE
          IF TOTALSTRETCH[1]<>0 THEN O := 1
        ELSE O := 0{:659};
        MEM[U+5].HH.B1 := O;
        MEM[U+6].INT := TOTALSTRETCH[O];
{665:}
        IF TOTALSHRINK[3]<>0 THEN O := 3
        ELSE
          IF TOTALSHRINK[2]<>0 THEN O := 2
        ELSE
          IF TOTALSHRINK[1]<>0 THEN O := 1
        ELSE O := 0{:665};
        MEM[U+5].HH.B0 := O;
        MEM[U+4].INT := TOTALSHRINK[O];
        POPNEST;
        MEM[CURLIST.TAILFIELD].HH.RH := U;
        CURLIST.TAILFIELD := U;
      END{:796};
{795:}
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWGLUE(MEM[MEM[CURALIGN].HH.
                                        RH+1].HH.LH);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      MEM[CURLIST.TAILFIELD].HH.B1 := 12{:795};
      IF MEM[CURALIGN+5].HH.LH>=257 THEN
        BEGIN
          FINCOL := TRUE;
          exit;
        END;
      INITSPAN(P);
    END;
  ALIGNSTATE := 1000000;{406:}
  REPEAT
    GETXTOKEN;
  UNTIL CURCMD<>10{:406};
  CURALIGN := P;
  INITCOL;
  FINCOL := FALSE;
END;
{:791}


{800:}
PROCEDURE DOASSIGNMENT; FORWARD;
PROCEDURE BUILDPAGE; FORWARD;




FUNCTION NORMMIN(H:Int32): SMALLNUMBER;
BEGIN
  IF      H<=0  THEN NORMMIN := 1
  ELSE IF H>=63 THEN NORMMIN := 63
                ELSE NORMMIN := H;
END;

PROCEDURE RESUMEAFTERD;
BEGIN
  IF CURGROUP<>15 THEN confusion_str('display');
  UNSAVE;
  CURLIST.PGFIELD := CURLIST.PGFIELD+3;
  PUSHNEST;
  CURLIST.MODEFIELD := 102;
  CURLIST.AUXFIELD.HH.LH := 1000;

  IF EQTB[5313].INT<=0 THEN CURLANG := 0
  ELSE IF EQTB[5313].INT>255 THEN CURLANG := 0
  ELSE CURLANG := EQTB[5313].INT;

  CURLIST.AUXFIELD.HH.RH := CURLANG;
  CURLIST.PGFIELD := (NORMMIN(EQTB[5314].INT)*64+NORMMIN(EQTB[5315].INT))
                     *65536+CURLANG;{443:}
  BEGIN
    GETXTOKEN;
    IF CURCMD<>10 THEN BACKINPUT;
  END{:443};
  IF NESTPTR=1 THEN BUILDPAGE;
END;


PROCEDURE FINALIGN;
VAR P,Q,R,S,U,V: HALFWORD;
  T,W: SCALED;
  O: SCALED;
  N: HALFWORD;
  RULESAVE: SCALED;
  AUXSAVE: MEMORYWORD;
BEGIN
  IF CURGROUP<>6 THEN confusion_str('align1');
  UNSAVE;
  IF CURGROUP<>6 THEN confusion_str('align0');
  UNSAVE;
  IF NEST[NESTPTR-1].MODEFIELD=203 THEN O := EQTB[5845].INT
  ELSE O := 0;
{801:}
  Q := MEM[MEM[29992].HH.RH].HH.RH;
  REPEAT
    FLUSHLIST(MEM[Q+3].INT);
    FLUSHLIST(MEM[Q+2].INT);
    P := MEM[MEM[Q].HH.RH].HH.RH;
    IF MEM[Q+1].INT=-1073741824 THEN{802:}
      BEGIN
        MEM[Q+1].INT := 0;
        R := MEM[Q].HH.RH;
        S := MEM[R+1].HH.LH;
        IF S<>0 THEN
          BEGIN
            MEM[0].HH.RH := MEM[0].HH.RH+1;
            DELETEGLUERE(S);
            MEM[R+1].HH.LH := 0;
          END;
      END{:802};
    IF MEM[Q].HH.LH<>29991 THEN{803:}
      BEGIN
        T := MEM[Q+1].INT+MEM[MEM[MEM[Q].HH
             .RH+1].HH.LH+1].INT;
        R := MEM[Q].HH.LH;
        S := 29991;
        MEM[S].HH.LH := P;
        N := 1;
        REPEAT
          MEM[R+1].INT := MEM[R+1].INT-T;
          U := MEM[R].HH.LH;
          WHILE MEM[R].HH.RH>N DO
            BEGIN
              S := MEM[S].HH.LH;
              N := MEM[MEM[S].HH.LH].HH.RH+1;
            END;
          IF MEM[R].HH.RH<N THEN
            BEGIN
              MEM[R].HH.LH := MEM[S].HH.LH;
              MEM[S].HH.LH := R;
              MEM[R].HH.RH := MEM[R].HH.RH-1;
              S := R;
            END
          ELSE
            BEGIN
              IF MEM[R+1].INT>MEM[MEM[S].HH.LH+1].INT THEN MEM[MEM[S].
                HH.LH+1].INT := MEM[R+1].INT;
              FREENODE(R,2);
            END;
          R := U;
        UNTIL R=29991;
      END{:803};
    MEM[Q].HH.B0 := 13;
    MEM[Q].HH.B1 := 0;
    MEM[Q+3].INT := 0;
    MEM[Q+2].INT := 0;
    MEM[Q+5].HH.B1 := 0;
    MEM[Q+5].HH.B0 := 0;
    MEM[Q+6].INT := 0;
    MEM[Q+4].INT := 0;
    Q := P;
  UNTIL Q=0{:801};{804:}
  SAVEPTR := SAVEPTR-2;
  PACKBEGINLIN := -CURLIST.MLFIELD;
  IF CURLIST.MODEFIELD=-1 THEN
    BEGIN
      RULESAVE := EQTB[5846].INT;
      EQTB[5846].INT := 0;
      P := HPACK(MEM[29992].HH.RH,SAVESTACK[SAVEPTR+1].INT,SAVESTACK[SAVEPTR+0].
           INT);
      EQTB[5846].INT := RULESAVE;
    END
  ELSE
    BEGIN
      Q := MEM[MEM[29992].HH.RH].HH.RH;
      REPEAT
        MEM[Q+3].INT := MEM[Q+1].INT;
        MEM[Q+1].INT := 0;
        Q := MEM[MEM[Q].HH.RH].HH.RH;
      UNTIL Q=0;
      P := VPACKAGE(MEM[29992].HH.RH,SAVESTACK[SAVEPTR+1].INT,SAVESTACK[SAVEPTR
           +0].INT,1073741823);
      Q := MEM[MEM[29992].HH.RH].HH.RH;
      REPEAT
        MEM[Q+1].INT := MEM[Q+3].INT;
        MEM[Q+3].INT := 0;
        Q := MEM[MEM[Q].HH.RH].HH.RH;
      UNTIL Q=0;
    END;
  PACKBEGINLIN := 0{:804};
{805:}
  Q := MEM[CURLIST.HEADFIELD].HH.RH;
  S := CURLIST.HEADFIELD;
  WHILE Q<>0 DO
    BEGIN
      IF NOT(Q>=HIMEMMIN)THEN
        IF MEM[Q].HH.B0=13 THEN
{807:}
          BEGIN
            IF CURLIST.MODEFIELD=-1 THEN
              BEGIN
                MEM[Q].HH.B0 := 0;
                MEM[Q+1].INT := MEM[P+1].INT;
              END
            ELSE
              BEGIN
                MEM[Q].HH.B0 := 1;
                MEM[Q+3].INT := MEM[P+3].INT;
              END;
            MEM[Q+5].HH.B1 := MEM[P+5].HH.B1;
            MEM[Q+5].HH.B0 := MEM[P+5].HH.B0;
            MEM[Q+6].GR := MEM[P+6].GR;
            MEM[Q+4].INT := O;
            R := MEM[MEM[Q+5].HH.RH].HH.RH;
            S := MEM[MEM[P+5].HH.RH].HH.RH;
            REPEAT{808:}
              N := MEM[R].HH.B1;
              T := MEM[S+1].INT;
              W := T;
              U := 29996;
              WHILE N>0 DO
                BEGIN
                  N := N-1;{809:}
                  S := MEM[S].HH.RH;
                  V := MEM[S+1].HH.LH;
                  MEM[U].HH.RH := NEWGLUE(V);
                  U := MEM[U].HH.RH;
                  MEM[U].HH.B1 := 12;
                  T := T+MEM[V+1].INT;
                  IF MEM[P+5].HH.B0=1 THEN
                    BEGIN
                      IF MEM[V].HH.B0=MEM[P+5].HH.B1
                        THEN T := T+ISORound(MEM[P+6].GR*MEM[V+2].INT);
                    END
                  ELSE
                    IF MEM[P+5].HH.B0=2 THEN
                      BEGIN
                        IF MEM[V].HH.B1=MEM[P+5].HH.B1
                          THEN T := T-ISORound(MEM[P+6].GR*MEM[V+3].INT);
                      END;
                  S := MEM[S].HH.RH;
                  MEM[U].HH.RH := NEWNULLBOX;
                  U := MEM[U].HH.RH;
                  T := T+MEM[S+1].INT;
                  IF CURLIST.MODEFIELD=-1 THEN MEM[U+1].INT := MEM[S+1].INT
                  ELSE
                    BEGIN
                      MEM[U
                      ].HH.B0 := 1;
                      MEM[U+3].INT := MEM[S+1].INT;
                    END{:809};
                END;
              IF CURLIST.MODEFIELD=-1 THEN{810:}
                BEGIN
                  MEM[R+3].INT := MEM[Q+3].INT;
                  MEM[R+2].INT := MEM[Q+2].INT;
                  IF T=MEM[R+1].INT THEN
                    BEGIN
                      MEM[R+5].HH.B0 := 0;
                      MEM[R+5].HH.B1 := 0;
                      MEM[R+6].GR := 0.0;
                    END
                  ELSE
                    IF T>MEM[R+1].INT THEN
                      BEGIN
                        MEM[R+5].HH.B0 := 1;
                        IF MEM[R+6].INT=0 THEN MEM[R+6].GR := 0.0
                        ELSE MEM[R+6].GR := (T-MEM[R+1].
                                            INT)/MEM[R+6].INT;
                      END
                  ELSE
                    BEGIN
                      MEM[R+5].HH.B1 := MEM[R+5].HH.B0;
                      MEM[R+5].HH.B0 := 2;
                      IF MEM[R+4].INT=0 THEN MEM[R+6].GR := 0.0
                      ELSE
                        IF (MEM[R+5].HH.B1=0)AND(MEM
                           [R+1].INT-T>MEM[R+4].INT)THEN MEM[R+6].GR := 1.0
                      ELSE MEM[R+6].GR := (MEM[R
                                          +1].INT-T)/MEM[R+4].INT;
                    END;
                  MEM[R+1].INT := W;
                  MEM[R].HH.B0 := 0;
                END{:810}
              ELSE{811:}
                BEGIN
                  MEM[R+1].INT := MEM[Q+1].INT;
                  IF T=MEM[R+3].INT THEN
                    BEGIN
                      MEM[R+5].HH.B0 := 0;
                      MEM[R+5].HH.B1 := 0;
                      MEM[R+6].GR := 0.0;
                    END
                  ELSE
                    IF T>MEM[R+3].INT THEN
                      BEGIN
                        MEM[R+5].HH.B0 := 1;
                        IF MEM[R+6].INT=0 THEN MEM[R+6].GR := 0.0
                        ELSE MEM[R+6].GR := (T-MEM[R+3].
                                            INT)/MEM[R+6].INT;
                      END
                  ELSE
                    BEGIN
                      MEM[R+5].HH.B1 := MEM[R+5].HH.B0;
                      MEM[R+5].HH.B0 := 2;
                      IF MEM[R+4].INT=0 THEN MEM[R+6].GR := 0.0
                      ELSE
                        IF (MEM[R+5].HH.B1=0)AND(MEM
                           [R+3].INT-T>MEM[R+4].INT)THEN MEM[R+6].GR := 1.0
                      ELSE MEM[R+6].GR := (MEM[R
                                          +3].INT-T)/MEM[R+4].INT;
                    END;
                  MEM[R+3].INT := W;
                  MEM[R].HH.B0 := 1;
                END{:811};
              MEM[R+4].INT := 0;
              IF U<>29996 THEN
                BEGIN
                  MEM[U].HH.RH := MEM[R].HH.RH;
                  MEM[R].HH.RH := MEM[29996].HH.RH;
                  R := U;
                END{:808};
              R := MEM[MEM[R].HH.RH].HH.RH;
              S := MEM[MEM[S].HH.RH].HH.RH;
            UNTIL R=0;
          END{:807}
      ELSE
        IF MEM[Q].HH.B0=2 THEN{806:}
          BEGIN
            IF (MEM[Q+1].INT=
               -1073741824)THEN MEM[Q+1].INT := MEM[P+1].INT;
            IF (MEM[Q+3].INT=-1073741824)THEN MEM[Q+3].INT := MEM[P+3].INT;
            IF (MEM[Q+2].INT=-1073741824)THEN MEM[Q+2].INT := MEM[P+2].INT;
            IF O<>0 THEN
              BEGIN
                R := MEM[Q].HH.RH;
                MEM[Q].HH.RH := 0;
                Q := HPACK(Q,0,1);
                MEM[Q+4].INT := O;
                MEM[Q].HH.RH := R;
                MEM[S].HH.RH := Q;
              END;
          END{:806};
      S := Q;
      Q := MEM[Q].HH.RH;
    END{:805};
  FLUSHNODELIS(P);
  POPALIGNMENT;
{812:}
  AUXSAVE := CURLIST.AUXFIELD;
  P := MEM[CURLIST.HEADFIELD].HH.RH;
  Q := CURLIST.TAILFIELD;
  POPNEST;
  IF CURLIST.MODEFIELD=203 THEN{1206:}
    BEGIN
      DOASSIGNMENT;
      IF CURCMD<>3 THEN{1207:}
        BEGIN
          print_err('Missing $$ inserted');
          help2('Displays can use special alignments (like \eqalignno)',
                'only if nothing but the alignment itself is between $$''s.');
          BACKERROR;
        END{:1207}
      ELSE{1197:}
        BEGIN
          GETXTOKEN;
          IF CURCMD<>3 THEN BEGIN
            print_err('Display math should end with $$');
            help2('The `$'' that I just saw supposedly matches a previous `$$''.',
                  'So I shall assume that you typed `$$'' both times.');
            BACKERROR;
          END;
        END{:1197};
      POPNEST;
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWPENALTY(EQTB[5274].INT);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWPARAMGLUE(3);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      MEM[CURLIST.TAILFIELD].HH.RH := P;
      IF P<>0 THEN CURLIST.TAILFIELD := Q;
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWPENALTY(EQTB[5275].INT);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWPARAMGLUE(4);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      CURLIST.AUXFIELD.INT := AUXSAVE.INT;
      RESUMEAFTERD;
    END{:1206}
  ELSE
    BEGIN
      CURLIST.AUXFIELD := AUXSAVE;
      MEM[CURLIST.TAILFIELD].HH.RH := P;
      IF P<>0 THEN CURLIST.TAILFIELD := Q;
      IF CURLIST.MODEFIELD=1 THEN BUILDPAGE;
    END{:812};
END;


PROCEDURE ALIGNPEEK;
BEGIN
  repeat
    ALIGNSTATE := 1000000;
    REPEAT
      GETXTOKEN;
    UNTIL CURCMD<>10;
  until (CURCMD<>5) OR (CURCHR<>258);
  IF CURCMD=34 THEN BEGIN
    SCANLEFTBRAC;
    NEWSAVELEVEL(7);
    IF CURLIST.MODEFIELD=-1 THEN NORMALPARAGR;
  END ELSE IF CURCMD=2 THEN FINALIGN
  ELSE BEGIN
    INITROW;
    INITCOL;
  END;
END;


PROCEDURE INITALIGN;
VAR SAVECSPTR: HALFWORD;
  P: HALFWORD;
BEGIN
  SAVECSPTR := CURCS;
  PUSHALIGNMEN;
  ALIGNSTATE := -1000000;
  {776:}
  IF (CURLIST.MODEFIELD=203) AND
     ((CURLIST.TAILFIELD<>CURLIST.HEADFIELD) OR (CURLIST.AUXFIELD.INT<>0))
  THEN BEGIN
    print_err('Improper ' + print_esc('halign') + ' inside $$''s');
    help3('Displays can use special alignments (like \eqalignno)',
          'only if nothing but the alignment itself is between $$''s.',
          'So I''ve deleted the formulas that preceded this alignment.');
    ERROR;
    FLUSHMATH;
  END
  {:776};
  PUSHNEST;

  {775:}
  IF CURLIST.MODEFIELD=203 THEN BEGIN
    CURLIST.MODEFIELD := -1;
    CURLIST.AUXFIELD.INT := NEST[NESTPTR-2].AUXFIELD.INT;
  END ELSE IF CURLIST.MODEFIELD>0 THEN CURLIST.MODEFIELD := -CURLIST.MODEFIELD;
  {:775}

  SCANSPEC(6,FALSE);
  MEM[29992].HH.RH := 0;
  CURALIGN := 29992;
  CURLOOP := 0;
  SCANNERSTATU := 4;
  WARNINGINDEX := SAVECSPTR;
  ALIGNSTATE := -1000000;
  WHILE TRUE DO BEGIN
    {778:}
    MEM[CURALIGN].HH.RH := NEWPARAMGLUE(11);
    CURALIGN := MEM[CURALIGN].HH.RH;
    {:778}
    IF CURCMD=5 THEN break;
    {779:}
    {783:}
    P := 29996;
    MEM[P].HH.RH := 0;
    WHILE TRUE DO BEGIN
      GETPREAMBLET;
      IF CURCMD=6 THEN break;
      IF (CURCMD<=5)AND(CURCMD>=4)AND(ALIGNSTATE=-1000000)THEN
        IF (P=29996)AND(CURLOOP=0)AND(CURCMD=4)THEN CURLOOP := CURALIGN
        ELSE BEGIN
          print_err('Missing # inserted in alignment preamble');
          help3('There should be exactly one # between &''s, when an',
                '\halign or \valign is being set up. In this case you had',
                'none, so I''ve put one in; maybe that will work.');
          BACKERROR;
          break;
        END ELSE IF (CURCMD<>10)OR(P<>29996) THEN BEGIN
          MEM[P].HH.RH := GETAVAIL;
          P := MEM[P].HH.RH;
          MEM[P].HH.LH := CURTOK;
        END;
    END;
    {:783};

    MEM[CURALIGN].HH.RH := NEWNULLBOX;
    CURALIGN := MEM[CURALIGN].HH.RH;
    MEM[CURALIGN].HH.LH := 29991;
    MEM[CURALIGN+1].INT := -1073741824;
    MEM[CURALIGN+3].INT := MEM[29996].HH.RH;{784:}
    P := 29996;
    MEM[P].HH.RH := 0;
    WHILE TRUE DO BEGIN
      GETPREAMBLET;
      IF (CURCMD<=5)AND(CURCMD>=4)AND(ALIGNSTATE=-1000000) THEN break;
      IF CURCMD=6 THEN BEGIN
        print_err('Only one # is allowed per tab');
        help3('There should be exactly one # between &''s, when an',
              '\halign or \valign is being set up. In this case you had',
              'more than one, so I''m ignoring all but the first.');
        ERROR;
        continue;
      END;
      MEM[P].HH.RH := GETAVAIL;
      P := MEM[P].HH.RH;
      MEM[P].HH.LH := CURTOK;
    END;
    MEM[P].HH.RH := GETAVAIL;
    P := MEM[P].HH.RH;
    MEM[P].HH.LH := 6714{:784};
    MEM[CURALIGN+2].INT := MEM[29996].HH.RH{:779};
  END;
  SCANNERSTATU := 0;
  NEWSAVELEVEL(6);
  IF EQTB[3420].HH.RH<>0 THEN BEGINTOKENLI(EQTB[3420].HH.RH,13);
  ALIGNPEEK;
END;
{:774}


FUNCTION FINITESHRINK(P:HALFWORD): HALFWORD;
VAR Q: HALFWORD;
BEGIN
  IF NOSHRINKERRO THEN BEGIN
    NOSHRINKERRO := FALSE;
{$IFDEF STATS}
    IF EQTB[5295].INT>0 THEN ENDDIAGNOSTI(TRUE);
{$ENDIF}
    print_err('Infinite glue shrinkage found in a paragraph');
    help5('The paragraph just ended includes some glue that has',
          'infinite shrinkability, e.g., `\hskip 0pt minus 1fil''.',
          'Such glue doesn''t belong there---it allows a paragraph',
          'of any length to fit on one line. But it''s safe to proceed,',
          'since the offensive shrinkability has been made finite.');
    ERROR;
{$IFDEF STATS}
    IF EQTB[5295].INT>0 THEN BEGINDIAGNOS;
{$ENDIF}
  END;
  Q := NEWSPEC(P);
  MEM[Q].HH.B1 := 0;
  DELETEGLUERE(P);
  FINITESHRINK := Q;
END;


{829:}
PROCEDURE TRYBREAK(PI:Int32;BREAKTYPE:SMALLNUMBER);

LABEL 10,30,31,22,60;

VAR R: HALFWORD;
  PREVR: HALFWORD;
  OLDL: HALFWORD;
  NOBREAKYET: BOOLEAN;{830:}
  PREVPREVR: HALFWORD;
  S: HALFWORD;
  Q: HALFWORD;
  V: HALFWORD;
  T: Int32;
  F: INTERNALFONT;
  L: HALFWORD;
  NODERSTAYSAC: BOOLEAN;
  LINEWIDTH: SCALED;
  FITCLASS: 0..3;
  B: HALFWORD;
  D: Int32;
  ARTIFICIALDE: BOOLEAN;
  SAVELINK: HALFWORD;
  SHORTFALL: SCALED;
{:830}
BEGIN{831:}
  IF ABS(PI)>=10000 THEN
    IF PI>0 THEN goto 10
  ELSE PI := -10000{:831};
  NOBREAKYET := TRUE;
  PREVR := 29993;
  OLDL := 0;
  CURACTIVEWID[1] := ACTIVEWIDTH[1];
  CURACTIVEWID[2] := ACTIVEWIDTH[2];
  CURACTIVEWID[3] := ACTIVEWIDTH[3];
  CURACTIVEWID[4] := ACTIVEWIDTH[4];
  CURACTIVEWID[5] := ACTIVEWIDTH[5];
  CURACTIVEWID[6] := ACTIVEWIDTH[6];
  WHILE TRUE DO
    BEGIN
      22: R := MEM[PREVR].HH.RH;
{832:}
      IF MEM[R].HH.B0=2 THEN
        BEGIN
          CURACTIVEWID[1] := CURACTIVEWID[1]+MEM[
                             R+1].INT;
          CURACTIVEWID[2] := CURACTIVEWID[2]+MEM[R+2].INT;
          CURACTIVEWID[3] := CURACTIVEWID[3]+MEM[R+3].INT;
          CURACTIVEWID[4] := CURACTIVEWID[4]+MEM[R+4].INT;
          CURACTIVEWID[5] := CURACTIVEWID[5]+MEM[R+5].INT;
          CURACTIVEWID[6] := CURACTIVEWID[6]+MEM[R+6].INT;
          PREVPREVR := PREVR;
          PREVR := R;
          GOTO 22;
        END{:832};{835:}
      BEGIN
        L := MEM[R+1].HH.LH;
        IF L>OLDL THEN
          BEGIN
            IF (MINIMUMDEMER<1073741823)AND((OLDL<>EASYLINE)OR(R
               =29993))THEN{836:}
              BEGIN
                IF NOBREAKYET THEN{837:}
                  BEGIN
                    NOBREAKYET := FALSE;
                    BREAKWIDTH[1] := BACKGROUND[1];
                    BREAKWIDTH[2] := BACKGROUND[2];
                    BREAKWIDTH[3] := BACKGROUND[3];
                    BREAKWIDTH[4] := BACKGROUND[4];
                    BREAKWIDTH[5] := BACKGROUND[5];
                    BREAKWIDTH[6] := BACKGROUND[6];
                    S := CURP;
                    IF BREAKTYPE>0 THEN
                      IF CURP<>0 THEN{840:}
                        BEGIN
                          T := MEM[CURP].HH.B1;
                          V := CURP;
                          S := MEM[CURP+1].HH.RH;
                          WHILE T>0 DO
                            BEGIN
                              T := T-1;
                              V := MEM[V].HH.RH;
{841:}
                              IF (V>=HIMEMMIN)THEN
                                BEGIN
                                  F := MEM[V].HH.B0;
                                  BREAKWIDTH[1] := BREAKWIDTH[1]-FONTINFO[WIDTHBASE[F]+FONTINFO[
                                                   CHARBASE[F]+
                                                   MEM[V].HH.B1].QQQQ.B0].INT;
                                END
                              ELSE
                                CASE MEM[V].HH.B0 OF 
                                  6:
                                     BEGIN
                                       F := MEM[V+1].HH.B0;
                                       BREAKWIDTH[1] := BREAKWIDTH[1]-FONTINFO[WIDTHBASE[F]+FONTINFO
                                                        [CHARBASE[F]+
                                                        MEM[V+1].HH.B1].QQQQ.B0].INT;
                                     END;
                                  0,1,2,11: BREAKWIDTH[1] := BREAKWIDTH[1]-MEM[V+1].INT;
                                  ELSE confusion_str('disc1')
                                END{:841};
                            END;
                          WHILE S<>0 DO
                            BEGIN{842:}
                              IF (S>=HIMEMMIN)THEN
                                BEGIN
                                  F := MEM[S].HH.B0;
                                  BREAKWIDTH[1] := BREAKWIDTH[1]+FONTINFO[WIDTHBASE[F]+FONTINFO[
                                                   CHARBASE[F]+
                                                   MEM[S].HH.B1].QQQQ.B0].INT;
                                END
                              ELSE
                                CASE MEM[S].HH.B0 OF 
                                  6:
                                     BEGIN
                                       F := MEM[S+1].HH.B0;
                                       BREAKWIDTH[1] := BREAKWIDTH[1]+FONTINFO[WIDTHBASE[F]+FONTINFO
                                                        [CHARBASE[F]+
                                                        MEM[S+1].HH.B1].QQQQ.B0].INT;
                                     END;
                                  0,1,2,11: BREAKWIDTH[1] := BREAKWIDTH[1]+MEM[S+1].INT;
                                  ELSE confusion_str('disc2')
                                END{:842};
                              S := MEM[S].HH.RH;
                            END;
                          BREAKWIDTH[1] := BREAKWIDTH[1]+DISCWIDTH;
                          IF MEM[CURP+1].HH.RH=0 THEN S := MEM[V].HH.RH;
                        END{:840};
                    WHILE S<>0 DO
                      BEGIN
                        IF (S>=HIMEMMIN)THEN GOTO 30;
                        CASE MEM[S].HH.B0 OF 
                          10:{838:}
                              BEGIN
                                V := MEM[S+1].HH.LH;
                                BREAKWIDTH[1] := BREAKWIDTH[1]-MEM[V+1].INT;
                                BREAKWIDTH[2+MEM[V].HH.B0] := BREAKWIDTH[2+MEM[V].HH.B0]-MEM[V+2].
                                                              INT;
                                BREAKWIDTH[6] := BREAKWIDTH[6]-MEM[V+3].INT;
                              END{:838};
                          12:;
                          9: BREAKWIDTH[1] := BREAKWIDTH[1]-MEM[S+1].INT;
                          11:
                              IF MEM[S].HH.B1<>1 THEN GOTO 30
                              ELSE BREAKWIDTH[1] := BREAKWIDTH[1]-MEM
                                                    [S+1].INT;
                          ELSE GOTO 30
                        END;
                        S := MEM[S].HH.RH;
                      END;
                    30:
                  END{:837};
{843:}
                IF MEM[PREVR].HH.B0=2 THEN
                  BEGIN
                    MEM[PREVR+1].INT := MEM[PREVR+1].
                                        INT-CURACTIVEWID[1]+BREAKWIDTH[1];
                    MEM[PREVR+2].INT := MEM[PREVR+2].INT-CURACTIVEWID[2]+BREAKWIDTH[2];
                    MEM[PREVR+3].INT := MEM[PREVR+3].INT-CURACTIVEWID[3]+BREAKWIDTH[3];
                    MEM[PREVR+4].INT := MEM[PREVR+4].INT-CURACTIVEWID[4]+BREAKWIDTH[4];
                    MEM[PREVR+5].INT := MEM[PREVR+5].INT-CURACTIVEWID[5]+BREAKWIDTH[5];
                    MEM[PREVR+6].INT := MEM[PREVR+6].INT-CURACTIVEWID[6]+BREAKWIDTH[6];
                  END
                ELSE
                  IF PREVR=29993 THEN
                    BEGIN
                      ACTIVEWIDTH[1] := BREAKWIDTH[1];
                      ACTIVEWIDTH[2] := BREAKWIDTH[2];
                      ACTIVEWIDTH[3] := BREAKWIDTH[3];
                      ACTIVEWIDTH[4] := BREAKWIDTH[4];
                      ACTIVEWIDTH[5] := BREAKWIDTH[5];
                      ACTIVEWIDTH[6] := BREAKWIDTH[6];
                    END
                ELSE
                  BEGIN
                    Q := GETNODE(7);
                    MEM[Q].HH.RH := R;
                    MEM[Q].HH.B0 := 2;
                    MEM[Q].HH.B1 := 0;
                    MEM[Q+1].INT := BREAKWIDTH[1]-CURACTIVEWID[1];
                    MEM[Q+2].INT := BREAKWIDTH[2]-CURACTIVEWID[2];
                    MEM[Q+3].INT := BREAKWIDTH[3]-CURACTIVEWID[3];
                    MEM[Q+4].INT := BREAKWIDTH[4]-CURACTIVEWID[4];
                    MEM[Q+5].INT := BREAKWIDTH[5]-CURACTIVEWID[5];
                    MEM[Q+6].INT := BREAKWIDTH[6]-CURACTIVEWID[6];
                    MEM[PREVR].HH.RH := Q;
                    PREVPREVR := PREVR;
                    PREVR := Q;
                  END{:843};
                IF ABS(EQTB[5279].INT)>=1073741823-MINIMUMDEMER THEN MINIMUMDEMER := 
                                                                                     1073741822
                ELSE MINIMUMDEMER := MINIMUMDEMER+ABS(EQTB[5279].INT);
                FOR FITCLASS:=0 TO 3 DO
                  BEGIN
                    IF MINIMALDEMER[FITCLASS]<=MINIMUMDEMER
                      THEN{845:}
                      BEGIN
                        Q := GETNODE(2);
                        MEM[Q].HH.RH := PASSIVE;
                        PASSIVE := Q;
                        MEM[Q+1].HH.RH := CURP;{$IFDEF STATS}
                        PASSNUMBER := PASSNUMBER+1;
                        MEM[Q].HH.LH := PASSNUMBER;{$ENDIF}
                        MEM[Q+1].HH.LH := BESTPLACE[FITCLASS];
                        Q := GETNODE(3);
                        MEM[Q+1].HH.RH := PASSIVE;
                        MEM[Q+1].HH.LH := BESTPLLINE[FITCLASS]+1;
                        MEM[Q].HH.B1 := FITCLASS;
                        MEM[Q].HH.B0 := BREAKTYPE;
                        MEM[Q+2].INT := MINIMALDEMER[FITCLASS];
                        MEM[Q].HH.RH := R;
                        MEM[PREVR].HH.RH := Q;
                        PREVR := Q;{$IFDEF STATS}
                        IF EQTB[5295].INT>0 THEN{846:}
                          BEGIN
                            print_nl_str('@@');
                            PRINTINT(MEM[PASSIVE].HH.LH);
                            print_str(': line ');
                            PRINTINT(MEM[Q+1].HH.LH-1);
                            PRINTCHAR(46);
                            PRINTINT(FITCLASS);
                            IF BREAKTYPE=1 THEN PRINTCHAR(45);
                            print_str(' t=');
                            PRINTINT(MEM[Q+2].INT);
                            print_str(' -> @@');
                            IF MEM[PASSIVE+1].HH.LH=0 THEN PRINTCHAR(48)
                            ELSE PRINTINT(MEM[MEM[
                                          PASSIVE+1].HH.LH].HH.LH);
                          END{:846};{$ENDIF}
                      END{:845};
                    MINIMALDEMER[FITCLASS] := 1073741823;
                  END;
                MINIMUMDEMER := 1073741823;
{844:}
                IF R<>29993 THEN
                  BEGIN
                    Q := GETNODE(7);
                    MEM[Q].HH.RH := R;
                    MEM[Q].HH.B0 := 2;
                    MEM[Q].HH.B1 := 0;
                    MEM[Q+1].INT := CURACTIVEWID[1]-BREAKWIDTH[1];
                    MEM[Q+2].INT := CURACTIVEWID[2]-BREAKWIDTH[2];
                    MEM[Q+3].INT := CURACTIVEWID[3]-BREAKWIDTH[3];
                    MEM[Q+4].INT := CURACTIVEWID[4]-BREAKWIDTH[4];
                    MEM[Q+5].INT := CURACTIVEWID[5]-BREAKWIDTH[5];
                    MEM[Q+6].INT := CURACTIVEWID[6]-BREAKWIDTH[6];
                    MEM[PREVR].HH.RH := Q;
                    PREVPREVR := PREVR;
                    PREVR := Q;
                  END{:844};
              END{:836};
            IF R=29993 THEN goto 10;
{850:}
            IF L>EASYLINE THEN
              BEGIN
                LINEWIDTH := SECONDWIDTH;
                OLDL := 65534;
              END
            ELSE
              BEGIN
                OLDL := L;
                IF L>LASTSPECIALL THEN LINEWIDTH := SECONDWIDTH
                ELSE
                  IF EQTB[3412].HH.RH=0
                    THEN LINEWIDTH := FIRSTWIDTH
                ELSE LINEWIDTH := MEM[EQTB[3412].HH.RH+2*L].INT
                ;
              END{:850};
          END;
      END{:835};{851:}
      BEGIN
        ARTIFICIALDE := FALSE;
        SHORTFALL := LINEWIDTH-CURACTIVEWID[1];
        IF SHORTFALL>0 THEN{852:}
          IF (CURACTIVEWID[3]<>0)OR(CURACTIVEWID[4]<>0)OR(
             CURACTIVEWID[5]<>0)THEN
            BEGIN
              B := 0;
              FITCLASS := 2;
            END
        ELSE
          BEGIN
            IF SHORTFALL>7230584 THEN
              IF CURACTIVEWID[2]<1663497 THEN
                BEGIN
                  B := 10000;
                  FITCLASS := 0;
                  GOTO 31;
                END;
            B := BADNESS(SHORTFALL,CURACTIVEWID[2]);
            IF B>12 THEN
              IF B>99 THEN FITCLASS := 0
            ELSE FITCLASS := 1
            ELSE FITCLASS := 2;
            31:
          END{:852}
        ELSE{853:}
          BEGIN
            IF -SHORTFALL>CURACTIVEWID[6]THEN B := 10001
            ELSE B := BADNESS(-SHORTFALL,CURACTIVEWID[6]);
            IF B>12 THEN FITCLASS := 3
            ELSE FITCLASS := 2;
          END{:853};
        IF (B>10000)OR(PI=-10000)THEN{854:}
          BEGIN
            IF FINALPASS AND(MINIMUMDEMER=
               1073741823)AND(MEM[R].HH.RH=29993)AND(PREVR=29993)THEN ARTIFICIALDE := 
                                                                                      TRUE
            ELSE
              IF B>THRESHOLD THEN GOTO 60;
            NODERSTAYSAC := FALSE;
          END{:854}
        ELSE
          BEGIN
            PREVR := R;
            IF B>THRESHOLD THEN GOTO 22;
            NODERSTAYSAC := TRUE;
          END;
{855:}
        IF ARTIFICIALDE THEN D := 0
        ELSE{859:}
          BEGIN
            D := EQTB[5265].INT+B;
            IF ABS(D)>=10000 THEN D := 100000000
            ELSE D := D*D;
            IF PI<>0 THEN
              IF PI>0 THEN D := D+PI*PI
            ELSE
              IF PI>-10000 THEN D := D-PI*PI;
            IF (BREAKTYPE=1)AND(MEM[R].HH.B0=1)THEN
              IF CURP<>0 THEN D := D+EQTB[5277].
                                   INT
            ELSE D := D+EQTB[5278].INT;
            IF ABS(FITCLASS-MEM[R].HH.B1)>1 THEN D := D+EQTB[5279].INT;
          END{:859};
{$IFDEF STATS}
        IF EQTB[5295].INT>0 THEN{856:}
          BEGIN
            IF PRINTEDNODE<>CURP THEN{857:}
              BEGIN
                print_nl_str('');
                IF CURP=0 THEN SHORTDISPLAY(MEM[PRINTEDNODE].HH.RH)
                ELSE
                  BEGIN
                    SAVELINK := MEM[CURP].HH.RH;
                    MEM[CURP].HH.RH := 0;
                    print_nl_str('');
                    SHORTDISPLAY(MEM[PRINTEDNODE].HH.RH);
                    MEM[CURP].HH.RH := SAVELINK;
                  END;
                PRINTEDNODE := CURP;
              END{:857};
            print_nl_str('@');
            IF CURP=0 THEN print_esc_str('par')
            ELSE
              IF MEM[CURP].HH.B0<>10 THEN
                BEGIN
                  IF 
                     MEM[CURP].HH.B0=12 THEN print_esc_str('penalty')
                  ELSE
                    IF MEM[CURP].HH.B0=7 THEN
                      print_esc_str('discretionary')
                  ELSE
                    IF MEM[CURP].HH.B0=11 THEN print_esc_str('kern')
                  ELSE print_esc_str('math');
                END;
            print_str(' via @@');
            IF MEM[R+1].HH.RH=0 THEN PRINTCHAR(48)
            ELSE PRINTINT(MEM[MEM[R+1].HH.RH].
                          HH.LH);
            print_str(' b=');
            IF B>10000 THEN PRINTCHAR(42)
            ELSE PRINTINT(B);
            print_str(' p=');
            PRINTINT(PI);
            print_str(' d=');
            IF ARTIFICIALDE THEN PRINTCHAR(42)
            ELSE PRINTINT(D);
          END{:856};{$ENDIF}
        D := D+MEM[R+2].INT;
        IF D<=MINIMALDEMER[FITCLASS]THEN
          BEGIN
            MINIMALDEMER[FITCLASS] := D;
            BESTPLACE[FITCLASS] := MEM[R+1].HH.RH;
            BESTPLLINE[FITCLASS] := L;
            IF D<MINIMUMDEMER THEN MINIMUMDEMER := D;
          END{:855};
        IF NODERSTAYSAC THEN GOTO 22;
        60:{860:}MEM[PREVR].HH.RH := MEM[R].HH.RH;
        FREENODE(R,3);
        IF PREVR=29993 THEN{861:}
          BEGIN
            R := MEM[29993].HH.RH;
            IF MEM[R].HH.B0=2 THEN
              BEGIN
                ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+MEM[R+1].INT
                ;
                ACTIVEWIDTH[2] := ACTIVEWIDTH[2]+MEM[R+2].INT;
                ACTIVEWIDTH[3] := ACTIVEWIDTH[3]+MEM[R+3].INT;
                ACTIVEWIDTH[4] := ACTIVEWIDTH[4]+MEM[R+4].INT;
                ACTIVEWIDTH[5] := ACTIVEWIDTH[5]+MEM[R+5].INT;
                ACTIVEWIDTH[6] := ACTIVEWIDTH[6]+MEM[R+6].INT;
                CURACTIVEWID[1] := ACTIVEWIDTH[1];
                CURACTIVEWID[2] := ACTIVEWIDTH[2];
                CURACTIVEWID[3] := ACTIVEWIDTH[3];
                CURACTIVEWID[4] := ACTIVEWIDTH[4];
                CURACTIVEWID[5] := ACTIVEWIDTH[5];
                CURACTIVEWID[6] := ACTIVEWIDTH[6];
                MEM[29993].HH.RH := MEM[R].HH.RH;
                FREENODE(R,7);
              END;
          END{:861}
        ELSE
          IF MEM[PREVR].HH.B0=2 THEN
            BEGIN
              R := MEM[PREVR].HH.RH;
              IF R=29993 THEN
                BEGIN
                  CURACTIVEWID[1] := CURACTIVEWID[1]-MEM[PREVR+1].INT;
                  CURACTIVEWID[2] := CURACTIVEWID[2]-MEM[PREVR+2].INT;
                  CURACTIVEWID[3] := CURACTIVEWID[3]-MEM[PREVR+3].INT;
                  CURACTIVEWID[4] := CURACTIVEWID[4]-MEM[PREVR+4].INT;
                  CURACTIVEWID[5] := CURACTIVEWID[5]-MEM[PREVR+5].INT;
                  CURACTIVEWID[6] := CURACTIVEWID[6]-MEM[PREVR+6].INT;
                  MEM[PREVPREVR].HH.RH := 29993;
                  FREENODE(PREVR,7);
                  PREVR := PREVPREVR;
                END
              ELSE
                IF MEM[R].HH.B0=2 THEN
                  BEGIN
                    CURACTIVEWID[1] := CURACTIVEWID[1]+
                                       MEM[R+1].INT;
                    CURACTIVEWID[2] := CURACTIVEWID[2]+MEM[R+2].INT;
                    CURACTIVEWID[3] := CURACTIVEWID[3]+MEM[R+3].INT;
                    CURACTIVEWID[4] := CURACTIVEWID[4]+MEM[R+4].INT;
                    CURACTIVEWID[5] := CURACTIVEWID[5]+MEM[R+5].INT;
                    CURACTIVEWID[6] := CURACTIVEWID[6]+MEM[R+6].INT;
                    MEM[PREVR+1].INT := MEM[PREVR+1].INT+MEM[R+1].INT;
                    MEM[PREVR+2].INT := MEM[PREVR+2].INT+MEM[R+2].INT;
                    MEM[PREVR+3].INT := MEM[PREVR+3].INT+MEM[R+3].INT;
                    MEM[PREVR+4].INT := MEM[PREVR+4].INT+MEM[R+4].INT;
                    MEM[PREVR+5].INT := MEM[PREVR+5].INT+MEM[R+5].INT;
                    MEM[PREVR+6].INT := MEM[PREVR+6].INT+MEM[R+6].INT;
                    MEM[PREVR].HH.RH := MEM[R].HH.RH;
                    FREENODE(R,7);
                  END;
            END{:860};
      END{:851};
    END;
  10:
{$IFDEF STATS}
{858:}
      IF CURP=PRINTEDNODE THEN
        IF CURP<>0 THEN
          IF MEM[CURP].HH.B0=7 THEN
            BEGIN
              T := MEM[CURP].HH.B1;
              WHILE T>0 DO
                BEGIN
                  T := T-1;
                  PRINTEDNODE := MEM[PRINTEDNODE].HH.RH;
                END;
            END
{:858}
{$ENDIF}
END;
{:829}{877:}
PROCEDURE POSTLINEBREA(FINALWIDOWPE:Int32);

LABEL 30,31;

VAR Q,R,S: HALFWORD;
  DISCBREAK: BOOLEAN;
  POSTDISCBREA: BOOLEAN;
  CURWIDTH: SCALED;
  CURINDENT: SCALED;
  T: QUARTERWORD;
  PEN: Int32;
  CURLINE: HALFWORD;
BEGIN{878:}
  Q := MEM[BESTBET+1].HH.RH;
  CURP := 0;
  REPEAT
    R := Q;
    Q := MEM[Q+1].HH.LH;
    MEM[R+1].HH.LH := CURP;
    CURP := R;
  UNTIL Q=0{:878};
  CURLINE := CURLIST.PGFIELD+1;
  REPEAT{880:}{881:}
    Q := MEM[CURP+1].HH.RH;
    DISCBREAK := FALSE;
    POSTDISCBREA := FALSE;
    IF Q<>0 THEN
      IF MEM[Q].HH.B0=10 THEN
        BEGIN
          DELETEGLUERE(MEM[Q+1].HH.LH);
          MEM[Q+1].HH.LH := EQTB[2890].HH.RH;
          MEM[Q].HH.B1 := 9;
          MEM[EQTB[2890].HH.RH].HH.RH := MEM[EQTB[2890].HH.RH].HH.RH+1;
          GOTO 30;
        END
    ELSE
      BEGIN
        IF MEM[Q].HH.B0=7 THEN{882:}
          BEGIN
            T := MEM[Q].HH.B1;
{883:}
            IF T=0 THEN R := MEM[Q].HH.RH
            ELSE
              BEGIN
                R := Q;
                WHILE T>1 DO
                  BEGIN
                    R := MEM[R].HH.RH;
                    T := T-1;
                  END;
                S := MEM[R].HH.RH;
                R := MEM[S].HH.RH;
                MEM[S].HH.RH := 0;
                FLUSHNODELIS(MEM[Q].HH.RH);
                MEM[Q].HH.B1 := 0;
              END{:883};
            IF MEM[Q+1].HH.RH<>0 THEN{884:}
              BEGIN
                S := MEM[Q+1].HH.RH;
                WHILE MEM[S].HH.RH<>0 DO
                  S := MEM[S].HH.RH;
                MEM[S].HH.RH := R;
                R := MEM[Q+1].HH.RH;
                MEM[Q+1].HH.RH := 0;
                POSTDISCBREA := TRUE;
              END{:884};
            IF MEM[Q+1].HH.LH<>0 THEN{885:}
              BEGIN
                S := MEM[Q+1].HH.LH;
                MEM[Q].HH.RH := S;
                WHILE MEM[S].HH.RH<>0 DO
                  S := MEM[S].HH.RH;
                MEM[Q+1].HH.LH := 0;
                Q := S;
              END{:885};
            MEM[Q].HH.RH := R;
            DISCBREAK := TRUE;
          END{:882}
        ELSE
          IF (MEM[Q].HH.B0=9)OR(MEM[Q].HH.B0=11)THEN MEM[Q+1].INT := 0;
      END
    ELSE
      BEGIN
        Q := 29997;
        WHILE MEM[Q].HH.RH<>0 DO
          Q := MEM[Q].HH.RH;
      END;
{886:}
    R := NEWPARAMGLUE(8);
    MEM[R].HH.RH := MEM[Q].HH.RH;
    MEM[Q].HH.RH := R;
    Q := R{:886};
    30:{:881};{887:}
    R := MEM[Q].HH.RH;
    MEM[Q].HH.RH := 0;
    Q := MEM[29997].HH.RH;
    MEM[29997].HH.RH := R;
    IF EQTB[2889].HH.RH<>0 THEN
      BEGIN
        R := NEWPARAMGLUE(7);
        MEM[R].HH.RH := Q;
        Q := R;
      END{:887};
{889:}
    IF CURLINE>LASTSPECIALL THEN
      BEGIN
        CURWIDTH := SECONDWIDTH;
        CURINDENT := SECONDINDENT;
      END
    ELSE
      IF EQTB[3412].HH.RH=0 THEN
        BEGIN
          CURWIDTH := FIRSTWIDTH;
          CURINDENT := FIRSTINDENT;
        END
    ELSE
      BEGIN
        CURWIDTH := MEM[EQTB[3412].HH.RH+2*CURLINE].INT;
        CURINDENT := MEM[EQTB[3412].HH.RH+2*CURLINE-1].INT;
      END;
    ADJUSTTAIL := 29995;
    JUSTBOX := HPACK(Q,CURWIDTH,0);
    MEM[JUSTBOX+4].INT := CURINDENT{:889};
{888:}
    APPENDTOVLIS(JUSTBOX);
    IF 29995<>ADJUSTTAIL THEN
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := MEM[29995]
                                        .HH.RH;
        CURLIST.TAILFIELD := ADJUSTTAIL;
      END;
    ADJUSTTAIL := 0{:888};
{890:}
    IF CURLINE+1<>BESTLINE THEN
      BEGIN
        PEN := EQTB[5276].INT;
        IF CURLINE=CURLIST.PGFIELD+1 THEN PEN := PEN+EQTB[5268].INT;
        IF CURLINE+2=BESTLINE THEN PEN := PEN+FINALWIDOWPE;
        IF DISCBREAK THEN PEN := PEN+EQTB[5271].INT;
        IF PEN<>0 THEN
          BEGIN
            R := NEWPENALTY(PEN);
            MEM[CURLIST.TAILFIELD].HH.RH := R;
            CURLIST.TAILFIELD := R;
          END;
      END{:890}{:880};
    CURLINE := CURLINE+1;
    CURP := MEM[CURP+1].HH.LH;
    IF CURP<>0 THEN
      IF NOT POSTDISCBREA THEN{879:}
        BEGIN
          R := 29997;
          WHILE TRUE DO
            BEGIN
              Q := MEM[R].HH.RH;
              IF Q=MEM[CURP+1].HH.RH THEN GOTO 31;
              IF (Q>=HIMEMMIN)THEN GOTO 31;
              IF (MEM[Q].HH.B0<9)THEN GOTO 31;
              IF MEM[Q].HH.B0=11 THEN
                IF MEM[Q].HH.B1<>1 THEN GOTO 31;
              R := Q;
            END;
          31:
              IF R<>29997 THEN
                BEGIN
                  MEM[R].HH.RH := 0;
                  FLUSHNODELIS(MEM[29997].HH.RH);
                  MEM[29997].HH.RH := Q;
                END;
        END{:879};
  UNTIL CURP=0;
  IF (CURLINE<>BESTLINE)OR(MEM[29997].HH.RH<>0)THEN confusion_str('line breaking');
  CURLIST.PGFIELD := BESTLINE-1;
END;
{:877}{895:}{906:}
FUNCTION RECONSTITUTE(J,N:SMALLNUMBER;
                      BCHAR,HCHAR:HALFWORD): SMALLNUMBER;

LABEL 22,30;

VAR P: HALFWORD;
  T: HALFWORD;
  Q: FOURQUARTERS;
  CURRH: HALFWORD;
  TESTCHAR: HALFWORD;
  W: SCALED;
  K: FONTINDEX;
BEGIN
  HYPHENPASSED := 0;
  T := 29996;
  W := 0;
  MEM[29996].HH.RH := 0;
{908:}
  CURL := HU[J]+0;
  CURQ := T;
  IF J=0 THEN
    BEGIN
      LIGATUREPRES := INITLIG;
      P := INITLIST;
      IF LIGATUREPRES THEN LFTHIT := INITLFT;
      WHILE P>0 DO
        BEGIN
          BEGIN
            MEM[T].HH.RH := GETAVAIL;
            T := MEM[T].HH.RH;
            MEM[T].HH.B0 := HF;
            MEM[T].HH.B1 := MEM[P].HH.B1;
          END;
          P := MEM[P].HH.RH;
        END;
    END
  ELSE
    IF CURL<256 THEN
      BEGIN
        MEM[T].HH.RH := GETAVAIL;
        T := MEM[T].HH.RH;
        MEM[T].HH.B0 := HF;
        MEM[T].HH.B1 := CURL;
      END;
  LIGSTACK := 0;
  BEGIN
    IF J<N THEN CURR := HU[J+1]+0
    ELSE CURR := BCHAR;
    IF ODD(HYF[J])THEN CURRH := HCHAR
    ELSE CURRH := 256;
  END{:908};
  22:{909:}
      IF CURL=256 THEN
        BEGIN
          K := BCHARLABEL[HF];
          IF K=0 THEN GOTO 30
          ELSE Q := FONTINFO[K].QQQQ;
        END
      ELSE
        BEGIN
          Q := FONTINFO[CHARBASE[HF]+CURL].QQQQ;
          IF ((Q.B2-0)MOD 4)<>1 THEN GOTO 30;
          K := LIGKERNBASE[HF]+Q.B3;
          Q := FONTINFO[K].QQQQ;
          IF Q.B0>128 THEN
            BEGIN
              K := LIGKERNBASE[HF]+256*Q.B2+Q.B3+32768-256*(128);
              Q := FONTINFO[K].QQQQ;
            END;
        END;
  IF CURRH<256 THEN TESTCHAR := CURRH
  ELSE TESTCHAR := CURR;
  WHILE TRUE DO
    BEGIN
      IF Q.B1=TESTCHAR THEN
        IF Q.B0<=128 THEN
          IF CURRH<256
            THEN
            BEGIN
              HYPHENPASSED := J;
              HCHAR := 256;
              CURRH := 256;
              GOTO 22;
            END
      ELSE
        BEGIN
          IF HCHAR<256 THEN
            IF ODD(HYF[J])THEN
              BEGIN
                HYPHENPASSED := 
                                J;
                HCHAR := 256;
              END;
          IF Q.B2<128 THEN{911:}
            BEGIN
              IF CURL=256 THEN LFTHIT := TRUE;
              IF J=N THEN
                IF LIGSTACK=0 THEN RTHIT := TRUE;
              BEGIN
                IF INTERRUPT<>0 THEN PAUSEFORINST;
              END;
              CASE Q.B2 OF 
                1,5:
                     BEGIN
                       CURL := Q.B3;
                       LIGATUREPRES := TRUE;
                     END;
                2,6:
                     BEGIN
                       CURR := Q.B3;
                       IF LIGSTACK>0 THEN MEM[LIGSTACK].HH.B1 := CURR
                       ELSE
                         BEGIN
                           LIGSTACK := 
                                       NEWLIGITEM(CURR);
                           IF J=N THEN BCHAR := 256
                           ELSE
                             BEGIN
                               P := GETAVAIL;
                               MEM[LIGSTACK+1].HH.RH := P;
                               MEM[P].HH.B1 := HU[J+1]+0;
                               MEM[P].HH.B0 := HF;
                             END;
                         END;
                     END;
                3:
                   BEGIN
                     CURR := Q.B3;
                     P := LIGSTACK;
                     LIGSTACK := NEWLIGITEM(CURR);
                     MEM[LIGSTACK].HH.RH := P;
                   END;
                7,11:
                      BEGIN
                        IF LIGATUREPRES THEN
                          BEGIN
                            P := NEWLIGATURE(HF,CURL,MEM[CURQ].
                                 HH.RH);
                            IF LFTHIT THEN
                              BEGIN
                                MEM[P].HH.B1 := 2;
                                LFTHIT := FALSE;
                              END;
                            IF FALSE THEN
                              IF LIGSTACK=0 THEN
                                BEGIN
                                  MEM[P].HH.B1 := MEM[P].HH.B1+1;
                                  RTHIT := FALSE;
                                END;
                            MEM[CURQ].HH.RH := P;
                            T := P;
                            LIGATUREPRES := FALSE;
                          END;
                        CURQ := T;
                        CURL := Q.B3;
                        LIGATUREPRES := TRUE;
                      END;
                ELSE
                  BEGIN
                    CURL := Q.B3;
                    LIGATUREPRES := TRUE;
                    IF LIGSTACK>0 THEN
                      BEGIN
                        IF MEM[LIGSTACK+1].HH.RH>0 THEN
                          BEGIN
                            MEM[T].HH
                            .RH := MEM[LIGSTACK+1].HH.RH;
                            T := MEM[T].HH.RH;
                            J := J+1;
                          END;
                        P := LIGSTACK;
                        LIGSTACK := MEM[P].HH.RH;
                        FREENODE(P,2);
                        IF LIGSTACK=0 THEN
                          BEGIN
                            IF J<N THEN CURR := HU[J+1]+0
                            ELSE CURR := BCHAR;
                            IF ODD(HYF[J])THEN CURRH := HCHAR
                            ELSE CURRH := 256;
                          END
                        ELSE CURR := MEM[LIGSTACK].HH.B1;
                      END
                    ELSE
                      IF J=N THEN GOTO 30
                    ELSE
                      BEGIN
                        BEGIN
                          MEM[T].HH.RH := GETAVAIL;
                          T := MEM[T].HH.RH;
                          MEM[T].HH.B0 := HF;
                          MEM[T].HH.B1 := CURR;
                        END;
                        J := J+1;
                        BEGIN
                          IF J<N THEN CURR := HU[J+1]+0
                          ELSE CURR := BCHAR;
                          IF ODD(HYF[J])THEN CURRH := HCHAR
                          ELSE CURRH := 256;
                        END;
                      END;
                  END
              END;
              IF Q.B2>4 THEN
                IF Q.B2<>7 THEN GOTO 30;
              GOTO 22;
            END{:911};
          W := FONTINFO[KERNBASE[HF]+256*Q.B2+Q.B3].INT;
          GOTO 30;
        END;
      IF Q.B0>=128 THEN
        IF CURRH=256 THEN GOTO 30
      ELSE
        BEGIN
          CURRH := 256;
          GOTO 22;
        END;
      K := K+Q.B0+1;
      Q := FONTINFO[K].QQQQ;
    END;
  30:{:909};
{910:}
  IF LIGATUREPRES THEN
    BEGIN
      P := NEWLIGATURE(HF,CURL,MEM[CURQ].HH.RH)
      ;
      IF LFTHIT THEN
        BEGIN
          MEM[P].HH.B1 := 2;
          LFTHIT := FALSE;
        END;
      IF RTHIT THEN
        IF LIGSTACK=0 THEN
          BEGIN
            MEM[P].HH.B1 := MEM[P].HH.B1+1;
            RTHIT := FALSE;
          END;
      MEM[CURQ].HH.RH := P;
      T := P;
      LIGATUREPRES := FALSE;
    END;
  IF W<>0 THEN
    BEGIN
      MEM[T].HH.RH := NEWKERN(W);
      T := MEM[T].HH.RH;
      W := 0;
    END;
  IF LIGSTACK>0 THEN
    BEGIN
      CURQ := T;
      CURL := MEM[LIGSTACK].HH.B1;
      LIGATUREPRES := TRUE;
      BEGIN
        IF MEM[LIGSTACK+1].HH.RH>0 THEN
          BEGIN
            MEM[T].HH.RH := MEM[LIGSTACK+1
                            ].HH.RH;
            T := MEM[T].HH.RH;
            J := J+1;
          END;
        P := LIGSTACK;
        LIGSTACK := MEM[P].HH.RH;
        FREENODE(P,2);
        IF LIGSTACK=0 THEN
          BEGIN
            IF J<N THEN CURR := HU[J+1]+0
            ELSE CURR := BCHAR;
            IF ODD(HYF[J])THEN CURRH := HCHAR
            ELSE CURRH := 256;
          END
        ELSE CURR := MEM[LIGSTACK].HH.B1;
      END;
      GOTO 22;
    END{:910};
  RECONSTITUTE := J;
END;{:906}
PROCEDURE HYPHENATE;

LABEL 50,30,40,41,42,45,10;

VAR {901:}I,J,L: 0..65;
  Q,R,S: HALFWORD;
  BCHAR: HALFWORD;{:901}{912:}
  MAJORTAIL,MINORTAIL: HALFWORD;
  C: ASCIICODE;
  CLOC: 0..63;
  RCOUNT: Int32;
  HYFNODE: HALFWORD;{:912}{922:}
  Z: TRIEPOINTER;
  V: Int32;{:922}{929:}
  H: HYPHPOINTER;
  K: STRNUMBER;
  U: POOLPOINTER;
{:929}
BEGIN{923:}
  FOR J:=0 TO HN DO
    HYF[J] := 0;{930:}
  H := HC[1];
  HN := HN+1;
  HC[HN] := CURLANG;
  FOR J:=2 TO HN DO
    H := (H+H+HC[J])MOD 307;
  WHILE TRUE DO
    BEGIN{931:}
      K := HYPHWORD[H];
      IF K=0 THEN GOTO 45;
      IF (STRSTART[K+1]-STRSTART[K])<HN THEN GOTO 45;
      IF (STRSTART[K+1]-STRSTART[K])=HN THEN
        BEGIN
          J := 1;
          U := STRSTART[K];
          REPEAT
            IF STRPOOL[U]<HC[J]THEN GOTO 45;
            IF STRPOOL[U]>HC[J]THEN GOTO 30;
            J := J+1;
            U := U+1;
          UNTIL J>HN;{932:}
          S := HYPHLIST[H];
          WHILE S<>0 DO
            BEGIN
              HYF[MEM[S].HH.LH] := 1;
              S := MEM[S].HH.RH;
            END{:932};
          HN := HN-1;
          GOTO 40;
        END;
      30:{:931};
      IF H>0 THEN H := H-1
      ELSE H := 307;
    END;
  45: HN := HN-1{:930};
  IF TRIE[CURLANG+1].B1<>CURLANG+0 THEN goto 10;
  HC[0] := 0;
  HC[HN+1] := 0;
  HC[HN+2] := 256;
  FOR J:=0 TO HN-RHYF+1 DO
    BEGIN
      Z := TRIE[CURLANG+1].RH+HC[J];
      L := J;
      WHILE HC[L]=TRIE[Z].B1-0 DO
        BEGIN
          IF TRIE[Z].B0<>0 THEN{924:}
            BEGIN
              V := 
                   TRIE[Z].B0;
              REPEAT
                V := V+OPSTART[CURLANG];
                I := L-HYFDISTANCE[V];
                IF HYFNUM[V]>HYF[I]THEN HYF[I] := HYFNUM[V];
                V := HYFNEXT[V];
              UNTIL V=0;
            END{:924};
          L := L+1;
          Z := TRIE[Z].RH+HC[L];
        END;
    END;
  40: FOR J:=0 TO LHYF-1 DO
        HYF[J] := 0;
  FOR J:=0 TO RHYF-1 DO
    HYF[HN-J] := 0{:923};
{902:}
  FOR J:=LHYF TO HN-RHYF DO
    IF ODD(HYF[J])THEN GOTO 41;
  goto 10;
  41:{:902};{903:}
  Q := MEM[HB].HH.RH;
  MEM[HB].HH.RH := 0;
  R := MEM[HA].HH.RH;
  MEM[HA].HH.RH := 0;
  BCHAR := HYFBCHAR;
  IF (HA>=HIMEMMIN)THEN
    IF MEM[HA].HH.B0<>HF THEN GOTO 42
  ELSE
    BEGIN
      INITLIST := HA;
      INITLIG := FALSE;
      HU[0] := MEM[HA].HH.B1-0;
    END
  ELSE
    IF MEM[HA].HH.B0=6 THEN
      IF MEM[HA+1].HH.B0<>HF THEN GOTO 42
  ELSE
    BEGIN
      INITLIST := MEM[HA+1].HH.RH;
      INITLIG := TRUE;
      INITLFT := (MEM[HA].HH.B1>1);
      HU[0] := MEM[HA+1].HH.B1-0;
      IF INITLIST=0 THEN
        IF INITLFT THEN
          BEGIN
            HU[0] := 256;
            INITLIG := FALSE;
          END;
      FREENODE(HA,2);
    END
  ELSE
    BEGIN
      IF NOT(R>=HIMEMMIN)THEN
        IF MEM[R].HH.B0=6 THEN
          IF MEM[R].
             HH.B1>1 THEN GOTO 42;
      J := 1;
      S := HA;
      INITLIST := 0;
      GOTO 50;
    END;
  S := CURP;
  WHILE MEM[S].HH.RH<>HA DO
    S := MEM[S].HH.RH;
  J := 0;
  GOTO 50;
  42: S := HA;
  J := 0;
  HU[0] := 256;
  INITLIG := FALSE;
  INITLIST := 0;
  50: FLUSHNODELIS(R);
{913:}
  REPEAT
    L := J;
    J := RECONSTITUTE(J,HN,BCHAR,HYFCHAR+0)+1;
    IF HYPHENPASSED=0 THEN
      BEGIN
        MEM[S].HH.RH := MEM[29996].HH.RH;
        WHILE MEM[S].HH.RH>0 DO
          S := MEM[S].HH.RH;
        IF ODD(HYF[J-1])THEN
          BEGIN
            L := J;
            HYPHENPASSED := J-1;
            MEM[29996].HH.RH := 0;
          END;
      END;
    IF HYPHENPASSED>0 THEN{914:}REPEAT
                                  R := GETNODE(2);
                                  MEM[R].HH.RH := MEM[29996].HH.RH;
                                  MEM[R].HH.B0 := 7;
                                  MAJORTAIL := R;
                                  RCOUNT := 0;
                                  WHILE MEM[MAJORTAIL].HH.RH>0 DO
                                    BEGIN
                                      MAJORTAIL := MEM[MAJORTAIL].HH.RH;
                                      RCOUNT := RCOUNT+1;
                                    END;
                                  I := HYPHENPASSED;
                                  HYF[I] := 0;{915:}
                                  MINORTAIL := 0;
                                  MEM[R+1].HH.LH := 0;
                                  HYFNODE := NEWCHARACTER(HF,HYFCHAR);
                                  IF HYFNODE<>0 THEN
                                    BEGIN
                                      I := I+1;
                                      C := HU[I];
                                      HU[I] := HYFCHAR;
                                      BEGIN
                                        MEM[HYFNODE].HH.RH := AVAIL;
                                        AVAIL := HYFNODE;{$IFDEF STATS}
                                        DYNUSED := DYNUSED-1;{$ENDIF}
                                      END;
                                    END;
                                  WHILE L<=I DO
                                    BEGIN
                                      L := RECONSTITUTE(L,I,FONTBCHAR[HF],256)+1;
                                      IF MEM[29996].HH.RH>0 THEN
                                        BEGIN
                                          IF MINORTAIL=0 THEN MEM[R+1].HH.LH := MEM
                                                                                [29996].HH.RH
                                          ELSE MEM[MINORTAIL].HH.RH := MEM[29996].HH.RH;
                                          MINORTAIL := MEM[29996].HH.RH;
                                          WHILE MEM[MINORTAIL].HH.RH>0 DO
                                            MINORTAIL := MEM[MINORTAIL].HH.RH;
                                        END;
                                    END;
                                  IF HYFNODE<>0 THEN
                                    BEGIN
                                      HU[I] := C;
                                      L := I;
                                      I := I-1;
                                    END{:915};
{916:}
                                  MINORTAIL := 0;
                                  MEM[R+1].HH.RH := 0;
                                  CLOC := 0;
                                  IF BCHARLABEL[HF]<>0 THEN
                                    BEGIN
                                      L := L-1;
                                      C := HU[L];
                                      CLOC := L;
                                      HU[L] := 256;
                                    END;
                                  WHILE L<J DO
                                    BEGIN
                                      REPEAT
                                        L := RECONSTITUTE(L,HN,BCHAR,256)+1;
                                        IF CLOC>0 THEN
                                          BEGIN
                                            HU[CLOC] := C;
                                            CLOC := 0;
                                          END;
                                        IF MEM[29996].HH.RH>0 THEN
                                          BEGIN
                                            IF MINORTAIL=0 THEN MEM[R+1].HH.RH := MEM
                                                                                  [29996].HH.RH
                                            ELSE MEM[MINORTAIL].HH.RH := MEM[29996].HH.RH;
                                            MINORTAIL := MEM[29996].HH.RH;
                                            WHILE MEM[MINORTAIL].HH.RH>0 DO
                                              MINORTAIL := MEM[MINORTAIL].HH.RH;
                                          END;
                                      UNTIL L>=J;
                                      WHILE L>J DO{917:}
                                        BEGIN
                                          J := RECONSTITUTE(J,HN,BCHAR,256)+1;
                                          MEM[MAJORTAIL].HH.RH := MEM[29996].HH.RH;
                                          WHILE MEM[MAJORTAIL].HH.RH>0 DO
                                            BEGIN
                                              MAJORTAIL := MEM[MAJORTAIL].HH.RH;
                                              RCOUNT := RCOUNT+1;
                                            END;
                                        END{:917};
                                    END{:916};
{918:}
                                  IF RCOUNT>127 THEN
                                    BEGIN
                                      MEM[S].HH.RH := MEM[R].HH.RH;
                                      MEM[R].HH.RH := 0;
                                      FLUSHNODELIS(R);
                                    END
                                  ELSE
                                    BEGIN
                                      MEM[S].HH.RH := R;
                                      MEM[R].HH.B1 := RCOUNT;
                                    END;
                                  S := MAJORTAIL{:918};
                                  HYPHENPASSED := J-1;
                                  MEM[29996].HH.RH := 0;
      UNTIL NOT ODD(HYF[J-1]){:914};
  UNTIL J>HN;
  MEM[S].HH.RH := Q{:913};
  FLUSHLIST(INITLIST){:903};
  10:
END;
{:895}

{942:}
{$IFDEF INITEX}
{944:}
FUNCTION NEWTRIEOP(D,N:SMALLNUMBER;
                   V:QUARTERWORD): QUARTERWORD;
VAR H: -TRIEOPSIZE..TRIEOPSIZE;
  U: QUARTERWORD;
  L: 0..TRIEOPSIZE;
BEGIN
  H := ABS(N+313*D+361*V+1009*CURLANG)MOD(TRIEOPSIZE+TRIEOPSIZE)-
       TRIEOPSIZE;
  WHILE TRUE DO
    BEGIN
      L := TRIEOPHASH[H];
      IF L=0 THEN
        BEGIN
          IF TRIEOPPTR=TRIEOPSIZE THEN overflow('pattern memory ops', TRIEOPSIZE);
          U := TRIEUSED[CURLANG];
          IF U=255 THEN overflow('pattern memory ops per language', 255);
          TRIEOPPTR := TRIEOPPTR+1;
          U := U+1;
          TRIEUSED[CURLANG] := U;
          HYFDISTANCE[TRIEOPPTR] := D;
          HYFNUM[TRIEOPPTR] := N;
          HYFNEXT[TRIEOPPTR] := V;
          TRIEOPLANG[TRIEOPPTR] := CURLANG;
          TRIEOPHASH[H] := TRIEOPPTR;
          TRIEOPVAL[TRIEOPPTR] := U;
          NEWTRIEOP := U;
          exit;
        END;
      IF (HYFDISTANCE[L]=D)AND(HYFNUM[L]=N)AND(HYFNEXT[L]=V)AND(TRIEOPLANG[L]=
         CURLANG)THEN
        BEGIN
          NEWTRIEOP := TRIEOPVAL[L];
          exit;
        END;
      IF H>-TRIEOPSIZE THEN H := H-1
      ELSE H := TRIEOPSIZE;
    END;
END;
{:944}{948:}
FUNCTION TRIENODE(P:TRIEPOINTER): TRIEPOINTER;
VAR H: TRIEPOINTER;
  Q: TRIEPOINTER;
BEGIN
  H := ABS(TRIEC[P]+1009*TRIEO[P]+2718*TRIEL[P]+3142*TRIER[P])MOD
       TRIESIZE;
  WHILE TRUE DO
    BEGIN
      Q := TRIEHASH[H];
      IF Q=0 THEN
        BEGIN
          TRIEHASH[H] := P;
          TRIENODE := P;
          exit;
        END;
      IF (TRIEC[Q]=TRIEC[P])AND(TRIEO[Q]=TRIEO[P])AND(TRIEL[Q]=TRIEL[P])AND(
         TRIER[Q]=TRIER[P])THEN
        BEGIN
          TRIENODE := Q;
          exit;
        END;
      IF H>0 THEN H := H-1
      ELSE H := TRIESIZE;
    END;
END;
{:948}{949:}
FUNCTION COMPRESSTRIE(P:TRIEPOINTER): TRIEPOINTER;
BEGIN
  IF P=0 THEN COMPRESSTRIE := 0
  ELSE
    BEGIN
      TRIEL[P] := COMPRESSTRIE(
                  TRIEL[P]);
      TRIER[P] := COMPRESSTRIE(TRIER[P]);
      COMPRESSTRIE := TRIENODE(P);
    END;
END;{:949}{953:}
PROCEDURE FIRSTFIT(P:TRIEPOINTER);

LABEL 45,40;

VAR H: TRIEPOINTER;
  Z: TRIEPOINTER;
  Q: TRIEPOINTER;
  C: ASCIICODE;
  L,R: TRIEPOINTER;
  LL: 1..256;
BEGIN
  C := TRIEC[P];
  Z := TRIEMIN[C];
  WHILE TRUE DO
    BEGIN
      H := Z-C;
{954:}
      IF TRIEMAX<H+256 THEN
        BEGIN
          IF TRIESIZE<=H+256 THEN overflow('pattern memory', TRIESIZE);
          REPEAT
            TRIEMAX := TRIEMAX+1;
            TRIETAKEN[TRIEMAX] := FALSE;
            TRIE[TRIEMAX].RH := TRIEMAX+1;
            TRIE[TRIEMAX].LH := TRIEMAX-1;
          UNTIL TRIEMAX=H+256;
        END{:954};
      IF TRIETAKEN[H]THEN GOTO 45;
{955:}
      Q := TRIER[P];
      WHILE Q>0 DO
        BEGIN
          IF TRIE[H+TRIEC[Q]].RH=0 THEN GOTO 45;
          Q := TRIER[Q];
        END;
      GOTO 40{:955};
      45: Z := TRIE[Z].RH;
    END;
  40:{956:}TRIETAKEN[H] := TRUE;
  TRIEHASH[P] := H;
  Q := P;
  REPEAT
    Z := H+TRIEC[Q];
    L := TRIE[Z].LH;
    R := TRIE[Z].RH;
    TRIE[R].LH := L;
    TRIE[L].RH := R;
    TRIE[Z].RH := 0;
    IF L<256 THEN
      BEGIN
        IF Z<256 THEN LL := Z
        ELSE LL := 256;
        REPEAT
          TRIEMIN[L] := R;
          L := L+1;
        UNTIL L=LL;
      END;
    Q := TRIER[Q];
  UNTIL Q=0{:956};
END;{:953}{957:}
PROCEDURE TRIEPACK(P:TRIEPOINTER);

VAR Q: TRIEPOINTER;
BEGIN
  REPEAT
    Q := TRIEL[P];
    IF (Q>0)AND(TRIEHASH[Q]=0)THEN
      BEGIN
        FIRSTFIT(Q);
        TRIEPACK(Q);
      END;
    P := TRIER[P];
  UNTIL P=0;
END;{:957}{959:}
PROCEDURE TRIEFIX(P:TRIEPOINTER);

VAR Q: TRIEPOINTER;
  C: ASCIICODE;
  Z: TRIEPOINTER;
BEGIN
  Z := TRIEHASH[P];
  REPEAT
    Q := TRIEL[P];
    C := TRIEC[P];
    TRIE[Z+C].RH := TRIEHASH[Q];
    TRIE[Z+C].B1 := C+0;
    TRIE[Z+C].B0 := TRIEO[P];
    IF Q>0 THEN TRIEFIX(Q);
    P := TRIER[P];
  UNTIL P=0;
END;{:959}{960:}
PROCEDURE NEWPATTERNS;

LABEL 30,31;

VAR K,L: 0..64;
  DIGITSENSED: BOOLEAN;
  V: QUARTERWORD;
  P,Q: TRIEPOINTER;
  FIRSTCHILD: BOOLEAN;
  C: ASCIICODE;
BEGIN
  IF TRIENOTREADY THEN
    BEGIN
      IF EQTB[5313].INT<=0 THEN CURLANG := 0
      ELSE
        IF EQTB[5313].INT>255 THEN CURLANG := 0
      ELSE CURLANG := EQTB[5313].INT;
      SCANLEFTBRAC;{961:}
      K := 0;
      HYF[0] := 0;
      DIGITSENSED := FALSE;
      WHILE TRUE DO
        BEGIN
          GETXTOKEN;
          CASE CURCMD OF 
            11,12:{962:}
                   IF DIGITSENSED OR(CURCHR<48)OR(CURCHR>57)THEN
                     BEGIN
                       IF CURCHR=46 THEN CURCHR := 0
                       ELSE
                         BEGIN
                           CURCHR := EQTB[4239+CURCHR].HH.RH;
                           IF CURCHR=0 THEN BEGIN
                             print_err('Nonletter');
                             help1('(See Appendix H.)');
                             ERROR;
                           END;
                         END;
                       IF K<63 THEN
                         BEGIN
                           K := K+1;
                           HC[K] := CURCHR;
                           HYF[K] := 0;
                           DIGITSENSED := FALSE;
                         END;
                     END
                   ELSE
                     IF K<63 THEN
                       BEGIN
                         HYF[K] := CURCHR-48;
                         DIGITSENSED := TRUE;
                       END{:962};
            10,2:
                  BEGIN
                    IF K>0 THEN{963:}
                      BEGIN{965:}
                        IF HC[1]=0 THEN HYF[0] := 0;
                        IF HC[K]=0 THEN HYF[K] := 0;
                        L := K;
                        V := 0;
                        WHILE TRUE DO
                          BEGIN
                            IF HYF[L]<>0 THEN V := NEWTRIEOP(K-L,HYF[L],V);
                            IF L>0 THEN L := L-1
                            ELSE GOTO 31;
                          END;
                        31:{:965};
                        Q := 0;
                        HC[0] := CURLANG;
                        WHILE L<=K DO
                          BEGIN
                            C := HC[L];
                            L := L+1;
                            P := TRIEL[Q];
                            FIRSTCHILD := TRUE;
                            WHILE (P>0)AND(C>TRIEC[P]) DO
                              BEGIN
                                Q := P;
                                P := TRIER[Q];
                                FIRSTCHILD := FALSE;
                              END;
                            IF (P=0)OR(C<TRIEC[P])THEN{964:}
                              BEGIN
                                IF TRIEPTR=TRIESIZE THEN overflow('pattern memory', TRIESIZE);
                                TRIEPTR := TRIEPTR+1;
                                TRIER[TRIEPTR] := P;
                                P := TRIEPTR;
                                TRIEL[P] := 0;
                                IF FIRSTCHILD THEN TRIEL[Q] := P
                                ELSE TRIER[Q] := P;
                                TRIEC[P] := C;
                                TRIEO[P] := 0;
                              END{:964};
                            Q := P;
                          END;
                        IF TRIEO[Q]<>0 THEN BEGIN
                          print_err('Duplicate pattern');
                          help1('(See Appendix H.)');
                          ERROR;
                        END;
                        TRIEO[Q] := V;
                      END{:963};
                    IF CURCMD=2 THEN GOTO 30;
                    K := 0;
                    HYF[0] := 0;
                    DIGITSENSED := FALSE;
                  END;
            ELSE BEGIN
              print_err('Bad ' + print_esc('patterns'));
              help1('(See Appendix H.)');
              ERROR;
            END
          END;
        END;
      30:{:961};
    END
  ELSE BEGIN
    print_err('Too late for ' + print_esc('patterns'));
    help1('All patterns must be given before typesetting begins.');
    ERROR;
    MEM[29988].HH.RH := SCANTOKS(FALSE,FALSE);
    FLUSHLIST(DEFREF);
  END;
END;
{:960}


{966:}
PROCEDURE INITTRIE;

VAR P: TRIEPOINTER;
  J,K,T: Int32;
  R,S: TRIEPOINTER;
  H: TWOHALVES;
BEGIN{952:}{945:}
  OPSTART[0] := -0;
  FOR J:=1 TO 255 DO
    OPSTART[J] := OPSTART[J-1]+TRIEUSED[J-1]-0;
  FOR J:=1 TO TRIEOPPTR DO
    TRIEOPHASH[J] := OPSTART[TRIEOPLANG[J]]+TRIEOPVAL
                     [J];
  FOR J:=1 TO TRIEOPPTR DO
    WHILE TRIEOPHASH[J]>J DO
      BEGIN
        K := TRIEOPHASH[J]
        ;
        T := HYFDISTANCE[K];
        HYFDISTANCE[K] := HYFDISTANCE[J];
        HYFDISTANCE[J] := T;
        T := HYFNUM[K];
        HYFNUM[K] := HYFNUM[J];
        HYFNUM[J] := T;
        T := HYFNEXT[K];
        HYFNEXT[K] := HYFNEXT[J];
        HYFNEXT[J] := T;
        TRIEOPHASH[J] := TRIEOPHASH[K];
        TRIEOPHASH[K] := K;
      END{:945};
  FOR P:=0 TO TRIESIZE DO
    TRIEHASH[P] := 0;
  TRIEL[0] := COMPRESSTRIE(TRIEL[0]);
  FOR P:=0 TO TRIEPTR DO
    TRIEHASH[P] := 0;
  FOR P:=0 TO 255 DO
    TRIEMIN[P] := P+1;
  TRIE[0].RH := 1;
  TRIEMAX := 0{:952};
  IF TRIEL[0]<>0 THEN
    BEGIN
      FIRSTFIT(TRIEL[0]);
      TRIEPACK(TRIEL[0]);
    END;
{958:}
  H.RH := 0;
  H.B0 := 0;
  H.B1 := 0;
  IF TRIEL[0]=0 THEN
    BEGIN
      FOR R:=0 TO 256 DO
        TRIE[R] := H;
      TRIEMAX := 256;
    END
  ELSE
    BEGIN
      TRIEFIX(TRIEL[0]);
      R := 0;
      REPEAT
        S := TRIE[R].RH;
        TRIE[R] := H;
        R := S;
      UNTIL R>TRIEMAX;
    END;
  TRIE[0].B1 := 63;{:958};
  TRIENOTREADY := FALSE;
END;
{:966}
{$ENDIF}
{:942}


PROCEDURE LINEBREAK(FINALWIDOWPE:Int32);

LABEL 30,31,32,33,34,35,22;

VAR {862:}AUTOBREAKING: BOOLEAN;
  PREVP: HALFWORD;
  Q,R,S,PREVS: HALFWORD;
  F: INTERNALFONT;{:862}{893:}
  J: SMALLNUMBER;
  C: 0..255;
{:893}
BEGIN
  PACKBEGINLIN := CURLIST.MLFIELD;
{816:}
  MEM[29997].HH.RH := MEM[CURLIST.HEADFIELD].HH.RH;
  IF (CURLIST.TAILFIELD>=HIMEMMIN)THEN
    BEGIN
      MEM[CURLIST.TAILFIELD].HH.RH := 
                                      NEWPENALTY(10000);
      CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
    END
  ELSE
    IF MEM[CURLIST.TAILFIELD].HH.B0<>10 THEN
      BEGIN
        MEM[CURLIST.
        TAILFIELD].HH.RH := NEWPENALTY(10000);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END
  ELSE
    BEGIN
      MEM[CURLIST.TAILFIELD].HH.B0 := 12;
      DELETEGLUERE(MEM[CURLIST.TAILFIELD+1].HH.LH);
      FLUSHNODELIS(MEM[CURLIST.TAILFIELD+1].HH.RH);
      MEM[CURLIST.TAILFIELD+1].INT := 10000;
    END;
  MEM[CURLIST.TAILFIELD].HH.RH := NEWPARAMGLUE(14);
  INITCURLANG := CURLIST.PGFIELD MOD 65536;
  INITLHYF := CURLIST.PGFIELD DIV 4194304;
  INITRHYF := (CURLIST.PGFIELD DIV 65536)MOD 64;
  POPNEST;
{:816}{827:}
  NOSHRINKERRO := TRUE;
  IF (MEM[EQTB[2889].HH.RH].HH.B1<>0)AND(MEM[EQTB[2889].HH.RH+3].INT<>0)
    THEN
    BEGIN
      EQTB[2889].HH.RH := FINITESHRINK(EQTB[2889].HH.RH);
    END;
  IF (MEM[EQTB[2890].HH.RH].HH.B1<>0)AND(MEM[EQTB[2890].HH.RH+3].INT<>0)
    THEN
    BEGIN
      EQTB[2890].HH.RH := FINITESHRINK(EQTB[2890].HH.RH);
    END;
  Q := EQTB[2889].HH.RH;
  R := EQTB[2890].HH.RH;
  BACKGROUND[1] := MEM[Q+1].INT+MEM[R+1].INT;
  BACKGROUND[2] := 0;
  BACKGROUND[3] := 0;
  BACKGROUND[4] := 0;
  BACKGROUND[5] := 0;
  BACKGROUND[2+MEM[Q].HH.B0] := MEM[Q+2].INT;
  BACKGROUND[2+MEM[R].HH.B0] := BACKGROUND[2+MEM[R].HH.B0]+MEM[R+2].INT;
  BACKGROUND[6] := MEM[Q+3].INT+MEM[R+3].INT;
{:827}{834:}
  MINIMUMDEMER := 1073741823;
  MINIMALDEMER[3] := 1073741823;
  MINIMALDEMER[2] := 1073741823;
  MINIMALDEMER[1] := 1073741823;
  MINIMALDEMER[0] := 1073741823;
{:834}{848:}
  IF EQTB[3412].HH.RH=0 THEN
    IF EQTB[5847].INT=0 THEN
      BEGIN
        LASTSPECIALL := 0;
        SECONDWIDTH := EQTB[5833].INT;
        SECONDINDENT := 0;
      END
  ELSE{849:}
    BEGIN
      LASTSPECIALL := ABS(EQTB[5304].INT);
      IF EQTB[5304].INT<0 THEN
        BEGIN
          FIRSTWIDTH := EQTB[5833].INT-ABS(EQTB[5847]
                        .INT);
          IF EQTB[5847].INT>=0 THEN FIRSTINDENT := EQTB[5847].INT
          ELSE FIRSTINDENT := 
                              0;
          SECONDWIDTH := EQTB[5833].INT;
          SECONDINDENT := 0;
        END
      ELSE
        BEGIN
          FIRSTWIDTH := EQTB[5833].INT;
          FIRSTINDENT := 0;
          SECONDWIDTH := EQTB[5833].INT-ABS(EQTB[5847].INT);
          IF EQTB[5847].INT>=0 THEN SECONDINDENT := EQTB[5847].INT
          ELSE SECONDINDENT 
            := 0;
        END;
    END{:849}
  ELSE
    BEGIN
      LASTSPECIALL := MEM[EQTB[3412].HH.RH].HH.LH-1;
      SECONDWIDTH := MEM[EQTB[3412].HH.RH+2*(LASTSPECIALL+1)].INT;
      SECONDINDENT := MEM[EQTB[3412].HH.RH+2*LASTSPECIALL+1].INT;
    END;
  IF EQTB[5282].INT=0 THEN EASYLINE := LASTSPECIALL
  ELSE EASYLINE := 65535
{:848};{863:}
  THRESHOLD := EQTB[5263].INT;
  IF THRESHOLD>=0 THEN
    BEGIN{$IFDEF STATS}
      IF EQTB[5295].INT>0 THEN
        BEGIN
          BEGINDIAGNOS;
          print_nl_str('@firstpass');
        END;{$ENDIF}
      SECONDPASS := FALSE;
      FINALPASS := FALSE;
    END
  ELSE
    BEGIN
      THRESHOLD := EQTB[5264].INT;
      SECONDPASS := TRUE;
      FINALPASS := (EQTB[5850].INT<=0);{$IFDEF STATS}
      IF EQTB[5295].INT>0 THEN BEGINDIAGNOS;{$ENDIF}
    END;
  WHILE TRUE DO
    BEGIN
      IF THRESHOLD>10000 THEN THRESHOLD := 10000;
      IF SECONDPASS THEN{891:}
        BEGIN{$IFDEF INITEX}
          IF TRIENOTREADY THEN INITTRIE;{$ENDIF}
          CURLANG := INITCURLANG;
          LHYF := INITLHYF;
          RHYF := INITRHYF;
        END{:891};{864:}
      Q := GETNODE(3);
      MEM[Q].HH.B0 := 0;
      MEM[Q].HH.B1 := 2;
      MEM[Q].HH.RH := 29993;
      MEM[Q+1].HH.RH := 0;
      MEM[Q+1].HH.LH := CURLIST.PGFIELD+1;
      MEM[Q+2].INT := 0;
      MEM[29993].HH.RH := Q;
      ACTIVEWIDTH[1] := BACKGROUND[1];
      ACTIVEWIDTH[2] := BACKGROUND[2];
      ACTIVEWIDTH[3] := BACKGROUND[3];
      ACTIVEWIDTH[4] := BACKGROUND[4];
      ACTIVEWIDTH[5] := BACKGROUND[5];
      ACTIVEWIDTH[6] := BACKGROUND[6];
      PASSIVE := 0;
      PRINTEDNODE := 29997;
      PASSNUMBER := 0;
      FONTINSHORTD := 0{:864};
      CURP := MEM[29997].HH.RH;
      AUTOBREAKING := TRUE;
      PREVP := CURP;
      WHILE (CURP<>0)AND(MEM[29993].HH.RH<>29993) DO{866:}
        BEGIN
          IF (CURP>=
             HIMEMMIN)THEN{867:}
            BEGIN
              PREVP := CURP;
              REPEAT
                F := MEM[CURP].HH.B0;
                ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+FONTINFO[WIDTHBASE[F]+FONTINFO[CHARBASE[F
                                  ]+MEM[CURP].HH.B1].QQQQ.B0].INT;
                CURP := MEM[CURP].HH.RH;
              UNTIL NOT(CURP>=HIMEMMIN);
            END{:867};
          CASE MEM[CURP].HH.B0 OF 
            0,1,2: ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+MEM[CURP+1]
                                     .INT;
            8:{1362:}
               IF MEM[CURP].HH.B1=4 THEN
                 BEGIN
                   CURLANG := MEM[CURP+1].HH.RH;
                   LHYF := MEM[CURP+1].HH.B0;
                   RHYF := MEM[CURP+1].HH.B1;
                 END{:1362};
            10:
                BEGIN{868:}
                  IF AUTOBREAKING THEN
                    BEGIN
                      IF (PREVP>=HIMEMMIN)THEN
                        TRYBREAK(0,0)
                      ELSE
                        IF (MEM[PREVP].HH.B0<9)THEN TRYBREAK(0,0)
                      ELSE
                        IF (MEM[
                           PREVP].HH.B0=11)AND(MEM[PREVP].HH.B1<>1)THEN TRYBREAK(0,0);
                    END;
                  IF (MEM[MEM[CURP+1].HH.LH].HH.B1<>0)AND(MEM[MEM[CURP+1].HH.LH+3].INT<>0)
                    THEN
                    BEGIN
                      MEM[CURP+1].HH.LH := FINITESHRINK(MEM[CURP+1].HH.LH);
                    END;
                  Q := MEM[CURP+1].HH.LH;
                  ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+MEM[Q+1].INT;
                  ACTIVEWIDTH[2+MEM[Q].HH.B0] := ACTIVEWIDTH[2+MEM[Q].HH.B0]+MEM[Q+2].INT;
                  ACTIVEWIDTH[6] := ACTIVEWIDTH[6]+MEM[Q+3].INT{:868};
                  IF SECONDPASS AND AUTOBREAKING THEN{894:}
                    BEGIN
                      PREVS := CURP;
                      S := MEM[PREVS].HH.RH;
                      IF S<>0 THEN
                        BEGIN{896:}
                          WHILE TRUE DO
                            BEGIN
                              IF (S>=HIMEMMIN)THEN
                                BEGIN
                                  C 
                                  := MEM[S].HH.B1-0;
                                  HF := MEM[S].HH.B0;
                                END
                              ELSE
                                IF MEM[S].HH.B0=6 THEN
                                  IF MEM[S+1].HH.RH=0 THEN GOTO 22
                              ELSE
                                BEGIN
                                  Q := MEM[S+1].HH.RH;
                                  C := MEM[Q].HH.B1-0;
                                  HF := MEM[Q].HH.B0;
                                END
                              ELSE
                                IF (MEM[S].HH.B0=11)AND(MEM[S].HH.B1=0)THEN GOTO 22
                              ELSE
                                IF MEM[
                                   S].HH.B0=8 THEN
                                  BEGIN{1363:}
                                    IF MEM[S].HH.B1=4 THEN
                                      BEGIN
                                        CURLANG := MEM[S
                                                   +1].HH.RH;
                                        LHYF := MEM[S+1].HH.B0;
                                        RHYF := MEM[S+1].HH.B1;
                                      END{:1363};
                                    GOTO 22;
                                  END
                              ELSE GOTO 31;
                              IF EQTB[4239+C].HH.RH<>0 THEN
                                IF (EQTB[4239+C].HH.RH=C)OR(EQTB[5301].INT>
                                   0)THEN GOTO 32
                              ELSE GOTO 31;
                              22: PREVS := S;
                              S := MEM[PREVS].HH.RH;
                            END;
                          32: HYFCHAR := HYPHENCHAR[HF];
                          IF HYFCHAR<0 THEN GOTO 31;
                          IF HYFCHAR>255 THEN GOTO 31;
                          HA := PREVS{:896};
                          IF LHYF+RHYF>63 THEN GOTO 31;{897:}
                          HN := 0;
                          WHILE TRUE DO
                            BEGIN
                              IF (S>=HIMEMMIN)THEN
                                BEGIN
                                  IF MEM[S].HH.B0<>HF THEN
                                    GOTO 33;
                                  HYFBCHAR := MEM[S].HH.B1;
                                  C := HYFBCHAR-0;
                                  IF EQTB[4239+C].HH.RH=0 THEN GOTO 33;
                                  IF HN=63 THEN GOTO 33;
                                  HB := S;
                                  HN := HN+1;
                                  HU[HN] := C;
                                  HC[HN] := EQTB[4239+C].HH.RH;
                                  HYFBCHAR := 256;
                                END
                              ELSE
                                IF MEM[S].HH.B0=6 THEN{898:}
                                  BEGIN
                                    IF MEM[S+1].HH.B0<>HF THEN
                                      GOTO 33;
                                    J := HN;
                                    Q := MEM[S+1].HH.RH;
                                    IF Q>0 THEN HYFBCHAR := MEM[Q].HH.B1;
                                    WHILE Q>0 DO
                                      BEGIN
                                        C := MEM[Q].HH.B1-0;
                                        IF EQTB[4239+C].HH.RH=0 THEN GOTO 33;
                                        IF J=63 THEN GOTO 33;
                                        J := J+1;
                                        HU[J] := C;
                                        HC[J] := EQTB[4239+C].HH.RH;
                                        Q := MEM[Q].HH.RH;
                                      END;
                                    HB := S;
                                    HN := J;
                                    IF ODD(MEM[S].HH.B1)THEN HYFBCHAR := FONTBCHAR[HF]
                                    ELSE HYFBCHAR := 256;
                                  END{:898}
                              ELSE
                                IF (MEM[S].HH.B0=11)AND(MEM[S].HH.B1=0)THEN
                                  BEGIN
                                    HB := S;
                                    HYFBCHAR := FONTBCHAR[HF];
                                  END
                              ELSE GOTO 33;
                              S := MEM[S].HH.RH;
                            END;
                          33:{:897};
{899:}
                          IF HN<LHYF+RHYF THEN GOTO 31;
                          WHILE TRUE DO
                            BEGIN
                              IF NOT((S>=HIMEMMIN))THEN
                                CASE MEM[S].HH.B0 OF 
                                  6:;
                                  11:
                                      IF MEM[S].HH.B1<>0 THEN GOTO 34;
                                  8,10,12,3,5,4: GOTO 34;
                                  ELSE GOTO 31
                                END;
                              S := MEM[S].HH.RH;
                            END;
                          34:{:899};
                          HYPHENATE;
                        END;
                      31:
                    END{:894};
                END;
            11:
                IF MEM[CURP].HH.B1=1 THEN
                  BEGIN
                    IF NOT(MEM[CURP].HH.RH>=HIMEMMIN)AND
                       AUTOBREAKING THEN
                      IF MEM[MEM[CURP].HH.RH].HH.B0=10 THEN TRYBREAK(0,0);
                    ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+MEM[CURP+1].INT;
                  END
                ELSE ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+MEM[CURP+1].INT;
            6:
               BEGIN
                 F := MEM[CURP+1].HH.B0;
                 ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+FONTINFO[WIDTHBASE[F]+FONTINFO[CHARBASE[F
                                   ]+MEM[CURP+1].HH.B1].QQQQ.B0].INT;
               END;
            7:{869:}
               BEGIN
                 S := MEM[CURP+1].HH.LH;
                 DISCWIDTH := 0;
                 IF S=0 THEN TRYBREAK(EQTB[5267].INT,1)
                 ELSE
                   BEGIN
                     REPEAT{870:}
                       IF (S>=
                          HIMEMMIN)THEN
                         BEGIN
                           F := MEM[S].HH.B0;
                           DISCWIDTH := DISCWIDTH+FONTINFO[WIDTHBASE[F]+FONTINFO[CHARBASE[F]+MEM[S].
                                        HH.B1].QQQQ.B0].INT;
                         END
                       ELSE
                         CASE MEM[S].HH.B0 OF 
                           6:
                              BEGIN
                                F := MEM[S+1].HH.B0;
                                DISCWIDTH := DISCWIDTH+FONTINFO[WIDTHBASE[F]+FONTINFO[CHARBASE[F]+
                                             MEM[S+1]
                                             .HH.B1].QQQQ.B0].INT;
                              END;
                           0,1,2,11: DISCWIDTH := DISCWIDTH+MEM[S+1].INT;
                           ELSE confusion_str('disc3')
                         END{:870};
                       S := MEM[S].HH.RH;
                     UNTIL S=0;
                     ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+DISCWIDTH;
                     TRYBREAK(EQTB[5266].INT,1);
                     ACTIVEWIDTH[1] := ACTIVEWIDTH[1]-DISCWIDTH;
                   END;
                 R := MEM[CURP].HH.B1;
                 S := MEM[CURP].HH.RH;
                 WHILE R>0 DO
                   BEGIN{871:}
                     IF (S>=HIMEMMIN)THEN
                       BEGIN
                         F := MEM[S].HH.B0;
                         ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+FONTINFO[WIDTHBASE[F]+FONTINFO[CHARBASE[F
                                           ]+MEM[S].HH.B1].QQQQ.B0].INT;
                       END
                     ELSE
                       CASE MEM[S].HH.B0 OF 
                         6:
                            BEGIN
                              F := MEM[S+1].HH.B0;
                              ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+FONTINFO[WIDTHBASE[F]+FONTINFO[
                                                CHARBASE[F
                                                ]+MEM[S+1].HH.B1].QQQQ.B0].INT;
                            END;
                         0,1,2,11: ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+MEM[S+1].INT;
                         ELSE confusion_str('disc4')
                       END{:871};
                     R := R-1;
                     S := MEM[S].HH.RH;
                   END;
                 PREVP := CURP;
                 CURP := S;
                 GOTO 35;
               END{:869};
            9:
               BEGIN
                 AUTOBREAKING := (MEM[CURP].HH.B1=1);
                 BEGIN
                   IF NOT(MEM[CURP].HH.RH>=HIMEMMIN)AND AUTOBREAKING THEN
                     IF MEM[MEM[
                        CURP].HH.RH].HH.B0=10 THEN TRYBREAK(0,0);
                   ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+MEM[CURP+1].INT;
                 END;
               END;
            12: TRYBREAK(MEM[CURP+1].INT,0);
            4,3,5:;
            ELSE confusion_str('paragraph')
          END;
          PREVP := CURP;
          CURP := MEM[CURP].HH.RH;
          35:
        END{:866};
      IF CURP=0 THEN{873:}
        BEGIN
          TRYBREAK(-10000,1);
          IF MEM[29993].HH.RH<>29993 THEN
            BEGIN{874:}
              R := MEM[29993].HH.RH;
              FEWESTDEMERI := 1073741823;
              REPEAT
                IF MEM[R].HH.B0<>2 THEN
                  IF MEM[R+2].INT<FEWESTDEMERI THEN
                    BEGIN
                      FEWESTDEMERI := MEM[R+2].INT;
                      BESTBET := R;
                    END;
                R := MEM[R].HH.RH;
              UNTIL R=29993;
              BESTLINE := MEM[BESTBET+1].HH.LH{:874};
              IF EQTB[5282].INT=0 THEN GOTO 30;
{875:}
              BEGIN
                R := MEM[29993].HH.RH;
                ACTUALLOOSEN := 0;
                REPEAT
                  IF MEM[R].HH.B0<>2 THEN
                    BEGIN
                      LINEDIFF := MEM[R+1].HH.LH-BESTLINE;
                      IF ((LINEDIFF<ACTUALLOOSEN)AND(EQTB[5282].INT<=LINEDIFF))OR((LINEDIFF>
                         ACTUALLOOSEN)AND(EQTB[5282].INT>=LINEDIFF))THEN
                        BEGIN
                          BESTBET := R;
                          ACTUALLOOSEN := LINEDIFF;
                          FEWESTDEMERI := MEM[R+2].INT;
                        END
                      ELSE
                        IF (LINEDIFF=ACTUALLOOSEN)AND(MEM[R+2].INT<FEWESTDEMERI)THEN
                          BEGIN
                            BESTBET := R;
                            FEWESTDEMERI := MEM[R+2].INT;
                          END;
                    END;
                  R := MEM[R].HH.RH;
                UNTIL R=29993;
                BESTLINE := MEM[BESTBET+1].HH.LH;
              END{:875};
              IF (ACTUALLOOSEN=EQTB[5282].INT)OR FINALPASS THEN GOTO 30;
            END;
        END{:873};
{865:}
      Q := MEM[29993].HH.RH;
      WHILE Q<>29993 DO
        BEGIN
          CURP := MEM[Q].HH.RH;
          IF MEM[Q].HH.B0=2 THEN FREENODE(Q,7)
          ELSE FREENODE(Q,3);
          Q := CURP;
        END;
      Q := PASSIVE;
      WHILE Q<>0 DO
        BEGIN
          CURP := MEM[Q].HH.RH;
          FREENODE(Q,2);
          Q := CURP;
        END{:865};
      IF NOT SECONDPASS THEN
        BEGIN{$IFDEF STATS}
          IF EQTB[5295].INT>0 THEN print_nl_str('@secondpass');{$ENDIF}
          THRESHOLD := EQTB[5264].INT;
          SECONDPASS := TRUE;
          FINALPASS := (EQTB[5850].INT<=0);
        END
      ELSE
        BEGIN{$IFDEF STATS}
          IF EQTB[5295].INT>0 THEN print_nl_str('@emergencypass');
{$ENDIF}
          BACKGROUND[2] := BACKGROUND[2]+EQTB[5850].INT;
          FINALPASS := TRUE;
        END;
    END;
  30:{$IFDEF STATS}
      IF EQTB[5295].INT>0 THEN
        BEGIN
          ENDDIAGNOSTI(TRUE);
          NORMALIZESEL;
        END;{$ENDIF}{:863};{876:}
  POSTLINEBREA(FINALWIDOWPE){:876};
{865:}
  Q := MEM[29993].HH.RH;
  WHILE Q<>29993 DO
    BEGIN
      CURP := MEM[Q].HH.RH;
      IF MEM[Q].HH.B0=2 THEN FREENODE(Q,7)
      ELSE FREENODE(Q,3);
      Q := CURP;
    END;
  Q := PASSIVE;
  WHILE Q<>0 DO
    BEGIN
      CURP := MEM[Q].HH.RH;
      FREENODE(Q,2);
      Q := CURP;
    END{:865};
  PACKBEGINLIN := 0;
END;{:815}{934:}
PROCEDURE NEWHYPHEXCEP;

LABEL 21,40,45;

VAR N: 0..64;
  J: 0..64;
  H: HYPHPOINTER;
  K: STRNUMBER;
  P: HALFWORD;
  Q: HALFWORD;
  S,T: STRNUMBER;
  U,V: POOLPOINTER;
BEGIN
  SCANLEFTBRAC;
  IF EQTB[5313].INT<=0 THEN CURLANG := 0
  ELSE
    IF EQTB[5313].INT>255 THEN
      CURLANG := 0
  ELSE CURLANG := EQTB[5313].INT;{935:}
  N := 0;
  P := 0;
  WHILE TRUE DO
    BEGIN
      GETXTOKEN;
      21:
          CASE CURCMD OF 
            11,12,68:{937:}
                      IF CURCHR=45 THEN{938:}
                        BEGIN
                          IF N<63
                            THEN
                            BEGIN
                              Q := GETAVAIL;
                              MEM[Q].HH.RH := P;
                              MEM[Q].HH.LH := N;
                              P := Q;
                            END;
                        END{:938}
                      ELSE
                        BEGIN
                          IF EQTB[4239+CURCHR].HH.RH=0 THEN
                            BEGIN
                              print_err('Not a letter');
                              help2('Letters in \hyphenation words must have \lccode>0.',
                                    'Proceed; I''ll ignore the character I just read.');
                              ERROR;
                            END
                          ELSE
                            IF N<63 THEN
                              BEGIN
                                N := N+1;
                                HC[N] := EQTB[4239+CURCHR].HH.RH;
                              END;
                        END{:937};
            16:
                BEGIN
                  SCANCHARNUM;
                  CURCHR := CURVAL;
                  CURCMD := 68;
                  GOTO 21;
                END;
            10,2:
                  BEGIN
                    IF N>1 THEN{939:}
                      BEGIN
                        N := N+1;
                        HC[N] := CURLANG;
                        BEGIN
                          IF POOLPTR+N>POOLSIZE THEN overflow('pool size', POOLSIZE-INITPOOLPTR);
                        END;
                        H := 0;
                        FOR J:=1 TO N DO
                          BEGIN
                            H := (H+H+HC[J])MOD 307;
                            append_char(HC[J]);
                          END;
                        S := MAKESTRING;
{940:}
                        IF HYPHCOUNT=307 THEN overflow('exception dictionary', 307);
                        HYPHCOUNT := HYPHCOUNT+1;
                        WHILE HYPHWORD[H]<>0 DO
                          BEGIN{941:}
                            K := HYPHWORD[H];
                            IF (STRSTART[K+1]-STRSTART[K])<(STRSTART[S+1]-STRSTART[S])THEN GOTO 40;
                            IF (STRSTART[K+1]-STRSTART[K])>(STRSTART[S+1]-STRSTART[S])THEN GOTO 45;
                            U := STRSTART[K];
                            V := STRSTART[S];
                            REPEAT
                              IF STRPOOL[U]<STRPOOL[V]THEN GOTO 40;
                              IF STRPOOL[U]>STRPOOL[V]THEN GOTO 45;
                              U := U+1;
                              V := V+1;
                            UNTIL U=STRSTART[K+1];
                            40: Q := HYPHLIST[H];
                            HYPHLIST[H] := P;
                            P := Q;
                            T := HYPHWORD[H];
                            HYPHWORD[H] := S;
                            S := T;
                            45:{:941};
                            IF H>0 THEN H := H-1
                            ELSE H := 307;
                          END;
                        HYPHWORD[H] := S;
                        HYPHLIST[H] := P{:940};
                      END{:939};
                    IF CURCMD=2 THEN exit;
                    N := 0;
                    P := 0;
                  END;
            ELSE
              BEGIN
                {936:}
                print_err('Improper ' + print_esc('hyphenation') + ' will be flushed');
                help2('Hyphenation exceptions must contain only letters',
                      'and hyphens. But continue; I''ll forgive and forget.');
                ERROR;
                {:936}
              END
          END;
    END{:935};
END;
{:934}{968:}
FUNCTION PRUNEPAGETOP(P:HALFWORD): HALFWORD;

VAR PREVP: HALFWORD;
  Q: HALFWORD;
BEGIN
  PREVP := 29997;
  MEM[29997].HH.RH := P;
  WHILE P<>0 DO
    CASE MEM[P].HH.B0 OF 
      0,1,2:{969:}
             BEGIN
               Q := NEWSKIPPARAM(10)
               ;
               MEM[PREVP].HH.RH := Q;
               MEM[Q].HH.RH := P;
               IF MEM[TEMPPTR+1].INT>MEM[P+3].INT THEN MEM[TEMPPTR+1].INT := MEM[TEMPPTR
                                                                             +1].INT-MEM[P+3].INT
               ELSE MEM[TEMPPTR+1].INT := 0;
               P := 0;
             END{:969};
      8,4,3:
             BEGIN
               PREVP := P;
               P := MEM[PREVP].HH.RH;
             END;
      10,11,12:
                BEGIN
                  Q := P;
                  P := MEM[Q].HH.RH;
                  MEM[Q].HH.RH := 0;
                  MEM[PREVP].HH.RH := P;
                  FLUSHNODELIS(Q);
                END;
      ELSE confusion_str('pruning')
    END;
  PRUNEPAGETOP := MEM[29997].HH.RH;
END;
{:968}{970:}
FUNCTION VERTBREAK(P:HALFWORD;H,D:SCALED): HALFWORD;

LABEL 30,45,90;

VAR PREVP: HALFWORD;
  Q,R: HALFWORD;
  PI: Int32;
  B: Int32;
  LEASTCOST: Int32;
  BESTPLACE: HALFWORD;
  PREVDP: SCALED;
  T: SMALLNUMBER;
BEGIN
  PREVP := P;
  LEASTCOST := 1073741823;
  ACTIVEWIDTH[1] := 0;
  ACTIVEWIDTH[2] := 0;
  ACTIVEWIDTH[3] := 0;
  ACTIVEWIDTH[4] := 0;
  ACTIVEWIDTH[5] := 0;
  ACTIVEWIDTH[6] := 0;
  PREVDP := 0;
  WHILE TRUE DO
    BEGIN{972:}
      IF P=0 THEN PI := -10000
      ELSE{973:}
        CASE MEM[P].HH
             .B0 OF 
          0,1,2:
                 BEGIN
                   ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+PREVDP+MEM[P+3].INT;
                   PREVDP := MEM[P+2].INT;
                   GOTO 45;
                 END;
          8:{1365:}GOTO 45{:1365};
          10:
              IF (MEM[PREVP].HH.B0<9)THEN PI := 0
              ELSE GOTO 90;
          11:
              BEGIN
                IF MEM[P].HH.RH=0 THEN T := 12
                ELSE T := MEM[MEM[P].HH.RH].HH.B0;
                IF T=10 THEN PI := 0
                ELSE GOTO 90;
              END;
          12: PI := MEM[P+1].INT;
          4,3: GOTO 45;
          ELSE confusion_str('vertbreak')
        END{:973};
{974:}
      IF PI<10000 THEN
        BEGIN{975:}
          IF ACTIVEWIDTH[1]<H THEN
            IF (
               ACTIVEWIDTH[3]<>0)OR(ACTIVEWIDTH[4]<>0)OR(ACTIVEWIDTH[5]<>0)THEN B := 0
          ELSE B := BADNESS(H-ACTIVEWIDTH[1],ACTIVEWIDTH[2])
          ELSE
            IF ACTIVEWIDTH[1]-H
               >ACTIVEWIDTH[6]THEN B := 1073741823
          ELSE B := BADNESS(ACTIVEWIDTH[1]-H,
                    ACTIVEWIDTH[6]){:975};
          IF B<1073741823 THEN
            IF PI<=-10000 THEN B := PI
          ELSE
            IF B<10000 THEN B := B+
                                 PI
          ELSE B := 100000;
          IF B<=LEASTCOST THEN
            BEGIN
              BESTPLACE := P;
              LEASTCOST := B;
              BESTHEIGHTPL := ACTIVEWIDTH[1]+PREVDP;
            END;
          IF (B=1073741823)OR(PI<=-10000)THEN GOTO 30;
        END{:974};
      IF (MEM[P].HH.B0<10)OR(MEM[P].HH.B0>11)THEN GOTO 45;
      90:{976:}
          IF MEM[P].HH.B0=11 THEN Q := P
          ELSE
            BEGIN
              Q := MEM[P+1].HH.LH;
              ACTIVEWIDTH[2+MEM[Q].HH.B0] := ACTIVEWIDTH[2+MEM[Q].HH.B0]+MEM[Q+2].INT;
              ACTIVEWIDTH[6] := ACTIVEWIDTH[6]+MEM[Q+3].INT;
              IF (MEM[Q].HH.B1<>0)AND(MEM[Q+3].INT<>0)THEN
                BEGIN
                  print_err('Infinite glue shrinkage found in box being split');
                  help4('The box you are \vsplitting contains some infinitely',
                        'shrinkable glue, e.g., `\vss'' or `\vskip 0pt minus 1fil''.',
                        'Such glue doesn''t belong there; but you can safely proceed,',
                        'since the offensive shrinkability has been made finite.');
                  ERROR;
                  R := NEWSPEC(Q);
                  MEM[R].HH.B1 := 0;
                  DELETEGLUERE(Q);
                  MEM[P+1].HH.LH := R;
                  Q := R;
                END;
            END;
      ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+PREVDP+MEM[Q+1].INT;
      PREVDP := 0{:976};
      45:
          IF PREVDP>D THEN
            BEGIN
              ACTIVEWIDTH[1] := ACTIVEWIDTH[1]+PREVDP-D;
              PREVDP := D;
            END;{:972};
      PREVP := P;
      P := MEM[PREVP].HH.RH;
    END;
  30: VERTBREAK := BESTPLACE;
END;


FUNCTION VSPLIT(N:EIGHTBITS; H:SCALED): HALFWORD;
VAR V: HALFWORD;
  P: HALFWORD;
  Q: HALFWORD;
BEGIN
  V := EQTB[3678+N].HH.RH;
  IF CURMARK[3]<>0 THEN BEGIN
    DELETETOKENR(CURMARK[3]);
    CURMARK[3] := 0;
    DELETETOKENR(CURMARK[4]);
    CURMARK[4] := 0;
  END;

  {978:}
  IF V=0 THEN BEGIN
    VSPLIT := 0;
    exit;
  END;
  IF MEM[V].HH.B0<>1 THEN BEGIN
    print_err(print_esc('vsplit') + ' needs a ' + print_esc('vbox'));
    help2('The box you are trying to split is an \hbox.',
          'I can''t split such a box, so I''ll leave it alone.');
    ERROR;
    VSPLIT := 0;
    exit;
  END;
  {:978}

  Q := VERTBREAK(MEM[V+5].HH.RH,H,EQTB[5836].INT);{979:}
  P := MEM[V+5].HH.RH;
  IF P=Q THEN MEM[V+5].HH.RH := 0
  ELSE WHILE TRUE DO BEGIN
    IF MEM[P].HH.B0=4 THEN
      IF CURMARK[3]=0 THEN BEGIN
        CURMARK[3] := MEM[P+1].INT;
        CURMARK[4] := CURMARK[3];
        MEM[CURMARK[3]].HH.LH := MEM[CURMARK[3]].HH.LH+2;
      END ELSE BEGIN
        DELETETOKENR(CURMARK[4]);
        CURMARK[4] := MEM[P+1].INT;
        MEM[CURMARK[4]].HH.LH := MEM[CURMARK[4]].HH.LH+1;
      END;
      IF MEM[P].HH.RH=Q THEN BEGIN
        MEM[P].HH.RH := 0;
        break;
      END;
      P := MEM[P].HH.RH;
  END;
  Q := PRUNEPAGETOP(Q);
  P := MEM[V+5].HH.RH;
  FREENODE(V,7);
  IF Q=0 THEN EQTB[3678+N].HH.RH := 0
  ELSE EQTB[3678+N].HH.RH := VPACKAGE(Q, 0, 1, 1073741823);
  VSPLIT := VPACKAGE(P,H,0,EQTB[5836].INT);
END;
{:977}

{987:}
PROCEDURE FREEZEPAGESP(S:SMALLNUMBER);
BEGIN
  PAGECONTENTS := S;
  PAGESOFAR[0] := EQTB[5834].INT;
  PAGEMAXDEPTH := EQTB[5835].INT;
  PAGESOFAR[7] := 0;
  PAGESOFAR[1] := 0;
  PAGESOFAR[2] := 0;
  PAGESOFAR[3] := 0;
  PAGESOFAR[4] := 0;
  PAGESOFAR[5] := 0;
  PAGESOFAR[6] := 0;
  LEASTPAGECOS := 1073741823;

{$IFDEF STATS}
  IF EQTB[5296].INT>0 THEN BEGIN
    BEGINDIAGNOS;
    print_nl_str('%% goal height=' + print_scaled(PAGESOFAR[0])
                  + ', max depth=' + print_scaled(PAGEMAXDEPTH));
    ENDDIAGNOSTI(FALSE);
  END;
{$ENDIF}
END;
{:987}

{992:}
PROCEDURE BOXERROR(N:EIGHTBITS);
BEGIN
  ERROR;
  BEGINDIAGNOS;
  print_nl_str('The following box has been deleted:');
  SHOWBOX(EQTB[3678+N].HH.RH);
  ENDDIAGNOSTI(TRUE);
  FLUSHNODELIS(EQTB[3678+N].HH.RH);
  EQTB[3678+N].HH.RH := 0;
END;


PROCEDURE ENSUREVBOX(N:EIGHTBITS);
VAR P: HALFWORD;
BEGIN
  P := EQTB[3678+N].HH.RH;
  IF P<>0 THEN
    IF MEM[P].HH.B0=0 THEN BEGIN
      print_err('Insertions can only be added to a vbox');
      help3('Tut tut: You''re trying to \insert into a',
            '\box register that now contains an \hbox.',
            'Proceed, and I''ll discard its present contents.');
      BOXERROR(N);
    END;
END;


PROCEDURE FIREUP(C:HALFWORD);
VAR P,Q,R,S: HALFWORD;
  PREVP: HALFWORD;
  N: 0..255;
  WAIT: BOOLEAN;
  SAVEVBADNESS: Int32;
  SAVEVFUZZ: SCALED;
  SAVESPLITTOP: HALFWORD;
BEGIN{1013:}
  IF MEM[BESTPAGEBREA].HH.B0=12 THEN
    BEGIN
      GEQWORDDEFIN(5302,
                   MEM[BESTPAGEBREA+1].INT);
      MEM[BESTPAGEBREA+1].INT := 10000;
    END
  ELSE GEQWORDDEFIN(5302,10000){:1013};
  IF CURMARK[2]<>0 THEN
    BEGIN
      IF CURMARK[0]<>0 THEN DELETETOKENR(CURMARK[0
                                         ]);
      CURMARK[0] := CURMARK[2];
      MEM[CURMARK[0]].HH.LH := MEM[CURMARK[0]].HH.LH+1;
      DELETETOKENR(CURMARK[1]);
      CURMARK[1] := 0;
    END;{1014:}
  IF C=BESTPAGEBREA THEN BESTPAGEBREA := 0;

  {1015:}
  IF EQTB[3933].HH.RH<>0 THEN BEGIN
    print_err(print_esc('box') + '255 is not void');
    help2('You shouldn''t use \box255 except in \output routines.',
          'Proceed, and I''ll discard its present contents.');
    BOXERROR(255);
  END;
  {:1015}

  INSERTPENALT := 0;
  SAVESPLITTOP := EQTB[2892].HH.RH;
  IF EQTB[5316].INT<=0 THEN{1018:}
    BEGIN
      R := MEM[30000].HH.RH;
      WHILE R<>30000 DO
        BEGIN
          IF MEM[R+2].HH.LH<>0 THEN
            BEGIN
              N := MEM[R].HH.B1
                   -0;
              ENSUREVBOX(N);
              IF EQTB[3678+N].HH.RH=0 THEN EQTB[3678+N].HH.RH := NEWNULLBOX;
              P := EQTB[3678+N].HH.RH+5;
              WHILE MEM[P].HH.RH<>0 DO
                P := MEM[P].HH.RH;
              MEM[R+2].HH.RH := P;
            END;
          R := MEM[R].HH.RH;
        END;
    END{:1018};
  Q := 29996;
  MEM[Q].HH.RH := 0;
  PREVP := 29998;
  P := MEM[PREVP].HH.RH;
  WHILE P<>BESTPAGEBREA DO
    BEGIN
      IF MEM[P].HH.B0=3 THEN
        BEGIN
          IF EQTB[5316
             ].INT<=0 THEN{1020:}
            BEGIN
              R := MEM[30000].HH.RH;
              WHILE MEM[R].HH.B1<>MEM[P].HH.B1 DO
                R := MEM[R].HH.RH;
              IF MEM[R+2].HH.LH=0 THEN WAIT := TRUE
              ELSE
                BEGIN
                  WAIT := FALSE;
                  S := MEM[R+2].HH.RH;
                  MEM[S].HH.RH := MEM[P+4].HH.LH;
                  IF MEM[R+2].HH.LH=P THEN{1021:}
                    BEGIN
                      IF MEM[R].HH.B0=1 THEN
                        IF (MEM[R+1].
                           HH.LH=P)AND(MEM[R+1].HH.RH<>0)THEN
                          BEGIN
                            WHILE MEM[S].HH.RH<>MEM[R+1].HH
                                  .RH DO
                              S := MEM[S].HH.RH;
                            MEM[S].HH.RH := 0;
                            EQTB[2892].HH.RH := MEM[P+4].HH.RH;
                            MEM[P+4].HH.LH := PRUNEPAGETOP(MEM[R+1].HH.RH);
                            IF MEM[P+4].HH.LH<>0 THEN
                              BEGIN
                                TEMPPTR := VPACKAGE(MEM[P+4].HH.LH,0,1,
                                           1073741823);
                                MEM[P+3].INT := MEM[TEMPPTR+3].INT+MEM[TEMPPTR+2].INT;
                                FREENODE(TEMPPTR,7);
                                WAIT := TRUE;
                              END;
                          END;
                      MEM[R+2].HH.LH := 0;
                      N := MEM[R].HH.B1-0;
                      TEMPPTR := MEM[EQTB[3678+N].HH.RH+5].HH.RH;
                      FREENODE(EQTB[3678+N].HH.RH,7);
                      EQTB[3678+N].HH.RH := VPACKAGE(TEMPPTR,0,1,1073741823);
                    END{:1021}
                  ELSE
                    BEGIN
                      WHILE MEM[S].HH.RH<>0 DO
                        S := MEM[S].HH.RH;
                      MEM[R+2].HH.RH := S;
                    END;
                END;{1022:}
              MEM[PREVP].HH.RH := MEM[P].HH.RH;
              MEM[P].HH.RH := 0;
              IF WAIT THEN
                BEGIN
                  MEM[Q].HH.RH := P;
                  Q := P;
                  INSERTPENALT := INSERTPENALT+1;
                END
              ELSE
                BEGIN
                  DELETEGLUERE(MEM[P+4].HH.RH);
                  FREENODE(P,5);
                END;
              P := PREVP{:1022};
            END{:1020};
        END
      ELSE
        IF MEM[P].HH.B0=4 THEN{1016:}
          BEGIN
            IF CURMARK[1]=0 THEN
              BEGIN
                CURMARK[1] := MEM[P+1].INT;
                MEM[CURMARK[1]].HH.LH := MEM[CURMARK[1]].HH.LH+1;
              END;
            IF CURMARK[2]<>0 THEN DELETETOKENR(CURMARK[2]);
            CURMARK[2] := MEM[P+1].INT;
            MEM[CURMARK[2]].HH.LH := MEM[CURMARK[2]].HH.LH+1;
          END{:1016};
      PREVP := P;
      P := MEM[PREVP].HH.RH;
    END;
  EQTB[2892].HH.RH := SAVESPLITTOP;
{1017:}
  IF P<>0 THEN
    BEGIN
      IF MEM[29999].HH.RH=0 THEN
        IF NESTPTR=0 THEN
          CURLIST.TAILFIELD := PAGETAIL
      ELSE NEST[0].TAILFIELD := PAGETAIL;
      MEM[PAGETAIL].HH.RH := MEM[29999].HH.RH;
      MEM[29999].HH.RH := P;
      MEM[PREVP].HH.RH := 0;
    END;
  SAVEVBADNESS := EQTB[5290].INT;
  EQTB[5290].INT := 10000;
  SAVEVFUZZ := EQTB[5839].INT;
  EQTB[5839].INT := 1073741823;
  EQTB[3933].HH.RH := VPACKAGE(MEM[29998].HH.RH,BESTSIZE,0,PAGEMAXDEPTH);
  EQTB[5290].INT := SAVEVBADNESS;
  EQTB[5839].INT := SAVEVFUZZ;
  IF LASTGLUE<>65535 THEN DELETEGLUERE(LASTGLUE);{991:}
  PAGECONTENTS := 0;
  PAGETAIL := 29998;
  MEM[29998].HH.RH := 0;
  LASTGLUE := 65535;
  LASTPENALTY := 0;
  LASTKERN := 0;
  PAGESOFAR[7] := 0;
  PAGEMAXDEPTH := 0{:991};
  IF Q<>29996 THEN
    BEGIN
      MEM[29998].HH.RH := MEM[29996].HH.RH;
      PAGETAIL := Q;
    END{:1017};{1019:}
  R := MEM[30000].HH.RH;
  WHILE R<>30000 DO
    BEGIN
      Q := MEM[R].HH.RH;
      FREENODE(R,4);
      R := Q;
    END;
  MEM[30000].HH.RH := 30000{:1019}{:1014};
  IF (CURMARK[0]<>0)AND(CURMARK[1]=0)THEN
    BEGIN
      CURMARK[1] := CURMARK[0];
      MEM[CURMARK[0]].HH.LH := MEM[CURMARK[0]].HH.LH+1;
    END;
  IF EQTB[3413].HH.RH<>0 THEN
    IF DEADCYCLES>=EQTB[5303].INT THEN
      BEGIN
        {1024:}
        print_err('Output loop---' + print_int(DEADCYCLES) + ' consecutive dead cycles');
        help3('I''ve concluded that your \output is awry; it never does a',
              '\shipout, so I''m shipping \box255 out myself. Next time',
              'increase \maxdeadcycles if you want me to be more patient!');
        ERROR;
        {:1024}
      END
  ELSE{1025:}
    BEGIN
      OUTPUTACTIVE := TRUE;
      DEADCYCLES := DEADCYCLES+1;
      PUSHNEST;
      CURLIST.MODEFIELD := -1;
      CURLIST.AUXFIELD.INT := -65536000;
      CURLIST.MLFIELD := -LINE;
      BEGINTOKENLI(EQTB[3413].HH.RH,6);
      NEWSAVELEVEL(8);
      NORMALPARAGR;
      SCANLEFTBRAC;
      exit;
    END{:1025};
{1023:}
  BEGIN
    IF MEM[29998].HH.RH<>0 THEN
      BEGIN
        IF MEM[29999].HH.RH=0
          THEN
          IF NESTPTR=0 THEN CURLIST.TAILFIELD := PAGETAIL
        ELSE NEST[0].
          TAILFIELD := PAGETAIL
        ELSE MEM[PAGETAIL].HH.RH := MEM[29999].HH.RH;
        MEM[29999].HH.RH := MEM[29998].HH.RH;
        MEM[29998].HH.RH := 0;
        PAGETAIL := 29998;
      END;
    SHIPOUT(EQTB[3933].HH.RH);
    EQTB[3933].HH.RH := 0;
  END{:1023};
END;
{:1012}
PROCEDURE BUILDPAGE;

LABEL 30,31,22,80,90;

VAR P: HALFWORD;
  Q,R: HALFWORD;
  B,C: Int32;
  PI: Int32;
  N: 0..255;
  DELTA,H,W: SCALED;
BEGIN
  IF (MEM[29999].HH.RH=0)OR OUTPUTACTIVE THEN exit;
  REPEAT
    22: P := MEM[29999].HH.RH;
{996:}
    IF LASTGLUE<>65535 THEN DELETEGLUERE(LASTGLUE);
    LASTPENALTY := 0;
    LASTKERN := 0;
    IF MEM[P].HH.B0=10 THEN
      BEGIN
        LASTGLUE := MEM[P+1].HH.LH;
        MEM[LASTGLUE].HH.RH := MEM[LASTGLUE].HH.RH+1;
      END
    ELSE
      BEGIN
        LASTGLUE := 65535;
        IF MEM[P].HH.B0=12 THEN LASTPENALTY := MEM[P+1].INT
        ELSE
          IF MEM[P].HH.B0=
             11 THEN LASTKERN := MEM[P+1].INT;
      END{:996};
{997:}{1000:}
    CASE MEM[P].HH.B0 OF 
      0,1,2:
             IF PAGECONTENTS<2 THEN{1001:}
               BEGIN
                 IF PAGECONTENTS=0 THEN FREEZEPAGESP(2)
                 ELSE PAGECONTENTS := 2;
                 Q := NEWSKIPPARAM(9);
                 IF MEM[TEMPPTR+1].INT>MEM[P+3].INT THEN MEM[TEMPPTR+1].INT := MEM[TEMPPTR
                                                                               +1].INT-MEM[P+3].INT
                 ELSE MEM[TEMPPTR+1].INT := 0;
                 MEM[Q].HH.RH := P;
                 MEM[29999].HH.RH := Q;
                 GOTO 22;
               END{:1001}
             ELSE{1002:}
               BEGIN
                 PAGESOFAR[1] := PAGESOFAR[1]+PAGESOFAR[7]+MEM[P
                                 +3].INT;
                 PAGESOFAR[7] := MEM[P+2].INT;
                 GOTO 80;
               END{:1002};
      8:{1364:}GOTO 80{:1364};
      10:
          IF PAGECONTENTS<2 THEN GOTO 31
          ELSE
            IF (MEM[PAGETAIL].HH.B0<9)THEN PI 
              := 0
          ELSE GOTO 90;
      11:
          IF PAGECONTENTS<2 THEN GOTO 31
          ELSE
            IF MEM[P].HH.RH=0 THEN exit
          ELSE
            IF MEM[MEM[P].HH.RH].HH.B0=10 THEN PI := 0
          ELSE GOTO 90;
      12:
          IF PAGECONTENTS<2 THEN GOTO 31
          ELSE PI := MEM[P+1].INT;
      4: GOTO 80;
      3:{1008:}
         BEGIN
           IF PAGECONTENTS=0 THEN FREEZEPAGESP(1);
           N := MEM[P].HH.B1;
           R := 30000;
           WHILE N>=MEM[MEM[R].HH.RH].HH.B1 DO
             R := MEM[R].HH.RH;
           N := N-0;
           IF MEM[R].HH.B1<>N+0 THEN{1009:}
             BEGIN
               Q := GETNODE(4);
               MEM[Q].HH.RH := MEM[R].HH.RH;
               MEM[R].HH.RH := Q;
               R := Q;
               MEM[R].HH.B1 := N+0;
               MEM[R].HH.B0 := 0;
               ENSUREVBOX(N);
               IF EQTB[3678+N].HH.RH=0 THEN MEM[R+3].INT := 0
               ELSE MEM[R+3].INT := MEM[EQTB
                                    [3678+N].HH.RH+3].INT+MEM[EQTB[3678+N].HH.RH+2].INT;
               MEM[R+2].HH.LH := 0;
               Q := EQTB[2900+N].HH.RH;
               IF EQTB[5318+N].INT=1000 THEN H := MEM[R+3].INT
               ELSE H := XOVERN(MEM[R+3].
                         INT,1000)*EQTB[5318+N].INT;
               PAGESOFAR[0] := PAGESOFAR[0]-H-MEM[Q+1].INT;
               PAGESOFAR[2+MEM[Q].HH.B0] := PAGESOFAR[2+MEM[Q].HH.B0]+MEM[Q+2].INT;
               PAGESOFAR[6] := PAGESOFAR[6]+MEM[Q+3].INT;
               IF (MEM[Q].HH.B1<>0)AND(MEM[Q+3].INT<>0)THEN BEGIN
                 print_err('Infinite glue shrinkage inserted from ' + 
                   print_esc('skip') + print_int(N));
                 help3('The correction glue for page breaking with insertions',
                       'must have finite shrinkability. But you may proceed,',
                       'since the offensive shrinkability has been made finite.');
                 ERROR;
               END;
             END{:1009};
           IF MEM[R].HH.B0=1 THEN INSERTPENALT := INSERTPENALT+MEM[P+1].INT
           ELSE
             BEGIN
               MEM[R+2].HH.RH := P;
               DELTA := PAGESOFAR[0]-PAGESOFAR[1]-PAGESOFAR[7]+PAGESOFAR[6];
               IF EQTB[5318+N].INT=1000 THEN H := MEM[P+3].INT
               ELSE H := XOVERN(MEM[P+3].
                         INT,1000)*EQTB[5318+N].INT;
               IF ((H<=0)OR(H<=DELTA))AND(MEM[P+3].INT+MEM[R+3].INT<=EQTB[5851+N].INT)
                 THEN
                 BEGIN
                   PAGESOFAR[0] := PAGESOFAR[0]-H;
                   MEM[R+3].INT := MEM[R+3].INT+MEM[P+3].INT;
                 END
               ELSE{1010:}
                 BEGIN
                   IF EQTB[5318+N].INT<=0 THEN W := 1073741823
                   ELSE
                     BEGIN
                       W := PAGESOFAR[0]-PAGESOFAR[1]-PAGESOFAR[7];
                       IF EQTB[5318+N].INT<>1000 THEN W := XOVERN(W,EQTB[5318+N].INT)*1000;
                     END;
                   IF W>EQTB[5851+N].INT-MEM[R+3].INT THEN W := EQTB[5851+N].INT-MEM[R+3].INT
                   ;
                   Q := VERTBREAK(MEM[P+4].HH.LH,W,MEM[P+2].INT);
                   MEM[R+3].INT := MEM[R+3].INT+BESTHEIGHTPL;{$IFDEF STATS}
                   IF EQTB[5296].INT>0 THEN{1011:}
                     BEGIN
                       BEGINDIAGNOS;
                       print_nl_str('% split' + print_int(N) + ' to ' + print_scaled(W)
                         + ',' + print_scaled(BESTHEIGHTPL) + ' p=');
                       IF Q=0 THEN PRINTINT(-10000)
                       ELSE IF MEM[Q].HH.B0=12 THEN PRINTINT(MEM[Q+1].INT)
                       ELSE PRINTCHAR(48);
                       ENDDIAGNOSTI(FALSE);
                     END{:1011};{$ENDIF}
                   IF EQTB[5318+N].INT<>1000 THEN BESTHEIGHTPL := XOVERN(BESTHEIGHTPL,1000)*
                                                                  EQTB[5318+N].INT;
                   PAGESOFAR[0] := PAGESOFAR[0]-BESTHEIGHTPL;
                   MEM[R].HH.B0 := 1;
                   MEM[R+1].HH.RH := Q;
                   MEM[R+1].HH.LH := P;
                   IF Q=0 THEN INSERTPENALT := INSERTPENALT-10000
                   ELSE
                     IF MEM[Q].HH.B0=12
                       THEN INSERTPENALT := INSERTPENALT+MEM[Q+1].INT;
                 END{:1010};
             END;
           GOTO 80;
         END{:1008};
      ELSE confusion_str('page')
    END{:1000};
{1005:}
    IF PI<10000 THEN
      BEGIN
        {1007:}
        IF PAGESOFAR[1]<PAGESOFAR[0] THEN
          IF (PAGESOFAR[3]<>0)OR(PAGESOFAR[4]<>0)OR(PAGESOFAR[5]<>0) THEN B := 0
          ELSE B := BADNESS(PAGESOFAR[0]-PAGESOFAR[1],PAGESOFAR[2])
        ELSE IF PAGESOFAR[1]-PAGESOFAR[0]>PAGESOFAR[6] THEN B := 1073741823
        ELSE B := BADNESS(PAGESOFAR[1]-PAGESOFAR[0],PAGESOFAR[6]);
        {:1007}

        IF B<1073741823 THEN
          IF PI<=-10000 THEN C := PI
          ELSE IF B<10000 THEN C := B+PI+INSERTPENALT
          ELSE C := 100000
        ELSE C := B;
        IF INSERTPENALT>=10000 THEN C := 1073741823;{$IFDEF STATS}
        IF EQTB[5296].INT>0 THEN{1006:}
          BEGIN
            BEGINDIAGNOS;
            print_nl_str('% t=' + print_totals + ' g=' + print_scaled(PAGESOFAR[0]) + ' b=');
            IF B=1073741823 THEN PRINTCHAR(42)
            ELSE PRINTINT(B);
            print_str(' p=' + print_int(PI) + ' c=');
            IF C=1073741823 THEN PRINTCHAR(42)
            ELSE PRINTINT(C);
            IF C<=LEASTPAGECOS THEN PRINTCHAR(35);
            ENDDIAGNOSTI(FALSE);
          END{:1006};
{$ENDIF}
        IF C<=LEASTPAGECOS THEN
          BEGIN
            BESTPAGEBREA := P;
            BESTSIZE := PAGESOFAR[0];
            LEASTPAGECOS := C;
            R := MEM[30000].HH.RH;
            WHILE R<>30000 DO
              BEGIN
                MEM[R+2].HH.LH := MEM[R+2].HH.RH;
                R := MEM[R].HH.RH;
              END;
          END;
        IF (C=1073741823)OR(PI<=-10000)THEN
          BEGIN
            FIREUP(P);
            IF OUTPUTACTIVE THEN exit;
            GOTO 30;
          END;
      END{:1005};
    IF (MEM[P].HH.B0<10)OR(MEM[P].HH.B0>11)THEN GOTO 80;
    90:{1004:}
        IF MEM[P].HH.B0=11 THEN Q := P
        ELSE
          BEGIN
            Q := MEM[P+1].HH.LH;
            PAGESOFAR[2+MEM[Q].HH.B0] := PAGESOFAR[2+MEM[Q].HH.B0]+MEM[Q+2].INT;
            PAGESOFAR[6] := PAGESOFAR[6]+MEM[Q+3].INT;
            IF (MEM[Q].HH.B1<>0)AND(MEM[Q+3].INT<>0)THEN
              BEGIN
                print_err('Infinite glue shrinkage found on current page');
                help4('The page about to be output contains some infinitely',
                      'shrinkable glue, e.g., `\vss'' or `\vskip 0pt minus 1fil''.',
                      'Such glue doesn''t belong there; but you can safely proceed,',
                      'since the offensive shrinkability has been made finite.');
                ERROR;
                R := NEWSPEC(Q);
                MEM[R].HH.B1 := 0;
                DELETEGLUERE(Q);
                MEM[P+1].HH.LH := R;
                Q := R;
              END;
          END;
    PAGESOFAR[1] := PAGESOFAR[1]+PAGESOFAR[7]+MEM[Q+1].INT;
    PAGESOFAR[7] := 0{:1004};
    80:{1003:}
        IF PAGESOFAR[7]>PAGEMAXDEPTH THEN
          BEGIN
            PAGESOFAR[1] := 
                            PAGESOFAR[1]+PAGESOFAR[7]-PAGEMAXDEPTH;
            PAGESOFAR[7] := PAGEMAXDEPTH;
          END;
{:1003};{998:}
    MEM[PAGETAIL].HH.RH := P;
    PAGETAIL := P;
    MEM[29999].HH.RH := MEM[P].HH.RH;
    MEM[P].HH.RH := 0;
    GOTO 30{:998};
    31:{999:}MEM[29999].HH.RH := MEM[P].HH.RH;
    MEM[P].HH.RH := 0;
    FLUSHNODELIS(P){:999};
    30:{:997};
  UNTIL MEM[29999].HH.RH=0;
{995:}
  IF NESTPTR=0 THEN CURLIST.TAILFIELD := 29999
  ELSE NEST[0].TAILFIELD 
    := 29999{:995};
END;{:994}{1030:}{1043:}
PROCEDURE APPSPACE;

VAR Q: HALFWORD;
BEGIN
  IF (CURLIST.AUXFIELD.HH.LH>=2000)AND(EQTB[2895].HH.RH<>0)THEN Q := 
                                                                     NEWPARAMGLUE(13)
  ELSE
    BEGIN
      IF EQTB[2894].HH.RH<>0 THEN MAINP := EQTB[2894]
                                           .HH.RH
      ELSE{1042:}
        BEGIN
          MAINP := FONTGLUE[EQTB[3934].HH.RH];
          IF MAINP=0 THEN
            BEGIN
              MAINP := NEWSPEC(0);
              MAINK := PARAMBASE[EQTB[3934].HH.RH]+2;
              MEM[MAINP+1].INT := FONTINFO[MAINK].INT;
              MEM[MAINP+2].INT := FONTINFO[MAINK+1].INT;
              MEM[MAINP+3].INT := FONTINFO[MAINK+2].INT;
              FONTGLUE[EQTB[3934].HH.RH] := MAINP;
            END;
        END{:1042};
      MAINP := NEWSPEC(MAINP);
{1044:}
      IF CURLIST.AUXFIELD.HH.LH>=2000 THEN MEM[MAINP+1].INT := MEM[MAINP
                                                               +1].INT+FONTINFO[7+PARAMBASE[EQTB[
                                                               3934].HH.RH]].INT;
      MEM[MAINP+2].INT := XNOVERD(MEM[MAINP+2].INT,CURLIST.AUXFIELD.HH.LH,1000);
      MEM[MAINP+3].INT := XNOVERD(MEM[MAINP+3].INT,1000,CURLIST.AUXFIELD.HH.LH)
{:1044};
      Q := NEWGLUE(MAINP);
      MEM[MAINP].HH.RH := 0;
    END;
  MEM[CURLIST.TAILFIELD].HH.RH := Q;
  CURLIST.TAILFIELD := Q;
END;


PROCEDURE INSERTDOLLAR;
BEGIN
  BACKINPUT;
  CURTOK := 804;
  print_err('Missing $ inserted');
  help2('I''ve inserted a begin-math/end-math symbol since I think',
        'you left one out. Proceed, with fingers crossed.');
  INSERROR;
END;


PROCEDURE you_cant;
BEGIN
  print_err('You can''t use `' + print_cmd_chr(CURCMD,CURCHR) +
            ''' in ' + print_mode(CURLIST.MODEFIELD));
END;


PROCEDURE report_illegal_case;
BEGIN
  you_cant;
  help4('Sorry, but I''m not programmed to handle this case;',
        'I''ll just pretend that you didn''t ask for it.',
        'If you''re in the wrong mode, you might be able to',
        'return to the right one by typing `I}'' or `I$'' or `I\par''.');
  ERROR;
END;


FUNCTION PRIVILEGED: BOOLEAN;
BEGIN
  IF CURLIST.MODEFIELD>0 THEN PRIVILEGED := TRUE
  ELSE BEGIN
    report_illegal_case;
    PRIVILEGED := FALSE;
  END;
END;


FUNCTION ITSALLOVER: BOOLEAN;
BEGIN
  IF PRIVILEGED THEN
    BEGIN
      IF (29998=PAGETAIL)AND(CURLIST.HEADFIELD=
         CURLIST.TAILFIELD)AND(DEADCYCLES=0)THEN
        BEGIN
          ITSALLOVER := TRUE;
          exit;
        END;
      BACKINPUT;
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWNULLBOX;
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      MEM[CURLIST.TAILFIELD+1].INT := EQTB[5833].INT;
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWGLUE(8);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWPENALTY(-1073741824);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      BUILDPAGE;
    END;
  ITSALLOVER := FALSE;
END;


PROCEDURE APPENDGLUE;
VAR S: SMALLNUMBER;
BEGIN
  S := CURCHR;
  CASE S OF 
    0: CURVAL := 4;
    1: CURVAL := 8;
    2: CURVAL := 12;
    3: CURVAL := 16;
    4: SCANGLUE(2);
    5: SCANGLUE(3);
  END;
  BEGIN
    MEM[CURLIST.TAILFIELD].HH.RH := NEWGLUE(CURVAL);
    CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
  END;
  IF S>=4 THEN
    BEGIN
      MEM[CURVAL].HH.RH := MEM[CURVAL].HH.RH-1;
      IF S>4 THEN MEM[CURLIST.TAILFIELD].HH.B1 := 99;
    END;
END;
{:1060}{1061:}
PROCEDURE APPENDKERN;

VAR S: QUARTERWORD;
BEGIN
  S := CURCHR;
  SCANDIMEN(S=99,FALSE,FALSE);
  BEGIN
    MEM[CURLIST.TAILFIELD].HH.RH := NEWKERN(CURVAL);
    CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
  END;
  MEM[CURLIST.TAILFIELD].HH.B1 := S;
END;


PROCEDURE OFFSAVE;
VAR P: HALFWORD;
BEGIN
  IF CURGROUP=0 THEN BEGIN
    {1066:}
    print_err('Extra ' + print_cmd_chr(CURCMD,CURCHR));
    help1('Things are pretty mixed up, but I think the worst is over.');
    ERROR;
    {:1066}
  END ELSE BEGIN
      BACKINPUT;
      P := GETAVAIL;
      MEM[29997].HH.RH := P;
      print_err('Missing ');

      {1065:}
      CASE CURGROUP OF 
        14:
            BEGIN
              MEM[P].HH.LH := 6711;
              print_esc_str('endgroup');
            END;
        15:
            BEGIN
              MEM[P].HH.LH := 804;
              PRINTCHAR(36);
            END;
        16:
            BEGIN
              MEM[P].HH.LH := 6712;
              MEM[P].HH.RH := GETAVAIL;
              P := MEM[P].HH.RH;
              MEM[P].HH.LH := 3118;
              print_esc_str('right.');
            END;
        ELSE
          BEGIN
            MEM[P].HH.LH := 637;
            PRINTCHAR(125);
          END
      END;
      {:1065}
      print_str(' inserted');
      BEGINTOKENLI(MEM[29997].HH.RH,4);

      help5('I''ve inserted something that you may have forgotten.',
            '(See the <inserted text> above.)',
            'With luck, this will get me unwedged. But if you',
            'really didn''t forget anything, try typing `2'' now; then',
            'my insertion and my current dilemma will both disappear.');
      ERROR;
    END;
END;


PROCEDURE EXTRARIGHTBR;
BEGIN
  CASE CURGROUP OF 
    14: print_err('Extra }, or forgotten ' + print_esc('endgroup'));
    15: print_err('Extra }, or forgotten $');
    16: print_err('Extra }, or forgotten ' + print_esc('right'));
  END;
  help5('I''ve deleted a group-closing symbol because it seems to be',
        'spurious, as in `$x}$''. But perhaps the } is legitimate and',
        'you forgot something else, as in `\hbox{$x}''. In such cases',
        'the way to recover is to insert both the forgotten and the',
        'deleted material, e.g., by typing `I$}''.');
  ERROR;
  ALIGNSTATE := ALIGNSTATE+1;
END;


PROCEDURE BOXEND(BOXCONTEXT:Int32);
VAR P: HALFWORD;
BEGIN
  IF BOXCONTEXT<1073741824 THEN{1076:}
    BEGIN
      IF CURBOX<>0 THEN
        BEGIN
          MEM[CURBOX+4].INT := BOXCONTEXT;
          IF ABS(CURLIST.MODEFIELD)=1 THEN
            BEGIN
              APPENDTOVLIS(CURBOX);
              IF ADJUSTTAIL<>0 THEN
                BEGIN
                  IF 29995<>ADJUSTTAIL THEN
                    BEGIN
                      MEM[CURLIST.
                      TAILFIELD].HH.RH := MEM[29995].HH.RH;
                      CURLIST.TAILFIELD := ADJUSTTAIL;
                    END;
                  ADJUSTTAIL := 0;
                END;
              IF CURLIST.MODEFIELD>0 THEN BUILDPAGE;
            END
          ELSE
            BEGIN
              IF ABS(CURLIST.MODEFIELD)=102 THEN CURLIST.AUXFIELD.HH.LH 
                := 1000
              ELSE
                BEGIN
                  P := NEWNOAD;
                  MEM[P+1].HH.RH := 2;
                  MEM[P+1].HH.LH := CURBOX;
                  CURBOX := P;
                END;
              MEM[CURLIST.TAILFIELD].HH.RH := CURBOX;
              CURLIST.TAILFIELD := CURBOX;
            END;
        END;
    END{:1076}
  ELSE
    IF BOXCONTEXT<1073742336 THEN{1077:}
      IF BOXCONTEXT<
         1073742080 THEN EQDEFINE(-1073738146+BOXCONTEXT,119,CURBOX)
  ELSE
    GEQDEFINE(-1073738402+BOXCONTEXT,119,CURBOX){:1077}
  ELSE
    IF CURBOX<>0
      THEN
      IF BOXCONTEXT>1073742336 THEN{1078:}
        BEGIN{404:}
          REPEAT
            GETXTOKEN;
          UNTIL (CURCMD<>10)AND(CURCMD<>0){:404};
          IF ((CURCMD=26)AND(ABS(CURLIST.MODEFIELD)<>1))OR((CURCMD=27)AND(ABS(
             CURLIST.MODEFIELD)=1))THEN
            BEGIN
              APPENDGLUE;
              MEM[CURLIST.TAILFIELD].HH.B1 := BOXCONTEXT-(1073742237);
              MEM[CURLIST.TAILFIELD+1].HH.RH := CURBOX;
            END
          ELSE
            BEGIN
              print_err('Leaders not followed by proper glue');
              help3('You should say `\leaders <box or rule><hskip or vskip>''.',
                    'I found the <box or rule>, but there''s no suitable',
                    '<hskip or vskip>, so I''m ignoring these leaders.');
              BACKERROR;
              FLUSHNODELIS(CURBOX);
            END;
        END{:1078}
  ELSE SHIPOUT(CURBOX);
END;{:1075}{1079:}
PROCEDURE BEGINBOX(BOXCONTEXT:Int32);

LABEL 30;

VAR P,Q: HALFWORD;
  M: QUARTERWORD;
  K: HALFWORD;
  N: EIGHTBITS;
BEGIN
  CASE CURCHR OF 
    0:
       BEGIN
         SCANEIGHTBIT;
         CURBOX := EQTB[3678+CURVAL].HH.RH;
         EQTB[3678+CURVAL].HH.RH := 0;
       END;
    1:
       BEGIN
         SCANEIGHTBIT;
         CURBOX := COPYNODELIST(EQTB[3678+CURVAL].HH.RH);
       END;
    2:{1080:}
        BEGIN
          CURBOX := 0;
          IF ABS(CURLIST.MODEFIELD)=203 THEN BEGIN
            you_cant;
            help1('Sorry; this \lastbox will be void.');
            ERROR;
          END ELSE IF (CURLIST.MODEFIELD=1)AND(CURLIST.HEADFIELD=CURLIST.TAILFIELD) THEN BEGIN
            you_cant;
            help2('Sorry...I usually can''t take things from the current page.',
                  'This \lastbox will therefore be void.');
            ERROR;
          END ELSE BEGIN
             IF NOT(CURLIST.TAILFIELD>=HIMEMMIN)THEN
               IF (MEM[CURLIST.TAILFIELD].HH.B0=0)OR(MEM[CURLIST.TAILFIELD].HH.B0=1) THEN
                 BEGIN
                   {1081:}
                   Q := CURLIST.HEADFIELD;
                   REPEAT
                     P := Q;
                     IF NOT(Q>=HIMEMMIN)THEN
                       IF MEM[Q].HH.B0=7 THEN
                         BEGIN
                           FOR M:=1 TO MEM[Q].
                               HH.B1 DO
                             P := MEM[P].HH.RH;
                           IF P=CURLIST.TAILFIELD THEN GOTO 30;
                         END;
                     Q := MEM[P].HH.RH;
                   UNTIL Q=CURLIST.TAILFIELD;
                   CURBOX := CURLIST.TAILFIELD;
                   MEM[CURBOX+4].INT := 0;
                   CURLIST.TAILFIELD := P;
                   MEM[P].HH.RH := 0;
                   30:
                 END{:1081};
           END;
       END{:1080};
    3: {1082:}
        BEGIN
          SCANEIGHTBIT;
          N := CURVAL;
          IF NOT scan_keyword('to') THEN BEGIN
            print_err('Missing `to'' inserted');
            help2('I''m working on `\vsplit<box number> to <dimen>'';',
                  'will look for the <dimen> next.');
            ERROR;
          END;
          SCANDIMEN(FALSE,FALSE,FALSE);
          CURBOX := VSPLIT(N,CURVAL);
          {:1082}
        END ELSE BEGIN
          {1083:}
        K := CURCHR-4;
        SAVESTACK[SAVEPTR+0].INT := BOXCONTEXT;
        IF K=102 THEN
          IF (BOXCONTEXT<1073741824)AND(ABS(CURLIST.MODEFIELD)=1)THEN
            SCANSPEC(3,TRUE)
        ELSE SCANSPEC(2,TRUE)
        ELSE
          BEGIN
            IF K=1 THEN SCANSPEC(4, TRUE)
            ELSE
              BEGIN
                SCANSPEC(5,TRUE);
                K := 1;
              END;
            NORMALPARAGR;
          END;
        PUSHNEST;
        CURLIST.MODEFIELD := -K;
        IF K=1 THEN
          BEGIN
            CURLIST.AUXFIELD.INT := -65536000;
            IF EQTB[3418].HH.RH<>0 THEN BEGINTOKENLI(EQTB[3418].HH.RH,11);
          END
        ELSE
          BEGIN
            CURLIST.AUXFIELD.HH.LH := 1000;
            IF EQTB[3417].HH.RH<>0 THEN BEGINTOKENLI(EQTB[3417].HH.RH,10);
          END;
        exit;
      END{:1083}
  END;
  BOXEND(BOXCONTEXT);
END;
{:1079}{1084:}
PROCEDURE SCANBOX(BOXCONTEXT:Int32);
BEGIN{404:}
  REPEAT
    GETXTOKEN;
  UNTIL (CURCMD<>10)AND(CURCMD<>0){:404};

  IF CURCMD=20 THEN BEGINBOX(BOXCONTEXT)
  ELSE IF (BOXCONTEXT>=1073742337) AND ((CURCMD=36)OR(CURCMD=35)) THEN BEGIN
    CURBOX := SCANRULESPEC;
    BOXEND(BOXCONTEXT);
  END ELSE BEGIN
    print_err('A <box> was supposed to be here');
    help3('I was expecting to see \hbox or \vbox or \copy or \box or',
          'something like that. So you might find something missing in',
          'your output. But keep trying; you can fix this later.');
    BACKERROR;
  END;
END;


PROCEDURE PACKAGE(C:SMALLNUMBER);
VAR H: SCALED;
  P: HALFWORD;
  D: SCALED;
BEGIN
  D := EQTB[5837].INT;
  UNSAVE;
  SAVEPTR := SAVEPTR-3;
  IF CURLIST.MODEFIELD=-102 THEN CURBOX := HPACK(MEM[CURLIST.HEADFIELD].HH.RH,
                                                 SAVESTACK[SAVEPTR+2].INT,
                                                 SAVESTACK[SAVEPTR+1].INT)
  ELSE BEGIN
      CURBOX := VPACKAGE(MEM[CURLIST.HEADFIELD].HH.RH,
                         SAVESTACK[SAVEPTR+2].INT,
                         SAVESTACK[SAVEPTR+1].INT,
                         D);
    IF C=4 THEN BEGIN
      H := 0;
      P := MEM[CURBOX+5].HH.RH;
      IF P<>0 THEN
        IF MEM[P].HH.B0<=2 THEN H := MEM[P+3].INT;
      MEM[CURBOX+2].INT := MEM[CURBOX+2].INT-H+MEM[CURBOX+3].INT;
      MEM[CURBOX+3].INT := H;
    END;
  END;
  POPNEST;
  BOXEND(SAVESTACK[SAVEPTR+0].INT);
END;


PROCEDURE NEWGRAF(INDENTED:BOOLEAN);
BEGIN
  CURLIST.PGFIELD := 0;
  IF (CURLIST.MODEFIELD=1)OR(CURLIST.HEADFIELD<>CURLIST.TAILFIELD)THEN
    BEGIN
      MEM[CURLIST.TAILFIELD].HH.RH := NEWPARAMGLUE(2);
      CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
    END;
  PUSHNEST;
  CURLIST.MODEFIELD := 102;
  CURLIST.AUXFIELD.HH.LH := 1000;
  IF EQTB[5313].INT<=0 THEN CURLANG := 0
  ELSE
    IF EQTB[5313].INT>255 THEN
      CURLANG := 0
  ELSE CURLANG := EQTB[5313].INT;
  CURLIST.AUXFIELD.HH.RH := CURLANG;
  CURLIST.PGFIELD := (NORMMIN(EQTB[5314].INT)*64+NORMMIN(EQTB[5315].INT))
                     *65536+CURLANG;
  IF INDENTED THEN
    BEGIN
      CURLIST.TAILFIELD := NEWNULLBOX;
      MEM[CURLIST.HEADFIELD].HH.RH := CURLIST.TAILFIELD;
      MEM[CURLIST.TAILFIELD+1].INT := EQTB[5830].INT;
    END;
  IF EQTB[3414].HH.RH<>0 THEN BEGINTOKENLI(EQTB[3414].HH.RH,7);
  IF NESTPTR=1 THEN BUILDPAGE;
END;{:1091}{1093:}
PROCEDURE INDENTINHMOD;

VAR P,Q: HALFWORD;
BEGIN
  IF CURCHR>0 THEN
    BEGIN
      P := NEWNULLBOX;
      MEM[P+1].INT := EQTB[5830].INT;
      IF ABS(CURLIST.MODEFIELD)=102 THEN CURLIST.AUXFIELD.HH.LH := 1000
      ELSE
        BEGIN
          Q := NEWNOAD;
          MEM[Q+1].HH.RH := 2;
          MEM[Q+1].HH.LH := P;
          P := Q;
        END;
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := P;
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
    END;
END;

PROCEDURE HEADFORVMODE;
BEGIN
  if CURLIST.MODEFIELD>=0 then begin
    BACKINPUT;
    CURTOK := PARTOKEN;
    BACKINPUT;
    CURINPUT.INDEXFIELD := 4;
  end else if CURCMD=36 then begin
    print_err('You can''t use `' + print_esc('hrule') + ''' here except with leaders');
    help2('To put a horizontal rule in an hbox or an alignment,',
          'you should use \leaders or \hrulefill (see The TeXbook).');
    ERROR;
  end else OFFSAVE;
END;


PROCEDURE ENDGRAF;
BEGIN
  IF CURLIST.MODEFIELD=102 THEN
    BEGIN
      IF CURLIST.HEADFIELD=CURLIST.
         TAILFIELD THEN POPNEST
      ELSE LINEBREAK(EQTB[5269].INT);
      NORMALPARAGR;
      ERRORCOUNT := 0;
    END;
END;


PROCEDURE BEGININSERTO;
BEGIN
  IF CURCMD=38
  THEN CURVAL := 255
  ELSE BEGIN
    SCANEIGHTBIT;
    IF CURVAL=255 THEN BEGIN
      print_err('You can''t ' + print_esc('insert255'));
      help1('I''m changing to \insert0; box 255 is special.');
      ERROR;
      CURVAL := 0;
    END;
  END;
  SAVESTACK[SAVEPTR+0].INT := CURVAL;
  SAVEPTR := SAVEPTR+1;
  NEWSAVELEVEL(11);
  SCANLEFTBRAC;
  NORMALPARAGR;
  PUSHNEST;
  CURLIST.MODEFIELD := -1;
  CURLIST.AUXFIELD.INT := -65536000;
END;


PROCEDURE MAKEMARK;
VAR P: HALFWORD;
BEGIN
  P := SCANTOKS(FALSE,TRUE);
  P := GETNODE(2);
  MEM[P].HH.B0 := 4;
  MEM[P].HH.B1 := 0;
  MEM[P+1].INT := DEFREF;
  MEM[CURLIST.TAILFIELD].HH.RH := P;
  CURLIST.TAILFIELD := P;
END;


PROCEDURE APPENDPENALT;
BEGIN
  SCANINT;
  BEGIN
    MEM[CURLIST.TAILFIELD].HH.RH := NEWPENALTY(CURVAL);
    CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
  END;
  IF CURLIST.MODEFIELD=1 THEN BUILDPAGE;
END;


PROCEDURE DELETELAST;
VAR P,Q: HALFWORD;
  M: QUARTERWORD;
BEGIN
  IF (CURLIST.MODEFIELD=1)AND(CURLIST.TAILFIELD=CURLIST.HEADFIELD) THEN BEGIN
    {1106:}
    IF (CURCHR<>10)OR(LASTGLUE<>65535) THEN BEGIN
      you_cant;
      IF CURCHR=11 THEN 
        help2('Sorry...I usually can''t take things from the current page.',
              'Try `I\kern-\lastkern'' instead.')
      ELSE IF CURCHR<>10 THEN 
        help2('Sorry...I usually can''t take things from the current page.',
              'Perhaps you can make the output routine do it.')
      else
        help2('Sorry...I usually can''t take things from the current page.',
              'Try `I\vskip-\lastskip'' instead.');
      ERROR;
    END;
    {:1106}
  END ELSE BEGIN
    IF NOT (CURLIST.TAILFIELD>=HIMEMMIN) THEN
      IF MEM[CURLIST.TAILFIELD].HH.B0=CURCHR THEN BEGIN
        Q := CURLIST.HEADFIELD;
        REPEAT
          P := Q;
          IF NOT(Q>=HIMEMMIN) THEN
            IF MEM[Q].HH.B0=7 THEN BEGIN
              FOR M:=1 TO MEM[Q].HH.B1 DO P := MEM[P].HH.RH;
              IF P=CURLIST.TAILFIELD THEN exit;
            END;
          Q := MEM[P].HH.RH;
        UNTIL Q=CURLIST.TAILFIELD;
        MEM[P].HH.RH := 0;
        FLUSHNODELIS(CURLIST.TAILFIELD);
        CURLIST.TAILFIELD := P;
      END;
  END;
END;


PROCEDURE UNPACKAGE;
VAR
  P: HALFWORD;
  C: 0..1;
BEGIN
  C := CURCHR;
  SCANEIGHTBIT;
  P := EQTB[3678+CURVAL].HH.RH;
  IF P=0 THEN exit;
  IF (ABS(CURLIST.MODEFIELD)=203) OR
     ((ABS(CURLIST.MODEFIELD)=1) AND (MEM[P].HH.B0<>1)) OR
     ((ABS(CURLIST.MODEFIELD)=102) AND (MEM[P].HH.B0<>0))
  THEN BEGIN
    print_err('Incompatible list can''t be unboxed');
    help3('Sorry, Pandora. (You sneaky devil.)',
          'I refuse to unbox an \hbox in vertical mode or vice versa.',
          'And I can''t open any boxes in math mode.');
    ERROR;
    exit;
  END;
  IF C=1 
  THEN MEM[CURLIST.TAILFIELD].HH.RH := COPYNODELIST(MEM[P+5].HH.RH)
  ELSE BEGIN
    MEM[CURLIST.TAILFIELD].HH.RH := MEM[P+5].HH.RH;
    EQTB[3678+CURVAL].HH.RH := 0;
    FREENODE(P,7);
  END;

  WHILE MEM[CURLIST.TAILFIELD].HH.RH<>0 DO
    CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
END;


PROCEDURE APPENDITALIC;
VAR P: HALFWORD;
  F: INTERNALFONT;
BEGIN
  IF CURLIST.TAILFIELD<>CURLIST.HEADFIELD THEN
    BEGIN
      IF (CURLIST.
         TAILFIELD>=HIMEMMIN)THEN P := CURLIST.TAILFIELD
      ELSE
        IF MEM[CURLIST.
           TAILFIELD].HH.B0=6 THEN P := CURLIST.TAILFIELD+1
      ELSE exit;
      F := MEM[P].HH.B0;
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWKERN(FONTINFO[ITALICBASE[F]+(
                                        FONTINFO[CHARBASE[F]+MEM[P].HH.B1].QQQQ.B2-0)DIV 4].INT);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      MEM[CURLIST.TAILFIELD].HH.B1 := 1;
    END;
END;
{:1113}{1117:}
PROCEDURE APPENDDISCRE;

VAR C: Int32;
BEGIN
  BEGIN
    MEM[CURLIST.TAILFIELD].HH.RH := NEWDISC;
    CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
  END;
  IF CURCHR=1 THEN
    BEGIN
      C := HYPHENCHAR[EQTB[3934].HH.RH];
      IF C>=0 THEN
        IF C<256 THEN MEM[CURLIST.TAILFIELD+1].HH.LH := NEWCHARACTER(
                                                        EQTB[3934].HH.RH,C);
    END
  ELSE
    BEGIN
      SAVEPTR := SAVEPTR+1;
      SAVESTACK[SAVEPTR-1].INT := 0;
      NEWSAVELEVEL(10);
      SCANLEFTBRAC;
      PUSHNEST;
      CURLIST.MODEFIELD := -102;
      CURLIST.AUXFIELD.HH.LH := 1000;
    END;
END;


PROCEDURE BUILDDISCRET;
VAR 
  P,Q: HALFWORD;
  N: Int32;
BEGIN
  UNSAVE;{1121:}
  Q := CURLIST.HEADFIELD;
  P := MEM[Q].HH.RH;
  N := 0;
  WHILE P<>0 DO BEGIN
    IF NOT(P>=HIMEMMIN)THEN
      IF MEM[P].HH.B0>2 THEN
        IF MEM[P].HH.B0<>11 THEN
          IF MEM[P].HH.B0<>6 THEN BEGIN
            print_err('Improper discretionary list');
            help1('Discretionary lists must contain only boxes and kerns.');
            ERROR;

            BEGINDIAGNOS;
            print_nl_str('The following discretionary sublist has been deleted:');
            SHOWBOX(P);
            ENDDIAGNOSTI(TRUE);
            FLUSHNODELIS(P);
            MEM[Q].HH.RH := 0;
            break;
          END;
    Q := P;
    P := MEM[Q].HH.RH;
    N := N+1;
  END;
  P := MEM[CURLIST.HEADFIELD].HH.RH;
  POPNEST;
  CASE SAVESTACK[SAVEPTR-1].INT OF 
    0:  MEM[CURLIST.TAILFIELD+1].HH.LH := P;
    1:  MEM[CURLIST.TAILFIELD+1].HH.RH := P;
    2:  BEGIN
          {1120:}
          IF (N>0)AND(ABS(CURLIST.MODEFIELD)=203) THEN BEGIN
            FLUSHNODELIS(P);
            N := 0;
            print_err('Illegal math ' + print_esc('discretionary'));
            help2('Sorry: The third part of a discretionary break must be',
                  'empty, in math formulas. I had to delete your third part.');
            ERROR;
          END ELSE MEM[CURLIST.TAILFIELD].HH.RH := P;
          IF N<=255 THEN MEM[CURLIST.TAILFIELD].HH.B1 := N
          ELSE BEGIN
            print_err('Discretionary list is too long');
            help2('Wow---I never thought anybody would tweak me here.',
                  'You can''t seriously need such a huge discretionary list?');
            ERROR;
          END;
          IF N>0 THEN CURLIST.TAILFIELD := Q;
          SAVEPTR := SAVEPTR-1;
          exit;
          {:1120};
        END;
  END;
  SAVESTACK[SAVEPTR-1].INT := SAVESTACK[SAVEPTR-1].INT+1;
  NEWSAVELEVEL(10);
  SCANLEFTBRAC;
  PUSHNEST;
  CURLIST.MODEFIELD := -102;
  CURLIST.AUXFIELD.HH.LH := 1000;
END;


PROCEDURE MAKEACCENT;
VAR S,T: Double;
  P,Q,R: HALFWORD;
  F: INTERNALFONT;
  A,H,X,W,DELTA: SCALED;
  I: FOURQUARTERS;
BEGIN
  SCANCHARNUM;
  F := EQTB[3934].HH.RH;
  P := NEWCHARACTER(F,CURVAL);
  IF P<>0 THEN
    BEGIN
      X := FONTINFO[5+PARAMBASE[F]].INT;
      S := FONTINFO[1+PARAMBASE[F]].INT/65536.0;
      A := FONTINFO[WIDTHBASE[F]+FONTINFO[CHARBASE[F]+MEM[P].HH.B1].QQQQ.B0].INT
      ;
      DOASSIGNMENT;{1124:}
      Q := 0;
      F := EQTB[3934].HH.RH;
      IF (CURCMD=11)OR(CURCMD=12)OR(CURCMD=68)THEN Q := NEWCHARACTER(F,CURCHR)
      ELSE
        IF CURCMD=16 THEN
          BEGIN
            SCANCHARNUM;
            Q := NEWCHARACTER(F,CURVAL);
          END
      ELSE BACKINPUT{:1124};
      IF Q<>0 THEN{1125:}
        BEGIN
          T := FONTINFO[1+PARAMBASE[F]].INT/65536.0;
          I := FONTINFO[CHARBASE[F]+MEM[Q].HH.B1].QQQQ;
          W := FONTINFO[WIDTHBASE[F]+I.B0].INT;
          H := FONTINFO[HEIGHTBASE[F]+(I.B1-0)DIV 16].INT;
          IF H<>X THEN
            BEGIN
              P := HPACK(P,0,1);
              MEM[P+4].INT := X-H;
            END;
          DELTA := ISORound((W-A)/2.0+H*T-X*S);
          R := NEWKERN(DELTA);
          MEM[R].HH.B1 := 2;
          MEM[CURLIST.TAILFIELD].HH.RH := R;
          MEM[R].HH.RH := P;
          CURLIST.TAILFIELD := NEWKERN(-A-DELTA);
          MEM[CURLIST.TAILFIELD].HH.B1 := 2;
          MEM[P].HH.RH := CURLIST.TAILFIELD;
          P := Q;
        END{:1125};
      MEM[CURLIST.TAILFIELD].HH.RH := P;
      CURLIST.TAILFIELD := P;
      CURLIST.AUXFIELD.HH.LH := 1000;
    END;
END;{:1123}{1127:}



{799:}
PROCEDURE FINROW;
VAR P: HALFWORD;
BEGIN
  IF CURLIST.MODEFIELD=-102 THEN
    BEGIN
      P := HPACK(MEM[CURLIST.
           HEADFIELD].HH.RH,0,1);
      POPNEST;
      APPENDTOVLIS(P);
      IF CURHEAD<>CURTAIL THEN
        BEGIN
          MEM[CURLIST.TAILFIELD].HH.RH := MEM[CURHEAD
                                          ].HH.RH;
          CURLIST.TAILFIELD := CURTAIL;
        END;
    END
  ELSE
    BEGIN
      P := VPACKAGE(MEM[CURLIST.HEADFIELD].HH.RH,0,1,1073741823);
      POPNEST;
      MEM[CURLIST.TAILFIELD].HH.RH := P;
      CURLIST.TAILFIELD := P;
      CURLIST.AUXFIELD.HH.LH := 1000;
    END;
  MEM[P].HH.B0 := 13;
  MEM[P+6].INT := 0;
  IF EQTB[3420].HH.RH<>0 THEN BEGINTOKENLI(EQTB[3420].HH.RH,13);
  ALIGNPEEK;
END;
{:799}

{1131:}
PROCEDURE DOENDV;
BEGIN
  BASEPTR := INPUTPTR;
  INPUTSTACK[BASEPTR] := CURINPUT;
  WHILE (INPUTSTACK[BASEPTR].INDEXFIELD<>2)AND(INPUTSTACK[BASEPTR].LOCFIELD
        =0)AND(INPUTSTACK[BASEPTR].STATEFIELD=0) DO
    BASEPTR := BASEPTR-1;
  IF (INPUTSTACK[BASEPTR].INDEXFIELD<>2)OR(INPUTSTACK[BASEPTR].LOCFIELD<>0)
     OR(INPUTSTACK[BASEPTR].STATEFIELD<>0)THEN fatal_error('(interwoven alignment preambles are not allowed)');
  IF CURGROUP=6 THEN
    BEGIN
      ENDGRAF;
      IF FINCOL THEN FINROW;
    END
  ELSE OFFSAVE;
END;
PROCEDURE PUSHMATH(C:GROUPCODE);
BEGIN
  PUSHNEST;
  CURLIST.MODEFIELD := -203;
  CURLIST.AUXFIELD.INT := 0;
  NEWSAVELEVEL(C);
END;
{:1136}{1138:}
PROCEDURE INITMATH;

LABEL 21,40,45,30;

VAR W: SCALED;
  L: SCALED;
  S: SCALED;
  P: HALFWORD;
  Q: HALFWORD;
  F: INTERNALFONT;
  N: Int32;
  V: SCALED;
  D: SCALED;
BEGIN
  GETTOKEN;
  IF (CURCMD=3)AND(CURLIST.MODEFIELD>0)THEN{1145:}
    BEGIN
      IF CURLIST.
         HEADFIELD=CURLIST.TAILFIELD THEN
        BEGIN
          POPNEST;
          W := -1073741823;
        END
      ELSE
        BEGIN
          LINEBREAK(EQTB[5270].INT);
{1146:}
          V := MEM[JUSTBOX+4].INT+2*FONTINFO[6+PARAMBASE[EQTB[3934].HH.RH]].
               INT;
          W := -1073741823;
          P := MEM[JUSTBOX+5].HH.RH;
          WHILE P<>0 DO
            BEGIN{1147:}
              21:
                  IF (P>=HIMEMMIN)THEN
                    BEGIN
                      F := MEM[P].HH.B0;
                      D := FONTINFO[WIDTHBASE[F]+FONTINFO[CHARBASE[F]+MEM[P].HH.B1].QQQQ.B0].INT
                      ;
                      GOTO 40;
                    END;
              CASE MEM[P].HH.B0 OF 
                0,1,2:
                       BEGIN
                         D := MEM[P+1].INT;
                         GOTO 40;
                       END;
                6:{652:}
                   BEGIN
                     MEM[29988] := MEM[P+1];
                     MEM[29988].HH.RH := MEM[P].HH.RH;
                     P := 29988;
                     GOTO 21;
                   END{:652};
                11,9: D := MEM[P+1].INT;
                10:{1148:}
                    BEGIN
                      Q := MEM[P+1].HH.LH;
                      D := MEM[Q+1].INT;
                      IF MEM[JUSTBOX+5].HH.B0=1 THEN
                        BEGIN
                          IF (MEM[JUSTBOX+5].HH.B1=MEM[Q].HH.
                             B0)AND(MEM[Q+2].INT<>0)THEN V := 1073741823;
                        END
                      ELSE
                        IF MEM[JUSTBOX+5].HH.B0=2 THEN
                          BEGIN
                            IF (MEM[JUSTBOX+5].HH.B1=
                               MEM[Q].HH.B1)AND(MEM[Q+3].INT<>0)THEN V := 1073741823;
                          END;
                      IF MEM[P].HH.B1>=100 THEN GOTO 40;
                    END{:1148};
                8:{1361:}D := 0{:1361};
                ELSE D := 0
              END{:1147};
              IF V<1073741823 THEN V := V+D;
              GOTO 45;
              40:
                  IF V<1073741823 THEN
                    BEGIN
                      V := V+D;
                      W := V;
                    END
                  ELSE
                    BEGIN
                      W := 1073741823;
                      GOTO 30;
                    END;
              45: P := MEM[P].HH.RH;
            END;
          30:{:1146};
        END;
{1149:}
      IF EQTB[3412].HH.RH=0 THEN
        IF (EQTB[5847].INT<>0)AND(((EQTB[5304].
           INT>=0)AND(CURLIST.PGFIELD+2>EQTB[5304].INT))OR(CURLIST.PGFIELD+1<-EQTB[
           5304].INT))THEN
          BEGIN
            L := EQTB[5833].INT-ABS(EQTB[5847].INT);
            IF EQTB[5847].INT>0 THEN S := EQTB[5847].INT
            ELSE S := 0;
          END
      ELSE
        BEGIN
          L := EQTB[5833].INT;
          S := 0;
        END
      ELSE
        BEGIN
          N := MEM[EQTB[3412].HH.RH].HH.LH;
          IF CURLIST.PGFIELD+2>=N THEN P := EQTB[3412].HH.RH+2*N
          ELSE P := EQTB[3412].
                    HH.RH+2*(CURLIST.PGFIELD+2);
          S := MEM[P-1].INT;
          L := MEM[P].INT;
        END{:1149};
      PUSHMATH(15);
      CURLIST.MODEFIELD := 203;
      EQWORDDEFINE(5307,-1);
      EQWORDDEFINE(5843,W);
      EQWORDDEFINE(5844,L);
      EQWORDDEFINE(5845,S);
      IF EQTB[3416].HH.RH<>0 THEN BEGINTOKENLI(EQTB[3416].HH.RH,9);
      IF NESTPTR=1 THEN BUILDPAGE;
    END{:1145}
  ELSE
    BEGIN
      BACKINPUT;
{1139:}
      BEGIN
        PUSHMATH(15);
        EQWORDDEFINE(5307,-1);
        IF EQTB[3415].HH.RH<>0 THEN BEGINTOKENLI(EQTB[3415].HH.RH,8);
      END{:1139};
    END;
END;{:1138}{1142:}
PROCEDURE STARTEQNO;
BEGIN
  SAVESTACK[SAVEPTR+0].INT := CURCHR;
  SAVEPTR := SAVEPTR+1;
{1139:}
  BEGIN
    PUSHMATH(15);
    EQWORDDEFINE(5307,-1);
    IF EQTB[3415].HH.RH<>0 THEN BEGINTOKENLI(EQTB[3415].HH.RH,8);
  END{:1139};
END;{:1142}{1151:}
PROCEDURE SCANMATH(P:HALFWORD);

LABEL 20,21;

VAR C: Int32;
BEGIN
  20:{404:}REPEAT
             GETXTOKEN;
      UNTIL (CURCMD<>10)AND(CURCMD<>0){:404};
  21:
      CASE CURCMD OF 
        11,12,68:
                  BEGIN
                    C := EQTB[5007+CURCHR].HH.RH-0;
                    IF C=32768 THEN
                      BEGIN{1152:}
                        BEGIN
                          CURCS := CURCHR+1;
                          CURCMD := EQTB[CURCS].HH.B0;
                          CURCHR := EQTB[CURCS].HH.RH;
                          XTOKEN;
                          BACKINPUT;
                        END{:1152};
                        GOTO 20;
                      END;
                  END;
        16:
            BEGIN
              SCANCHARNUM;
              CURCHR := CURVAL;
              CURCMD := 68;
              GOTO 21;
            END;
        17:
            BEGIN
              SCANFIFTEENB;
              C := CURVAL;
            END;
        69: C := CURCHR;
        15:
            BEGIN
              SCANTWENTYSE;
              C := CURVAL DIV 4096;
            END;
        ELSE{1153:}
          BEGIN
            BACKINPUT;
            SCANLEFTBRAC;
            SAVESTACK[SAVEPTR+0].INT := P;
            SAVEPTR := SAVEPTR+1;
            PUSHMATH(9);
            exit;
          END{:1153}
      END;
  MEM[P].HH.RH := 1;
  MEM[P].HH.B1 := C MOD 256+0;
  IF (C>=28672)AND((EQTB[5307].INT>=0)AND(EQTB[5307].INT<16))THEN MEM[P].HH
    .B0 := EQTB[5307].INT
  ELSE MEM[P].HH.B0 := (C DIV 256)MOD 16;
END;
{:1151}{1155:}
PROCEDURE SETMATHCHAR(C:Int32);

VAR P: HALFWORD;
BEGIN
  IF C>=32768 THEN{1152:}
    BEGIN
      CURCS := CURCHR+1;
      CURCMD := EQTB[CURCS].HH.B0;
      CURCHR := EQTB[CURCS].HH.RH;
      XTOKEN;
      BACKINPUT;
    END{:1152}
  ELSE
    BEGIN
      P := NEWNOAD;
      MEM[P+1].HH.RH := 1;
      MEM[P+1].HH.B1 := C MOD 256+0;
      MEM[P+1].HH.B0 := (C DIV 256)MOD 16;
      IF C>=28672 THEN
        BEGIN
          IF ((EQTB[5307].INT>=0)AND(EQTB[5307].INT<16))THEN
            MEM[P+1].HH.B0 := EQTB[5307].INT;
          MEM[P].HH.B0 := 16;
        END
      ELSE MEM[P].HH.B0 := 16+(C DIV 4096);
      MEM[CURLIST.TAILFIELD].HH.RH := P;
      CURLIST.TAILFIELD := P;
    END;
END;

PROCEDURE MATHLIMITSWI;
BEGIN
  if (CURLIST.HEADFIELD<>CURLIST.TAILFIELD) and 
     (MEM[CURLIST.TAILFIELD].HH.B0=17)
  then begin
    MEM[CURLIST.TAILFIELD].HH.B1 := CURCHR;
  end else begin
    print_err('Limit controls must follow a math operator');
    help1('I''m ignoring this misplaced \limits or \nolimits command.');
    ERROR;
  end;
END;

PROCEDURE SCANDELIMITE(P:HALFWORD;R:BOOLEAN);
BEGIN
  IF R THEN SCANTWENTYSE
  ELSE
    BEGIN{404:}
      REPEAT
        GETXTOKEN;
      UNTIL (CURCMD<>10)AND(CURCMD<>0){:404};
      CASE CURCMD OF 
        11,12: CURVAL := EQTB[5574+CURCHR].INT;
        15: SCANTWENTYSE;
        ELSE CURVAL := -1
      END;
    END;
  IF CURVAL<0 THEN BEGIN

    {@<Report that an invalid delimiter code is being changed @>}
    print_err('Missing delimiter (. inserted)');
    help6('I was expecting to see something like `('' or `\{'' or',
          '`\}'' here. If you typed, e.g., `{'' instead of `\{'', you',
          'should probably delete the `{'' by typing `1'' now, so that',
          'braces don''t get unbalanced. Otherwise just proceed.',
          'Acceptable delimiters are characters whose \delcode is',
          'nonnegative, or you can use `\delimiter <delimiter code>''.');
    BACKERROR;
    CURVAL := 0;

  END;
  MEM[P].QQQQ.B0 := (CURVAL DIV 1048576)MOD 16;
  MEM[P].QQQQ.B1 := (CURVAL DIV 4096)MOD 256+0;
  MEM[P].QQQQ.B2 := (CURVAL DIV 256)MOD 16;
  MEM[P].QQQQ.B3 := CURVAL MOD 256+0;
END;


PROCEDURE MATHRADICAL;
BEGIN
  BEGIN
    MEM[CURLIST.TAILFIELD].HH.RH := GETNODE(5);
    CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
  END;
  MEM[CURLIST.TAILFIELD].HH.B0 := 24;
  MEM[CURLIST.TAILFIELD].HH.B1 := 0;
  MEM[CURLIST.TAILFIELD+1].HH := EMPTYFIELD;
  MEM[CURLIST.TAILFIELD+3].HH := EMPTYFIELD;
  MEM[CURLIST.TAILFIELD+2].HH := EMPTYFIELD;
  SCANDELIMITE(CURLIST.TAILFIELD+4,TRUE);
  SCANMATH(CURLIST.TAILFIELD+1);
END;


PROCEDURE MATHAC;
BEGIN
  IF CURCMD=45 THEN BEGIN

    {@<Complain that the user should have said \mathaccent @>}
    print_err('Please use ' + print_esc('mathaccent') + ' for accents in math mode');
    help2('I''m changing \accent to \mathaccent here; wish me luck.',
          '(Accents are not the same in formulas as they are in text.)');
    ERROR;

  END;
  BEGIN
    MEM[CURLIST.TAILFIELD].HH.RH := GETNODE(5);
    CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
  END;
  MEM[CURLIST.TAILFIELD].HH.B0 := 28;
  MEM[CURLIST.TAILFIELD].HH.B1 := 0;
  MEM[CURLIST.TAILFIELD+1].HH := EMPTYFIELD;
  MEM[CURLIST.TAILFIELD+3].HH := EMPTYFIELD;
  MEM[CURLIST.TAILFIELD+2].HH := EMPTYFIELD;
  MEM[CURLIST.TAILFIELD+4].HH.RH := 1;
  SCANFIFTEENB;
  MEM[CURLIST.TAILFIELD+4].HH.B1 := CURVAL MOD 256+0;
  IF (CURVAL>=28672)AND((EQTB[5307].INT>=0)AND(EQTB[5307].INT<16))THEN MEM[
    CURLIST.TAILFIELD+4].HH.B0 := EQTB[5307].INT
  ELSE MEM[CURLIST.TAILFIELD+4]
    .HH.B0 := (CURVAL DIV 256)MOD 16;
  SCANMATH(CURLIST.TAILFIELD+1);
END;


PROCEDURE APPENDCHOICE;
BEGIN
  BEGIN
    MEM[CURLIST.TAILFIELD].HH.RH := NEWCHOICE;
    CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
  END;
  SAVEPTR := SAVEPTR+1;
  SAVESTACK[SAVEPTR-1].INT := 0;
  PUSHMATH(13);
  SCANLEFTBRAC;
END;


FUNCTION FINMLIST(P:HALFWORD): HALFWORD;
VAR Q: HALFWORD;
BEGIN
  IF CURLIST.AUXFIELD.INT<>0 THEN{1185:}
    BEGIN
      MEM[CURLIST.AUXFIELD.
      INT+3].HH.RH := 3;
      MEM[CURLIST.AUXFIELD.INT+3].HH.LH := MEM[CURLIST.HEADFIELD].HH.RH;
      IF P=0 THEN Q := CURLIST.AUXFIELD.INT
      ELSE
        BEGIN
          Q := MEM[CURLIST.AUXFIELD.
               INT+2].HH.LH;
          IF MEM[Q].HH.B0<>30 THEN confusion_str('right');
          MEM[CURLIST.AUXFIELD.INT+2].HH.LH := MEM[Q].HH.RH;
          MEM[Q].HH.RH := CURLIST.AUXFIELD.INT;
          MEM[CURLIST.AUXFIELD.INT].HH.RH := P;
        END;
    END{:1185}
  ELSE
    BEGIN
      MEM[CURLIST.TAILFIELD].HH.RH := P;
      Q := MEM[CURLIST.HEADFIELD].HH.RH;
    END;
  POPNEST;
  FINMLIST := Q;
END;
{:1184}
PROCEDURE BUILDCHOICES;
VAR P: HALFWORD;
BEGIN
  UNSAVE;
  P := FINMLIST(0);
  CASE SAVESTACK[SAVEPTR-1].INT OF 
    0: MEM[CURLIST.TAILFIELD+1].HH.LH := P;
    1: MEM[CURLIST.TAILFIELD+1].HH.RH := P;
    2: MEM[CURLIST.TAILFIELD+2].HH.LH := P;
    3:
       BEGIN
         MEM[CURLIST.TAILFIELD+2].HH.RH := P;
         SAVEPTR := SAVEPTR-1;
         exit;
       END;
  END;
  SAVESTACK[SAVEPTR-1].INT := SAVESTACK[SAVEPTR-1].INT+1;
  PUSHMATH(13);
  SCANLEFTBRAC;
END;{:1174}{1176:}
PROCEDURE SUBSUP;

VAR T: SMALLNUMBER;
  P: HALFWORD;
BEGIN
  T := 0;
  P := 0;
  IF CURLIST.TAILFIELD<>CURLIST.HEADFIELD THEN
    IF (MEM[CURLIST.TAILFIELD].
       HH.B0>=16)AND(MEM[CURLIST.TAILFIELD].HH.B0<30)THEN
      BEGIN
        P := CURLIST.
             TAILFIELD+2+CURCMD-7;
        T := MEM[P].HH.RH;
      END;
  IF (P=0)OR(T<>0)THEN{1177:}
    BEGIN
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := 
                                        NEWNOAD;
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      P := CURLIST.TAILFIELD+2+CURCMD-7;
      IF T<>0 THEN BEGIN
        IF CURCMD=7 THEN BEGIN
          print_err('Double superscript');
          help1('I treat `x^1^2'' essentially like `x^1{}^2''.');
          ERROR;
        END ELSE BEGIN
          print_err('Double subscript');
          help1('I treat `x_1_2'' essentially like `x_1{}_2''.');
          ERROR;
        END;
      END;
    END{:1177};
  SCANMATH(P);
END;

PROCEDURE MATHFRACTION;
VAR C: SMALLNUMBER;
BEGIN
  C := CURCHR;
  IF CURLIST.AUXFIELD.INT<>0 THEN{1183:}
    BEGIN
      IF C>=3 THEN
        BEGIN
          SCANDELIMITE(29988,FALSE);
          SCANDELIMITE(29988,FALSE);
        END;
      IF C MOD 3=0 THEN SCANDIMEN(FALSE,FALSE,FALSE);
      
      print_err('Ambiguous; you need another { and }');
      help3('I''m ignoring this fraction specification, since I don''t',
            'know whether a construction like `x \over y \over z''',
            'means `{x \over y} \over z'' or `x \over {y \over z}''.');
      ERROR;
    END{:1183}
  ELSE
    BEGIN
      CURLIST.AUXFIELD.INT := GETNODE(6);
      MEM[CURLIST.AUXFIELD.INT].HH.B0 := 25;
      MEM[CURLIST.AUXFIELD.INT].HH.B1 := 0;
      MEM[CURLIST.AUXFIELD.INT+2].HH.RH := 3;
      MEM[CURLIST.AUXFIELD.INT+2].HH.LH := MEM[CURLIST.HEADFIELD].HH.RH;
      MEM[CURLIST.AUXFIELD.INT+3].HH := EMPTYFIELD;
      MEM[CURLIST.AUXFIELD.INT+4].QQQQ := NULLDELIMITE;
      MEM[CURLIST.AUXFIELD.INT+5].QQQQ := NULLDELIMITE;
      MEM[CURLIST.HEADFIELD].HH.RH := 0;
      CURLIST.TAILFIELD := CURLIST.HEADFIELD;
{1182:}
      IF C>=3 THEN
        BEGIN
          SCANDELIMITE(CURLIST.AUXFIELD.INT+4,FALSE);
          SCANDELIMITE(CURLIST.AUXFIELD.INT+5,FALSE);
        END;
      CASE C MOD 3 OF 
        0:
           BEGIN
             SCANDIMEN(FALSE,FALSE,FALSE);
             MEM[CURLIST.AUXFIELD.INT+1].INT := CURVAL;
           END;
        1: MEM[CURLIST.AUXFIELD.INT+1].INT := 1073741824;
        2: MEM[CURLIST.AUXFIELD.INT+1].INT := 0;
      END{:1182};
    END;
END;
{:1181}{1191:}
PROCEDURE MATHLEFTRIGH;

VAR T: SMALLNUMBER;
  P: HALFWORD;
BEGIN
  T := CURCHR;
  IF (T=31)AND(CURGROUP<>16)THEN{1192:}
    BEGIN
      IF CURGROUP=15 THEN
        BEGIN
          SCANDELIMITE(29988,FALSE);
          print_err('Extra ' + print_esc('right'));
          help1('I''m ignoring a \right that had no matching \left.');
          ERROR;
        END
      ELSE OFFSAVE;
    END{:1192}
  ELSE
    BEGIN
      P := NEWNOAD;
      MEM[P].HH.B0 := T;
      SCANDELIMITE(P+1,FALSE);
      IF T=30 THEN
        BEGIN
          PUSHMATH(16);
          MEM[CURLIST.HEADFIELD].HH.RH := P;
          CURLIST.TAILFIELD := P;
        END
      ELSE
        BEGIN
          P := FINMLIST(P);
          UNSAVE;
          BEGIN
            MEM[CURLIST.TAILFIELD].HH.RH := NEWNOAD;
            CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
          END;
          MEM[CURLIST.TAILFIELD].HH.B0 := 23;
          MEM[CURLIST.TAILFIELD+1].HH.RH := 3;
          MEM[CURLIST.TAILFIELD+1].HH.LH := P;
        END;
    END;
END;
{:1191}{1194:}
PROCEDURE AFTERMATH;

VAR L: BOOLEAN;
  DANGER: BOOLEAN;
  M: Int32;
  P: HALFWORD;
  A: HALFWORD;{1198:}
  B: HALFWORD;
  W: SCALED;
  Z: SCALED;
  E: SCALED;
  Q: SCALED;
  D: SCALED;
  S: SCALED;
  G1,G2: SMALLNUMBER;
  R: HALFWORD;
  T: HALFWORD;{:1198}
BEGIN
  DANGER := FALSE;
{1195:}
  IF (FONTPARAMS[EQTB[3937].HH.RH]<22) OR
     (FONTPARAMS[EQTB[3953].HH.RH]<22) OR
     (FONTPARAMS[EQTB[3969].HH.RH]<22)
  THEN BEGIN
    print_err('Math formula deleted: Insufficient symbol fonts');
    help3('Sorry, but I can''t typeset math unless \textfont 2',
          'and \scriptfont 2 and \scriptscriptfont 2 have all',
          'the \fontdimen values needed in math symbol fonts.');
    ERROR;
    FLUSHMATH;
    DANGER := TRUE;
  END ELSE IF (FONTPARAMS[EQTB[3938].HH.RH]<13) OR
              (FONTPARAMS[EQTB[3954].HH.RH]<13) OR
              (FONTPARAMS[EQTB[3970].HH.RH]<13)
  THEN BEGIN
    print_err('Math formula deleted: Insufficient extension fonts');
    help3('Sorry, but I can''t typeset math unless \textfont 3',
          'and \scriptfont 3 and \scriptscriptfont 3 have all',
          'the \fontdimen values needed in math extension fonts.');
    ERROR;
    FLUSHMATH;
    DANGER := TRUE;
  END;
{:1195}
  M := CURLIST.MODEFIELD;
  L := FALSE;
  P := FINMLIST(0);
  IF CURLIST.MODEFIELD=-M THEN BEGIN
    {1197:}
    GETXTOKEN;
    IF CURCMD<>3 THEN BEGIN
      print_err('Display math should end with $$');
      help2('The `$'' that I just saw supposedly matches a previous `$$''.',
            'So I shall assume that you typed `$$'' both times.');
      BACKERROR;
    END;
    {:1197};

    CURMLIST := P;
    CURSTYLE := 2;
    MLISTPENALTI := FALSE;
    MLISTTOHLIST;
    A := HPACK(MEM[29997].HH.RH,0,1);
    UNSAVE;
    SAVEPTR := SAVEPTR-1;
    IF SAVESTACK[SAVEPTR+0].INT=1 THEN L := TRUE;
    DANGER := FALSE;

    {1195:}
    IF (FONTPARAMS[EQTB[3937].HH.RH]<22) OR
       (FONTPARAMS[EQTB[3953].HH.RH]<22) OR
       (FONTPARAMS[EQTB[3969].HH.RH]<22)
    THEN BEGIN
      print_err('Math formula deleted: Insufficient symbol fonts');
      help3('Sorry, but I can''t typeset math unless \textfont 2',
            'and \scriptfont 2 and \scriptscriptfont 2 have all',
            'the \fontdimen values needed in math symbol fonts.');
      ERROR;
      FLUSHMATH;
      DANGER := TRUE;
    END ELSE IF (FONTPARAMS[EQTB[3938].HH.RH]<13) OR
                (FONTPARAMS[EQTB[3954].HH.RH]<13) OR
                (FONTPARAMS[EQTB[3970].HH.RH]<13)
    THEN BEGIN
      print_err('Math formula deleted: Insufficient extension fonts');
      help3('Sorry, but I can''t typeset math unless \textfont 3',
            'and \scriptfont 3 and \scriptscriptfont 3 have all',
            'the \fontdimen values needed in math extension fonts.');
      ERROR;
      FLUSHMATH;
      DANGER := TRUE;
    END
    {:1195};

    M := CURLIST.MODEFIELD;
    P := FINMLIST(0);
  END ELSE A := 0;

  IF M<0 THEN{1196:}
    BEGIN
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWMATH(EQTB[5831].INT,0);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      CURMLIST := P;
      CURSTYLE := 2;
      MLISTPENALTI := (CURLIST.MODEFIELD>0);
      MLISTTOHLIST;
      MEM[CURLIST.TAILFIELD].HH.RH := MEM[29997].HH.RH;
      WHILE MEM[CURLIST.TAILFIELD].HH.RH<>0 DO
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWMATH(EQTB[5831].INT,1);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      CURLIST.AUXFIELD.HH.LH := 1000;
      UNSAVE;
    END{:1196}
  ELSE BEGIN
    IF A=0 THEN BEGIN
      {1197:}
      GETXTOKEN;
      IF CURCMD<>3 THEN BEGIN
        print_err('Display math should end with $$');
        help2('The `$'' that I just saw supposedly matches a previous `$$''.',
              'So I shall assume that you typed `$$'' both times.');
        BACKERROR;
      END;
      {:1197}
    END;

    {1199:}
    CURMLIST := P;
    CURSTYLE := 0;
    MLISTPENALTI := FALSE;
    MLISTTOHLIST;
    P := MEM[29997].HH.RH;
    ADJUSTTAIL := 29995;
    B := HPACK(P,0,1);
    P := MEM[B+5].HH.RH;
    T := ADJUSTTAIL;
    ADJUSTTAIL := 0;
    W := MEM[B+1].INT;
    Z := EQTB[5844].INT;
    S := EQTB[5845].INT;
    IF (A=0)OR DANGER THEN BEGIN
      E := 0;
      Q := 0;
    END ELSE BEGIN
      E := MEM[A+1].INT;
      Q := E+FONTINFO[6+PARAMBASE[EQTB[3937].HH.RH]].INT;
    END;
    IF W+Q>Z THEN{1201:}
        BEGIN
          IF (E<>0)AND((W-TOTALSHRINK[0]+Q<=Z)OR(
             TOTALSHRINK[1]<>0)OR(TOTALSHRINK[2]<>0)OR(TOTALSHRINK[3]<>0))THEN
            BEGIN
              FREENODE(B,7);
              B := HPACK(P,Z-Q,0);
            END
          ELSE
            BEGIN
              E := 0;
              IF W>Z THEN
                BEGIN
                  FREENODE(B,7);
                  B := HPACK(P,Z,0);
                END;
            END;
          W := MEM[B+1].INT;
        END{:1201};{1202:}
      D := HALF(Z-W);
      IF (E>0)AND(D<2*E)THEN
        BEGIN
          D := HALF(Z-W-E);
          IF P<>0 THEN
            IF NOT(P>=HIMEMMIN)THEN
              IF MEM[P].HH.B0=10 THEN D := 0;
        END{:1202};
{1203:}
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWPENALTY(EQTB[5274].INT);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      IF (D+S<=EQTB[5843].INT)OR L THEN
        BEGIN
          G1 := 3;
          G2 := 4;
        END
      ELSE
        BEGIN
          G1 := 5;
          G2 := 6;
        END;
      IF L AND(E=0)THEN
        BEGIN
          MEM[A+4].INT := S;
          APPENDTOVLIS(A);
          BEGIN
            MEM[CURLIST.TAILFIELD].HH.RH := NEWPENALTY(10000);
            CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
          END;
        END
      ELSE
        BEGIN
          MEM[CURLIST.TAILFIELD].HH.RH := NEWPARAMGLUE(G1);
          CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
        END{:1203};
{1204:}
      IF E<>0 THEN
        BEGIN
          R := NEWKERN(Z-W-E-D);
          IF L THEN
            BEGIN
              MEM[A].HH.RH := R;
              MEM[R].HH.RH := B;
              B := A;
              D := 0;
            END
          ELSE
            BEGIN
              MEM[B].HH.RH := R;
              MEM[R].HH.RH := A;
            END;
          B := HPACK(B,0,1);
        END;
      MEM[B+4].INT := S+D;
      APPENDTOVLIS(B){:1204};
{1205:}
      IF (A<>0)AND(E=0)AND NOT L THEN
        BEGIN
          BEGIN
            MEM[CURLIST.TAILFIELD]
            .HH.RH := NEWPENALTY(10000);
            CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
          END;
          MEM[A+4].INT := S+Z-MEM[A+1].INT;
          APPENDTOVLIS(A);
          G2 := 0;
        END;
      IF T<>29995 THEN
        BEGIN
          MEM[CURLIST.TAILFIELD].HH.RH := MEM[29995].HH.RH;
          CURLIST.TAILFIELD := T;
        END;
      BEGIN
        MEM[CURLIST.TAILFIELD].HH.RH := NEWPENALTY(EQTB[5275].INT);
        CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
      END;
      IF G2>0 THEN
        BEGIN
          MEM[CURLIST.TAILFIELD].HH.RH := NEWPARAMGLUE(G2);
          CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
        END{:1205};
      RESUMEAFTERD{:1199};
    END;
END;{:1194}{1200:}


PROCEDURE GETRTOKEN;
BEGIN
  while true do begin
    REPEAT
      GETTOKEN;
    UNTIL CURTOK<>2592;
    if (CURCS<>0) and (CURCS<=2614) then break;
    print_err('Missing control sequence inserted');
    help5('Please don''t say `\def cs{...}'', say `\def\cs{...}''.',
          'I''ve inserted an inaccessible control sequence so that your',
          'definition will be completed without mixing me up too badly.',
          'You can recover graciously from this error, if you''re',
          'careful; see exercise 27.2 in The TeXbook.');
    IF CURCS=0 THEN BACKINPUT;
    CURTOK := 6709;
    INSERROR;
  end;
END;


PROCEDURE TRAPZEROGLUE;
BEGIN
  IF (MEM[CURVAL+1].INT=0)AND(MEM[CURVAL+2].INT=0)AND(MEM[CURVAL+3].
     INT=0)THEN
    BEGIN
      MEM[0].HH.RH := MEM[0].HH.RH+1;
      DELETEGLUERE(CURVAL);
      CURVAL := 0;
    END;
END;


PROCEDURE DOREGISTERCO(A:SMALLNUMBER);
VAR
  L,Q,R,S: HALFWORD;
  P: 0..3;
BEGIN
  Q := CURCMD;
  if Q<>89 then begin
    GETXTOKEN;
    IF (CURCMD>=73) AND (CURCMD<=76) THEN BEGIN
      L := CURCHR;
      P := CURCMD-73;
    end else begin
      IF CURCMD<>89 THEN BEGIN
        print_err('You can''t use `' + print_cmd_chr(CURCMD,CURCHR) +
                  ''' after ' + print_cmd_chr(Q, 0));
        help1('I''m forgetting what you said and not changing anything.');
        ERROR;
        exit;
      END;
      P := CURCHR;
      SCANEIGHTBIT;
      CASE P OF 
        0: L := CURVAL+5318;
        1: L := CURVAL+5851;
        2: L := CURVAL+2900;
        3: L := CURVAL+3156;
      END;
    end;
  end else begin
    P := CURCHR;
    SCANEIGHTBIT;
    CASE P OF 
      0: L := CURVAL+5318;
      1: L := CURVAL+5851;
      2: L := CURVAL+2900;
      3: L := CURVAL+3156;
    END;
  end;

  IF Q=89 THEN SCANOPTIONAL
          ELSE IF scan_keyword('by') THEN;
  ARITHERROR := FALSE;
  IF Q<91 THEN
    {1238:}
    IF P<2 THEN BEGIN
      IF P=0 THEN SCANINT
             ELSE SCANDIMEN(FALSE,FALSE,FALSE);
      IF Q=90 THEN CURVAL := CURVAL+EQTB[L].INT;
    END ELSE BEGIN
      SCANGLUE(P);
      IF Q=90 THEN BEGIN
        {1239:}
        Q := NEWSPEC(CURVAL);
        R := EQTB[L].HH.RH;
        DELETEGLUERE(CURVAL);
        MEM[Q+1].INT := MEM[Q+1].INT+MEM[R+1].INT;
        IF MEM[Q+2].INT=0 THEN MEM[Q].HH.B0 := 0;
        IF MEM[Q].HH.B0=MEM[R].HH.B0 
        THEN MEM[Q+2].INT := MEM[Q+2].INT+MEM[R+2].INT
        ELSE IF (MEM[Q].HH.B0<MEM[R].HH.B0)AND(MEM[R+2].INT<>0) THEN BEGIN
          MEM[Q+2].INT := MEM[R+2].INT;
          MEM[Q].HH.B0 := MEM[R].HH.B0;
        END;
        IF MEM[Q+3].INT=0 THEN MEM[Q].HH.B1 := 0;
        IF MEM[Q].HH.B1=MEM[R].HH.B1 
        THEN MEM[Q+3].INT := MEM[Q+3].INT+MEM[R+3].INT
        ELSE IF (MEM[Q].HH.B1<MEM[R].HH.B1)AND(MEM[R+3].INT<>0) THEN BEGIN
          MEM[Q+3].INT := MEM[R+3].INT;
          MEM[Q].HH.B1 := MEM[R].HH.B1;
        END;
        CURVAL := Q;
        {:1239}
      END;
    END
    {:1238}
  ELSE BEGIN
    {1240:}
    SCANINT;
    IF P<2 THEN
      IF Q=91 THEN
        IF P=0 THEN CURVAL := MULTANDADD(EQTB[L].INT, CURVAL, 0, 2147483647)
               ELSE CURVAL := MULTANDADD(EQTB[L].INT, CURVAL, 0, 1073741823)
      ELSE CURVAL := XOVERN(EQTB[L].INT,CURVAL)
    ELSE BEGIN
      S := EQTB[L].HH.RH;
      R := NEWSPEC(S);
      IF Q=91 THEN BEGIN
        MEM[R+1].INT := MULTANDADD(MEM[S+1].INT, CURVAL, 0, 1073741823);
        MEM[R+2].INT := MULTANDADD(MEM[S+2].INT, CURVAL, 0, 1073741823);
        MEM[R+3].INT := MULTANDADD(MEM[S+3].INT, CURVAL, 0, 1073741823);
      END ELSE BEGIN
        MEM[R+1].INT := XOVERN(MEM[S+1].INT,CURVAL);
        MEM[R+2].INT := XOVERN(MEM[S+2].INT,CURVAL);
        MEM[R+3].INT := XOVERN(MEM[S+3].INT,CURVAL);
      END;
      CURVAL := R;
    END;
    {:1240}
  END;

  IF ARITHERROR THEN BEGIN
    print_err('Arithmetic overflow');
    help2('I can''t carry out that multiplication or division,',
          'since the result is out of range.');
    IF P>=2 THEN DELETEGLUERE(CURVAL);
    ERROR;
    exit;
  END;
  IF P<2 THEN
    IF (A>=4)THEN GEQWORDDEFIN(L, CURVAL)
             ELSE EQWORDDEFINE(L, CURVAL)
  ELSE BEGIN
    TRAPZEROGLUE;
    IF (A>=4) THEN GEQDEFINE(L, 117, CURVAL)
              ELSE EQDEFINE(L, 117, CURVAL);
  END;
END;


PROCEDURE ALTERAUX;
VAR C: HALFWORD;
BEGIN
  IF CURCHR<>ABS(CURLIST.MODEFIELD) 
  THEN report_illegal_case
  ELSE BEGIN
    C := CURCHR;
    SCANOPTIONAL;
    IF C=1 THEN BEGIN
      SCANDIMEN(FALSE,FALSE,FALSE);
      CURLIST.AUXFIELD.INT := CURVAL;
    END ELSE BEGIN
      SCANINT;
      IF (CURVAL<=0) OR (CURVAL>32767) THEN BEGIN
        print_err('Bad space factor (' + print_int(CURVAL) + ')');
        help1('I allow only values in the range 1..32767 here.');
        ERROR;
      END ELSE CURLIST.AUXFIELD.HH.LH := CURVAL;
    END;
  END;
END;


PROCEDURE ALTERPREVGRA;
VAR P: 0..NESTSIZE;
BEGIN
  NEST[NESTPTR] := CURLIST;
  P := NESTPTR;
  WHILE ABS(NEST[P].MODEFIELD)<>1 DO
    P := P-1;
  SCANOPTIONAL;
  SCANINT;
  IF CURVAL<0 THEN BEGIN
    print_err('Bad ' + print_esc('prevgraf') + ' (' + print_int(CURVAL) + ')');
    help1('I allow only nonnegative values here.');
    ERROR;
  END ELSE BEGIN
    NEST[P].PGFIELD := CURVAL;
    CURLIST := NEST[NESTPTR];
  END;
END;


PROCEDURE ALTERPAGESOF;
VAR C: 0..7;
BEGIN
  C := CURCHR;
  SCANOPTIONAL;
  SCANDIMEN(FALSE,FALSE,FALSE);
  PAGESOFAR[C] := CURVAL;
END;


PROCEDURE ALTERINTEGER;
VAR C: 0..1;
BEGIN
  C := CURCHR;
  SCANOPTIONAL;
  SCANINT;
  IF C=0 THEN DEADCYCLES := CURVAL
  ELSE INSERTPENALT := CURVAL;
END;


PROCEDURE ALTERBOXDIME;
VAR
  C: SMALLNUMBER;
  B: EIGHTBITS;
BEGIN
  C := CURCHR;
  SCANEIGHTBIT;
  B := CURVAL;
  SCANOPTIONAL;
  SCANDIMEN(FALSE,FALSE,FALSE);
  IF EQTB[3678+B].HH.RH<>0 THEN MEM[EQTB[3678+B].HH.RH+C].INT := CURVAL;
END;










{ ----------------------------------------------------------------------
  Handle font files
  ---------------------------------------------------------------------- }

{Read 16 bit bigendian from TFM file.
 Return false if I/O error or if sign bit of value is set}
function read_sixteen(var TFMFile: byte_file; var Dest: HALFWORD) : boolean;
var Lo, Hi: EIGHTBITS;
begin
  {$I-}
  read(TFMFile, Hi, Lo);
  {$I+}
  if (IOResult = 0) and (Hi < 128) then begin
    Dest := HALFWORD(Hi)*256 + Lo;
    read_sixteen := true;
  end else begin
    read_sixteen := false;
  end
end;

{Read 4 bytes from TFM file.
 Return false if I/O error}
function store_four_quaters(var TFMFile: byte_file; var qw: FOURQUARTERS) : boolean;
var a,b, c, d : EIGHTBITS;
begin
  {$I-}
  read(TFMFile, a, b, c, d);
  {$I+}
  if IOResult = 0 then begin
    qw.b0 := a;
    qw.b1 := b;
    qw.b2 := c;
    qw.b3 := d;
    store_four_quaters := true;
  end else begin
    store_four_quaters := false;
  end
end;


(*
@ A |fix_word| whose four bytes are $(a,b,c,d)$ from left to right represents
the number
$$x=\left\{\vcenter{\halign{$#$,\hfil\qquad&if $#$\hfil\cr
b\cdot2^{-4}+c\cdot2^{-12}+d\cdot2^{-20}&a=0;\cr
-16+b\cdot2^{-4}+c\cdot2^{-12}+d\cdot2^{-20}&a=255.\cr}}\right.$$
(No other choices of |a| are allowed, since the magnitude of a number in
design-size units must be less than 16.)  We want to multiply this
quantity by the integer~|z|, which is known to be less than $2^{27}$.
If $|z|<2^{23}$, the individual multiplications $b\cdot z$,
$c\cdot z$, $d\cdot z$ cannot overflow; otherwise we will divide |z| by 2,
4, 8, or 16, to obtain a multiplier less than $2^{23}$, and we can
compensate for this later. If |z| has thereby been replaced by
$|z|^\prime=|z|/2^e$, let $\beta=2^{4-e}$; we shall compute
$$\lfloor(b+c\cdot2^{-8}+d\cdot2^{-16})\,z^\prime/\beta\rfloor$$
if $a=0$, or the same quantity minus $\alpha=2^{4+e}z^\prime$ if $a=255$.
This calculation must be done exactly, in order to guarantee portability
of \TeX\ between computers.
*)
function store_scaled(var TFMFile: byte_file;
                      Alpha: SCALED;
                      Beta: SCALED;
                      Z: SCALED;
                      var Result: SCALED) : boolean;
var
  a, b, c, d: EIGHTBITS;
  sw: SCALED;
begin
  {$I-}
  read(TFMFile, a, b, c, d);
  {$I+}
  store_scaled := false;
  if IOResult = 0 then begin
    sw := (((((d*Z) DIV 256)+(c*Z)) DIV 256)+(b*Z)) DIV Beta;
    if a=0 then begin
      Result := sw;
      store_scaled := true;
    end else if a=255 then begin
      Result := sw - Alpha;
      store_scaled := true;
    end
  end
end;

{ 0 all fine
  1 out of memory
  2 invalid format}
function ReadFontFile(var TFMFILE: byte_file;
                      F: INTERNALFONT;
                      S: SCALED) : uint32;
VAR K: FONTINDEX;
  LF,LH,BC,EC,NW,NH,ND,NI,NL,NK,NE,NP: HALFWORD;
  A,B,C,D: EIGHTBITS;
  QW: FOURQUARTERS;
  SW: SCALED;
  BCHLABEL: Int32;
  BCHAR: 0..256;
  Z: SCALED;
  ALPHA: Int32;
  BETA: 1..16;
BEGIN
  ReadFontFile := 2; {invalid format error}

  {565: @<Read the .TFM size fields@>}
  if not read_sixteen(TFMFILE, LF) then exit;
  if not read_sixteen(TFMFILE, LH) then exit;
  if not read_sixteen(TFMFILE, BC) then exit;
  if not read_sixteen(TFMFILE, EC) then exit;

  IF (BC>EC+1)OR(EC>255)THEN exit;
  IF BC>255 THEN BEGIN
    BC := 1;
    EC := 0;
  END;

  if not read_sixteen(TFMFILE, NW) then exit;
  if not read_sixteen(TFMFILE, NH) then exit;
  if not read_sixteen(TFMFILE, ND) then exit;
  if not read_sixteen(TFMFILE, NI) then exit;
  if not read_sixteen(TFMFILE, NL) then exit;
  if not read_sixteen(TFMFILE, NK) then exit;
  if not read_sixteen(TFMFILE, NE) then exit;
  if not read_sixteen(TFMFILE, NP) then exit;

  IF LF<>6+LH+(EC-BC+1)+NW+NH+ND+NI+NL+NK+NE+NP THEN exit;
  IF (NW=0)OR(NH=0)OR(ND=0)OR(NI=0) THEN exit;
  {:565};

  {566: @<Use size fields to allocate font information@>}
  LF := LF-6-LH;
  IF NP<7 THEN LF := LF+7-NP;
  IF (FMEMPTR+LF>FONTMEMSIZE) THEN BEGIN
    ReadFontFile := 1; {out of memory error}
    exit;
  END;
  CHARBASE[F] := FMEMPTR-BC;
  WIDTHBASE[F] := CHARBASE[F]+EC+1;
  HEIGHTBASE[F] := WIDTHBASE[F]+NW;
  DEPTHBASE[F] := HEIGHTBASE[F]+NH;
  ITALICBASE[F] := DEPTHBASE[F]+ND;
  LIGKERNBASE[F] := ITALICBASE[F]+NI;
  KERNBASE[F] := LIGKERNBASE[F]+NL-256*(128);
  EXTENBASE[F] := KERNBASE[F]+256*(128)+NK;
  PARAMBASE[F] := EXTENBASE[F]+NE;
  {:566}
 
  {568: @<Read the .TFM header@>}
  IF LH<2 THEN exit;
  if not store_four_quaters(TFMFILE, FONTCHECK[F]) then exit;
  {$I-}
  read(TFMFILE, A, B, C, D);
  {$I+}
  if IOResult <> 0 then exit;
  if A > 127 then exit; {this rejects a negative design size}
  Z := (A * $100000) + (B * $1000) + (C * 16) + (D div 16);
  if Z < fixUnity then exit;

  {ignore the rest of the header}
  WHILE LH>2 DO BEGIN 
    {$I-}
    read(TFMFILE, A, B, C, D);
    {$I+}
    if IOResult <> 0 then exit;
    LH := LH-1;
  END;
  FONTDSIZE[F] := Z;
  IF S<>-1000 THEN BEGIN
    IF S>=0 THEN Z := S
    ELSE Z := XNOVERD(Z,-S,1000);
  END;
  FONTSIZE[F] := Z;
  {:568};

  {569: @<Read character data@>}

  FOR K:=FMEMPTR TO WIDTHBASE[F]-1 DO BEGIN
    if not store_four_quaters(TFMFILE, QW) then exit;
    FONTINFO[K].QQQQ := QW;
    A := QW.B0;
    B := QW.B1;
    C := QW.B2;
    D := QW.B3;
    IF (A>=NW)OR(B DIV 16>=NH)OR(B MOD 16>=ND)OR(C DIV 4>=NI)THEN exit;
    CASE C MOD 4 OF 
      lig_tag:  IF D>=NL THEN exit;
      ext_tag:  IF D>=NE THEN exit;
      list_tag: BEGIN
                 {570: <@Check for charlist cycle@>}

{@ We want to make sure that there is no cycle of characters linked together
by |list_tag| entries, since such a cycle would get \TeX\ into an endless
loop. If such a cycle exists, the routine here detects it when processing
the largest character code in the cycle.}

                 if (D<BC) OR (D>EC) then exit;
                 while D<K+BC-FMEMPTR do begin
                   QW := FONTINFO[CHARBASE[F]+D].QQQQ;
                   if (QW.B2 MOD 4)<>list_tag then break;
                   D := QW.B3;
                 end;
                 if D=K+BC-FMEMPTR then exit;
                 {:570}
               END;
    END;
  END;
  {:569}

  {571: @<Read box dimensions@>}
  BEGIN
    {572: @<Replace |z| b< $|z|^\prime$ and compute $\alpha,\beta$@>}
    BEGIN
      ALPHA := 16;
      WHILE Z>=8388608 DO
        BEGIN
          Z := Z DIV 2;
          ALPHA := ALPHA+ALPHA;
        END;
      BETA := 256 DIV ALPHA;
      ALPHA := ALPHA*Z;
    END;
    {:572}
    FOR K:=WIDTHBASE[F]TO LIGKERNBASE[F]-1 DO BEGIN
      if not store_scaled(TFMFILE, ALPHA, BETA, Z, FONTINFO[K].INT) then exit;
    END;
    IF FONTINFO[WIDTHBASE[F]].INT<>0 THEN exit;
    IF FONTINFO[HEIGHTBASE[F]].INT<>0 THEN exit;
    IF FONTINFO[DEPTHBASE[F]].INT<>0 THEN exit;
    IF FONTINFO[ITALICBASE[F]].INT<>0 THEN exit;
  END;
  {:571}

  {573: @<Read ligature/kern program@>}
  BCHLABEL := 32767;
  BCHAR := 256;
  IF NL>0 THEN BEGIN
    FOR K:=LIGKERNBASE[F]TO KERNBASE[F]+256*(128)-1 DO BEGIN
      if not store_four_quaters(TFMFILE, QW) then exit;
      FONTINFO[K].QQQQ := QW;
      A := QW.B0;
      B := QW.B1;
      C := QW.B2;
      D := QW.B3;
      IF A>128 THEN BEGIN
        IF 256*C+D>=NL THEN exit;
        IF A=255 THEN
          IF K=LIGKERNBASE[F]THEN BCHAR := B;
      END ELSE BEGIN
        IF B<>BCHAR THEN BEGIN
          IF (B<BC)OR(B>EC)THEN exit;
          QW := FONTINFO[CHARBASE[F]+B].QQQQ;
          IF NOT(QW.B0>0)THEN exit;
        END;
        IF C<128 THEN BEGIN
          IF (D<BC)OR(D>EC)THEN exit;
          QW := FONTINFO[CHARBASE[F]+D].QQQQ;
          IF NOT(QW.B0>0)THEN exit;
        END ELSE IF 256*(C-128)+D>=NK THEN exit;
        IF A<128 THEN
          IF K-LIGKERNBASE[F]+A+1>=NL THEN exit;
      END;
    END;
    IF A=255 THEN BCHLABEL := 256*C+D;
  END;
  FOR K:=KERNBASE[F]+256*(128)TO EXTENBASE[F]-1 DO BEGIN
    if not store_scaled(TFMFILE, ALPHA, BETA, Z, FONTINFO[K].INT) then exit;
  END;
  {:573}

  {574: @<Read extensible character recipes@>}
  FOR K:=EXTENBASE[F]TO PARAMBASE[F]-1 DO BEGIN
    if not store_four_quaters(TFMFILE, QW) then exit;
    FONTINFO[K].QQQQ := QW;
    A := QW.B0;
    B := QW.B1;
    C := QW.B2;
    D := QW.B3;

      IF A<>0 THEN
        BEGIN
          BEGIN
            IF (A<BC)OR(A>EC)THEN exit
          END;
          QW := FONTINFO[CHARBASE[F]+A].QQQQ;
          IF NOT(QW.B0>0)THEN exit;
        END;
      IF B<>0 THEN
        BEGIN
          BEGIN
            IF (B<BC)OR(B>EC)THEN exit
          END;
          QW := FONTINFO[CHARBASE[F]+B].QQQQ;
          IF NOT(QW.B0>0)THEN exit;
        END;
      IF C<>0 THEN
        BEGIN
          BEGIN
            IF (C<BC)OR(C>EC)THEN exit
          END;
          QW := FONTINFO[CHARBASE[F]+C].QQQQ;
          IF NOT(QW.B0>0)THEN exit;
        END;
      BEGIN
        BEGIN
          IF (D<BC)OR(D>EC)THEN exit
        END;
        QW := FONTINFO[CHARBASE[F]+D].QQQQ;
        IF NOT(QW.B0>0)THEN exit;
      END;
  END;
  {:574}

  {575: @<Read font parameters@>}
  FOR K:=1 TO NP DO BEGIN
    IF K=1 THEN BEGIN
      {$I-}
      read(TFMFILE, A, B, C, D);
      {$I+}
      if IOResult <> 0 then exit;
      if A > 127 then SW := SCALED(A) - 256 else SW := A;
      SW := (SW * $100000) + (B * $1000) + (C*16) + (D div 16);
      FONTINFO[PARAMBASE[F]].INT := SW;
    END ELSE BEGIN
      if not store_scaled(TFMFILE, ALPHA, BETA, Z, SW) then exit;
      FONTINFO[PARAMBASE[F]+K-1].INT := SW;
    END;
  END;
  FOR K:=NP+1 TO 7 DO
    FONTINFO[PARAMBASE[F]+K-1].INT := 0;
  {:575}

  {576: @<Make final adjustments and |goto done|@>}
  IF NP>=7 THEN FONTPARAMS[F] := NP
  ELSE FONTPARAMS[F] := 7;
  HYPHENCHAR[F] := EQTB[5309].INT;
  SKEWCHAR[F] := EQTB[5310].INT;
  IF BCHLABEL<NL THEN BCHARLABEL[F] := BCHLABEL+LIGKERNBASE[F]
  ELSE
    BCHARLABEL[F] := 0;
  FONTBCHAR[F] := BCHAR+0;
  FONTFALSEBCH[F] := BCHAR+0;
  IF BCHAR<=EC THEN
    IF BCHAR>=BC THEN
      BEGIN
        QW := FONTINFO[CHARBASE[F]+BCHAR
              ].QQQQ;
        IF (QW.B0>0)THEN FONTFALSEBCH[F] := 256;
      END;
  FONTBC[F] := BC;
  FONTEC[F] := EC;
  FONTGLUE[F] := 0;
  CHARBASE[F] := CHARBASE[F]-0;
  WIDTHBASE[F] := WIDTHBASE[F]-0;
  LIGKERNBASE[F] := LIGKERNBASE[F]-0;
  KERNBASE[F] := KERNBASE[F]-0;
  EXTENBASE[F] := EXTENBASE[F]-0;
  PARAMBASE[F] := PARAMBASE[F]-1;
  FMEMPTR := FMEMPTR+LF;
  ReadFontFile := 0; {successful, no error}
  {:576}
  {:562}
END;

FUNCTION READFONTINFO(U:HALFWORD;
                      FileName: shortstring;
                      S:SCALED): INTERNALFONT;
VAR
  TFMFile: byte_file;
  FontNo: INTERNALFONT;
  ErrorCode: uint32;
BEGIN
  ErrorCode := 1; {out of memory. Better: too many fonts loaded}
  if FONTPTR < font_max then begin
    ErrorCode := 3; {file not found}
    if b_open_in(TFMFile, FileName) then begin
      FontNo := FONTPTR+1;
      ErrorCode := ReadFontFile(TFMFile, FontNo, S);
      close(TFMFile);

      if ErrorCode = 0 then begin
        FONTPTR := FontNo; {finally reserve font entry}
        READFONTINFO := FontNo;
        exit;
      end;
    end;
  end;

  {Report an error according to ErrorCode}
  print_err('Font ' + sprint_cs(U) + '=' + RemoveFileExtension(FileName));
  IF S>=0 THEN print_str(' at ' + print_scaled(S) + 'pt')
  ELSE IF S<>-1000 THEN print_str(' scaled ' + print_int(-S));

  if ErrorCode = 1 then begin
    print_str(' not loaded: Not enough room left');
    help4('I''m afraid I won''t be able to make use of this font,',
          'because my memory for character-size data is too small.',
          'If you''re really stuck, ask a wizard to enlarge me.',
          'Or maybe try `I\font<same font id>=<name of loaded font>''.');
    ERROR;
  end else if ErrorCode = 2 then begin
    print_str(' not loadable: Bad metric (TFM) file');
    help5('I wasn''t able to read the size data for this font,',
          'so I will ignore the font specification.',
          '[Wizards can fix TFM files using TFtoPL/PLtoTF.]',
          'You might try inserting a different font spec;',
          'e.g., type `I\font<same font id>=<substitute font name>''.');
    ERROR;
  end else begin
    print_str(' not loadable: Metric (TFM) file not found');
    help5('I wasn''t able to read the size data for this font,',
          'so I will ignore the font specification.',
          '[Wizards can fix TFM files using TFtoPL/PLtoTF.]',
          'You might try inserting a different font spec;',
          'e.g., type `I\font<same font id>=<substitute font name>''.');
    ERROR;
  end;
  READFONTINFO := null_font;
END;

function FindFont(UserFontId: HALFWORD;
                  const FileNameArea: shortstring;
                  ScaleFactor: SCALED) : INTERNALFONT;
var
  FontNo: INTERNALFONT;
  Slash: SizeInt;
  Area: shortstring;
  Name: shortstring;
  AreaIndex: STRNUMBER;
  NameIndex: STRNUMBER;
begin
  AreaIndex := 0;
  NameIndex := 0;
  FOR FontNo := 1 TO FONTPTR DO begin
    if GetString(FONTAREA[FontNo])+GetString(FONTNAME[FontNo]) = FileNameArea then begin
      AreaIndex := FONTAREA[FontNo];
      NameIndex := FONTNAME[FontNo];

      IF ((ScaleFactor>0) and (ScaleFactor=FONTSIZE[FontNo])) or
         ((ScaleFactor<=0) and (FONTSIZE[FontNo]=
         XNOVERD(FONTDSIZE[FontNo],-ScaleFactor,1000))) then begin
        FindFont := FontNo;
        exit;
      end;
    END;
  end;

  Slash := pos('/', FileNameArea); {0 if no path}
  if Slash=0 then begin
    {special case: without path use standard directory}
    Area := 'TeXfonts/';
    AreaIndex := 338{''};
  end else begin
    Area := copy(FileNameArea, 1, Slash-1);
  end;
  Name := copy(FileNameArea, Slash+1);

  FontNo := READFONTINFO(UserFontId, Area+Name+'.tfm', ScaleFactor);

  if FontNo <> null_font then begin
    if AreaIndex=0 then AreaIndex := AddString(Area);
    FONTAREA[FontNo] := AreaIndex;
    if NameIndex=0 then NameIndex := AddString(Name);
    FONTNAME[FontNo] := NameIndex;
  end;
  FindFont := FontNo;
end;

{1257:}
PROCEDURE NEWFONT(A:SMALLNUMBER);
VAR
  U: HALFWORD;
  S: SCALED;
  F: INTERNALFONT;
  T: STRNUMBER;
  FileNameArea: shortstring;

BEGIN
  IF job_name='' THEN OPENLOGFILE;
  GETRTOKEN;

  U := CURCS;
  if      U =  null_cs     then T := 1219 {'FONT'}
  else if U >= hash_base   then T := HASH[U].RH
  else if U >= single_base then T := U - single_base
  else T := AddString('FONT' + GetString(U-1));

  IF A>=4 THEN GEQDEFINE(U,87,0)
          ELSE EQDEFINE(U,87,0);
  SCANOPTIONAL;

  FileNameArea := RemoveFileExtension(scan_file_name);

{1258:}
  NAMEINPROGRE := TRUE;
  IF scan_keyword('at') THEN BEGIN

    {1259:}
    SCANDIMEN(FALSE,FALSE,FALSE);
    S := CURVAL;
    IF (S<=0)OR(S>=134217728) THEN BEGIN
      print_err('Improper `at'' size (' + print_scaled(S) + 'pt), replaced by 10pt');
      help2('I can only handle fonts at positive sizes that are',
            'less than 2048pt, so I''ve changed what you said to 10pt.');
      ERROR;
      S := 10*65536;
    END;
    {:1259}

  END ELSE IF scan_keyword('scaled') THEN BEGIN
    SCANINT;
    S := -CURVAL;
    IF (CURVAL<=0)OR(CURVAL>32768) THEN BEGIN
      print_err('Illegal magnification has been changed to 1000 (' + print_int(CURVAL) + ')');
      help1('The magnification ratio must be between 1 and 32768.');
      ERROR;
      S := -1000;
    END;
  END ELSE S := -1000;
  NAMEINPROGRE := FALSE;
{:1258}

  F := FindFont(U, FileNameArea, S);

  EQTB[U].HH.RH := F;
  EQTB[2624+F] := EQTB[U];
  HASH[2624+F].RH := T;
END;
{:1257}







{ ----------------------------------------------------------------------
  Debugging
  ---------------------------------------------------------------------- }


{$IFDEF DEBUGGING}

VAR
  FREE: PACKED ARRAY[MEMMIN..MEMMAX] OF BOOLEAN;
  WASFREE: PACKED ARRAY[MEMMIN..MEMMAX] OF BOOLEAN;
  WASMEMEND,WASLOMAX,WASHIMIN: HALFWORD;
  PANICKING: BOOLEAN;




PROCEDURE CHECKMEM(PRINTLOCS:BOOLEAN);
LABEL 31,32;
VAR P,Q: HALFWORD;
  CLOBBERED: BOOLEAN;
BEGIN
  FOR P:=MEMMIN TO LOMEMMAX DO
    FREE[P] := FALSE;
  FOR P:=HIMEMMIN TO MEMEND DO
    FREE[P] := FALSE;{168:}
  P := AVAIL;
  Q := 0;
  CLOBBERED := FALSE;
  WHILE P<>0 DO
    BEGIN
      IF (P>MEMEND)OR(P<HIMEMMIN)THEN CLOBBERED := TRUE
      ELSE
        IF FREE[P]THEN CLOBBERED := TRUE;
      IF CLOBBERED THEN
        BEGIN
          print_nl_str('AVAIL list clobbered at ');
          PRINTINT(Q);
          GOTO 31;
        END;
      FREE[P] := TRUE;
      Q := P;
      P := MEM[Q].HH.RH;
    END;
  31:{:168};{169:}
  P := ROVER;
  Q := 0;
  CLOBBERED := FALSE;
  REPEAT
    IF (P>=LOMEMMAX)OR(P<MEMMIN)THEN CLOBBERED := TRUE
    ELSE
      IF (MEM[P+1].
         HH.RH>=LOMEMMAX)OR(MEM[P+1].HH.RH<MEMMIN)THEN CLOBBERED := TRUE
    ELSE
      IF 
         NOT((MEM[P].HH.RH=65535))OR(MEM[P].HH.LH<2)OR(P+MEM[P].HH.LH>LOMEMMAX)OR
         (MEM[MEM[P+1].HH.RH+1].HH.LH<>P)THEN CLOBBERED := TRUE;
    IF CLOBBERED THEN
      BEGIN
        print_nl_str('Double-AVAIL list clobbered at ');
        PRINTINT(Q);
        GOTO 32;
      END;
    FOR Q:=P TO P+MEM[P].HH.LH-1 DO
      BEGIN
        IF FREE[Q]THEN
          BEGIN
            print_nl_str('Doubly free location at ');
            PRINTINT(Q);
            GOTO 32;
          END;
        FREE[Q] := TRUE;
      END;
    Q := P;
    P := MEM[P+1].HH.RH;
  UNTIL P=ROVER;
  32:{:169};{170:}
  P := MEMMIN;
  WHILE P<=LOMEMMAX DO
    BEGIN
      IF (MEM[P].HH.RH=65535)THEN
        BEGIN
          print_nl_str('Bad flag at ')
          ;
          PRINTINT(P);
        END;
      WHILE (P<=LOMEMMAX)AND NOT FREE[P] DO
        P := P+1;
      WHILE (P<=LOMEMMAX)AND FREE[P] DO
        P := P+1;
    END{:170};
  IF PRINTLOCS THEN{171:}
    BEGIN
      print_nl_str('New busy locs:');
      FOR P:=MEMMIN TO LOMEMMAX DO
        IF NOT FREE[P]AND((P>WASLOMAX)OR WASFREE[P]
           )THEN
          BEGIN
            PRINTCHAR(32);
            PRINTINT(P);
          END;
      FOR P:=HIMEMMIN TO MEMEND DO
        IF NOT FREE[P]AND((P<WASHIMIN)OR(P>
           WASMEMEND)OR WASFREE[P])THEN
          BEGIN
            PRINTCHAR(32);
            PRINTINT(P);
          END;
    END{:171};
  FOR P:=MEMMIN TO LOMEMMAX DO
    WASFREE[P] := FREE[P];
  FOR P:=HIMEMMIN TO MEMEND DO
    WASFREE[P] := FREE[P];
  WASMEMEND := MEMEND;
  WASLOMAX := LOMEMMAX;
  WASHIMIN := HIMEMMIN;
END;

PROCEDURE SEARCHMEM(P:HALFWORD);
VAR Q: Int32;
BEGIN
  FOR Q:=MEMMIN TO LOMEMMAX DO
    BEGIN
      IF MEM[Q].HH.RH=P THEN
        BEGIN
          print_nl_str('LINK(');
          PRINTINT(Q);
          PRINTCHAR(41);
        END;
      IF MEM[Q].HH.LH=P THEN
        BEGIN
          print_nl_str('INFO(');
          PRINTINT(Q);
          PRINTCHAR(41);
        END;
    END;
  FOR Q:=HIMEMMIN TO MEMEND DO
    BEGIN
      IF MEM[Q].HH.RH=P THEN
        BEGIN
          print_nl_str('LINK(');
          PRINTINT(Q);
          PRINTCHAR(41);
        END;
      IF MEM[Q].HH.LH=P THEN
        BEGIN
          print_nl_str('INFO(');
          PRINTINT(Q);
          PRINTCHAR(41);
        END;
    END;
{255:}
  FOR Q:=1 TO 3933 DO
    BEGIN
      IF EQTB[Q].HH.RH=P THEN
        BEGIN
          print_nl_str('EQUIV(');
          PRINTINT(Q);
          PRINTCHAR(41);
        END;
    END{:255};
{285:}
  IF SAVEPTR>0 THEN FOR Q:=0 TO SAVEPTR-1 DO
                      BEGIN
                        IF SAVESTACK[Q].
                           HH.RH=P THEN
                          BEGIN
                            print_nl_str('SAVE(');
                            PRINTINT(Q);
                            PRINTCHAR(41);
                          END;
                      END{:285};
{933:}
  FOR Q:=0 TO 307 DO
    BEGIN
      IF HYPHLIST[Q]=P THEN
        BEGIN
          print_nl_str('HYPH(');
          PRINTINT(Q);
          PRINTCHAR(41);
        END;
    END{:933};
END;

PROCEDURE PRINTWORD(W:MEMORYWORD);
BEGIN
  PRINTINT(W.INT);
  PRINTCHAR(32);
  print_str(print_scaled(W.INT));
  PRINTCHAR(32);
  print_str(print_scaled(ISORound(65536*W.GR)));
  PRINTLN;
  PRINTINT(W.HH.LH);
  PRINTCHAR(61);
  PRINTINT(W.HH.B0);
  PRINTCHAR(58);
  PRINTINT(W.HH.B1);
  PRINTCHAR(59);
  PRINTINT(W.HH.RH);
  PRINTCHAR(32);
  PRINTINT(W.QQQQ.B0);
  PRINTCHAR(58);
  PRINTINT(W.QQQQ.B1);
  PRINTCHAR(58);
  PRINTINT(W.QQQQ.B2);
  PRINTCHAR(58);
  PRINTINT(W.QQQQ.B3);
END;

PROCEDURE DEBUGHELP;
LABEL 888;
VAR K,L,M,N: Int32;
BEGIN;
  WHILE TRUE DO BEGIN
      print_nl_str('debug # (-1 to exit):');
      FLUSH(OUTPUT);
      READ(INPUT,M);
      IF M<0 THEN exit
      ELSE
        IF M=0 THEN
          BEGIN
            GOTO 888;
            888: M := 0;
{'BREAKPOINT'}
          END
      ELSE
        BEGIN
          READ(INPUT,N);
          CASE M OF {1339:}
            1: PRINTWORD(MEM[N]);
            2: PRINTINT(MEM[N].HH.LH);
            3: PRINTINT(MEM[N].HH.RH);
            4: PRINTWORD(EQTB[N]);
            5: PRINTWORD(FONTINFO[N]);
            6: PRINTWORD(SAVESTACK[N]);
            7: SHOWBOX(N);
            8: BEGIN
                 BREADTHMAX := 10000;
                 DEPTHTHRESHO := POOLSIZE-POOLPTR-10;
                 SHOWNODELIST(N);
               END;
            9: print_utf8str(show_token_list_simple(N,1000));
            10: SLOWPRINT(N);
            11: CHECKMEM(N>0);
            12: SEARCHMEM(N);
            13:
                BEGIN
                  READ(INPUT,L);
                  print_str(print_cmd_chr(N,L));
                END;
            14: FOR K:=0 TO N DO
                  slow_print_char(BUFFER[K]);
            15:
                BEGIN
                  FONTINSHORTD := 0;
                  SHORTDISPLAY(N);
                END;
            16: PANICKING := NOT PANICKING;
            ELSE PRINTCHAR(63)
          END;
        END;
    END;
END;
{$ENDIF}







{ ----------------------------------------------------------------------
  Main loop
  ---------------------------------------------------------------------- }



{1265:}
PROCEDURE NEWINTERACTI;
BEGIN
  PRINTLN;
  INTERACTION := CURCHR;
  IF INTERACTION=0 THEN SELECTOR := 16
                   ELSE SELECTOR := 17;
  IF LOGOPENED THEN SELECTOR := SELECTOR+2;
END;
{:1265}

PROCEDURE PREFIXEDCOMM;
VAR
  A: SMALLNUMBER;
  F: INTERNALFONT;
  J: HALFWORD;
  K: FONTINDEX;
  P,Q: HALFWORD;
  N: Int32;
  E: BOOLEAN;
BEGIN
  A := 0;
  WHILE CURCMD=93 DO BEGIN
    IF NOT ODD(A DIV CURCHR) THEN A := A+CURCHR;
    {404:}
    REPEAT
      GETXTOKEN;
    UNTIL (CURCMD<>10)AND(CURCMD<>0){:404};
    IF CURCMD<=70 THEN BEGIN
      {1212:}
      print_err('You can''t use a prefix with `' + print_cmd_chr(CURCMD, CURCHR) + '''');
      help1('I''ll pretend you didn''t say \long or \outer or \global.');
      BACKERROR;
      exit;
      {:1212}
    END;
  END;

  {1213:}
  IF (CURCMD<>97) AND (A MOD 4<>0) THEN BEGIN
    print_err('You can''t use `' + print_esc('long') + ''' or `' 
      + print_esc('outer') + ''' with `' + print_cmd_chr(CURCMD, CURCHR) + '''');
    help1('I''ll pretend you didn''t say \long or \outer here.');
    ERROR;
  END;
  {:1213}

  {1214:}
  IF EQTB[5306].INT<>0 THEN
    IF EQTB[5306].INT<0 THEN
      BEGIN
        IF (A>=4)
          THEN A := A-4;
      END
  ELSE
    BEGIN
      IF NOT(A>=4)THEN A := A+4;
    END{:1214};
  CASE CURCMD OF {1217:}
    87:
        IF (A>=4)THEN GEQDEFINE(3934,120,CURCHR)
        ELSE
          EQDEFINE(3934,120,CURCHR);
{:1217}{1218:}
    97:
        BEGIN
          IF ODD(CURCHR)AND NOT(A>=4)AND(EQTB[5306].INT>=0)
            THEN A := A+4;
          E := (CURCHR>=2);
          GETRTOKEN;
          P := CURCS;
          Q := SCANTOKS(TRUE,E);
          IF (A>=4)THEN GEQDEFINE(P,111+(A MOD 4),DEFREF)
          ELSE EQDEFINE(P,111+(A MOD
                        4),DEFREF);
        END;{:1218}{1221:}
    94:
        BEGIN
          N := CURCHR;
          GETRTOKEN;
          P := CURCS;
          IF N=0 THEN
            BEGIN
              REPEAT
                GETTOKEN;
              UNTIL CURCMD<>10;
              IF CURTOK=3133 THEN
                BEGIN
                  GETTOKEN;
                  IF CURCMD=10 THEN GETTOKEN;
                END;
            END
          ELSE
            BEGIN
              GETTOKEN;
              Q := CURTOK;
              GETTOKEN;
              BACKINPUT;
              CURTOK := Q;
              BACKINPUT;
            END;
          IF CURCMD>=111 THEN MEM[CURCHR].HH.LH := MEM[CURCHR].HH.LH+1;
          IF (A>=4)THEN GEQDEFINE(P,CURCMD,CURCHR)
          ELSE EQDEFINE(P,CURCMD,CURCHR);
        END;{:1221}{1224:}
    95:
        BEGIN
          N := CURCHR;
          GETRTOKEN;
          P := CURCS;
          IF (A>=4)THEN GEQDEFINE(P,0,256)
          ELSE EQDEFINE(P,0,256);
          SCANOPTIONAL;
          CASE N OF 
            0:
               BEGIN
                 SCANCHARNUM;
                 IF (A>=4)THEN GEQDEFINE(P,68,CURVAL)
                 ELSE EQDEFINE(P,68,CURVAL);
               END;
            1:
               BEGIN
                 SCANFIFTEENB;
                 IF (A>=4)THEN GEQDEFINE(P,69,CURVAL)
                 ELSE EQDEFINE(P,69,CURVAL);
               END;
            ELSE
              BEGIN
                SCANEIGHTBIT;
                CASE N OF 
                  2:
                     IF (A>=4)THEN GEQDEFINE(P,73,5318+CURVAL)
                     ELSE EQDEFINE(P,73,
                                   5318+CURVAL);
                  3:
                     IF (A>=4)THEN GEQDEFINE(P,74,5851+CURVAL)
                     ELSE EQDEFINE(P,74,5851+CURVAL
                       );
                  4:
                     IF (A>=4)THEN GEQDEFINE(P,75,2900+CURVAL)
                     ELSE EQDEFINE(P,75,2900+CURVAL
                       );
                  5:
                     IF (A>=4)THEN GEQDEFINE(P,76,3156+CURVAL)
                     ELSE EQDEFINE(P,76,3156+CURVAL
                       );
                  6:
                     IF (A>=4)THEN GEQDEFINE(P,72,3422+CURVAL)
                     ELSE EQDEFINE(P,72,3422+CURVAL
                       );
                END;
              END
          END;
        END;{:1224}

{1225:}
    96:
        BEGIN
          SCANINT;
          N := CURVAL;
          IF NOT scan_keyword('to')THEN BEGIN
            print_err('Missing `to'' inserted');
            help2('You should have said `\read<number> to \cs''.',
                  'I''m going to look for the \cs now.');
            ERROR;
          END;
          GETRTOKEN;
          P := CURCS;
          READTOKS(N,P);
          IF (A>=4) THEN GEQDEFINE(P,111,CURVAL)
                    ELSE EQDEFINE(P,111,CURVAL);
        END;
{:1225}
{1226:}
    71,72:
        BEGIN
          Q := CURCS;
          IF CURCMD=71 THEN BEGIN
            SCANEIGHTBIT;
            P := 3422+CURVAL;
          END ELSE P := CURCHR;
          SCANOPTIONAL;
          {404:}
          REPEAT
            GETXTOKEN;
          UNTIL (CURCMD<>10)AND(CURCMD<>0);
          {:404}
          IF CURCMD=71 THEN BEGIN
            SCANEIGHTBIT;
            CURCMD := 72;
            CURCHR := 3422+CURVAL;
          END;

          if CURCMD=72 then begin
            Q := EQTB[CURCHR].HH.RH;
            IF Q=0 THEN
              IF (A>=4) THEN GEQDEFINE(P, 101, 0)
                        ELSE  EQDEFINE(P, 101, 0)
            ELSE BEGIN
              MEM[Q].HH.LH := MEM[Q].HH.LH+1;
              IF (A>=4) THEN GEQDEFINE(P, 111, Q)
                        ELSE  EQDEFINE(P, 111, Q);
            END;
          end else begin
            BACKINPUT;
            CURCS := Q;
            Q := SCANTOKS(FALSE,FALSE);
            IF MEM[DEFREF].HH.RH=0 THEN BEGIN
              IF (A>=4) THEN GEQDEFINE(P, 101, 0)
                        ELSE  EQDEFINE(P, 101, 0);
              BEGIN
                MEM[DEFREF].HH.RH := AVAIL;
                AVAIL := DEFREF;
{$IFDEF STATS}
                DYNUSED := DYNUSED-1;
{$ENDIF}
              END;
            END ELSE BEGIN
              IF P=3413 THEN BEGIN
                MEM[Q].HH.RH := GETAVAIL;
                Q := MEM[Q].HH.RH;
                MEM[Q].HH.LH := 637;
                Q := GETAVAIL;
                MEM[Q].HH.LH := 379;
                MEM[Q].HH.RH := MEM[DEFREF].HH.RH;
                MEM[DEFREF].HH.RH := Q;
              END;
              IF (A>=4) THEN GEQDEFINE(P, 111, DEFREF)
                        ELSE  EQDEFINE(P, 111, DEFREF);
            END;
          end;
        END;
{:1226}{1228:}
    73:
        BEGIN
          P := CURCHR;
          SCANOPTIONAL;
          SCANINT;
          IF (A>=4)THEN GEQWORDDEFIN(P,CURVAL)
          ELSE EQWORDDEFINE(P,CURVAL);
        END;
    74:
        BEGIN
          P := CURCHR;
          SCANOPTIONAL;
          SCANDIMEN(FALSE,FALSE,FALSE);
          IF (A>=4)THEN GEQWORDDEFIN(P,CURVAL)
          ELSE EQWORDDEFINE(P,CURVAL);
        END;
    75,76:
           BEGIN
             P := CURCHR;
             N := CURCMD;
             SCANOPTIONAL;
             IF N=76 THEN SCANGLUE(3)
             ELSE SCANGLUE(2);
             TRAPZEROGLUE;
             IF (A>=4)THEN GEQDEFINE(P,117,CURVAL)
             ELSE EQDEFINE(P,117,CURVAL);
           END;
{:1228}{1232:}
    85:
        BEGIN{1233:}
          IF CURCHR=3983 THEN N := 15
          ELSE IF CURCHR=5007 THEN N := 32768
          ELSE IF CURCHR=4751 THEN N := 32767
          ELSE IF CURCHR=5574 THEN N := 16777215
          ELSE N := 255{:1233};
          P := CURCHR;
          SCANCHARNUM;
          P := P+CURVAL;
          SCANOPTIONAL;
          SCANINT;
          IF ((CURVAL<0)AND(P<5574))OR(CURVAL>N)THEN BEGIN
            IF P<5574 THEN begin
              print_err('Invalid code (' + print_int(CURVAL)
                + '), should be in the range 0..' + print_int(N));
              help1('I''m going to use 0 instead of that illegal code value.');
              ERROR;
            end else begin
              print_err('Invalid code (' + print_int(CURVAL)
                + '), should be at most ' + print_int(N));
              help1('I''m going to use 0 instead of that illegal code value.');
              ERROR;
            end;
            CURVAL := 0;
          END;
          IF P<5007 THEN
            IF (A>=4) THEN GEQDEFINE(P, 120, CURVAL)
                      ELSE  EQDEFINE(P, 120, CURVAL)
          ELSE IF P<5574 THEN
            IF (A>=4) THEN GEQDEFINE(P, 120, CURVAL)
                      ELSE  EQDEFINE(P, 120, CURVAL)
          ELSE
            IF (A>=4) THEN GEQWORDDEFIN(P, CURVAL)
                      ELSE EQWORDDEFINE(P, CURVAL);
        END;{:1232}{1234:}
    86:
        BEGIN
          P := CURCHR;
          SCANFOURBITI;
          P := P+CURVAL;
          SCANOPTIONAL;
          SCANFONTIDEN;
          IF (A>=4)THEN GEQDEFINE(P,120,CURVAL)
          ELSE EQDEFINE(P,120,CURVAL);
        END;
{:1234}{1235:}
    89,90,91,92: DOREGISTERCO(A);
{:1235}{1241:}
    98:
        BEGIN
          SCANEIGHTBIT;
          IF (A>=4)THEN N := 256+CURVAL
          ELSE N := CURVAL;
          SCANOPTIONAL;
          IF SETBOXALLOWE THEN SCANBOX(1073741824+N)
          ELSE BEGIN
            print_err('Improper ' + print_esc('setbox'));
            help2('Sorry, \setbox is not allowed after \halign in a display,',
                  'or between \accent and an accented character.');
            ERROR;
          END;
        END;
{:1241}{1242:}
    79: ALTERAUX;
    80: ALTERPREVGRA;
    81: ALTERPAGESOF;
    82: ALTERINTEGER;
    83: ALTERBOXDIME;{:1242}{1248:}
    84:
        BEGIN
          SCANOPTIONAL;
          SCANINT;
          N := CURVAL;
          IF N<=0 THEN P := 0
          ELSE
            BEGIN
              P := GETNODE(2*N+1);
              MEM[P].HH.LH := N;
              FOR J:=1 TO N DO
                BEGIN
                  SCANDIMEN(FALSE,FALSE,FALSE);
                  MEM[P+2*J-1].INT := CURVAL;
                  SCANDIMEN(FALSE,FALSE,FALSE);
                  MEM[P+2*J].INT := CURVAL;
                END;
            END;
          IF (A>=4)THEN GEQDEFINE(3412,118,P)
          ELSE EQDEFINE(3412,118,P);
        END;
{:1248}{1252:}
    99:
        IF CURCHR=1 THEN BEGIN
{$IFDEF INITEX}
          NEWPATTERNS;
{$ELSE}
          print_err('Patterns can be loaded only by INITEX');
          HELPPTR := 0;
          ERROR;
          REPEAT
            GETTOKEN;
          UNTIL CURCMD=2;
          exit;
{$ENDIF}
        END ELSE BEGIN
          NEWHYPHEXCEP;
        END;
{:1252}
{1253:}
    77:
        BEGIN
          FINDFONTDIME(TRUE);
          K := CURVAL;
          SCANOPTIONAL;
          SCANDIMEN(FALSE,FALSE,FALSE);
          FONTINFO[K].INT := CURVAL;
        END;
    78:
        BEGIN
          N := CURCHR;
          SCANFONTIDEN;
          F := CURVAL;
          SCANOPTIONAL;
          SCANINT;
          IF N=0 THEN HYPHENCHAR[F] := CURVAL
          ELSE SKEWCHAR[F] := CURVAL;
        END;
{:1253}
{1256:}
    88: NEWFONT(A);
{:1256}
{1264:}
    100: NEWINTERACTI;
{:1264}
    ELSE confusion_str('prefix')
  END;

  {1269:}
  IF AFTERTOKEN<>0 THEN BEGIN
    CURTOK := AFTERTOKEN;
    BACKINPUT;
    AFTERTOKEN := 0;
  END
  {:1269};
END;
{:1211}

{1270:}
PROCEDURE DOASSIGNMENT;
BEGIN
  WHILE TRUE DO
    BEGIN{404:}
      REPEAT
        GETXTOKEN;
      UNTIL (CURCMD<>10)AND(CURCMD<>0){:404};
      IF CURCMD<=70 THEN exit;
      SETBOXALLOWE := FALSE;
      PREFIXEDCOMM;
      SETBOXALLOWE := TRUE;
    END;
END;
{:1270}

{1275:}
PROCEDURE OPENORCLOSEI;
VAR
  C: 0..1;
  N: 0..15;
  FileName: shortstring;
BEGIN
  C := CURCHR;
  SCANFOURBITI;
  N := CURVAL;
  IF READOPEN[N]<>2 THEN BEGIN
    close(READFILE[N]);
    READOPEN[N] := 2;
  END;
  IF C<>0 THEN BEGIN
    SCANOPTIONAL;
    FileName := scan_file_name;
    if a_open_in(READFILE[N], FileName) then READOPEN[N] := 1;
  END;
END;
{:1275}

{1279:}
PROCEDURE ISSUEMESSAGE;
VAR
  C: 0..1;
  s: utf8string;
BEGIN
  C := CURCHR;
  MEM[29988].HH.RH := SCANTOKS(FALSE,TRUE);

  if DEFREF<>0 then s := show_token_list_simple(MEM[DEFREF].HH.RH,10000000)
               else s := '';
  FLUSHLIST(DEFREF);

  IF C=0 THEN BEGIN
    {1280:}
    IF TERMOFFSET+length(s) > MAXPRINTLINE-2 THEN PRINTLN
    ELSE IF (TERMOFFSET>0) OR (FILEOFFSET>0) THEN PRINTCHAR(32);
    slow_print_utf8str(s);
    FLUSH(OUTPUT);
    {:1280}
  END ELSE BEGIN
    {1283:}
    print_err(s);
    IF EQTB[3421].HH.RH<>0 THEN USEERRHELP := TRUE
    ELSE IF LONGHELPSEEN THEN BEGIN
      help1('(That was another \errmessage.)');
    END ELSE BEGIN
      IF INTERACTION<3 THEN LONGHELPSEEN := TRUE;
      help4('This error message was generated by an \errmessage',
            'command, so I can''t give any explicit help.',
            'Pretend that you''re Hercule Poirot: Examine all clues,',
            'and deduce the truth by order and method.');
    END;
    ERROR;
    USEERRHELP := FALSE;
    {:1283}
  END;
END;
{:1279}

{1288:}
PROCEDURE SHIFTCASE;

VAR B: HALFWORD;
  P: HALFWORD;
  T: HALFWORD;
  C: EIGHTBITS;
BEGIN
  B := CURCHR;
  P := SCANTOKS(FALSE,FALSE);
  P := MEM[DEFREF].HH.RH;
  WHILE P<>0 DO BEGIN
    {1289:}
    T := MEM[P].HH.LH;
    IF T<4352 THEN BEGIN
      C := T MOD 256;
      IF EQTB[B+C].HH.RH<>0 THEN MEM[P].HH.LH := T-C+EQTB[B+C].HH.RH;
    END;
    {:1289}
    P := MEM[P].HH.RH;
  END;
  BEGINTOKENLI(MEM[DEFREF].HH.RH,3);
  BEGIN
    MEM[DEFREF].HH.RH := AVAIL;
    AVAIL := DEFREF;
{$IFDEF STATS}
    DYNUSED := DYNUSED-1;
{$ENDIF}
  END;
END;
{:1288}

{1293:}
PROCEDURE SHOWACTIVITI;
VAR P: 0..NESTSIZE;
  M: -203..203;
  A: MEMORYWORD;
  Q,R: HALFWORD;
  T: Int32;
BEGIN
  NEST[NESTPTR] := CURLIST;
  print_nl_str('');
  PRINTLN;
  FOR P:=NESTPTR DOWNTO 0 DO
    BEGIN
      M := NEST[P].MODEFIELD;
      A := NEST[P].AUXFIELD;
      print_nl_str('### ' + print_mode(M) + ' entered at line ' + print_int(ABS(NEST[P].MLFIELD)));
      IF M=102 THEN
        IF NEST[P].PGFIELD<>8585216 THEN
          BEGIN
            print_str(' (language');
            PRINTINT(NEST[P].PGFIELD MOD 65536);
            print_str(':hyphenmin');
            PRINTINT(NEST[P].PGFIELD DIV 4194304);
            PRINTCHAR(44);
            PRINTINT((NEST[P].PGFIELD DIV 65536)MOD 64);
            PRINTCHAR(41);
          END;
      IF NEST[P].MLFIELD<0 THEN print_str(' (\output routine)');
      IF P=0 THEN
        BEGIN{986:}
          IF 29998<>PAGETAIL THEN
            BEGIN
              print_nl_str('### current page:');
              IF OUTPUTACTIVE THEN print_str(' (held over for next output)');
              SHOWBOX(MEM[29998].HH.RH);
              IF PAGECONTENTS>0 THEN
                BEGIN
                  print_nl_str('total height ' + print_totals);
                  print_nl_str(' goal height ' + print_scaled(PAGESOFAR[0]));
                  R := MEM[30000].HH.RH;
                  WHILE R<>30000 DO
                    BEGIN
                      PRINTLN;
                      print_esc_str('insert');
                      T := MEM[R].HH.B1-0;
                      PRINTINT(T);
                      print_str(' adds ');
                      IF EQTB[5318+T].INT=1000 THEN T := MEM[R+3].INT
                      ELSE T := XOVERN(MEM[R+3].INT,1000)*EQTB[5318+T].INT;
                      print_str(print_scaled(T));
                      IF MEM[R].HH.B0=1 THEN
                        BEGIN
                          Q := 29998;
                          T := 0;
                          REPEAT
                            Q := MEM[Q].HH.RH;
                            IF (MEM[Q].HH.B0=3)AND(MEM[Q].HH.B1=MEM[R].HH.B1)THEN T := T+1;
                          UNTIL Q=MEM[R+1].HH.LH;
                          print_str(', #');
                          PRINTINT(T);
                          print_str(' might split');
                        END;
                      R := MEM[R].HH.RH;
                    END;
                END;
            END{:986};
          IF MEM[29999].HH.RH<>0 THEN print_nl_str('### recent contributions:');
        END;
      SHOWBOX(MEM[NEST[P].HEADFIELD].HH.RH);
{219:}
      CASE ABS(M)DIV(101) OF 
        0:
           BEGIN
             print_nl_str('prevdepth ');
             IF A.INT<=-65536000 THEN print_str('ignored')
             ELSE print_str(print_scaled(A.INT));
             IF NEST[P].PGFIELD<>0 THEN
               BEGIN
                 print_str(', prevgraf ');
                 PRINTINT(NEST[P].PGFIELD);
                 print_str(' line');
                 IF NEST[P].PGFIELD<>1 THEN PRINTCHAR(115);
               END;
           END;
        1:
           BEGIN
             print_nl_str('spacefactor ');
             PRINTINT(A.HH.LH);
             IF M>0 THEN
               IF A.HH.RH>0 THEN
                 BEGIN
                   print_str(', current language ');
                   PRINTINT(A.HH.RH);
                 END;
           END;
        2:
           IF A.INT<>0 THEN
             BEGIN
               print_str('this will begin denominator of:');
               SHOWBOX(A.INT);
             END;
      END{:219};
    END;
END;

PROCEDURE SHOWWHATEVER;
var c: HALFWORD;
BEGIN
  if (CURCHR=3) or (CURCHR=1) then begin
    if CURCHR=3 then begin
      BEGINDIAGNOS;
      SHOWACTIVITI;
    end else begin

      {1296:}
      SCANEIGHTBIT;
      BEGINDIAGNOS;
      print_nl_str('> \box');
      PRINTINT(CURVAL);
      PRINTCHAR(61);
      IF EQTB[3678+CURVAL].HH.RH=0 THEN print_str('void')
      ELSE SHOWBOX(EQTB[3678+CURVAL].HH.RH);
      {:1296}

    end;

    {1298:}
    ENDDIAGNOSTI(TRUE);
    print_err('OK');
    IF (SELECTOR=19) and (EQTB[5292].INT<=0) THEN BEGIN
      SELECTOR := 17;
      print_str(' (see the transcript file)');
      SELECTOR := 19;
    END;
    {:1298}

  end else begin
    if CURCHR=0 then begin

      {1294:}
      GETTOKEN;
      print_nl_str('> ');
      IF CURCS<>0 THEN print_str(sprint_cs(CURCS) + '=');

      {@ The |print_meaning| subroutine displays |cur_cmd| and |cur_chr| in
         symbolic form, including the expansion of a macro or mark.}
      print_str(print_cmd_chr(CURCMD, CURCHR));
      IF CURCMD>=110 THEN BEGIN
        PRINTCHAR(58);
        PRINTLN;
        c := CURCHR;
        if CURCMD=110 then c := CURMARK[CURCHR];
        if c<>0 then print_utf8str(show_token_list_simple(MEM[c].HH.RH, 10000000));
      END;
      {:1294}

    end else begin

      {1297:}
      c := THETOKS; {discard result}
      print_nl_str('> ');
      TOKENSHOW(29997);
      FLUSHLIST(MEM[29997].HH.RH);
      {:1297}

    end;
  end;

  IF INTERACTION<3 THEN BEGIN
    HELPPTR := 0;
    ERRORCOUNT := ERRORCOUNT-1;
  END ELSE IF EQTB[5292].INT>0 THEN BEGIN
    help3('This isn''t an error message; I''m just \showing something.',
          'Type `I\show...'' to show more (e.g., \show\cs,',
          '\showthe\count10, \showbox255, \showlists).');
  END ELSE BEGIN
    help5('This isn''t an error message; I''m just \showing something.',
          'Type `I\show...'' to show more (e.g., \show\cs,',
          '\showthe\count10, \showbox255, \showlists).',
          'And type `I\tracingonline=1\show...'' to show boxes and',
          'lists on your terminal as well as in the transcript file.');
  END;
  ERROR;
END;
{:1293}


{1348:}
{1349:}
PROCEDURE NEWWHATSIT(S:SMALLNUMBER;W:SMALLNUMBER);

VAR P: HALFWORD;
BEGIN
  P := GETNODE(W);
  MEM[P].HH.B0 := 8;
  MEM[P].HH.B1 := S;
  MEM[CURLIST.TAILFIELD].HH.RH := P;
  CURLIST.TAILFIELD := P;
END;
{:1349}{1350:}
PROCEDURE NEWWRITEWHAT(W:SMALLNUMBER);
BEGIN
  NEWWHATSIT(CURCHR,W);
  IF W<>2 THEN SCANFOURBITI
  ELSE
    BEGIN
      SCANINT;
      IF CURVAL<0 THEN CURVAL := 17
      ELSE
        IF CURVAL>15 THEN CURVAL := 16;
    END;
  MEM[CURLIST.TAILFIELD+1].HH.LH := CURVAL;
END;
{:1350}

PROCEDURE DOEXTENSION;
VAR
  K: Int32;
  P: HALFWORD;
BEGIN
  CASE CURCHR OF 
    0:{1351:}
       BEGIN
         NEWWRITEWHAT(3);
         SCANOPTIONAL;
(*
         SCANFILENAME;
         IF CUREXT=338{''} THEN CUREXT := 791{'.tex'};
         MEM[CURLIST.TAILFIELD+1].HH.RH := CURNAME;
         MEM[CURLIST.TAILFIELD+2].HH.LH := CURAREA;
         MEM[CURLIST.TAILFIELD+2].HH.RH := CUREXT;
*)
         MEM[CURLIST.TAILFIELD+1].HH.RH := AddString(scan_file_name);
       END{:1351};
    1:{1352:}
       BEGIN
         K := CURCS;
         NEWWRITEWHAT(2);
         CURCS := K;
         P := SCANTOKS(FALSE,FALSE);
         MEM[CURLIST.TAILFIELD+1].HH.RH := DEFREF;
       END{:1352};
    2:{1353:}
       BEGIN
         NEWWRITEWHAT(2);
         MEM[CURLIST.TAILFIELD+1].HH.RH := 0;
       END{:1353};
    3:{1354:}
       BEGIN
         NEWWHATSIT(3,2);
         MEM[CURLIST.TAILFIELD+1].HH.LH := 0;
         P := SCANTOKS(FALSE,TRUE);
         MEM[CURLIST.TAILFIELD+1].HH.RH := DEFREF;
       END{:1354};
    4:{1375:}
       BEGIN
         GETXTOKEN;
         IF (CURCMD=59)AND(CURCHR<=2)THEN
           BEGIN
             P := CURLIST.TAILFIELD;
             DOEXTENSION;
             OUTWHAT(CURLIST.TAILFIELD);
             FLUSHNODELIS(CURLIST.TAILFIELD);
             CURLIST.TAILFIELD := P;
             MEM[P].HH.RH := 0;
           END
         ELSE BACKINPUT;
       END{:1375};
    5:{1377:}
       IF ABS(CURLIST.MODEFIELD)<>102 THEN report_illegal_case
       ELSE
         BEGIN
           NEWWHATSIT(4,2);
           SCANINT;
           IF CURVAL<=0 THEN CURLIST.AUXFIELD.HH.RH := 0
           ELSE
             IF CURVAL>255 THEN
               CURLIST.AUXFIELD.HH.RH := 0
           ELSE CURLIST.AUXFIELD.HH.RH := CURVAL;
           MEM[CURLIST.TAILFIELD+1].HH.RH := CURLIST.AUXFIELD.HH.RH;
           MEM[CURLIST.TAILFIELD+1].HH.B0 := NORMMIN(EQTB[5314].INT);
           MEM[CURLIST.TAILFIELD+1].HH.B1 := NORMMIN(EQTB[5315].INT);
         END{:1377};
    ELSE confusion_str('ext1')
  END;
END;
{:1348}

{1376:}
PROCEDURE FIXLANGUAGE;

VAR L: ASCIICODE;
BEGIN
  IF EQTB[5313].INT<=0 THEN L := 0
  ELSE
    IF EQTB[5313].INT>255 THEN L := 
                                    0
  ELSE L := EQTB[5313].INT;
  IF L<>CURLIST.AUXFIELD.HH.RH THEN
    BEGIN
      NEWWHATSIT(4,2);
      MEM[CURLIST.TAILFIELD+1].HH.RH := L;
      CURLIST.AUXFIELD.HH.RH := L;
      MEM[CURLIST.TAILFIELD+1].HH.B0 := NORMMIN(EQTB[5314].INT);
      MEM[CURLIST.TAILFIELD+1].HH.B1 := NORMMIN(EQTB[5315].INT);
    END;
END;
{:1376}{1068:}
PROCEDURE HANDLERIGHTB;

VAR P,Q: HALFWORD;
  D: SCALED;
  F: Int32;
BEGIN
  CASE CURGROUP OF 
    1: UNSAVE;
    0:  BEGIN
          print_err('Too many }''s');
          help2('You''ve closed more groups than you opened.',
                'Such booboos are generally harmless, so keep going.');
          ERROR;
        END;
    14,15,16: EXTRARIGHTBR;{1085:}
    2: PACKAGE(0);
    3:
       BEGIN
         ADJUSTTAIL := 29995;
         PACKAGE(0);
       END;
    4:
       BEGIN
         ENDGRAF;
         PACKAGE(0);
       END;
    5:
       BEGIN
         ENDGRAF;
         PACKAGE(4);
       END;{:1085}{1100:}
    11:
        BEGIN
          ENDGRAF;
          Q := EQTB[2892].HH.RH;
          MEM[Q].HH.RH := MEM[Q].HH.RH+1;
          D := EQTB[5836].INT;
          F := EQTB[5305].INT;
          UNSAVE;
          SAVEPTR := SAVEPTR-1;
          P := VPACKAGE(MEM[CURLIST.HEADFIELD].HH.RH,0,1,1073741823);
          POPNEST;
          IF SAVESTACK[SAVEPTR+0].INT<255 THEN
            BEGIN
              BEGIN
                MEM[CURLIST.TAILFIELD].
                HH.RH := GETNODE(5);
                CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
              END;
              MEM[CURLIST.TAILFIELD].HH.B0 := 3;
              MEM[CURLIST.TAILFIELD].HH.B1 := SAVESTACK[SAVEPTR+0].INT+0;
              MEM[CURLIST.TAILFIELD+3].INT := MEM[P+3].INT+MEM[P+2].INT;
              MEM[CURLIST.TAILFIELD+4].HH.LH := MEM[P+5].HH.RH;
              MEM[CURLIST.TAILFIELD+4].HH.RH := Q;
              MEM[CURLIST.TAILFIELD+2].INT := D;
              MEM[CURLIST.TAILFIELD+1].INT := F;
            END
          ELSE
            BEGIN
              BEGIN
                MEM[CURLIST.TAILFIELD].HH.RH := GETNODE(2);
                CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
              END;
              MEM[CURLIST.TAILFIELD].HH.B0 := 5;
              MEM[CURLIST.TAILFIELD].HH.B1 := 0;
              MEM[CURLIST.TAILFIELD+1].INT := MEM[P+5].HH.RH;
              DELETEGLUERE(Q);
            END;
          FREENODE(P,7);
          IF NESTPTR=0 THEN BUILDPAGE;
        END;
    8:{1026:}
        BEGIN
          IF (CURINPUT.LOCFIELD<>0) OR
             ((CURINPUT.INDEXFIELD<>6)AND(CURINPUT.INDEXFIELD<>3))
          THEN BEGIN
            {1027:}
            print_err('Unbalanced output routine');
            help2('Your sneaky output routine has problematic {''s and/or }''s.',
                  'I can''t handle that very well; good luck.');
            ERROR;
            REPEAT
              GETTOKEN;
              UNTIL CURINPUT.LOCFIELD=0;
            END;
            {:1027}
            ENDTOKENLIST;
            ENDGRAF;
            UNSAVE;
            OUTPUTACTIVE := FALSE;
            INSERTPENALT := 0;

            {1028:}
            IF EQTB[3933].HH.RH<>0 THEN BEGIN
              print_err('Output routine didn''t use all of ' + print_esc('box255'));
              help3('Your \output commands should empty \box255,',
                    'e.g., by saying `\shipout\box255''.',
                    'Proceed; I''ll discard its present contents.');
              BOXERROR(255);
            END;
            {:1028}

            IF CURLIST.TAILFIELD<>CURLIST.HEADFIELD THEN BEGIN
              MEM[PAGETAIL].HH.RH := MEM[CURLIST.HEADFIELD].HH.RH;
              PAGETAIL := CURLIST.TAILFIELD;
            END;
            IF MEM[29998].HH.RH<>0 THEN BEGIN
              IF MEM[29999].HH.RH=0 THEN NEST[0].TAILFIELD := PAGETAIL;
              MEM[PAGETAIL].HH.RH := MEM[29999].HH.RH;
              MEM[29999].HH.RH := MEM[29998].HH.RH;
              MEM[29998].HH.RH := 0;
              PAGETAIL := 29998;
            END;
            POPNEST;
            BUILDPAGE;
          END;
    10: BUILDDISCRET;
    6:  BEGIN
          BACKINPUT;
          CURTOK := 6710;
          print_err('Missing ' + print_esc('cr') + ' inserted');
          help1('I''m guessing that you meant to end an alignment here.');
          INSERROR;
        END;
    7:  BEGIN
          ENDGRAF;
          UNSAVE;
          ALIGNPEEK;
        END;
    12: BEGIN
          ENDGRAF;
          UNSAVE;
          SAVEPTR := SAVEPTR-2;
          P := VPACKAGE(MEM[CURLIST.HEADFIELD].HH.RH,
                        SAVESTACK[SAVEPTR+1].INT,
                        SAVESTACK[SAVEPTR+0].INT,
                        1073741823);
          POPNEST;
          BEGIN
            MEM[CURLIST.TAILFIELD].HH.RH := NEWNOAD;
            CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
          END;
          MEM[CURLIST.TAILFIELD].HH.B0 := 29;
          MEM[CURLIST.TAILFIELD+1].HH.RH := 2;
          MEM[CURLIST.TAILFIELD+1].HH.LH := P;
        END;{:1168}{1173:}
    13: BUILDCHOICES;
{:1173}{1186:}
    9:
       BEGIN
         UNSAVE;
         SAVEPTR := SAVEPTR-1;
         MEM[SAVESTACK[SAVEPTR+0].INT].HH.RH := 3;
         P := FINMLIST(0);
         MEM[SAVESTACK[SAVEPTR+0].INT].HH.LH := P;
         IF P<>0 THEN
           IF MEM[P].HH.RH=0 THEN
             IF MEM[P].HH.B0=16 THEN
               BEGIN
                 IF MEM
                    [P+3].HH.RH=0 THEN
                   IF MEM[P+2].HH.RH=0 THEN
                     BEGIN
                       MEM[SAVESTACK[SAVEPTR
                       +0].INT].HH := MEM[P+1].HH;
                       FREENODE(P,4);
                     END;
               END
         ELSE
           IF MEM[P].HH.B0=28 THEN
             IF SAVESTACK[SAVEPTR+0].INT=CURLIST.
                TAILFIELD+1 THEN
               IF MEM[CURLIST.TAILFIELD].HH.B0=16 THEN{1187:}
                 BEGIN
                   Q := 
                        CURLIST.HEADFIELD;
                   WHILE MEM[Q].HH.RH<>CURLIST.TAILFIELD DO
                     Q := MEM[Q].HH.RH;
                   MEM[Q].HH.RH := P;
                   FREENODE(CURLIST.TAILFIELD,4);
                   CURLIST.TAILFIELD := P;
                 END{:1187};
       END;{:1186}
    ELSE confusion_str('rightbrace')
  END;
END;
{:1068}
PROCEDURE MAINCONTROL;

LABEL 60,21,70,80,90,91,92,95,100,101,110,111,112,120;

VAR T: Int32;
BEGIN
  IF EQTB[3419].HH.RH<>0 THEN BEGINTOKENLI(EQTB[3419].HH.RH,12);
60:
  GETXTOKEN;
21:
  {1031:}
  IF INTERRUPT<>0 THEN
    IF OKTOINTERRUP THEN
  BEGIN
    BACKINPUT;
    IF INTERRUPT<>0 THEN PAUSEFORINST;
    GOTO 60;
  END;

{$IFDEF DEBUGGING}
  IF PANICKING THEN CHECKMEM(FALSE);
{$ENDIF}
  IF EQTB[5299].INT>0 THEN SHOWCURCMDCH{:1031};
  CASE ABS(CURLIST.MODEFIELD)+CURCMD OF 
    113,
    114,
    170:  GOTO 70;
    118:  BEGIN
            SCANCHARNUM;
            CURCHR := CURVAL;
            GOTO 70;
          END;
    167:  BEGIN
            GETXTOKEN;
            IF (CURCMD=11)OR(CURCMD=12)OR(CURCMD=68)OR(CURCMD=16) 
            THEN CANCELBOUNDA := TRUE;
            GOTO 21;
          END;
    112:  IF CURLIST.AUXFIELD.HH.LH=1000 THEN GOTO 120
                                         ELSE APPSPACE;
    166,
    267:  GOTO 120;
    1,
    102,
    203,
    11,
    213,
    268:;
    40,
    141,
    242:  BEGIN
            {406:}
            REPEAT
              GETXTOKEN;
            UNTIL CURCMD<>10;
            {:406}
            GOTO 21;
          END;
    15:
        IF ITSALLOVER THEN exit;
{1048:}
    23,123,224,71,172,273,{:1048}{1098:}39,{:1098}{1111:}45,{:1111}
{1144:}49,150,{:1144}7,108,209: report_illegal_case;
{1046:}
    8,109,9,110,18,119,70,171,51,152,16,117,50,151,53,154,67,168,54,
    155,55,156,57,158,56,157,31,132,52,153,29,130,47,148,212,216,217,230,227
    ,236,239{:1046}: INSERTDOLLAR;
{1056:}
    37,137,238:
                BEGIN
                  BEGIN
                    MEM[CURLIST.TAILFIELD].HH.RH := SCANRULESPEC
                    ;
                    CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
                  END;
                  IF ABS(CURLIST.MODEFIELD)=1 THEN CURLIST.AUXFIELD.INT := -65536000
                  ELSE
                    IF 
                       ABS(CURLIST.MODEFIELD)=102 THEN CURLIST.AUXFIELD.HH.LH := 1000;
                END;
{:1056}{1057:}
    28,128,229,231: APPENDGLUE;
    30,131,232,233: APPENDKERN;
{:1057}{1063:}
    2,103: NEWSAVELEVEL(1);
    62,163,264: NEWSAVELEVEL(14);
    63,164,265:
                IF CURGROUP=14 THEN UNSAVE
                ELSE OFFSAVE;
{:1063}{1067:}
    3,104,205: HANDLERIGHTB;
{:1067}{1073:}
    22,124,225:
                BEGIN
                  T := CURCHR;
                  SCANDIMEN(FALSE,FALSE,FALSE);
                  IF T=0 THEN SCANBOX(CURVAL)
                  ELSE SCANBOX(-CURVAL);
                END;
    32,133,234: SCANBOX(1073742237+CURCHR);
    21,122,223: BEGINBOX(0);
{:1073}{1090:}
    44: NEWGRAF(CURCHR>0);
    12,13,17,69,4,24,36,46,48,27,34,65,66:
                                           BEGIN
                                             BACKINPUT;
                                             NEWGRAF(TRUE);
                                           END;
{:1090}{1092:}
    145,246: INDENTINHMOD;{:1092}{1094:}
    14:
        BEGIN
          NORMALPARAGR;
          IF CURLIST.MODEFIELD>0 THEN BUILDPAGE;
        END;
    115:
         BEGIN
           IF ALIGNSTATE<0 THEN OFFSAVE;
           ENDGRAF;
           IF CURLIST.MODEFIELD=1 THEN BUILDPAGE;
         END;
    116,129,138,126,134: HEADFORVMODE;
{:1094}{1097:}
    38,139,240,140,241: BEGININSERTO;
    19,120,221: MAKEMARK;
{:1097}{1102:}
    43,144,245: APPENDPENALT;
{:1102}{1104:}
    26,127,228: DELETELAST;{:1104}{1109:}
    25,125,226: UNPACKAGE;
{:1109}{1112:}
    146: APPENDITALIC;
    247:
         BEGIN
           MEM[CURLIST.TAILFIELD].HH.RH := NEWKERN(0);
           CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
         END;
{:1112}{1116:}
    149,250: APPENDDISCRE;{:1116}{1122:}
    147: MAKEACCENT;
{:1122}{1126:}
    6,107,208,5,106,207: ALIGNERROR;
    35,136,237: NOALIGNERROR;
    64,165,266: OMITERROR;{:1126}{1130:}
    33,135: INITALIGN;
    235:
         IF PRIVILEGED THEN
           IF CURGROUP=15 THEN INITALIGN
         ELSE OFFSAVE;
    10,111: DOENDV;{:1130}{1134:}
    68,169,270: CSERROR;
{:1134}{1137:}
    105: INITMATH;
{:1137}{1140:}
    251:
         IF PRIVILEGED THEN
           IF CURGROUP=15 THEN STARTEQNO
         ELSE
           OFFSAVE;
{:1140}{1150:}
    204:
         BEGIN
           BEGIN
             MEM[CURLIST.TAILFIELD].HH.RH := NEWNOAD;
             CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
           END;
           BACKINPUT;
           SCANMATH(CURLIST.TAILFIELD+1);
         END;
{:1150}{1154:}
    214,215,271: SETMATHCHAR(EQTB[5007+CURCHR].HH.RH-0);
    219:
         BEGIN
           SCANCHARNUM;
           CURCHR := CURVAL;
           SETMATHCHAR(EQTB[5007+CURCHR].HH.RH-0);
         END;
    220:
         BEGIN
           SCANFIFTEENB;
           SETMATHCHAR(CURVAL);
         END;
    272: SETMATHCHAR(CURCHR);
    218:
         BEGIN
           SCANTWENTYSE;
           SETMATHCHAR(CURVAL DIV 4096);
         END;
{:1154}{1158:}
    253:
         BEGIN
           BEGIN
             MEM[CURLIST.TAILFIELD].HH.RH := NEWNOAD;
             CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
           END;
           MEM[CURLIST.TAILFIELD].HH.B0 := CURCHR;
           SCANMATH(CURLIST.TAILFIELD+1);
         END;
    254: MATHLIMITSWI;{:1158}{1162:}
    269: MATHRADICAL;
{:1162}{1164:}
    248,249: MATHAC;{:1164}{1167:}
    259:
         BEGIN
           SCANSPEC(12,FALSE);
           NORMALPARAGR;
           PUSHNEST;
           CURLIST.MODEFIELD := -1;
           CURLIST.AUXFIELD.INT := -65536000;
           IF EQTB[3418].HH.RH<>0 THEN BEGINTOKENLI(EQTB[3418].HH.RH,11);
         END;
{:1167}{1171:}
    256:
         BEGIN
           MEM[CURLIST.TAILFIELD].HH.RH := NEWSTYLE(CURCHR);
           CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
         END;
    258:
         BEGIN
           BEGIN
             MEM[CURLIST.TAILFIELD].HH.RH := NEWGLUE(0);
             CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
           END;
           MEM[CURLIST.TAILFIELD].HH.B1 := 98;
         END;
    257: APPENDCHOICE;
{:1171}{1175:}
    211,210: SUBSUP;{:1175}{1180:}
    255: MATHFRACTION;
{:1180}{1190:}
    252: MATHLEFTRIGH;
{:1190}{1193:}
    206:
         IF CURGROUP=15 THEN AFTERMATH
         ELSE OFFSAVE;
{:1193}{1210:}
    72,173,274,73,174,275,74,175,276,75,176,277,76,177,278,77,
    178,279,78,179,280,79,180,281,80,181,282,81,182,283,82,183,284,83,184,
    285,84,185,286,85,186,287,86,187,288,87,188,289,88,189,290,89,190,291,90
    ,191,292,91,192,293,92,193,294,93,194,295,94,195,296,95,196,297,96,197,
    298,97,198,299,98,199,300,99,200,301,100,201,302,101,202,303:
                                                                  PREFIXEDCOMM;{:1210}{1268:}
    41,142,243:
                BEGIN
                  GETTOKEN;
                  AFTERTOKEN := CURTOK;
                END;{:1268}{1271:}
    42,143,244:
                BEGIN
                  GETTOKEN;
                  SAVEFORAFTER(CURTOK);
                END;
{:1271}{1274:}
    61,162,263: OPENORCLOSEI;
{:1274}{1276:}
    59,160,261: ISSUEMESSAGE;
{:1276}{1285:}
    58,159,260: SHIFTCASE;
{:1285}{1290:}
    20,121,222: SHOWWHATEVER;
{:1290}{1347:}
    60,161,262: DOEXTENSION;{:1347}{:1045}
  END;
  GOTO 60;
  70:{1034:}MAINS := EQTB[4751+CURCHR].HH.RH;
  IF MAINS=1000 THEN CURLIST.AUXFIELD.HH.LH := 1000
  ELSE
    IF MAINS<1000 THEN
      BEGIN
        IF MAINS>0 THEN CURLIST.AUXFIELD.HH.LH := MAINS;
      END
  ELSE
    IF CURLIST.AUXFIELD.HH.LH<1000 THEN CURLIST.AUXFIELD.HH.LH := 
                                                                  1000
  ELSE CURLIST.AUXFIELD.HH.LH := MAINS;
  MAINF := EQTB[3934].HH.RH;
  BCHAR := FONTBCHAR[MAINF];
  FALSEBCHAR := FONTFALSEBCH[MAINF];
  IF CURLIST.MODEFIELD>0 THEN
    IF EQTB[5313].INT<>CURLIST.AUXFIELD.HH.RH
      THEN FIXLANGUAGE;
  BEGIN
    LIGSTACK := AVAIL;
    IF LIGSTACK=0 THEN LIGSTACK := GETAVAIL
    ELSE
      BEGIN
        AVAIL := MEM[LIGSTACK].HH
                 .RH;
        MEM[LIGSTACK].HH.RH := 0;{$IFDEF STATS}
        DYNUSED := DYNUSED+1;{$ENDIF}
      END;
  END;
  MEM[LIGSTACK].HH.B0 := MAINF;
  CURL := CURCHR+0;
  MEM[LIGSTACK].HH.B1 := CURL;
  CURQ := CURLIST.TAILFIELD;
  IF CANCELBOUNDA THEN
    BEGIN
      CANCELBOUNDA := FALSE;
      MAINK := 0;
    END
  ELSE MAINK := BCHARLABEL[MAINF];
  IF MAINK=0 THEN GOTO 92;
  CURR := CURL;
  CURL := 256;
  GOTO 111;
  80:{1035:}
      IF CURL<256 THEN
        BEGIN
          IF MEM[CURQ].HH.RH>0 THEN
            IF MEM[
               CURLIST.TAILFIELD].HH.B1=HYPHENCHAR[MAINF]+0 THEN INSDISC := TRUE;
          IF LIGATUREPRES THEN
            BEGIN
              MAINP := NEWLIGATURE(MAINF,CURL,MEM[CURQ].HH.RH
                       );
              IF LFTHIT THEN
                BEGIN
                  MEM[MAINP].HH.B1 := 2;
                  LFTHIT := FALSE;
                END;
              IF RTHIT THEN
                IF LIGSTACK=0 THEN
                  BEGIN
                    MEM[MAINP].HH.B1 := MEM[MAINP].HH.
                                        B1+1;
                    RTHIT := FALSE;
                  END;
              MEM[CURQ].HH.RH := MAINP;
              CURLIST.TAILFIELD := MAINP;
              LIGATUREPRES := FALSE;
            END;
          IF INSDISC THEN
            BEGIN
              INSDISC := FALSE;
              IF CURLIST.MODEFIELD>0 THEN
                BEGIN
                  MEM[CURLIST.TAILFIELD].HH.RH := NEWDISC;
                  CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
                END;
            END;
        END{:1035};
  90:{1036:}
      IF LIGSTACK=0 THEN GOTO 21;
  CURQ := CURLIST.TAILFIELD;
  CURL := MEM[LIGSTACK].HH.B1;
  91:
      IF NOT(LIGSTACK>=HIMEMMIN)THEN GOTO 95;
  92:
      IF (CURCHR<FONTBC[MAINF])OR(CURCHR>FONTEC[MAINF])THEN
        BEGIN
          CHARWARNING(MAINF,CURCHR);
          BEGIN
            MEM[LIGSTACK].HH.RH := AVAIL;
            AVAIL := LIGSTACK;{$IFDEF STATS}
            DYNUSED := DYNUSED-1;{$ENDIF}
          END;
          GOTO 60;
        END;
  MAINI := FONTINFO[CHARBASE[MAINF]+CURL].QQQQ;
  IF NOT(MAINI.B0>0)THEN
    BEGIN
      CHARWARNING(MAINF,CURCHR);
      BEGIN
        MEM[LIGSTACK].HH.RH := AVAIL;
        AVAIL := LIGSTACK;{$IFDEF STATS}
        DYNUSED := DYNUSED-1;{$ENDIF}
      END;
      GOTO 60;
    END;
  MEM[CURLIST.TAILFIELD].HH.RH := LIGSTACK;
  CURLIST.TAILFIELD := LIGSTACK{:1036};
  100:{1038:}get_next(true);
  IF CURCMD=11 THEN GOTO 101;
  IF CURCMD=12 THEN GOTO 101;
  IF CURCMD=68 THEN GOTO 101;
  XTOKEN;
  IF CURCMD=11 THEN GOTO 101;
  IF CURCMD=12 THEN GOTO 101;
  IF CURCMD=68 THEN GOTO 101;
  IF CURCMD=16 THEN
    BEGIN
      SCANCHARNUM;
      CURCHR := CURVAL;
      GOTO 101;
    END;
  IF CURCMD=65 THEN BCHAR := 256;
  CURR := BCHAR;
  LIGSTACK := 0;
  GOTO 110;
  101: MAINS := EQTB[4751+CURCHR].HH.RH;
  IF MAINS=1000 THEN CURLIST.AUXFIELD.HH.LH := 1000
  ELSE
    IF MAINS<1000 THEN
      BEGIN
        IF MAINS>0 THEN CURLIST.AUXFIELD.HH.LH := MAINS;
      END
  ELSE
    IF CURLIST.AUXFIELD.HH.LH<1000 THEN CURLIST.AUXFIELD.HH.LH := 
                                                                  1000
  ELSE CURLIST.AUXFIELD.HH.LH := MAINS;
  BEGIN
    LIGSTACK := AVAIL;
    IF LIGSTACK=0 THEN LIGSTACK := GETAVAIL
    ELSE
      BEGIN
        AVAIL := MEM[LIGSTACK].HH
                 .RH;
        MEM[LIGSTACK].HH.RH := 0;{$IFDEF STATS}
        DYNUSED := DYNUSED+1;{$ENDIF}
      END;
  END;
  MEM[LIGSTACK].HH.B0 := MAINF;
  CURR := CURCHR+0;
  MEM[LIGSTACK].HH.B1 := CURR;
  IF CURR=FALSEBCHAR THEN CURR := 256{:1038};
  110:{1039:}
       IF ((MAINI.B2-0)MOD 4)<>1 THEN GOTO 80;
  IF CURR=256 THEN GOTO 80;
  MAINK := LIGKERNBASE[MAINF]+MAINI.B3;
  MAINJ := FONTINFO[MAINK].QQQQ;
  IF MAINJ.B0<=128 THEN GOTO 112;
  MAINK := LIGKERNBASE[MAINF]+256*MAINJ.B2+MAINJ.B3+32768-256*(128);
  111: MAINJ := FONTINFO[MAINK].QQQQ;
  112:
       IF MAINJ.B1=CURR THEN
         IF MAINJ.B0<=128 THEN{1040:}
           BEGIN
             IF MAINJ.B2
                >=128 THEN
               BEGIN
                 IF CURL<256 THEN
                   BEGIN
                     IF MEM[CURQ].HH.RH>0 THEN
                       IF MEM
                          [CURLIST.TAILFIELD].HH.B1=HYPHENCHAR[MAINF]+0 THEN INSDISC := TRUE;
                     IF LIGATUREPRES THEN
                       BEGIN
                         MAINP := NEWLIGATURE(MAINF,CURL,MEM[CURQ].HH.RH
                                  );
                         IF LFTHIT THEN
                           BEGIN
                             MEM[MAINP].HH.B1 := 2;
                             LFTHIT := FALSE;
                           END;
                         IF RTHIT THEN
                           IF LIGSTACK=0 THEN
                             BEGIN
                               MEM[MAINP].HH.B1 := MEM[MAINP].HH.
                                                   B1+1;
                               RTHIT := FALSE;
                             END;
                         MEM[CURQ].HH.RH := MAINP;
                         CURLIST.TAILFIELD := MAINP;
                         LIGATUREPRES := FALSE;
                       END;
                     IF INSDISC THEN
                       BEGIN
                         INSDISC := FALSE;
                         IF CURLIST.MODEFIELD>0 THEN
                           BEGIN
                             MEM[CURLIST.TAILFIELD].HH.RH := NEWDISC;
                             CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
                           END;
                       END;
                   END;
                 BEGIN
                   MEM[CURLIST.TAILFIELD].HH.RH := NEWKERN(FONTINFO[KERNBASE[MAINF]+256
                                                   *MAINJ.B2+MAINJ.B3].INT);
                   CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
                 END;
                 GOTO 90;
               END;
             IF CURL=256 THEN LFTHIT := TRUE
             ELSE
               IF LIGSTACK=0 THEN RTHIT := TRUE;
             BEGIN
               IF INTERRUPT<>0 THEN PAUSEFORINST;
             END;
             CASE MAINJ.B2 OF 
               1,5:
                    BEGIN
                      CURL := MAINJ.B3;
                      MAINI := FONTINFO[CHARBASE[MAINF]+CURL].QQQQ;
                      LIGATUREPRES := TRUE;
                    END;
               2,6:
                    BEGIN
                      CURR := MAINJ.B3;
                      IF LIGSTACK=0 THEN
                        BEGIN
                          LIGSTACK := NEWLIGITEM(CURR);
                          BCHAR := 256;
                        END
                      ELSE
                        IF (LIGSTACK>=HIMEMMIN)THEN
                          BEGIN
                            MAINP := LIGSTACK;
                            LIGSTACK := NEWLIGITEM(CURR);
                            MEM[LIGSTACK+1].HH.RH := MAINP;
                          END
                      ELSE MEM[LIGSTACK].HH.B1 := CURR;
                    END;
               3:
                  BEGIN
                    CURR := MAINJ.B3;
                    MAINP := LIGSTACK;
                    LIGSTACK := NEWLIGITEM(CURR);
                    MEM[LIGSTACK].HH.RH := MAINP;
                  END;
               7,11:
                     BEGIN
                       IF CURL<256 THEN
                         BEGIN
                           IF MEM[CURQ].HH.RH>0 THEN
                             IF MEM[
                                CURLIST.TAILFIELD].HH.B1=HYPHENCHAR[MAINF]+0 THEN INSDISC := TRUE;
                           IF LIGATUREPRES THEN
                             BEGIN
                               MAINP := NEWLIGATURE(MAINF,CURL,MEM[CURQ].HH.RH);
                               IF LFTHIT THEN
                                 BEGIN
                                   MEM[MAINP].HH.B1 := 2;
                                   LFTHIT := FALSE;
                                 END;
                               IF FALSE THEN
                                 IF LIGSTACK=0 THEN
                                   BEGIN
                                     MEM[MAINP].HH.B1 := MEM[MAINP].HH.
                                                         B1+1;
                                     RTHIT := FALSE;
                                   END;
                               MEM[CURQ].HH.RH := MAINP;
                               CURLIST.TAILFIELD := MAINP;
                               LIGATUREPRES := FALSE;
                             END;
                           IF INSDISC THEN
                             BEGIN
                               INSDISC := FALSE;
                               IF CURLIST.MODEFIELD>0 THEN
                                 BEGIN
                                   MEM[CURLIST.TAILFIELD].HH.RH := NEWDISC;
                                   CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
                                 END;
                             END;
                         END;
                       CURQ := CURLIST.TAILFIELD;
                       CURL := MAINJ.B3;
                       MAINI := FONTINFO[CHARBASE[MAINF]+CURL].QQQQ;
                       LIGATUREPRES := TRUE;
                     END;
               ELSE
                 BEGIN
                   CURL := MAINJ.B3;
                   LIGATUREPRES := TRUE;
                   IF LIGSTACK=0 THEN GOTO 80
                   ELSE GOTO 91;
                 END
             END;
             IF MAINJ.B2>4 THEN
               IF MAINJ.B2<>7 THEN GOTO 80;
             IF CURL<256 THEN GOTO 110;
             MAINK := BCHARLABEL[MAINF];
             GOTO 111;
           END{:1040};
  IF MAINJ.B0=0 THEN MAINK := MAINK+1
  ELSE
    BEGIN
      IF MAINJ.B0>=128 THEN GOTO
        80;
      MAINK := MAINK+MAINJ.B0+1;
    END;
  GOTO 111{:1039};
  95:{1037:}MAINP := MEM[LIGSTACK+1].HH.RH;
  IF MAINP>0 THEN
    BEGIN
      MEM[CURLIST.TAILFIELD].HH.RH := MAINP;
      CURLIST.TAILFIELD := MEM[CURLIST.TAILFIELD].HH.RH;
    END;
  TEMPPTR := LIGSTACK;
  LIGSTACK := MEM[TEMPPTR].HH.RH;
  FREENODE(TEMPPTR,2);
  MAINI := FONTINFO[CHARBASE[MAINF]+CURL].QQQQ;
  LIGATUREPRES := TRUE;
  IF LIGSTACK=0 THEN
    IF MAINP>0 THEN GOTO 100
  ELSE CURR := BCHAR
  ELSE CURR := 
               MEM[LIGSTACK].HH.B1;
  GOTO 110{:1037}{:1034};
  120:{1041:}
       IF EQTB[2894].HH.RH=0 THEN
         BEGIN{1042:}
           BEGIN
             MAINP := FONTGLUE[
                      EQTB[3934].HH.RH];
             IF MAINP=0 THEN
               BEGIN
                 MAINP := NEWSPEC(0);
                 MAINK := PARAMBASE[EQTB[3934].HH.RH]+2;
                 MEM[MAINP+1].INT := FONTINFO[MAINK].INT;
                 MEM[MAINP+2].INT := FONTINFO[MAINK+1].INT;
                 MEM[MAINP+3].INT := FONTINFO[MAINK+2].INT;
                 FONTGLUE[EQTB[3934].HH.RH] := MAINP;
               END;
           END{:1042};
           TEMPPTR := NEWGLUE(MAINP);
         END
       ELSE TEMPPTR := NEWPARAMGLUE(12);
  MEM[CURLIST.TAILFIELD].HH.RH := TEMPPTR;
  CURLIST.TAILFIELD := TEMPPTR;
  GOTO 60{:1041};
END;
{:1030}

{1303:}
procedure too_small(ParameterName: shortstring);
var i: Integer;
begin
  write(output, '---! Must increase the ' + ParameterName);
  writeln(output);
end;

function UInt32LE(Buf: array of byte; Ofs: SizeUInt) : UInt32;
begin
  UInt32LE :=  UInt32(Buf[Ofs])           or (UInt32(Buf[Ofs+1]) shl 8) or
              (UInt32(Buf[Ofs+2]) shl 16) or (UInt32(Buf[Ofs+3]) shl 24);
end;

function BlockReadSuccess(var f: byte_file; var Buf; Len: UInt32) : boolean;
begin
  {$I-}
  blockread(f, Buf, Len);
  BlockReadSuccess :=  IOResult = 0;
  {$I+}
end;

function ReadFormatFile(var f: byte_file): boolean;
VAR
  P,Q: UInt32;

  i, j, u32 : UInt32;
  Buf: array [0..91] of byte;
  Next: UInt32;
  mw : MEMORYWORD;

BEGIN
  ReadFormatFile := false;

  {1308: @<Undump constants for consistency check@>}
  if not BlockReadSuccess(f, Buf, 32) then exit;
  if (UInt32LE(Buf,  0) <> 69577846) or
     (UInt32LE(Buf,  4) <> mem_bot) or
     (UInt32LE(Buf,  8) <> mem_top) or
     (UInt32LE(Buf, 12) <> eqtb_size) or
     (UInt32LE(Buf, 16) <> hash_prime) or
     (UInt32LE(Buf, 20) <> hyph_size) then exit;
  {:1308}

  {1310: @<Undump the string pool@>}
  u32 := UInt32LE(Buf, 24);
  if (u32 > pool_size) then too_small('string_pool_size');
  POOLPTR := u32;
  u32 := UInt32LE(Buf, 28);
  if (u32 > max_strings) then too_small('max string');
  STRPTR := u32;
  INITSTRPTR := STRPTR;
  INITPOOLPTR := POOLPTR;
  if not BlockReadSuccess(f, STRPOOL, STRPTR*4+4) then exit;
  for i := 0 to STRPTR do STRSTART[i] := UInt32LE(STRPOOL, 4*i);

  j := (POOLPTR + 3) and (not 3);
  if not BlockReadSuccess(f, STRPOOL, j) then exit;
  {Special treatment of last word. FIXME}
  for i := 0 to 3 do STRPOOL[POOLPTR-4+i] := STRPOOL[j-4+i];
  {:1310}

  {1312: @<Undump the dynamic memory@>}
  if not BlockReadSuccess(f, Buf, 8) then exit;
  LOMEMMAX := UInt32LE(Buf, 0);
  if (LOMEMMAX < lo_mem_stat_max+1000 ) or (LOMEMMAX >= hi_mem_stat_min) then exit;
  ROVER := UInt32LE(Buf, 4);
  if (ROVER < lo_mem_stat_max+1) or (ROVER > LOMEMMAX) then exit;

  P := mem_bot;
  Q := ROVER;
  repeat
    if not BlockReadSuccess(f, MEM[P], (Q-P+2)*4) then exit;
    P := Q+MEM[Q].HH.LH;        {next p := q+nodesize(q)}
    Next := MEM[Q+1].HH.RH;     {next q := rlink(q)}
    if (P>LOMEMMAX) or ((Next<=Q) and (Next<>ROVER)) then exit;
    Q := Next;
  until Q=ROVER;

  if not BlockReadSuccess(f, MEM[P], (LOMEMMAX-P+1)*4) then exit;
  IF MEMMIN<-2 THEN BEGIN
    P := MEM[ROVER+1].HH.LH;
    Q := MEMMIN+1;
    MEM[MEMMIN].HH.RH := 0;
    MEM[MEMMIN].HH.LH := 0;
    MEM[P+1].HH.RH := Q;
    MEM[ROVER+1].HH.LH := Q;
    MEM[Q+1].HH.RH := ROVER;
    MEM[Q+1].HH.LH := P;
    MEM[Q].HH.RH := 65535;
    MEM[Q].HH.LH := -0-Q;
  END;

  if not BlockReadSuccess(f, Buf, 8) then exit;
  HIMEMMIN := UInt32LE(Buf, 0);
  if (HIMEMMIN <= LOMEMMAX) or (HIMEMMIN > hi_mem_stat_min) then exit;
  AVAIL := UInt32LE(Buf, 4);
  if AVAIL > mem_top then exit;
  MEMEND := mem_top;

  if not BlockReadSuccess(f, MEM[HIMEMMIN], (MEMEND-HIMEMMIN+1)*4) then exit;
  if not BlockReadSuccess(f, Buf, 8) then exit;
  VARUSED := UInt32LE(Buf, 0);
  DYNUSED := UInt32LE(Buf, 4);
  {:1312}

  {1314: @<Undump the table of equivalents@>}
  {1317: @<Undump regions 1 to 6 of |eqtb|@>}
  i := active_base;
  REPEAT
    if not BlockReadSuccess(f, Buf, 4) then exit;
    u32 := UInt32LE(Buf, 0);
    if (u32<1) or (i+u32 > eqtb_size+1) then exit;

    if not BlockReadSuccess(f, EQTB[i], u32*4) then exit;
    i := i + u32;

    if not BlockReadSuccess(f, Buf, 4) then exit;
    u32 := UInt32LE(Buf, 0);
    if i+u32 > eqtb_size+1 then exit;

    for j := i to i+u32-1 do EQTB[j] := EQTB[i-1];
    i := i + u32;
  UNTIL i > eqtb_size;
  {:1317}

  if not BlockReadSuccess(f, Buf, 8) then exit;
  PARLOC := UInt32LE(Buf, 0);
  if (PARLOC<hash_base) or (PARLOC>frozen_control_sequence) then exit;
  WRITELOC := UInt32LE(Buf, 4);
  if (WRITELOC<hash_base) or (WRITELOC>frozen_control_sequence) then exit;
  PARTOKEN := PARLOC + cs_token_flag;

  {1319: @<Undump the hash table@>}
  if not BlockReadSuccess(f, Buf, 4) then exit;
  HASHUSED := UInt32LE(Buf, 0);
  if (HASHUSED<hash_base) or (HASHUSED>frozen_control_sequence) then exit;
  i := hash_base - 1;
  repeat
    if not BlockReadSuccess(f, Buf, 8) then exit;
    j := UInt32LE(Buf, 0);
    if (j<=i) or (j>HASHUSED) then exit;
    i := j;
    u32 := UInt32LE(Buf, 4);
    mw.INT := u32;
    HASH[i] := mw.HH;
  until i=HASHUSED;
  {FIXME: combine to only one block read}
  for i := HASHUSED+1 to undefined_control_sequence-1 do begin
    if not BlockReadSuccess(f, Buf, 4) then exit;
    u32 := UInt32LE(Buf, 0);
    mw.INT := u32;
    HASH[i] := mw.HH;
  end;
  if not BlockReadSuccess(f, Buf, 4) then exit;
  CSCOUNT := UInt32LE(Buf, 4);
  {:1319}
  {:1314}

  {1321: @<Undump the font information@>}
  if not BlockReadSuccess(f, Buf, 4) then exit;
  u32 := UInt32LE(Buf, 0);
  if (u32<7) then exit;
  if (u32>FONTMEMSIZE) then too_small('font mem size');
  FMEMPTR := u32;

  if not BlockReadSuccess(f, FONTINFO, FMEMPTR*4) then exit;
  if not BlockReadSuccess(f, Buf, 4) then exit;
  u32 := UInt32LE(Buf, 0);
  if u32>font_max then too_small('font max');
  FONTPTR := u32;

  for i := 0 to FONTPTR do begin
    {1323: @<Undump the array info for internal font number |k|@>}
    if not BlockReadSuccess(f, Buf, 92) then exit;
    mw.INT         := UInt32LE(Buf, 0);
    FONTCHECK[i]   := mw.QQQQ;
    FONTSIZE[i]    := UInt32LE(Buf, 4);
    FONTDSIZE[i]   := UInt32LE(Buf, 8);
    u32            := UInt32LE(Buf, 12);
    if u32>max_halfword then exit;
    FONTPARAMS[i]  := u32;
    HYPHENCHAR[i]  := UInt32LE(Buf, 16);
    SKEWCHAR[i]    := UInt32LE(Buf, 20);
    u32            := UInt32LE(Buf, 24);
    if u32>STRPTR then exit;
    FONTNAME[i]    := u32;
    u32            := UInt32LE(Buf, 28);
    if u32>STRPTR then exit;
    FONTAREA[i]    := u32;
    u32            := UInt32LE(Buf, 32);
    if u32>255 then exit;
    FONTBC[i]      := u32;
    u32            := UInt32LE(Buf, 36);
    if u32>255 then exit;
    FONTEC[i]      := u32;
    CHARBASE[i]    := UInt32LE(Buf, 40);
    WIDTHBASE[i]   := UInt32LE(Buf, 44);
    HEIGHTBASE[i]  := UInt32LE(Buf, 48);
    DEPTHBASE[i]   := UInt32LE(Buf, 52);
    ITALICBASE[i]  := UInt32LE(Buf, 56);
    LIGKERNBASE[i] := UInt32LE(Buf, 60);
    KERNBASE[i]    := UInt32LE(Buf, 64);
    EXTENBASE[i]   := UInt32LE(Buf, 68);
    PARAMBASE[i]   := UInt32LE(Buf, 72);
    u32            := UInt32LE(Buf, 76);
    if u32>LOMEMMAX then exit;
    FONTGLUE[i]    := u32;
    u32            := UInt32LE(Buf, 80);
    if u32>=FMEMPTR then exit;
    BCHARLABEL[i]  := u32;
    u32            := UInt32LE(Buf, 84);
    if u32>non_char then exit;
    FONTBCHAR[i]   := u32;
    u32            := UInt32LE(Buf, 88);
    if u32>non_char then exit;
    FONTFALSEBCH[i]:= u32;
    {:1323}
  end;
  {:1321}

  {1325: @<Undump the hyphenation tables@>}
  if not BlockReadSuccess(f, Buf, 4) then exit;
  u32 := UInt32LE(Buf, 0);
  if u32>hyph_size then exit;
  HYPHCOUNT := u32;

  for i := 1 to HYPHCOUNT do begin
    if not BlockReadSuccess(f, Buf, 12) then exit;
    j := UInt32LE(Buf, 0);
    u32 := UInt32LE(Buf, 4);
    if (j>hyph_size) or (u32>STRPTR) then exit;
    HYPHWORD[j] := u32;
    u32 := UInt32LE(Buf, 8);
    if u32>max_halfword then exit;
    HYPHLIST[j] := u32;
  END;

  if not BlockReadSuccess(f, Buf, 4) then exit;
  u32 := UInt32LE(Buf, 0);
  if u32>TRIESIZE then too_small('trie size');
  {$IFDEF INITEX}
  TRIEMAX := u32;
  {$ENDIF}
  {FIXME: read in one block and pack halfwords}
  for i := 0 to u32 do begin
    if not BlockReadSuccess(f, Buf, 4) then exit;
    mw.INT := UInt32LE(Buf, 0);
    TRIE[i] := mw.HH;
  end;

  if not BlockReadSuccess(f, Buf, 4) then exit;
  j := UInt32LE(Buf, 0);
  if j>TRIEOPSIZE then too_small('trie op size');
  {$IFDEF INITEX}
  TRIEOPPTR := j;
  {$ENDIF}
  for i := 1 to j do begin
    if not BlockReadSuccess(f, Buf, 12) then exit;
    u32 := UInt32LE(Buf, 0);
    if u32>63 then exit;
    HYFDISTANCE[i] := u32;
    u32 := UInt32LE(Buf, 4);
    if u32>63 then exit;
    HYFNUM[i] := u32;
    u32 := UInt32LE(Buf, 8);
    if u32>max_quarterword then exit;
    HYFNEXT[i] := u32;
  end;

  {$IFDEF INITEX}
  for i := 0 to 255 do TRIEUSED[i] := 0;
  TRIENOTREADY := FALSE;
  {$ENDIF}
  i := 256;
  while j>0 do begin {j=TRIEOPPTR}
    if not BlockReadSuccess(f, Buf, 8) then exit;
    u32 := UInt32LE(Buf, 0);
    if u32>=i then exit;
    i := u32;
    u32 := UInt32LE(Buf, 4);
    if (u32<1) or (u32>j) then exit;
    {$IFDEF INITEX}
    TRIEUSED[i] := u32;
    {$ENDIF}
    j := j - u32;
    OPSTART[i] := j;
  END;
  {:1325}

  {1327: @<Undump a couple more things and the closing check word@>}
  if not BlockReadSuccess(f, Buf, 12) then exit;
  u32 := UInt32LE(Buf, 0);
  if (u32<batch_mode) or (u32>error_stop_mode) then exit;
  INTERACTION := u32;
  u32 := UInt32LE(Buf, 4);
  if u32>STRPTR then exit;
  FORMATIDENT := u32;
  if UInt32LE(Buf, 8)<>69069 then exit;
  {:1327}

  ReadFormatFile := true;
END;
{:1303}



const
  FormatFileDirectory = 'TeXformats/';
  FormatFileFilename  = 'plain';
  FormatFileExtension = '.fmt';

function FindFormatFile(var f: byte_file) : boolean;
var
  i, j: 0..BUFSIZE;
  s: shortstring;
begin
  FindFormatFile := true;
  if BUFFER[CURINPUT.LOCFIELD]=ord('&') then begin

    {Get filename from input line}
    CURINPUT.LOCFIELD := CURINPUT.LOCFIELD+1;
    j := CURINPUT.LOCFIELD;
    BUFFER[LAST] := 32;
    while BUFFER[j]<>32 do j := j+1;
    SetLength(s, j - CURINPUT.LOCFIELD);
    for i := CURINPUT.LOCFIELD to j-1 do 
      s[i-CURINPUT.LOCFIELD+1] := chr(BUFFER[i]);

    {skip spaces after filename}
    while (j<CURINPUT.LIMITFIELD) and (BUFFER[j]=32) do j := j + 1;
    CURINPUT.LOCFIELD := j;

    if b_open_in(f, s+FormatFileExtension) then exit;
    if b_open_in(f, FormatFileDirectory+s+FormatFileExtension) then exit;
    writeln(output, 'Sorry, I can''t find that format;',' will try PLAIN.');
  end else begin

{$IFDEF INITEX}
    {if INITEX no implicit load of plain.fmt}
    FindFormatFile := false;
    exit;
{$ENDIF}

  end;

  if not b_open_in(f, FormatFileDirectory+FormatFileFilename+FormatFileExtension) then begin
    writeln(output, 'I can''t find the PLAIN format file!');
    halt(History);
  end;
END;

procedure TryToLoadFormatFile;
var
  f: byte_file;
begin
  if FindFormatFile(f) then begin
    if not ReadFormatFile(f) then begin
      writeln(Output, '(Fatal format file error; I''m stymied)');
      halt(History);
    end;
    close(f);
  end;
end;








{ ----------------------------------------------------------------------
  Exclusively for INITEX
  ---------------------------------------------------------------------- }

{$IFDEF INITEX}

{131:}
PROCEDURE SORTAVAIL;
VAR
  P,Q,R: HALFWORD;
  OLDROVER: HALFWORD;
BEGIN
  P := GETNODE(1073741824);
  P := MEM[ROVER+1].HH.RH;
  MEM[ROVER+1].HH.RH := 65535;
  OLDROVER := ROVER;
  WHILE P<>OLDROVER DO BEGIN
    {132:}
    IF P<ROVER THEN BEGIN
      Q := P;
      P := MEM[Q+1].HH.RH;
      MEM[Q+1].HH.RH := ROVER;
      ROVER := Q;
    END ELSE BEGIN
      Q := ROVER;
      WHILE MEM[Q+1].HH.RH<P DO
        Q := MEM[Q+1].HH.RH;
      R := MEM[P+1].HH.RH;
      MEM[P+1].HH.RH := MEM[Q+1].HH.RH;
      MEM[Q+1].HH.RH := P;
      P := R;
    END;
    {:132}
  END;
  P := ROVER;
  WHILE MEM[P+1].HH.RH<>65535 DO BEGIN
    MEM[MEM[P+1].HH.RH+1].HH.LH := P;
    P := MEM[P+1].HH.RH;
  END;
  MEM[P+1].HH.RH := ROVER;
  MEM[ROVER+1].HH.LH := P;
END;
{:131}



{1302:}
procedure SetUInt32LE(var Buf: array of byte; Ofs: SizeUInt; Val: UInt32);
begin
  Buf[Ofs] := Val;
  Buf[Ofs+1] := Val shr 8;
  Buf[Ofs+2] := Val shr 16;
  Buf[Ofs+3] := Val shr 24;
end;

function BlockWriteSuccess(var f: file; var Buf; Len: UInt32) : boolean;
begin
  {$I-}
  blockwrite(f, Buf, Len);
  BlockWriteSuccess :=  IOResult = 0;
  {$I+}
end;

PROCEDURE StoreFormatFile;
LABEL 41,42,31,32;
VAR J,K,L: Int32;
  P,Q: HALFWORD;
  X: Int32;
  W: FOURQUARTERS;
  mw: MEMORYWORD;

  f: byte_file;
  Buf: array[0..91] of byte;
  FileName: shortstring;
  s: shortstring;
  LocalFormatIdent: STRNUMBER;
BEGIN

  {@<If dumping is not allowed, abort@>}
  IF SAVEPTR<>0 THEN BEGIN
    print_err('You can''t dump inside a group');
    help1('`{...\dump}'' is a no-no.');
    succumb;
  END;

  {1328:}
  IF INTERACTION=0 THEN SELECTOR := 18
                   ELSE SELECTOR := 19;

  s := ' (preloaded format=' 
    + job_name + ' '
    + print_int(EQTB[int_base+year_code].INT) + '.'
    + print_int(EQTB[int_base+month_code].INT) + '.'
    + print_int(EQTB[int_base+day_code].INT) + chr(41);
  LocalFormatIdent := AddString(s); 
    {not necessary to set FORMATIDENT, because we are at the end of the program}

  FileName := job_name + '.fmt';
  while not b_open_out(f, FileName) do begin
    prompt_file_name(FileName, 'format file name', '.fmt');
  end;
  print_nl_str('Beginning to dump on file ');
  print_str(FileName);
  print_nl_str('');
  slow_print_str(s);
  {:1328}

  {1307: @<Dump constants for consistency check@>}
  SetUInt32LE(Buf, 0, 69577846);
  SetUInt32LE(Buf, 4, mem_bot);
  SetUInt32LE(Buf, 8, mem_top);
  SetUInt32LE(Buf, 12, eqtb_size);
  SetUInt32LE(Buf, 16, hash_prime);
  SetUInt32LE(Buf, 20, hyph_size);
  {:1307}

  {1309: @<Dump the string pool@>}
  SetUInt32LE(Buf, 24, POOLPTR);
  SetUInt32LE(Buf, 28, STRPTR);
  blockwrite(f, Buf, 32);

  {FIXME: pack in 16 bit and use one blockwrite}
  for K := 0 to STRPTR do begin
    SetUInt32LE(Buf, 0, STRSTART[K]);
    blockwrite(f, Buf, 4);
  end;

  blockwrite(f, STRPOOL, POOLPTR and not 3);
  {Special treatment of last word. FIXME}
  if (POOLPTR and 3) <> 0 then blockwrite(f, STRPOOL[POOLPTR-4], 4);

  PRINTLN;
  PRINTINT(STRPTR);
  print_str(' strings of total length '); {" strings of total length "}
  PRINTINT(POOLPTR);
  {:1309}

  {1311: @<Dump the dynamic memory@>}

  SORTAVAIL;
  VARUSED := 0;
  SetUInt32LE(Buf, 0, LOMEMMAX);
  SetUInt32LE(Buf, 4, ROVER);
  blockwrite(f, Buf, 8);
  P := 0;
  Q := ROVER;
  X := 0;
  REPEAT
    blockwrite(f, MEM[P], (Q-P+2)*4);
    X := X+Q+2-P;
    VARUSED := VARUSED+Q-P;
    P := Q+MEM[Q].HH.LH;
    Q := MEM[Q+1].HH.RH;
  UNTIL Q=ROVER;
  VARUSED := VARUSED+LOMEMMAX-P;
  DYNUSED := MEMEND+1-HIMEMMIN;
  blockwrite(f, MEM[P], (LOMEMMAX-P+1)*4);
  X := X+LOMEMMAX+1-P;

  SetUInt32LE(Buf, 0, HIMEMMIN);
  SetUInt32LE(Buf, 4, AVAIL);
  blockwrite(f, Buf, 8);
  blockwrite(f, MEM[HIMEMMIN], (MEMEND-HIMEMMIN+1)*4);
  X := X+MEMEND+1-HIMEMMIN;
  P := AVAIL;
  WHILE P<>0 DO BEGIN
      DYNUSED := DYNUSED-1;
      P := MEM[P].HH.RH;
  END;

  SetUInt32LE(Buf, 0, VARUSED);
  SetUInt32LE(Buf, 4, DYNUSED);
  blockwrite(f, Buf, 8);
  PRINTLN;
  PRINTINT(X);
  print_str(' memory locations dumped; current usage is ');
  PRINTINT(VARUSED);
  PRINTCHAR(38);
  PRINTINT(DYNUSED);
  {:1311}

  {1313: @<Dump the table of equivalents@>}
  {1315: @<Dump regions 1 to 4 of |eqtb|@>}
  K := active_base;
  REPEAT
    J := K;
    WHILE J<int_base-1 DO
      BEGIN
        IF (EQTB[J].HH.RH=EQTB[J+1].HH.RH)AND(EQTB[J].HH.B0
           =EQTB[J+1].HH.B0)AND(EQTB[J].HH.B1=EQTB[J+1].HH.B1)THEN GOTO 41;
        J := J+1;
      END;
    L := int_base;
    GOTO 31;
41:
    J := J+1;
    L := J;
    WHILE J<int_base-1 DO
      BEGIN
        IF (EQTB[J].HH.RH<>EQTB[J+1].HH.RH)OR(EQTB[J].HH.B0
           <>EQTB[J+1].HH.B0)OR(EQTB[J].HH.B1<>EQTB[J+1].HH.B1)THEN GOTO 31;
        J := J+1;
      END;
31:
    SetUInt32LE(Buf, 0, L-K);
    blockwrite(f, Buf, 4);
    blockwrite(f, EQTB[K], (L-K)*4);
    K := J+1;
    SetUInt32LE(Buf, 0, K-L);
    blockwrite(f, Buf, 4);
  UNTIL K=int_base;
  {:1315}

  {1316: @<Dump regions 5 and 6 of |eqtb|@>}
  REPEAT
    J := K;
    WHILE J<eqtb_size DO
      BEGIN
        IF EQTB[J].INT=EQTB[J+1].INT THEN GOTO 42;
        J := J+1;
      END;
    L := eqtb_size+1;
    GOTO 32;
42:
    J := J+1;
    L := J;
    WHILE J<eqtb_size DO
      BEGIN
        IF EQTB[J].INT<>EQTB[J+1].INT THEN GOTO 32;
        J := J+1;
      END;
32:
    SetUInt32LE(Buf, 0, L-K);
    blockwrite(f, Buf, 4);
    blockwrite(f, EQTB[K], (L-K)*4);
    K := J+1;
    SetUInt32LE(Buf, 0, K-L);
    blockwrite(f, Buf, 4);
  UNTIL K>eqtb_size;
  {:1316}

  SetUInt32LE(Buf, 0, PARLOC);
  SetUInt32LE(Buf, 4, WRITELOC);

  {1318: @<Dump the hash table@>}
  SetUInt32LE(Buf, 8, HASHUSED);
  blockwrite(f, Buf, 12);
  CSCOUNT := frozen_control_sequence-1-HASHUSED;
  FOR P:=hash_base TO HASHUSED DO BEGIN
    IF HASH[P].RH<>0 THEN BEGIN
      SetUInt32LE(Buf, 0, P);
      mw.HH := HASH[P];
      SetUInt32LE(Buf, 4, mw.INT);
      blockwrite(f, Buf, 8);
      CSCOUNT := CSCOUNT+1;
    END;
  END;
  FOR P:=HASHUSED+1 TO undefined_control_sequence-1 DO BEGIN
    mw.HH := HASH[P];
    SetUInt32LE(Buf, 0, mw.INT);
    blockwrite(f, Buf, 4);
  END;
  SetUInt32LE(Buf, 0, CSCOUNT);
  PRINTLN;
  PRINTINT(CSCOUNT);
  print_str(' multiletter control sequences');
  {:1318}
  {:1313}

  {1320:}
  SetUInt32LE(Buf, 4, FMEMPTR);
  blockwrite(f, Buf, 8);
  blockwrite(f, FONTINFO, FMEMPTR*4);
  SetUInt32LE(Buf, 0, FONTPTR);
  blockwrite(f, Buf, 4);
  FOR K:=0 TO FONTPTR DO BEGIN
    {1322:}
    mw.QQQQ := FONTCHECK[K];
    SetUInt32LE(Buf, 0, mw.INT);
    SetUInt32LE(Buf, 4, FONTSIZE[K]);
    SetUInt32LE(Buf, 8, FONTDSIZE[K]);
    SetUInt32LE(Buf, 12, FONTPARAMS[K]);
    SetUInt32LE(Buf, 16, HYPHENCHAR[K]);
    SetUInt32LE(Buf, 20, SKEWCHAR[K]);
    SetUInt32LE(Buf, 24, FONTNAME[K]);
    SetUInt32LE(Buf, 28, FONTAREA[K]);
    SetUInt32LE(Buf, 32, FONTBC[K]);
    SetUInt32LE(Buf, 36, FONTEC[K]);
    SetUInt32LE(Buf, 40, CHARBASE[K]);
    SetUInt32LE(Buf, 44, WIDTHBASE[K]);
    SetUInt32LE(Buf, 48, HEIGHTBASE[K]);
    SetUInt32LE(Buf, 52, DEPTHBASE[K]);
    SetUInt32LE(Buf, 56, ITALICBASE[K]);
    SetUInt32LE(Buf, 60, LIGKERNBASE[K]);
    SetUInt32LE(Buf, 64, KERNBASE[K]);
    SetUInt32LE(Buf, 68, EXTENBASE[K]);
    SetUInt32LE(Buf, 72, PARAMBASE[K]);
    SetUInt32LE(Buf, 76, FONTGLUE[K]);
    SetUInt32LE(Buf, 80, BCHARLABEL[K]);
    SetUInt32LE(Buf, 84, FONTBCHAR[K]);
    SetUInt32LE(Buf, 88, FONTFALSEBCH[K]);
    blockwrite(f, Buf, 92);
    print_nl_str('\font'); // FIXME: escape char hardcoded
    PRINTESC(HASH[2624+K].RH);
    PRINTCHAR(61);
    print_str(GetString(FONTAREA[K]) + GetString(FONTNAME[K]));
    IF FONTSIZE[K]<>FONTDSIZE[K] THEN BEGIN
      print_str(' at ' + print_scaled(FONTSIZE[K]) + 'pt');
    END;
    {:1322}
  END;
  PRINTLN;
  print_str(print_int(FMEMPTR-7) + ' words of font info for ' 
    + print_int(FONTPTR-0) + ' preloaded font');
  IF FONTPTR<>1 THEN PRINTCHAR(115);
  {:1320}

  {1324: @<Dump the hyphenation tables@>}

  SetUInt32LE(Buf, 0, HYPHCOUNT);
  blockwrite(f, Buf, 4);
  FOR K:=0 TO hyph_size DO BEGIN
    {possible BUG: why not HYPHCOUNT and no check for 0}
    IF HYPHWORD[K]<>0 THEN BEGIN
      SetUInt32LE(Buf, 0, K);
      SetUInt32LE(Buf, 4, HYPHWORD[K]);
      SetUInt32LE(Buf, 8, HYPHLIST[K]);
      blockwrite(f, Buf, 12);
    END;
  END;
  PRINTLN;
  PRINTINT(HYPHCOUNT);
  print_str(' hyphenation exception');
  IF HYPHCOUNT<>1 THEN PRINTCHAR(115);
  IF TRIENOTREADY THEN INITTRIE;

  SetUInt32LE(Buf, 0, TRIEMAX);
  blockwrite(f, Buf, 4);
  FOR K:=0 TO TRIEMAX DO BEGIN
    mw.HH := TRIE[K];
    SetUInt32LE(Buf, 0, mw.INT);
    blockwrite(f, Buf, 4);
  END;
  SetUInt32LE(Buf, 0, TRIEOPPTR);
  blockwrite(f, Buf, 4);
  FOR K:=1 TO TRIEOPPTR DO BEGIN
    SetUInt32LE(Buf, 0, HYFDISTANCE[K]);
    SetUInt32LE(Buf, 4, HYFNUM[K]);
    SetUInt32LE(Buf, 8, HYFNEXT[K]);
    blockwrite(f, Buf, 12);
  END;

  print_nl_str('Hyphenation trie of length ');
  PRINTINT(TRIEMAX);
  print_str(' has ');
  PRINTINT(TRIEOPPTR);
  print_str(' op');
  IF TRIEOPPTR<>1 THEN PRINTCHAR(115);
  print_str(' out of ');
  PRINTINT(TRIEOPSIZE);
  FOR K:=255 DOWNTO 0 DO BEGIN
    IF TRIEUSED[K]>0 THEN BEGIN
      print_nl_str('  ');
      PRINTINT(TRIEUSED[K]);
      print_str(' for language ');
      PRINTINT(K);
      SetUInt32LE(Buf, 0, K);
      SetUInt32LE(Buf, 4, TRIEUSED[K]);
      blockwrite(f, Buf, 8);
    END;
  END;
  {:1324}

  {1326:}
  SetUInt32LE(Buf, 0, INTERACTION);
  SetUInt32LE(Buf, 4, LocalFormatIdent);
  SetUInt32LE(Buf, 8, 69069);
  blockwrite(f, Buf, 12);
  EQTB[5294].INT := 0;
  {:1326}

  close(f)
END;
{:1302}

procedure InitInitex;
VAR
  K: Int32;
begin
{164:}
  FOR K:=1 TO 19 DO
    MEM[K].INT := 0;
  K := 0;
  WHILE K<=19 DO
    BEGIN
      MEM[K].HH.RH := 1;
      MEM[K].HH.B0 := 0;
      MEM[K].HH.B1 := 0;
      K := K+4;
    END;
  MEM[6].INT := 65536;
  MEM[4].HH.B0 := 1;
  MEM[10].INT := 65536;
  MEM[8].HH.B0 := 2;
  MEM[14].INT := 65536;
  MEM[12].HH.B0 := 1;
  MEM[15].INT := 65536;
  MEM[12].HH.B1 := 1;
  MEM[18].INT := -65536;
  MEM[16].HH.B0 := 1;
  ROVER := 20;
  MEM[ROVER].HH.RH := 65535;
  MEM[ROVER].HH.LH := 1000;
  MEM[ROVER+1].HH.LH := ROVER;
  MEM[ROVER+1].HH.RH := ROVER;
  LOMEMMAX := ROVER+1000;
  MEM[LOMEMMAX].HH.RH := 0;
  MEM[LOMEMMAX].HH.LH := 0;
  FOR K:=29987 TO 30000 DO
    MEM[K] := MEM[LOMEMMAX];
{790:}
  MEM[29990].HH.LH := 6714;{:790}{797:}
  MEM[29991].HH.RH := 256;
  MEM[29991].HH.LH := 0;{:797}{820:}
  MEM[29993].HH.B0 := 1;
  MEM[29994].HH.LH := 65535;
  MEM[29993].HH.B1 := 0;
{:820}{981:}
  MEM[30000].HH.B1 := 255;
  MEM[30000].HH.B0 := 1;
  MEM[30000].HH.RH := 30000;{:981}{988:}
  MEM[29998].HH.B0 := 10;
  MEM[29998].HH.B1 := 0;{:988};
  AVAIL := 0;
  MEMEND := 30000;
  HIMEMMIN := 29987;
  VARUSED := 20;
  DYNUSED := 14;{:164}{222:}
  EQTB[2881].HH.B0 := 101;
  EQTB[2881].HH.RH := 0;
  EQTB[2881].HH.B1 := 0;
  FOR K:=1 TO 2880 DO
    EQTB[K] := EQTB[2881];{:222}{228:}
  EQTB[2882].HH.RH := 0;
  EQTB[2882].HH.B1 := 1;
  EQTB[2882].HH.B0 := 117;
  FOR K:=2883 TO 3411 DO
    EQTB[K] := EQTB[2882];
  MEM[0].HH.RH := MEM[0].HH.RH+530;{:228}{232:}
  EQTB[3412].HH.RH := 0;
  EQTB[3412].HH.B0 := 118;
  EQTB[3412].HH.B1 := 1;
  FOR K:=3413 TO 3677 DO
    EQTB[K] := EQTB[2881];
  EQTB[3678].HH.RH := 0;
  EQTB[3678].HH.B0 := 119;
  EQTB[3678].HH.B1 := 1;
  FOR K:=3679 TO 3933 DO
    EQTB[K] := EQTB[3678];
  EQTB[3934].HH.RH := 0;
  EQTB[3934].HH.B0 := 120;
  EQTB[3934].HH.B1 := 1;
  FOR K:=3935 TO 3982 DO
    EQTB[K] := EQTB[3934];
  EQTB[3983].HH.RH := 0;
  EQTB[3983].HH.B0 := 120;
  EQTB[3983].HH.B1 := 1;
  FOR K:=3984 TO 5262 DO
    EQTB[K] := EQTB[3983];
  FOR K:=0 TO 255 DO
    BEGIN
      EQTB[3983+K].HH.RH := 12;
      EQTB[5007+K].HH.RH := K+0;
      EQTB[4751+K].HH.RH := 1000;
    END;
  EQTB[3996].HH.RH := 5;
  EQTB[4015].HH.RH := 10;
  EQTB[4075].HH.RH := 0;
  EQTB[4020].HH.RH := 14;
  EQTB[4110].HH.RH := 15;
  EQTB[3983].HH.RH := 9;
  FOR K:=48 TO 57 DO
    EQTB[5007+K].HH.RH := K+28672;
  FOR K:=65 TO 90 DO
    BEGIN
      EQTB[3983+K].HH.RH := 11;
      EQTB[3983+K+32].HH.RH := 11;
      EQTB[5007+K].HH.RH := K+28928;
      EQTB[5007+K+32].HH.RH := K+28960;
      EQTB[4239+K].HH.RH := K+32;
      EQTB[4239+K+32].HH.RH := K+32;
      EQTB[4495+K].HH.RH := K;
      EQTB[4495+K+32].HH.RH := K;
      EQTB[4751+K].HH.RH := 999;
    END;
{:232}{240:}
  FOR K:=5263 TO 5573 DO
    EQTB[K].INT := 0;
  EQTB[5280].INT := 1000;
  EQTB[5264].INT := 10000;
  EQTB[5304].INT := 1;
  EQTB[5303].INT := 25;
  EQTB[5308].INT := 92;
  EQTB[5311].INT := 13;
  FOR K:=0 TO 255 DO
    EQTB[5574+K].INT := -1;
  EQTB[5620].INT := 0;
{:240}{250:}
  FOR K:=5830 TO 6106 DO
    EQTB[K].INT := 0;
{:250}{258:}
  HASHUSED := 2614;
  CSCOUNT := 0;
  EQTB[2623].HH.B0 := 116;
  HASH[2623].RH := 502;{:258}{552:}
  FONTPTR := 0;
  FMEMPTR := 7;
  FONTNAME[0] := 801;
  FONTAREA[0] := 338;
  HYPHENCHAR[0] := 45;
  SKEWCHAR[0] := -1;
  BCHARLABEL[0] := 0;
  FONTBCHAR[0] := 256;
  FONTFALSEBCH[0] := 256;
  FONTBC[0] := 1;
  FONTEC[0] := 0;
  FONTSIZE[0] := 0;
  FONTDSIZE[0] := 0;
  CHARBASE[0] := 0;
  WIDTHBASE[0] := 0;
  HEIGHTBASE[0] := 0;
  DEPTHBASE[0] := 0;
  ITALICBASE[0] := 0;
  LIGKERNBASE[0] := 0;
  KERNBASE[0] := 0;
  EXTENBASE[0] := 0;
  FONTGLUE[0] := 0;
  FONTPARAMS[0] := 7;
  PARAMBASE[0] := -1;
  FOR K:=0 TO 6 DO
    FONTINFO[K].INT := 0;
{:552}{946:}
  FOR K:=-TRIEOPSIZE TO TRIEOPSIZE DO
    TRIEOPHASH[K] := 0;
  FOR K:=0 TO 255 DO
    TRIEUSED[K] := 0;
  TRIEOPPTR := 0;
{:946}{951:}
  TRIENOTREADY := TRUE;
  TRIEL[0] := 0;
  TRIEC[0] := 0;
  TRIEPTR := 0;
{:951}{1216:}
  HASH[2614].RH := 1190;{:1216}{1301:}
  FORMATIDENT := 1257;
{:1301}{1369:}
  HASH[2622].RH := 1296;
  EQTB[2622].HH.B1 := 1;
  EQTB[2622].HH.B0 := 113;
  EQTB[2622].HH.RH := 0;{:1369}
END;

{47:}
procedure GetStringsStarted;
const
  Hex: array [0..15] of char = '0123456789abcdef';
var
  i: int32;
  s: string[7];
begin
  POOLPTR := 0;

  s := '^^A';
  for i := 0 to 31 do begin
    s[3] := chr(i+64);
    SetString(i, s);
  end;
  for i := 32 to 126 do begin
    SetString(i, chr(i));
  end;
  SetString(127, '^^?');
  s := '^^00';
  for i := 128 to 255 do begin
    s[3] := Hex[i shr 4];
    s[4] := Hex[i and 15];
    SetString(i, s);
  end;

  SetString(256, 'buffer size');
  SetString(257, 'pool size');
  SetString(258, 'number of strings');
  SetString(259, '???');
  SetString(260, 'm2d5c2l5x2v5i');
  SetString(261, 'End of file on the terminal!');
  SetString(262, '! ');
  SetString(263, '(That makes 100 errors; please try again.)');
  SetString(264, '? ');
  SetString(265, 'You want to edit file ');
  SetString(266, ' at line ');
  SetString(267, 'Type <return> to proceed, S to scroll future error messages,');
  SetString(268, 'R to run without stopping, Q to run quietly,');
  SetString(269, 'I to insert something, ');
  SetString(270, 'E to edit your file,');
  SetString(271, '1 or ... or 9 to ignore the next 1 to 9 tokens of input,');
  SetString(272, 'H for help, X to quit.');
  SetString(273, 'OK, entering ');
  SetString(274, 'batchmode');
  SetString(275, 'nonstopmode');
  SetString(276, 'scrollmode');
  SetString(277, '...');
  SetString(278, 'insert>');
  SetString(279, 'I have just deleted some text, as you asked.');
  SetString(280, 'You can now delete more, or insert, or whatever.');
  SetString(281, 'Sorry, I don''t know how to help in this situation.');
  SetString(282, 'Maybe you should try asking a human?');
  SetString(283, 'Sorry, I already gave what help I could...');
  SetString(284, 'An error might have occurred before I noticed any problems.');
  SetString(285, '``If all else fails, read the instructions.''''');
  SetString(286, ' (');
  SetString(287, 'Emergency stop');
  SetString(288, 'TeX capacity exceeded, sorry [');
  SetString(289, 'If you really absolutely need more capacity,');
  SetString(290, 'you can ask a wizard to enlarge me.');
  SetString(291, 'This can''t happen (');
  SetString(292, 'I''m broken. Please show this to someone who can fix can fix');
  SetString(293, 'I can''t go on meeting you like this');
  SetString(294, 'One of your faux pas seems to have wounded me deeply...');
  SetString(295, 'in fact, I''m barely conscious. Please fix it and try again.');
  SetString(296, 'Interruption');
  SetString(297, 'You rang?');
  SetString(298, 'Try to insert an instruction for me (e.g., `I\showlists''),');
  SetString(299, 'unless you just want to quit by typing `X''.');
  SetString(300, 'main memory size');
  SetString(301, 'AVAIL list clobbered at ');
  SetString(302, 'Double-AVAIL list clobbered at ');
  SetString(303, 'Doubly free location at ');
  SetString(304, 'Bad flag at ');
  SetString(305, 'New busy locs:');
  SetString(306, 'LINK(');
  SetString(307, 'INFO(');
  SetString(308, '[]');
  SetString(309, 'CLOBBERED.');
  SetString(310, 'foul');
  SetString(311, 'fil');
  SetString(312, ' plus ');
  SetString(313, ' minus ');
  SetString(314, ' []');
  SetString(315, 'Bad link, display aborted.');
  SetString(316, 'etc.');
  SetString(317, 'Unknown node type!');
  SetString(318, 'unset');
  SetString(319, 'box(');
  SetString(320, ')x');
  SetString(321, ', shifted ');
  SetString(322, ' columns)');
  SetString(323, ', stretch ');
  SetString(324, ', shrink ');
  SetString(325, ', glue set ');
  SetString(326, '- ');
  SetString(327, '?.?');
  SetString(328, '< -');
  SetString(329, 'rule(');
  SetString(330, 'insert');
  SetString(331, ', natural size ');
  SetString(332, '; split(');
  SetString(333, '); float cost ');
  SetString(334, 'glue');
  SetString(335, 'nonscript');
  SetString(336, 'mskip');
  SetString(337, 'mu');
  SetString(338, '');
  SetString(339, 'leaders ');
  SetString(340, 'kern');
  SetString(341, ' (for accent)');
  SetString(342, 'mkern');
  SetString(343, 'math');
  SetString(344, 'on');
  SetString(345, 'off');
  SetString(346, ', surrounded ');
  SetString(347, ' (ligature ');
  SetString(348, 'penalty ');
  SetString(349, 'discretionary');
  SetString(350, ' replacing ');
  SetString(351, 'mark');
  SetString(352, 'vadjust');
  SetString(353, 'flushing');
  SetString(354, 'copying');
  SetString(355, 'vertical');
  SetString(356, 'horizontal');
  SetString(357, 'display math');
  SetString(358, 'no');
  SetString(359, 'internal vertical');
  SetString(360, 'restricted horizontal');
  SetString(361, ' mode');
  SetString(362, 'semantic nest size');
  SetString(363, '### ');
  SetString(364, ' entered at line ');
  SetString(365, ' (language');
  SetString(366, ':hyphenmin');
  SetString(367, ' (\output routine)');
  SetString(368, '### recent contributions:');
  SetString(369, 'prevdepth ');
  SetString(370, 'ignored');
  SetString(371, ', prevgraf ');
  SetString(372, ' line');
  SetString(373, 'spacefactor ');
  SetString(374, ', current language ');
  SetString(375, 'this will begin denominator of:');
  SetString(376, 'lineskip');
  SetString(377, 'baselineskip');
  SetString(378, 'parskip');
  SetString(379, 'abovedisplayskip');
  SetString(380, 'belowdisplayskip');
  SetString(381, 'abovedisplayshortskip');
  SetString(382, 'belowdisplayshortskip');
  SetString(383, 'leftskip');
  SetString(384, 'rightskip');
  SetString(385, 'topskip');
  SetString(386, 'splittopskip');
  SetString(387, 'tabskip');
  SetString(388, 'spaceskip');
  SetString(389, 'xspaceskip');
  SetString(390, 'parfillskip');
  SetString(391, 'thinmuskip');
  SetString(392, 'medmuskip');
  SetString(393, 'thickmuskip');
  SetString(394, '[unknown glue parameter!]');
  SetString(395, 'skip');
  SetString(396, 'muskip');
  SetString(397, 'pt');
  SetString(398, 'output');
  SetString(399, 'everypar');
  SetString(400, 'everymath');
  SetString(401, 'everydisplay');
  SetString(402, 'everyhbox');
  SetString(403, 'everyvbox');
  SetString(404, 'everyjob');
  SetString(405, 'everycr');
  SetString(406, 'errhelp');
  SetString(407, 'toks');
  SetString(408, 'parshape');
  SetString(409, 'box');
  SetString(410, 'void');
  SetString(411, 'current font');
  SetString(412, 'textfont');
  SetString(413, 'scriptfont');
  SetString(414, 'scriptscriptfont');
  SetString(415, 'catcode');
  SetString(416, 'lccode');
  SetString(417, 'uccode');
  SetString(418, 'sfcode');
  SetString(419, 'mathcode');
  SetString(420, 'pretolerance');
  SetString(421, 'tolerance');
  SetString(422, 'linepenalty');
  SetString(423, 'hyphenpenalty');
  SetString(424, 'exhyphenpenalty');
  SetString(425, 'clubpenalty');
  SetString(426, 'widowpenalty');
  SetString(427, 'displaywidowpenalty');
  SetString(428, 'brokenpenalty');
  SetString(429, 'binoppenalty');
  SetString(430, 'relpenalty');
  SetString(431, 'predisplaypenalty');
  SetString(432, 'postdisplaypenalty');
  SetString(433, 'interlinepenalty');
  SetString(434, 'doublehyphendemerits');
  SetString(435, 'finalhyphendemerits');
  SetString(436, 'adjdemerits');
  SetString(437, 'mag');
  SetString(438, 'delimiterfactor');
  SetString(439, 'looseness');
  SetString(440, 'time');
  SetString(441, 'day');
  SetString(442, 'month');
  SetString(443, 'year');
  SetString(444, 'showboxbreadth');
  SetString(445, 'showboxdepth');
  SetString(446, 'hbadness');
  SetString(447, 'vbadness');
  SetString(448, 'pausing');
  SetString(449, 'tracingonline');
  SetString(450, 'tracingmacros');
  SetString(451, 'tracingstats');
  SetString(452, 'tracingparagraphs');
  SetString(453, 'tracingpages');
  SetString(454, 'tracingoutput');
  SetString(455, 'tracinglostchars');
  SetString(456, 'tracingcommands');
  SetString(457, 'tracingrestores');
  SetString(458, 'uchyph');
  SetString(459, 'outputpenalty');
  SetString(460, 'maxdeadcycles');
  SetString(461, 'hangafter');
  SetString(462, 'floatingpenalty');
  SetString(463, 'globaldefs');
  SetString(464, 'fam');
  SetString(465, 'escapechar');
  SetString(466, 'defaulthyphenchar');
  SetString(467, 'defaultskewchar');
  SetString(468, 'endlinechar');
  SetString(469, 'newlinechar');
  SetString(470, 'language');
  SetString(471, 'lefthyphenmin');
  SetString(472, 'righthyphenmin');
  SetString(473, 'holdinginserts');
  SetString(474, 'errorcontextlines');
  SetString(475, '[unknown integer parameter!]');
  SetString(476, 'count');
  SetString(477, 'delcode');
  SetString(478, 'parindent');
  SetString(479, 'mathsurround');
  SetString(480, 'lineskiplimit');
  SetString(481, 'hsize');
  SetString(482, 'vsize');
  SetString(483, 'maxdepth');
  SetString(484, 'splitmaxdepth');
  SetString(485, 'boxmaxdepth');
  SetString(486, 'hfuzz');
  SetString(487, 'vfuzz');
  SetString(488, 'delimitershortfall');
  SetString(489, 'nulldelimiterspace');
  SetString(490, 'scriptspace');
  SetString(491, 'predisplaysize');
  SetString(492, 'displaywidth');
  SetString(493, 'displayindent');
  SetString(494, 'overfullrule');
  SetString(495, 'hangindent');
  SetString(496, 'hoffset');
  SetString(497, 'voffset');
  SetString(498, 'emergencystretch');
  SetString(499, '[unknown dimen parameter!]');
  SetString(500, 'dimen');
  SetString(501, 'EQUIV(');
  SetString(502, 'notexpanded:');
  SetString(503, 'hash size');
  SetString(504, 'csname');
  SetString(505, 'endcsname');
  SetString(506, 'IMPOSSIBLE.');
  SetString(507, 'NONEXISTENT.');
  SetString(508, 'accent');
  SetString(509, 'advance');
  SetString(510, 'afterassignment');
  SetString(511, 'aftergroup');
  SetString(512, 'begingroup');
  SetString(513, 'char');
  SetString(514, 'delimiter');
  SetString(515, 'divide');
  SetString(516, 'endgroup');
  SetString(517, 'expandafter');
  SetString(518, 'font');
  SetString(519, 'fontdimen');
  SetString(520, 'halign');
  SetString(521, 'hrule');
  SetString(522, 'ignorespaces');
  SetString(523, 'mathaccent');
  SetString(524, 'mathchar');
  SetString(525, 'mathchoice');
  SetString(526, 'multiply');
  SetString(527, 'noalign');
  SetString(528, 'noboundary');
  SetString(529, 'noexpand');
  SetString(530, 'omit');
  SetString(531, 'penalty');
  SetString(532, 'prevgraf');
  SetString(533, 'radical');
  SetString(534, 'read');
  SetString(535, 'relax');
  SetString(536, 'setbox');
  SetString(537, 'the');
  SetString(538, 'valign');
  SetString(539, 'vcenter');
  SetString(540, 'vrule');
  SetString(541, 'save size');
  SetString(542, 'grouping levels');
  SetString(543, 'curlevel');
  SetString(544, 'retaining');
  SetString(545, 'restoring');
  SetString(546, 'SAVE(');
  SetString(547, 'Incompatible magnification (');
  SetString(548, ');');
  SetString(549, ' the previous value will be retained');
  SetString(550, 'I can handle only one magnification ratio per job. So I''ve');
  SetString(551, 'reverted to the magnification you used earlier on this run.');
  SetString(552, 'Illegal magnification has been changed to 1000');
  SetString(553, 'The magnification ratio must be between 1 and 32768.');
  SetString(554, 'ETC.');
  SetString(555, 'BAD.');
  SetString(556, '->');
  SetString(557, 'begin-group character ');
  SetString(558, 'end-group character ');
  SetString(559, 'math shift character ');
  SetString(560, 'macro parameter character ');
  SetString(561, 'superscript character ');
  SetString(562, 'subscript character ');
  SetString(563, 'end of alignment template');
  SetString(564, 'blank space ');
  SetString(565, 'the letter ');
  SetString(566, 'the character ');
  SetString(567, '[unknown command code!]');
  SetString(568, ': ');
  SetString(569, 'Runaway ');
  SetString(570, 'definition');
  SetString(571, 'argument');
  SetString(572, 'preamble');
  SetString(573, 'text');
  SetString(574, '<*>');
  SetString(575, '<insert> ');
  SetString(576, '<read ');
  SetString(577, 'l.');
  SetString(578, '<argument> ');
  SetString(579, '<template> ');
  SetString(580, '<recently read> ');
  SetString(581, '<to be read again> ');
  SetString(582, '<inserted text> ');
  SetString(583, '<output> ');
  SetString(584, '<everypar> ');
  SetString(585, '<everymath> ');
  SetString(586, '<everydisplay> ');
  SetString(587, '<everyhbox> ');
  SetString(588, '<everyvbox> ');
  SetString(589, '<everyjob> ');
  SetString(590, '<everycr> ');
  SetString(591, '<mark> ');
  SetString(592, '<write> ');
  SetString(593, 'input stack size');
  SetString(594, 'write');
  SetString(595, '(interwoven alignment preambles are not allowed)');
  SetString(596, 'text input levels');
  SetString(597, 'par');
  SetString(598, 'Incomplete ');
  SetString(599, '; all text was ignored after line ');
  SetString(600, 'A forbidden control sequence occurred in skipped text.');
  SetString(601, 'This kind of error happens when you say `\if...'' and forget');
  SetString(602, 'the matching `\fi''. I''ve inserted a `\fi''; this might work.');
  SetString(603, 'The file ended while I was skipping conditional text.');
  SetString(604, 'File ended');
  SetString(605, 'Forbidden control sequence found');
  SetString(606, ' while scanning ');
  SetString(607, ' of ');
  SetString(608, 'I suspect you have forgotten a `}'', causing me');
  SetString(609, 'to read past where you wanted me to stop.');
  SetString(610, 'I''ll try to recover; but if the error is serious,');
  SetString(611, 'you''d better type `E'' or `X'' now and fix your file.');
  SetString(612, 'use');
  SetString(613, 'Text line contains an invalid character');
  SetString(614, 'A funny symbol that I can''t read has just been input.');
  SetString(615, 'Continue, and I''ll forget that it ever happened.');
  SetString(616, '(Please type a command or say `\end'')');
  SetString(617, '*** (job aborted, no legal \end found)');
  SetString(618, '=>');
  SetString(619, 'Undefined control sequence');
  SetString(620, 'The control sequence at the end of the top line');
  SetString(621, 'of your error message was never \def''ed. If you have');
  SetString(622, 'misspelled it (e.g., `\hobx''), type `I'' and the correct');
  SetString(623, 'spelling (e.g., `I\hbox''). Otherwise just continue,');
  SetString(624, 'and I''ll forget about whatever was undefined.');
  SetString(625, 'Missing ');
  SetString(626, ' inserted');
  SetString(627, 'The control sequence marked <to be read again> should');
  SetString(628, 'not appear between \csname and \endcsname.');
  SetString(629, 'input');
  SetString(630, 'endinput');
  SetString(631, 'topmark');
  SetString(632, 'firstmark');
  SetString(633, 'botmark');
  SetString(634, 'splitfirstmark');
  SetString(635, 'splitbotmark');
  SetString(636, 'parameter stack size');
  SetString(637, 'Argument of ');
  SetString(638, ' has an extra }');
  SetString(639, 'I''ve run across a `}'' that doesn''t seem to match anything.');
  SetString(640, 'For example, `\def\a#1{...}'' and `\a}'' would produce');
  SetString(641, 'this error. If you simply proceed now, the `\par'' that');
  SetString(642, 'I''ve just inserted will cause me to report a runaway');
  SetString(643, 'argument that might be the root of the problem. But if');
  SetString(644, 'your `}'' was spurious, just type `2'' and it will go away.');
  SetString(645, 'Paragraph ended before ');
  SetString(646, ' was complete');
  SetString(647, 'I suspect you''ve forgotten a `}'', causing me to apply this');
  SetString(648, 'control sequence to too much text. How can we recover?');
  SetString(649, 'My plan is to forget the whole thing and hope for the best.');
  SetString(650, 'Use of ');
  SetString(651, ' doesn''t match its definition');
  SetString(652, 'If you say, e.g., `\def\a1{...}'', then you must always');
  SetString(653, 'put `1'' after `\a'', since control sequence names are');
  SetString(654, 'made up of letters only. The macro here has not been');
  SetString(655, 'followed by the required stuff, so I''m ignoring it.');
  SetString(656, '<-');
  SetString(657, 'Missing { inserted');
  SetString(658, 'A left brace was mandatory here, so I''ve put one in.');
  SetString(659, 'You might want to delete and/or insert some corrections');
  SetString(660, 'so that I will find a matching right brace soon.');
  SetString(661, '(If you''re confused by all this, try typing `I}'' now.)');
  SetString(662, 'Incompatible glue units');
  SetString(663, 'I''m going to assume that 1mu=1pt when they''re mixed.');
  SetString(664, 'Missing number, treated as zero');
  SetString(665, 'A number should have been here; I inserted `0''.');
  SetString(666, '(If you can''t figure out why I needed to see a number,');
  SetString(667, 'look up `weird error'' in the index to The TeXbook.)');
  SetString(668, 'spacefactor');
  SetString(669, 'prevdepth');
  SetString(670, 'deadcycles');
  SetString(671, 'insertpenalties');
  SetString(672, 'wd');
  SetString(673, 'ht');
  SetString(674, 'dp');
  SetString(675, 'lastpenalty');
  SetString(676, 'lastkern');
  SetString(677, 'lastskip');
  SetString(678, 'inputlineno');
  SetString(679, 'badness');
  SetString(680, 'Improper ');
  SetString(681, 'You can refer to \spacefactor only in horizontal mode;');
  SetString(682, 'you can refer to \prevdepth only in vertical mode; and');
  SetString(683, 'neither of these is meaningful inside \write. So');
  SetString(684, 'I''m forgetting what you said and using zero instead.');
  SetString(685, 'You can''t use `');
  SetString(686, ''' after ');
  SetString(687, 'Bad register code');
  SetString(688, 'A register number must be between 0 and 255.');
  SetString(689, 'I changed this one to zero.');
  SetString(690, 'Bad character code');
  SetString(691, 'A character number must be between 0 and 255.');
  SetString(692, 'Bad number');
  SetString(693, 'Since I expected to read a number between 0 and 15,');
  SetString(694, 'Bad mathchar');
  SetString(695, 'A mathchar number must be between 0 and 32767.');
  SetString(696, 'Bad delimiter code');
  SetString(697, 'A numeric delimiter code must be between 0 and 2^{27}-1.');
  SetString(698, 'Improper alphabetic constant');
  SetString(699, 'A one-character control sequence belongs after a ` mark.');
  SetString(700, 'So I''m essentially inserting \0 here.');
  SetString(701, 'Number too big');
  SetString(702, 'I can only go up to 2147483647=''17777777777="7FFFFFFF,');
  SetString(703, 'so I''m using that number instead of yours.');
  SetString(704, 'true');
  SetString(705, 'Illegal unit of measure (');
  SetString(706, 'replaced by filll)');
  SetString(707, 'I dddon''t go any higher than filll.');
  SetString(708, 'em');
  SetString(709, 'ex');
  SetString(710, 'mu inserted)');
  SetString(711, 'The unit of measurement in math glue must be mu.');
  SetString(712, 'To recover gracefully from this error, it''s best to');
  SetString(713, 'delete the erroneous units; e.g., type `2'' to delete');
  SetString(714, 'two letters. (See Chapter 27 of The TeXbook.)');
  SetString(715, 'in');
  SetString(716, 'pc');
  SetString(717, 'cm');
  SetString(718, 'mm');
  SetString(719, 'bp');
  SetString(720, 'dd');
  SetString(721, 'cc');
  SetString(722, 'sp');
  SetString(723, 'pt inserted)');
  SetString(724, 'Dimensions can be in units of em, ex, in, pt, pc,');
  SetString(725, 'cm, mm, dd, cc, bp, or sp; but yours is a new one!');
  SetString(726, 'I''ll assume that you meant to say pt, for printer''s points.');
  SetString(727, 'Dimension too large');
  SetString(728, 'I can''t work with sizes bigger than about 19 feet.');
  SetString(729, 'Continue and I''ll use the largest value I can.');
  SetString(730, 'plus');
  SetString(731, 'minus');
  SetString(732, 'width');
  SetString(733, 'height');
  SetString(734, 'depth');
  SetString(735, 'number');
  SetString(736, 'romannumeral');
  SetString(737, 'string');
  SetString(738, 'meaning');
  SetString(739, 'fontname');
  SetString(740, 'jobname');
  SetString(741, ' at ');
  SetString(742, 'Where was the left brace? You said something like `\def\a}'',');
  SetString(743, 'which I''m going to interpret as `\def\a{}''.');
  SetString(744, 'You already have nine parameters');
  SetString(745, 'I''m going to ignore the # sign you just used,');
  SetString(746, 'as well as the token that followed it.');
  SetString(747, 'Parameters must be numbered consecutively');
  SetString(748, 'I''ve inserted the digit you should have used after the #.');
  SetString(749, 'Type `1'' to delete what you did use.');
  SetString(750, 'Illegal parameter number in definition of ');
  SetString(751, 'You meant to type ## instead of #, right?');
  SetString(752, 'Or maybe a } was forgotten somewhere earlier, and things');
  SetString(753, 'are all screwed up? I''m going to assume that you meant ##.');
  SetString(754, '*** (cannot \read from terminal in nonstop modes)');
  SetString(755, 'File ended within ');
  SetString(756, 'This \read has unbalanced braces.');
  SetString(757, 'if');
  SetString(758, 'ifcat');
  SetString(759, 'ifnum');
  SetString(760, 'ifdim');
  SetString(761, 'ifodd');
  SetString(762, 'ifvmode');
  SetString(763, 'ifhmode');
  SetString(764, 'ifmmode');
  SetString(765, 'ifinner');
  SetString(766, 'ifvoid');
  SetString(767, 'ifhbox');
  SetString(768, 'ifvbox');
  SetString(769, 'ifx');
  SetString(770, 'ifeof');
  SetString(771, 'iftrue');
  SetString(772, 'iffalse');
  SetString(773, 'ifcase');
  SetString(774, 'fi');
  SetString(775, 'or');
  SetString(776, 'else');
  SetString(777, 'Extra ');
  SetString(778, 'I''m ignoring this; it doesn''t match any \if.');
  SetString(779, '{true}');
  SetString(780, '{false}');
  SetString(781, 'Missing = inserted for ');
  SetString(782, 'I was expecting to see `<'', `='', or `>''. Didn''t.');
  SetString(783, '{case ');
  SetString(784, 'TeXinputs//');
  SetString(785, 'TeXfonts//');
  SetString(786, '.fmt');
  SetString(787, 'input file name');
  SetString(788, 'I can''t find file `');
  SetString(789, 'I can''t write on file `');
  SetString(790, '''.');
  SetString(791, '.tex');
  SetString(792, 'Please type another ');
  SetString(793, '*** (job aborted, file error in nonstop mode)');
  SetString(794, '.dvi');
  SetString(795, 'file name for output');
  SetString(796, 'texput');
  SetString(797, '.log');
  SetString(798, '**');
  SetString(799, 'transcript file name');
  SetString(800, '  ');
  SetString(801, 'nullfont');
  SetString(802, 'Font ');
  SetString(803, ' scaled ');
  SetString(804, ' not loadable: Bad metric (TFM) file');
  SetString(805, ' not loadable: Metric (TFM) file not found');
  SetString(806, 'I wasn''t able to read the size data for this font,');
  SetString(807, 'so I will ignore the font specification.');
  SetString(808, '[Wizards can fix TFM files using TFtoPL/PLtoTF.]');
  SetString(809, 'You might try inserting a different font spec;');
  SetString(810, 'e.g., type `I\font<same font id>=<substitute font name>''.');
  SetString(811, '.tfm');
  SetString(812, ' not loaded: Not enough room left');
  SetString(813, 'I''m afraid I won''t be able to make use of this font,');
  SetString(814, 'because my memory for character-size data is too small.');
  SetString(815, 'If you''re really stuck, ask a wizard to enlarge me.');
  SetString(816, 'Or maybe try `I\font<same font id>=<name of loaded font>''.');
  SetString(817, 'Missing font identifier');
  SetString(818, 'I was looking for a control sequence whose');
  SetString(819, 'current meaning has been defined by \font.');
  SetString(820, ' has only ');
  SetString(821, ' fontdimen parameters');
  SetString(822, 'To increase the number of font parameters, you must');
  SetString(823, 'use \fontdimen immediately after the \font is loaded.');
  SetString(824, 'font memory');
  SetString(825, 'Missing character: There is no ');
  SetString(826, ' in font ');
  SetString(827, ' TeX output ');
  SetString(828, 'vlistout');
  SetString(829, 'Completed box being shipped out');
  SetString(830, 'Memory usage before: ');
  SetString(831, ' after: ');
  SetString(832, '; still untouched: ');
  SetString(833, 'Huge page cannot be shipped out');
  SetString(834, 'The page just created is more than 18 feet tall or');
  SetString(835, 'more than 18 feet wide, so I suspect something went wrong.');
  SetString(836, 'The following box has been deleted:');
  SetString(837, 'No pages of output.');
  SetString(838, 'Output written on ');
  SetString(839, ' page');
  SetString(840, ', ');
  SetString(841, ' bytes).');
  SetString(842, 'to');
  SetString(843, 'spread');
  SetString(844, 'Underfull');
  SetString(845, 'Loose');
  SetString(846, ' \hbox (badness ');
  SetString(847, ') has occurred while \output is active');
  SetString(848, ') in paragraph at lines ');
  SetString(849, ') in alignment at lines ');
  SetString(850, '--');
  SetString(851, ') detected at line ');
  SetString(852, 'Overfull \hbox (');
  SetString(853, 'pt too wide');
  SetString(854, 'Tight \hbox (badness ');
  SetString(855, 'vpack');
  SetString(856, ' \vbox (badness ');
  SetString(857, 'Overfull \vbox (');
  SetString(858, 'pt too high');
  SetString(859, 'Tight \vbox (badness ');
  SetString(860, '{}');
  SetString(861, 'displaystyle');
  SetString(862, 'textstyle');
  SetString(863, 'scriptstyle');
  SetString(864, 'scriptscriptstyle');
  SetString(865, 'Unknown style!');
  SetString(866, 'mathord');
  SetString(867, 'mathop');
  SetString(868, 'mathbin');
  SetString(869, 'mathrel');
  SetString(870, 'mathopen');
  SetString(871, 'mathclose');
  SetString(872, 'mathpunct');
  SetString(873, 'mathinner');
  SetString(874, 'overline');
  SetString(875, 'underline');
  SetString(876, 'left');
  SetString(877, 'right');
  SetString(878, 'limits');
  SetString(879, 'nolimits');
  SetString(880, 'fraction, thickness ');
  SetString(881, '= default');
  SetString(882, ', left-delimiter ');
  SetString(883, ', right-delimiter ');
  SetString(884, ' is undefined (character ');
  SetString(885, 'Somewhere in the math formula just ended, you used the');
  SetString(886, 'stated character from an undefined font family. For example,');
  SetString(887, 'plain TeX doesn''t allow \it or \sl in subscripts. Proceed,');
  SetString(888, 'and I''ll try to forget that I needed that character.');
  SetString(889, 'mlist1');
  SetString(890, 'mlist2');
  SetString(891, 'mlist3');
  SetString(892, '0234000122*4000133**3**344*0400400*000000234000111*1111112341011');
  SetString(893, 'mlist4');
  SetString(894, ' inside $$''s');
  SetString(895, 'Displays can use special alignments (like \eqalignno)');
  SetString(896, 'only if nothing but the alignment itself is between $$''s.');
  SetString(897, 'So I''ve deleted the formulas that preceded this alignment.');
  SetString(898, 'span');
  SetString(899, 'cr');
  SetString(900, 'crcr');
  SetString(901, 'endtemplate');
  SetString(902, 'alignment tab character ');
  SetString(903, 'Missing # inserted in alignment preamble');
  SetString(904, 'There should be exactly one # between &''s, when an');
  SetString(905, '\halign or \valign is being set up. In this case you had');
  SetString(906, 'none, so I''ve put one in; maybe that will work.');
  SetString(907, 'Only one # is allowed per tab');
  SetString(908, 'more than one, so I''m ignoring all but the first.');
  SetString(909, 'endv');
  SetString(910, 'Extra alignment tab has been changed to ');
  SetString(911, 'You have given more \span or & marks than there were');
  SetString(912, 'in the preamble to the \halign or \valign now in progress.');
  SetString(913, 'So I''ll assume that you meant to type \cr instead.');
  SetString(914, '256 spans');
  SetString(915, 'align1');
  SetString(916, 'align0');
  SetString(917, 'Infinite glue shrinkage found in a paragraph');
  SetString(918, 'The paragraph just ended includes some glue that has');
  SetString(919, 'infinite shrinkability, e.g., `\hskip 0pt minus 1fil''.');
  SetString(920, 'Such glue doesn''t belong there---it allows a paragraph');
  SetString(921, 'of any length to fit on one line. But it''s safe to proceed,');
  SetString(922, 'since the offensive shrinkability has been made finite.');
  SetString(923, 'disc1');
  SetString(924, 'disc2');
  SetString(925, '@@');
  SetString(926, ': line ');
  SetString(927, ' t=');
  SetString(928, ' -> @@');
  SetString(929, ' via @@');
  SetString(930, ' b=');
  SetString(931, ' p=');
  SetString(932, ' d=');
  SetString(933, '@firstpass');
  SetString(934, '@secondpass');
  SetString(935, '@emergencypass');
  SetString(936, 'paragraph');
  SetString(937, 'disc3');
  SetString(938, 'disc4');
  SetString(939, 'line breaking');
  SetString(940, 'HYPH(');
  SetString(941, 'hyphenation');
  SetString(942, ' will be flushed');
  SetString(943, 'Hyphenation exceptions must contain only letters');
  SetString(944, 'and hyphens. But continue; I''ll forgive and forget.');
  SetString(945, 'Not a letter');
  SetString(946, 'Letters in \hyphenation words must have \lccode>0.');
  SetString(947, 'Proceed; I''ll ignore the character I just read.');
  SetString(948, 'exception dictionary');
  SetString(949, 'pattern memory ops');
  SetString(950, 'pattern memory ops per language');
  SetString(951, 'pattern memory');
  SetString(952, 'Too late for ');
  SetString(953, 'patterns');
  SetString(954, 'All patterns must be given before typesetting begins.');
  SetString(955, 'Bad ');
  SetString(956, '(See Appendix H.)');
  SetString(957, 'Nonletter');
  SetString(958, 'Duplicate pattern');
  SetString(959, 'pruning');
  SetString(960, 'vertbreak');
  SetString(961, 'Infinite glue shrinkage found in box being split');
  SetString(962, 'The box you are \vsplitting contains some infinitely');
  SetString(963, 'shrinkable glue, e.g., `\vss'' or `\vskip 0pt minus 1fil''.');
  SetString(964, 'Such glue doesn''t belong there; but you can safely proceed,');
  SetString(965, 'vsplit');
  SetString(966, ' needs a ');
  SetString(967, 'vbox');
  SetString(968, 'The box you are trying to split is an \hbox.');
  SetString(969, 'I can''t split such a box, so I''ll leave it alone.');
  SetString(970, 'pagegoal');
  SetString(971, 'pagetotal');
  SetString(972, 'pagestretch');
  SetString(973, 'pagefilstretch');
  SetString(974, 'pagefillstretch');
  SetString(975, 'pagefilllstretch');
  SetString(976, 'pageshrink');
  SetString(977, 'pagedepth');
  SetString(978, 'fill');
  SetString(979, 'filll');
  SetString(980, '### current page:');
  SetString(981, ' (held over for next output)');
  SetString(982, 'total height ');
  SetString(983, ' goal height ');
  SetString(984, ' adds ');
  SetString(985, ', #');
  SetString(986, ' might split');
  SetString(987, '%% goal height=');
  SetString(988, ', max depth=');
  SetString(989, 'Insertions can only be added to a vbox');
  SetString(990, 'Tut tut: You''re trying to \insert into a');
  SetString(991, '\box register that now contains an \hbox.');
  SetString(992, 'Proceed, and I''ll discard its present contents.');
  SetString(993, 'page');
  SetString(994, 'Infinite glue shrinkage found on current page');
  SetString(995, 'The page about to be output contains some infinitely');
  SetString(996, ' g=');
  SetString(997, ' c=');
  SetString(998, 'Infinite glue shrinkage inserted from ');
  SetString(999, 'The correction glue for page breaking with insertions');
  SetString(1000, 'must have finite shrinkability. But you may proceed,');
  SetString(1001, '% split');
  SetString(1002, ' to ');
  SetString(1003, '255 is not void');
  SetString(1004, 'You shouldn''t use \box255 except in \output routines.');
  SetString(1005, 'Output loop---');
  SetString(1006, ' consecutive dead cycles');
  SetString(1007, 'I''ve concluded that your \output is awry; it never does a');
  SetString(1008, '\shipout, so I''m shipping \box255 out myself. Next time');
  SetString(1009, 'increase \maxdeadcycles if you want me to be more patient!');
  SetString(1010, 'Unbalanced output routine');
  SetString(1011, 'Your sneaky output routine has problematic {''s and/or }''s.');
  SetString(1012, 'I can''t handle that very well; good luck.');
  SetString(1013, 'Output routine didn''t use all of ');
  SetString(1014, 'Your \output commands should empty \box255,');
  SetString(1015, 'e.g., by saying `\shipout\box255''.');
  SetString(1016, 'Proceed; I''ll discard its present contents.');
  SetString(1017, 'Missing $ inserted');
  SetString(1018, 'I''ve inserted a begin-math/end-math symbol since I think');
  SetString(1019, 'you left one out. Proceed, with fingers crossed.');
  SetString(1020, ''' in ');
  SetString(1021, 'Sorry, but I''m not programmed to handle this case;');
  SetString(1022, 'I''ll just pretend that you didn''t ask for it.');
  SetString(1023, 'If you''re in the wrong mode, you might be able to');
  SetString(1024, 'return to the right one by typing `I}'' or `I$'' or `I\par''.');
  SetString(1025, 'end');
  SetString(1026, 'dump');
  SetString(1027, 'hskip');
  SetString(1028, 'hfil');
  SetString(1029, 'hfill');
  SetString(1030, 'hss');
  SetString(1031, 'hfilneg');
  SetString(1032, 'vskip');
  SetString(1033, 'vfil');
  SetString(1034, 'vfill');
  SetString(1035, 'vss');
  SetString(1036, 'vfilneg');
  SetString(1037, 'I''ve inserted something that you may have forgotten.');
  SetString(1038, '(See the <inserted text> above.)');
  SetString(1039, 'With luck, this will get me unwedged. But if you');
  SetString(1040, 'really didn''t forget anything, try typing `2'' now; then');
  SetString(1041, 'my insertion and my current dilemma will both disappear.');
  SetString(1042, 'right.');
  SetString(1043, 'Things are pretty mixed up, but I think the worst is over.');
  SetString(1044, 'Too many }''s');
  SetString(1045, 'You''ve closed more groups than you opened.');
  SetString(1046, 'Such booboos are generally harmless, so keep going.');
  SetString(1047, 'rightbrace');
  SetString(1048, 'Extra }, or forgotten ');
  SetString(1049, 'I''ve deleted a group-closing symbol because it seems to be');
  SetString(1050, 'spurious, as in `$x}$''. But perhaps the } is legitimate and');
  SetString(1051, 'you forgot something else, as in `\hbox{$x}''. In such cases');
  SetString(1052, 'the way to recover is to insert both the forgotten and the');
  SetString(1053, 'deleted material, e.g., by typing `I$}''.');
  SetString(1054, 'moveleft');
  SetString(1055, 'moveright');
  SetString(1056, 'raise');
  SetString(1057, 'lower');
  SetString(1058, 'copy');
  SetString(1059, 'lastbox');
  SetString(1060, 'vtop');
  SetString(1061, 'hbox');
  SetString(1062, 'shipout');
  SetString(1063, 'leaders');
  SetString(1064, 'cleaders');
  SetString(1065, 'xleaders');
  SetString(1066, 'Leaders not followed by proper glue');
  SetString(1067, 'You should say `\leaders <box or rule><hskip or vskip>''.');
  SetString(1068, 'I found the <box or rule>, but there''s no suitable');
  SetString(1069, '<hskip or vskip>, so I''m ignoring these leaders.');
  SetString(1070, 'Sorry; this \lastbox will be void.');
  SetString(1071, 'Sorry...I usually can''t take things from the current page.');
  SetString(1072, 'This \lastbox will therefore be void.');
  SetString(1073, 'Missing `to'' inserted');
  SetString(1074, 'I''m working on `\vsplit<box number> to <dimen>'';');
  SetString(1075, 'will look for the <dimen> next.');
  SetString(1076, 'A <box> was supposed to be here');
  SetString(1077, 'I was expecting to see \hbox or \vbox or \copy or \box or');
  SetString(1078, 'something like that. So you might find something missing in');
  SetString(1079, 'your output. But keep trying; you can fix this later.');
  SetString(1080, 'indent');
  SetString(1081, 'noindent');
  SetString(1082, ''' here except with leaders');
  SetString(1083, 'To put a horizontal rule in an hbox or an alignment,');
  SetString(1084, 'you should use \leaders or \hrulefill (see The TeXbook).');
  SetString(1085, 'You can''t ');
  SetString(1086, 'I''m changing to \insert0; box 255 is special.');
  SetString(1087, 'Try `I\vskip-\lastskip'' instead.');
  SetString(1088, 'Try `I\kern-\lastkern'' instead.');
  SetString(1089, 'Perhaps you can make the output routine do it.');
  SetString(1090, 'unpenalty');
  SetString(1091, 'unkern');
  SetString(1092, 'unskip');
  SetString(1093, 'unhbox');
  SetString(1094, 'unhcopy');
  SetString(1095, 'unvbox');
  SetString(1096, 'unvcopy');
  SetString(1097, 'Incompatible list can''t be unboxed');
  SetString(1098, 'Sorry, Pandora. (You sneaky devil.)');
  SetString(1099, 'I refuse to unbox an \hbox in vertical mode or vice versa.');
  SetString(1100, 'And I can''t open any boxes in math mode.');
  SetString(1101, 'Illegal math ');
  SetString(1102, 'Sorry: The third part of a discretionary break must be');
  SetString(1103, 'empty, in math formulas. I had to delete your third part.');
  SetString(1104, 'Discretionary list is too long');
  SetString(1105, 'Wow---I never thought anybody would tweak me here.');
  SetString(1106, 'You can''t seriously need such a huge discretionary list?');
  SetString(1107, 'Improper discretionary list');
  SetString(1108, 'Discretionary lists must contain only boxes and kerns.');
  SetString(1109, 'The following discretionary sublist has been deleted:');
  SetString(1110, 'Missing } inserted');
  SetString(1111, 'I''ve put in what seems to be necessary to fix');
  SetString(1112, 'the current column of the current alignment.');
  SetString(1113, 'Try to go on, since this might almost work.');
  SetString(1114, 'Misplaced ');
  SetString(1115, 'I can''t figure out why you would want to use a tab mark');
  SetString(1116, 'here. If you just want an ampersand, the remedy is');
  SetString(1117, 'simple: Just type `I\&'' now. But if some right brace');
  SetString(1118, 'up above has ended a previous alignment prematurely,');
  SetString(1119, 'you''re probably due for more error messages, and you');
  SetString(1120, 'might try typing `S'' now just to see what is salvageable.');
  SetString(1121, 'or \cr or \span just now. If something like a right brace');
  SetString(1122, 'I expect to see \noalign only after the \cr of');
  SetString(1123, 'an alignment. Proceed, and I''ll ignore this case.');
  SetString(1124, 'I expect to see \omit only after tab marks or the \cr of');
  SetString(1125, 'I''m guessing that you meant to end an alignment here.');
  SetString(1126, 'I''m ignoring this, since I wasn''t doing a \csname.');
  SetString(1127, 'eqno');
  SetString(1128, 'leqno');
  SetString(1129, 'displaylimits');
  SetString(1130, 'Limit controls must follow a math operator');
  SetString(1131, 'I''m ignoring this misplaced \limits or \nolimits command.');
  SetString(1132, 'Missing delimiter (. inserted)');
  SetString(1133, 'I was expecting to see something like `('' or `\{'' or');
  SetString(1134, '`\}'' here. If you typed, e.g., `{'' instead of `\{'', you');
  SetString(1135, 'should probably delete the `{'' by typing `1'' now, so that');
  SetString(1136, 'braces don''t get unbalanced. Otherwise just proceed.');
  SetString(1137, 'Acceptable delimiters are characters whose \delcode is');
  SetString(1138, 'nonnegative, or you can use `\delimiter <delimiter code>''.');
  SetString(1139, 'Please use ');
  SetString(1140, ' for accents in math mode');
  SetString(1141, 'I''m changing \accent to \mathaccent here; wish me luck.');
  SetString(1142, '(Accents are not the same in formulas as they are in text.)');
  SetString(1143, 'Double superscript');
  SetString(1144, 'I treat `x^1^2'' essentially like `x^1{}^2''.');
  SetString(1145, 'Double subscript');
  SetString(1146, 'I treat `x_1_2'' essentially like `x_1{}_2''.');
  SetString(1147, 'above');
  SetString(1148, 'over');
  SetString(1149, 'atop');
  SetString(1150, 'abovewithdelims');
  SetString(1151, 'overwithdelims');
  SetString(1152, 'atopwithdelims');
  SetString(1153, 'Ambiguous; you need another { and }');
  SetString(1154, 'I''m ignoring this fraction specification, since I don''t');
  SetString(1155, 'know whether a construction like `x \over y \over z''');
  SetString(1156, 'means `{x \over y} \over z'' or `x \over {y \over z}''.');
  SetString(1157, 'I''m ignoring a \right that had no matching \left.');
  SetString(1158, 'Math formula deleted: Insufficient symbol fonts');
  SetString(1159, 'Sorry, but I can''t typeset math unless \textfont 2');
  SetString(1160, 'and \scriptfont 2 and \scriptscriptfont 2 have all');
  SetString(1161, 'the \fontdimen values needed in math symbol fonts.');
  SetString(1162, 'Math formula deleted: Insufficient extension fonts');
  SetString(1163, 'Sorry, but I can''t typeset math unless \textfont 3');
  SetString(1164, 'and \scriptfont 3 and \scriptscriptfont 3 have all');
  SetString(1165, 'the \fontdimen values needed in math extension fonts.');
  SetString(1166, 'Display math should end with $$');
  SetString(1167, 'The `$'' that I just saw supposedly matches a previous `$$''.');
  SetString(1168, 'So I shall assume that you typed `$$'' both times.');
  SetString(1169, 'display');
  SetString(1170, 'Missing $$ inserted');
  SetString(1171, 'long');
  SetString(1172, 'outer');
  SetString(1173, 'global');
  SetString(1174, 'def');
  SetString(1175, 'gdef');
  SetString(1176, 'edef');
  SetString(1177, 'xdef');
  SetString(1178, 'prefix');
  SetString(1179, 'You can''t use a prefix with `');
  SetString(1180, 'I''ll pretend you didn''t say \long or \outer or \global.');
  SetString(1181, ''' or `');
  SetString(1182, ''' with `');
  SetString(1183, 'I''ll pretend you didn''t say \long or \outer here.');
  SetString(1184, 'Missing control sequence inserted');
  SetString(1185, 'Please don''t say `\def cs{...}'', say `\def\cs{...}''.');
  SetString(1186, 'I''ve inserted an inaccessible control sequence so that your');
  SetString(1187, 'definition will be completed without mixing me up too badly.');
  SetString(1188, 'You can recover graciously from this error, if you''re');
  SetString(1189, 'careful; see exercise 27.2 in The TeXbook.');
  SetString(1190, 'inaccessible');
  SetString(1191, 'let');
  SetString(1192, 'futurelet');
  SetString(1193, 'chardef');
  SetString(1194, 'mathchardef');
  SetString(1195, 'countdef');
  SetString(1196, 'dimendef');
  SetString(1197, 'skipdef');
  SetString(1198, 'muskipdef');
  SetString(1199, 'toksdef');
  SetString(1200, 'You should have said `\read<number> to \cs''.');
  SetString(1201, 'I''m going to look for the \cs now.');
  SetString(1202, 'Invalid code (');
  SetString(1203, '), should be in the range 0..');
  SetString(1204, '), should be at most ');
  SetString(1205, 'I''m going to use 0 instead of that illegal code value.');
  SetString(1206, 'by');
  SetString(1207, 'Arithmetic overflow');
  SetString(1208, 'I can''t carry out that multiplication or division,');
  SetString(1209, 'since the result is out of range.');
  SetString(1210, 'I''m forgetting what you said and not changing anything.');
  SetString(1211, 'Sorry, \setbox is not allowed after \halign in a display,');
  SetString(1212, 'or between \accent and an accented character.');
  SetString(1213, 'Bad space factor');
  SetString(1214, 'I allow only values in the range 1..32767 here.');
  SetString(1215, 'I allow only nonnegative values here.');
  SetString(1216, 'Patterns can be loaded only by INITEX');
  SetString(1217, 'hyphenchar');
  SetString(1218, 'skewchar');
  SetString(1219, 'FONT');
  SetString(1220, 'at');
  SetString(1221, 'scaled');
  SetString(1222, 'Improper `at'' size (');
  SetString(1223, 'pt), replaced by 10pt');
  SetString(1224, 'I can only handle fonts at positive sizes that are');
  SetString(1225, 'less than 2048pt, so I''ve changed what you said to 10pt.');
  SetString(1226, 'select font ');
  SetString(1227, 'errorstopmode');
  SetString(1228, 'openin');
  SetString(1229, 'closein');
  SetString(1230, 'message');
  SetString(1231, 'errmessage');
  SetString(1232, '(That was another \errmessage.)');
  SetString(1233, 'This error message was generated by an \errmessage');
  SetString(1234, 'command, so I can''t give any explicit help.');
  SetString(1235, 'Pretend that you''re Hercule Poirot: Examine all clues,');
  SetString(1236, 'and deduce the truth by order and method.');
  SetString(1237, 'lowercase');
  SetString(1238, 'uppercase');
  SetString(1239, 'show');
  SetString(1240, 'showbox');
  SetString(1241, 'showthe');
  SetString(1242, 'showlists');
  SetString(1243, 'This isn''t an error message; I''m just \showing something.');
  SetString(1244, 'Type `I\show...'' to show more (e.g., \show\cs,');
  SetString(1245, '\showthe\count10, \showbox255, \showlists).');
  SetString(1246, 'And type `I\tracingonline=1\show...'' to show boxes and');
  SetString(1247, 'lists on your terminal as well as in the transcript file.');
  SetString(1248, '> ');
  SetString(1249, 'undefined');
  SetString(1250, 'macro');
  SetString(1251, 'long macro');
  SetString(1252, 'outer macro');
  SetString(1253, 'outer endtemplate');
  SetString(1254, '> \box');
  SetString(1255, 'OK');
  SetString(1256, ' (see the transcript file)');
  SetString(1257, ' (INITEX)');
  SetString(1258, 'You can''t dump inside a group');
  SetString(1259, '`{...\dump}'' is a no-no.');
  SetString(1260, ' strings of total length ');
  SetString(1261, ' memory locations dumped; current usage is ');
  SetString(1262, ' multiletter control sequences');
  SetString(1263, ' words of font info for ');
  SetString(1264, ' preloaded font');
  SetString(1265, '\font');
  SetString(1266, ' hyphenation exception');
  SetString(1267, 'Hyphenation trie of length ');
  SetString(1268, ' has ');
  SetString(1269, ' op');
  SetString(1270, ' out of ');
  SetString(1271, ' for language ');
  SetString(1272, ' (preloaded format=');
  SetString(1273, 'format file name');
  SetString(1274, 'Beginning to dump on file ');
  SetString(1275, 'Transcript written on ');
  SetString(1276, ' )');
  SetString(1277, 'end occurred ');
  SetString(1278, 'inside a group at level ');
  SetString(1279, 'when ');
  SetString(1280, ' on line ');
  SetString(1281, ' was incomplete)');
  SetString(1282, '(see the transcript file for additional information)');
  SetString(1283, '(\dump is performed only by INITEX)');
  SetString(1284, 'debug # (-1 to exit):');
  SetString(1285, 'openout');
  SetString(1286, 'closeout');
  SetString(1287, 'special');
  SetString(1288, 'immediate');
  SetString(1289, 'setlanguage');
  SetString(1290, '[unknown extension!]');
  SetString(1291, 'ext1');
  SetString(1292, ' (hyphenmin ');
  SetString(1293, 'whatsit?');
  SetString(1294, 'ext2');
  SetString(1295, 'ext3');
  SetString(1296, 'endwrite');
  SetString(1297, 'Unbalanced write command');
  SetString(1298, 'On this page there''s a \write with fewer real {''s than }''s.');
  SetString(1299, 'ext4');
  SetString(1300, 'output file name');
  STRPTR := 1301;
  STRSTART[STRPTR] := POOLPTR;
end;
{:47}

{264:}
PROCEDURE PRIMITIVE(S:STRNUMBER;C:QUARTERWORD;O:HALFWORD);
VAR K: POOLPOINTER;
  J: SMALLNUMBER;
  L: SMALLNUMBER;
BEGIN
  IF S<256 THEN CURVAL := S+257
  ELSE
    BEGIN
      K := STRSTART[S];
      L := STRSTART[S+1]-K;
      FOR J:=0 TO L-1 DO
        BUFFER[J] := STRPOOL[K+J];
      CURVAL := id_lookup(false, 0, L);
      BEGIN
        STRPTR := STRPTR-1;
        POOLPTR := STRSTART[STRPTR];
      END;
      HASH[CURVAL].RH := S;
    END;
  EQTB[CURVAL].HH.B1 := 1;
  EQTB[CURVAL].HH.B0 := C;
  EQTB[CURVAL].HH.RH := O;
END;
{:264}

{1336:}
PROCEDURE INITPRIM;
BEGIN
{226:}
  PRIMITIVE(376,75,2882);
  PRIMITIVE(377,75,2883);
  PRIMITIVE(378,75,2884);
  PRIMITIVE(379,75,2885);
  PRIMITIVE(380,75,2886);
  PRIMITIVE(381,75,2887);
  PRIMITIVE(382,75,2888);
  PRIMITIVE(383,75,2889);
  PRIMITIVE(384,75,2890);
  PRIMITIVE(385,75,2891);
  PRIMITIVE(386,75,2892);
  PRIMITIVE(387,75,2893);
  PRIMITIVE(388,75,2894);
  PRIMITIVE(389,75,2895);
  PRIMITIVE(390,75,2896);
  PRIMITIVE(391,76,2897);
  PRIMITIVE(392,76,2898);
  PRIMITIVE(393,76,2899);{:226}{230:}
  PRIMITIVE(398,72,3413);
  PRIMITIVE(399,72,3414);
  PRIMITIVE(400,72,3415);
  PRIMITIVE(401,72,3416);
  PRIMITIVE(402,72,3417);
  PRIMITIVE(403,72,3418);
  PRIMITIVE(404,72,3419);
  PRIMITIVE(405,72,3420);
  PRIMITIVE(406,72,3421);
{:230}{238:}
  PRIMITIVE(420,73,5263);
  PRIMITIVE(421,73,5264);
  PRIMITIVE(422,73,5265);
  PRIMITIVE(423,73,5266);
  PRIMITIVE(424,73,5267);
  PRIMITIVE(425,73,5268);
  PRIMITIVE(426,73,5269);
  PRIMITIVE(427,73,5270);
  PRIMITIVE(428,73,5271);
  PRIMITIVE(429,73,5272);
  PRIMITIVE(430,73,5273);
  PRIMITIVE(431,73,5274);
  PRIMITIVE(432,73,5275);
  PRIMITIVE(433,73,5276);
  PRIMITIVE(434,73,5277);
  PRIMITIVE(435,73,5278);
  PRIMITIVE(436,73,5279);
  PRIMITIVE(437,73,5280);
  PRIMITIVE(438,73,5281);
  PRIMITIVE(439,73,5282);
  PRIMITIVE(440,73,5283);
  PRIMITIVE(441,73,5284);
  PRIMITIVE(442,73,5285);
  PRIMITIVE(443,73,5286);
  PRIMITIVE(444,73,5287);
  PRIMITIVE(445,73,5288);
  PRIMITIVE(446,73,5289);
  PRIMITIVE(447,73,5290);
  PRIMITIVE(448,73,5291);
  PRIMITIVE(449,73,5292);
  PRIMITIVE(450,73,5293);
  PRIMITIVE(451,73,5294);
  PRIMITIVE(452,73,5295);
  PRIMITIVE(453,73,5296);
  PRIMITIVE(454,73,5297);
  PRIMITIVE(455,73,5298);
  PRIMITIVE(456,73,5299);
  PRIMITIVE(457,73,5300);
  PRIMITIVE(458,73,5301);
  PRIMITIVE(459,73,5302);
  PRIMITIVE(460,73,5303);
  PRIMITIVE(461,73,5304);
  PRIMITIVE(462,73,5305);
  PRIMITIVE(463,73,5306);
  PRIMITIVE(464,73,5307);
  PRIMITIVE(465,73,5308);
  PRIMITIVE(466,73,5309);
  PRIMITIVE(467,73,5310);
  PRIMITIVE(468,73,5311);
  PRIMITIVE(469,73,5312);
  PRIMITIVE(470,73,5313);
  PRIMITIVE(471,73,5314);
  PRIMITIVE(472,73,5315);
  PRIMITIVE(473,73,5316);
  PRIMITIVE(474,73,5317);
{:238}{248:}
  PRIMITIVE(478,74,5830);
  PRIMITIVE(479,74,5831);
  PRIMITIVE(480,74,5832);
  PRIMITIVE(481,74,5833);
  PRIMITIVE(482,74,5834);
  PRIMITIVE(483,74,5835);
  PRIMITIVE(484,74,5836);
  PRIMITIVE(485,74,5837);
  PRIMITIVE(486,74,5838);
  PRIMITIVE(487,74,5839);
  PRIMITIVE(488,74,5840);
  PRIMITIVE(489,74,5841);
  PRIMITIVE(490,74,5842);
  PRIMITIVE(491,74,5843);
  PRIMITIVE(492,74,5844);
  PRIMITIVE(493,74,5845);
  PRIMITIVE(494,74,5846);
  PRIMITIVE(495,74,5847);
  PRIMITIVE(496,74,5848);
  PRIMITIVE(497,74,5849);
  PRIMITIVE(498,74,5850);{:248}{265:}
  PRIMITIVE(32,64,0);
  PRIMITIVE(47,44,0);
  PRIMITIVE(508,45,0);
  PRIMITIVE(509,90,0);
  PRIMITIVE(510,40,0);
  PRIMITIVE(511,41,0);
  PRIMITIVE(512,61,0);
  PRIMITIVE(513,16,0);
  PRIMITIVE(504,107,0);
  PRIMITIVE(514,15,0);
  PRIMITIVE(515,92,0);
  PRIMITIVE(505,67,0);
  PRIMITIVE(516,62,0);
  HASH[2616].RH := 516;
  EQTB[2616] := EQTB[CURVAL];
  PRIMITIVE(517,102,0);
  PRIMITIVE(518,88,0);
  PRIMITIVE(519,77,0);
  PRIMITIVE(520,32,0);
  PRIMITIVE(521,36,0);
  PRIMITIVE(522,39,0);
  PRIMITIVE(330,37,0);
  PRIMITIVE(351,18,0);
  PRIMITIVE(523,46,0);
  PRIMITIVE(524,17,0);
  PRIMITIVE(525,54,0);
  PRIMITIVE(526,91,0);
  PRIMITIVE(527,34,0);
  PRIMITIVE(528,65,0);
  PRIMITIVE(529,103,0);
  PRIMITIVE(335,55,0);
  PRIMITIVE(530,63,0);
  PRIMITIVE(408,84,0);
  PRIMITIVE(531,42,0);
  PRIMITIVE(532,80,0);
  PRIMITIVE(533,66,0);
  PRIMITIVE(534,96,0);
  PRIMITIVE(535,0,256);
  HASH[2621].RH := 535;
  EQTB[2621] := EQTB[CURVAL];
  PRIMITIVE(536,98,0);
  PRIMITIVE(537,109,0);
  PRIMITIVE(407,71,0);
  PRIMITIVE(352,38,0);
  PRIMITIVE(538,33,0);
  PRIMITIVE(539,56,0);
  PRIMITIVE(540,35,0);{:265}{334:}
  PRIMITIVE(597,13,256);
  PARLOC := CURVAL;
  PARTOKEN := 4095+PARLOC;{:334}{376:}
  PRIMITIVE(629,104,0);
  PRIMITIVE(630,104,1);{:376}{384:}
  PRIMITIVE(631,110,0);
  PRIMITIVE(632,110,1);
  PRIMITIVE(633,110,2);
  PRIMITIVE(634,110,3);
  PRIMITIVE(635,110,4);{:384}{411:}
  PRIMITIVE(476,89,0);
  PRIMITIVE(500,89,1);
  PRIMITIVE(395,89,2);
  PRIMITIVE(396,89,3);
{:411}{416:}
  PRIMITIVE(668,79,102);
  PRIMITIVE(669,79,1);
  PRIMITIVE(670,82,0);
  PRIMITIVE(671,82,1);
  PRIMITIVE(672,83,1);
  PRIMITIVE(673,83,3);
  PRIMITIVE(674,83,2);
  PRIMITIVE(675,70,0);
  PRIMITIVE(676,70,1);
  PRIMITIVE(677,70,2);
  PRIMITIVE(678,70,3);
  PRIMITIVE(679,70,4);{:416}{468:}
  PRIMITIVE(735,108,0);
  PRIMITIVE(736,108,1);
  PRIMITIVE(737,108,2);
  PRIMITIVE(738,108,3);
  PRIMITIVE(739,108,4);
  PRIMITIVE(740,108,5);
{:468}{487:}
  PRIMITIVE(757,105,0);
  PRIMITIVE(758,105,1);
  PRIMITIVE(759,105,2);
  PRIMITIVE(760,105,3);
  PRIMITIVE(761,105,4);
  PRIMITIVE(762,105,5);
  PRIMITIVE(763,105,6);
  PRIMITIVE(764,105,7);
  PRIMITIVE(765,105,8);
  PRIMITIVE(766,105,9);
  PRIMITIVE(767,105,10);
  PRIMITIVE(768,105,11);
  PRIMITIVE(769,105,12);
  PRIMITIVE(770,105,13);
  PRIMITIVE(771,105,14);
  PRIMITIVE(772,105,15);
  PRIMITIVE(773,105,16);
{:487}{491:}
  PRIMITIVE(774,106,2);
  HASH[2618].RH := 774;
  EQTB[2618] := EQTB[CURVAL];
  PRIMITIVE(775,106,4);
  PRIMITIVE(776,106,3);
{:491}{553:}
  PRIMITIVE(801,87,0);
  HASH[2624].RH := 801;
  EQTB[2624] := EQTB[CURVAL];{:553}{780:}
  PRIMITIVE(898,4,256);
  PRIMITIVE(899,5,257);
  HASH[2615].RH := 899;
  EQTB[2615] := EQTB[CURVAL];
  PRIMITIVE(900,5,258);
  HASH[2619].RH := 901;
  HASH[2620].RH := 901;
  EQTB[2620].HH.B0 := 9;
  EQTB[2620].HH.RH := 29989;
  EQTB[2620].HH.B1 := 1;
  EQTB[2619] := EQTB[2620];
  EQTB[2619].HH.B0 := 115;
{:780}{983:}
  PRIMITIVE(970,81,0);
  PRIMITIVE(971,81,1);
  PRIMITIVE(972,81,2);
  PRIMITIVE(973,81,3);
  PRIMITIVE(974,81,4);
  PRIMITIVE(975,81,5);
  PRIMITIVE(976,81,6);
  PRIMITIVE(977,81,7);
{:983}{1052:}
  PRIMITIVE(1025,14,0);
  PRIMITIVE(1026,14,1);
{:1052}{1058:}
  PRIMITIVE(1027,26,4);
  PRIMITIVE(1028,26,0);
  PRIMITIVE(1029,26,1);
  PRIMITIVE(1030,26,2);
  PRIMITIVE(1031,26,3);
  PRIMITIVE(1032,27,4);
  PRIMITIVE(1033,27,0);
  PRIMITIVE(1034,27,1);
  PRIMITIVE(1035,27,2);
  PRIMITIVE(1036,27,3);
  PRIMITIVE(336,28,5);
  PRIMITIVE(340,29,1);
  PRIMITIVE(342,30,99);
{:1058}{1071:}
  PRIMITIVE(1054,21,1);
  PRIMITIVE(1055,21,0);
  PRIMITIVE(1056,22,1);
  PRIMITIVE(1057,22,0);
  PRIMITIVE(409,20,0);
  PRIMITIVE(1058,20,1);
  PRIMITIVE(1059,20,2);
  PRIMITIVE(965,20,3);
  PRIMITIVE(1060,20,4);
  PRIMITIVE(967,20,5);
  PRIMITIVE(1061,20,106);
  PRIMITIVE(1062,31,99);
  PRIMITIVE(1063,31,100);
  PRIMITIVE(1064,31,101);
  PRIMITIVE(1065,31,102);{:1071}{1088:}
  PRIMITIVE(1080,43,1);
  PRIMITIVE(1081,43,0);{:1088}{1107:}
  PRIMITIVE(1090,25,12);
  PRIMITIVE(1091,25,11);
  PRIMITIVE(1092,25,10);
  PRIMITIVE(1093,23,0);
  PRIMITIVE(1094,23,1);
  PRIMITIVE(1095,24,0);
  PRIMITIVE(1096,24,1);
{:1107}{1114:}
  PRIMITIVE(45,47,1);
  PRIMITIVE(349,47,0);
{:1114}{1141:}
  PRIMITIVE(1127,48,0);
  PRIMITIVE(1128,48,1);
{:1141}{1156:}
  PRIMITIVE(866,50,16);
  PRIMITIVE(867,50,17);
  PRIMITIVE(868,50,18);
  PRIMITIVE(869,50,19);
  PRIMITIVE(870,50,20);
  PRIMITIVE(871,50,21);
  PRIMITIVE(872,50,22);
  PRIMITIVE(873,50,23);
  PRIMITIVE(875,50,26);
  PRIMITIVE(874,50,27);
  PRIMITIVE(1129,51,0);
  PRIMITIVE(878,51,1);
  PRIMITIVE(879,51,2);
{:1156}{1169:}
  PRIMITIVE(861,53,0);
  PRIMITIVE(862,53,2);
  PRIMITIVE(863,53,4);
  PRIMITIVE(864,53,6);
{:1169}{1178:}
  PRIMITIVE(1147,52,0);
  PRIMITIVE(1148,52,1);
  PRIMITIVE(1149,52,2);
  PRIMITIVE(1150,52,3);
  PRIMITIVE(1151,52,4);
  PRIMITIVE(1152,52,5);{:1178}{1188:}
  PRIMITIVE(876,49,30);
  PRIMITIVE(877,49,31);
  HASH[2617].RH := 877;
  EQTB[2617] := EQTB[CURVAL];
{:1188}{1208:}
  PRIMITIVE(1171,93,1);
  PRIMITIVE(1172,93,2);
  PRIMITIVE(1173,93,4);
  PRIMITIVE(1174,97,0);
  PRIMITIVE(1175,97,1);
  PRIMITIVE(1176,97,2);
  PRIMITIVE(1177,97,3);
{:1208}{1219:}
  PRIMITIVE(1191,94,0);
  PRIMITIVE(1192,94,1);
{:1219}{1222:}
  PRIMITIVE(1193,95,0);
  PRIMITIVE(1194,95,1);
  PRIMITIVE(1195,95,2);
  PRIMITIVE(1196,95,3);
  PRIMITIVE(1197,95,4);
  PRIMITIVE(1198,95,5);
  PRIMITIVE(1199,95,6);
{:1222}{1230:}
  PRIMITIVE(415,85,3983);
  PRIMITIVE(419,85,5007);
  PRIMITIVE(416,85,4239);
  PRIMITIVE(417,85,4495);
  PRIMITIVE(418,85,4751);
  PRIMITIVE(477,85,5574);
  PRIMITIVE(412,86,3935);
  PRIMITIVE(413,86,3951);
  PRIMITIVE(414,86,3967);{:1230}{1250:}
  PRIMITIVE(941,99,0);
  PRIMITIVE(953,99,1);{:1250}{1254:}
  PRIMITIVE(1217,78,0);
  PRIMITIVE(1218,78,1);{:1254}{1262:}
  PRIMITIVE(274,100,0);
  PRIMITIVE(275,100,1);
  PRIMITIVE(276,100,2);
  PRIMITIVE(1227,100,3);
{:1262}{1272:}
  PRIMITIVE(1228,60,1);
  PRIMITIVE(1229,60,0);
{:1272}{1277:}
  PRIMITIVE(1230,58,0);
  PRIMITIVE(1231,58,1);
{:1277}{1286:}
  PRIMITIVE(1237,57,4239);
  PRIMITIVE(1238,57,4495);
{:1286}{1291:}
  PRIMITIVE(1239,19,0);
  PRIMITIVE(1240,19,1);
  PRIMITIVE(1241,19,2);
  PRIMITIVE(1242,19,3);
{:1291}{1344:}
  PRIMITIVE(1285,59,0);
  PRIMITIVE(594,59,1);
  WRITELOC := CURVAL;
  PRIMITIVE(1286,59,2);
  PRIMITIVE(1287,59,3);
  PRIMITIVE(1288,59,4);
  PRIMITIVE(1289,59,5);{:1344};
END;{$ENDIF}
{:1336}









{ ----------------------------------------------------------------------
  End of program execution
  ---------------------------------------------------------------------- }

{1335:}
PROCEDURE FINALCLEANUP;
VAR C: SMALLNUMBER;
BEGIN
  C := CURCHR;
  IF C<>1 THEN EQTB[5312].INT := -1;
  IF job_name='' THEN OPENLOGFILE;
  WHILE INPUTPTR>0 DO begin
    IF CURINPUT.STATEFIELD=0 THEN ENDTOKENLIST
    ELSE ENDFILEREADI;
  end;
  WHILE OPENPARENS>0 DO BEGIN
    print_str(' )');
    OPENPARENS := OPENPARENS-1;
  END;
  IF CURLEVEL>1 THEN BEGIN
    print_nl_str('(' + print_esc('end') + ' occurred inside a group at level ' +
      print_int(CURLEVEL-1) + ')');
  END;
  WHILE CONDPTR<>0 DO BEGIN
    print_nl_str('(' + print_esc('end') + ' occurred when ' + print_cmd_chr(105,CURIF));
    IF IFLINE<>0 THEN BEGIN
      print_str(' on line ' + print_int(IFLINE));
    END;
    print_str(' was incomplete)');
    IFLINE := MEM[CONDPTR+1].INT;
    CURIF := MEM[CONDPTR].HH.B1;
    TEMPPTR := CONDPTR;
    CONDPTR := MEM[CONDPTR].HH.RH;
    FREENODE(TEMPPTR,2);
  END;
  IF HISTORY<>0 THEN
    IF ((HISTORY=1)OR(INTERACTION<3)) THEN
      IF SELECTOR=19 THEN
  BEGIN
    SELECTOR := 17;
    print_nl_str('(see the transcript file for additional information)');
    SELECTOR := 19;
  END;
  IF C=1 THEN BEGIN
    {$IFDEF INITEX}
      FOR C:=0 TO 4 DO
        IF CURMARK[C]<>0 THEN DELETETOKENR(CURMARK[C]);
      IF LASTGLUE<>65535 THEN DELETEGLUERE(LASTGLUE);
      StoreFormatFile;
    {$ELSE}
      print_nl_str('(\dump is performed only by INITEX)');
    {$ENDIF}
  END;
END;
{:1335}

{1333:}
PROCEDURE close_files_and_terminate;
VAR K: Int32;
BEGIN
  {1378:}
  FOR K:=0 TO 15 DO
    IF WRITEOPEN[K]THEN close(WRITEFILE[K])
  {:1378};
  EQTB[5312].INT := -1;

{$IFDEF STATS}
  IF EQTB[5294].INT>0 THEN{1334:}
    IF LOGOPENED THEN
      BEGIN
        WRITELN(LOGFILE, ' ');
        WRITELN(LOGFILE,'Here is how much of TeX''s memory',' you used:');
        WRITE(LOGFILE,' ',STRPTR-INITSTRPTR:1,' string');
        IF STRPTR<>INITSTRPTR+1 THEN WRITE(LOGFILE,'s');
        WRITELN(LOGFILE,' out of ',MAXSTRINGS-INITSTRPTR:1);
        WRITELN(LOGFILE,' ',POOLPTR-INITPOOLPTR:1,' string characters out of ',
                POOLSIZE-INITPOOLPTR:1);
        WRITELN(LOGFILE,' ',LOMEMMAX-MEMMIN+MEMEND-HIMEMMIN+2:1,
                ' words of memory out of ',MEMEND+1-MEMMIN:1);
        WRITELN(LOGFILE,' ',CSCOUNT:1,' multiletter control sequences out of ',
                2100:1);
        WRITE(LOGFILE,' ',FMEMPTR:1,' words of font info for ',FONTPTR-0:1,
              ' font');
        IF FONTPTR<>1 THEN WRITE(LOGFILE,'s');
        WRITELN(LOGFILE,', out of ',FONTMEMSIZE:1,' for ',FONTMAX-0:1);
        WRITE(LOGFILE,' ',HYPHCOUNT:1,' hyphenation exception');
        IF HYPHCOUNT<>1 THEN WRITE(LOGFILE,'s');
        WRITELN(LOGFILE,' out of ',307:1);
        WRITELN(LOGFILE,' ',MAXINSTACK:1,'i,',MAXNESTSTACK:1,'n,',MAXPARAMSTAC:1
                ,'p,',MAXBUFSTACK+1:1,'b,',MAXSAVESTACK+6:1,'s stack positions out of ',
                STACKSIZE:1,'i,',NESTSIZE:1,'n,',PARAMSIZE:1,'p,',BUFSIZE:1,'b,',
                SAVESIZE:1,'s');
      END{:1334};
{$ENDIF};

{642:}
  WHILE CURS>-1 DO BEGIN
    IF CURS>0 
    THEN dvi_out(142)
    ELSE BEGIN
      dvi_out(140);
      TOTALPAGES := TOTALPAGES+1;
    END;
    CURS := CURS-1;
  END;
  
  IF TOTALPAGES=0
  THEN print_nl_str('No pages of output.')
  ELSE BEGIN
    dvi_out(248);
    DVIFOUR(LASTBOP);
    LASTBOP := DVIOFFSET+DVIPTR-5;
    DVIFOUR(25400000);
    DVIFOUR(473628672);
    prepare_mag;
    DVIFOUR(EQTB[5280].INT);
    DVIFOUR(MAXV);
    DVIFOUR(MAXH);
    dvi_out(MAXPUSH DIV 256);
    dvi_out(MAXPUSH MOD 256);
    dvi_out((TOTALPAGES DIV 256) MOD 256);
    dvi_out(TOTALPAGES MOD 256);

    {643:}
    WHILE FONTPTR>0 DO BEGIN
      IF FONTUSED[FONTPTR] THEN DVIFONTDEF(FONTPTR);
      FONTPTR := FONTPTR-1;
    END
    {:643};

    dvi_out(249);
    DVIFOUR(LASTBOP);
    dvi_out(2);
    K := 4+((dvi_buf_size-DVIPTR)MOD 4);
    WHILE K>0 DO BEGIN
      dvi_out(223);
      K := K-1;
    END;

    {599:}
    IF DVILIMIT=HALFBUF THEN WRITEDVI(HALFBUF,dvi_buf_size-1);
    IF DVIPTR>0 THEN WRITEDVI(0,DVIPTR-1){:599};
    print_nl_str('Output written on ' + output_file_name + ' (');
      {FIXME: this is the only reason for saving output_file_name}
      PRINTINT(TOTALPAGES);
      print_str(' page');
      IF TOTALPAGES<>1 THEN PRINTCHAR(115);
      print_str(', ');
      PRINTINT(DVIOFFSET+DVIPTR);
      print_str(' bytes).');
      close(DVIFILE);
  END;
  {:642}

  IF LOGOPENED THEN BEGIN
    WRITELN(LOGFILE);
    close(LOGFILE);
    SELECTOR := SELECTOR-2;
    IF SELECTOR=17 THEN BEGIN
      print_nl_str('Transcript written on ' + 
                   PrintableStr(GetString(LOGNAME)) + '.');
      PRINTLN;
    END;
  END;
  halt(History);
END;
{:1333}



{1332:}
BEGIN
  HISTORY := 3;

  assert((half_error_line>=30) and (half_error_line<=error_line-15));
  assert(max_print_line>=60);
  assert((dvi_buf_size mod 8) = 0);
  assert(mem_bot+1100 <= mem_top);
  assert(hash_prime <= hash_size);
  assert(max_in_open < 128);
  assert(mem_top >= 256+11);

  assert((mem_min<=mem_bot) and (mem_max>=mem_top));
  assert((min_quarterword <= 0) and (max_quarterword>=127));
  assert((min_halfword <= 0) and (max_halfword>=32767));
  assert((min_quarterword >= min_halfword) and (max_quarterword <= max_halfword));
  assert((mem_min >= min_halfword) and (mem_max<max_halfword) and (mem_bot-mem_min<=max_halfword+1));
  assert((font_base>=min_quarterword) and (font_max<=max_quarterword));
  assert(font_max <= font_base+256);
  assert((save_size <= max_halfword) or (max_strings <= max_halfword));
  assert(buf_size <= max_halfword);
  assert(max_quarterword-min_quarterword >= 255);

  assert(cs_token_flag+undefined_control_sequence <= max_halfword);
  assert(2*max_halfword >= mem_top-mem_min);

  InitGeneral;

{$IFDEF DEBUGGING}
  WASMEMEND := MEMMIN;
  WASLOMAX := MEMMIN;
  WASHIMIN := MEMMAX;
  PANICKING := FALSE;
{$ENDIF}

  TALLY := 0;
  TERMOFFSET := 0;
  FILEOFFSET := 0;

  write(output,'This is TeX, Version 3.141592653 Free Pascal');

{$IFDEF INITEX}
  assert((mem_min = mem_bot) and (mem_max = mem_top));

  InitInitex;
  GetStringsStarted;
  INITPRIM;
  INITSTRPTR := STRPTR;
  INITPOOLPTR := POOLPTR;

  writeln(output, ' (INITEX)');
{$ELSE}
  writeln(output, ' (no format preloaded)');
{$ENDIF}

  fix_date_and_time;
  InitTerminal;
  TryToLoadFormatFile;

  {FIXME: What is this for?
  if end_line_char_inactive then decr(limit)
  else  buffer[limit]:=end_line_char;}
  IF (EQTB[5311].INT<0) OR (EQTB[5311].INT>255) 
    THEN CURINPUT.LIMITFIELD := CURINPUT.LIMITFIELD-1
    ELSE BUFFER[CURINPUT.LIMITFIELD] := EQTB[5311].INT;

  MAGICOFFSET := STRSTART[892]-9*16{:765};
  IF INTERACTION=0 THEN SELECTOR := 16
                   ELSE SELECTOR := 17;

  IF (CURINPUT.LOCFIELD<CURINPUT.LIMITFIELD) AND
     (EQTB[3983+BUFFER[CURINPUT.LOCFIELD]].HH.RH<>0)
    THEN STARTINPUT;

  HISTORY := 0;
  MAINCONTROL;
  FINALCLEANUP;
  close_files_and_terminate;
END.{:1332}
