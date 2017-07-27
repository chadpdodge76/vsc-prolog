%%
:- module(formatter, []).
read_and_portray_term(TabSize, TabDistance) :-
    set_setting(listing:body_indentation, TabSize),
    set_setting(listing:tab_distance, TabDistance),
    nb_setval(last_pred, null),
    nb_setval(vars1, []),
    nb_setval(vars2, []),
    new_memory_file(MFHandler),
    setup_call_cleanup(open_memory_file(MFHandler, update, StreamW),
                       read_and_portray_term1(user_input, StreamW, vars1),
                       close(StreamW)),
    nb_getval(vars1, Vars1),
    setup_call_cleanup(open_memory_file(MFHandler, read, StreamR),
                       read_and_portray_term1(StreamR, user_output, vars2),
                       close(StreamR)),
    free_memory_file(MFHandler),
    nb_getval(vars2, Vars2),
    (   maplist(var_name, Vars1, Vars2, [_|Varsa])
    ->  reverse(Varsa, Vars),
        print_message(information, variables(Vars))
    ;   print_message(error, variables)
    ),
    halt.
read_and_portray_term(_, _) :-
    halt.

load_doc_text(DocText):-
    open_string(DocText, Stream),
    load_files(doctext, [stream(Stream),module(user)]).

read_and_portray_term1(StreamR, StreamW, Vars) :-
    repeat,
    catch(
        read_term(StreamR, Term, [variable_names(VarsNames)]),
        E,    
        (print_message(error, E), halt)),
    nb_update_val(Vars, VarsNames),
    (   Vars==vars2
    ->  writeln(@#&),
        separate(Term, StreamW)
    ;   true
    ),
    portray_clause(StreamW, Term),
    Term=end_of_file, !.

var_name(Vars1, Vars2, Vars) :-
    is_list(Vars1),
    is_list(Vars2), !,
    length(Vars1, Len),
    length(Vars2, Len),
    maplist(var_name1, Vars1, Vars2, Varsa),
    atomic_list_concat(Varsa, ',', Vars).

var_name1(N1=_, N2=_, Pair) :-
    atomic_list_concat([N2, :, N1], Pair).

nb_update_val(Name, NewVal) :-
    nb_getval(Name, OldVal),
    nb_setval(Name, [NewVal|OldVal]).

separate(Term, LastPred) :-
    nb_getval(last_pred, CurrPred),
    term_pred(Term, Stream),
    separate(CurrPred, Stream, LastPred).

separate(null, CurrPred, _) :-
    nb_setval(last_pred, CurrPred), !.
separate(Same, Same, _) :- !.
separate(_, CurrPred, Stream) :-
    nb_setval(last_pred, CurrPred),
    nl(Stream).

term_pred((M:P:-_), M:Name/Arity) :-
    functor(P, Name, Arity), !.
term_pred((M:P-->_), M:Name/Arity) :-
    functor(P, Name, Arity), !.
term_pred((P:-_), Name/Arity) :-
    functor(P, Name, Arity), !.
term_pred((P-->_), Name/Arity) :-
    functor(P, Name, Arity), !.
term_pred((:-P), Name/Arity) :-
    functor(P, Name, Arity), !.
term_pred(P, Name/Arity) :-
    functor(P, Name, Arity).