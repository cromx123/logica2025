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
"\\vee"        { /*printf("OR ");*/  printf(" \\neg (\\neg %s \\)", datos) }
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
    return 0;
}