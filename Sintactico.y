%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

int yystopparser = 0;
FILE *yyin;

int yyerror();
int yylex();

int nivel_anidamiento = 0;
int num_errores = 0;

%}

%union {
    int ival;
    char *sval;
}

%token <ival> CTE CTE_REAL CTE_STRING CTE_CHAR
%token <sval> ID
%token OP_AS OP_SUM OP_MUL OP_RES OP_DIV OP_MOD OP_POT
%token OP_IGUAL OP_DIF OP_MENOR OP_MAYOR OP_MENOR_IGUAL OP_MAYOR_IGUAL
%token OP_AND OP_OR OP_NOT
%token PAR_A PAR_C COR_A COR_C LLAVE_A LLAVE_C PUNTO_COMA COMA PUNTO DOS_PUNTOS
%token IF ELSE WHILE RETURN WRITE
%token INT FLOAT CHAR STRING BOOL TRUE FALSE VOID MAIN CONST INIT

%type <ival> expresion termino factor
%type <ival> condicion expresion_logica
%type <ival> sentencia sentencia_compuesta
%type <ival> seleccion iteracion
%type <ival> bloque_init lista_declaraciones declaracion_grupo
%type <sval> lista_ids tipo

%left OP_OR
%left OP_AND
%left OP_IGUAL OP_DIF
%left OP_MENOR OP_MAYOR OP_MENOR_IGUAL OP_MAYOR_IGUAL
%left OP_SUM OP_RES
%left OP_MUL OP_DIV OP_MOD
%right OP_POT
%right OP_NOT

%%

programa:
    bloque_init sentencias
    { printf("Programa reconocido exitosamente\n"); }
    ;

bloque_init:
    INIT LLAVE_A lista_declaraciones LLAVE_C
    { printf("Bloque de inicializacion reconocido\n"); }
    ;

lista_declaraciones:
    /* vacio */
    { printf("Lista de declaraciones vacia\n"); }
    | lista_declaraciones declaracion_grupo
    ;

declaracion_grupo:
    lista_ids DOS_PUNTOS tipo
    { printf("Declaracion de variables completada\n"); }
    ;

lista_ids:
    ID
    { 
        printf("Variable: %s\n", $1); 
        $$ = $1;
    }
    | lista_ids COMA ID
    { 
        printf("Variable adicional: %s\n", $3); 
        $$ = $1;
    }
    ;

tipo:
    INT     { printf("Tipo: int\n"); $$ = "int"; }
    | FLOAT { printf("Tipo: float\n"); $$ = "float"; }
    | CHAR  { printf("Tipo: char\n"); $$ = "char"; }
    | STRING { printf("Tipo: string\n"); $$ = "string"; }
    | BOOL  { printf("Tipo: bool\n"); $$ = "bool"; }
    ;

sentencias:
    /* vacio */
    { printf("Sentencias vacias\n"); }
    | sentencias sentencia
    ;

sentencia:
    sentencia_simple
    | sentencia_compuesta
    | seleccion
    | iteracion
    | RETURN expresion
    { printf("Sentencia return\n"); }
    ;

sentencia_simple:
    ID OP_AS expresion
    { printf("Asignacion: %s = expresion\n", $1); }
    | expresion
    | WRITE PAR_A CTE_STRING PAR_C
    { printf("Sentencia write\n"); }
    ;

sentencia_compuesta:
    LLAVE_A sentencias LLAVE_C
    { printf("Bloque de sentencias\n"); }
    ;

seleccion:
    IF PAR_A condicion PAR_C sentencia
    { printf("Seleccion if\n"); }
    | IF PAR_A condicion PAR_C sentencia ELSE sentencia
    { printf("Seleccion if-else\n"); }
    ;

iteracion:
    WHILE PAR_A condicion PAR_C sentencia_compuesta
    { printf("Iteracion while\n"); }
    ;

condicion:
    expresion_logica
    ;

expresion_logica:
    expresion_relacional
    { printf("Expresion logica: expresion_relacional\n"); }
    | expresion_logica OP_AND expresion_logica
    { printf("Expresion logica: AND\n"); }
    | expresion_logica OP_OR expresion_logica
    { printf("Expresion logica: OR\n"); }
    | OP_NOT expresion_logica
    { printf("Expresion logica: NOT\n"); }
    | PAR_A expresion_logica PAR_C
    { printf("Expresion logica: entre parentesis\n"); }
    ;

expresion_relacional:
    expresion
    | expresion OP_IGUAL expresion
    { printf("Condicion de igualdad\n"); }
    | expresion OP_DIF expresion
    { printf("Condicion de diferencia\n"); }
    | expresion OP_MENOR expresion
    { printf("Condicion menor que\n"); }
    | expresion OP_MAYOR expresion
    { printf("Condicion mayor que\n"); }
    | expresion OP_MENOR_IGUAL expresion
    { printf("Condicion menor o igual que\n"); }
    | expresion OP_MAYOR_IGUAL expresion
    { printf("Condicion mayor o igual que\n"); }
    | PAR_A expresion_relacional PAR_C
    { printf("Condicion relacional entre parentesis\n"); }
    ;

expresion:
    termino
    { printf("Termino es expresion\n"); }
    | expresion OP_SUM termino
    { printf("Expresion + termino\n"); }
    | expresion OP_RES termino
    { printf("Expresion - termino\n"); }
    ;

termino:
    factor
    { printf("Factor es termino\n"); }
    | termino OP_MUL factor
    { printf("Termino * factor\n"); }
    | termino OP_DIV factor
    { printf("Termino / factor\n"); }
    | termino OP_MOD factor
    { printf("Termino %% factor\n"); }
    | termino OP_POT factor
    { printf("Termino ** factor\n"); }
    ;

factor:
    ID
    { printf("Identificador es factor: %s\n", $1); }
    | CTE
    { printf("Constante es factor\n"); }
    | CTE_REAL
    { printf("Constante real es factor\n"); }
    | CTE_STRING
    { printf("Constante string es factor\n"); }
    | CTE_CHAR
    { printf("Constante char es factor\n"); }
    | PAR_A expresion PAR_C
    { printf("Expresion entre parentesis es factor\n"); }
    | OP_SUM factor
    { printf("Factor con signo positivo\n"); }
    | OP_RES factor
    { printf("Factor con signo negativo\n"); }
    | TRUE
    { printf("Valor logico true es factor\n"); }
    | FALSE
    { printf("Valor logico false es factor\n"); }
    ;

%%

int main(int argc, char *argv[])
{
    if (argc != 2) {
        printf("Uso: %s <archivo_entrada>\n", argv[0]);
        return 1;
    }
    
    if ((yyin = fopen(argv[1], "rt")) == NULL) {
        printf("No se puede abrir el archivo de prueba: %s\n", argv[1]);
        return 1;
    }
    
    printf("=== ANALIZADOR LEXICO Y SINTACTICO ===\n");
    printf("Analizando archivo: %s\n\n", argv[1]);
    
    printf("=== INICIANDO ANALISIS LEXICO ===\n");
    printf("Generando tabla de simbolos inicial...\n");
    
    yyparse();
    
    if (num_errores == 0) {
        printf("\n=== ANALISIS COMPLETADO EXITOSAMENTE ===\n");
    } else {
        printf("\n=== ANALISIS COMPLETADO CON %d ERRORES ===\n", num_errores);
    }
    
    fclose(yyin);
    return 0;
}

int yyerror()
{
    extern int yylineno;
    printf("ERROR SINTACTICO en linea %d\n", yylineno);
    num_errores++;
    return 0;
}