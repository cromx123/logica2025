Evaluador y Transformador de Fórmulas Lógicas en C
------------------------------------------------------------------------------------------------------
Compilación:

flex tarea1.lex
gcc -o tarea1.exe lex.yy.c -ll
./tarea1.exe < expresion.txt

Se incluyen expresion.txt expresion2.txt y expresion3.txt como datos de prueba.
Se incluye un run.sh que compila y ejecuta el programa con las 3 expresiones.
Compilación:

bash run.sh

Si se desea probar varios .txt con formulas distintas, procuparar seguir este patron:
expresion, expresion2, expresion3, ... expresionn

Para compilación n > 3

bash run.sh n
donde: n = {Cantidad de fórmulas a ejecutar}
------------------------------------------------------------------------------------------------------
Ejemplo de uso:
La fórmula lógica en formato LaTeX en un archivo .txt, por ejemplo:

((p ∧ p) ∧ (¬p ∨ ¬p))

se veria asi en expresion.txt:

$(p \wedge q) \wedge (\neg p \vee \neg q)


### Salida esperadas

SATISFACIBLE, NO-SATISFACIBLE, NO-SOLUTION

------------------------------------------------------------------------------------------------------
### Autor
Cristobal Gallardo y Sebastian Caceres.
