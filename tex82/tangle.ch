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
@d print(#)==write(term_out,#) {`|print|' means write on the terminal}
@y
@d term_out==OUTPUT {the terminal as an output file}
@d print(#)==write(term_out,#) {`|print|' means write on the terminal}
@z

@x
rewrite(term_out,'TTY:'); {send |term_out| output to the terminal}
@y
rewrite(term_out); {send |term_out| output to the terminal}
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
  assign(change_file, paramstr(2));
  reset(web_file);
  reset(change_file);
@z

@x
rewrite(Pascal_file); rewrite(pool);
@y
if paramcount <> 4 then begin
  writeln('Usage: tangle input.web input.ch output.p output.pool');
  halt;
end;
assign(Pascal_file, paramstr(3));
assign(pool,paramstr(4));
rewrite(Pascal_file);
rewrite(pool);
@z

@x
@t\4\4@>{here files should be closed if the operating system requires it}
@y
close(Pascal_file);
close(pool);
close(web_file);
close(change_file);
@z
