#define _INT 1
#define _BOOL 2
#define _UNDETERMINED 3
#define _PARAMLIST 4

1. arrays - ε {
    // always fist node reached - perfect place to initialize global state. 
    initGlobalState();
}

2. function - '(' "define" ID {
    printf("\n function - '(' 'define' %s param_list {} expr ')'", $3);

    // check if main is already defined - if it has, exit program
    if(getFuncO("main")){
        printf("Line %d --- Fatal: function 'main' need to be the last function declared in the program.\nExiting.\n", yylloc.first_line);
        exit(0);
    }

    FunctionData* funcEntry_p = getFuncO($3);
    // entry shouldn't exist, if it does it'll get overwritten
    if(funcEntry_p && funcEntry_p->isUndefined == 1) {
        // if function is defined previousy as undefined, re-use the stored obj
        funcEntry_p->type = _UNDETERMINED;
        funcEntry_p->isUndefined = 0;
    } else {
        if(funcEntry_p && funcEntry_p->isUndefined != 1) {
            printf("Line %d --- Function '%s' already declared", yylloc.first_line, $3);

        addFunc(createFuncData($3, 0, _UNDETERMINED));
    }

    // createScope
    createScope($3);
} 
21.
param_list expr ')' {
    FunctionData* funcEntry_p = getFuncO(currScope_p->name);
    // set return type
    funcEntry_p->type = $2->type;

    printScopeSymbols(currScope_p);

    // pop fuunc scop
    currScope_p = currScope_p->enclosingScope_p;
}


3. id_list - id {
    printf("\n id_list - ID (%s)", $1);     
    Symbol* sym_p = (Symbol*) malloc(sizeof(Symbol));
    sym_p = get(currScope_p, $1);
    
    // lexeme shouldn't exist - if it does its value will get overwritten, for now
    if(sym_p)
        printf("Line %d --- Parameter %s already defined", yylloc.first_line, $1);

    sym_p = createSymbol($1, _INT, 0);
    add(currScope_p, sym_p); 

    // always left-most node for id_list - create a new paramListScope to keep track of # of and param objects
    PLScope* plScope_p = (PLScope*) malloc(sizeof(PLScope));
    plScope_p = _newPLScope();

    _addToPL(plScope_p, sym_p);
    
    $$ = plScope_p;
}
4. id_list - id_list id {
    printf("\n id_list - id_list %s", $2);
    Symbol* sym_p = malloc(sizeof(Symbol));
    sym_p = get(currScope_p, $2);

    // lexeme shouldn't exist - if it does its value will get overwritten, for now
    if(sym_p)
        printf("Line %d --- Parameter %s already defined", yylloc.first_line, $2);

    sym_p = createSymbol($2, _INT, 0);
    add(currScope_p, sym_p); 
    
    // use other copy to pass up to param_list for analysis.
    PLScope* plScope_p = $1;
    _addToPL(plScope_p, sym_p);
    
    $$ = plScope_p;
}
5. *4 
6. param_list -> ( id_list ) {
    int paramsCount = 0;

    PLScope* plScope_p = (PLScope*) malloc(sizeof(PLScope));

    if($2){
        plScope_p = $2;

        _printPL(plScope_p);
        paramsCount = plScope_p->count;
    }

    // report function param number to function hashtable entry
    FunctionData* funcEntry_p = getFuncO(currScope_p->name);
    funcEntry_p->paramsCount = paramsCount

    $$ = plScope_p;
}

7. expr - id {
    printf("\n expr - ID (%s)", $1);    

    Symbol* sym_p = malloc(sizeof(Symbol));
    sym_p = get(currScope_p, $1);

    if(!sym_p){ // lexeme should exist
        printf("Line %d --- Undeclared variable %s", yylloc.first_line, $1);
        // create a symbol to return for type's sake
        sym_p = createSymbol($1, _UNDETERMINED, 0);
        // micro optimization / pain saver - if we cidentify current scope as a functions, we can say the type is int no matter what
    } 

    $$ = sym_p;
}
8. expr - num {
    printf("\n expr - NUM (%d)", $1);
    $$ = createSymbol("_NUMERIC_VAL_", _INT, $1);
}
9. expr - ( = expr expr ) {
    printf("\n expr - '(' '=' expr expr ')'");      

    Symbol* exp_1 = $3;
    Symbol* exp_2 = $4;

    Symbol* sym_p = malloc(sizeof(Symbol));
    // no matter whether UNDEFINED | INT | BOOl combination, return comparison of two exprs
    sym_p = createSymbol("_EQ_EXP_EXP", _BOOL, exp_1->val == exp_2->val);

    printf("\n\tlexeme: %s, type: %d, val: %d", sym_p->lexeme, sym_p->type, sym_p->val);

    $$ = sym_p;
}
10. -> *7
11. actual_list -> ε {
    printf("\n actual_list -> ε");
  
    // left-most node, create a new parameterListScope obj
    $$ = _newPLScope();        
}
12. -> *11
13. -> *7
14. -> *8
15. expr -> '(' '-' expr expr ')' {
    printf("\n expr - '(' '-' expr expr ')'");  
    // if either expr isn't INT, print an error message, but continue computation
    if($3->type != _INT || $4->type != _INT) 
        printf("\nLine %d --- ( - epxr expr ) expects arguments of type 'int'", yylloc.first_line);

    $$ = createSymbol("_MIN_EXP_EXP", _INT, ($3->val - $4->val));
}
16. actual_list -> actual_list expr {
    printf("\n actual_list - actual_list expr"); 
    PLScope* plScope_p = $1;
    _addToPL(plScope_p, $2);

    _printPL(plScope_p);

    $$ = plScope_p;           
}

17. expr -> ( id actual_list ) {
    printf("\n expr - '(' ID (%s) actual_list ')'", $2);  

    FunctionData* funcO = (FunctionData*) malloc(sizeof(FunctionData));
    funcO = getFuncO($2);

    if(!funcO || funcO->isUndefined == 1) {
        printf("Line %d --- Undeclared function %s", yylloc.first_line, $2);
        if(!funcO) {
            // add function to global function tracker (with undefined flag) to later determine type
            FunctionData* undefinedFunc_p = createFuncData($2, 0, _UNDETERMINED);
            undefinedFunc_p->isUndefined = 1;
            funcO = addFunc(undefinedFunc_p);
        }
    } else {
        // check num of params for existing functions
        if(funcO->paramsCount != $3->count) {
            printf("Line %d --- Function %s expected %d parms", yylloc.first_line, $2, $3->count);
        }
    }

    Symbol* param = (Symbol*) malloc(sizeof(Symbol));
    for(int i = 0; i < $3->count; i++) {
        param = _getFromPL($3, $3->ids_p[i]);
        if(param->type != _INT)
            printf("Line %d --- Functions expect parameters of type int. Param at index %d is not an int", yylloc.first_line, i);
    }

    int type = funcO->type
    if(strcasecmp(funcO->lexeme, currScope_p->name) == 0) {
        funcO->isRecursive = true;
        type = _INT;
    }

    // the value here will need to be the value retreived from running the function instead of 0
    $$ = createSymbol("_ID_ACTUAL-LIST", type, 0);
}

18: -> *16
19: -> *17
20. expr -> ( if expr expr expr ) {
    // print error if types don't match, but ignore if either type is undetermined
    if($4->type != $5->type || !($4->type == _UNDETERMINED  || $5 == _UNDETERMINED) )) {
        printf("Line %d --- Types of 'if' statement need to match", yylloc.first_line);
    }

    int type = _UNDETERMINED;
    if($4->type == _UNDETERMINED && $5->type != _UNDETERMINED)
        type = $5->type;
    else if($5->type == _UNDETERMINED && $4->type != _UNDETERMINED)
        type = $4->type;
    else if($4->type == $5->type)
        type = $4->type;

    // if true first, else second
    int val = expr.val == 1 ? $4->val : $5->val;

    $$ = createSymbol("_IF_EXPR_EXPR_EXPR", type, val);
}

21. ^
22. {}
23. *2
24. *3
25. *6
26. *7
27. *8
28. expr -> ( + expr expr ) {
    printf("\n expr - '(' '+' expr expr ')'");  
    // if either expr isn't INT, print an error message, but continue computation
    if($3->type != _INT || $4->type != _INT) 
        printf("\nLine %d --- ( + epxr expr ) expects arguments of type 'int'", yylloc.first_line);

    $$ = createSymbol("_MIN_EXP_EXP", _INT, ($3->val + $4->val));
}
29. *2
30. *22
31. *2
32. param_list -> ( ) {
    // report function param number to function hashtable entry
    FunctionData* funcEntry_p = getFuncO(currScope_p->name);
    funcEntry_p->paramsCount = 0

    $$ = NULL;
}
33. *11
34. *7
35. *16
36. *8
37. *16
38. *17
39. *21
40. *39
41. {}