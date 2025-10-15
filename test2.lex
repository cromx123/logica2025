/***************************************************************************************
 * 
 * tarea1.lex: Implementacion Algoritmo SAT lineal
 *
 * Programmer: Juan Moreno Herrera. Karla Ramos
 *
 * Santiago de Chile, 26\05\2025
 *
 **************************************************************************************/
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum { T_END=0, T_DOLLAR, T_LPAR, T_RPAR, T_NEG, T_AND, T_OR, T_IMPL, T_VAR, T_TOP, T_BOT };//Definición de tokens 

typedef enum { NODE_VAR, NODE_TOP, NODE_BOT, NODE_NEG, NODE_AND, NODE_OR, NODE_IMPL } NodeType;

typedef struct {
    int type;     // Tipo de token
    char *lexeme; // Solo para variables
} Token;

typedef struct Node {
    NodeType type;
    char *varname;
    struct Node *left, *right;
} Node;

typedef struct {
    char **antecedente; int n_ante;
    char *consecuente;
    int negado;
} Clausula;



int precedence(int type);
int isRightAssociative(int type);
void recolectar(struct Node *m,char ***lits_ptr, int *n_lits_ptr, int *cap_lits_ptr,int **negs_ptr, int *n_negs_ptr, int *cap_negs_ptr);//prototipo de recolectar
Token **tokens = NULL;// Array dinamico de tokens 
int ntokens = 0, cap_tokens = 0;
Clausula **clausulas = NULL;// Array dinamico de clausulas
int n_claus = 0, cap_claus = 0;


// Shunting Yard: infijo a postfijo
Token **infixToPostfix(Token **in, int nin, int *npostfix) {
    int cap_stack = 8, top = -1;
    Token **stack = calloc(cap_stack, sizeof(Token*));
    int cap_out;
    if (nin) cap_out = nin * 2; else cap_out = 8;
    int outn = 0;
    Token **out = calloc(cap_out, sizeof(Token*));
    int i, j;

    for (i = 0; i < nin; i = i + 1) {
        int t = in[i]->type;
        if (t == T_VAR || t == T_TOP || t == T_BOT) {
            if (outn == cap_out) {
                int newcap = cap_out * 2;
                Token **nuevo = calloc(newcap, sizeof(Token*));
                for (j = 0; j < outn; j = j + 1) nuevo[j] = out[j];
                free(out); out = nuevo; cap_out = newcap;
            }
            out[outn] = in[i];
            outn = outn + 1;
        } else if (t == T_NEG || t == T_AND || t == T_OR || t == T_IMPL) {
            while (top >= 0) {
                int ot = stack[top]->type;
                int p1 = precedence(t), p2 = precedence(ot);
                if ((isRightAssociative(t) && p1 < p2) ||
                    (!isRightAssociative(t) && p1 <= p2)) {
                    if (outn == cap_out) {
                        int newcap = cap_out * 2;
                        Token **nuevo = calloc(newcap, sizeof(Token*));
                        for (j = 0; j < outn; j = j + 1) nuevo[j] = out[j];
                        free(out); out = nuevo; cap_out = newcap;
                    }
                    out[outn] = stack[top];
                    outn = outn + 1;
                    top = top - 1;
                } else break;
            }
            if ((top + 1) == cap_stack) {
                int newcap = cap_stack * 2;
                Token **nuevo = calloc(newcap, sizeof(Token*));
                for (j = 0; j <= top; j = j + 1) nuevo[j] = stack[j];
                free(stack); stack = nuevo; cap_stack = newcap;
            }
            top = top + 1;
            stack[top] = in[i];
        } else if (t == T_LPAR) {
            if ((top + 1) == cap_stack) {
                int newcap = cap_stack * 2;
                Token **nuevo = calloc(newcap, sizeof(Token*));
                for (j = 0; j <= top; j = j + 1) nuevo[j] = stack[j];
                free(stack); stack = nuevo; cap_stack = newcap;
            }
            top = top + 1;
            stack[top] = in[i];
        } else if (t == T_RPAR) {
            while (top >= 0 && stack[top]->type != T_LPAR) {
                if (outn == cap_out) {
                    int newcap = cap_out * 2;
                    Token **nuevo = calloc(newcap, sizeof(Token*));
                    for (j = 0; j < outn; j = j + 1) nuevo[j] = out[j];
                    free(out); out = nuevo; cap_out = newcap;
                }
                out[outn] = stack[top];
                outn = outn + 1;
                top = top - 1;
            }
            if (top >= 0 && stack[top]->type == T_LPAR) top = top - 1;
            else { printf("NO-SOLUTION\n"); exit(0); }
        }
    }
    while (top >= 0) {
        if (stack[top]->type == T_LPAR || stack[top]->type == T_RPAR) {
            printf("NO-SOLUTION\n"); exit(0);
        }
        if (outn == cap_out) {
            int newcap = cap_out * 2;
            Token **nuevo = calloc(newcap, sizeof(Token*));
            for (j = 0; j < outn; j = j + 1) nuevo[j] = out[j];
            free(out); out = nuevo; cap_out = newcap;
        }
        out[outn] = stack[top];
        outn = outn + 1;
        top = top - 1;
    }
    free(stack);
    *npostfix = outn;
    return out;
}

//AST desde postfijo 
Node* makeNode(NodeType t, Node *l, Node *r, const char *v) {
    Node* n = calloc(1, sizeof(Node));
    n->type = t;
    if (v) {
        n->varname = calloc(strlen(v)+1, 1);
        strcpy(n->varname, v);
    }
    n->left = l;
    n->right = r;
    return n;
}

Node* buildASTfromPostfix(Token **postfix, int npostfix) {
    int cap_stack = 8, top = -1;
    Node **stack = calloc(cap_stack, sizeof(Node*));
    int i, j;
    for (i = 0; i < npostfix; i = i + 1) {
        int t = postfix[i]->type;
        if ((top + 1) == cap_stack) {
            int newcap = cap_stack * 2;
            Node **nuevo = calloc(newcap, sizeof(Node*));
            for (j = 0; j <= top; j = j + 1) nuevo[j] = stack[j];
            free(stack); stack = nuevo; cap_stack = newcap;
        }
        if (t == T_VAR) {
            stack[top + 1] = makeNode(NODE_VAR, NULL, NULL, postfix[i]->lexeme);
            top = top + 1;
        } else if (t == T_TOP) {
            stack[top + 1] = makeNode(NODE_TOP, NULL, NULL, NULL);
            top = top + 1;
        } else if (t == T_BOT) {
            stack[top + 1] = makeNode(NODE_BOT, NULL, NULL, NULL);
            top = top + 1;
        } else if (t == T_NEG) {
            if (top < 0) { printf("NO-SOLUTION\n"); exit(0); }
            Node *l = stack[top];
            top = top - 1;
            stack[top + 1] = makeNode(NODE_NEG, l, NULL, NULL);
            top = top + 1;
        } else if (t == T_AND || t == T_OR || t == T_IMPL) {
            if (top < 1) { printf("NO-SOLUTION\n"); exit(0); }
            Node *r = stack[top];
            top = top - 1;
            Node *l = stack[top];
            top = top - 1;
            NodeType nt;
            if (t == T_AND) nt = NODE_AND;
            else if (t == T_OR) nt = NODE_OR;
            else nt = NODE_IMPL;
            stack[top + 1] = makeNode(nt, l, r, NULL);
            top = top + 1;
        } else {
            printf("NO-SOLUTION\n"); exit(0);
        }
    }
    if (top != 0) { printf("NO-SOLUTION\n"); exit(0); }
    Node *ast = stack[top];
    free(stack);
    return ast;
}


Node* elimImpl(Node *n) {
    if (!n) return NULL;
    if (n->type == NODE_IMPL) {
        Node *not_left = makeNode(NODE_NEG, elimImpl(n->left), NULL, NULL);
        Node *right = elimImpl(n->right);
        Node *or_node = makeNode(NODE_OR, not_left, right, NULL);
        return or_node;
    } else if (n->type == NODE_AND || n->type == NODE_OR) {
        n->left = elimImpl(n->left);
        n->right = elimImpl(n->right);
        return n;
    } else if (n->type == NODE_NEG) {
        n->left = elimImpl(n->left);
        return n;
    } else {
        return n;
    }
}

// NNF 
Node* nnf(Node *n) {
    if (!n) return NULL;
    if (n->type == NODE_NEG) {
        Node *h = n->left;
        if (!h) return n;
        if (h->type == NODE_NEG) {
            Node *nn = nnf(h->left);
            free(n);
            return nn;
        } else if (h->type == NODE_AND) {
            Node *nl = makeNode(NODE_NEG, h->left, NULL, NULL);
            Node *nr = makeNode(NODE_NEG, h->right, NULL, NULL);
            Node *o = makeNode(NODE_OR, nnf(nl), nnf(nr), NULL);
            free(n);
            return o;
        } else if (h->type == NODE_OR) {
            Node *nl = makeNode(NODE_NEG, h->left, NULL, NULL);
            Node *nr = makeNode(NODE_NEG, h->right, NULL, NULL);
            Node *a = makeNode(NODE_AND, nnf(nl), nnf(nr), NULL);
            free(n);
            return a;
        } else {
            n->left = nnf(h);
            return n;
        }
    } else if (n->type == NODE_AND || n->type == NODE_OR) {
        n->left = nnf(n->left);
        n->right = nnf(n->right);
        return n;
    } else {
        return n;
    }
}

// CNF 
Node* cnf(Node *n) {
    if (!n) return NULL;
    if (n->type == NODE_OR) {
        Node *A = cnf(n->left);
        Node *B = cnf(n->right);
        if (A->type == NODE_AND) {
            Node *o1 = makeNode(NODE_OR, A->left, B, NULL);
            Node *o2 = makeNode(NODE_OR, A->right, B, NULL);
            Node *a = makeNode(NODE_AND, cnf(o1), cnf(o2), NULL);
            free(n);
            return a;
        } else if (B->type == NODE_AND) {
            Node *o1 = makeNode(NODE_OR, A, B->left, NULL);
            Node *o2 = makeNode(NODE_OR, A, B->right, NULL);
            Node *a = makeNode(NODE_AND, cnf(o1), cnf(o2), NULL);
            free(n);
            return a;
        } else {
            n->left = A;
            n->right = B;
            return n;
        }
    } else if (n->type == NODE_AND) {
        n->left = cnf(n->left);
        n->right = cnf(n->right);
        return n;
    } else if (n->type == NODE_NEG) {
        n->left = cnf(n->left);
        return n;
    } else {
        return n;
    }
}

/*
 * Usage
 */

void Usage(char *progname) {
    printf("\nUso: %s < expresion.txt\n", progname);
    exit(1);
}

/*
 * add token
 */

void add_token(int type, const char *lexeme) {
    if (ntokens == cap_tokens) {
        int newcap;
        int i;
        if (cap_tokens) {
            newcap = cap_tokens * 2;
        } else {
            newcap = 8;
        }
        Token **nuevo = calloc(newcap, sizeof(Token*));
        for (i = 0; i < ntokens; i = i + 1) nuevo[i] = tokens[i];
        free(tokens); tokens = nuevo; cap_tokens = newcap;
    }
    Token *t = calloc(1, sizeof(Token));
    t->type = type;
    if (lexeme) {
        t->lexeme = calloc(strlen(lexeme)+1, 1);
        strcpy(t->lexeme, lexeme);
    }
    tokens[ntokens] = t;
    ntokens = ntokens + 1;
}

/*
 * precedence
 */

int precedence(int type) {
    switch (type) {
        case T_NEG: return 4;
        case T_AND: return 3;
        case T_OR:  return 2;
        case T_IMPL:return 1;
        default:    return 0;
    }
}

/*
 * is Right Associative
 */

int isRightAssociative(int type) {
    return (type == T_NEG || type == T_IMPL);
}

/*
 * free AST
 */

void freeAST(Node *n) {
    if (!n) return;
    freeAST(n->left);
    freeAST(n->right);
    if (n->varname) free(n->varname);
    free(n);
}

/*
 * free Tokens
 */

void freeTokens() {
    int i;
    for (i = 0; i < ntokens; i = i + 1) {
        if (tokens[i]->lexeme) free(tokens[i]->lexeme);
        free(tokens[i]);
    }
    free(tokens);
}

/*
 * free Clausulas
 */

void freeClausulas() {
    int i, j;
    for (i = 0; i < n_claus; i = i + 1) {
        Clausula *c = clausulas[i];
        if (c->antecedente) {
            for (j = 0; j < c->n_ante; j = j + 1)
                free(c->antecedente[j]);
            free(c->antecedente);
        }
        if (c->consecuente) free(c->consecuente);
        free(c);
    }
    free(clausulas);
}

/*
 * agregar Clausula
 */

void agregarClausula(char **ante, int n_ante, const char *cons, int negado) {
    int i;
    if (n_claus == cap_claus) {
        int newCap;
        if (cap_claus) {
            newCap = cap_claus * 2;
        } else {
            newCap = 8;
        }
        Clausula **nuevo = calloc(newCap, sizeof(Clausula*));
        for (i = 0; i < n_claus; i = i + 1) nuevo[i] = clausulas[i];
        free(clausulas); clausulas = nuevo; cap_claus = newCap;
    }
    Clausula *c = calloc(1, sizeof(Clausula));
    if (n_ante > 0) {
        c->antecedente = calloc(n_ante, sizeof(char*));
        for (i = 0; i < n_ante; i = i + 1) {
            c->antecedente[i] = calloc(strlen(ante[i])+1, 1);
            strcpy(c->antecedente[i], ante[i]);
        }
    } else {
        c->antecedente = NULL;
    }
    c->n_ante = n_ante;
    c->consecuente = calloc(strlen(cons)+1, 1);
    strcpy(c->consecuente, cons);
    c->negado = negado;
    clausulas[n_claus] = c;
    n_claus = n_claus + 1;
}

/*
 * recolectar
 */
 
void recolectar(Node *m,
                char ***lits_ptr, int *n_lits_ptr, int *cap_lits_ptr,
                int **negs_ptr, int *n_negs_ptr, int *cap_negs_ptr) {
    if (!m) return;
    if (m->type == NODE_OR) {
        recolectar(m->left, lits_ptr, n_lits_ptr, cap_lits_ptr,
                   negs_ptr, n_negs_ptr, cap_negs_ptr);
        recolectar(m->right, lits_ptr, n_lits_ptr, cap_lits_ptr,
                   negs_ptr, n_negs_ptr, cap_negs_ptr);
    } else if (m->type == NODE_VAR) {
        if (*n_lits_ptr == *cap_lits_ptr) {
            int newcap = (*cap_lits_ptr) ? (*cap_lits_ptr)*2 : 4;
            char **nuevo = calloc(newcap, sizeof(char*));
            int k;
            for (k = 0; k < *n_lits_ptr; k = k + 1) nuevo[k] = (*lits_ptr)[k];
            free(*lits_ptr); *lits_ptr = nuevo; *cap_lits_ptr = newcap;
        }
        (*lits_ptr)[*n_lits_ptr] = calloc(strlen(m->varname)+1, 1);
        strcpy((*lits_ptr)[*n_lits_ptr], m->varname);
        *n_lits_ptr = *n_lits_ptr + 1;
        if (*n_negs_ptr == *cap_negs_ptr) {
            int newcap = (*cap_negs_ptr) ? (*cap_negs_ptr)*2 : 4;
            int *nuevo = calloc(newcap, sizeof(int));
            int k;
            for (k = 0; k < *n_negs_ptr; k = k + 1) nuevo[k] = (*negs_ptr)[k];
            free(*negs_ptr); *negs_ptr = nuevo; *cap_negs_ptr = newcap;
        }
        (*negs_ptr)[*n_negs_ptr] = 0;
        *n_negs_ptr = *n_negs_ptr + 1;
    } else if (m->type == NODE_NEG && m->left && m->left->type == NODE_VAR) {
        if (*n_lits_ptr == *cap_lits_ptr) {
            int newcap = (*cap_lits_ptr) ? (*cap_lits_ptr)*2 : 4;
            char **nuevo = calloc(newcap, sizeof(char*));
            int k;
            for (k = 0; k < *n_lits_ptr; k = k + 1) nuevo[k] = (*lits_ptr)[k];
            free(*lits_ptr); *lits_ptr = nuevo; *cap_lits_ptr = newcap;
        }
        (*lits_ptr)[*n_lits_ptr] = calloc(strlen(m->left->varname)+1, 1);
        strcpy((*lits_ptr)[*n_lits_ptr], m->left->varname);
        *n_lits_ptr = *n_lits_ptr + 1;
        if (*n_negs_ptr == *cap_negs_ptr) {
            int newcap = (*cap_negs_ptr) ? (*cap_negs_ptr)*2 : 4;
            int *nuevo = calloc(newcap, sizeof(int));
            int k;
            for (k = 0; k < *n_negs_ptr; k = k + 1) nuevo[k] = (*negs_ptr)[k];
            free(*negs_ptr); *negs_ptr = nuevo; *cap_negs_ptr = newcap;
        }
        (*negs_ptr)[*n_negs_ptr] = 1;
        *n_negs_ptr = *n_negs_ptr + 1;
    }
}

/*
 * ast2 lineal
 */
 
void ast2lineal(Node *n) {
    if (!n) return;
    if (n->type == NODE_AND) {
        ast2lineal(n->left); ast2lineal(n->right);
    } else if (n->type == NODE_OR) {
        char **lits = NULL;
        int n_lits = 0, cap_lits = 0;
        int *negs = NULL;
        int n_negs = 0, cap_negs = 0;
        int i;
        // Llama a recolectar con los punteros a los arreglos y sus contadores
        recolectar(n, &lits, &n_lits, &cap_lits, &negs, &n_negs, &cap_negs);
        if (n_lits == 1) {
            agregarClausula(NULL, 0, lits[0], negs[0]);
        } else if (n_lits > 1) {
            int idx_con = -1;
            for (i = 0; i < n_lits; i = i + 1) {
                if (negs[i] == 0) { idx_con = i; break; }
            }
            if (idx_con == -1) idx_con = 0;
            char **ante = calloc(n_lits-1, sizeof(char*));
            int n_ante = 0;
            for (i = 0; i < n_lits; i = i + 1) {
                if (i != idx_con) {
                    ante[n_ante] = lits[i];
                    n_ante = n_ante + 1;
                }
            }
            agregarClausula(ante, n_ante, lits[idx_con], negs[idx_con]);
            free(ante);
        }
        for (i = 0; i < n_lits; i = i + 1) free(lits[i]);
        free(lits);
        free(negs);
    } else if (n->type == NODE_VAR) {
        agregarClausula(NULL, 0, n->varname, 0);
    } else if (n->type == NODE_NEG && n->left && n->left->type == NODE_VAR) {
        agregarClausula(NULL, 0, n->left->varname, 1);
    }
}

/*
 * resolver SAT lineal
 */

int resolverSAT() {
    int cap_marc = n_claus * 2 + 8, cap_neg = n_claus * 2 + 8;
    char **marcadas = calloc(cap_marc, sizeof(char*));
    char **negados  = calloc(cap_neg, sizeof(char*));
    int n_marc = 0, n_neg = 0, cambio = 1, conflicto = 0;
    int i, j, k, t;
    for (i = 0; i < n_claus; i = i + 1) {
        if (clausulas[i]->n_ante == 0 && clausulas[i]->negado == 0) {
            if (n_marc == cap_marc) {
                int newCap = cap_marc * 2;
                char **nuevo = calloc(newCap, sizeof(char*));
                for (t = 0; t < n_marc; t = t + 1) nuevo[t] = marcadas[t];
                free(marcadas); marcadas = nuevo; cap_marc = newCap;
            }
            marcadas[n_marc] = clausulas[i]->consecuente;
            n_marc = n_marc + 1;
        }
        if (clausulas[i]->n_ante == 0 && clausulas[i]->negado == 1) {
            if (n_neg == cap_neg) {
                int newCap = cap_neg * 2;
                char **nuevo = calloc(newCap, sizeof(char*));
                for (t = 0; t < n_neg; t = t + 1) nuevo[t] = negados[t];
                free(negados); negados = nuevo; cap_neg = newCap;
            }
            negados[n_neg] = clausulas[i]->consecuente;
            n_neg = n_neg + 1;
        }
    }
    while (cambio && !conflicto) {
        cambio = 0;
        for (i = 0; i < n_claus; i = i + 1) {
            int todos = 1;
            for (j = 0; j < clausulas[i]->n_ante; j = j + 1) {
                int ok = 0;
                for (k = 0; k < n_marc; k = k + 1)
                    if (strcmp(clausulas[i]->antecedente[j], marcadas[k]) == 0) ok = 1;
                if (!ok) { todos = 0; break; }
            }
            if (todos && clausulas[i]->n_ante > 0) {
                if (clausulas[i]->negado == 0) {
                    int ya = 0;
                    for (k = 0; k < n_marc; k = k + 1)
                        if (strcmp(marcadas[k], clausulas[i]->consecuente) == 0) ya = 1;
                    if (!ya) {
                        if (n_marc == cap_marc) {
                            int newCap = cap_marc * 2;
                            char **nuevo = calloc(newCap, sizeof(char*));
                            for (t = 0; t < n_marc; t = t + 1) nuevo[t] = marcadas[t];
                            free(marcadas); marcadas = nuevo; cap_marc = newCap;
                        }
                        marcadas[n_marc] = clausulas[i]->consecuente;
                        n_marc = n_marc + 1;
                        cambio = 1;
                    }
                } else {
                    int ya = 0;
                    for (k = 0; k < n_neg; k = k + 1)
                        if (strcmp(negados[k], clausulas[i]->consecuente) == 0) ya = 1;
                    if (!ya) {
                        if (n_neg == cap_neg) {
                            int newCap = cap_neg * 2;
                            char **nuevo = calloc(newCap, sizeof(char*));
                            for (t = 0; t < n_neg; t = t + 1) nuevo[t] = negados[t];
                            free(negados); negados = nuevo; cap_neg = newCap;
                        }
                        negados[n_neg] = clausulas[i]->consecuente;
                        n_neg = n_neg + 1;
                        cambio = 1;
                    }
                }
            }
        }
        for (i = 0; i < n_marc && !conflicto; i = i + 1)
            for (j = 0; j < n_neg; j = j + 1)
                if (strcmp(marcadas[i], negados[j]) == 0) {
                    conflicto = 1;
                }
    }
    if (conflicto) {
        free(marcadas); free(negados);
        return -1;
    }
    for (i = 0; i < n_claus; i = i + 1) {
        if (clausulas[i]->n_ante > 0) {
            int ok = 1;
            for (j = 0; j < clausulas[i]->n_ante; j = j + 1) {
                int found = 0;
                for (k = 0; k < n_marc; k = k + 1)
                    if (strcmp(clausulas[i]->antecedente[j], marcadas[k]) == 0)
                        found = 1;
                if (!found) ok = 0;
            }
            int concl = 0;
            for (k = 0; k < n_marc; k = k + 1)
                if (strcmp(clausulas[i]->consecuente, marcadas[k]) == 0)
                    concl = 1;
            for (k = 0; k < n_neg; k = k + 1)
                if (strcmp(clausulas[i]->consecuente, negados[k]) == 0)
                    concl = 1;
            if (!ok && !concl) {
                free(marcadas); free(negados);
                return 0;
            }
        }
    }
    free(marcadas);
    free(negados);
    return 1;
}



%}

%option noyywrap

%%
"$"            { add_token(T_DOLLAR, NULL); }
"\\neg"         { add_token(T_NEG, NULL); }
"\\wedge"       { add_token(T_AND, NULL); }
"\\vee"         { add_token(T_OR, NULL); }
"\\rightarrow"  { add_token(T_IMPL, NULL); }
"\\top"         { add_token(T_TOP, NULL); }
"\\bot"         { add_token(T_BOT, NULL); }
"("             { add_token(T_LPAR, NULL); }
")"             { add_token(T_RPAR, NULL); }
[a-zA-Z][a-zA-Z0-9_]* {
    add_token(T_VAR, yytext);
}
[ \t\r\n]       ; // ignora espacios
.               { printf("NO-SOLUTION\n"); exit(0); }

%%


/*
 *
 * Main
 *
 */

int main(int argc, char **argv) {
    if (argc > 1) Usage(argv[0]);
    int c;
    int i;
    c = getchar();
    if (c == EOF) Usage(argv[0]);
    ungetc(c, stdin); // Devuelve el caracter al stream para el lexer
    yylex(); // Tokeniza toda la entrada y llena el array 'tokens', 'ntokens'
    // Si el primer y último token no son T_DOLLAR, error
    if (ntokens < 2 || tokens[0]->type != T_DOLLAR || tokens[ntokens-1]->type != T_DOLLAR) {
        printf("NO-SOLUTION\n"); exit(0);
    }
    // Elimina los tokens de dólar para procesar solo la fórmula
    int nin = ntokens - 2;
    Token **tokens_in = calloc(nin, sizeof(Token*));
    for (i = 0; i < nin; i = i + 1) tokens_in[i] = tokens[i+1];
    int npostfix = 0;
    Token **postfix = infixToPostfix(tokens_in, nin, &npostfix);
    Node *ast = buildASTfromPostfix(postfix, npostfix);
    ast = elimImpl(ast);
    ast = nnf(ast);
    ast = cnf(ast);
    // Traducción a SAT lineal
    ast2lineal(ast);
    int res = resolverSAT();
    if (res == 1)      printf("SATISFACIBLE\n");
    else if (res == -1) printf("NO-SATISFACIBLE\n");
    else                printf("NO-SOLUTION\n");

    free(tokens_in);
    free(postfix);
    freeAST(ast);
    freeTokens();
    freeClausulas();
    return 0;
}

