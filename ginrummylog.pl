:- discontiguous descartar/5.

% is_meld(+Cartas) -  Se cumple si y solo si Cartas es un set o un run válido
is_meld(Cartas) :- is_set(Cartas), !.
is_meld(Cartas) :- is_run(Cartas), !.

is_set(Cartas) :-
    length(Cartas, N),
    (N = 3; N = 4),
    mismo_valor(Cartas),
    palos_distintos(Cartas).

mismo_valor([c(_, _)]).
mismo_valor([c(V1, _), c(V2, _) | Resto]) :-
    V1 = V2,
    mismo_valor([c(V2, _) | Resto]).

palos_distintos([c(_, P1), c(_, P2), c(_, P3)]) :-
    P1 \= P2,
    P1 \= P3,
    P2 \= P3.
palos_distintos([c(_, P1), c(_, P2), c(_, P3), c(_, P4)]) :-
    P1 \= P2,
    P1 \= P3,
    P1 \= P4,
    P2 \= P3,
    P2 \= P4,
    P3 \= P4.

is_run(Cartas) :-
    length(Cartas, N),
    N >= 3,
    mismo_palo(Cartas),
    consecutivas(Cartas).

mismo_palo([c(_, _)]).
mismo_palo([c(_, P1), c(_, P2) | Resto]) :-
    P1 = P2,
    mismo_palo([c(_, P2) | Resto]).

consecutivas(Cartas) :-
    cartas_valores(Cartas, Valores),
    msort(Valores, Ordenados),
    consecutivos_ord(Ordenados).

cartas_valores([], []).
cartas_valores([c(V, _) | Resto], [N|Ns]) :-
    valor_carta(V, N),
    cartas_valores(Resto, Ns).

valor_carta(a, 1).
valor_carta(j, 11).
valor_carta(q, 12).
valor_carta(k, 13).
valor_carta(N, N) :-
    integer(N),
    N >= 2,
    N =< 10.

consecutivos_ord([_]).
consecutivos_ord([N1, N2|Ns]) :-
    N2 is N1 + 1,
    consecutivos_ord([N2|Ns]).

% ---------------------------------------------------------------------------------------------
% valor_deadwood(+Cartas, ?Valor) - Valor es la suma de valores de puntos de las cartas en Cartas según la tabla de deadwood.
valor_deadwood(Cartas, Valor) :-
    valor_deadwoodAC(Cartas, 0, Valor).

valor_deadwoodAC([], Ac, Ac).
valor_deadwoodAC([c(V,_) | Resto], Ac, Valor) :-
    valor_deadwood_carta(V, N),
    Ac2 is Ac + N,
    valor_deadwoodAC(Resto, Ac2, Valor).

valor_deadwood_carta(a, 1).
valor_deadwood_carta(j, 10).
valor_deadwood_carta(q, 10).
valor_deadwood_carta(k, 10).
valor_deadwood_carta(N, N) :-
    integer(N),
    N >= 2,
    N =< 10.

% ---------------------------------------------------------------------------------------------
% get_melds(+Mano, ?Melds, ?Sobrantes)
get_melds(Mano, [], Mano).
get_melds(Mano, [Meld | RestoMelds], Sobrantes) :-
    subconjunto_largo(Mano, Meld),
    is_meld(Meld),
    remover_cartas(Meld, Mano, Resto),
    get_melds(Resto, RestoMelds, Sobrantes).

subconjunto_largo(Conjunto, Sub) :-
    subconjunto(Conjunto, Sub),
    length(Sub, N),
    N >= 3.

subconjunto(_, []).
subconjunto([C1 | Cs], [C1 | Ms]) :-
    subconjunto(Cs, Ms).
subconjunto([_ | Cs], Ms) :-
    subconjunto(Cs, Ms).

remover_cartas([], Mano, Mano).
remover_cartas([C | Cs], Mano, Resto) :-
    select(C, Mano, RestoMano),
    remover_cartas(Cs, RestoMano, Resto).

% ---------------------------------------------------------------------------------------------
% best_melds(+Mano, ?MejorMelds, ?Sobrante, ?Valor)
best_melds(Mano, MejorMelds, MejorSobrante, MejorValor) :-
    findall(
        datos(Melds, Sobrantes, Valor),
        (
            get_melds(Mano, Melds, Sobrantes),
            flatten(Melds, CartasEnMelds),
            length(CartasEnMelds, N),
            N =< 10,
            valor_deadwood(Sobrantes, Valor)
        ),
        Candidatos
    ),
    min_deadwood(Candidatos, MejorMelds, MejorSobrante, MejorValor).

min_deadwood([datos(M, S, V)], M, S, V).
min_deadwood([datos(M1, S1, V1), datos(_, _, V2) | Resto], M, S, V):-
    V1 =< V2,
    min_deadwood([datos(M1, S1, V1) | Resto], M, S, V).
min_deadwood([datos(_, _, V1), datos(M2, S2, V2) | Resto], M, S, V):-
    V1 > V2,
    min_deadwood([datos(M2, S2, V2) | Resto], M, S, V).

% ---------------------------------------------------------------------------------------------
% robar(+Mano, +Descarte, +CartasVistas, +Estrategia, ?Lugar)
% RANDOM:
robar(_, _, _, random, Lugar) :-
    random_member(Lugar, [mazo, descarte]).

% GREEDY:
robar(Mano, Descarte, _, greedy, descarte) :-
    best_melds(Mano, _, _, ValorActual),
    best_melds([Descarte | Mano], _, _, ValorDescarte),
    ValorDescarte =< ValorActual.
robar(Mano, Descarte, _, greedy, mazo) :-
    best_melds(Mano, _, _, ValorActual),
    best_melds([Descarte | Mano], _, _, ValorDescarte),
    ValorDescarte > ValorActual.

% PRO:
robar(Mano, Descarte, _, pro, descarte) :-
    best_melds(Mano, _, _, ValorActual),
    best_melds([Descarte | Mano], _, _, ValorConDescarte),
    ValorConDescarte =< ValorActual.

robar(Mano, c(VDesc, _), _, pro, descarte) :-
    best_melds(Mano, _, Sobrante, ValorActual),
    best_melds([c(VDesc, _) | Mano], _, _, ValorConDescarte),
    ValorConDescarte > ValorActual,
    valor_deadwood_carta(VDesc, PuntosDesc),
    PuntosDesc =< 4,
    tiene_carta_alta(Sobrante).

robar(_, _, _, pro, mazo).

tiene_carta_alta([c(V, _) | _]) :-
    valor_deadwood_carta(V, Puntos),
    Puntos >= 10.
tiene_carta_alta([c(V, _) | Resto]) :-
    valor_deadwood_carta(V, Puntos),
    Puntos < 10,
    tiene_carta_alta(Resto).

% ---------------------------------------------------------------------------------------------
% descartar(+OldMano, +CartasVistas, +Estrategia, ?NewMano, ?NewDescarte)
% RANDOM:
descartar(OldMano, _, random, NewMano, NewDescarte) :-
    random_member(NewDescarte, OldMano),
    select(NewDescarte, OldMano, NewMano).

% GREEDY:
descartar(OldMano, _, greedy, NewMano, NewDescarte) :-
    findall(
        datos(Valor, Carta, Resto),
        (
            select(Carta, OldMano, Resto),
            best_melds(Resto, _, _, Valor)
        ),
        Candidatos
    ),
    min_datos(Candidatos, NewMano, NewDescarte).

min_datos([datos(_, C, R)], R, C).
min_datos([datos(V1, C1, R1), datos(V2, _, _) | Resto], R, C) :-
    V1 =< V2,
    min_datos([datos(V1, C1, R1) | Resto], R, C).
min_datos([datos(V1, _, _), datos(V2, C2, R2) | Resto], R, C) :-
    V1 > V2,
    min_datos([datos(V2, C2, R2) | Resto], R, C).

% PRO:
descartar(OldMano, CartasVistas, pro, NewMano, NewDescarte) :-
    best_melds(OldMano, _, Sobrante, _),
    findall(
        cvalor(Carta,Valor),
        (
            member(Carta,Sobrante),
            potencial_carta(Carta,OldMano,CartasVistas,Valor)
        ),
        CartasValores
    ),
    peor_valor(CartasValores,NewDescarte),
    select(NewDescarte,OldMano,NewMano).

potencial_carta(c(V,P), OldMano, CartasVistas, Valor) :-
    select(c(V,P),OldMano,Mano),
    findall(
        1,
        (
            member(c(V,P2),CartasVistas),
            P2 \= P
        ),
        SM
    ),
    length(SM, SetsMuertos),
    valor_carta(V,N),
    findall(
        1,
        (
            member(c(V2,P),CartasVistas),
            valor_carta(V2,N2),
            D is abs(N-N2),
            D > 0,
            D =< 2
        ),
        RM
    ),
    length(RM, RunsMuertos),
    potencial_set(c(V,P),Mano,PotencialSet),
    potencial_run(c(V,P),Mano,PotencialRun),
    Valor is SetsMuertos + RunsMuertos - PotencialSet - PotencialRun.

potencial_set(c(V,P), Mano, PotencialSet) :-
    findall(
        1,
        (
            member(c(V,P2),Mano),
            P2 \= P
        ),
        PS
    ),
    length(PS, PotencialSet).

potencial_run(c(V,P), Mano, PotencialRun) :-
    valor_carta(V,N),
    findall(
        1,
        (
            member(c(V2,P),Mano),
            valor_carta(V2,N2),
            D is abs(N-N2),
            D > 0,
            D =< 2
        ),
        PR
    ),
    length(PR, PotencialRun).

peor_valor([cvalor(C,_)], C).
peor_valor([cvalor(C1,V), cvalor(C2,V) | Resto], C) :-
    valor_deadwood_carta(C1, N1),
    valor_deadwood_carta(C2, N2),
    N1 >= N2,
    !,
    peor_valor([cvalor(C1,V)|Resto], C).
peor_valor([cvalor(C1,V), cvalor(C2,V) | Resto], C) :-
    valor_deadwood_carta(C1, N1),
    valor_deadwood_carta(C2, N2),
    N1 < N2,
    !,
    peor_valor([cvalor(C2,V)|Resto], C).
peor_valor([cvalor(C1,V1), cvalor(C2,V2) | Resto], C) :-
    V1 > V2,
    !,
    peor_valor([cvalor(C1,V1)|Resto], C).
peor_valor([_, CV2 | Resto], C) :-
    peor_valor([CV2 | Resto], C).

% ---------------------------------------------------------------------------------------------
% cerrar(+Mano, +CartasVistas, +Estrategia, ?Decision)
% RANDOM:
cerrar(Mano, _, random, Decision) :-
    best_melds(Mano, _, _, Valor),
    Valor =< 10,
    random_member(Decision, [continuar, cortar]).
cerrar(Mano, _, random, continuar) :-
    best_melds(Mano, _, _, Valor),
    Valor > 10.

% GREEDY:
cerrar(Mano, _, greedy, cortar) :-
    best_melds(Mano, _, _, Valor),
    Valor =< 10.
cerrar(Mano, _, greedy,  continuar) :-
    best_melds(Mano, _, _, Valor),
    Valor > 10.

% PRO:
cerrar(Mano, _, pro, Decision) :-
    cerrar(Mano, _, greedy, Decision).