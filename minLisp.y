%{
    #include "minLisp.tab.h"
    #include "minLisp.h"
    #include <stdio.h>
    #include <stdlib.h>
    #include <search.h>
    #include <string.h>

    // Lex/YACC utilities
    int yylex();
    int yyerror(char *s);
    extern int yylineno;

    Scope* currScope_p = NULL;
    Scope* topScope_p = NULL;
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
%type<paramsListType> param_list id_list


%%  
ML          :   arrays program  {
    printf("\n ML - arrays program ");

    FunctionData* r = (FunctionData*) malloc(sizeof(FunctionData));

    printf("\n\nPrinting funcs:");
    for(int i = 0; i < globalFuncs_p->count; i++) {
        r = getFuncO(globalFuncs_p->ids_p[i]);
        printf("\nfuncName: %s, paramCount: %d, funcReturnType: %d", r->lexeme, r->paramsCount, r->type);
    }

    printf("\n\n");
}
            ;
arrays      :   %empty {
    printf("\n arrays - __empty__ ");
    // always fist node reached - perfect place to initialize global state. 
    initGlobalState();
}           
            |  arrays array {
    printf("\n arrays - arrays array ");
}
            ;
array       :   '(' _array ID NUM ')'    {
    printf("\n array - '(' 'array' %s %d ')'", $3, $4);
}
            ;
program		:   program function    {
    printf("\n program - program function");
}
            |   function    {
    printf("\n program - function");
}
            ;
function    :   '(' _define ID param_list {

    printf("\n function - '(' 'define' %s param_list {} expr ')'", $3);
     // add function to function scope
    FunctionData* funcEntry_p = getFuncO($3);
    // entry shouldn't exist, if it does it'll get overwritten
    if(funcEntry_p && funcEntry_p->undefined != 1)
        printf("Function '%s' already declared", $3);


    int paramsCount = 0;

    if($4){
         PLScope* plScope_p = (PLScope*) malloc(sizeof(PLScope));
        plScope_p = $4;

        _printPL(plScope_p);
        paramsCount = plScope_p->count;
    }
   
    // report function param number to function hashtable entry
    addFunc(createFuncData($3, paramsCount, _UNDETERMINED));

} expr ')' {
   
}
            ;
param_list	:   '(' ')' {
    printf("\n param_list - '(' ')'");
    $$ = NULL;
}
            |   '(' id_list ')' {
    printf("\n param_list - '(' id_list ')'");
    $$ = $2;
}
            ;
// internal type - PLScope*
id_list		:   id_list ID 
{
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
            |   ID 
{
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
            ;

expr		:   NUM {
    printf("\n expr - %d", $1);
    $$ = createSymbol("_NUMERIC_VAL_", _INT, $1);
}
            |   ID {
    printf("\n expr - %s", $1);    

    Symbol* sym_p = malloc(sizeof(Symbol));
    sym_p = get(currScope_p, $1);

    if(!sym_p){ // lexeme should exist
        printf("Undeclared variable %s", $1);
        // create a symbol to return for type's sake
        sym_p = createSymbol($1, _UNDETERMINED, 0);
    } 

    $$ = sym_p;
}
            |   ID  '[' expr ']' {
    printf("\n expr - %s '[' expr ']'", $1);    
}
            |   _true {
    printf("\n expr - 'true'");    
}
            |   _false {
    printf("\n expr - 'false'");
}
            |   '(' _if expr expr expr ')' {
    printf("\n expr - '(' 'if' expr expr expr ')");    
}
            |   '(' _while expr expr ')' {
    printf("\n expr - '(' 'while' expr expr ')"); 
}
            |   '(' ID {
    FunctionData* res = getFuncO($2);
    if(!res || res->undefined == 1) {
        printf("Undeclared function %s", $2);
        if(!res) {
            // add function to global function tracker (with undefined flag) to later determine type
            FunctionData* undefinedFunc_p = createFuncData($2, 0, _UNDETERMINED);
            undefinedFunc_p->undefined = 1;
            addFunc(undefinedFunc_p);
        }
    }
    // ...
}               actual_list ')' {
    printf("\n expr - '(' %s actual_list ')'", $2);    
}
            |   '(' _write expr ')' {
    printf("\n expr - '(' 'write' expr ')'");    
}
            |   '(' _writeln expr ')' {
    printf("\n expr - '(' 'writeln' expr ')'");    
}
            |   '(' _read ')' {
    printf("\n expr - '(' 'read' ')'");    
}
            |   '(' _let '(' assign_list ')' expr ')' {
    printf("\n expr - '(' 'let' '(' assign_list ')' expr ')'");    
}
            |   '(' _set ID expr ')' {
    Symbol* getter = malloc(sizeof(Symbol));
    getter = $4;
    printf("\n expr - '(' 'set' %s expr ')'", $3);    
    printf("\n expr's value: %d", getter->val);
}
            |   '(' _set ID '[' expr ']' expr ')' {
    printf("\n expr - '(' 'set' %s '[' expr ']' expr ')'", $3);    
}
            |   '(' '+' expr expr ')' {
    printf("\n expr - '(' '+' expr expr ')'");    
}
            |   '(' '-' expr expr ')' {
    printf("\n expr - '(' '-' expr expr ')'");    
}
            |   '(' '*' expr expr ')' {
    printf("\n expr - '(' '*' expr expr ')'");    
}
            |   '(' '/' expr expr ')' {
    printf("\n expr - '(' '/' expr expr ')'");    
}
            |   '(' '<' expr expr ')' {
    printf("\n expr - '(' '<' expr expr ')'");    
}           |   '(' '>' expr expr ')' {
    printf("\n expr - '(' '>' expr expr ')'");    
}
            |   '(' LTE expr expr ')' {
    printf("\n expr - '(' '<=' expr expr ')'");    
}
            |   '(' GTE expr expr ')' {
    printf("\n expr - '(' '>=' expr expr ')'");    
}
            |   '(' '=' expr expr ')' {
    printf("\n expr - '(' '=' expr expr ')'");      

    Symbol* exp_1 = $3;
    Symbol* exp_2 = $4;

    Symbol* sym_p = malloc(sizeof(Symbol));
    // no matter whether UNDEFINED | INT | BOOl combination, return comparison of two exprs
    sym_p = createSymbol("_EQ_EXP_EXP", _BOOL, exp_1->val == exp_2->val);

    printf("\n\tlexeme: %s, type: %d, val: %d", sym_p->lexeme, sym_p->type, sym_p->val);

    $$ = sym_p;
}
            |   '(' NEQ expr ')' {
    printf("\n expr - '(' '<>' expr ')'");    
}
            |   '(' '-' expr ')' {
    printf("\n expr - '(' '-' expr ')'");    
}
            |   '(' _and expr expr ')' {
    printf("\n expr - '(' 'and' expr expr ')'");    
}
            |   '(' '&' expr expr ')' {
    printf("\n expr - '(' '&' expr expr ')'");    
}
            |   '(' _or expr expr ')' {
    printf("\n expr - '(' 'or' expr expr ')'");    
}
            |   '(' '|' expr expr ')' {
    printf("\n expr - '(' '|' expr expr ')'");    
}
            |   '(' _not expr expr ')' {
    printf("\n expr - '(' 'not' expr expr ')'");    
}
            |   '(' '!' expr expr ')' {
    printf("\n expr - '(' '!' expr expr ')'");    
}
            |   '(' _seq expr_list ')' {
    printf("\n expr - '(' 'seq' expr_list ')'");    
}
            ;
actual_list	:   %empty {
    printf("\n actual_list - __empty__");
}
            |   actual_list expr {
    printf("\n actual_list - actual_list expr");
}
            ;
assign_list	:   assign_list '(' ID expr ')' {
    printf("\n assign_list - assign_list '(' %s expr ')'", $3);
}
            |   '(' ID expr ')' {
    printf("\n assign_list -  '(' %s expr ')'", $2);
}
            ;
expr_list   :   expr_list expr {
    printf("\n expr_list -  expr_list expr ");
}
            |   expr {
    printf("\n expr_list - expr ");
}
            ;
%%

int yyerror(char* s) {
	printf("\n\t--- %s - { line: %d }\n", s, yylloc.first_line );
	return 0;
}

void initGlobalState() {
    if(!currScope_p && !topScope_p && !globalFuncs_p) {
        currScope_p = (Scope *) malloc(sizeof(Scope));
        currScope_p = _newScope();
        currScope_p->enclosingScope_p = NULL;
        currScope_p->isTopScope = 1;

        topScope_p = (Scope *) malloc(sizeof(Scope));
        topScope_p = currScope_p;

        createGlobalFuncs();
    }
}


// ------

Symbol* createSymbol(char lexeme[255], int type, int val) {
    Symbol* nSymbol_p =  malloc(sizeof(Symbol));
    nSymbol_p->lexeme = (char *) malloc(sizeof(STR_SIZE));
    strcpy(nSymbol_p->lexeme, lexeme);
    nSymbol_p->type = type;
    nSymbol_p->val = val;

    return nSymbol_p;
}

void createScope() {
    Scope* parent_p = (Scope*) malloc(sizeof(Scope));
    parent_p = currScope_p;
    currScope_p = _newScope();
    currScope_p->enclosingScope_p = parent_p;
    currScope_p->isTopScope = 0;
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
    printf("\n\n--- printing ---");

    Scope* currScope_p = scope_p;

    while (1) {
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
    FunctionData* funcDataO_p =  malloc(sizeof(FunctionData));
    funcDataO_p->lexeme = (char *) malloc(sizeof(STR_SIZE));
    strcpy(funcDataO_p->lexeme, lexeme);
    funcDataO_p->paramsCount = paramsCount;
    funcDataO_p->type = type;
    funcDataO_p->undefined = 0;

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
    Symbol* sym_p = (Symbol*) malloc(sizeof(Symbol));

    for(int i = 0; i < pl_p->count; i++ ) {
        sym_p = _getFromPL(pl_p, pl_p->ids_p[i]);

        printf("\nSymbol - lexeme: %s, type: %d, val: %d", sym_p->lexeme, sym_p->type, sym_p->val);
    }
}

// ------

int main (void) {
    yylloc.first_line = yylloc.last_line = 1;
    yylloc.first_column = yylloc.last_column = 0;
    return yyparse ();
}