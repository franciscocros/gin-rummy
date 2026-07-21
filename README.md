# GinRummyLog

Implementación del juego de cartas **Gin Rummy** en **SWI-Prolog**, desarrollada utilizando programación lógica para modelar las reglas del juego, detectar melds y construir distintos modelos de jugadores automáticos.

El proyecto incluye un motor completo del juego, una interfaz interactiva por consola, pruebas unitarias y herramientas para evaluar y comparar el rendimiento de distintas estrategias.

---

## Características

- Implementación completa de las reglas principales de Gin Rummy.
- Detección automática de **sets** y **runs**.
- Cálculo del **deadwood** de una mano.
- Búsqueda de la mejor combinación posible de melds.
- Jugador humano y jugadores automáticos.
- Simulación de partidas entre estrategias.
- Pruebas unitarias utilizando **plunit**.

---

## Estructura del proyecto

```text
.
├── ginrummylog.pl      # Motor principal del juego
├── server.pl           # Interfaz interactiva por consola
├── test.pl             # Pruebas unitarias
├── benchmark.pl        # Comparación entre estrategias
└── eval_ginrummy.pl    # Evaluación estadística
```

---

## Requisitos

- SWI-Prolog

---

## Ejecución

Iniciar SWI-Prolog:

```bash
swipl
```

Cargar el servidor:

```prolog
?- [server].
?- main.
```

Al comenzar una partida se solicitará:

- Semilla para el generador aleatorio.
- Modo de ejecución.
- Estrategia para cada jugador.

Los modos disponibles son:

- **Normal:** permite jugar como humano contra una estrategia automática o enfrentar dos estrategias automáticas.
- **Debug:** permite enfrentar libremente cualquier estrategia y muestra información adicional sobre el estado interno del juego, los melds encontrados y el deadwood de cada mano.

---

## Representación de las cartas

Las cartas se representan mediante el término:

```prolog
c(Valor, Palo)
```

---

## Motor del juego

Toda la lógica del juego se encuentra implementada en **ginrummylog.pl**.

Entre sus principales responsabilidades se encuentran:

- Validación de melds.
- Detección de sets.
- Detección de runs.
- Cálculo del deadwood.
- Obtención de la mejor combinación de melds.
- Gestión de robos y descartes.
- Decisión de cuándo cortar la partida.
- Implementación de las distintas estrategias automáticas.

---

## Estrategias implementadas

### Humano

Permite que todas las decisiones sean tomadas manualmente desde la consola.

### Random

Realiza todas las acciones de manera completamente aleatoria, sin analizar el estado de la mano.

### Greedy

Evalúa el efecto inmediato de cada decisión buscando minimizar el deadwood actual de la mano.

### Pro

Utiliza información sobre las cartas ya jugadas para obtener la mejor combinación posible de melds para decidir qué carta robar, cuál descartar y cuándo cortar, intentando maximizar la calidad de la mano en cada turno.

---

## Pruebas

El proyecto incluye pruebas unitarias desarrolladas con **plunit**.

Para ejecutarlas:

```prolog
?- [test].
?- run_tests.
```

Las pruebas verifican, entre otros aspectos:

- Validación de sets.
- Validación de runs.
- Casos inválidos de melds.
- Cálculo correcto del deadwood.
- Obtención de melds.
- Selección óptima de melds.

---

## Benchmark

El archivo `benchmark.pl` permite enfrentar automáticamente distintas estrategias durante múltiples partidas para comparar su rendimiento.

Para ejecutar un benchmark:

```prolog
?- [benchmark].
?- correr_benchmark(50, pro, greedy).
```

Al finalizar se muestran estadísticas como:

- Cantidad de victorias por estrategia.
- Empates.
- Porcentaje de victorias.
- Resultados de cada partida.

---

## Evaluación estadística

El archivo `eval_ginrummy.pl` permite ejecutar simulaciones masivas utilizando diferentes semillas aleatorias.

Ejemplo:

```bash
swipl -q -s eval_ginrummy.pl -g "run(100),halt."
```

La evaluación calcula estadísticas como:

- Cantidad de victorias.
- Cantidad de empates.
- Promedio de turnos por partida.
- Diferencia promedio de deadwood entre jugadores.

También dispone de un modo de ejecución en vivo que muestra el resultado de cada partida mientras se desarrolla la simulación.

---

## Tecnologías utilizadas

- SWI-Prolog
- Programación lógica
- Biblioteca `lists`
- Biblioteca `random`
- **plunit** para pruebas unitarias

---

## Objetivo del proyecto

Este proyecto tiene como objetivo aplicar técnicas de programación lógica para modelar un juego de cartas completo, implementando algoritmos para la detección óptima de melds y diferentes estrategias de toma de decisiones. Además del motor del juego, incorpora herramientas de prueba, simulación y evaluación que permiten analizar y comparar el desempeño de los distintos jugadores automáticos.

---

## Autor

Juan Francisco Cros

Proyecto desarrollado con fines académicos para Ingeniería en Computación – UDELAR.
