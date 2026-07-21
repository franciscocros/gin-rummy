%swipl -q -s eval_ginrummy.pl -g "run_live(100),halt."

:- ['ginrummylog.pl'].
:- use_module(library(random)).
:- use_module(library(lists)).

palo_eval(c). palo_eval(d). palo_eval(t). palo_eval(p).
valor_eval(a). valor_eval(2). valor_eval(3). valor_eval(4). valor_eval(5). valor_eval(6). valor_eval(7). valor_eval(8). valor_eval(9). valor_eval(10). valor_eval(j). valor_eval(q). valor_eval(k).

mazo_eval(Mazo) :-
    findall(c(V, P), (valor_eval(V), palo_eval(P)), Ordenado),
    random_permutation(Ordenado, Mazo).

repartir_eval(Mazo, M1, M2, Pila, Resto) :-
    length(M1, 10), append(M1, R1, Mazo),
    length(M2, 10), append(M2, R2, R1),
    R2 = [Top|Resto],
    Pila = [Top].

vistas_eval([_|Vs], Vs) :- !.
vistas_eval([], []).

estrategia_turno(1, E1, _, E1).
estrategia_turno(2, _, E2, E2).
mano_turno(1, M1, _, M1).
mano_turno(2, _, M2, M2).
reemplazar_mano(1, _M1, M2, NM, NM, M2).
reemplazar_mano(2, M1, _M2, NM, M1, NM).
siguiente(1, 2).
siguiente(2, 1).

jugar_seed(Seed, E1, E2, resultado(Seed, Iter, D1, D2, Ganador)) :-
    set_random(seed(Seed)),
    mazo_eval(Mazo),
    repartir_eval(Mazo, M1, M2, Pila, Resto),
    loop_eval(M1, M2, Resto, Pila, 1, E1, E2, 0, Iter, F1, F2),
    best_melds(F1, _, _, D1),
    best_melds(F2, _, _, D2),
    ganador(D1, D2, Ganador).

loop_eval(M1, M2, [], _Pila, _Turno, _E1, _E2, Iter, Iter, M1, M2) :- !.
loop_eval(M1, M2, Deck, Pila, Turno, E1, E2, Iter0, Iter, F1, F2) :-
    estrategia_turno(Turno, E1, E2, E),
    mano_turno(Turno, M1, M2, Mano),
    Pila = [Top|VistasRobar],
    once(robar(Mano, Top, VistasRobar, E, Lugar)),
    aplicar_robo_eval(Lugar, Mano, Top, Deck, Pila, Mano11, Deck1, Pila1),
    vistas_eval(Pila1, VistasDescartar),
    once(descartar(Mano11, VistasDescartar, E, Mano10, CartaDesc)),
    Pila2 = [CartaDesc|Pila1],
    vistas_eval(Pila2, VistasCerrar),
    once(cerrar(Mano10, VistasCerrar, E, Decision)),
    reemplazar_mano(Turno, M1, M2, Mano10, NM1, NM2),
    Iter1 is Iter0 + 1,
    ( Decision = cortar ->
        Iter = Iter1,
        F1 = NM1,
        F2 = NM2
    ; siguiente(Turno, Sig),
      loop_eval(NM1, NM2, Deck1, Pila2, Sig, E1, E2, Iter1, Iter, F1, F2)
    ).

aplicar_robo_eval(mazo, Mano, _, [Carta|Deck], Pila, [Carta|Mano], Deck, Pila) :- !.
aplicar_robo_eval(descarte, Mano, Carta, Deck, [Carta|PilaRest], [Carta|Mano], Deck, PilaRest).

ganador(D1, D2, jugador1) :- D1 < D2, !.
ganador(D1, D2, jugador2) :- D2 < D1, !.
ganador(_, _, empate).

contar([], 0, 0, 0, 0, 0).
contar([resultado(_, Iter, D1, D2, G)|Rs], GP, GG, Emp, SumIter, SumDiff) :-
    contar(Rs, GP0, GG0, Emp0, SI0, SD0),
    ( G = jugador1 -> GP is GP0 + 1, GG = GG0, Emp = Emp0
    ; G = jugador2 -> GG is GG0 + 1, GP = GP0, Emp = Emp0
    ; Emp is Emp0 + 1, GP = GP0, GG = GG0
    ),
    SumIter is SI0 + Iter,
    Diff is D2 - D1,
    SumDiff is SD0 + Diff.

run(N) :-
    findall(
        R,
        (
            between(1, N, _),
            random_between(1, 10000000, Seed),
            jugar_seed(Seed, pro, greedy, R)
        ),
        Resultados
    ),
    maplist(writeln, Resultados),
    contar(Resultados, GP, GG, Emp, SumIter, SumDiff),
    AvgIter is SumIter / N,
    AvgDiff is SumDiff / N,
    format(
        'summary(pro_vs_greedy, games=~w, pro_wins=~w, greedy_wins=~w, ties=~w, avg_iter=~2f, avg_deadwood_advantage_pro=~2f)~n',
        [N, GP, GG, Emp, AvgIter, AvgDiff]
    ).

run_live(N) :-
    run_live(1, N, 0, 0, 0, 0, 0).

run_live(I, N, GP, GG, Emp, SumIter, SumDiff) :-
    I =< N,
    random_between(1, 10000000, Seed),
    jugar_seed(Seed, pro, greedy, R),
    writeln(R),
    flush_output,
    actualizar_contadores(R, GP, GG, Emp, SumIter, SumDiff, GP1, GG1, Emp1, SumIter1, SumDiff1),
    imprimir_parcial(I, GP1, GG1, Emp1, SumIter1, SumDiff1),
    I1 is I + 1,
    run_live(I1, N, GP1, GG1, Emp1, SumIter1, SumDiff1).
run_live(I, N, GP, GG, Emp, SumIter, SumDiff) :-
    I > N,
    AvgIter is SumIter / N,
    AvgDiff is SumDiff / N,
    format(
        'summary(pro_vs_greedy, games=~w, pro_wins=~w, greedy_wins=~w, ties=~w, avg_iter=~2f, avg_deadwood_advantage_pro=~2f)~n',
        [N, GP, GG, Emp, AvgIter, AvgDiff]
    ).

actualizar_contadores(resultado(_, Iter, D1, D2, G), GP, GG, Emp, SumIter, SumDiff, GP1, GG1, Emp1, SumIter1, SumDiff1) :-
    ( G = jugador1 -> GP1 is GP + 1, GG1 = GG, Emp1 = Emp
    ; G = jugador2 -> GG1 is GG + 1, GP1 = GP, Emp1 = Emp
    ; Emp1 is Emp + 1, GP1 = GP, GG1 = GG
    ),
    SumIter1 is SumIter + Iter,
    Diff is D2 - D1,
    SumDiff1 is SumDiff + Diff.

imprimir_parcial(Jugadas, GP, GG, Emp, SumIter, SumDiff) :-
    AvgIter is SumIter / Jugadas,
    AvgDiff is SumDiff / Jugadas,
    format(
        'partial(games=~w, pro_wins=~w, greedy_wins=~w, ties=~w, avg_iter=~2f, avg_deadwood_advantage_pro=~2f)~n',
        [Jugadas, GP, GG, Emp, AvgIter, AvgDiff]
    ),
    flush_output.
