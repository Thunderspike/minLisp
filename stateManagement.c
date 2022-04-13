#include "minLisp.h"

int scopeIdCounter = 0;
int nodeCounter = 0;
Scope* currScope_p = NULL;
GlobalFuncs* globalFuncs_p = NULL;
GlobalArrays* globalArrs_p = NULL;

void initGlobalState() {
    if(!currScope_p && !globalFuncs_p) {
        currScope_p = (Scope *) malloc(sizeof(Scope));
        createScope("top");
        currScope_p->isTopScope = 1;

        createGlobalFuncs();
        createGlobalArrays();
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

void createGlobalArrays() {
    // globalArrs_p
    globalArrs_p = (GlobalArrays *) malloc(sizeof(GlobalArrays));
    globalArrs_p->count = 0;
    globalArrs_p->capacity = HASHMAPCAPACITY; 
    globalArrs_p->hashmap_p = (struct hsearch_data *) malloc(sizeof(struct hsearch_data));
    globalArrs_p->ids_p = (char **) malloc(HASHMAPCAPACITY * STR_SIZE);

    struct hsearch_data *newHashmap_p = (struct hsearch_data *) calloc(1, sizeof(struct hsearch_data));

    if (hcreate_r(HASHMAPCAPACITY, newHashmap_p) == 0) {
        fprintf(stderr, "\nError: Unable to create hashmap for global arrays.\n");
        exit(0);
    }
    globalArrs_p->hashmap_p = (struct hsearch_data *) newHashmap_p;
}

ArrayObj* addArrToScope(ArrayObj* arrO_p) {
    ENTRY entry = {
        .key = arrO_p->lexeme,
        .data = arrO_p
    }, *entry_p;

    if (hsearch_r(entry, ENTER, &entry_p, globalArrs_p->hashmap_p) == 0) {
        fprintf(stderr, "\nError: entry for token failed into global array tracker's hashmap\n");
        exit(0);
    }
    
    globalArrs_p->ids_p[globalArrs_p->count] = (char *) malloc(STR_SIZE);
    strcpy(globalArrs_p->ids_p[globalArrs_p->count], arrO_p->lexeme);

    globalArrs_p->count++;

    return arrO_p;
}

ArrayObj* createArrayO(char* lexeme, int size) {
    ArrayObj* arrO_p = (ArrayObj*) malloc(sizeof(ArrayObj));
    arrO_p->lexeme = (char*) malloc(sizeof(STR_SIZE));
    strcpy(arrO_p->lexeme, lexeme);
    arrO_p->capacity = size;
    arrO_p->arr = (Symbol**) malloc(sizeof(Symbol) * size);
    
    return arrO_p;
}

ArrayObj* getArrayO(char* lexeme) {
    ENTRY entry = { .key = lexeme };
    ENTRY* entry_p = (ENTRY *) malloc(sizeof(ENTRY));

    hsearch_r(
        entry,
        FIND,
        &entry_p,
        globalArrs_p->hashmap_p
    );

    if (!entry_p)
        return NULL;
    
    return (ArrayObj *)(entry_p->data);
}

void printArrays() {
    printf("\n\t --- printing array entries list --- ");
    Symbol* arrEntry_p = (Symbol*) malloc(sizeof(Symbol));
    for(int i = 0; i < globalArrs_p->count; i++) {
        ArrayObj* arrO_p = getArrayO(globalArrs_p->ids_p[i]);
        printf("\n[");
        for(int j = 0; j < arrO_p->capacity; j++) {
            arrEntry_p = arrO_p->arr[j];
            if(arrEntry_p)  
                printf(" %d,", arrEntry_p->val);
            else 
                printf(" NULL");
            
        }
        printf(" ]");
    }
    printf("\n\t --- end --- ");
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
