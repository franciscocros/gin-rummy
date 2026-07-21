:- [ginrummylog].
:- use_module(library(lists), [nth1/3, select/3]).

%% --- Mazo (baraja) ----------
palo(c).
palo(d).
palo(t).
palo(p).

valor_carta(2).
valor_carta(3).
valor_carta(4).
valor_carta(5).
valor_carta(6).
valor_carta(7).
valor_carta(8).
valor_carta(9).
valor_carta(10).
valor_carta(j).
valor_carta(q).
valor_carta(k).
valor_carta(a).

carta(c(V, P)) :-
    valor_carta(V),
    palo(P).

get_mazo_random(Mazo) :-
    findall(c(V, P), carta(c(V, P)), Aux),
    random_permutation(Aux, Mazo).

%% Punto de entrada
main :-
    writeln('=== GinRummyLog (terminal) ==='),
    obtener_semilla(Seed),
    preparar_rng(Seed),
    get_mazo_random(Mazo0),
    obtener_modo(Modo),
    obtener_estrategias(Modo, E1, E2),
    repartir(Mazo0, M1, M2, Pila0, MazoResto),
    estado_inicial_msg(Modo, M1, M2, MazoResto, Pila0),
    loop_juego(M1, M2, MazoResto, Pila0, 1, Modo, E1, E2).

preparar_rng(Seed) :-
    integer(Seed),
    !,
    set_random(seed(Seed)).
preparar_rng(Seed) :-
    atom(Seed),
    atom_number(Seed, N),
    integer(N),
    set_random(seed(N)).

obtener_semilla(Seed) :-
    writeln('Ingrese la semilla (entero):'),
    read(S0),
    (   integer(S0)
    ->  Seed = S0
    ;   atom(S0),
        atom_number(S0, N),
        integer(N)
    ->  Seed = N
    ;   writeln('Semilla invalida, intente de nuevo.'),
        obtener_semilla(Seed)
    ).

obtener_modo(Modo) :-
    writeln('Modo: normal. o debug.'),
    read(M),
    (   M = normal
    ->  Modo = normal
    ;   M = debug
    ->  Modo = debug
    ;   writeln('Modo invalido.'),
        obtener_modo(Modo)
    ).

estrategia_valida(E) :-
    member(E, [humano, greedy, random, pro]).

obtener_estrategias(debug, E1, E2) :-
    writeln('Estrategia jugador 1 [humano, greedy, random, pro]:'),
    read(A),
    (   estrategia_valida(A)
    ->  writeln('Estrategia jugador 2 [humano, greedy, random, pro]:'),
        read(B),
        (   estrategia_valida(B)
        ->  E1 = A, E2 = B
        ;   writeln('Estrategia invalida.'),
            obtener_estrategias(debug, E1, E2)
        )
    ;   writeln('Estrategia invalida.'),
        obtener_estrategias(debug, E1, E2)
    ).

obtener_estrategias(normal, E1, E2) :-
    writeln('Estrategia jugador 1 [humano, greedy, random, pro]:'),
    read(A),
    (   member(A, [humano, greedy, random, pro])
    ->  writeln('Estrategia jugador 2 [greedy, random, pro]:'),
        read(B),
        (   member(B, [greedy, random, pro])
        ->  E1 = A, E2 = B
        ;   writeln('En modo normal el jugador 2 solo puede ser greedy, random o pro.'),
            obtener_estrategias(normal, E1, E2)
        )
    ;   writeln('Estrategia invalida.'),
        obtener_estrategias(normal, E1, E2)
    ).

repartir(Mazo, Mano1, Mano2, PilaDisc, MazoResto) :-
    length(Toma1, 10),
    length(Toma2, 10),
    append(Toma1, Rest1, Mazo),
    append(Toma2, Rest2, Rest1),
    Mano1 = Toma1,
    Mano2 = Toma2,
    Rest2 = [C|MazoResto],
    PilaDisc = [C].

mano_jugador(1, M1, _, M1).
mano_jugador(2, _, M2, M2).

%% reemplazo_mano(+Turno, +M1, +M2, +NuevaManoTurno, -M1Out, -M2Out)
reemplazo_mano(1, _M1, M2, Nuevo, Nuevo, M2).
reemplazo_mano(2, M1, _M2, Nuevo, M1, Nuevo).

jugador_opuesto(1, 2).
jugador_opuesto(2, 1).

pila_tras_robar_mazo(Pila, Pila).

pila_tras_descartar(Carta, PilaAnt, [Carta|PilaAnt]).

%% Descomposicion greedy (best_melds/4 en ginrummylog.pl)
imprimir_analisis_mano(Mano) :-
    best_melds(Mano, Melds, Sobrante, Dw),
    imprimir_analisis_detalle(Melds, Sobrante, Dw).

imprimir_analisis_detalle(Melds, Sobrante, Dw) :-
    msort(Sobrante, SobOrd),
    format('  Melds: ~w~n', [Melds]),
    format('  Sobrantes (fuera de meld): ~w~n', [SobOrd]),
    format('  Deadwood: ~w~n', [Dw]).

estado_inicial_msg(debug, M1, M2, Deck, Pila) :-
    !,
    writeln('--- Estado inicial (debug) ---'),
    imprimir_debug(M1, M2, Deck, Pila, 1).
estado_inicial_msg(_, _, _, _, _).

hay_descarte_robable([_|_]).

loop_juego(M1, M2, [], _Pila, _Turno, Modo, _E1, _E2) :-
    !,
    writeln('Mazo vacio: termina la partida.'),
    fin_partida(M1, M2, ninguno, M1, M2, Modo).
loop_juego(M1, M2, Deck, Pila, Turno, Modo, E1, E2) :-
    antes_turno_msg(Modo, M1, M2, Deck, Pila, Turno),
    estrategia_en_turno(Turno, E1, E2, E),
    mano_jugador(Turno, M1, M2, Mano),
    pila_para_turno(Pila, Top, VsRobar),
    ejecutar_robar(Turno, Modo, E, Mano, Top, VsRobar, Deck, Pila, _Lugar,
                   NuevaMano11, NuevoDeck, PilaTrasRobo, RoboTxt),
    accion_jugador_msg(Modo, Turno, RoboTxt),
    vistas_para_descartar(PilaTrasRobo, VsDesc),
    ejecutar_descartar(Turno, Modo, E, NuevaMano11, VsDesc, Mano10,
                       CartaDesc, DescTxt),
    pila_tras_descartar(CartaDesc, PilaTrasRobo, NuevaPila),
    accion_jugador_msg(Modo, Turno, DescTxt),
    reemplazo_mano(Turno, M1, M2, Mano10, ManoActualizada1, ManoActualizada2),
    vistas_para_cerrar(NuevaPila, VsCerrar),
    ejecutar_cerrar(Turno, Modo, E, Mano10, VsCerrar, Decision, CerrarTxt),
    accion_jugador_msg(Modo, Turno, CerrarTxt),
    (   Decision = cortar
    ->  fin_partida(M1, M2, Turno, ManoActualizada1, ManoActualizada2, Modo)
    ;   jugador_opuesto(Turno, Sig),
        loop_juego(ManoActualizada1, ManoActualizada2, NuevoDeck, NuevaPila,
                   Sig, Modo, E1, E2)
    ).

pila_para_turno([Top|Vs], Top, Vs).
pila_para_turno([], none, []).

vistas_para_descartar(Pila, Vs) :-
    ( Pila = [_|Vs] -> true ; Pila = [], Vs = [] ).

vistas_para_cerrar(Pila, Vs) :-
    ( Pila = [_|Vs] -> true ; Pila = [], Vs = [] ).

estrategia_en_turno(1, E1, _, E1).
estrategia_en_turno(2, _, E2, E2).

antes_turno_msg(debug, M1, M2, Deck, Pila, Turno) :-
    !,
    format('~n=== Turno jugador ~w (debug) ===~n', [Turno]),
    imprimir_debug(M1, M2, Deck, Pila, Turno).
antes_turno_msg(normal, M1, _, Deck, Pila, 1) :-
    !,
    imprimir_vista_p1(M1, Deck, Pila).
antes_turno_msg(normal, _, _, _, _, 2).

imprimir_debug(M1, M2, Deck, Pila, Turno) :-
    msort(M1, S1),
    msort(M2, S2),
    writeln('Jugador 1:'),
    format('  Mano: ~w~n', [S1]),
    imprimir_analisis_mano(M1),
    writeln('Jugador 2:'),
    format('  Mano: ~w~n', [S2]),
    imprimir_analisis_mano(M2),
    length(Deck, N),
    format('Mazo (~w cartas, orden de robo): ~w~n', [N, Deck]),
    format('Pila descarte (tope primero): ~w~n', [Pila]),
    format('Jugador en turno: ~w~n', [Turno]).

imprimir_vista_p1(M1, Deck, Pila) :-
    msort(M1, S1),
    format('~n--- Tu mano (jugador 1) ---~n~w~n', [S1]),
    imprimir_analisis_mano(M1),
    length(Deck, N),
    format('Cartas restantes en el mazo: ~w~n', [N]),
    (   Pila = []
    ->  writeln('Descarte: base vacia (no hay tope).')
    ;   Pila = [T|Vs],
        format('Tope del descarte: ~w~nCartas ya vistas (no el tope): ~w~n', [T, Vs])
    ).

accion_jugador_msg(normal, 2, Msg) :-
    nonvar(Msg),
    Msg \== '',
    !,
    format('[Jugador 2] ~w~n', [Msg]).
accion_jugador_msg(normal, _, _) :- !.
accion_jugador_msg(debug, Turno, Msg) :-
    nonvar(Msg),
    Msg \== '',
    !,
    format('[Jugador ~w] ~w~n', [Turno, Msg]).
accion_jugador_msg(debug, _, _).

%% Robar
ejecutar_robar(Turno, Modo, humano, Mano, Top, Vs, Deck, Pila, Lugar,
                NuevaMano11, NuevoDeck, PilaTrasRobo, Msg) :-
    !,
    humano_ve_mano_robar(Turno, Modo, Mano, Deck, Pila),
    pedir_robar_humano(Top, Vs, Deck, Pila, Lugar, Msg),
    aplicar_robo(Lugar, Mano, Top, Deck, Pila, NuevaMano11, NuevoDeck, PilaTrasRobo).

ejecutar_robar(_, _, IA, Mano, none, _, Deck, Pila, Lugar,
                NuevaMano11, NuevoDeck, PilaTrasRobo, Msg) :-
    IA \== humano,
    !,
    Lugar = mazo,
    robar_msg(mazo, Msg),
    aplicar_robo(mazo, Mano, none, Deck, Pila, NuevaMano11, NuevoDeck, PilaTrasRobo).

ejecutar_robar(_, _, IA, Mano, T, Vs, Deck, Pila, Lugar,
                NuevaMano11, NuevoDeck, PilaTrasRobo, Msg) :-
    IA \== humano,
    compound(T),
    !,
    robar(Mano, T, Vs, IA, Lugar),
    robar_msg(Lugar, Msg),
    aplicar_robo(Lugar, Mano, T, Deck, Pila, NuevaMano11, NuevoDeck, PilaTrasRobo).

humano_ve_mano_robar(1, normal, _, _, _) :- !.
humano_ve_mano_robar(1, debug, _, _, _) :- !.
humano_ve_mano_robar(2, debug, Mano, _, _) :-
    msort(Mano, S),
    format('--- Tu mano (jugador 2) ---~n~w~n', [S]),
    imprimir_analisis_mano(Mano).

robar_msg(mazo, 'roba del mazo').
robar_msg(descarte, 'roba del descarte').

aplicar_robo(mazo, Mano, _, [R|Resto], Pila, [R|Mano], Resto, PilaOut) :-
    !,
    pila_tras_robar_mazo(Pila, PilaOut).
aplicar_robo(descarte, Mano, C, Deck, [C|PilaRest], [C|Mano], Deck, PilaRest).

pedir_robar_humano(_, _, [], [], _, _) :-
    !,
    fail.

pedir_robar_humano(_, _, [], [_|_], descarte, 'roba del descarte (humano) (mazo vacio)') :-
    !,
    writeln('Mazo vacio. Robas del descarte.').

pedir_robar_humano(none, [], Deck, [], mazo, 'roba del mazo (humano)') :-
    Deck \== [],
    !,
    writeln('Descarte vacio. Robas del mazo.').

pedir_robar_humano(Top, Vs, Deck, Pila, Lugar, Msg) :-
    Deck \== [],
    Pila \== [],
    !,
    writeln('Robar: escribi mazo. o descarte.'),
    read(O),
    (   O = mazo
    ->  Lugar = mazo,
        Msg = 'roba del mazo (humano)'
    ;   O = descarte
    ->  Lugar = descarte,
        Msg = 'roba del descarte (humano)'
    ;   writeln('Opcion invalida.'),
        pedir_robar_humano(Top, Vs, Deck, Pila, Lugar, Msg)
    ).

pedir_robar_humano(_Top, _Vs, Deck, [], mazo, 'roba del mazo (humano)') :-
    Deck \== [],
    !,
    writeln('Descarte vacio. Robas del mazo.').

%% Descartar
ejecutar_descartar(Turno, Modo, humano, Mano11, _VsDesc, NuevaMano, Carta, Msg) :-
    !,
    humano_ve_mano_descartar(Turno, Modo, Mano11),
    pedir_descarte_humano(Mano11, Carta, NuevaMano),
    format(atom(Msg), '(humano) descarta ~w', [Carta]).

ejecutar_descartar(_, _, E, Mano11, VsDesc, NuevaMano, Carta, Msg) :-
    E \== humano,
    !,
    descartar(Mano11, VsDesc, E, NuevaMano, Carta),
    format(atom(Msg), 'descarta ~w', [Carta]).

humano_ve_mano_descartar(1, normal, Mano) :-
    !,
    msort(Mano, S),
    writeln('Descomposicion greedy antes de descartar:'),
    imprimir_analisis_mano(Mano),
    writeln('Elegi carta a descartar (indice):'),
    enumerar_mano(S).
humano_ve_mano_descartar(1, debug, Mano) :-
    humano_ve_mano_descartar_cualquier(1, Mano).
humano_ve_mano_descartar(2, debug, Mano) :-
    humano_ve_mano_descartar_cualquier(2, Mano).

humano_ve_mano_descartar_cualquier(J, Mano) :-
    msort(Mano, S),
    format('Jugador ~w - descomposicion greedy:~n', [J]),
    imprimir_analisis_mano(Mano),
    format('Jugador ~w - cartas (indice):~n', [J]),
    enumerar_mano(S).

enumerar_mano(Mano) :-
    enumerar_mano_acc(1, Mano).

enumerar_mano_acc(_, []).
enumerar_mano_acc(N, [C|T]) :-
    format('  ~w: ~w~n', [N, C]),
    N1 is N + 1,
    enumerar_mano_acc(N1, T).

pedir_descarte_humano(Mano11, Carta, NuevaMano) :-
    msort(Mano11, Ord),
    writeln('Indice (1-11):'),
    read(I),
    (   integer(I),
        I >= 1,
        I =< 11,
        nth1(I, Ord, Carta)
    ->  select(Carta, Mano11, NuevaMano)
    ;   writeln('Indice invalido.'),
        pedir_descarte_humano(Mano11, Carta, NuevaMano)
    ).

%% Cerrar
ejecutar_cerrar(Turno, Modo, humano, Mano10, _Vs, Decision, Msg) :-
    !,
    best_melds(Mano10, _, _, Dw),
    humano_cerrar(Turno, Modo, Dw, Decision),
    (   Decision = cortar
    ->  format(atom(Msg), '(humano) cierra la ronda (deadwood ~w)', [Dw])
    ;   Msg = '(humano) continua'
    ).

ejecutar_cerrar(_, _, E, Mano10, Vs, Decision, Msg) :-
    E \== humano,
    cerrar(Mano10, Vs, E, Decision),
    (   Decision = cortar
    ->  Msg = 'cierra la ronda'
    ;   Msg = 'continua'
    ).

humano_cerrar(1, normal, Dw, Decision) :-
    !,
    (   Dw =< 10
    ->  format('Deadwood estimado: ~w~n', [Dw]),
        writeln('cortar. o continuar.'),
        read(R),
        (   R = cortar
        ->  Decision = cortar
        ;   R = continuar
        ->  Decision = continuar
        ;   writeln('Opcion invalida.'),
            humano_cerrar(1, normal, Dw, Decision)
        )
    ;   writeln('Deadwood > 10: solo podes continuar.'),
        Decision = continuar
    ).

humano_cerrar(_, debug, Dw, Decision) :-
    (   Dw =< 10
    ->  format('Deadwood estimado: ~w~n', [Dw]),
        writeln('cortar. o continuar.'),
        read(R),
        (   R = cortar
        ->  Decision = cortar
        ;   R = continuar
        ->  Decision = continuar
        ;   writeln('Opcion invalida.'),
            humano_cerrar(_, debug, Dw, Decision)
        )
    ;   writeln('Deadwood > 10: solo podes continuar.'),
        Decision = continuar
    ).

fin_partida(_M1vieja, _M2vieja, QuienCorta, F1, F2, Modo) :-
    best_melds(F1, M1m, S1, D1),
    best_melds(F2, M2m, S2, D2),
    writeln('=== Fin de la ronda ==='),
    (   QuienCorta = ninguno
    ->  writeln('Nadie corto (mazo vacio).')
    ;   format('Corto el jugador ~w.~n', [QuienCorta])
    ),
    (   Modo = debug
    ->  msort(F1, SF1),
        msort(F2, SF2),
        writeln('Jugador 1 (final):'),
        format('  Mano: ~w~n', [SF1]),
        imprimir_analisis_detalle(M1m, S1, D1),
        writeln('Jugador 2 (final):'),
        format('  Mano: ~w~n', [SF2]),
        imprimir_analisis_detalle(M2m, S2, D2)
    ;   msort(F1, SF1),
        msort(F2, SF2),
        format('Tu mano final: ~w~n', [SF1]),
        imprimir_analisis_detalle(M1m, S1, D1),
        writeln('Mano del rival (jugador 2):'),
        format('  Cartas: ~w~n', [SF2]),
        imprimir_analisis_detalle(M2m, S2, D2)
    ),
    resultado_msg(D1, D2).

resultado_msg(D1, D2) :-
    D1 < D2,
    !,
    writeln('Ganador: jugador 1 (menor deadwood).').
resultado_msg(D1, D2) :-
    D2 < D1,
    !,
    writeln('Ganador: jugador 2 (menor deadwood).').
resultado_msg(_, _) :-
    writeln('Empate en deadwood.').
