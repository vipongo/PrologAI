:- module(chatbot_server,
  [ start_server/0,
    stop_server/0
  ]
).
    :- use_module(library(isub)).
    :- use_module(library(memfile)).
	:- use_module(library(lists)).
	:- use_module(library(http/thread_httpd)).
    :- use_module(library(http/http_dispatch)).
    :- use_module(library(http/http_files)).
    :- use_module(library(http/websocket)).

:- http_handler(root(qbot),
   http_upgrade_to_websocket(qbot, []),
   [spawn([])]).

start_server :-
    default_port(Port),
    start_server(Port).
start_server(Port) :-
   write('connection begining'),
    http_server(http_dispatch, [port(Port)]),
   write('connection established').

stop_server() :-
    default_port(Port),
    stop_server(Port).
stop_server(Port) :-
    http_stop_server(Port, []).

default_port(3000).


qbot(WebSocket) :-
   ws_receive(WebSocket, Message, [format(json)]),
   ( Message.opcode == close
   -> true
   ; get_response(Message.data, Response),
     write(Message.data),
     lire_question(Response.message, L_Mots),
     produire_reponse(L_Mots,L_ligne_reponse),
     write("Response qbot: "), writeln(L_ligne_reponse),
     flatten(L_ligne_reponse, FlattenList),
     atomics_to_string(FlattenList, ' ', ResponseString),
     ws_send(WebSocket, json(ResponseString)),
      qbot(WebSocket)
   ).

%! get_response(+Message, -Response) is det.
% Pull the message content out of the JSON converted to a prolog dict
% then add the current time, then pass it back up to be sent to the
% client
get_response(Message, Response) :-
  Response = _{message:Message.message}.

/* --------------------------------------------------------------------- */
/*                                                                       */
/*        PRODUIRE_REPONSE(L_Mots,L_Lignes_reponse) :                    */
/*                                                                       */
/*        Input : une liste de mots L_Mots representant la question      */
/*                de l'utilisateur                                       */
/*        Output : une liste de liste de lignes correspondant a la       */
/*                 reponse fournie par le bot                            */
/*                                                                       */
/*        NB Pour l'instant le predicat retourne dans tous les cas       */
/*            [  [je, ne, sais, pas, '.'],                               */
/*               [les, etudiants, vont, m, '\'', aider, '.'],            */
/*               ['vous le verrez !']                                    */
/*            ]                                                          */
/*                                                                       */
/*        Je ne doute pas que ce sera le cas ! Et vous souhaite autant   */
/*        d'amusement a coder le predicat que j'ai eu a ecrire           */
/*        cet enonce et ce squelette de solution !                       */
/*                                                                       */
/* --------------------------------------------------------------------- */


/*                      !!!    A MODIFIER   !!!                          */
/*Ajouter fonction Levenshtein (Isub) */

%Not used for the web interface
%produire_reponse([fin],[L1]) :-
%   L1 = [merci, de, m, '\'', avoir, consulte], !.    

produire_reponse(L,Rep) :-
   write(L),
   mclef(M,_), mClefSimilarity(L,M),   /*Check for levenshtein*/
   clause(regle_rep(M,_,Pattern,Rep),Body), /*Return True if levenshtein possible*/
   match_pattern(Pattern,L),
   call(Body), !.

produire_reponse(_,[L1,L2, L3]) :-
   L1 = [je, ne, sais, pas, '.'],
   L2 = [les, etudiants, vont, m, '\'', aider, '.' ],
   L3 = ['vous le verrez !'].

match_pattern(Pattern,Lmots) :-
   sublist(Pattern,Lmots).

match_pattern(LPatterns,Lmots) :-
   match_pattern_dist([100|LPatterns],Lmots).

match_pattern(P, L):-
   numbSimilarity(P,L,N), N>=2.

match_pattern_dist([],_).

match_pattern_dist([N,Pattern|Lpatterns],Lmots) :-
   within_dist(N,Pattern,Lmots,Lmots_rem),

   match_pattern_dist(Lpatterns,Lmots_rem).

within_dist(_,Pattern,Lmots,Lmots_rem) :-
   prefixrem(Pattern,Lmots,Lmots_rem).
within_dist(N,Pattern,[_|Lmots],Lmots_rem) :-
   N > 1, Naux is N-1,
  within_dist(Naux,Pattern,Lmots,Lmots_rem).


sublist(SL,L) :- 
   prefix(SL,L), !.
sublist(SL,[_|T]) :- sublist(SL,T).

sublistrem(SL,L,Lr) :- 
   prefixrem(SL,L,Lr), !.
sublistrem(SL,[_|T],Lr) :- sublistrem(SL,T,Lr).

prefixrem([],L,L).
prefixrem([H|T],[H|L],Lr) :- prefixrem(T,L,Lr).
% ----------------------------------------------------------------%
/** Check non useless(like le, la, les, des, pour, par) similarities between the two lists
 *  Example : numbSimilarity([test,hello,ha,de],[helllllo,hi,test,ho,de],N) --> N = 2
 * **/
numbSimilarity([],_,0).
numbSimilarity(_,[],0).
numbSimilarity([],[],0).
numbSimilarity([P|PS],[A|B],N+M):- isList(P), numbSimilarity(P,[A|B],M), numbSimilarity(PS,[A|B],N).
numbSimilarity([P|PS],[A|B],N):- integer(P), numbSimilarity(PS,[A|B],N).
numbSimilarity([P|PS],[A|B],N+1):- not(isList(P)), not(integer(P)), elem(A,[P|PS]), check_useful(A), numbSimilarity([P|PS],B,N).
numbSimilarity([P|PS],[A|B],N):- not(isList(P)), not(integer(P)), elem(A,[P|PS]), not(check_useful(A)), numbSimilarity([P|PS],B,N).
numbSimilarity([P|PS],[A|B],N+1):- not(isList(P)), not(integer(P)), check_useful(A), similarity([P|PS],A),numbSimilarity([P|PS],B,N).
numbSimilarity([P|PS],[A|B],N):- not(isList(P)), not(integer(P)), check_useful(A), not(similarity([P|PS],A)),numbSimilarity([P|PS],B,N).
numbSimilarity([P|PS],[A|B],N):- not(check_useful(A)), numbSimilarity([P|PS],B,N).
% ----------------------------------------------------------------%

/** True if element is not a determinant, coordinating conjonction or conjunction of overbordination **/
check_useful(A):- not(det(A)), not(conjCoord(A)), not(subord(A)).



% ----------------------------------------------------------------%

/** Check id it's a list **/
isList([]).
isList([_|XS]):- isList(XS).



% ----------------------------------------------------------------%

/* check if A is element of the list */
elem(A,[A|_]).
elem(A,[_|Y]):-elem(A,Y).


% ----------------------------------------------------------------%

/* get index of A in the list */
getIndex([A|_],A,0).
getIndex([_|F],N,I):-getIndex(F,N,I1), I is I1+1.

% ----------------------------------------------------------------%

/* list of subord/conjCoord/determinent */

subord(a).
subord(dans).
subord(par).
subord(pour).
subord(sans).
subord(sous).
subord(comme).
subord(quand).
subord(lorsque).
subord(que).
subord(si).

det(le).
det(la).
det(une).
det(un).
det(de).
det(des).
det(les).
det(du).
det(au).
det(aux).

conjCoord(mais).
conjCoord(ou).
conjCoord(et).
conjCoord(donc).
conjCoord(or).
conjCoord(ni).
conjCoord(car).

% ----------------------------------------------------------------%
/**
 * levenshtein algorithm
 * True if X is similar
 * False either
 **/
similarity([P|Q],X):- isub(P,X,true,D), D =< 0.75, similarity(Q,X).
similarity([P|_],X):- isub(P,X,true,D), D > 0.75.

mClefSimilarity([P|Q],X):- isub(P,X,true,D), D =< 0.90, mClefSimilarity(Q,X).
mClefSimilarity([P|_],X):- isub(P,X,true,D), D > 0.90.
% ----------------------------------------------------------------%

taille_jeu(9,9).
nb_barriere_par_joueur(5).

% ----------------------------------------------------------------%

mclef(commence,10).
mclef(barriere,5).
mclef(barrieres,5).
mclef(deplacer,5).
mclef(sauter, 5).
mclef(poser, 5).


% ----------------------------------------------------------------%

regle_rep(commence,1,
  [ qui, commence, le, jeu ],
  [ [ "c est", au, pion, bleu, de, commencer ],
    [ puis, aux, pions, "rouge," , vert, et, "jaune." ] ] ).

% ----------------------------------------------------------------%

regle_rep(barrieres,5,
  [2, [ combien ], 3, [ barrieres ], 5, [ debut] ],
  [ [ vous, disposez, de, X, "barrieres." ] ]) :-

     nb_barriere_par_joueur(X).

% ----------------------------------------------------------------%

regle_rep(deplacer, 1,
   [3,[deplacer], 3 , [barriere]],
   [ [ non, vous, ne, pouvez, "pas." ] ] ).

% ----------------------------------------------------------------%

regle_rep(sauter, 1,
   [3, [sauter],5,[pion]],
   [[oui, si, il, "n est", pas, suivi],
   [d, un, autre, pion, ou, "dune", "barriere."] ] ).

% ----------------------------------------------------------------%

regle_rep(poser, 1,
   [3,[poser],3,[barriere]],
   [[en, principe, oui],
   [mais, vous, ne, pouvez, pas, enfermer, un, pion, "adverse."]]).

/* --------------------------------------------------------------------- */
/*                                                                       */
/*          CONVERSION D'UNE QUESTION DE L'UTILISATEUR EN                */
/*                        LISTE DE MOTS                                  */
/*                                                                       */
/* --------------------------------------------------------------------- */

% lire_question(L_Mots) 
%lire_question(LMots) :- read_atomics(LMots).
lire_question(Question, LMots) :- read_atomics(Question, LMots).



/*****************************************************************************/
% my_char_type(+Char,?Type)
%    Char is an ASCII code.
%    Type is whitespace, punctuation, numeric, alphabetic, or special.

my_char_type(46,period) :- !.
my_char_type(X,alphanumeric) :- X >= 65, X =< 90, !.
my_char_type(X,alphanumeric) :- X >= 97, X =< 123, !.
my_char_type(X,alphanumeric) :- X >= 48, X =< 57, !.
my_char_type(X,whitespace) :- X =< 32, !.
my_char_type(X,punctuation) :- X >= 33, X =< 47, !.
my_char_type(X,punctuation) :- X >= 58, X =< 64, !.
my_char_type(X,punctuation) :- X >= 91, X =< 96, !.
my_char_type(X,punctuation) :- X >= 123, X =< 126, !.
my_char_type(_,special).


/*****************************************************************************/
% lower_case(+C,?L)
%   If ASCII code C is an upper-case letter, then L is the
%   corresponding lower-case letter. Otherwise L=C.

lower_case(X,Y) :-
	X >= 65,
	X =< 90,
	Y is X + 32, !.

lower_case(X,X).


/*****************************************************************************/
% read_lc_string(-String)
%  Reads a line of input into String as a list of ASCII codes,
%  with all capital letters changed to lower case.

read_lc_string(String) :-
	get_code(FirstChar),
	lower_case(FirstChar,LChar),
	read_lc_string_aux(LChar,String).

read_lc_string_aux(10,[]) :- !.  % end of line

read_lc_string_aux(-1,[]) :- !.  % end of file

read_lc_string_aux(LChar,[LChar|Rest]) :- read_lc_string(Rest).


/*****************************************************************************/
% extract_word(+String,-Rest,-Word) (final version)
%  Extracts the first Word from String; Rest is rest of String.
%  A word is a series of contiguous letters, or a series
%  of contiguous digits, or a single special character.
%  Assumes String does not begin with whitespace.

extract_word([C|Chars],Rest,[C|RestOfWord]) :-
	my_char_type(C,Type),
	extract_word_aux(Type,Chars,Rest,RestOfWord).

extract_word_aux(special,Rest,Rest,[]) :- !.
   % if Char is special, don't read more chars.

extract_word_aux(Type,[C|Chars],Rest,[C|RestOfWord]) :-
	my_char_type(C,Type), !,
	extract_word_aux(Type,Chars,Rest,RestOfWord).

extract_word_aux(_,Rest,Rest,[]).   % if previous clause did not succeed.


/*****************************************************************************/
% remove_initial_blanks(+X,?Y)
%   Removes whitespace characters from the
%   beginning of string X, giving string Y.

remove_initial_blanks([C|Chars],Result) :-
	my_char_type(C,whitespace), !,
	remove_initial_blanks(Chars,Result).

remove_initial_blanks(X,X).   % if previous clause did not succeed.


/*****************************************************************************/
% digit_value(?D,?V)
%  Where D is the ASCII code of a digit,
%  V is the corresponding number.

digit_value(48,0).
digit_value(49,1).
digit_value(50,2).
digit_value(51,3).
digit_value(52,4).
digit_value(53,5).
digit_value(54,6).
digit_value(55,7).
digit_value(56,8).
digit_value(57,9).


/*****************************************************************************/
% string_to_number(+S,-N)
%  Converts string S to the number that it
%  represents, e.g., "234" to 234.
%  Fails if S does not represent a nonnegative integer.

string_to_number(S,N) :-
	string_to_number_aux(S,0,N).

string_to_number_aux([D|Digits],ValueSoFar,Result) :-
	digit_value(D,V),
	NewValueSoFar is 10*ValueSoFar + V,
	string_to_number_aux(Digits,NewValueSoFar,Result).

string_to_number_aux([],Result,Result).


/*****************************************************************************/
% string_to_atomic(+String,-Atomic)
%  Converts String into the atom or number of
%  which it is the written representation.

string_to_atomic([C|Chars],Number) :-
	string_to_number([C|Chars],Number), !.

string_to_atomic(String,Atom) :- atom_codes(Atom,String).
  % assuming previous clause failed.


/*****************************************************************************/
% extract_atomics(+String,-ListOfAtomics) (second version)
%  Breaks String up into ListOfAtomics
%  e.g., " abc def  123 " into [abc,def,123].

extract_atomics(String,ListOfAtomics) :-
	remove_initial_blanks(String,NewString),
	extract_atomics_aux(NewString,ListOfAtomics).

extract_atomics_aux([C|Chars],[A|Atomics]) :-
	extract_word([C|Chars],Rest,Word),
	string_to_atomic(Word,A),       % <- this is the only change
	extract_atomics(Rest,Atomics).

extract_atomics_aux([],[]).


/*****************************************************************************/
% clean_string(+String,-Cleanstring)
%  removes all punctuation characters from String and return Cleanstring

clean_string([C|Chars],L) :-
	my_char_type(C,punctuation),
	clean_string(Chars,L), !.
clean_string([C|Chars],[C|L]) :-
	clean_string(Chars,L), !.
clean_string([C|[]],[]) :-
	my_char_type(C,punctuation), !.
clean_string([C|[]],[C]).


/*****************************************************************************/
% read_atomics(-ListOfAtomics)
%  Reads a line of input, removes all punctuation characters, and converts
%  it into a list of atomic terms, e.g., [this,is,an,example].

/*read_atomics(ListOfAtomics) :-
	read_lc_string(String),
	clean_string(String,Cleanstring),
	extract_atomics(Cleanstring,ListOfAtomics).*/

read_atomics(QuestionString, ListOfAtomics) :-
   write("Question posee: "), writeln(QuestionString),
   string_codes(QuestionString, QuestionCodes),
   write("Question as ASCII codes: "), writeln(QuestionCodes),
  clean_string(QuestionCodes,Cleanstring),
  write("clean string : "), writeln(Cleanstring),
  extract_atomics(Cleanstring,ListOfAtomics),
  write("list of atomics : "), writeln(ListOfAtomics).

/* --------------------------------------------------------------------- */
/*                                                                       */
/*        ECRIRE_REPONSE : ecrit une suite de lignes de texte            */
/*                                                                       */
/* --------------------------------------------------------------------- */

ecrire_reponse(L) :-
   nl, write('QBot :'),
   ecrire_li_reponse(L,1,1).

% ecrire_li_reponse(Ll,M,E)
% input : Ll, liste de listes de mots (tout en minuscules)
%         M, indique si le premier caractere du premier mot de 
%            la premiere ligne doit etre mis en majuscule (1 si oui, 0 si non)
%         E, indique le nombre d'espaces avant ce premier mot 

ecrire_li_reponse([],_,_) :- 
    nl.

ecrire_li_reponse([Li|Lls],Mi,Ei) :- 
   ecrire_ligne(Li,Mi,Ei,Mf),
   ecrire_li_reponse(Lls,Mf,2).

% ecrire_ligne(Li,Mi,Ei,Mf)
% input : Li, liste de mots a ecrire
%         Mi, Ei booleens tels que decrits ci-dessus
% output : Mf, booleen tel que decrit ci-dessus a appliquer 
%          a la ligne suivante, si elle existe

ecrire_ligne([],M,_,M) :- 
   nl.

ecrire_ligne([M|L],Mi,Ei,Mf) :-
   ecrire_mot(M,Mi,Maux,Ei,Eaux),
   ecrire_ligne(L,Maux,Eaux,Mf).

% ecrire_mot(M,B1,B2,E1,E2)
% input : M, le mot a ecrire
%         B1, indique s'il faut une majuscule (1 si oui, 0 si non)
%         E1, indique s'il faut un espace avant le mot (1 si oui, 0 si non)
% output : B2, indique si le mot suivant prend une majuscule
%          E2, indique si le mot suivant doit etre precede d'un espace

ecrire_mot('.',_,1,_,1) :-
   write('. '), !.
ecrire_mot('\'',X,X,_,0) :-
   write('\''), !.
ecrire_mot(',',X,X,E,1) :-
   espace(E), write(','), !.
ecrire_mot(M,0,0,E,1) :-
   espace(E), write(M).
ecrire_mot(M,1,0,E,1) :-
   atom_codes(M,[C|L]),
   D is C - 32,
   atom_codes(N,[D|L]),
   espace(E), write(N).

espace(0).
espace(N) :- N>0, Nn is N-1, write(' '), espace(Nn).


/* --------------------------------------------------------------------- */
/*                                                                       */
/*                            TEST DE FIN                                */
/*                                                                       */
/* --------------------------------------------------------------------- */

fin(L) :- member(fin,L).


/* --------------------------------------------------------------------- */
/*                                                                       */
/*                         BOUCLE PRINCIPALE                             */
/*                                                                       */
/* --------------------------------------------------------------------- */

quoridoria :- 

   nl, nl, nl,
   write('Bonjour, je suis QBot, le bot explicateur de QuoridorIA.'), nl,
   write('En quoi puis-je vous aider ?'), 
   nl, nl, 

   repeat,
      write('Vous : '), flush_output,
      lire_question(L_Mots),
      produire_reponse(L_Mots,L_ligne_reponse),
      ecrire_reponse(L_ligne_reponse),
   fin(L_Mots), !.
   

/* --------------------------------------------------------------------- */
/*                                                                       */
/*             ACTIVATION DU PROGRAMME APRES COMPILATION                 */
/*                                                                       */
/* --------------------------------------------------------------------- */

:- start_server.