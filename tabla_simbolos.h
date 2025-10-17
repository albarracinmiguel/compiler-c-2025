#ifndef TABLA_SIMBOLOS_H
#define TABLA_SIMBOLOS_H

//tipos de simbolos
#define T_CTE "CONSTANTE"
#define T_VAR "VARIABLE"
#define T_HEX "CONSTANTE_HEX"
#define T_FLOAT "CONSTANTE_REAL"
#define T_STRING "CONSTANTE_STRING"
#define T_CHAR "CONSTANTE_CHAR"

typedef struct {
    char nombre[50];
    char tipo[20];
    char valor[50];
    int longitud;
    int linea;
} Simbolo;

// definidos en el lexer
extern Simbolo tabla_simbolos[1000];
extern int num_simbolos;

int buscar_simbolo(char* nombre);
void agregar_simbolo(char* nombre, char* tipo, char* valor, int linea);
void generar_tabla_simbolos(void);
void inicializar_lexer(void);

const Simbolo* obtener_tabla_simbolos(int* cantidad);
const Simbolo* obtener_simbolo_por_nombre(const char* nombre);

#endif
