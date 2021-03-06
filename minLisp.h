#define _GNU_SOURCE
#define DEBUG 0
#define STR_SIZE 255
#define HASHMAPCAPACITY 30
#define MAIN "main"

#define _UNSASSIGNED 0 // unused
#define _INT 1
#define _BOOL 2
#define _UNDETERMINED 3
#define _PARAMLIST 4

#include <stdio.h>
#include <stdlib.h>
#include <search.h>
#include <string.h>

// int scopeIdCounter = 0;
// int nodeCounter = 0;
// Scope* currScope_p = NULL;
// GlobalFuncs* globalFuncs_p = NULL;
// GlobalArrays* globalArrs_p = NULL;

// Symbol table utilities
typedef struct Scope {
    int id;
    char* name;
    int count; // switchToSymbolCount ideally
    int capacity;
    struct hsearch_data *hashmap_p;
    char** ids_p; // rename this to symbolIds ideally
    struct Scope* enclosingScope_p;
    int isTopScope;
} Scope;

// creates top scope, points currScope, and creates global function scope
void initGlobalState(); 
void createScope(char* name);
Scope* _newScope();

// ------
// the workhorse grammar object, as well as what's stored in the Scope's symbol (hash) table
typedef struct Symbol {
    char* lexeme;
    int type;
    int val;
} Symbol;

Symbol* createSymbol(char lexeme[255], int type, int val);
void add(Scope*, Symbol*);
Symbol* get(Scope* scope_p, char id[255]);
void printScopeSymbols(Scope*);

// ------
// keep track of functions in global scope
typedef struct GlobalFunctionsEnumerator {
    int count;
    int capacity;
    struct hsearch_data *hashmap_p;
    char** ids_p;
} GlobalFuncs;

// function data object
typedef struct FunctionData {
    char* lexeme;
    int paramsCount;
    int type;
    int isRecursive;
    int isUndefined;
} FunctionData;

// CRUD ops for global function object
void createGlobalFuncs();
FunctionData* createFuncData(char lexeme[255], int paramsCount, int type);
FunctionData* addFunc(FunctionData* funcDataO_p);
FunctionData* getFuncO(char funcName[255]);
void printFuncs();

// ----
// keeps track of arrays in global scope
typedef struct GlobalArraysEnumerator {
    int count;
    int capacity;
    struct hsearch_data *hashmap_p;
    char** ids_p;
} GlobalArrays;

typedef struct ArrayObject {
    char* lexeme;
    int capacity;
    Symbol** arr;
} ArrayObj;

// CRUD ops for global array management
void createGlobalArrays();
ArrayObj* addArrToScope(ArrayObj* arrO_p);
ArrayObj* createArrayO(char* lexeme, int size);
ArrayObj* getArrayO(char* lexeme);
void printArrays();


// ------
// YYAC grammar specific utilities

// params list grammar types - id_list & assign_list are making use of it to keep track of count
typedef struct ParamsListScope {
    int count;
    int capacity;
    struct hsearch_data *hashmap_p;
    char** ids_p;
} PLScope;

PLScope* _newPLScope();
void _addToPL(PLScope* pl_p,  Symbol* symbol_p);
Symbol* _getFromPL(PLScope* pl_p, char lexeme[255]);
void _printPL(PLScope* pl_p);

extern int scopeIdCounter;
extern int nodeCounter;
extern Scope* currScope_p;
extern GlobalFuncs* globalFuncs_p;
extern GlobalArrays* globalArrs_p;