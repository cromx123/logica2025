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

Nodo* empujar_negaciones(Nodo *nodo) {
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
            // T(φ1 ∨ φ2) = ¬(¬T(φ1) ∧ ¬T(φ2))
            Nodo *izq_t = traducir(nodo->izq);
            Nodo *der_t = traducir(nodo->der);
            return negacion(conjuncion(negacion(izq_t), negacion(der_t)));
        }

        case IMPLIES: {
            // T(φ1 → φ2) = ¬(T(φ1) ∧ ¬T(φ2))
            Nodo *izq_t = traducir(nodo->izq);
            Nodo *der_t = traducir(nodo->der);
            return negacion(conjuncion(izq_t, negacion(der_t)));
        }

        default:
            return NULL;
    }
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
    
    Nodo *sin_neg = empujar_negaciones(traducida); // ¬ distribuidas
    Nodo *cnf = convertir_cnf(sin_neg); // forma final CNF

    printf("Fórmula en CNF: ");
    imprimir_nodo(cnf);
    printf("\n");
    return 0;
}