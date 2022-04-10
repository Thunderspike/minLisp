%{
    #include "minLisp.tab.h"
    #include "minLisp.h"
%}

%option yylineno

id      [a-zA-Z][a-zA-Z0-9_]*
num     [0-9]+

%%
[(]         { yylval.enumVal = RPARAM; return('('); }
[)]         { yylval.enumVal = LPARAM; return(')'); }
[+]         { yylval.enumVal = PLUS; return('+'); }
[-]         { yylval.enumVal = MINUS; return('-'); }
[*]         { yylval.enumVal = MULT; return('*'); }
[/]         { yylval.enumVal = DIV; return('/'); }
[<]         { yylval.enumVal = LT; return('<'); }
[<=]        { yylval.enumVal = LTE; return('<='); }
[<>]        { yylval.enumVal = NEQ; return('<>'); }
[>]         { yylval.enumVal = GT; return('>'); }
[>=]        { yylval.enumVal = GTE; return('>='); }
[=]         { yylval.enumVal = EQ; return('='); }
[[]         { yylval.enumVal = LBRACK; return('['); }
[]]         { yylval.enumVal = RBRACK; return(']'); }
[&]         { yylval.enumVal = AMPER; return('&'); }
[|]         { yylval.enumVal = PIPE; return('|'); }
[!]         { yylval.enumVal = EXCL; return('!'); }

[array]     { return("array"); }
[seq]       { return("seq"); }
[define]    { return("define"); }
[if]        { return("if"); }
[while]     { return("while"); }
[write]     { return("write"); }
[writeln]   { return("writeln"); }
[read]      { return("read"); }
[and]       { return("and"); }
[or]        { return("or"); }
[not]       { return("not"); }
[set]       { return("set"); }
[let]       { return("let"); }
[true]      { return("true"); }
[false]     { return("false"); }
                    
{id}	    { 
                yylval.nameVal = 
                    (char*) malloc(strlen(yytext) + 1);
                strcpy(yylval.nameVal, yytext); 
                return(ID); 
            }
{num}       { yyval.intVal = atoi(yytext); return(NUM); }
[\t]	    { yylloc.first_column+=5; }
[ ]         { yylloc.first_column++; }
[\n]        { 
                yylloc.first_line++; 
                yylloc.first_column = 0;
            }
.           ;

%%