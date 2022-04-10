# CS 540 2022 Programming Assignment #3
## Due date 4/10/2022 (11:59pm)

## MinLisp and Type Checking

For this assignment, you will be using YACC and flex to create a parser and 
typechecker for MinLisp. Once you can parse MinLisp programs correctly, you will 
augment your parser with a symbol table and actions so that you are checking the
type system of MinLisp, as described in this document and in the associated MinLisp
specification. Work on each element of the task in sequence - don't move to the next
part until you know the previous part works! If you are working in C or C++, all input
will come from stdin. Output must go to the screen (stdout);

## Part I: Parsing MinLisp

Informatrion about the lexical elements are given in the spec. The first step is to 
use flex/jflex to have it find and return the given tokens. You will also want to
write a rule that allows you to count the lin in the input file. Once you are confident
that this is working, the next step is to use bison/byacc to write the parser itself.

The grammar for the language is given in the MinLisp specification. You shouldn't have
to make changes for this assignment but it's ok if you do (as long as the changes you
make do not change the language recognized).

If a syntax error is detected during parsing, YACC will terminate byt default. This is
fine; however, you need to create a yyerror() procedure so that at terminatiojn time, 
the line number where the error occurred can be printed. __Be sure that you can parse
all of the given examples (and MinLisp code that you write before moving to the next
step__