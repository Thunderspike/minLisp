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
        char* keyword;
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
    char* keyword;
    char* nameVal;
    int intVal;
}

%token _array _seq _define _if _while _write _writeln _read 
%token _and _or _not _set _let _true _false
%token LTE NEQ GTE
%token ID NUM 

%type<nameVal> ID 
%type<intVal> NUM

%%  
ML          :   arrays program  {
    printf("\n ML - arrays program ");
    printf("\n");
}
            ;
arrays      :   %empty {
    printf("\n arrays - __empty__ ");
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
function    :   '(' _define ID param_list expr ')' {
    printf("\n function - '(' 'define' %s param_list expr ')'", $3);
}
            ;
param_list	:   '(' ')' {
    printf("\n param_list - '(' ')'");
}
            |   '(' id_list ')' {
    printf("\n param_list - '(' id_list ')'");
}
            ;
id_list		:   id_list ID {
    printf("\n id_list - id_list %s", $2);
}
            |   ID {
    printf("\n id_list - %s", $1);                
}
            ;

expr		:   NUM {
    printf("\n expr - %d", $1);    
}
            |   ID {
    printf("\n expr - %s", $1);    
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
            |   '(' ID actual_list ')' {
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
    printf("\n expr - '(' 'set' %s expr ')'", $3);    
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