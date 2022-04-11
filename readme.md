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

## Part II: Symbol Table for MinLisp
The first part of the typechecking is to create a symbol table structure to keep track of the 
symbols that are defined in the program. The goal is to have a way to be sure that the variables 
used in an input program have been declared (and are visible) and that variable names aren’t 
duplicated in a single namespace. Named variables include function names (which are visible 
globally), array names (which are visible globally), parameters (which are only visible in the 
declared function) and identifiers in let statements (which are only visible in the expression 
associated with the let statement – which may in turn contain a let statement). These are the only
places where new identifiers are created. Since we are only using a single pass on the input 
program, a function cannot be (legally) called until it has been declared. However, recursive calls 
(such as in the recursive add function below) are legal.
 

To accomplish this tak, you will add actions to your YACC grammar from part I. You may be tempted to add actions to your lex file to put identifiers into your symbols table but this is not a good idea since you don't know in what context (definition or use) you are seeing the given token. So, send the elexeme to the parser (as described in class) and deal nwith the symbols appropriately there. To keep track of symbols encountered, you will have to implement a data structure that keeps track of the visible names for all currently active scopes during the parsing process. As the parsing process encountres a new scope, this information needs to be added and any identifiers declared are recorded in this scope (and checked to make sure they are not duplicates). The use of identifiers within a scope must be checked against the current symbol table to see if the name is valid. As a scope is exited, all the inforrmation about that scope is discarded. 

If, during the parse of a MinLisp program, you encountereed a duplicate declaration or variable that is not declared, a message about thisd should be printed out, along with the associated line number. Processing should continue (you don't have to do anything special nfor this to happen.) Be sure your error messages are informative. For example for this simple syntactically correcty MinLips program:

```MinLisp
(define add(x y x) 
    (if(= y 0)
        x
        (incr (add x (- y 1)))
    )
)
(define incr(x) (+ x y))

(define main() (add x 2))
```

example error messages could be:

**
Line 1: Duplicate name x in this scope
Line 4: Undeclared function incr
Line 8: Undeclared variable y
Line 10: Undeclared variable x.
**

Note: Generating incorrect messages is also an error. For example, in line 4, `incr` is unknown but `add` should be known and in your symbol table. Be sure that this part works before moving to part III.