#!/bin/bash

flex tarea1.lex
gcc -o tarea1.exe lex.yy.c -ll

n=${1:-3}

echo "===> Ejecutando expresion 1"
./tarea1.exe < expresion.txt

for ((i = 2; i <= n; i = i + 1)); do
    echo "===> Ejecutando expresion $i"
    ./tarea1.exe < expresion${i}.txt
done