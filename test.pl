:- use_module(library(plunit)).

:- [ginrummylog].

:- begin_tests(gin_rummy).

%%%%%%%%%%%%%%
%%% Helpers
%%%%%%%%%%%%%%

same_cards(L1, L2) :-
    msort(L1, S1),
    msort(L2, S2),
    S1 == S2.

all_melds_valid([]).
all_melds_valid([M|Ms]) :-
    is_meld(M),
    all_melds_valid(Ms).

%%%%%%%%%%%%%%
%%% is_meld/1
%%%%%%%%%%%%%%

test(is_meld_set_de_3,[nondet]) :-
    is_meld([c(7,c), c(7,d), c(7,p)]).

test(is_meld_set_de_4,[nondet]) :-
    is_meld([c(q,c), c(q,d), c(q,t), c(q,p)]).

test(is_meld_run_de_3_desordenado,[nondet]) :-
    is_meld([c(5,p), c(3,p), c(4,p)]).

test(is_meld_run_de_5,[nondet]) :-
    is_meld([c(3,c), c(4,c), c(5,c), c(6,c), c(7,c)]).

test(is_meld_falla_por_palos_distintos, [fail,nondet]) :-
    is_meld([c(3,c), c(4,d), c(5,c)]).

test(is_meld_falla_por_hueco, [fail,nondet]) :-
    is_meld([c(3,p), c(4,p), c(6,p)]).

test(is_meld_falla_por_largo_2, [fail,nondet]) :-
    is_meld([c(9,c), c(9,d)]).

test(is_meld_falla_por_escalera_circular, [fail,nondet]) :-
    is_meld([c(q,c), c(k,c), c(a,c)]).

test(is_meld_escalera_con_as, [nondet]) :-
    is_meld([c(3,c), c(2,c), c(a,c)]).

%%%%%%%%%%%%%%
%%% valor_deadwood/2
%%%%%%%%%%%%%%

test(valor_deadwood_vacio,[nondet]) :-
    valor_deadwood([], V),
    assertion(V =:= 0).

test(valor_deadwood_basico,[nondet]) :-
    valor_deadwood([c(a,c), c(10,d), c(j,p), c(5,t)], V),
    assertion(V =:= 26).

%%%%%%%%%%%%%%
%%% get_melds/3
%%%%%%%%%%%%%%

test(get_melds_vacio,[nondet]) :-
    get_melds([], Melds, Sobrante),
    assertion(Melds == []),
    assertion(Sobrante == []).

test(get_melds_sin_melds_devuelve_todo_sobrante,[nondet]) :-
    Mano = [c(2,c), c(5,d), c(7,p), c(9,t)],
    get_melds(Mano, [], Mano2),
    same_cards(Mano, Mano2).

test(get_melds_encuentra_un_meld,[nondet]) :-
    Mano = [c(3,p), c(4,p), c(5,p), c(k,d)],
    get_melds(Mano, [[c(3,p), c(4,p), c(5,p)]], [c(k,d)]).

test(get_melds_encuentra_dos_melds_disjuntos,[nondet]) :-
    Mano = [c(3,p), c(4,p), c(5,p), c(9,c), c(9,d), c(9,t), c(k,d)],
    get_melds(Mano, Melds, Sobrante),
    length(Melds, 2),
    flatten(Melds, Todas),
    same_cards(Todas, [c(3,p), c(4,p), c(5,p), c(9,c), c(9,d), c(9,t)]),
    same_cards(Sobrante, [c(k,d)]),
    all_melds_valid(Melds),
    !.

%%%%%%%%%%%%%%
%%% best_melds/4
%%%%%%%%%%%%%%

test(best_melds_sin_melds,[nondet]) :-
    Mano = [c(2,c), c(5,d), c(7,p), c(9,t)],
    best_melds(Mano, Melds, Sobrante, Valor),
    assertion(Melds == []),
    assertion(same_cards(Sobrante, Mano)),
    assertion(Valor =:= 23).

test(best_melds_dos_melds_y_un_sobrante,[nondet]) :-
    Mano = [c(3,p), c(4,p), c(5,p), c(9,c), c(9,d), c(9,t), c(k,d)],
    best_melds(Mano, Melds, Sobrante, Valor),
    flatten(Melds, Todas),
    same_cards(Todas, [c(3,p), c(4,p), c(5,p), c(9,c), c(9,d), c(9,t)]),
    same_cards(Sobrante, [c(k,d)]),
    assertion(Valor =:= 10).

test(best_melds_prefiere_la_combinacion_optima,[nondet]) :-
    % Acá hay solapamiento posible con los 5.
    % La mejor jugada es el run 3-4-5-6 de p, dejando 5c, 5d, k.
    Mano = [c(3,p), c(4,p), c(5,p), c(6,p), c(5,c), c(5,d), c(k,d)],
    best_melds(Mano, Melds, Sobrante, Valor),
    flatten(Melds, Todas),
    same_cards(Todas, [c(3,p), c(4,p), c(5,p), c(6,p)]),
    same_cards(Sobrante, [c(5,c), c(5,d), c(k,d)]),
    assertion(Valor =:= 20).

:- end_tests(gin_rummy).
