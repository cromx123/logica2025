# Proyecto: Evaluador y Transformador de Fórmulas Lógicas en C
Este proyecto implementa un parser, transformador y evaluador de fórmulas lógicas booleanas en lenguaje C. Está orientado a la transformación de fórmulas a formas normales conjuntivas (CNF) y a la evaluación de su satisfacibilidad (SAT).

### Características
- Parseo de fórmulas lógicas con operadores:

- Conjunción (∧), disyunción (∨), negación (¬), implicación (→), etc.

- Traducción de fórmulas a una forma simplificada para SAT (forma lineal).

- Empuje de negaciones para normalizar expresiones.

- Conversión a forma normal conjuntiva (CNF).

- Evaluación de satisfacibilidad (SAT) simple.

- Uso de DAG con memoización para reutilizar nodos y optimizar memoria.

- Manejo adecuado de liberación de memoria para evitar errores de segmentación.

### Estructura
- test.lex  
- tarea1.lex
- run_all.sh
- run.sh
- lex.yy.c
- expresiones //carpeta de expresiones
- expresion.txt
- datos.txt
- crear_expresiones.exe
- crear_expresiones.c

------------------------------------------------------------------------------------------------------
### Cómo compilar
Se asume que tienes instalado gcc y, en caso de usar Flex/Bison, también estas herramientas.

```c
flex tarea1.lex
gcc -o tarea1.exe lex.yy.c -ll
./tarea1.exe < expresion.txt
```

###Cómo usar
Coloca la fórmula lógica en formato LaTeX en un archivo, por ejemplo:
```c
((p ∧ p) ∧ (¬p ∨ ¬p))
```
se veria asi en expresion.txt:
```
$(p \wedge q) \wedge (\neg p \vee \neg q)
```

### Salida esperada
```
Inicio de programa
Fórmula original: ((p ∧ p) ∧ (¬p ∨ ¬p))
Fórmula en Sat Lineal: ((p ∧ p) ∧ ¬(¬¬p ∧ ¬¬p))
Fórmula en CNF: ((p ∧ p) ∧ (¬p ∨ ¬p))
NO-SATISFACIBLE
```

------------------------------------------------------------------------------------------------------
### Notas
El proyecto implementa memoización manual para evitar duplicados en el árbol lógico.

Para evitar errores de memoria, se libera toda la memoria al final a través de la tabla de memoización.

Se recomienda revisar y extender la función de evaluación de SAT según necesidades.

------------------------------------------------------------------------------------------------------
### Autor
Cristobal Gallardo y Sebastian Caceres.
