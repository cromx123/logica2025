#!/bin/bash

flex tarea1.lex
gcc -o tarea1.exe lex.yy.c -ll
# Ejecuta las pruebas para las expresiones de 1 a 25
n=${1:-3}

for ((i = 1; i <= n; i = i + 1)); do
    echo "===> Ejecutando expresion $i"
    ./tarea1.exe < ./expresiones/formula_${i}.txt
done