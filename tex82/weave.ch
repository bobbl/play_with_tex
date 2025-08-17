@x
@<Compiler directives@>=
@y
@<Compiler directives@>=
@{@&$M@&O@&D@&E I@&S@&O@}
@z

@x
@d othercases == others: {default for cases not listed explicitly}
@y
@d othercases == else {default for cases not listed explicitly}
@z

@x
@!text_file=packed file of text_char;
@y
@!text_file=text;
@z

@x
  end

@<Globals...@>=
@!term_out:text_file; {the terminal as an output file}
@y
  end

@d term_out==OUTPUT {the terminal as an output file}
@z

@x
rewrite(term_out,'TTY:'); {send |term_out| output to the terminal}
@y
@z

@x
@d update_terminal == break(term_out) {empty the terminal output buffer}
@y
@d update_terminal == flush(term_out) {empty the terminal output buffer}
@z

@x
begin reset(web_file); reset(change_file);
@y
begin
 assign(web_file, paramstr(1));
 reset(web_file);
 assign(change_file, paramstr(2));
 reset(change_file);
@z

@x
rewrite(tex_file);
@y
if paramcount <> 3 then begin
  write_ln('Usage: weave input.web input.ch output.tex');
  halt;
end;
assign(tex_file, paramstr(3));
rewrite(tex_file);
@z

% CLOSE must be in capital letters, otherwise it is replaced by the tangle macro
% `close=6`
@x
@t\4\4@>{here files should be closed if the operating system requires it}
@y
CLOSE(web_file);
CLOSE(change_file);
CLOSE(tex_file);
@z
