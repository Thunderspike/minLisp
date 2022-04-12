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
            |	( < expr expr )     |	( > expr expr )
            |	( <= expr expr)     |	( >= expr expr)
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

## Types and Rules and Semantics

### Types
* The base types in MinLisp are **integer** and **boolean**. We also have a type constructor array which can be used to create named 1-D integer arrays of a pre-defined size. Array are only created globally anad are visible in all scopes unless an integer or boolean variable of the same name is created in a subscope.
* User defined functions create a subscope of the global scope. Each function has a name (which must be unique in the scope), some **number of parameters of type integer** and **returns the type of the expr (integer or boolean)** associated with the declaration. When a function is used, it must be called with the correct number of parameters of type integer. Each formal parameter in a declaration creates an integer variable by the name in this scope. 
* The *let* expression creates a new subscope with newly defined variables. The type of the variables is given by the type of the expression associated with that variable. This expression is discussed more in the next section.
* In any given scope, names must be unique. It is okay to re-use a name in a sub-scope. 

### Operators
The number and type of the operands, as well as the type of the result, for each operator is given in the table below. Precedence is not an issue since the operators are prefix. 

```
| Operator            | # Operands | Operand Types | Result Type |
|---------------------|------------|---------------|-------------|
| +, -, *             | 2          | integer       | integer     |
| -                   | 1          | integer       | integer     |
| <, >, =, <=, >=, <> | 2          | integer       | boolean     |
| &, \|, and, or      | 2          | boolean       | boolean     |
| !, not              | 1          | boolean       | boolean     |
```
### Expressions
Expressions have types and return values in MinLisp. The type and returns of some of the expressions is pretty straightforward but other require a little more description
* ( read )
    The read expression will read an integer from stdin and return that integer. The type of the read expression is integer.
* ( write expr ), ( writeln expr )
    The write expressions expect an **integer** exression that will be preinted to stdout. **The expression returns the value of the expression written and the type of the write expression is integer.**
* ( if expr expr expr) - (if bool expr1 expr2) where type of expr1 and expr2 matches
    The if expression has three associated expressions. **The first expression is the condition to be evaluated and must have type boolean**. The second expression is the expression to be evaluated (and returned) when the condition is true and the third expression will be evaluated (and returned) when the condition is false. *The type of the second and third expressions must match and must either be integer **or** boolean*. The if expression has a type that matches the type of the second and third expression since that is the result returned by the expression. 
* ( while expr expr )
    The while expression allows the second expression to be repeatedly evaluated as long as the first expression remains true. The type of the first expression must be boolean. The type of the while expression is the type of its second expression (as that is what is returned by the overall expression).
* ( seq expr+ )
    The sequence operator allows one or more expressions to be evaluated in sequential order. The value of the last (rightmost) expression in the sequence is returned by this expression and the type of that last expression is the type returend by the seq expression.
* ( set id expr) (set id[ expr ] expr)
    The two set expressions allow valuesx to be assigned to integers or booleans (for the first type) or array element (for the second). The overall type of the expression will be either integer or boolean depending on the assignment.
* ( let ( assign_list ) expr )
    The let expression **createes a new scope** and new user-defined variables and initial values are gien in the assign_list. The expression returns the value of the expression (and hence has the type of the expression). As an example `(let ((x 2)(y z)) + x y ) would create two new variables x and y with the values 2 and the current value of z (presumably defined in an enclosing scope). The overall expression will return the result of the (+ x y) expression and the type of the given let expression is integer. 
* ( id expr* )
    User defined expressions can be invoked with associated actual parameters. The function being called must exist. Direct recursion is allowed but not indirect. To make typechiecking recursion easier, you can assume that any recursive function returns the integer type. The paramter expressions must be type integer and the number of parameters should match the definition. The expression itself has a type that matches the function definition. 

## Other Notes

Another requirement of MinLisp is that the last function defined in the input must be called 'main'. When we generate code in the last assignment, this is where execution will start.