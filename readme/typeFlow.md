#define INT 1
#define BOOL 2
#define EMTPY 3
#define UNDETERMINED 4
#define PARAMLIST 5

2. id_list - id {
    Symbol* res = get(topScope_p, $1);
    
    // lexeme shouldn't exist
    if(res)
        printf("Parameter %s already defined", $1);
    else   
        add(topScope_p, createSymbol($1, INT));
    
    $$ = INT; // { type = INT, val = NULL }
}
3. id_list - id_list id {
    Symbol* res = get(topScope_p, $2);

    if(res) // lexeme shouldn't exist
        printf("Parameter %s already defined", $2);
    else
        add(topScope_p, createSymbol($2, INT)); 
    $$ = INT;
}
6. expr - id {
    Symbol* res = top.get($1);
    
    Symbol* res = (Symbol *) malloc(sizeof(Symbol));
    res = NULL;
    
    if(!res) // lexeme should exist
        printf("Undeclared variable $s", $1);
    else {
        res = get(topScope_p, $1);
    }

    printf("expr - id { %s - type: %d }" $1, res->type);

    $$ = res ? res->type : UNDETERMINED; // { type:res ? res->type : UNDETERMINED; val: res->val; }
}
7. expr - num { $$ = INT; }
8. expr - ( = expr { } expr exr ) {
    if($3 == UNDETERMINED || $4 == UNDERTERMINED)
        $$ = UNDETERMINED;
    else
        $$ = BOOL // val = true/false
}
9. -> *6
10. expr -> ( id {} expr ) {
    FuncSymbol* res = getFunction($2);
    if(!res)
        printf("Undeclared function %s", $2);
}
11. -> 10
12. actual_list -> ε {
    $$ = plScope_p();
}
13. -> 6
```c
typedef struct Symbol {
    char* lexeme;
    int type;
    int val;
} Symbol;

typedef struct ParamsListScope {
    int count;
    int capacity;
    struct hsearch_data *hashmap_p;
    char** ids_p;
} PLScope;
```

14. actual_list: actual_list expr {
    
    PLScope* pl_p = malloc(sizeof(PLScope));
    pl_p = (PLScope *) $1;
    Symbol* exp = malloc(sizeof(PLScope));
    exp = expr;

    // expr can only be either INT, UNDETERMINED
    // if UNDETERMINED, we've already complained
    if( exp->type == UNDETERMINED ){
        // just convert it to INT
        exp->type = INT;
        addToPL(pl_p, exp);
    }

    // type can never be "PARAMLIST" for expr here as left-recursive YACC


    Symbol* r1 = (Symbol*) malloc(sizeof(Symbol));
    Symbol* r2 = (Symbol*) malloc(sizeof(Symbol));
    r1 = $1;
    r2 = $2
    if(!$1) {

    }
}