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
int num_tokens = 0;
int capacidad_tokens = 0;

void agregar_token(const char *tok) {
    int i, nueva_capacidad;
    char **nuevo_espacio;
    if (num_tokens >= capacidad_tokens) {
        if(capacidad_tokens == 0){
            nueva_capacidad = 10;
        }else{
            nueva_capacidad = capacidad_tokens * 2;
        }

        nuevo_espacio = malloc(nueva_capacidad * sizeof(char *));
        if (nuevo_espacio == NULL) {
            fprintf(stderr, "Error al asignar memoria para tokens\n");
            exit(EXIT_FAILURE);
        }

        // Copiar los punteros existentes
        for (i = 0; i < num_tokens; i = i + 1) {
            nuevo_espacio[i] = tokens[i];
        }

        free(tokens); // Liberar memoria antigua
        tokens = nuevo_espacio;
        capacidad_tokens = nueva_capacidad;
    }

    tokens[num_tokens] = malloc(strlen(tok) + 1);
    if (tokens[num_tokens] == NULL) {
        fprintf(stderr, "Error al asignar memoria para token\n");
        exit(EXIT_FAILURE);
    }

    strcpy(tokens[num_tokens], tok);
    num_tokens = num_tokens + 1;
}

// === TIPOS DE NODOS ===
typedef enum {
    VAR, NEG, AND, OR, IMPLIES, TOP, BOT
} TipoNodo;

// === NODO DEL ARBOL ===
struct Nodo {
    TipoNodo tipo;
    char *nombre;          
    struct Nodo *izq;
    struct Nodo *der;
};

int pos = 0;

// === FUNCIONES AUXILIARES ===


struct Nodo *crear_nodo(TipoNodo tipo, struct Nodo *izq, struct Nodo *der, const char *nombre) {
    struct Nodo *n = malloc(sizeof(struct Nodo));
    n->tipo = tipo;
    n->izq = izq;
    n->der = der;
    if (nombre) {
        n->nombre = malloc(strlen(nombre) + 1);
        if (n->nombre)
            strcpy(n->nombre, nombre);
    } else {
        n->nombre = NULL;
    }
    return n;
}


// Parseo recursivo básico
struct Nodo *parse_formula();

struct Nodo *parse_atom() {
    char *tok = tokens[pos];
    pos = pos + 1;  
    if (strcmp(tok, "(") == 0) {
        struct Nodo *n = parse_formula();
        pos = pos + 1;
        return n;
    } else if (strcmp(tok, "NEG") == 0) {
        struct Nodo *n = parse_atom();
        return crear_nodo(NEG, n, NULL, NULL);
    } else {
        return crear_nodo(VAR, NULL, NULL, tok);
    }
}

struct Nodo *parse_formula() {
    struct Nodo *izq = parse_atom();
    if (pos >= num_tokens) {
        return izq;
    }

    char *tok = tokens[pos];
    if (strcmp(tok, "AND") == 0 || strcmp(tok, "OR") == 0 || strcmp(tok, "IMPLIES") == 0) {
        pos = pos + 1;
        struct Nodo *der = parse_formula();
        if (strcmp(tok, "AND") == 0) return crear_nodo(AND, izq, der, NULL);
        if (strcmp(tok, "OR") == 0) return crear_nodo(OR, izq, der, NULL);
        if (strcmp(tok, "IMPLIES") == 0) return crear_nodo(IMPLIES, izq, der, NULL);
    }
    return izq;
}

struct Nodo* copiar_nodo(struct Nodo *nodo);

struct Nodo* copiar_nodo(struct Nodo *nodo) {
    struct Nodo *nuevo = malloc(sizeof(struct Nodo));
    nuevo->tipo = nodo->tipo;

    if (nodo->nombre) {
        nuevo->nombre = malloc(strlen(nodo->nombre) + 1);
        if (nuevo->nombre)
            strcpy(nuevo->nombre, nodo->nombre);
    } else {
        nuevo->nombre = NULL;
    }

    if (nodo->izq != NULL) {
        nuevo->izq = copiar_nodo(nodo->izq);
    } else {
        nuevo->izq = NULL;
    }

    if (nodo->der != NULL){
        nodo->der = copiar_nodo(nodo->der);
    }else{
        nodo->der = NULL;
    }
    return nuevo;
}



struct Nodo* negacion(struct Nodo *hijo) {
    struct Nodo *nuevo = (struct Nodo*)malloc(sizeof(struct Nodo));
    nuevo->tipo = NEG;
    nuevo->nombre = NULL;
    nuevo->izq = hijo;
    nuevo->der = NULL;
    return nuevo;
}

struct Nodo* conjuncion(struct Nodo *a, struct Nodo *b) {
    struct Nodo *nuevo = (struct Nodo*)malloc(sizeof(struct Nodo));
    nuevo->tipo = AND;
    nuevo->nombre = NULL;
    nuevo->izq = a;
    nuevo->der = b;
    return nuevo;
}

/* struct Nodo* empujar_negaciones(struct Nodo *nodo) {
    if (!nodo) return NULL;

    switch (nodo->tipo) {
        case VAR:
            return copiar_nodo(nodo);

        case AND:
        case OR:
            return crear_nodo(nodo->tipo,
                              empujar_negaciones(nodo->izq),
                              empujar_negaciones(nodo->der),
                              NULL);

        case NEG: {
            struct Nodo *sub = nodo->izq;
            if (sub->tipo == VAR) {
                return copiar_nodo(nodo);  
            } else if (sub->tipo == NEG) {
                return empujar_negaciones(sub->izq);
            } else if (sub->tipo == AND) {
                return crear_nodo(OR,
                        empujar_negaciones(negacion(sub->izq)),
                        empujar_negaciones(negacion(sub->der)),
                        NULL);
            } else if (sub->tipo == OR) {
                return crear_nodo(AND,
                        empujar_negaciones(negacion(sub->izq)),
                        empujar_negaciones(negacion(sub->der)),
                        NULL);
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
        return crear_nodo(AND,
            distribuir_o(a->izq, b),
            distribuir_o(a->der, b),
            NULL);
    }
    if (b->tipo == AND) {
        return crear_nodo(AND,
            distribuir_o(a, b->izq),
            distribuir_o(a, b->der),
            NULL);
    }
    return crear_nodo(OR, a, b, NULL);
}

struct Nodo* convertir_cnf(struct Nodo *nodo) {
    if (!nodo) return NULL;

    if (nodo->tipo == AND) {
        return crear_nodo(AND,
            convertir_cnf(nodo->izq),
            convertir_cnf(nodo->der),
            NULL);
    }

    if (nodo->tipo == OR) {
        struct Nodo *izq = convertir_cnf(nodo->izq);
        struct Nodo *der = convertir_cnf(nodo->der);
        return distribuir_o(izq, der);
    }

    return copiar_nodo(nodo);
}
 */

 // Traducción
struct Nodo* traducir(struct Nodo *nodo) {
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
            struct Nodo *izq_t = traducir(nodo->izq);
            struct Nodo *der_t = traducir(nodo->der);
            return negacion(conjuncion(negacion(izq_t), negacion(der_t)));
        }

        case IMPLIES: {
            // T(1 → 2) = ¬(T(1) ∧ ¬T(2))
            struct Nodo *izq_t = traducir(nodo->izq);
            struct Nodo *der_t = traducir(nodo->der);
            return negacion(conjuncion(izq_t, negacion(der_t)));
        }

        default:
            return NULL;
    }
}

int eval(struct Nodo *n, char **vars, int *vals, int n_vars) {
    int i, a, b;
    if (!n) {
        return 0;
    }

    switch (n->tipo) {
        case VAR:
            for (i = 0; i < n_vars; i = i + 1) {
                if (strcmp(vars[i], n->nombre) == 0)
                    return vals[i];
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
            if (strcmp(vars[i], n->nombre) == 0) {
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
    char *vars[10];
    int vals[10]; // toma valores 1 o 0 si es verdadero o falso
    int n_vars = 0;
    int result, total, i, j;
    recolectar_vars(n, vars, &n_vars);

    total = 1 << n_vars; // 2^n combinaciones

    for (i = 0; i < total; i = i + 1) {
        for (j = 0; j < n_vars; j = j + 1)
            vals[j] = (i >> j) & 1;
    
        result = eval(n, vars, vals, n_vars);
    }

    return result;
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

void free_tokens(){
    int i;
    for (i = 0; i < num_tokens; i = i + 1) {
        free(tokens[i]);
    }
    free(tokens);
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
[a-z][0-9]*    { agregar_token(yytext);}
"\$\$"         { /* ignora $$ */ }
"$"            { /**/}
[ \t\r]        { /* ignora espacios */ }
[ \n]          { printf("\n");} 
.              { printf("UNKNOWN: %s\n", yytext); }
%%



int main(int argc, char **argv) {
    printf("Inicio de programa\n");
    yylex();
    struct Nodo *arbol = parse_formula();
    printf("Fórmula original: ");
    imprimir_nodo(arbol);
    printf("\n");

    struct Nodo *traducida = traducir(arbol);  // transforma OR e IMPLIES
    printf("Fórmula en Sat Lineal: ");
    imprimir_nodo(traducida);
    printf("\n");

    
    // struct Nodo *sin_neg = empujar_negaciones(traducida);
    // struct Nodo *cnf = convertir_cnf(sin_neg);
    // printf("Fórmula en CNF: ");
    // imprimir_nodo(cnf);
    // printf("\n");

    if (es_satisfacible(traducida) == 1) {
        printf("SATISFACIBLE\n");
    } else {
        printf("NO-SATISFACIBLE\n");
    }    
    // Libera memoria asignada para los tokens
    free_tokens();
    return 0;
}