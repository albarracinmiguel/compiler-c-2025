%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "y.tab.h"
#include "tabla_simbolos.h"
#define MAX_SIZE 1000

int yystopparser = 0;
extern FILE *yyin;

int yyerror();
int yylex();

int nivel_anidamiento = 0;
int num_errores = 0;

// definiciones para polaca
char **polaca = NULL;
int limite_polaca = 0;
int idx = 0;
int idx_var = 0;
char condicion[4];
char variables_definidas[1000][50];

void volcar_polaca_en_archivo() {
    
    FILE *f = fopen("intermediate-code.txt", "w");
    if (!f) {
        printf("No se pudo abrir polaca.txt para escritura\n");
        return;
    }
    // calcular el ancho maximo
    int max_len = 0;
    char buffer[100];
    for (int i = 0; i < idx; i++) {
        
        int len = polaca[i] ? strlen(polaca[i]) : 0;
        if (len > max_len) max_len = len;
        //puede pasar que el numero sea mas ancho
        sprintf(buffer, "%d", i);
        int num_len = strlen(buffer);
        if (num_len > max_len) max_len = num_len;
    }
    // indices
    for (int i = 0; i < idx; i++) {
        sprintf(buffer, "%d", i);
        fprintf(f, "%-*s", max_len, buffer);
        if (i < idx - 1) fprintf(f, " ");
    }
    fprintf(f, "\n");
    // valores
    for (int i = 0; i < idx; i++) {
        fprintf(f, "%-*s", max_len, polaca[i] ? polaca[i] : "");
        if (i < idx - 1) fprintf(f, " ");
    }
    fprintf(f, "\n");
    fclose(f);
    printf("Archivo intermediate-code.txt generado.\n");
}

static void reservar(int capacidad) {
    if (limite_polaca >= capacidad) return;
    int nuevo_limite = limite_polaca ? limite_polaca : 64;
    while (nuevo_limite < capacidad) nuevo_limite *= 2;
    char **tmp = (char**)realloc(polaca, nuevo_limite * sizeof(char*));
    if (!tmp) {
        printf("Error de memoria ampliando polaca a %d elementos\n", nuevo_limite);
        exit(1);
    }
    // inicializa en null
    for (int i = limite_polaca; i < nuevo_limite; ++i) tmp[i] = NULL;
    polaca = tmp;
    limite_polaca = nuevo_limite;
}

//implementacion de pila de int para los branches
typedef struct {
    int arr[MAX_SIZE];  
    int top;        
} Stack;

void init(Stack *stack) {
    stack->top = -1;  
}

bool isEmpty(Stack *stack) {
    return stack->top == -1;  
}

bool isFull(Stack *stack) {
    return stack->top == MAX_SIZE - 1;  
}

void push(Stack *stack, int value) {
    
    if (isFull(stack)) {
        printf("pila llena\n");
        return;
    }
    stack->arr[++stack->top] = value;
}

int pop(Stack *stack) {
    if (isEmpty(stack)) {
        return -1;
    }
    int popped = stack->arr[stack->top];
    stack->top--;
    return popped;
}

void insertar_en_polaca(char* elemento) {
    reservar(idx + 1);
    polaca[idx++] = elemento;
}

void insertar_int_en_polaca(int valor) {
    char* buffer = (char*)malloc(20 * sizeof(char));
    if (!buffer) return;
    sprintf(buffer, "%d", valor);
    reservar(idx + 1);
    polaca[idx++] = buffer;
}

void reemplazar_en_polaca(int posicion, int valor) {
    char* buffer = (char*)malloc(20 * sizeof(char));
    if (!buffer) return;
    sprintf(buffer, "%d", valor);
    //reservar(posicion + 1);
    polaca[posicion] = buffer;
}

bool ya_definida(char* var) {
    for (int i = 0; i < 1000; i++) {
        if (strcmp(variables_definidas[i], var) == 0) {
            return true;
        }
    }
    return false;
}

Stack pila;


%}

%union {
    int ival;
    char *sval;
}

%token <ival> CTE 
%token <sval> ID CTE_STRING CTE_REAL CTE_CHAR
%token OP_AS OP_SUM OP_MUL OP_RES OP_DIV OP_MOD OP_POT
%token OP_IGUAL OP_DIF OP_MENOR OP_MAYOR OP_MENOR_IGUAL OP_MAYOR_IGUAL
%token OP_AND OP_OR OP_NOT
%token PAR_A PAR_C COR_A COR_C LLAVE_A LLAVE_C PUNTO_COMA COMA PUNTO DOS_PUNTOS
%token IF ELSE WHILE RETURN WRITE READ EQUAL_EXPRESSIONS CONVDATE
%token INT FLOAT CHAR STRING BOOL TRUE FALSE VOID MAIN CONST INIT

%type <ival> expresion termino factor
%type <ival> condicion expresion_logica expresion_relacional
%type <ival> sentencia asignacion
%type <ival> seleccion iteracion
%type <ival> bloque_init lista_declaraciones declaracion_grupo
%type <sval> lista_ids tipo

%left OP_OR
%left OP_AND
%left OP_IGUAL OP_DIF
%left OP_MENOR OP_MAYOR OP_MENOR_IGUAL OP_MAYOR_IGUAL
%left OP_SUM OP_RES
%left OP_MUL OP_DIV OP_MOD
%right MENOS_UNARIO
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
        if(ya_definida($1)) {
            printf("ERROR: Variable %s ya definida\n", $1);
            exit(1);
        } else {
            strcpy(variables_definidas[idx_var++], $1);
        }
    }
    | lista_ids COMA ID
    { 
        printf("Variable adicional: %s\n", $3); 
        $$ = $3;
        if(ya_definida($3)) {
            printf("ERROR: Variable %s ya definida\n", $3);
            exit(1);
        } else {
            strcpy(variables_definidas[idx_var++], $3);
        }
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
    asignacion
    | expresion
    | seleccion
    | iteracion
    { printf("Sentencia return\n"); }
    | WRITE PAR_A CTE_STRING PAR_C
    { printf("Sentencia write\n"); }
    | READ PAR_A CTE_STRING PAR_C
    { printf("Sentencia read\n"); }
    ;

asignacion:
    ID OP_AS expresion
    { printf("Asignacion: %s = expresion\n", $1); 
      insertar_en_polaca($1);
      insertar_en_polaca(":=");
    }
    ;

seleccion:
    IF PAR_A condicion PAR_C LLAVE_A sentencias LLAVE_C
    { printf("Seleccion if\n");
    reemplazar_en_polaca(pop(&pila), idx);
    }
    | IF PAR_A condicion PAR_C LLAVE_A sentencias LLAVE_C sentencia_else LLAVE_A sentencias LLAVE_C
    { printf("Seleccion if-else\n");
    reemplazar_en_polaca(pop(&pila), idx);
    }
    ;

sentencia_else:
    ELSE 
    {
        insertar_en_polaca("BI");
        reemplazar_en_polaca(pop(&pila), idx+1);
        push(&pila, idx);
        insertar_en_polaca("#");
    }
    ;
iteracion:
    while PAR_A condicion PAR_C LLAVE_A sentencias fin_iteracion
    { printf("Iteracion while\n");}
    ;
while:
WHILE
{
    push(&pila, idx);
    insertar_en_polaca("ET");
}
;
fin_iteracion:
LLAVE_C
    { 
        insertar_en_polaca("BI");
        reemplazar_en_polaca(pop(&pila), idx+1);
        insertar_int_en_polaca(pop(&pila));
    }
    ;

condicion:
    expresion_logica
    {insertar_en_polaca("CMP");
    insertar_en_polaca(condicion); 
    push(&pila, idx);
    insertar_en_polaca("#");}
    ;

expresion_logica:
    expresion_relacional
    | expresion_relacional OP_AND expresion_relacional
    { printf("Expresion logica AND\n"); }
    | expresion_relacional OP_OR expresion_relacional
    { printf("Expresion logica OR\n"); }
    | OP_NOT expresion_relacional
    { printf("Expresion logica NOT\n"); }
    ;

expresion_relacional:
    expresion
        | expresion OP_IGUAL expresion
        { printf("Condicion de igualdad\n");
            strcpy(condicion, "BNE"); }
        | expresion OP_DIF expresion
        { printf("Condicion de diferencia\n");
            strcpy(condicion, "BEQ"); }
        | expresion OP_MENOR expresion
        { printf("Condicion menor que\n"); 
            strcpy(condicion, "BGE"); }
        | expresion OP_MAYOR expresion
        { printf("Condicion mayor que\n"); 
            strcpy(condicion, "BLE"); }
        | expresion OP_MENOR_IGUAL expresion
        { printf("Condicion menor o igual que\n"); 
            strcpy(condicion, "BGT"); }
        | expresion OP_MAYOR_IGUAL expresion
        { printf("Condicion mayor o igual que\n"); 
            strcpy(condicion, "BLT"); }
    ;

expresion:
    termino
    { printf("Termino es expresion\n"); }
    | expresion OP_SUM termino
    { printf("Expresion + termino\n");
      insertar_en_polaca("+"); }
    | expresion OP_RES termino
    { printf("Expresion - termino\n"); 
      insertar_en_polaca("-"); }
    | OP_RES expresion %prec MENOS_UNARIO
    { printf("Expresion con signo negativo\n"); }
    ;

termino:
    factor
    { printf("Factor es termino\n"); }
    | termino OP_MUL factor
    { printf("Termino * factor\n"); 
      insertar_en_polaca("*"); }
    | termino OP_DIV factor
    { printf("Termino / factor\n");
      insertar_en_polaca("/"); }
    | termino OP_MOD factor
    { printf("Termino %% factor\n"); 
      insertar_en_polaca("%"); }
    | termino OP_POT factor
    { printf("Termino ** factor\n");
      insertar_en_polaca("**"); }
    ;

factor:
    ID
    { printf("Identificador es factor: %s\n", $1); 
      insertar_en_polaca($1); }
    | CTE
    { printf("Constante es factor\n"); 
      insertar_int_en_polaca($1); }
    | CTE_REAL
    { printf("Constante real es factor\n"); 
      insertar_en_polaca($1); }
    | CTE_STRING
    { printf("Constante string es factor\n"); 
      insertar_en_polaca($1); }
    | CTE_CHAR
    { printf("Constante char es factor\n"); 
      insertar_en_polaca($1); }
    | PAR_A expresion PAR_C
    { printf("Expresion entre parentesis es factor\n"); }
    | TRUE
    { printf("Valor logico true es factor\n"); }
    | FALSE
    { printf("Valor logico false es factor\n"); }
    | EQUAL_EXPRESSIONS PAR_A lista_expresiones PAR_C
    { printf("Funcion equalExpressions\n"); }
    | CONVDATE PAR_A CTE OP_RES CTE OP_RES CTE PAR_C
    { printf("Funcion convDate\n"); }
    ;

lista_expresiones:
    expresion
    { printf("Primera expresion en lista\n"); }
    | lista_expresiones COMA expresion
    { printf("Expresion adicional en lista\n"); }
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
    init(&pila);
    yyparse();
    
    if (num_errores == 0) {
        printf("\n=== ANALISIS COMPLETADO EXITOSAMENTE ===\n");
            volcar_polaca_en_archivo();
    } else {
        printf("\n=== ANALISIS COMPLETADO CON %d ERRORES ===\n", num_errores);
            volcar_polaca_en_archivo();
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