#!/bin/bash

flex tarea1.lex
gcc -o tarea1.exe lex.yy.c -ll

n=10

for ((i=1; i<=n; i++)); do
    echo "===> Ejecutando prueba $i"
    ./tarea1.exe < ./expresiones/formula_${i}.txt
    echo ""
    echo "=========================================="
done