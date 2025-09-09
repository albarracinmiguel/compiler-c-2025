%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

FILE *yyin;
extern YYSTYPE yylval;

// Estructura para tabla de simbolos
typedef struct {
    char nombre[50];
    char tipo[20];
    char valor[50];
    int longitud;
    int linea;
} Simbolo;

Simbolo tabla_simbolos[1000];
int num_simbolos = 0;

// Funcion para agregar simbolo a la tabla
void agregar_simbolo(char* nombre, char* tipo, char* valor, int linea) {
    if (num_simbolos < 1000) {
        strcpy(tabla_simbolos[num_simbolos].nombre, nombre);
        strcpy(tabla_simbolos[num_simbolos].tipo, tipo);
        strcpy(tabla_simbolos[num_simbolos].valor, valor);
        tabla_simbolos[num_simbolos].linea = linea;
        tabla_simbolos[num_simbolos].longitud = strlen(nombre);
        num_simbolos++;
    }
}

// Funcion para buscar simbolo en la tabla
int buscar_simbolo(char* nombre) {
    for (int i = 0; i < num_simbolos; i++) {
        if (strcmp(tabla_simbolos[i].nombre, nombre) == 0) {
            return i;
        }
    }
    return -1;
}

// Funcion para generar archivo de tabla de simbolos
void generar_tabla_simbolos() {
    FILE *archivo = fopen("symbol-table.txt", "w");
    if (archivo != NULL) {
        fprintf(archivo, "TABLA DE SIMBOLOS\n");
        fprintf(archivo, "=================\n\n");
        fprintf(archivo, "%-20s %-15s %-20s %-10s %-10s\n", "NOMBRE", "TIPO", "VALOR", "LONGITUD", "LINEA");
        fprintf(archivo, "%-20s %-15s %-20s %-10s %-10s\n", "------", "----", "-----", "--------", "-----");
        
        for (int i = 0; i < num_simbolos; i++) {
            fprintf(archivo, "%-20s %-15s %-20s %-10d %-10d\n", 
                    tabla_simbolos[i].nombre,
                    tabla_simbolos[i].tipo,
                    tabla_simbolos[i].valor,
                    tabla_simbolos[i].longitud,
                    tabla_simbolos[i].linea);
        }
        fclose(archivo);
        printf("Tabla de simbolos generada en 'symbol-table.txt'\n");
    }
}

// Funcion de inicializacion del lexer
void inicializar_lexer() {
    printf("=== INICIANDO ANALISIS LEXICO ===\n");
    printf("Generando tabla de simbolos inicial...\n");
    generar_tabla_simbolos();
}

%}

%option noyywrap
%option yylineno

DIGITO           [0-9]
LETRA            [a-zA-Z]
DIGITO_HEX       [0-9a-fA-F]
DIGITO_OCT       [0-7]

CTE              {DIGITO}+
CTE_HEX          "0x"{DIGITO_HEX}+
CTE_OCT          "0"{DIGITO_OCT}+
CTE_REAL         {DIGITO}+"."{DIGITO}+
CTE_STRING       \"[^\"]*\"
CTE_CHAR         \'[^\']\'
CTE_DATE         {DIGITO}{DIGITO}{DIGITO}{DIGITO}{DIGITO}{DIGITO}{DIGITO}{DIGITO}

ID               {LETRA}({LETRA}|{DIGITO}|"_")*

OP_AS            ":="
OP_SUM           "+"
OP_MUL           "*"
OP_RES           "-"
OP_DIV           "/"
OP_MOD           "%"
OP_POT           "**"
OP_IGUAL         "=="
OP_DIF           "!="
OP_MENOR         "<"
OP_MAYOR         ">"
OP_MENOR_IGUAL   "<="
OP_MAYOR_IGUAL   ">="
OP_AND           "AND"
OP_OR            "OR"
OP_NOT           "NOT"

PAR_A            "("
PAR_C            ")"
COR_A            "["
COR_C            "]"
LLAVE_A          "{"
LLAVE_C          "}"
PUNTO_COMA       ";"
COMA             ","
PUNTO            "."
DOS_PUNTOS       ":"

COMENTARIO_LINEA "#+"[^+]*"+#"
COMENTARIO_BLOQUE "#+"([^+]|"+"[^#])*"+#"

%%

{CTE}            { 
    static int primera_vez = 1;
    if (primera_vez) {
        inicializar_lexer();
        primera_vez = 0;
    }
    
    printf("Constante: %s\n", yytext);
    // Verificar rango de constantes
    long valor = atol(yytext);
    if (valor > 2147483647) {
        printf("ERROR: Constante decimal excede el rango permitido: %s\n", yytext);
        exit(1);
    }
    agregar_simbolo(yytext, "CONSTANTE", yytext, yylineno);
    yylval.ival = atoi(yytext);
    return CTE;
}

{CTE_HEX}       { 
    static int primera_vez = 1;
    if (primera_vez) {
        inicializar_lexer();
        primera_vez = 0;
    }
    
    printf("Constante hexadecimal: %s\n", yytext);
    agregar_simbolo(yytext, "CONSTANTE_HEX", yytext, yylineno);
    yylval.ival = (int)strtol(yytext, NULL, 16);
    return CTE;
}

{CTE_OCT}       { 
    static int primera_vez = 1;
    if (primera_vez) {
        inicializar_lexer();
        primera_vez = 0;
    }
    
    printf("Constante octal: %s\n", yytext);
    agregar_simbolo(yytext, "CONSTANTE_OCT", yytext, yylineno);
    yylval.ival = (int)strtol(yytext, NULL, 8);
    return CTE;
}

{CTE_REAL}      { 
    static int primera_vez = 1;
    if (primera_vez) {
        inicializar_lexer();
        primera_vez = 0;
    }
    
    printf("Constante real: %s\n", yytext);
    agregar_simbolo(yytext, "CONSTANTE_REAL", yytext, yylineno);
    yylval.ival = (int)atof(yytext);
    return CTE_REAL;
}

{CTE_STRING}    { 
    static int primera_vez = 1;
    if (primera_vez) {
        inicializar_lexer();
        primera_vez = 0;
    }
    
    printf("Constante string: %s\n", yytext);
    agregar_simbolo(yytext, "CONSTANTE_STRING", yytext, yylineno);
    yylval.sval = strdup(yytext);
    return CTE_STRING;
}

{CTE_CHAR}      { 
    static int primera_vez = 1;
    if (primera_vez) {
        inicializar_lexer();
        primera_vez = 0;
    }
    
    printf("Constante char: %s\n", yytext);
    agregar_simbolo(yytext, "CONSTANTE_CHAR", yytext, yylineno);
    yylval.ival = yytext[1];
    return CTE_CHAR;
}

{CTE_DATE}    { 
    static int primera_vez = 1;
    if (primera_vez) {
        inicializar_lexer();
        primera_vez = 0;
    }
    
    printf("Constante Fecha Convertida: %s\n", yytext);
    // Verificar rango de constantes
    if (strlen(yytext) > 10) {
        printf("ERROR: La fecha excede el rango permitido: %s\n", yytext);
        exit(1);
    }
    agregar_simbolo(yytext, "CONSTANTE_DATE", yytext, yylineno);
    yylval.sval = strdup(yytext);
    return CTE_DATE;
}

"init"          { 
    static int primera_vez = 1;
    if (primera_vez) {
        inicializar_lexer();
        primera_vez = 0;
    }
    
    printf("Palabra reservada: init\n"); 
    return INIT; 
}

"Int"           { printf("Tipo: Int\n"); return INT; }
"Float"         { printf("Tipo: Float\n"); return FLOAT; }
"Char"          { printf("Tipo: Char\n"); return CHAR; }
"String"        { printf("Tipo: String\n"); return STRING; }
"Bool"          { printf("Tipo: Bool\n"); return BOOL; }

"if"            { 
    static int primera_vez = 1;
    if (primera_vez) {
        inicializar_lexer();
        primera_vez = 0;
    }
    
    printf("Palabra reservada: if\n"); 
    return IF; 
}
"else"          { printf("Palabra reservada: else\n"); return ELSE; }
"while"         { printf("Palabra reservada: while\n"); return WHILE; }
"return"        { printf("Palabra reservada: return\n"); return RETURN; }
"int"           { printf("Palabra reservada: int\n"); return INT; }
"float"         { printf("Palabra reservada: float\n"); return FLOAT; }
"char"          { printf("Palabra reservada: char\n"); return CHAR; }
"string"        { printf("Palabra reservada: string\n"); return STRING; }
"bool"          { printf("Palabra reservada: bool\n"); return BOOL; }
"true"          { printf("Palabra reservada: true\n"); return TRUE; }
"false"         { printf("Palabra reservada: false\n"); return FALSE; }
"void"          { printf("Palabra reservada: void\n"); return VOID; }
"main"          { printf("Palabra reservada: main\n"); return MAIN; }
"write"         { printf("Palabra reservada: write\n"); return WRITE; }
"equalExpressions" { printf("Funcion: equalExpressions\n"); return EQUAL_EXPRESSIONS; }
"AND"            { printf("Operador AND: %s\n", yytext); return OP_AND; }
"OR"             { printf("Operador OR: %s\n", yytext); return OP_OR; }
"NOT"            { printf("Operador NOT: %s\n", yytext); return OP_NOT; }
"convDate"      { printf("Funcion: convDate\n"); return CONVDATE; }

{ID}            { 
    static int primera_vez = 1;
    if (primera_vez) {
        inicializar_lexer();
        primera_vez = 0;
    }
    
    printf("Identificador: %s\n", yytext);
    // Verificar longitud del identificador
    if (strlen(yytext) > 31) {
        printf("ERROR: Identificador excede la longitud maxima permitida: %s\n", yytext);
        exit(1);
    }
    // Si no existe en la tabla, agregarlo como variable
    if (buscar_simbolo(yytext) == -1) {
        agregar_simbolo(yytext, "VARIABLE", "", yylineno);
    }
    yylval.sval = strdup(yytext);
    return ID;
}

{OP_AS}         { printf("Operador de asignacion: %s\n", yytext); return OP_AS; }
{OP_SUM}        { printf("Operador suma: %s\n", yytext); return OP_SUM; }
{OP_MUL}        { printf("Operador multiplicacion: %s\n", yytext); return OP_MUL; }
{OP_RES}        { printf("Operador resta: %s\n", yytext); return OP_RES; }
{OP_DIV}        { printf("Operador division: %s\n", yytext); return OP_DIV; }
{OP_MOD}        { printf("Operador modulo: %s\n", yytext); return OP_MOD; }
{OP_POT}        { printf("Operador potencia: %s\n", yytext); return OP_POT; }
{OP_IGUAL}      { printf("Operador igual: %s\n", yytext); return OP_IGUAL; }
{OP_DIF}        { printf("Operador diferente: %s\n", yytext); return OP_DIF; }
{OP_MENOR}      { printf("Operador menor: %s\n", yytext); return OP_MENOR; }
{OP_MAYOR}      { printf("Operador mayor: %s\n", yytext); return OP_MAYOR; }
{OP_MENOR_IGUAL} { printf("Operador menor igual: %s\n", yytext); return OP_MENOR_IGUAL; }
{OP_MAYOR_IGUAL} { printf("Operador mayor igual: %s\n", yytext); return OP_MAYOR_IGUAL; }

{PAR_A}         { printf("Parentesis abierto: %s\n", yytext); return PAR_A; }
{PAR_C}         { printf("Parentesis cerrado: %s\n", yytext); return PAR_C; }
{COR_A}         { printf("Corchete abierto: %s\n", yytext); return COR_A; }
{COR_C}         { printf("Corchete cerrado: %s\n", yytext); return COR_C; }
{LLAVE_A}       { printf("Llave abierta: %s\n", yytext); return LLAVE_A; }
{LLAVE_C}       { printf("Llave cerrada: %s\n", yytext); return LLAVE_C; }
{PUNTO_COMA}    { printf("Punto y coma: %s\n", yytext); return PUNTO_COMA; }
{COMA}          { printf("Coma: %s\n", yytext); return COMA; }
{PUNTO}         { printf("Punto: %s\n", yytext); return PUNTO; }
{DOS_PUNTOS}    { printf("Dos puntos: %s\n", yytext); return DOS_PUNTOS; }

{COMENTARIO_LINEA}  { 
    printf("Comentario de linea: %s\n", yytext); 
    /* Ignorar comentarios */
}
{COMENTARIO_BLOQUE} { 
    printf("Comentario de bloque: %s\n", yytext); 
    /* Ignorar comentarios */
}

"\n"            { /* Nueva linea */ }
"\t"            { /* Tab */ }
" "             { /* Espacio */ }
"\r"            { /* Retorno de carro */ }

.               { 
    printf("ERROR LEXICO: Caracter no reconocido '%s' en linea %d\n", yytext, yylineno); 
    exit(1);
}

%%