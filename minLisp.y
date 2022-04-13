%{
    #include "minLisp.tab.h"
    #include "minLisp.h"

    // Lex/YACC utilities
    int yylex();
    int yyerror(char *s);
    extern int yylineno;
%}

%locations

%union {
    char* keyword;
    char* nameVal;
    int intVal;
    struct Symbol* symbolPointerType;
    struct ParamsListScope* paramsListType;
}

%token _array _seq _define _if _while _write _writeln _read 
%token _and _or _not _set _let _true _false
%token LTE NEQ GTE
%token ID NUM 

%type<nameVal> ID 
%type<intVal> NUM
%type<symbolPointerType> expr 
%type<paramsListType> id_list param_list assign_list actual_list expr_list


%%  
ML          :   arrays program  {
    if(DEBUG) {
        printf("\n(%d) ML - arrays program", nodeCounter++);
        printFuncs();
        printArrays();
    }


    printf("\n");
}
            ;
arrays      :   %empty {
    if(DEBUG)
        printf("\n(%d) arrays - __empty__ ", nodeCounter++);

    // always fist node reached - perfect place to initialize global state. 
    initGlobalState();
}           
            |  arrays array {
    if(DEBUG)
        printf("\n(%d) arrays - arrays array ", nodeCounter++);

}
            ;
array       :   '(' _array ID NUM ')'    {
    if(DEBUG) 
        printf("\n(%d) array - '(' 'array' %s %d ')'", nodeCounter++, $3, $4);

    if(strcasecmp($3, (char*) "main") == 0)
        printf("\nLine %d --- Illegal variable name 'main' for arrays'", yylloc.first_line);

    ArrayObj* arrO_p = (ArrayObj*) malloc(sizeof(ArrayObj));
    arrO_p = getArrayO($3);

    if(arrO_p) {
        printf("\nLine %d --- Array '%s' has already been defined.", yylloc.first_line, $3);
    } else {
        int size = $4;
        if(size < 0) {
            printf("\nLine %d --- Array indices must be type integer and >= 0", yylloc.first_line);
            size = 0;
        }
        addArrToScope(createArrayO($3, size));
    }
}
            ;
program		:   program function    {
    if(DEBUG)
        printf("\n(%d) program - program function", nodeCounter++);
}
            |   function    {
    if(DEBUG)            
    printf("\n(%d) program - function", nodeCounter++);
}
            ;
function    :   '(' _define ID {
    if(DEBUG)
        printf("\n(%d) function - '(' 'define' ID (%s) {} param_list  expr ')'", nodeCounter++, $3);


    // check if main is already defined
    if(getFuncO("main"))
        printf("\nLine %d --- Last function must be main.\n", yylloc.first_line);
    
    if(getArrayO($3))
        printf("\nLine %d --- Variable '%s' already declared in scope as an array", yylloc.first_line, $3);

    FunctionData* funcEntry_p = getFuncO($3);
    // entry shouldn't exist, if it does it'll get overwritten
    if(funcEntry_p && funcEntry_p->isUndefined == 1) {
        // if function is defined previousy as undefined, re-use the stored obj
        funcEntry_p->type = _INT;
        funcEntry_p->isUndefined = 0;
    } else {
        if(funcEntry_p && funcEntry_p->isUndefined != 1)
            printf("\nLine %d --- Function '%s' already declared in scope", yylloc.first_line, $3);

        addFunc(createFuncData($3, 0, _INT));
    }

    // createScope
    createScope($3);
} param_list expr ')' {
    if(DEBUG)
        printf("\n(%d) function - '(' 'define' ID (%s) --> param_list  expr ')'", nodeCounter++, $3);

    FunctionData* funcEntry_p = getFuncO(currScope_p->name);
    // set return type
    funcEntry_p->type = $6->type;

    if(DEBUG)
        printScopeSymbols(currScope_p);

    // pop func scope
    currScope_p = currScope_p->enclosingScope_p;
}
            ;
param_list	:   '(' ')' {
    if(DEBUG)
        printf("\n(%d) param_list - '(' ')'", nodeCounter++);
    // report function param number to function hashtable entry
    FunctionData* funcEntry_p = getFuncO(currScope_p->name);
    funcEntry_p->paramsCount = 0;

    $$ = NULL;
}
            |   '(' id_list ')' {
    if(DEBUG)
        printf("\n(%d) param_list - '(' id_list ')'", nodeCounter++);

    int paramsCount = 0;

    PLScope* plScope_p = (PLScope*) malloc(sizeof(PLScope));

    if($2){
        plScope_p = $2;

        if(DEBUG)
            _printPL(plScope_p);
        paramsCount = plScope_p->count;
    }

    // report function param number to function hashtable entry
    FunctionData* funcEntry_p = getFuncO(currScope_p->name);
    funcEntry_p->paramsCount = paramsCount;

    if(DEBUG)
        printFuncs(funcEntry_p);


    $$ = plScope_p;
}
            ;
// internal type - PLScope*
id_list		:   id_list ID 
{
    if(DEBUG)
        printf("\n(%d) id_list - id_list %s", nodeCounter++, $2);
    Symbol* sym_p = malloc(sizeof(Symbol));
    sym_p = get(currScope_p, $2);

    // use other copy to pass up to param_list for keeps
    PLScope* plScope_p = $1;

    // lexeme shouldn't exist - if it does its value will get overwritten, for now
    if(sym_p)
        printf("\nLine %d --- Parameter '%s' already defined", yylloc.first_line, $2);
    else {
        // only add symbol if it's new to scope

        sym_p = createSymbol($2, _INT, 0);
        add(currScope_p, sym_p); 
         _addToPL(plScope_p, sym_p);
    }
     
    $$ = plScope_p;
}
            |   ID 
{
    if(DEBUG)
        printf("\n(%d) id_list - ID (%s)", nodeCounter++, $1);     

    Symbol* sym_p = (Symbol*) malloc(sizeof(Symbol));
    sym_p = createSymbol($1, _INT, 0);
    add(currScope_p, sym_p); 

    // always left-most node for id_list - create a new paramListScope to keep track of # of and param objects
    PLScope* plScope_p = (PLScope*) malloc(sizeof(PLScope));
    plScope_p = _newPLScope();

    _addToPL(plScope_p, sym_p);
    
    $$ = plScope_p;        
}
            ;

expr		:   NUM {
    if(DEBUG)
        printf("\n(%d) expr - NUM (%d)", nodeCounter++, $1);

    $$ = createSymbol("_NUMERIC_VAL_", _INT, $1);
}
            |   ID {
    if(DEBUG)
        printf("\n(%d) expr - ID (%s)", nodeCounter++, $1);    

    Symbol* sym_p = malloc(sizeof(Symbol));
    sym_p = get(currScope_p, $1);

    // lexeme should exist
    if(!sym_p){ 
        // if it doesn't, check it's a function or an array
        FunctionData* funcD_p = getFuncO($1);
        ArrayObj* arrO_p = getArrayO($1);
        if(funcD_p) 
            printf("\nLine %d --- Function used incorrectly: '%s'", yylloc.first_line, $1);
        else if(arrO_p)
            printf("\nLine %d --- Array used incorrectly: '%s'", yylloc.first_line, $1);
        else
            printf("\nLine %d --- Undeclared variable '%s'", yylloc.first_line, $1);

        // create a symbol to return for type's sake
        sym_p = createSymbol($1, _INT, 0);
        // micro optimization / pain saver - if we identify current scope as a functions, we can say the type is int no matter what
    } 

    $$ = sym_p;
}
            |   ID  '[' expr ']' {
    if(DEBUG)
        printf("\n(%d) expr - %s '[' expr ']'", nodeCounter++, $1);  

    ArrayObj* arrO_p = (ArrayObj*) malloc(sizeof(ArrayObj));
    Symbol* sym_p = (Symbol*) malloc(sizeof(Symbol));

    arrO_p = getArrayO($1);

    int arrAccessErr = 0;

    if(get(currScope_p, $1)) {
        printf("\nLine %d --- Variable '%s' in local scope as non-array", yylloc.first_line, $1);
        arrAccessErr = 1;
    } else if(!arrO_p) {
        printf("\nLine %d --- Undeclared array '%s'", yylloc.first_line, $1);
        arrAccessErr = 1;
    }

    if($3->type != _INT || $3->val < 0) {
        printf("\nLine %d --- Array indices must be type integer and >= 0", yylloc.first_line);
        arrAccessErr = 1;
    }

    if(arrO_p && $3->val >= arrO_p->capacity ) {
       printf("\nLine %d ---  Illegal index '%d' - array '%s' has a capacity of '%d' elements.", yylloc.first_line, $3->val, $1, arrO_p->capacity);
       arrAccessErr = 1;
    }

    if(arrAccessErr)
        sym_p = createSymbol("_ERR_ARR_ACCESS", _INT, 0);
    else {
        sym_p = arrO_p->arr[$3->val];
        if(!sym_p)  // maybe warn for null element? I don't see this done in real langs
            sym_p = createSymbol("_NULL_ARR_ELEMENT", _INT, 0);
    }
    $$ = sym_p;
}
            |   _true {
    if(DEBUG)
        printf("\n(%d) expr - 'true'", nodeCounter++);    

    // these should just be static symbols
    $$ = createSymbol("_TRUE", _BOOL, 1);
}
            |   _false {
    if(DEBUG)
        printf("\n(%d) expr - 'false'", nodeCounter++);

    $$ = createSymbol("_FALSE", _BOOL, 2);
}
            |   '(' _if expr expr expr ')' {
    if(DEBUG)
        printf("\n(%d) expr - '(' 'if' expr expr expr ')", nodeCounter++); 

    if($3->type != _BOOL)
        printf("\nLine %d --- Incorrect type for first expression in if expression: Boolean expected", yylloc.first_line);

    // print error if types don't match, but ignore if either type is undetermined
    if(
        $4->type != $5->type &&
        !($4->type == _UNDETERMINED || $5->type == _UNDETERMINED) 
    ) {
        printf("\nLine %d --- Non-matching types used in if statements clauses", yylloc.first_line);
    }

    int type = _UNDETERMINED; // if bool and int types, just pass up undetermined
    if($4->type == _UNDETERMINED && $5->type != _UNDETERMINED)
        type = $5->type;
    else if($5->type == _UNDETERMINED && $4->type != _UNDETERMINED)
        type = $4->type;
    else if($4->type == $5->type)
        type = $4->type;

    // if true first, else second
    int val = $3->val == 1 ? $4->val : $5->val;

    $$ = createSymbol("_IF_EXPR_EXPR_EXPR", type, val);  
}
            |   '(' _while expr expr ')' {
    if(DEBUG)
        printf("\n(%d) expr - '(' 'while' expr expr ')", nodeCounter++); 
    
    if($3->type != _UNDETERMINED && $3->type != _BOOL) 
        printf("\nLine %d --- Incorrect type for first expression in while expression: Boolean expected", yylloc.first_line);

    $$ = createSymbol("_WHILE_EXPR_EXPR", $4->type, $4->val);
}
            |   '(' ID actual_list ')' {
    if(DEBUG) {
        printf("\n(%d) expr - '(' ID (%s) actual_list ')'", nodeCounter++, $2);  
        _printPL($3);
    }

    int type = _INT;

    // make sure ID doesn't already exist in scope before doing function type checks
    if(get(currScope_p, $2)) {
        printf("\nLine %d --- Non function being used as a function: '%s'", yylloc.first_line, $2);
    } else {
        FunctionData* funcO = (FunctionData*) malloc(sizeof(FunctionData));
        funcO = getFuncO($2);

        if(!funcO || funcO->isUndefined == 1) {
            printf("\nLine %d --- Undeclared function: '%s'", yylloc.first_line, $2);
            if(!funcO) {
                // add function to global function tracker (with undefined flag) to later determine type
                FunctionData* undefinedFunc_p = createFuncData($2, 0, _UNDETERMINED);
                undefinedFunc_p->isUndefined = 1;
                funcO = addFunc(undefinedFunc_p);
            }
        } else {

            // check num of params for existing functions
            if(funcO->paramsCount != $3->count) {
                printf("\nLine %d --- Function '%s' expected [%d] parms", yylloc.first_line, $2, funcO->paramsCount);
            }
        }

        Symbol* param = (Symbol*) malloc(sizeof(Symbol));
        for(int i = 0; i < $3->count; i++) {
            param = _getFromPL($3, $3->ids_p[i]);
            if(param->type != _INT && param->type != _UNDETERMINED)
                printf("\nLine %d --- Functions expect parameters of type integer. Param at index [%d] is not an integer", yylloc.first_line, i);
        }

        type = funcO->type;
        if(strcasecmp(funcO->lexeme, currScope_p->name) == 0) {
            funcO->isRecursive = 1;
            type = _INT;
        }
    }
       
    // the value here will need to be the value retreived from running the function instead of 0
    $$ = createSymbol("_ID_ACTUAL-LIST", type, 0);   
}
            |   '(' _write expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'write' expr ')'", nodeCounter++);

    Symbol* sym_p = (Symbol*) malloc(sizeof(Symbol));
    sym_p = $3;

    if(sym_p->type != _INT && sym_p->type != _UNDETERMINED)
        printf("\nLine %d --- 'write' expects an integer type", yylloc.first_line);

    sym_p->type = _INT;
    
    $$ = sym_p;
}
            |   '(' _writeln expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'writeln' expr ')'", nodeCounter++);    

    Symbol* sym_p = (Symbol*) malloc(sizeof(Symbol));
    sym_p = $3;

    if(sym_p->type != _INT && sym_p->type != _UNDETERMINED)
        printf("\nLine %d --- '_writeln' expects an integer type", yylloc.first_line);

    sym_p->type = _INT;
    
    $$ = sym_p;
}
            |   '(' _read ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'read' ')'", nodeCounter++);  

    $$ = createSymbol("_READ", _INT, 0); 
}
            |   '(' _let {
    if(DEBUG) 
        printf("\n(%d) expr - '(' 'let' {} '(' assign_list ')' expr ')'", nodeCounter++); 

    // push scope
    createScope(NULL);

} '(' assign_list ')' {
    if(DEBUG) {
        printf("\n(%d) expr - '(' 'let' '(' assign_list ')' {} expr ')'", nodeCounter++);    
        printScopeSymbols(currScope_p);
    }
} expr ')' {
    if(DEBUG) {
        printf("\n(%d) expr - '(' 'let'  '(' assign_list ')' --> expr ')'", nodeCounter++);    
    }

    // pop scope
    currScope_p = currScope_p->enclosingScope_p;

    $$ = $8;
} 
            |   '(' _set ID expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'set' %s expr ')'", nodeCounter++, $3);  

    // assuming set doesn't add to scope, just edits a pre-existing variable
    Symbol* sym_p = (Symbol*) malloc(sizeof(Symbol));
    sym_p = get(currScope_p, $3);
    if(!sym_p) {
        printf("\nLine %d --- variable '%s' does not exist in scope", yylloc.first_line, $3);
    } else { 
        if(DEBUG) {
            printf("\n\tRight symbol: Lex: %s, type: %d, val: %d", sym_p->lexeme, sym_p->type, sym_p->val);
            printf("\n\tLeft symbol: Lex: %s, type: %d, val: %d",  $4->lexeme,  $4->type,  $4->val);
        }

        if(sym_p->type != $4->type) 
            printf("\nLine %d --- Type mismatch in set statement", yylloc.first_line);

        sym_p->val = $4->val;
    }
    
    $$ = sym_p;
}
            |   '(' _set ID '[' expr ']' expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'set' %s '[' expr ']' expr ')'", nodeCounter++, $3);    

    Symbol* sym_p = (Symbol*) malloc(sizeof(Symbol));
    ArrayObj* arrO_p = (ArrayObj*) malloc(sizeof(ArrayObj));
    
    // make ID is neither neither function or local variable
    FunctionData* funcO = getFuncO($3);
    sym_p = get(currScope_p, $3);
    if(funcO) 
        printf("\nLine %d --- '%s' in scope as a function. Expected to be an array", yylloc.first_line, $3);
    if(sym_p) 
        printf("\nLine %d --- '%s' in scope as a local variable. Expected to be an array", yylloc.first_line, $3);
    
    sym_p = $7;

    // check type of right expr - error if not int
    if(sym_p->type != _INT)
        printf("\nLine %d --- Illegal parameter type: Arrays only store integer types.", yylloc.first_line);

    
    arrO_p = getArrayO($3);

    int arrAccessErr = 0;    

    if(!arrO_p) {
        printf("\nLine %d --- Undeclared array '%s'", yylloc.first_line, $3);
        arrAccessErr = 1;
    }

    if($5->type != _INT || $5->val < 0) {
        printf("\nLine %d --- Array indices must be type integer and >= 0", yylloc.first_line);
        arrAccessErr = 1;
    }

    if(arrO_p && $5->val >= arrO_p->capacity ) {
        printf("\nLine %d ---  Illegal index '%d' - array '%s' has a capacity of '%d' elements.", yylloc.first_line, $5->val, $3, arrO_p->capacity);
        arrAccessErr = 1;
    }

    if(arrAccessErr)
        sym_p = createSymbol("_ERR_ARR_ACCESS", _INT, 0);
    else {
        sym_p = createSymbol("_RE_ASSIGN_ARR_EL", _INT, $7->val);
        // store symbol at index if possible
    }

    $$ = sym_p;
}
            |   '(' '+' expr expr ')' {
    if(DEBUG) { 
        printf("\n(%d) expr - '(' '+' expr expr ')'", nodeCounter++);  

        printf("\nLeft - Lex: %s, type: %d, val: %d", $3->lexeme, $3->type, $3->val);
        printf("\nRight - Lex: %s, type: %d, val: %d", $4->lexeme, $4->type, $4->val);
    }
         
    // if either expr isn't INT (except undetermined), print an error message, but continue computation
    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _INT || $4->type != _INT) 
    ) 
        printf("\nLine %d --- Incorrect type for operator +: Integers expected", yylloc.first_line);

    $$ = createSymbol("_PLUS_EXP_EXP", _INT, (($3->val) + ($4->val)));  
}
            |   '(' '-' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '-' expr expr ')'", nodeCounter++);

    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _INT || $4->type != _INT) 
    ) 
        printf("\nLine %d --- Incorrect type for operator -: Integers expected", yylloc.first_line);

    $$ = createSymbol("_MIN_EXP_EXP", _INT, (($3->val) - ($4->val)));
}
            |   '(' '*' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '*' expr expr ')'", nodeCounter++);    

    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _INT || $4->type != _INT) 
    ) 
        printf("\nLine %d --- Incorrect type for operator *: Integers expected", yylloc.first_line);

    $$ = createSymbol("_MULT_EXP_EXP", _INT, (($3->val) * ($4->val)));
}
            |   '(' '/' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '/' expr expr ')'", nodeCounter++);    
    
    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _INT || $4->type != _INT) 
    ) 
        printf("\nLine %d --- Incorrect type for operator /: Integers expected", yylloc.first_line);

    $$ = createSymbol("_DIVIDE_EXP_EXP", _INT, (($3->val) / ($4->val)));
}
            |   '(' '<' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '<' expr expr ')'", nodeCounter++);    

    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _INT || $4->type != _INT) 
    ) 
        printf("\nLine %d --- Incorrect type for operator <: Integers expected", yylloc.first_line);

    $$ = createSymbol("_LT_EXP_EXP", _BOOL, (($3->val) < ($4->val)));
}           |   '(' '>' expr expr ')' {
    if(DEBUG)    
        printf("\n(%d) expr - '(' '>' expr expr ')'", nodeCounter++);    

    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _INT || $4->type != _INT) 
    ) 
        printf("\nLine %d --- Incorrect type for operator >: Integers expected", yylloc.first_line);

    $$ = createSymbol("_GT_EXP_EXP", _BOOL, (($3->val) > ($4->val)));
}
            |   '(' LTE expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '<=' expr expr ')'", nodeCounter++);    

    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _INT || $4->type != _INT) 
    ) 
        printf("\nLine %d --- Incorrect type for operator <=: Integers expected", yylloc.first_line);

    $$ = createSymbol("_LTE_EXP_EXP", _BOOL, (($3->val) <= ($4->val)));
}
            |   '(' GTE expr expr ')' {
    if(DEBUG)
        printf("\n(%d) expr - '(' '>=' expr expr ')'", nodeCounter++);    

    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _INT || $4->type != _INT) 
    ) 
        printf("\nLine %d --- Incorrect type for operator >=: Integers expected", yylloc.first_line);

    $$ = createSymbol("_GTE_EXP_EXP", _BOOL, (($3->val) >= ($4->val)));
}
            |   '(' '=' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '=' expr expr ')'", nodeCounter++);      

    Symbol* exp_1 = $3;
    Symbol* exp_2 = $4;

    Symbol* sym_p = malloc(sizeof(Symbol));

    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _INT || $4->type != _INT) 
    ) 
        printf("\nLine %d --- Incorrect type for operator =: Integers expected", yylloc.first_line);

    // no matter whether UNDEFINED | INT | BOOl combination, return comparison of two exprs
    sym_p = createSymbol("_EQ_EXP_EXP", _BOOL, exp_1->val == exp_2->val);

    if(DEBUG) 
        printf("\n\tlexeme: %s, type: %d, val: %d", sym_p->lexeme, sym_p->type, sym_p->val);

    $$ = sym_p;
}
            |   '(' NEQ expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '<>' expr ')'", nodeCounter++); 

    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _INT || $4->type != _INT) 
    ) 
        printf("\nLine %d --- Incorrect type for operator <>: Integers expected", yylloc.first_line);

    $$ = createSymbol("_NEQ_EXP_EXP", _BOOL, (($3->val) != ($4->val)));   
}
            |   '(' '-' expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '-' expr ')'", nodeCounter++);  

    if($3->type != _UNDETERMINED && $3->type != _INT)
        printf("\nLine %d --- Incorrect type for operator -: Integer expected", yylloc.first_line);

    $$ = createSymbol("_NEGAT_EXPR", _INT, -($3->val));  
}
            |   '(' _and expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'and' expr expr ')'", nodeCounter++);

    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _BOOL || $4->type != _BOOL) 
    ) 
        printf("\nLine %d --- Incorrect type for operator 'and': Booleans expected", yylloc.first_line);

    $$ = createSymbol("_AND", _BOOL, (($3->val) && ($4->val)));
}
            |   '(' '&' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '&' expr expr ')'", nodeCounter++);    

    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _BOOL || $4->type != _BOOL) 
    ) 
        printf("\nLine %d --- Incorrect type for operator '&': Booleans expected", yylloc.first_line);

    $$ = createSymbol("_AND", _BOOL, (($3->val) && ($4->val)));
}
            |   '(' _or expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'or' expr expr ')'", nodeCounter++); 

    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _BOOL || $4->type != _BOOL) 
    ) 
        printf("\nLine %d --- Incorrect type for operator 'or': Booleans expected", yylloc.first_line);

    $$ = createSymbol("_OR", _BOOL, (($3->val) || ($4->val)));  
}
            |   '(' '|' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '|' expr expr ')'", nodeCounter++);    

    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _BOOL || $4->type != _BOOL) 
    ) 
        printf("\nLine %d --- Incorrect type for operator '|': Booleans expected", yylloc.first_line);

    $$ = createSymbol("_OR", _BOOL, (($3->val) || ($4->val))); 
}
            |   '(' _not expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'not' expr ')'", nodeCounter++);    

    if($3->type != _UNDETERMINED && $3->type != _BOOL)
        printf("\nLine %d --- Incorrect type for operator 'not': Boolean expected", yylloc.first_line);

    $$ = createSymbol("_NEGATION", _BOOL, !($3->val)); 
}
            |   '(' '!' expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '!' expr  ')'", nodeCounter++);

    if($3->type != _UNDETERMINED  && $3->type != _BOOL)
        printf("\nLine %d --- Incorrect type for operator '!': Boolean expected", yylloc.first_line);

    $$ = createSymbol("_NEGATION", _BOOL, !($3->val)); 
}
            |   '(' _seq expr_list ')' {
    if(DEBUG) {
        printf("\n(%d) expr - '(' 'seq' expr_list ')'", nodeCounter++);    
        _printPL($3);
    }   
 
    // last symbol from the hashtable
    Symbol* sym_p  = _getFromPL($3, $3->ids_p[$3->count - 1]);
    
    if(DEBUG)
        printf("\nlast symbol in expr_list - lexeme: %s, type: %d, val: %d", sym_p->lexeme, sym_p->type, sym_p->val);
    
    $$ = createSymbol("_SEQ_EXPR", sym_p->type, sym_p->val);
}
            ;
actual_list	:   %empty {
    if(DEBUG)    
        printf("\n(%d) actual_list -> ε", nodeCounter++);
  
    // left-most node, create a new parameterListScope obj
    $$ = _newPLScope();   
}
            |   actual_list expr {
    if(DEBUG)                
        printf("\n(%d) actual_list - actual_list expr", nodeCounter++); 
    
    PLScope* plScope_p = $1;

    _addToPL(plScope_p, $2);
        
    $$ = plScope_p;  
}
            ;
assign_list	:   assign_list '(' ID expr ')' {
    if(DEBUG)    
        printf("\n(%d) assign_list - assign_list '(' %s expr ')'", nodeCounter++, $3);

    Symbol* sym_p = malloc(sizeof(Symbol));
    sym_p = get(currScope_p, $3);

    // lexeme shouldn't exist - if it does its value will get overwritten
    if(sym_p){
        printf("Line %d --- Parameter %s already defined", yylloc.first_line, $3);
        sym_p->type = $4->type;
        sym_p->val = $4->val;
    } else {
        sym_p = createSymbol($3, $4->type, $4->val);
        add(currScope_p, sym_p); 
    }

    _addToPL($1, sym_p);

    $$ = $1;  
}
            |   '(' ID expr ')' {
    if(DEBUG)                
        printf("\n(%d) assign_list -  '(' %s expr ')'", nodeCounter++, $2);

    // always left-most node for id_list - create a new paramListScope to keep track of param objects
    Symbol* sym_p = (Symbol*) malloc(sizeof(Symbol));
    sym_p = createSymbol($2, $3->type, $3->val);
    add(currScope_p, sym_p); 

    PLScope* plScope_p = (PLScope*) malloc(sizeof(PLScope));
    plScope_p = _newPLScope();

    _addToPL(plScope_p, sym_p);

    $$ = plScope_p;  
}
            ;
expr_list   :   expr_list expr {
    if(DEBUG)    
        printf("\n(%d) expr_list -  expr_list expr ", nodeCounter++);

    PLScope* plScope_p = $1;
    _addToPL(plScope_p, $2);
    
    $$ = plScope_p;
}
            |   expr {
    if(DEBUG)                
        printf("\n(%d) expr_list - expr ", nodeCounter++);

    // always left-most node for expr_list - create a new paramListScope to track list objects
    PLScope* plScope_p = (PLScope*) malloc(sizeof(PLScope));
    plScope_p = _newPLScope();

    _addToPL(plScope_p, $1);
    
    $$ = plScope_p;  
}
            ;
%%

int yyerror(char* s) {
	printf("\n\t--- %s - { line: %d }\n", s, yylloc.first_line );
	return 0;
}

int main (void) {
    yylloc.first_line = yylloc.last_line = 1;
    yylloc.first_column = yylloc.last_column = 0;
    return yyparse ();
}