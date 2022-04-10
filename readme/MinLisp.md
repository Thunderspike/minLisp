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
