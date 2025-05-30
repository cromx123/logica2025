%{
/***************************************************************************************
 * 
 * tarea1.c: Algoritmo de Satisfactibilidad 
 * Programmer: Benjamin Caceres, Cristobal Gallardo
 * Santiago de Chile, 26/05/2025
 *
 **************************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char **tokens = NULL;
int num_tokens = 0, capacidad_tokens = 0, pos = 0, memo_size = 0, memo_capacity = 0;
/*
*
*
*/
void agregar_token(const char *tok) {
    int i, nueva_capacidad, len;
    char **nuevo_espacio;
    if (num_tokens >= capacidad_tokens) {
        if(capacidad_tokens == 0) {
            nueva_capacidad = 10;
        }
        else {
            nueva_capacidad = capacidad_tokens * 2;
        }
        nuevo_espacio = calloc(nueva_capacidad, sizeof(char *));

        for (i = 0; i < num_tokens; i = i + 1) {
            nuevo_espacio[i] = tokens[i];
        }
        free(tokens);
        tokens = nuevo_espacio;
        capacidad_tokens = nueva_capacidad;
    }
    len = strlen(tok);
    tokens[num_tokens] = calloc(len + 1, sizeof(char));

    for (i = 0; i < len; i = i + 1) {
        tokens[num_tokens][i] = tok[i];
    }
    num_tokens = num_tokens + 1;
}

typedef enum {
    VAR, NEG, AND, OR, IMPLIES, TOP, BOT
} TipoNodo; 

struct Nodo {
    TipoNodo tipo;
    char *nombre;          
    struct Nodo *izq;
    struct Nodo *der;
};


char* ulong_a_hex(unsigned long valor) {
    char* hex = NULL, *result = NULL;
    const char* hex_digits;
    int i, start, len, j;

    hex = calloc(17, 1);
    if (!hex) {
        return NULL;
    }
    hex_digits = "0123456789abcdef";
    i = 15;
    hex[16] = '\0';

    if (valor == 0) {
        hex[15] = '0';
        i = 14;
    } 
    else {
        while (valor > 0 && i >= 0) {
            hex[i] = hex_digits[valor % 16];
            i = i - 1;
            valor = valor / 16;
        }
    }

    start = i + 1;
    len = 16 - start;
    result = calloc(len + 1, 1);
    if (!result) {
        free(hex);
        return NULL;
    }

    for (j = 0; j < len; j = j + 1) {
        result[j] = hex[start + j];
    }
    result[len] = '\0';
    free(hex);
    return result;
}

char* clave_nodo(int tipo, struct Nodo* izq, struct Nodo* der, char* nombre) {
    const char* nombre_str;
    char* izq_str = NULL, *der_str = NULL, tipo_char, *clave = NULL;
    size_t offset, total_len, len, i;

    tipo_char = (char)tipo;
    izq_str = ulong_a_hex((unsigned long)izq);
    der_str = ulong_a_hex((unsigned long)der);
    if (!izq_str || !der_str) {
        return NULL;
    }
    if (nombre != NULL) {
        nombre_str = nombre;
    } 
    else {
        nombre_str = "";
    }
    total_len = 1 + 1 + strlen(izq_str) + 1 + strlen(der_str) + 1 + strlen(nombre_str) + 1;
    clave = calloc(total_len, 1);
    if (!clave) {
        free(izq_str);
        free(der_str);
        return NULL;
    }

    offset = 0;
    clave[offset] = tipo_char;
    offset = offset + 1;
    clave[offset] = '_';
    offset = offset + 1;

    for (i = 0; izq_str[i] != '\0'; i = i + 1) {
        clave[offset] = izq_str[i];
        offset = offset + 1;
    }
    clave[offset] = '_';
    offset = offset + 1;

    for (i = 0; der_str[i] != '\0'; i = i + 1) {
        clave[offset] = der_str[i];
        offset = offset + 1;
    }
    clave[offset] = '_';
    offset = offset + 1;

    for (i = 0; nombre_str[i] != '\0'; i = i + 1) {
        clave[offset] = nombre_str[i];
        offset = offset + 1;
    }
    clave[offset] = '\0';

    free(izq_str);
    free(der_str);
    return clave;
}

struct NodoMemo {
    char* clave;
    struct Nodo *nodo;
};

struct NodoMemo* memo = NULL;


int son_iguales(const char *a, const char *b) {
    while (*a && *b) {
        if (*a != *b){
            return 0;
        }
        a = a + 1;
        b = b + 1;
    }
    return *a == *b;
}

struct Nodo* buscar_en_memo(char* clave) {
    int i;
    for (i = 0; i < memo_size; i = i + 1) {
        if (son_iguales(memo[i].clave, clave)) {
            return memo[i].nodo;
        }
    }
    return NULL;
}

void guardar_en_memo(char* clave, struct Nodo* nodo) {
    memo[memo_size].clave = clave;
    memo[memo_size].nodo = nodo;
    memo_size = memo_size + 1;
}

struct Nodo *crear_nodo(TipoNodo tipo, struct Nodo *izq, struct Nodo *der, const char *nombre) {
    int i, len;
    struct Nodo *n = NULL;

    n = calloc(1, sizeof(struct Nodo));
    n->tipo = tipo;
    n->izq = izq;
    n->der = der;
    if (nombre) {
        len = 0;
        while (nombre[len] != '\0') {
            len = len + 1;
        }

        n->nombre = calloc(len + 1, sizeof(char));
        if (n->nombre) {
            for (i = 0; i <= len; i = i + 1) {
                n->nombre[i] = nombre[i]; 
            }
        }
    }
    else {
        n->nombre = NULL;
    }
    return n;
}

struct Nodo* crear_nodo_dag(char tipo, struct Nodo* izq, struct Nodo* der, char* nombre) {
    char* clave = clave_nodo(tipo, izq, der, nombre);
    struct Nodo *existente = NULL, *nuevo = NULL;

    existente = buscar_en_memo(clave);
    if (existente != NULL) {
        free(clave);
        return existente;
    }

    nuevo = crear_nodo(tipo, izq, der, nombre);
    guardar_en_memo(clave, nuevo);
    return nuevo;
}



// Parseo recursivo básico
struct Nodo *parse_formula();

struct Nodo *parse_atom() {
    struct Nodo *n = NULL;
    char *tok = tokens[pos];

    if (pos >= num_tokens) {
        return NULL;
    } 
    pos = pos + 1;  

    if (tok[0] == '(' && tok[1] == '\0') {
        n = parse_formula();
        if (pos >= num_tokens || strcmp(tokens[pos], ")") != 0) {
            return NULL;
        }
        pos = pos + 1;
        return n;
    } 
    else if (tok[0] == 'N' && tok[1] == 'E' && tok[2] == 'G' && tok[3] == '\0') {
        n = parse_atom();
        if (n == NULL)  {
            return NULL;
        } 
        return crear_nodo_dag(NEG, n, NULL, NULL);
    } 
    else {
        return crear_nodo_dag(VAR, NULL, NULL, tok);
    }
    return NULL;
}

struct Nodo *parse_formula() {
    int es_and, es_or, es_implies;
    char *tok;
    struct Nodo *izq = NULL, *der = NULL;

    if (pos >= num_tokens) {
        return NULL;
    }
    izq = parse_atom();
    if (izq == NULL) {
        return NULL;
    }
    if (pos >= num_tokens) {
        return izq;
    }

    tok = tokens[pos];
    es_and = tok[0] == 'A' && tok[1] == 'N' && tok[2] == 'D' && tok[3] == '\0';
    es_or = tok[0] == 'O' && tok[1] == 'R' && tok[2] == '\0';
    es_implies = tok[0] == 'I' && tok[1] == 'M' && tok[2] == 'P' && tok[3] == 'L' && tok[4] == 'I' && tok[5] == 'E' && tok[6] == 'S' && tok[7] == '\0';

    if (es_and || es_or || es_implies) {
        pos = pos + 1;
        der = parse_formula();
        if (der == NULL) {
            return NULL;
        }
        if (es_and) {
            return crear_nodo_dag(AND, izq, der, NULL);
        }
        if (es_or) {
            return crear_nodo_dag(OR, izq, der, NULL);
        }

        if (es_implies) {
            return crear_nodo_dag(IMPLIES, izq, der, NULL);
        }
    }

    return izq;
}


struct Nodo* copiar_nodo(struct Nodo *nodo) {
    if (!nodo) {
        return NULL;
    }
    return crear_nodo_dag(nodo->tipo, nodo->izq, nodo->der, nodo->nombre);
}



struct Nodo* negacion(struct Nodo *hijo) {
    return crear_nodo_dag(NEG, hijo, NULL, NULL);
}

struct Nodo* conjuncion(struct Nodo *a, struct Nodo *b) {
    return crear_nodo_dag(AND, a, b, NULL);
}

struct Nodo* empujar_negaciones(struct Nodo *nodo) {
    if (!nodo) {
        return NULL;
    }

    switch (nodo->tipo) {
        case VAR:
            return copiar_nodo(nodo);

        case AND:
        case OR:
            return crear_nodo_dag(nodo->tipo, empujar_negaciones(nodo->izq), empujar_negaciones(nodo->der), NULL);
        case NEG: {
            struct Nodo *sub = nodo->izq;
            if (sub->tipo == VAR) {
                return copiar_nodo(nodo);  
            } 
            else if (sub->tipo == NEG) {
                return empujar_negaciones(sub->izq);
            } 
            else if (sub->tipo == AND) {
                return crear_nodo_dag(OR, empujar_negaciones(negacion(sub->izq)), empujar_negaciones(negacion(sub->der)), NULL);
            } 
            else if (sub->tipo == OR) {
                return crear_nodo_dag(AND, empujar_negaciones(negacion(sub->izq)), empujar_negaciones(negacion(sub->der)), NULL);
            }
            break;
        }
        default:
            return NULL;
    }
    return NULL;
}

struct Nodo* distribuir_o(struct Nodo *a, struct Nodo *b) {
    if (a->tipo == AND) {
        return crear_nodo_dag(AND, distribuir_o(a->izq, b), distribuir_o(a->der, b), NULL);
    }
    if (b->tipo == AND) {
        return crear_nodo_dag(AND, distribuir_o(a, b->izq), distribuir_o(a, b->der), NULL);
    }
    return crear_nodo_dag(OR, a, b, NULL);
}

struct Nodo* convertir_cnf(struct Nodo *nodo) {
    struct Nodo *izq = NULL, *der = NULL;
    
    if (!nodo) {
        return NULL;
    }
    if (nodo->tipo == AND) {
        return crear_nodo_dag(AND, convertir_cnf(nodo->izq), convertir_cnf(nodo->der), NULL);
    }

    if (nodo->tipo == OR) {
        izq = convertir_cnf(nodo->izq);
        der = convertir_cnf(nodo->der);
        return distribuir_o(izq, der);
    }

    return copiar_nodo(nodo);
}

 // Traducción
struct Nodo* traducir(struct Nodo *nodo) {
    struct Nodo *izq_t = NULL, *der_t = NULL;
    if (!nodo) {
        return NULL;
    }

    switch (nodo->tipo) {
        case VAR:
            return copiar_nodo(nodo);

        case NEG:
            return negacion(traducir(nodo->izq));

        case AND:
            return conjuncion(traducir(nodo->izq), traducir(nodo->der));

        case OR: {
            // T(1 ∨ 2) = ¬(¬T(1) ∧ ¬T(2))
            izq_t = traducir(nodo->izq);
            der_t = traducir(nodo->der);
            return negacion(conjuncion(negacion(izq_t), negacion(der_t)));
        }

        case IMPLIES: {
            // T(1 → 2) = ¬(T(1) ∧ ¬T(2))
            izq_t = traducir(nodo->izq);
            der_t = traducir(nodo->der);
            return negacion(conjuncion(izq_t, negacion(der_t)));
        }

        default:
            return NULL;
    }
}

// Evaluación
int eval(struct Nodo *n, char **vars, int *vals, int n_vars) {
    int i, a, b;
    if (!n) {
        return 0;
    }

    switch (n->tipo) {
        case VAR:
            for (i = 0; i < n_vars; i = i + 1) {
                if (son_iguales(vars[i], n->nombre)) {
                    return vals[i];
                }
            }
            return 0;

        case NEG:
            return !eval(n->izq, vars, vals, n_vars);

        case AND:
            return eval(n->izq, vars, vals, n_vars) && eval(n->der, vars, vals, n_vars);

        case OR:
            return eval(n->izq, vars, vals, n_vars) || eval(n->der, vars, vals, n_vars);

        case IMPLIES: {
            a = eval(n->izq, vars, vals, n_vars);
            b = eval(n->der, vars, vals, n_vars);
            return !a || b;
        }

        case TOP: 
            return 1;
        case BOT: 
            return 0;
    }
    return 0;
}

void recolectar_vars(struct Nodo *n, char **vars, int *n_vars) {
    int i;
    if (!n) {
        return;
    }
    if (n->tipo == VAR) {
        for (i = 0; i < *n_vars; i = i + 1) {
            if (son_iguales(vars[i], n->nombre)) {
                return;
            }
        }
        vars[*n_vars] = n->nombre;
        *n_vars = *n_vars + 1;
    } else {
        recolectar_vars(n->izq, vars, n_vars);
        recolectar_vars(n->der, vars, n_vars);
    }
}

int es_satisfacible(struct Nodo *n) {
    char **vars_tmp, **vars;
    int i, j, capacidad, n_vars, *vals, total, result;

    capacidad = 10;
    n_vars = 0;
    vars_tmp = calloc(capacidad, sizeof(char *));

    recolectar_vars(n, vars_tmp, &n_vars);

    vars = calloc(n_vars, sizeof(char *));
    vals = calloc(n_vars, sizeof(int));

    for (i = 0; i < n_vars; i = i + 1) {
        vars[i] = vars_tmp[i];
    }

    free(vars_tmp);

    total = 1 << n_vars; // 2^n combinaciones

    for (i = 0; i < total; i = i + 1) {
        for (j = 0; j < n_vars; j = j + 1) {
            vals[j] = (i >> j) & 1;
        }
        result = eval(n, vars, vals, n_vars);
        if (result == 1) {
            free(vars);
            free(vals);
            return 1; // satisfacible
        }
    }

    free(vars);
    free(vals);
    return 0; // no satisfacible
}



void imprimir_formula_original() {
    int i;
    printf("Tokens leídos:\n");
    for (i = 0; i < num_tokens; i = i + 1) {
        printf("%s ", tokens[i]);
    }
    printf("\n");
}

void imprimir_nodo(struct Nodo *n) {
    if (!n) {
        return;
    }
    switch (n->tipo) {
        case VAR: printf("%s", n->nombre); break;
        case TOP: printf("\u22A4"); break;
        case BOT: printf("\u22A5"); break;
        case NEG:
            printf("¬");
            imprimir_nodo(n->izq);
            break;
        case AND:
            printf("(");
            imprimir_nodo(n->izq);
            printf(" ∧ ");
            imprimir_nodo(n->der);
            printf(")");
            break;
        case OR:
            printf("(");
            imprimir_nodo(n->izq);
            printf(" ∨ ");
            imprimir_nodo(n->der);
            printf(")");
            break;
        case IMPLIES:
            printf("(");
            imprimir_nodo(n->izq);
            printf(" → ");
            imprimir_nodo(n->der);
            printf(")");
            break;
    }
}
void free_memory() {
    for (int i = 0; i < memo_size; i = i + 1) {
        if (memo[i].nodo->nombre)
            free(memo[i].nodo->nombre);
        free(memo[i].nodo);
        free(memo[i].clave);
    }
    memo_size = 0;
}

%}

%%a
"\\neg"        { agregar_token("NEG"); }
"\\wedge"      { agregar_token("AND"); }
"\\vee"        { agregar_token("OR"); }
"\\rightarrow" { agregar_token("IMPLIES"); }
"\\top"        { agregar_token("TOP"); }
"\\bot"        { agregar_token("BOT"); }
"("            { agregar_token("("); }
")"            { agregar_token(")"); }
[a-zA-Z][a-zA-Z0-9_]*    { agregar_token(yytext);}
"\$\$"         { /* ignora $$ */ }
"$"            { /**/}
[ \t\r]        { /* ignora espacios */ }
[ \n]          { printf("\n");} 
.              { printf("UNKNOWN: %s\n", yytext); }
%%



int main(int argc, char **argv) {
    struct Nodo *arbol = NULL, *traducida = NULL, *sin_neg = NULL, *cnf = NULL;
    // printf("Inicio de programa\n");
    yylex();

    arbol = parse_formula();

    if (!arbol || pos < num_tokens) {
        printf("NO-SOLUTION\n");
        free_memory();
        return 1;
    }

    // printf("Fórmula original: ");
    // imprimir_nodo(arbol);
    // printf("\n");

    traducida = traducir(arbol);
    // printf("Fórmula en Sat Lineal: ");
    // imprimir_nodo(traducida);
    // printf("\n");

    sin_neg = empujar_negaciones(traducida);
    cnf = convertir_cnf(sin_neg);
    // printf("Fórmula en CNF: ");
    // imprimir_nodo(cnf);
    // printf("\n");

    if (es_satisfacible(cnf) == 1) {
        printf("SATISFACIBLE\n");
    } else {
        printf("NO-SATISFACIBLE\n");
    }    
    // Libera memoria asignada 
    free_memory();
    return 0;
}