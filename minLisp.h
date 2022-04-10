#define _GNU_SOURCE
#define STR_SIZE 255
#define HASHMAPCAPACITY 30

#define ID = 1
#define NUM = 2
#define _OP_ 3
#define _KEYWORD 4

typedef enum symbols { 
    RPARAM = 0, 
    LPARAM = 1,
    PLUS = 2, 
    MINUS = 3, 
    MULT = 4, 
    DIV = 5, 
    LT = 6, 
    LTE = 7, 
    NEQ = 8, 
    GT = 9, 
    GTE = 10, 
    EQ = 11, 
    LBRACK = 12, 
    RBRACK = 13, 
    AMPER = 14, 
    PIPE = 15, 
    EXCL = 16  
} op;

typedef enum keywords {
    array = 101,
    seq = 102,
    define = 103,
    if = 104,
    while = 105,
    write = 106,
    writeln = 107,
    read = 108,
    and = 109,
    or = 110,
    not = 111,
    set = 112,
    let = 113,
    true = 114,
    false = 115
} types;