#define _GNU_SOURCE
#define STR_SIZE 255
#define HASHMAPCAPACITY 30

#define _INT 1
#define _BOOL 2
#define _UNDETERMINED 3
#define _PARAMLIST 4


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
    char* lexeme;
    int type;
    int val;
    void* ptr;
} Symbol;

void createScope(); 
Scope* _newScope();

Symbol* createSymbol(char lexeme[255], int type, int val);

void add(Scope*, Symbol*);
Symbol* get(Scope* scope_p, char id[255]);
void printScopeSymbols(Scope*);