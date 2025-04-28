This change file for TeX is a minimal combination of
<https://bitbucket.org/HeikoTheissen/tex/src/master/web/tex.ch>
and tex.ch from the CTAN package <https://ctan.org/pkg/tex-fpc>

SPDX-License-Identifier: 0BSD


@x
@d banner=='This is TeX, Version 3.141592653' {printed when \TeX\ starts}
@y
@d banner=='This is TeX, Version 3.141592653 Free Pascal' {printed when \TeX\ starts}
@z

@x
@d debug==@{ {change this to `$\\{debug}\equiv\null$' when debugging}
@d gubed==@t@>@} {change this to `$\\{gubed}\equiv\null$' when debugging}
@y
@d debug==@{$IFDEF debugging@} {compile with \.{-ddebugging} when debugging}
@d gubed==@{$ENDIF@}
@z

@x
@d stat==@{ {change this to `$\\{stat}\equiv\null$' when gathering
  usage statistics}
@d tats==@t@>@} {change this to `$\\{tats}\equiv\null$' when gathering
  usage statistics}
@y
@d stat==@{$IFDEF stats@} {compile with \.{-dstats} when gathering
  usage statistics}
@d tats==@{$ENDIF@}
@z

@x
@d init== {change this to `$\\{init}\equiv\.{@@\{}$' in the production version}
@d tini== {change this to `$\\{tini}\equiv\.{@@\}}$' in the production version}
@y
@d init==@{$IFDEF initex@} {compile with \.{-dinitex} to get \.{INITEX}}
@d tini==@{$ENDIF@}
@z

@x
@<Compiler directives@>=
@y
@<Compiler directives@>=
@{@&$MODE ISO@}
@z

@x
@d othercases == others: {default for cases not listed explicitly}
@y
@d othercases == else {default for cases not listed explicitly}
@z

@x
@!file_name_size=40; {file names shouldn't be longer than this}
@!pool_name='TeXformats:TEX.POOL                     ';
@y
@!file_name_size=80; {file names shouldn't be longer than this}
@!pool_name='TeXformats/tex.pool';
@z

% accept horizontal tab and form feed
@x
for i:=0 to @'37 do xchr[i]:=' ';
@y
for i:=0 to @'37 do xchr[i]:=' ';
xchr[@'11] := chr(@'11); {accept horizontal tab}
xchr[@'14] := chr(@'14); {accept form feed}
@z

@x
@!alpha_file=packed file of text_char; {files that contain textual data}
@y
@!alpha_file=text_file; {files that contain textual data, untyped}
@z

@x
|name_of_file| could be opened.

@d reset_OK(#)==erstat(#)=0
@d rewrite_OK(#)==erstat(#)=0

@p function a_open_in(var f:alpha_file):boolean;
@y
|name_of_file| could be opened.

@d reset_OK(#)==IOResult=0
@d rewrite_OK(#)==IOResult=0

@p
@{@&$I-@} {I/O checking off}
function a_open_in(var f:alpha_file):boolean;
@z

@x
begin reset(f,name_of_file,'/O'); a_open_in:=reset_OK(f);
@y
begin assign(f, name_of_file); reset(f); a_open_in:=reset_OK(f);
@z

@x
begin rewrite(f,name_of_file,'/O'); a_open_out:=rewrite_OK(f);
@y
begin assign(f, name_of_file); rewrite(f); a_open_out:=rewrite_OK(f);
@z

@x
begin reset(f,name_of_file,'/O'); b_open_in:=reset_OK(f);
@y
begin assign(f, name_of_file); reset(f); b_open_in:=reset_OK(f);
@z

@x
begin rewrite(f,name_of_file,'/O'); b_open_out:=rewrite_OK(f);
@y
begin assign(f, name_of_file); rewrite(f); b_open_out:=rewrite_OK(f);
@z

@x
begin reset(f,name_of_file,'/O'); w_open_in:=reset_OK(f);
@y
begin assign(f, name_of_file); reset(f); w_open_in:=reset_OK(f);
@z

@x
begin rewrite(f,name_of_file,'/O'); w_open_out:=rewrite_OK(f);
end;
@y
begin assign(f, name_of_file); rewrite(f); w_open_out:=rewrite_OK(f);
end;
@{@&$I+@} {I/O checking on}
@z

@x
begin if bypass_eoln then if not eof(f) then get(f);
  {input the first character of the line into |f^|}
@y
begin
@z

@x
  last:=last_nonblank; input_ln:=true;
@y
  read_ln(f); {this replaces the |bypass_eoln| mechanism}
  last:=last_nonblank; input_ln:=true;
@z

@x
@<Glob...@>=
@!term_in:alpha_file; {the terminal as an input file}
@!term_out:alpha_file; {the terminal as an output file}
@y
@z

@x
@d t_open_in==reset(term_in,'TTY:','/O/I') {open the terminal for text input}
@d t_open_out==rewrite(term_out,'TTY:','/O') {open the terminal for text output}
@y
@d term_in==INPUT {the terminal as an input file}
@d term_out==OUTPUT {the terminal as an output file}
@d t_open_in==reset(term_in) {open the terminal for text input}
@d t_open_out==rewrite(term_out) {open the terminal for text output}
@z

@x
@d update_terminal == break(term_out) {empty the terminal output buffer}
@d clear_terminal == break_in(term_in,true) {clear the terminal input buffer}
@y
@d update_terminal == flush(term_out) {empty the terminal output buffer}
@d clear_terminal == do_nothing {clear the terminal input buffer}
@z

@x
@p function init_terminal:boolean; {gets the terminal input started}
label exit;
begin t_open_in;
@y
@d argv==p@&a@&r@&a@&m@&s@&t@&r
@d argc==paramcount

@p function input_argv:boolean; {feed command line arguments into input}
var args:shortstring;
    i:integer;
    last_nonblank:0..buf_size; {|last| with trailing blanks removed}
begin
  if paramcount = 0 then input_argv:=false
  else begin
    last:=first; last_nonblank:=first;
    args:='';
    for i:=1 to argc do args:=args + argv(i) + ' ';
    for i:=1 to LENGTH(args) do begin
      if last>=max_buf_stack then
        begin max_buf_stack:=last+1;
        if max_buf_stack=buf_size then
          @<Report overflow of the input buffer, and abort@>;
        end;
      buffer[last]:=xord[args[i]]; incr(last);
      if buffer[last-1]<>" " then last_nonblank:=last;
    end;
    last:=last_nonblank; input_argv:=true;
  end;
end;
@#
function init_terminal:boolean; {gets the terminal input started}
label exit;
begin if input_argv then
  begin init_terminal:=true; loc:=first; end
  else begin t_open_in;
@z

@x
  write_ln(term_out,'Please type the name of your input file.');
  end;
exit:end;
@y
  write_ln(term_out,'Please type the name of your input file.');
  end;
end;
exit:end;
@z

@x
name_of_file:=pool_name; {we needn't set |name_length|}
@y
name_of_file:=pool_name;
name_length:=19; {we must set |name_length| for |file_search|}
@z

@x
job_name_code: print(job_name);
@y
job_name_code: begin print(job_area);print(job_name);end;
@z

@x
@d TEX_area=="TeXinputs:"
@.TeXinputs@>
@d TEX_font_area=="TeXfonts:"
@y
@d TEX_area=="TeXinputs//" {\.{//} means all subdirectories}
@.TeXinputs@>
@d TEX_font_area=="TeXfonts//"
@z

@x
  if (c=">")or(c=":") then
@y
  if c="/" then
@z

@x
if k<=file_name_size then name_length:=k@+else name_length:=file_name_size;
for k:=name_length+1 to file_name_size do name_of_file[k]:=' ';
end;
@y
if k<=file_name_size then name_length:=k@+else name_length:=file_name_size;
for k:=name_length+1 to file_name_size do name_of_file[k]:=#0;
end;
@z

@x
TEX_format_default:='TeXformats:plain.fmt';
@y
TEX_format_default:='TeXformats/plain.fmt';
@z

@x
for k:=name_length+1 to file_name_size do name_of_file[k]:=' ';
@y
@^FPC Pascal@>
for k:=name_length+1 to file_name_size do name_of_file[k]:=#0;
@z

@x
@!job_name:str_number; {principal file name}
@y
@!job_name:str_number; {principal file name}
@!job_area:str_number; {directory name of principal file}
@!name_of_job_area:shortstring; {for passing to |file_search|}
@z

@x
begin cur_area:=""; cur_ext:=s;
@y
begin cur_area:=job_area; cur_ext:=s;
@z

@x
if job_name=0 then job_name:="texput";
@y
if job_name=0 then begin job_area:="";name_of_job_area:='';job_name:="texput";end;
@z

@x
@p procedure start_input; {\TeX\ will \.{\\input} something}
label done;
@y
@p procedure start_input; {\TeX\ will \.{\\input} something}
var j:pool_pointer;
label done;
@z

@x
  begin job_name:=cur_name; open_log_file;
@y
  begin job_area:=cur_area; name_of_job_area:='';
  for j:=str_start[job_area] to str_start[job_area+1]-1 do {pack
   |job_area| into shortstring}
    name_of_job_area:=name_of_job_area+xchr[so(str_pool[j])];
  job_name:=cur_name; open_log_file;
@z

@x
|if eof(tfm_file) then abort; end|\unskip'.
@^system dependencies@>

@d fget==get(tfm_file)
@y
|if eof(tfm_file) then abort; end|\unskip'.
@^system dependencies@>

@d fget==begin if eof(tfm_file) then abort;get(tfm_file);end
@z

@x
if eof(tfm_file) then abort;
for k:=np+1 to 7 do font_info[param_base[f]+k-1].sc:=0;
@y
{|eof(tfm_file)| is true after the last byte has been read}
for k:=np+1 to 7 do font_info[param_base[f]+k-1].sc:=0;
@z

@x
if (x<>69069)or eof(fmt_file) then goto bad_fmt
@y
if (x<>69069) then goto bad_fmt {|eof(fmt_file)| is true after the last word
  has been read}
@z

% print newline at end of output
@x
    slow_print(log_name); print_char(".");
@y
    slow_print(log_name); print_char("."); print_ln;
@z
