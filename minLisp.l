%{
    #include "minLisp.tab.h"
%}

%option yylineno

id      [a-zA-Z][a-zA-Z0-9_]*
num     [0-9]+
comment \#(.*)

%%
[(]         { return('('); }
[)]         { return(')'); }
[+]         { return('+'); }
[-]         { return('-'); }
[*]         { return('*'); }
[/]         { return('/'); }
"<"         { return('<'); }
">"         { return('>'); }
"<="        { return(LTE); }
">="        { return(GTE); }
"<>"        { return(NEQ); }
"="         { return('='); }
[[]         { return('['); }
[]]         { return(']'); }
[&]         { return('&'); }
[|]         { return('|'); }
[!]         { return('!'); }

"array"     { yylval.keyword = "array"; return(_array); }
"seq"       { yylval.keyword = "seq"; return(_seq); }
"define"    { yylval.keyword = "define"; return(_define); }
"if"        { yylval.keyword = "if"; return(_if); }
"while"     { yylval.keyword = "while"; return(_while); }
"write"     { yylval.keyword = "write"; return(_write); }
"writeln"   { yylval.keyword = "writeln"; return(_writeln); }
"read"      { yylval.keyword = "read"; return(_read); }
"and"       { yylval.keyword = "and"; return(_and); }
"or"        { yylval.keyword = "or"; return(_or); }
"not"       { yylval.keyword = "not"; return(_not); }
"set"       { yylval.keyword = "set"; return(_set); }
"let"       { yylval.keyword = "let"; return(_let); }
"true"      { yylval.keyword = "true"; return(_true); }
"false"     { yylval.keyword = "false"; return(_false); }
                    
{id}	    { 
                yylval.nameVal = 
                    (char*) malloc(strlen(yytext) + 1);
                strcpy(yylval.nameVal, yytext); 
                return(ID); 
            }
{num}       { yylval.intVal = atoi(yytext); return(NUM); }
[\t]	    { yylloc.first_column+=5; }
[ ]         { yylloc.first_column++; }
{comment}   {
                // yylloc.first_line++; 
                // yylloc.first_column = 0;
            }
[\n]        { 
                yylloc.first_line++; 
                // yylloc.first_column = 0;
            }
%%