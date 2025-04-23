%{
#include <stdio.h>
%}

%%
"\\neg"        { printf("NEG\n"); }
"\\wedge"      { printf("AND\n"); }
"\\vee"        { printf("OR\n"); }
"\\rightarrow" { printf("IMPLIES\n"); }
"("            { printf("LPAREN\n"); }
")"            { printf("RPAREN\n"); }
[a-z]          { printf("VAR: %s\n", yytext); }
"\$\$"       { /* ignora los delimitadores $$ */ }
[ \t\n\r]      { /* ignora espacios */ }
.              { printf("UNKNOWN: %s\n", yytext); }
%%

int main() {
    yylex();
    return 0;
}

