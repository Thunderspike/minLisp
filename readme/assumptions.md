1. defaulting to _INT for ` expr: ( define id param_list expr )` in type conflics (as opposed to _UNDEFINED)
2. defaulting to _INT return for `expr: ID` in type conflicts (as opposed to _UNDEFINED)
3. defaulting to _INT for `expr: ( ID actual_list )` for IDs that have been overwritten by scope variables (323)
4. should default to _INT for `(if expr expr expr )` ~(292)
4. Asssuming function names cannot have the same names as array names (I have them in different data structures so the implementation technically allows it) - thus, it's illegal to call an array `main` and it's illegal to declare a function with a pre-existing array variable (although cascading errors are not caught here)
5. assume array's is only storing type ints
6. If there's a duplication of parameters in function calls I'm not counting them as valid, and thus not counting them in the cannocial number of parameters - thus a( x, y, y) has 2 paraeters and will complain if you try to call it with 3 or anything other than 2