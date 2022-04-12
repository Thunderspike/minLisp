#define _INT 1
#define _BOOL 2
#define _UNDETERMINED 3
#define _PARAMLIST 4

Symbol* createSymbol(char lexeme[255], int type, int val) {
    Symbol* nSymbol_p =  malloc(sizeof(Symbol));
    nSymbol_p->lexeme = (char *) malloc(sizeof(STR_SIZE));
    strcpy(nSymbol_p->lexeme, lexeme);
    nSymbol_p->type = type;
    nSymbol_p->val = val;

    return nSymbol_p;
}

1. arrays - ε {
    // always fist node reached - perfect place to initialize global state. 
    initGlobalState();
}


2. id_list - id {
    printf("\n id_list - ID (%s)", $1);     
    Symbol* sym_p = (Symbol*) malloc(sizeof(Symbol));
    sym_p = get(currScope_p, $1);
    
    // lexeme shouldn't exist - if it does its value will get overwritten, for now
    if(sym_p)
        printf("Parameter %s already defined", $1);

    sym_p = createSymbol($1, _INT, 0);
    add(currScope_p, sym_p); 

    // always left-most node for id_list - create a new paramListScope to keep track of # of and param objects
    PLScope* plScope_p = (PLScope*) malloc(sizeof(PLScope));
    plScope_p = _newPLScope();

    _addToPL(plScope_p, sym_p);
    
    $$ = plScope_p;
}
3. id_list - id_list id {
    printf("\n id_list - id_list %s", $2);
    Symbol* sym_p = malloc(sizeof(Symbol));
    sym_p = get(currScope_p, $2);

    // lexeme shouldn't exist - if it does its value will get overwritten, for now
    if(sym_p)
        printf("Parameter %s already defined", $2);

    sym_p = createSymbol($2, _INT, 0);
    add(currScope_p, sym_p); 
    
    // use other copy to pass up to param_list for analysis.
    PLScope* plScope_p = $1;
    _addToPL(plScope_p, sym_p);
    
    $$ = plScope_p;
}
4. *3
5. function - '(' "define" ID param_list {} expr ')' {
    // add function to function scope
    FunctionData* funcEntry_p = getFuncO($3);
    // entry shouldn't exist, if it does it'll get overwritten
    if(funcEntry_p)
        prinf("Function '$s' already declared", $3);

    PLScope* plScope_p = (PLScope*) malloc(sizeof(PLScope));
    plScope_p = (PLScope *) $4->ptr;

    _printPL(plScope_p);

    // report function param number to function hashtable entry
    createFuncData($3, plScope_p->count, _UNDETERMINED);
}

// --- todo above: report scope name so that we can connect `"define" id param_list` to `expr` which ultimately returns the type of the function
6. expr - id {
    Symbol* sym_p = malloc(sizeof(Symbol));
    sym_p = get(currScope_p, $1);

    if(!sym_p){ // lexeme should exist
        printf("Undeclared variable $s", $1);
        // create a symbol to return for type's sake
        sym_p = createSymbol($1, _UNDETERMINED, 0);
    } 

    $$ = sym_p;
}
7. expr - num {
    $$ = createSymbol("_NUMERIC_VAL_", _INT, $1);
}
8. expr - ( = expr expr ) {
    printf("\n expr - '(' '=' expr expr ')'");   

    // check here, I don't think passed pointers need allocated.
    Symbol* exp_1 = $3;
    Symbol* exp_1 = $4;

    Symbol* sym_p = malloc(sizeof(Symbol));
    // no matter whether UNDEFINED | INT | BOOl combination, return comparison of two exprs
    symp_p = createSymbol("_EQ_EXP_EXP", _BOOL, exp_1->val == exp_2->val);

    printf("\n\tlexeme: %s, type: %d, val: %d", symp_p->lexeme, symp_p->type, symp_p->type, symp_p->val);

    $$ = symp_p;
}
9. -> *6
10: -> NULL
11. actual_list -> ε {
    printf("\n actual_list -> ε");     
  
    // left-most node, create a new parameterListScope obj
    $$ = _newPLScope();        
}
12. -> *10
13. -> *11
14. -> *6
15. -> *7
16. expr -> '(' '-' expr expr ')' {
    // if either expr isn't INT, print an error message, but continue computation
    if($3->type != _INT || $4->type != _INT) 
        printf("\n( - epxr expr ) expects arguments of type 'int'");

    $$ = createSymbol("_MIN_EXP_EXP", _INT, ($3->val - $4->val));
}
17. actual_list -> actual_list expr {
    printf("\n actual_list - actual_list expr -> ε");  
    PLScope* plScope_p = $1;
    _addToPL(plScope_p, $2);
    $$ = plScope_p;           
}

18. expr -> ( id actual_list ) {
    // Ideally we check first post id to report func DNE then we check params so that underlying calls don't get printed first, but this'll do for now
    FunctionData* funcO = getFuncO($2);
    if(!funcO || funcO->undefined == 1) {
        printf("Undeclared function %s", $2);
        if(!funcO) {
            // add function to global function tracker (with undefined flag) to later determine type
            FunctionData* undefinedFunc_p = createFuncData($2, 0, _UNDETERMINED);
            undefinedFunc_p->undefined = 1;
            funcO = addFunc(undefinedFunc_p);
        }
    } else {
        // check num of params for existing functions
        if(funcO->paramsCount != $3->count) {
            printf("Function %s expected %d parms", $2, $3->count);
        }
    }
    Symbol* param = (Symbol*) malloc(sizeof(Symbol);
    for(int i = 0; i < $3->count, i++) {
        param = _getFromPL($3, $3->ids_p[i]);
        if(param->type != _INT)
            printf("Functions expect parameters of type int. Param at index %d is not an int", i);
    }

    // the value here will need to be the value retreived from running the function instead of 0
    $$ = createSymbol("_ID_ACTUAL-LIST", funcO->type, 0);
}

19: -> *17
20: -> *18

21. expr -> ( if expr expr expr ) {
    // print error if types don't match, but ignore if either type is undetermined
    if($4->type != $5->type || !($4->type == _UNDETERMINED  || $5 == _UNDETERMINED) )) {
        printf("Types of 'if' statement need to match");
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