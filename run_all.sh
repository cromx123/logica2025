#!/bin/bash

flex tarea1.lex
gcc -o tarea1.exe lex.yy.c -ll

flex test.lex
gcc -o test.exe lex.yy.c -ll

flex test2.lex
gcc -o test2.exe lex.yy.c -ll
# Ejecuta las pruebas para las expresiones de 1 a 25
n=${1:-3}

for ((i = 1; i <= n; i = i + 1)); do
    echo "===> Ejecutando prueba $i"
    echo "Tarea 1 - Prueba $i"
    ./tarea1.exe < ./expresiones/formula_${i}.txt
    echo "Test - Prueba $i"
    ./test.exe < ./expresiones/formula_${i}.txt
    echo "Test2 - Prueba $i"
    ./test2.exe < ./expresiones/formula_${i}.txt
    echo "=========================================="
done