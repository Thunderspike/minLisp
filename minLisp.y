%{
    #include "minLisp.tab.h"
    #include "minLisp.h"

    // Lex/YACC utilities
    int yylex();
    int yyerror(char *s);
    extern int yylineno;

    int scopeIdCounter = 0;
    int nodeCounter = 0;
    Scope* currScope_p = NULL;
    GlobalFuncs* globalFuncs_p = NULL;
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
%type<paramsListType> id_list param_list actual_list


%%  
ML          :   arrays program  {
    if(DEBUG) {
        printf("\n(%d) ML - arrays program", nodeCounter++);
        printFuncs();
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

    // check if main is already defined - if it has, exit program
    if(getFuncO("main")){
        printf("\nLine %d --- Fatal: function 'main' need to be the last function declared in the program.\nExiting.\n", yylloc.first_line);
        exit(0);
    }

    FunctionData* funcEntry_p = getFuncO($3);
    // entry shouldn't exist, if it does it'll get overwritten
    if(funcEntry_p && funcEntry_p->isUndefined == 1) {
        // if function is defined previousy as undefined, re-use the stored obj
        funcEntry_p->type = _UNDETERMINED;
        funcEntry_p->isUndefined = 0;
    } else {
        if(funcEntry_p && funcEntry_p->isUndefined != 1)
            printf("\nLine %d --- Function '%s' already declared", yylloc.first_line, $3);

        addFunc(createFuncData($3, 0, _UNDETERMINED));
    }

    // createScope
    createScope($3);
} param_list expr ')' {
    if(DEBUG)
        printf("\n(%d) function - '(' 'define' ID (%s) --> param_list  expr ')'", nodeCounter++, $3);

    FunctionData* funcEntry_p = getFuncO(currScope_p->name);
    // set return type
    funcEntry_p->type = $6->type;

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

    if(!sym_p){ // lexeme should exist
        printf("\nLine %d --- Undeclared variable '%s'", yylloc.first_line, $1);
        // create a symbol to return for type's sake
        sym_p = createSymbol($1, _UNDETERMINED, 0);
        // micro optimization / pain saver - if we cidentify current scope as a functions, we can say the type is int no matter what
    } 

    $$ = sym_p;
}
            |   ID  '[' expr ']' {
    if(DEBUG)
        printf("\n(%d) expr - %s '[' expr ']'", nodeCounter++, $1);    
}
            |   _true {
    if(DEBUG)
        printf("\n(%d) expr - 'true'", nodeCounter++);    
}
            |   _false {
    if(DEBUG)
        printf("\n(%d) expr - 'false'", nodeCounter++);
}
            |   '(' _if expr expr expr ')' {
    if(DEBUG)
        printf("\n(%d) expr - '(' 'if' expr expr expr ')", nodeCounter++); 

    // print error if types don't match, but ignore if either type is undetermined
    if(
        $4->type != $5->type &&
        !($4->type == _UNDETERMINED || $5->type == _UNDETERMINED) 
    ) {
        printf("\nLine %d --- Types of expr 2 and expr 3 don't match for the 'if' statement", yylloc.first_line);
    }

    int type = _UNDETERMINED;
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
}
            |   '(' ID actual_list ')' {
    if(DEBUG)
        printf("\n(%d) expr - '(' ID (%s) actual_list ')'", nodeCounter++, $2);  

    FunctionData* funcO = (FunctionData*) malloc(sizeof(FunctionData));
    funcO = getFuncO($2);

    if(!funcO || funcO->isUndefined == 1) {
        printf("\nLine %d --- Undeclared function '%s'", yylloc.first_line, $2);
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

    int type = funcO->type;
    if(strcasecmp(funcO->lexeme, currScope_p->name) == 0) {
        funcO->isRecursive = 1;
        type = _INT;
    }

    // the value here will need to be the value retreived from running the function instead of 0
    $$ = createSymbol("_ID_ACTUAL-LIST", type, 0);   
}
            |   '(' _write expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'write' expr ')'", nodeCounter++);    
}
            |   '(' _writeln expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'writeln' expr ')'", nodeCounter++);    
}
            |   '(' _read ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'read' ')'", nodeCounter++);    
}
            |   '(' _let '(' assign_list ')' expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'let' '(' assign_list ')' expr ')'", nodeCounter++);    
}
            |   '(' _set ID expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'set' %s expr ')'", nodeCounter++, $3);    
    Symbol* getter = malloc(sizeof(Symbol));
    getter = $4;
    printf("\n expr's value: %d", getter->val);
}
            |   '(' _set ID '[' expr ']' expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'set' %s '[' expr ']' expr ')'", nodeCounter++, $3);    
}
            |   '(' '+' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '+' expr expr ')'", nodeCounter++);  
    // if either expr isn't INT (except undetermined), print an error message, but continue computation
    
    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _INT || $4->type != _INT) 
    ) 
        printf("\nLine %d --- ( + epxr expr ) expects arguments of type integer", yylloc.first_line);

    $$ = createSymbol("_PLUS_EXP_EXP", _INT, (($3->val) + ($4->val)));  
}
            |   '(' '-' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '-' expr expr ')'", nodeCounter++);  
    // if either expr isn't INT (except undetermined), print an error message, but continue computation
    if(
        !($3->type == _UNDETERMINED || $4->type == _UNDETERMINED) && 
        ($3->type != _INT || $4->type != _INT) 
    ) 
        printf("\nLine %d --- ( - epxr expr ) expects arguments of type integer", yylloc.first_line);

    $$ = createSymbol("_MIN_EXP_EXP", _INT, (($3->val) - ($4->val)));
}
            |   '(' '*' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '*' expr expr ')'", nodeCounter++);    
}
            |   '(' '/' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '/' expr expr ')'", nodeCounter++);    
}
            |   '(' '<' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '<' expr expr ')'", nodeCounter++);    
}           |   '(' '>' expr expr ')' {
    if(DEBUG)    
        printf("\n(%d) expr - '(' '>' expr expr ')'", nodeCounter++);    
}
            |   '(' LTE expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '<=' expr expr ')'", nodeCounter++);    
}
            |   '(' GTE expr expr ')' {
    printf("\n(%d) expr - '(' '>=' expr expr ')'", nodeCounter++);    
}
            |   '(' '=' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '=' expr expr ')'", nodeCounter++);      

    Symbol* exp_1 = $3;
    Symbol* exp_2 = $4;

    Symbol* sym_p = malloc(sizeof(Symbol));
    // no matter whether UNDEFINED | INT | BOOl combination, return comparison of two exprs
    if(DEBUG) 
        sym_p = createSymbol("_EQ_EXP_EXP", _BOOL, exp_1->val == exp_2->val);

    printf("\n\tlexeme: %s, type: %d, val: %d", sym_p->lexeme, sym_p->type, sym_p->val);

    $$ = sym_p;
}
            |   '(' NEQ expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '<>' expr ')'", nodeCounter++);    
}
            |   '(' '-' expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '-' expr ')'", nodeCounter++);    
}
            |   '(' _and expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'and' expr expr ')'", nodeCounter++);    
}
            |   '(' '&' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '&' expr expr ')'", nodeCounter++);    
}
            |   '(' _or expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'or' expr expr ')'", nodeCounter++);    
}
            |   '(' '|' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '|' expr expr ')'", nodeCounter++);    
}
            |   '(' _not expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'not' expr expr ')'", nodeCounter++);    
}
            |   '(' '!' expr expr ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' '!' expr expr ')'", nodeCounter++);    
}
            |   '(' _seq expr_list ')' {
    if(DEBUG)                
        printf("\n(%d) expr - '(' 'seq' expr_list ')'", nodeCounter++);    
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

    printf("\n\tSymbol: lexeme: %s, type: %d, val: %d", $2->lexeme, $2->type, $2->val);

    _addToPL(plScope_p, $2);

    // debugger;
    _printPL(plScope_p);

    $$ = plScope_p;  
}
            ;
assign_list	:   assign_list '(' ID expr ')' {
    if(DEBUG)    
        printf("\n(%d) assign_list - assign_list '(' %s expr ')'", nodeCounter++, $3);
}
            |   '(' ID expr ')' {
    if(DEBUG)                
        printf("\n(%d) assign_list -  '(' %s expr ')'", nodeCounter++, $2);
}
            ;
expr_list   :   expr_list expr {
    if(DEBUG)    
        printf("\n(%d) expr_list -  expr_list expr ", nodeCounter++);
}
            |   expr {
    if(DEBUG)                
        printf("\n(%d) expr_list - expr ", nodeCounter++);
}
            ;
%%

// ------
// ------

void initGlobalState() {
    if(!currScope_p && !globalFuncs_p) {
        currScope_p = (Scope *) malloc(sizeof(Scope));
        createScope("top");
        currScope_p->isTopScope = 1;

        createGlobalFuncs();
    }
}

// ------

void createScope(char* name) {
    Scope* parent_p = (Scope*) malloc(sizeof(Scope));
    parent_p = currScope_p;
    currScope_p = _newScope();
    currScope_p->enclosingScope_p = parent_p;
    currScope_p->isTopScope = 0;
    currScope_p->name = (char*) malloc(sizeof(STR_SIZE));
    if(name)
        currScope_p->name = name;
    else {
        // int length = snprintf( NULL, 0, "%d", scopeIdCounter );
        // currScope_p->name  = (char*) malloc( length + 1 );
        // snprintf( currScope_p->name , length + 1, "%d", scopeIdCounter );
        snprintf( currScope_p->name, STR_SIZE, "%d", scopeIdCounter );
    }

    currScope_p->id = scopeIdCounter++;
}

Scope* _newScope() {

    // printf("\n\n--- creating new scope ---");

    Scope* newScope_p = (Scope *) malloc(sizeof(Scope));
    newScope_p->count = 0;
    newScope_p->capacity = HASHMAPCAPACITY; 
    newScope_p->hashmap_p = (struct hsearch_data *) malloc(sizeof(struct hsearch_data));
    newScope_p->ids_p = (char **) malloc(HASHMAPCAPACITY * STR_SIZE);
    newScope_p->enclosingScope_p = (Scope *) malloc(sizeof(Scope));
    newScope_p->isTopScope = 0;

    struct hsearch_data *newHashmap_p = (struct hsearch_data *) calloc(1, sizeof(struct hsearch_data));

    // printf("\nCreating hashmap for new scope");
    if (hcreate_r(HASHMAPCAPACITY, newHashmap_p) == 0) {
        fprintf(stderr, "\nError: Unable to create hashmap for scope.\n");
        exit(0);
    }
    newScope_p->hashmap_p = (struct hsearch_data *) newHashmap_p;

    return newScope_p;
}

Symbol* createSymbol(char lexeme[255], int type, int val) {
    Symbol* nSymbol_p =  (Symbol*) malloc(sizeof(Symbol));
    nSymbol_p->lexeme = (char *) malloc(sizeof(STR_SIZE));
    strcpy(nSymbol_p->lexeme, lexeme);
    nSymbol_p->type = type;
    nSymbol_p->val = val;

    return nSymbol_p;
}

void add(Scope* scope_p, Symbol* symbol_p) {
   
    // printf("\n--- adding to hashtable ---");
    // printf(
    //     "\nAdding entry with key '%s' and data: { %s: %s } to scope's hashmap",
    //     symbol_p->lexeme,
    //     symbol_p->type,
    //     symbol_p->lexeme
    // );

    ENTRY entry = {
        .key = symbol_p->lexeme,
        .data = symbol_p
    }, *entry_p;

    if (hsearch_r(entry, ENTER, &entry_p, scope_p->hashmap_p) == 0) {
        fprintf(stderr, "\nError: entry for token failed into scope's hashtable\n");
        exit(0);
    }
    
    scope_p->ids_p[scope_p->count] = (char *) malloc(STR_SIZE);
    strcpy(scope_p->ids_p[scope_p->count], symbol_p->lexeme);

    scope_p->count++;
}

Symbol* get(Scope* scope_p, char id[255]){
    // printf("\n\n--- get '%s' ---", id);

    Scope* currScope_p = scope_p;

    while (1) {
        ENTRY entry = { .key = id };
        ENTRY* entry_p = (ENTRY *) malloc(sizeof(ENTRY));

        hsearch_r(
            entry,
            FIND,
            &entry_p,
            currScope_p->hashmap_p
        );

        if (!entry_p) {
            if (currScope_p->isTopScope) {
                return NULL;
            } else {
                currScope_p = currScope_p->enclosingScope_p;
            }
        } else {
            // printf("\nFound { %s: %s } in get\n",
            //     ((Symbol *)(entry_p->data))->type,
            //     ((Symbol *)(entry_p->data))->lexeme
            // );

            return (Symbol *)(entry_p->data);
        }
    }
}


void printScopeSymbols(Scope* scope_p) {
    printf("\n\n--- printing scope symbols ---");

    Scope* currScope_p = scope_p;

    while (1) {
        printf("\nScope - name: %s, id: %d ", currScope_p->name, currScope_p->id);
        printf("\n[ ");
        ENTRY entry, *entry_p;

        for (int i = 0; i < currScope_p->count; i++) {
            entry.key = (currScope_p->ids_p)[i];

            if (
                hsearch_r(
                    entry,
                    FIND,
                    &entry_p,
                    currScope_p->hashmap_p
                ) == 0
            ){
                fprintf(stderr, "\nError: search for lexeme '%s' in scope's hashtbale failed in print\n", entry.key);
                exit(0);
            }

            printf(
                "{ %s: %d }, ",
                ((Symbol *) (entry_p->data))->lexeme,
                ((Symbol *) (entry_p->data))->type
            );
        }
        printf("]\n");

        if (!currScope_p->isTopScope)
            currScope_p = currScope_p->enclosingScope_p;
        else
            break;
    }
}

// ------

void createGlobalFuncs() {
    globalFuncs_p = (GlobalFuncs *) malloc(sizeof(GlobalFuncs));
    globalFuncs_p->count = 0;
    globalFuncs_p->capacity = HASHMAPCAPACITY; 
    globalFuncs_p->hashmap_p = (struct hsearch_data *) malloc(sizeof(struct hsearch_data));
    globalFuncs_p->ids_p = (char **) malloc(HASHMAPCAPACITY * STR_SIZE);

    struct hsearch_data *newHashmap_p = (struct hsearch_data *) calloc(1, sizeof(struct hsearch_data));

     if (hcreate_r(HASHMAPCAPACITY, newHashmap_p) == 0) {
        fprintf(stderr, "\nError: Unable to create hashmap for functions.\n");
        exit(0);
    }
    globalFuncs_p->hashmap_p = (struct hsearch_data *) newHashmap_p;
}

FunctionData* createFuncData(char lexeme[255], int paramsCount, int type) {
    FunctionData* funcDataO_p =  (FunctionData*) malloc(sizeof(FunctionData));
    funcDataO_p->lexeme = (char *) malloc(sizeof(STR_SIZE));
    strcpy(funcDataO_p->lexeme, lexeme);
    funcDataO_p->paramsCount = paramsCount;
    funcDataO_p->type = type;
    funcDataO_p->isRecursive = 0;
    funcDataO_p->isUndefined = 0;

    return funcDataO_p;
}

FunctionData* addFunc(FunctionData* funcDataO_p) {
    ENTRY entry = {
        .key = funcDataO_p->lexeme,
        .data = funcDataO_p
    }, *entry_p;

    if (hsearch_r(entry, ENTER, &entry_p, globalFuncs_p->hashmap_p) == 0) {
        fprintf(stderr, "\nError: entry for function data object in global function hashmap\n");
        exit(0);
    }
    
    globalFuncs_p->ids_p[globalFuncs_p->count] = (char *) malloc(STR_SIZE);
    strcpy(globalFuncs_p->ids_p[globalFuncs_p->count], funcDataO_p->lexeme);

    globalFuncs_p->count++;

    return funcDataO_p;
}

FunctionData* getFuncO(char funcName[255]){

    ENTRY entry = { .key = funcName };
    ENTRY* entry_p = (ENTRY *) malloc(sizeof(ENTRY));

    hsearch_r(
        entry,
        FIND,
        &entry_p,
        globalFuncs_p->hashmap_p
    );

    if (!entry_p) 
        return NULL;

    return (FunctionData *) (entry_p->data);
}

void printFuncs() {
    printf("\n\t --- printing funcs available to global scope --- ");
    FunctionData* func = (FunctionData*) malloc(sizeof(FunctionData));
    for(int i = 0; i < globalFuncs_p->count; i++) {
        func = getFuncO(globalFuncs_p->ids_p[i]);
        printf("\nfuncName: %s, paramCount: %d, funcReturnType: %d, isRecursive: %d, isUndefined: %d", 
            func->lexeme, func->paramsCount, func->type, func->isRecursive, func->isUndefined
        );
    }
    printf("\n\t --- finished funcs ---\n");
}

// ------

PLScope* _newPLScope() {
    PLScope* newPLScope_p = (PLScope *) malloc(sizeof(PLScope));
    newPLScope_p->count = 0;
    newPLScope_p->capacity = HASHMAPCAPACITY; 
    newPLScope_p->hashmap_p = (struct hsearch_data *) malloc(sizeof(struct hsearch_data));
    newPLScope_p->ids_p = (char **) malloc(HASHMAPCAPACITY * STR_SIZE);

    struct hsearch_data *newHashmap_p = (struct hsearch_data *) calloc(1, sizeof(struct hsearch_data));

     if (hcreate_r(HASHMAPCAPACITY, newHashmap_p) == 0) {
        fprintf(stderr, "\nError: Unable to create hashmap for parameterList scope.\n");
        exit(0);
    }
    newPLScope_p->hashmap_p = (struct hsearch_data *) newHashmap_p;

    return newPLScope_p;
}

void _addToPL(PLScope* pl_p,  Symbol* symbol_p) {
    ENTRY entry = {
        .key = symbol_p->lexeme,
        .data = symbol_p
    }, *entry_p;

    if (hsearch_r(entry, ENTER, &entry_p, pl_p->hashmap_p) == 0) {
        fprintf(stderr, "\nError: entry for token failed into scope's hashtable\n");
        exit(0);
    }
    
    pl_p->ids_p[pl_p->count] = (char *) malloc(STR_SIZE);
    strcpy(pl_p->ids_p[pl_p->count], symbol_p->lexeme);

    pl_p->count++;
}

Symbol* _getFromPL(PLScope* pl_p, char lexeme[255]){

    ENTRY entry = { .key = lexeme };
    ENTRY* entry_p = (ENTRY *) malloc(sizeof(ENTRY));

    hsearch_r(
        entry,
        FIND,
        &entry_p,
        pl_p->hashmap_p
    );

    if (!entry_p) 
        return NULL;

    return (Symbol *) (entry_p->data);
}

void _printPL(PLScope* pl_p) {
    printf("\n\t --- printing current parameter list --- ");
    Symbol* sym_p = (Symbol*) malloc(sizeof(Symbol));

    for(int i = 0; i < pl_p->count; i++ ) {
        sym_p = _getFromPL(pl_p, pl_p->ids_p[i]);

        printf("\nSymbol - lexeme: %s, type: %d, val: %d", sym_p->lexeme, sym_p->type, sym_p->val);
    }
    printf("\n\t --- finished parameter list ---\n");
}

// ------
// ------

int yyerror(char* s) {
	printf("\n\t--- %s - { line: %d }\n", s, yylloc.first_line );
	return 0;
}

int main (void) {
    yylloc.first_line = yylloc.last_line = 1;
    yylloc.first_column = yylloc.last_column = 0;
    return yyparse ();
}