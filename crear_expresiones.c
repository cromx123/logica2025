#include <stdio.h>
#include <stdlib.h>
#include <time.h>

const char *vars[] = {"p", "q", "r", "s", "t", "aa", "x1", "x2"};
const char *ops[] = {" \\wedge ", " \\vee ", " \\rightarrow "};

void Usage(char *mess) {
    printf("\nUsage: %s n\n", mess);
}

// Genera una fórmula aleatoria recursivamente
void generar_formula(FILE *f, int profundidad) {
    int tipo;
    tipo = rand() % 4;

    if (profundidad == 0 || tipo == 0) {
        // Variable o negación de variable
        if (rand() % 2 == 0) {
            fprintf(f, "%s", vars[rand() % 8]);
        } else {
            fprintf(f, "\\neg %s", vars[rand() % 8]);
        }
    } else {
        fprintf(f, "(");
        generar_formula(f, profundidad - 1);
        fprintf(f, "%s", ops[rand() % 3]);
        generar_formula(f, profundidad - 1);
        fprintf(f, ")");
    }
}

int main(int argc, char **argv) {
    int i, n;
    char nombre[32];
    if (argc == 2){
        n = atoi(argv[1]); // Cantidad de archivos
        srand(time(NULL));

        for (i = 0; i < n; i = i + 1) {
            snprintf(nombre, sizeof(nombre), "expresiones/formula_%d.txt", i + 1);

            FILE *f = fopen(nombre, "w");
            if (!f) {
                perror("No se pudo crear el archivo");
                return 1;
            }

            fprintf(f, "$");
            generar_formula(f, 2 + rand() % 4);  // Profundidad entre 2 y 3
            fprintf(f, "$\n");

            fclose(f);
            printf("Generado: %s\n", nombre);
        }
    }else{
        Usage(argv[0]);
    }
    return 0;
}
