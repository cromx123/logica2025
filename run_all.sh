#!/bin/bash

flex test.lex
gcc -o test.exe lex.yy.c -ll

n=25

for ((i = 1; i <= n; i = i + 1)); do
    echo "===> Ejecutando prueba $i"
    ./tarea1.exe < ./expresiones/formula_${i}.txt
    echo ""
    echo "=========================================="
done