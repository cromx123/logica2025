#!/bin/bash

flex tarea1.lex
gcc -o tarea1.exe lex.yy.c -ll
./tarea1.exe < expresion.txt

flex test.lex
gcc -o test.exe lex.yy.c -ll
./test.exe < expresion.txt

flex test2.lex
gcc -o test2.exe lex.yy.c -ll
./test2.exe < expresion.txt