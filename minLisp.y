%{
    
    #define _INT_TYPE 1
    #define _CHAR_TYPE 2
    #define _BOOL_TYPE 3

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

    // Symbol table utilities
    typedef struct Scope {
        int count;
        int capacity;
        struct hsearch_data *hashmap_p;
        char** ids_p;
        struct Scope* enclosingScope_p;
        int isTopScope;
    } Scope;

    typedef struct Symbol {
        int keyword;
        char* type;
        char* lexeme;
    } Symbol;

    void createScope(); 
    Scope* _newScope();

    Symbol* createSymbol(char type[255], char lexeme[255]);

    void add(Scope*, Symbol*);
    Symbol* get(Scope* scope_p, char id[255]);
    void printScopeSymbols(Scope*);

    Scope* currScope_p = NULL;
%}

%locations

%union {
    char* nameVal;
    int intVal;
}

%token LBRACKET RBRACKET TYPE_ ID ENDSTMT
%type<nameVal> ID 
%type<intVal> NUM

%%  
ML          :   arrays program  {}
            ;
arrays      :   arrays array    {}
            ;
array       :   '(' 'array' ID NUM ')'    {}
            ;
program		:   program function    {}
            |   function    {}
            ;
function    :   '(' 'define' ID param_list expr ')' 
            ;
param_list	:   '(' ')'
            |   '(' id_list ')'
            ;
id_list		:   id_list ID
            |   ID
            ;
expr		:   NUM
            |   ID
            |   ID  '[' expr ']'
            |   'true'
            |   'false'
            |   '(' 'if' expr expr expr ')'
            |   '(' 'while' expr expr ')'
            |   '(' ID actual_list ')'
            |   '(' 'write' expr ')'
            |   '(' 'writeln' expr ')'
            |   '(' 'read' ')'
            |   '(' 'let' '(' assign_list ')' expr ')'
            |   '(' 'set' ID expr ')'
            |   '(' 'set' ID '[' expr ']' expr ')'
            |   '(' '+' expr expr ')'
            |   '(' '-' expr expr ')'
            |   '(' '*' expr expr ')'
            |   '(' '/' expr expr ')'
            |   '(' '<' expr expr ')'
            |   '(' '<=' expr expr ')'
            |   '(' '=' expr expr ')'
            |   '(' '-' expr ')'
            |   '(' 'and' expr expr ')'
            |   '(' '&' expr expr ')'
            |   '(' 'or' expr expr ')'
            |   '(' '|' expr expr ')'
            |   '(' 'not' expr expr ')'
            |   '(' '!' expr expr ')'
            |   '(' 'seq' expr_list ')'
            ;
actual_list	:   actual_list expr
            |   %empty
            ;
assign_list	:   assign_list '(' ID expr ')'
            ;
            |   '(' ID expr ')'
expr_list   :   expr_list expr
            ;
            |   expr
            ;
%%

int yyerror(char* s) {
	// printf("\n\t--- %s - { line: %d, col: %d }\n", s, yylloc.first_line, yylloc.first_column );
	return 0;
}

Symbol* createSymbol(char type[255], char lexeme[255]) {
    Symbol* nSymbol_p = (Symbol *) malloc(sizeof(Symbol));
    nSymbol_p->type = (char *) malloc(sizeof(STR_SIZE));
    strcpy(nSymbol_p->type, type);
    nSymbol_p->lexeme = (char *) malloc(sizeof(STR_SIZE));
    strcpy(nSymbol_p->lexeme, lexeme);

    return nSymbol_p;
}

void createScope() {
    if(!currScope_p) {
        currScope_p = (Scope *) malloc(sizeof(Scope));
        currScope_p = _newScope();
        currScope_p->enclosingScope_p = NULL;
        currScope_p->isTopScope = 1;
    } else {
        Scope* parent_p = (Scope*) malloc(sizeof(Scope));
        parent_p = currScope_p;
        currScope_p = _newScope();
        currScope_p->enclosingScope_p = parent_p;
        currScope_p->isTopScope = 0;
    }
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
                "{ %s: %s }, ",
                ((Symbol *) (entry_p->data))->type,
                ((Symbol *) (entry_p->data))->lexeme
            );
        }
        printf("]\n");

        if (!currScope_p->isTopScope)
            currScope_p = currScope_p->enclosingScope_p;
        else
            break;
    }
}

int main (void) {
    yylloc.first_line = yylloc.last_line = 1;
    yylloc.first_column = yylloc.last_column = 0;
    return yyparse ();
}