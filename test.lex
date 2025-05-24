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

        char **nuevo_espacio = calloc(nueva_capacidad, sizeof(char *));

        // Copiar los punteros existentes
        for (i = 0; i < num_tokens; i = i + 1) {
            nuevo_espacio[i] = tokens[i];
        }

        free(tokens); // Liberar memoria antigua
        tokens = nuevo_espacio;
        capacidad_tokens = nueva_capacidad;
    }
    int len = strlen(tok);
    tokens[num_tokens] = calloc(len + 1, sizeof(char));

    for (i = 0; i < len; i++) {
        tokens[num_tokens][i] = tok[i];
    }
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

char* clave_nodo(int tipo, struct Nodo* izq, struct Nodo* der, char* nombre) {
    char* clave = malloc(256);
    snprintf(clave, 256, "%c_%p_%p_%s", tipo, izq, der, nombre ? nombre : ""); 
    return clave;
}

struct NodoMemo {
    char* clave;
    struct Nodo *nodo;
};

struct NodoMemo memo[1000];
int memo_size = 0;

struct Nodo* buscar_en_memo(char* clave) {
    for (int i = 0; i < memo_size; i = i + 1) {
        if (strcmp(memo[i].clave, clave) == 0) return memo[i].nodo;
    }
    return NULL;
}

void guardar_en_memo(char* clave, struct Nodo* nodo) {
    memo[memo_size].clave = clave;
    memo[memo_size].nodo = nodo;
    memo_size = memo_size + 1;
}

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

struct Nodo* crear_nodo_dag(char tipo, struct Nodo* izq, struct Nodo* der, char* nombre) {
    char* clave = clave_nodo(tipo, izq, der, nombre);
    struct Nodo* existente = buscar_en_memo(clave);
    if (existente != NULL) {
        free(clave); // evitamos fugas de memoria
        return existente;
    }

    struct Nodo* nuevo = crear_nodo(tipo, izq, der, nombre);
    guardar_en_memo(clave, nuevo);
    return nuevo;
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
        return crear_nodo_dag(NEG, n, NULL, NULL);
    } else {
        return crear_nodo_dag(VAR, NULL, NULL, tok);
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
        if (strcmp(tok, "AND") == 0) return crear_nodo_dag(AND, izq, der, NULL);
        if (strcmp(tok, "OR") == 0) return crear_nodo_dag(OR, izq, der, NULL);
        if (strcmp(tok, "IMPLIES") == 0) return crear_nodo_dag(IMPLIES, izq, der, NULL);
    }
    return izq;
}

struct Nodo* copiar_nodo(struct Nodo *nodo);

struct Nodo* copiar_nodo(struct Nodo *nodo) {
    if (!nodo) return NULL;
    return crear_nodo_dag(nodo->tipo, nodo->izq, nodo->der, nodo->nombre);
}



struct Nodo* negacion(struct Nodo *hijo) {
    return crear_nodo_dag(NEG, hijo, NULL, NULL);
}

struct Nodo* conjuncion(struct Nodo *a, struct Nodo *b) {
    return crear_nodo_dag(AND, a, b, NULL);
}

struct Nodo* empujar_negaciones(struct Nodo *nodo) {
    if (!nodo) return NULL;

    switch (nodo->tipo) {
        case VAR:
            return copiar_nodo(nodo);

        case AND:
        case OR:
            return crear_nodo_dag(nodo->tipo,
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
                return crear_nodo_dag(OR,
                        empujar_negaciones(negacion(sub->izq)),
                        empujar_negaciones(negacion(sub->der)),
                        NULL);
            } else if (sub->tipo == OR) {
                return crear_nodo_dag(AND,
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
        return crear_nodo_dag(AND,
            distribuir_o(a->izq, b),
            distribuir_o(a->der, b),
            NULL);
    }
    if (b->tipo == AND) {
        return crear_nodo_dag(AND,
            distribuir_o(a, b->izq),
            distribuir_o(a, b->der),
            NULL);
    }
    return crear_nodo_dag(OR, a, b, NULL);
}

struct Nodo* convertir_cnf(struct Nodo *nodo) {
    if (!nodo) return NULL;

    if (nodo->tipo == AND) {
        return crear_nodo_dag(AND,
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
    char *vars[100];
    int vals[100]; // toma valores 1 o 0 si es verdadero o falso
    int n_vars = 0;
    int result, total, i, j;
    recolectar_vars(n, vars, &n_vars);

    total = 1 << n_vars; // 2^n combinaciones

    for (i = 0; i < total; i = i + 1) {
        for (j = 0; j < n_vars; j = j + 1){
            vals[j] = (i >> j) & 1;
        }
        result = eval(n, vars, vals, n_vars);
        if (result == 1) {
            return 1; // satisfacible
        }
    }

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

void free_tokens(){
    int i;
    for (i = 0; i < num_tokens; i = i + 1) {
        free(tokens[i]);
    }
    free(tokens);
}
void liberar_arbol(struct Nodo *n) {
    if (!n) return;
    liberar_arbol(n->izq);
    liberar_arbol(n->der);
    printf("Liberando nodo: %p, nombre: %s\n", (void*)n, n->nombre ? n->nombre : "(null)");
    if (n->nombre) free(n->nombre);
    free(n);
}
void liberar_memo() {
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
[a-z][0-9]*    { agregar_token(yytext);}
"\$\$"         { /* ignora $$ */ }
"$"            { /**/}
[ \t\r]        { /* ignora espacios */ }
[ \n]          { printf("\n");} 
.              { printf("UNKNOWN: %s\n", yytext); }
%%



int main(int argc, char **argv) {
    printf("Soy un Test\n");
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

    
    struct Nodo *sin_neg = empujar_negaciones(traducida);
    struct Nodo *cnf = convertir_cnf(sin_neg);
    printf("Fórmula en CNF: ");
    imprimir_nodo(cnf);
    printf("\n");

    if (es_satisfacible(cnf) == 1) {
        printf("SATISFACIBLE\n");
    } else {
        printf("NO-SATISFACIBLE\n");
    }    
    // Libera memoria asignada para los tokens
    // free_tokens();
    // liberar_arbol(cnf);
    liberar_memo();
    return 0;
}