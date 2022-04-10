# CS 440/540 Spring 2022: MinLisp
This document is the language specification for MinLisp. It may evolve over the course 
of the semester so be sure to look at it again before you start every assignment.

## Lexical Elements

* Identifiers (id) start with an alphabetic character(upper or lower case), followed 
by zero or more alphabetic characters, numbers or _ (underscore)
* Numbers (num) are strings of digits and are non-negative (there is a negation 
operator)
* Keywords: **array**, **seq**, **define**, **if** **while**, **write**, **writeln**, 
            **read**, **and**, **or**, **not**, **set**, **let**, **true**, **false**
* Symbols: **(**, **)**, **+**, **-**, **\***, **/**, **<**, **<=**, **<>**, **>**, 
            **>=**, **=**, **[**, **]**, **&**, **|**, **!**

* The language is case sensitive, meaning that, for example, variables a and A are 
    different
* Comments start with a # symbol, continuing to the end of the line. Remember that 
    comments (as well as other white space such as tabs, spaces and newlines) should 
    be discarded. You should be matching the newlines to keep track of what line is 
    currently being processed.


```minLisp
 
ML		    :=	arrays program
arrays		:=	arrays array
            |   ε
array		:=	( array id num )
program		:=	program function
		    |	function 
function	:=	( define id param_list expr ) 
param_list	:=	( )
			|	( id_list ) 
id_list		:=	id_list id
		    |	id	 
expr		:=	num
            |	id 
            |	id [ expr ] 
            |	true
            |	false
            |	( if expr expr expr )
            |	( while expr expr )
            |	( id actual_list )
            |	( write expr )  
            |	( writeln expr )  
            |	( read )
            |	( let (assign_list ) expr )
            |	( set id expr ) 
            |	( set id [ expr ] expr ) 
            |	( + expr expr )
            |	( - expr expr)
            |	( * expr expr )
            |	( / expr expr)
            |	( < expr expr )
            |	( <= expr expr)
            |	( = expr expr )
            |	( <> expr expr)
            |	( - expr )   
            |	( and  expr expr)  	|	( &  expr expr)
            |	( or  expr expr )	|	( |  expr expr )
            |	( not expr ) 		|	( ! expr )  
            |   ( seq expr_list )
actual_list	:=	actual_list expr
		    |	ε
assign_list	:=	assign_list ( id expr )
		    |	( id expr ) 
expr_list   :=  expr_list expr
		    |	expr
```