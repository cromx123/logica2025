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

#define MAX_TOKENS 100
char *tokens[MAX_TOKENS];
int num_tokens = 0;

void agregar_token(const char *tok) {
    tokens[num_tokens++] = strdup(tok);
}

// === TIPOS DE NODOS ===
typedef enum {
    VAR, NEG, AND, OR, IMPLIES, TOP, BOT
} TipoNodo;

// === NODO DEL ARBOL ===
typedef struct Nodo {
    TipoNodo tipo;
    char *nombre;          
    struct Nodo *izq;
    struct Nodo *der;
} Nodo;

int pos = 0;

// === FUNCIONES AUXILIARES ===


Nodo *crear_nodo(TipoNodo tipo, Nodo *izq, Nodo *der, const char *nombre) {
    Nodo *n = malloc(sizeof(Nodo));
    n->tipo = tipo;
    n->izq = izq;
    n->der = der;
    if (nombre)
        n->nombre = strdup(nombre);
    else
        n->nombre = NULL;
    return n;
}


// Parseo recursivo básico
Nodo *parse_formula();

Nodo *parse_atom() {
    char *tok = tokens[pos++];
    if (strcmp(tok, "(") == 0) {
        Nodo *n = parse_formula();
        pos++; // saltar ')'
        return n;
    } else if (strcmp(tok, "NEG") == 0) {
        Nodo *n = parse_atom();
        return crear_nodo(NEG, n, NULL, NULL);
    } else {
        return crear_nodo(VAR, NULL, NULL, tok);
    }
}

Nodo *parse_formula() {
    Nodo *izq = parse_atom();
    if (pos >= num_tokens) return izq;

    char *tok = tokens[pos];
    if (strcmp(tok, "AND") == 0 || strcmp(tok, "OR") == 0 || strcmp(tok, "IMPLIES") == 0) {
        pos++;
        Nodo *der = parse_formula();
        if (strcmp(tok, "AND") == 0) return crear_nodo(AND, izq, der, NULL);
        if (strcmp(tok, "OR") == 0) return crear_nodo(OR, izq, der, NULL);
        if (strcmp(tok, "IMPLIES") == 0) return crear_nodo(IMPLIES, izq, der, NULL);
    }
    return izq;
}


Nodo* copiar_nodo(Nodo *nodo) {
    Nodo *nuevo = (Nodo*)malloc(sizeof(Nodo));
    nuevo->tipo = nodo->tipo;
    nuevo->nombre = nodo->nombre ? strdup(nodo->nombre) : NULL;
    nuevo->izq = nodo->izq ? copiar_nodo(nodo->izq) : NULL;
    nuevo->der = nodo->der ? copiar_nodo(nodo->der) : NULL;
    return nuevo;
}

Nodo* copiar_nodo(Nodo *nodo);

Nodo* negacion(Nodo *hijo) {
    Nodo *nuevo = (Nodo*)malloc(sizeof(Nodo));
    nuevo->tipo = NEG;
    nuevo->nombre = NULL;
    nuevo->izq = hijo;
    nuevo->der = NULL;
    return nuevo;
}

Nodo* conjuncion(Nodo *a, Nodo *b) {
    Nodo *nuevo = (Nodo*)malloc(sizeof(Nodo));
    nuevo->tipo = AND;
    nuevo->nombre = NULL;
    nuevo->izq = a;
    nuevo->der = b;
    return nuevo;
}

/* Nodo* empujar_negaciones(Nodo *nodo) {
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
            Nodo *sub = nodo->izq;
            if (sub->tipo == VAR) {
                return copiar_nodo(nodo);  // ¬p
            } else if (sub->tipo == NEG) {
                // ¬(¬φ) → φ
                return empujar_negaciones(sub->izq);
            } else if (sub->tipo == AND) {
                // ¬(φ ∧ ψ) → ¬φ ∨ ¬ψ
                return crear_nodo(OR,
                        empujar_negaciones(negacion(sub->izq)),
                        empujar_negaciones(negacion(sub->der)),
                        NULL);
            } else if (sub->tipo == OR) {
                // ¬(φ ∨ ψ) → ¬φ ∧ ¬ψ
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

Nodo* distribuir_o(Nodo *a, Nodo *b) {
    // Distribuir: (a ∨ (b1 ∧ b2)) => (a ∨ b1) ∧ (a ∨ b2)
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

Nodo* convertir_cnf(Nodo *nodo) {
    if (!nodo) return NULL;

    if (nodo->tipo == AND) {
        return crear_nodo(AND,
            convertir_cnf(nodo->izq),
            convertir_cnf(nodo->der),
            NULL);
    }

    if (nodo->tipo == OR) {
        Nodo *izq = convertir_cnf(nodo->izq);
        Nodo *der = convertir_cnf(nodo->der);
        return distribuir_o(izq, der);
    }

    return copiar_nodo(nodo); // VAR o NEG(VAR)
}
 */

 // Traducción
Nodo* traducir(Nodo *nodo) {
    if (!nodo) return NULL;

    switch (nodo->tipo) {
        case VAR:
            return copiar_nodo(nodo);

        case NEG:
            return negacion(traducir(nodo->izq));

        case AND:
            return conjuncion(traducir(nodo->izq), traducir(nodo->der));

        case OR: {
            // T(1 ∨ 2) = ¬(¬T(1) ∧ ¬T(2))
            Nodo *izq_t = traducir(nodo->izq);
            Nodo *der_t = traducir(nodo->der);
            return negacion(conjuncion(negacion(izq_t), negacion(der_t)));
        }

        case IMPLIES: {
            // T(1 → 2) = ¬(T(1) ∧ ¬T(2))
            Nodo *izq_t = traducir(nodo->izq);
            Nodo *der_t = traducir(nodo->der);
            return negacion(conjuncion(izq_t, negacion(der_t)));
        }

        default:
            return NULL;
    }
}

int eval(Nodo *n, char **vars, int *vals, int n_vars) {
    if (!n) return 0;

    switch (n->tipo) {
        case VAR:
            for (int i = 0; i < n_vars; ++i) {
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
            int a = eval(n->izq, vars, vals, n_vars);
            int b = eval(n->der, vars, vals, n_vars);
            return !a || b;
        }

        case TOP: return 1;
        case BOT: return 0;
    }
    return 0;
}

void recolectar_vars(Nodo *n, char **vars, int *n_vars) {
    int i;
    if (!n) return;
    if (n->tipo == VAR) {
        for (i = 0; i < *n_vars; ++i) {
            if (strcmp(vars[i], n->nombre) == 0) return; // ya está
        }
        vars[*n_vars] = n->nombre;
        (*n_vars)++;
    } else {
        recolectar_vars(n->izq, vars, n_vars);
        recolectar_vars(n->der, vars, n_vars);
    }
}

int es_satisfacible(Nodo *n) {
    char *vars[10];
    int vals[10]; // toma valores 1 o 0 si es verdadero o falso
    int n_vars = 0;
    int result, total, i, j;
    recolectar_vars(n, vars, &n_vars);

    total = 1 << n_vars; // 2^n_vars combinaciones

    for (i = 0; i < total; ++i) {
        for (j = 0; j < n_vars; ++j)
            vals[j] = (i >> j) & 1;

        result = eval(n, vars, vals, n_vars);
    }

    return result;
}



void imprimir_formula_original() {
    printf("Tokens leídos:\n");
    for (int i = 0; i < num_tokens; ++i) {
        printf("%s ", tokens[i]);
    }
    printf("\n");
}

void imprimir_nodo(Nodo *n) {
    if (!n) return;
    switch (n->tipo) {
        case VAR: printf("%s", n->nombre); break;
        case TOP: printf("\u22A4"); break;
        case BOT: printf("\u22A5"); break;
        case NEG:
            printf("¬");
            imprimir_nodo(n->izq);
            break;
        case AND:
            printf("("); imprimir_nodo(n->izq); printf(" ∧ "); imprimir_nodo(n->der); printf(")");
            break;
        case OR:
            printf("("); imprimir_nodo(n->izq); printf(" ∨ "); imprimir_nodo(n->der); printf(")");
            break;
        case IMPLIES:
            printf("("); imprimir_nodo(n->izq); printf(" → "); imprimir_nodo(n->der); printf(")");
            break;
    }
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
    Nodo *arbol = parse_formula();
    printf("Fórmula original: ");
    imprimir_nodo(arbol);
    printf("\n");

    Nodo *traducida = traducir(arbol);  // transforma OR e IMPLIES
    printf("Fórmula en Sat Lineal: ");
    imprimir_nodo(traducida);
    printf("\n");

    
    // Nodo *sin_neg = empujar_negaciones(traducida); // ¬ distribuidas
    // Nodo *cnf = convertir_cnf(sin_neg); // forma final CNF
    // printf("Fórmula en CNF: ");
    // imprimir_nodo(cnf);
    // printf("\n");

    if (es_satisfacible(traducida) == 1) {
        printf("SATISFACIBLE\n");
    } else {
        printf("NO-SATISFACIBLE\n");
    }    

    return 0;
}