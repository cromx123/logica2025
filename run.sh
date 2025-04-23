#!/bin/bash

flex tarea1.lex
gcc -o tarea1.exe lex.yy.c -ll
./tarea1.exe < expresion.txt