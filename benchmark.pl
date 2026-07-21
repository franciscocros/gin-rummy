:- [ginrummylog].
:- use_module(library(lists), [nth1/3, select/3]).

%% --- Mazo (baraja) ----------
palo(c). palo(d). palo(t). palo(p).

valor_carta_s(2). valor_carta_s(3). valor_carta_s(4). valor_carta_s(5).
valor_carta_s(6). valor_carta_s(7). valor_carta_s(8). valor_carta_s(9).
valor_carta_s(10). valor_carta_s(j). valor_carta_s(q). valor_carta_s(k). valor_carta_s(a).

carta_s(c(V,P)) :- valor_carta_s(V), palo(P).

get_mazo_random_s(Mazo) :-
    findall(c(V,P), carta_s(c(V,P)), Aux),
    random_permutation(Aux, Mazo).

repartir_s(Mazo, Mano1, Mano2, PilaDisc, MazoResto) :-
    length(Toma1, 10), length(Toma2, 10),
    append(Toma1, Rest1, Mazo),
    append(Toma2, Rest2, Rest1),
    Mano1 = Toma1, Mano2 = Toma2,
    Rest2 = [C|MazoResto],
    PilaDisc = [C].

% =============================================================================
% SIMULACION DE UNA PARTIDA
% simular_partida(+Seed, +E1, +E2, -Ganador, -DW1, -DW2, -Turnos)
% =============================================================================
simular_partida(Seed, E1, E2, Ganador, DW1, DW2, Turnos) :-
    set_random(seed(Seed)),
    get_mazo_random_s(Mazo),
    repartir_s(Mazo, M1, M2, Pila, Deck),
    simular_loop(M1, M2, Deck, Pila, 1, E1, E2, 0, Ganador, DW1, DW2, Turnos).

simular_loop(M1, M2, [], _Pila, _Turno, _E1, _E2, T, ninguno, DW1, DW2, T) :-
    !,
    best_melds(M1, _, _, DW1),
    best_melds(M2, _, _, DW2).

simular_loop(M1, M2, Deck, Pila, Turno, E1, E2, TAcc, Ganador, DW1, DW2, Turnos) :-
    % Seleccionar estrategia y mano del jugador en turno
    ( Turno =:= 1 -> E = E1, Mano = M1 ; E = E2, Mano = M2 ),

    % Robar
    ( Pila = [Top|Vs] -> true ; Top = none, Vs = [] ),
    ( Top \= none
    -> robar(Mano, Top, Vs, E, Lugar)
    ;  Lugar = mazo
    ),
    aplicar_robo_s(Lugar, Mano, Top, Deck, Pila, Mano11, Deck2, Pila2),

    % Descartar
    ( Pila2 = [_|VsDesc] -> true ; VsDesc = [] ),
    descartar(Mano11, VsDesc, E, Mano10, CartaDesc),
    pila_tras_descartar_s(CartaDesc, Pila2, NuevaPila),

    % Actualizar mano del jugador
    ( Turno =:= 1 -> M1b = Mano10, M2b = M2 ; M1b = M1, M2b = Mano10 ),

    % Cerrar
    ( NuevaPila = [_|VsCerrar] -> true ; VsCerrar = [] ),
    cerrar(Mano10, VsCerrar, E, Decision),

    TAcc1 is TAcc + 1,

    ( Decision = cortar
    ->  best_melds(M1b, _, _, DW1),
        best_melds(M2b, _, _, DW2),
        Turnos = TAcc1,
        ( DW1 < DW2 -> Ganador = jugador1
        ; DW2 < DW1 -> Ganador = jugador2
        ; Ganador = empate
        )
    ;   Siguiente is (3 - Turno),  % alterna entre 1 y 2
        simular_loop(M1b, M2b, Deck2, NuevaPila, Siguiente, E1, E2,
                     TAcc1, Ganador, DW1, DW2, Turnos)
    ).

aplicar_robo_s(mazo, Mano, _, [R|Resto], Pila, [R|Mano], Resto, Pila) :- !.
aplicar_robo_s(descarte, Mano, C, Deck, [C|PilaRest], [C|Mano], Deck, PilaRest).

pila_tras_descartar_s(Carta, Pila, [Carta|Pila]).

% =============================================================================
% CORRER N PARTIDAS Y MOSTRAR TABLA
% correr_benchmark(+N, +E1, +E2)
% Ejemplo: correr_benchmark(25, pro, greedy).
% =============================================================================
correr_benchmark(N, E1, E2) :-
    format('~n=== Benchmark: ~w vs ~w (~w partidas) ===~n', [E1, E2, N]),
    format('~w~n', ['Seed | Turnos | DW_J1 | DW_J2 | Ganador']),
    format('~w~n', ['-----|--------|-------|-------|--------']),
    N2 is 5000+N,
    numlist(5000, N2, Seeds),
    maplist(correr_una(E1, E2), Seeds, Resultados),
    contar_ganadores(Resultados, W1, W2, Emp),
    format('~n--- Totales ---~n'),
    format('~w wins: ~w~n', [E1, W1]),
    format('~w wins: ~w~n', [E2, W2]),
    format('Empates:  ~w~n', [Emp]),
    Total is W1 + W2 + Emp,
    ( Total > 0
    -> Pct is round(W1 * 100 / Total),
       format('Win rate ~w: ~w%~n', [E1, Pct])
    ; true ).

correr_una(E1, E2, Seed, res(Ganador, DW1, DW2, Turnos)) :-
    simular_partida(Seed, E1, E2, Ganador, DW1, DW2, Turnos),
    format('~w | ~w | ~w | ~w | ~w~n', [Seed, Turnos, DW1, DW2, Ganador]).

contar_ganadores([], 0, 0, 0).
contar_ganadores([res(G,_,_,_)|T], W1, W2, Emp) :-
    contar_ganadores(T, W1a, W2a, Empa),
    ( G = jugador1 -> W1 is W1a+1, W2=W2a,    Emp=Empa
    ; G = jugador2 -> W1 = W1a,    W2 is W2a+1, Emp=Empa
    ;                 W1 = W1a,    W2 = W2a,    Emp is Empa+1 ).

% =============================================================================
% PUNTO DE ENTRADA RAPIDO
% main. → corre 25 partidas pro vs greedy
% =============================================================================
main :-
    correr_benchmark(25, pro, greedy).
