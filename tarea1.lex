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

struct Atomos {
    char *id;
    unsigned int marcado; /* 0 o 1 */
};

struct Clausula {
    struct Atomos **antecedente;
    struct Atomos *consecuencia;
};

struct Formulas {
    struct Clausula **clausulas;
    int num_clausulas;
};

struct Formulas **Resultado;
struct Formulas formula;

int traduccion(){
    printf("Soy la traduccion\n");
}
int alg_satisfacible(){
    return 1;
}
%}

%%
"\\neg"        { printf("NEG "); }
"\\wedge"      { printf("AND "); }
"\\vee"        { printf("OR ");}
"\\rightarrow" { printf("IMPLIES "); }
"\\top"        { printf("T ");}
"\\bot"        { printf("⊥ ");}
"("            { printf("( "); }
")"            { printf(") "); }
[a-z][0-9]*          { printf("%s ", yytext); }
"\$\$"         { /* ignora los delimitadores $$ */ }
[ \t\r]        { /* ignora espacios */ }
[ \n]          { printf("\n");} 
.              { printf("UNKNOWN: %s\n", yytext); }
%%



int main(int argc, char **argv) {

    printf("Inicio de programa\n");
    yylex();
    printf("\n");
    if (alg_satisfacible()==1){
        printf("SATISFACIBLE\n");
    }if(alg_satisfacible()==0){
        printf("NO-SATISFACIBLE\n");
    }else{
        printf("NO-SOLUTION\n");
    }
    
    return 0;
}