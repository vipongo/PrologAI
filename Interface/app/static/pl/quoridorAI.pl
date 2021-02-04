
:- module(ia_server,
  [ start_server/0,
    stop_server/0
  ]
).
	:- use_module(library(lists)).
	:- use_module(library(http/thread_httpd)).
    :- use_module(library(http/http_dispatch)).
    :- use_module(library(http/http_files)).
    :- use_module(library(http/websocket)).

:- http_handler(root(ia),
                http_upgrade_to_websocket(ia, []),
                [spawn([])]).

start_server :-
    default_port(Port),
    start_server(Port).
start_server(Port) :-
    http_server(http_dispatch, [port(Port)]).

stop_server() :-
    default_port(Port),
    stop_server(Port).
stop_server(Port) :-
    http_stop_server(Port, []).

default_port(4000).

/* ------------------------------------------------------------------------------------------*/
/* ------------------------------------------------------------------------------------------*/

ia(WebSocket):-
    ws_receive(WebSocket, Message, [format(json)]),
    ( Message.opcode == close
        -> true
    ; get_response(Message.data, Response),
       pos(Response.x, Response.y, Position),
       write(Response),
      % In case action is to move a pawn.
      (isAccessible(Position, Response.color)
            -> move(Response.color, Position, ResponseString),
               ws_send(WebSocket, json(ResponseString))
        % In case action is to place a wall.
      ; (barriercheck(Position, _)
             -> placeBarrier(Position, Response.direction, ResponseString),
                ws_send(WebSocket, json(ResponseString))
        ; ws_send(WebSocket, json(Response.color))
        )
      ),
      write("New state: "), writeln(""),
      ia(WebSocket)
    ).



% get_response(+Message, -Response) is det.
% Pull the message content out of the JSON converted to a prolog dict
get_response(Message, Response) :-
    Response = _{color: Message.color, direction: Message.direction, x: Message.x, y: Message.y}.


/* --------------------------------------------------------------------- */
/*                                                                       */
/*                          Initial State                                */
/*                                                                       */
/* --------------------------------------------------------------------- */


pawnPosition("red", [4, 0]).
pawnPosition("yellow", [0, 4]).
pawnPosition("blue", [4, 8]).
pawnPosition("green", [8, 4]).


placeBarrier(_, _, ResponseString) :- ResponseString = "".

/*placeBarrier(Position, Orientation, ResponseString):-
    possibleBarrier(Position),ResponseString
    string_concat("OK:", "WALL", PreResponseString1),
    string_concat(PreResponseString1, "-", PreResponseString2),
    string_concat(PreResponseString2, Position, PreResponseString3),
    string_concat(PreResponseString3, "-", PreResponseString4),
    string_concat(PreResponseString4, Orientation, ResponseString),
    PlusX is X+1, MinY is Y-1,
    (Orientation == "Vertical"
        ->
           assert( barriercheck(Position1, Position12)),
           assert( barriercheck(Position2, Position22)),
           assert( barriercheck(Position3, Position32)),
           assert( barriercheck(Position4, Position42))

        ;
           assert(barriercheck(Position1, Position12)),
           assert(barriercheck(Position2, Position22)),
           assert(barriercheck(Position3, Position32)),
           assert(barriercheck(Position4, Position42))
    ).*/

possibleBarrier(Position):-
    between(1,8, first(Position)),
    between(1,8, second(Position)).

/* --------------------------------------------------------------------- */
/*                                                                       */
/*                          Game rules                                   */
/*                                                                       */
/* --------------------------------------------------------------------- */
:- dynamic position/2.

% Position structure

position([X,Y]):- 
    gameSize(MaxUp,MaxY),
    GoUp is MaxUp - 1,
    GoRight is MaxY - 1,
    between(0,GoUp,X),
    between(0,GoRight,Y).

% Number of accepted barriers
acceptedBarriers(N):-
    maxBarriers(M),
    between(0, M, N).

% Set of barriers structure
setBarriers([]).
setBarriers([barrier(PosX,PosY)|XS]):-
    barrier(PosX,PosY),
    not(alreadyPlaced(PosX,XS)),
    not(collision(PosX,PosY,XS)),
    setBarriers(XS).

% Direction for barriers
axe(horizontal).
axe(vertical).

% Barrier structure
barrier([PosX,PosY], Axe):-
    position([PosX,PosY]),
    PosX < 8,
    PosY > 0,
    PosY < 8,
    PosX > 0,
    axe(Axe).

% Player data
player(Color, Barrier, Position):-
    color(Color),
    acceptedBarriers(Barrier),
    position(Position).



/* --------------------------------------------------------------------- */
/*                                                                       */
/*                          SPECIAL STATES                               */
/*                                                                       */
/* --------------------------------------------------------------------- */

% Final place blue
blueFinalState(state(_,[player(blue,_,[xPos,yPos]),_,_,_],_)):-
    yPos == 0,
    position([xPos,yPos]).

% Final place red
redFinalState(state(_,[_,player(red,_,[xPos,yPos]),_,_],_)):-
    yPos == 8,
    position([xPos,yPos]).

% final place green
greenFinalState(state(_,[_,_,player(green,_,[xPos,yPos]),_],_)):-
    xPos == 0,
    position([xPos,yPos]).

% final place yellow  
yellowFinalState(state(_,[_,_,_,player(yellow,_,[xPos,yPos])],_)):-
    xPos == 8,
    position([xPos,yPos]).




% États finaux
/* --------------------------------------------------------------------- */
/*                                                                       */
/*                     Final State of the game                           */
/*                                                                       */
/* --------------------------------------------------------------------- */

final_state(state(CurrentColor,[player(C,NB,[PosX,PosY]),P2,P3,P4],SB)):-
    %state(CurrentColor,[player(C,NB,[PosX,PosY]),P2,P3,P4],SB),
    final_pos(C,[PosX,PosY]).

final_state(state(CurrentColor,[P1,player(C,NB,[PosX,PosY]),P3,P4],SB)):-
    %state(CurrentColor,[P1,player(C,NB,[PosX,PosY]),P3,P4],SB),
    final_pos(C,[PosX,PosY]).

final_state(state(CurrentColor,[P1,P2,player(C,NB,[PosX,PosY]),P4],SB)):-
    %state(CurrentColor,[P1,P2,player(C,NB,[PosX,PosY]),P4],SB),
    final_pos(C,[PosX,PosY]).

final_state(state(CurrentColor,[P1,P2,P3,player(C,NB,[PosX,PosY])],SB)):-
    %state(CurrentColor,[P1,P2,P3,player(C,NB,[PosX,PosY])],SB),
    final_pos(C,[PosX,PosY]).

% final position

final_pos(blue,[xPos,yPos]):-
    yPos is 0,
    position([xPos,yPos]).

final_pos(green,[xPos,yPos]):-
    xPos is 0,
    position([xPos,yPos]).

final_pos(yellow,[xPos,yPos]):-
    xPos is 8,
    position([xPos,yPos]).
    
final_pos(red,[xPos,yPos]):-
    yPos is 8,
    position([xPos,yPos]).
/* --------------------------------------------------------------------- */
/*                                                                       */
/*                          Game parameters                              */
/*                                                                       */
/* --------------------------------------------------------------------- */

% Actual game parameters
% Size
gameSize(9,9).

%Number of available barriers
maxBarriers(5).

% Parameters for other functions

% Color of the player
color(blue).
color(red).
color(green).
color(yellow).


/* --------------------------------------------------------------------- */
/*                                                                       */
/*                          Secondary Game rules                         */
/*                                                                       */
/* --------------------------------------------------------------------- */
%TODO:
%alreadyPlaced
alreadyPlaced(Position,[barrier(Position,_)]).
alreadyPlaced(Position,[barrier(Position,_)|_]).
alreadyPlaced(Position,[barrier(H,_)|XS]):-
    Position \= H,
    alreadyPlaced(Position,XS).


%Collision check for barrier not to collide
collision([PosX,PosY],P,[barrier(Pos,P)]):-
    P == vertical,
    verticalZone([PosX,PosY],Pos).  
collision([PosX,PosY],P,[barrier(Pos,P)]):-
    P == horizontal,
    horizontalZone([PosX,PosY],Pos).    
collision([PosX,PosY],P,[barrier(Pos,P)|_]):-
    P == vertical,
    verticalZone([PosX,PosY],Pos). 
collision([PosX,PosY],P,[barrier(Pos,P)|_]):-
    P == horizontal,
    horizontalZone([PosX,PosY],Pos).  
collision([PosX,PosY],P,[barrier(_,H)|XS]):-
    P \= H,
    collision([PosX,PosY],P,XS).

verticalZone([X1,Y1],[X2,Y2]):-
    X1 == X2,
    Y1 is Y2 + 1.
verticalZone([X1,Y1],[X2,Y2]):-
    X1 == X2,
    Y1 is Y2 - 1.

horizontalZone([X1,Y1],[X2,Y2]):-
    Y1 == Y2,
    X1 is X2 + 1.
horizontalZone([X1,Y1],[X2,Y2]):-
    Y1 == Y2,
    X1 is X2 - 1. 

% Is a case accessible to a player
isAccessible(ToPosition, Color):-
    pawnPosition(Color, FromPosition),
    leapfrog(FromPosition, ToPosition).
    %setBarriers(Barrier),
    %adjacentList([PosX,PosY],State),
    %removeUnavailableTile([PosX,PosY], State, Barrier),
    %list_to_set(NextState,LastState).

isAccessible(Pawn, NextPosition):-
    position(Pawn,PositionBarrierPossible),
    assert(barriercheck(PositionBarrierPossible, "-1")).

% Create a list of adjacent place from a tile
adjacentList([PosX,PosY],LastState):-
    isBorder([PosX,PosY],right),
    Left is PosX-1,
    Up is PosY+1,
    Down is PosY-1,
    LastState = [[PosX,Up],[Left,PosY],[PosX,Down]].
adjacentList([PosX,PosY],LastState):-
    not(isBorder([PosX,PosY],_)),
    not(isCorner([PosX,PosY],_)),
    Right is PosX+1,
    Left is PosX-1,
    Up is PosY+1,
    Down is PosY-1,
    LastState = [[Right,PosY],[PosX,Up],[Left,PosY],[PosX,Down]].
adjacentList([PosX,PosY],LastState):-
    isCorner([PosX,PosY],leftUp),
    Right is PosX+1,
    Down is PosY-1,
    LastState = [[Right,PosY],[PosX,Down]].
adjacentList([PosX,PosY],LastState):-
    isCorner([PosX,PosY],leftDown),
    Right is PosX+1,
    Up is PosY+1,
    LastState = [[Right,PosY],[PosX,Up]].
adjacentList([PosX,PosY],LastState):-
    isCorner([PosX,PosY],rightDown),
    Left is PosX-1,
    Up is PosY+1,
    LastState = [[PosX,Up],[Left,PosY]].
adjacentList([PosX,PosY],LastState):-
    isBorder([PosX,PosY],left),
    Right is PosX+1,
    Up is PosY+1,
    Down is PosY-1,
    LastState = [[Right,PosY],[PosX,Up],[PosX,Down]].
adjacentList([PosX,PosY],LastState):-
    isBorder([PosX,PosY],up),
    Right is PosX+1,
    Left is PosX-1,
    Down is PosY-1,
    LastState = [[Right,PosY],[Left,PosY],[PosX,Down]].
adjacentList([PosX,PosY],LastState):-
    isCorner([PosX,PosY],rightUp),
    Left is PosX-1,
    Down is PosY-1,
    LastState = [[Left,PosY],[PosX,Down]].
adjacentList([PosX,PosY],LastState):-
    isBorder([PosX,PosY],down),
    Right is PosX+1,
    Left is PosX-1,
    Up is PosY+1,
    LastState = [[Right,PosY],[PosX,Up],[Left,PosY]].

% Check if corner 
isCorner([PosX,PosY], rightUp):-
    PosX == 8,
    PosY == 8.
isCorner([PosX,PosY], leftUp):-
    PosX == 0,
    PosY == 8.
isCorner([PosX,PosY], rightDown):-
    PosX == 8,
    PosY == 0.
isCorner([PosX,PosY], leftDown):-
    PosX == 0,
    PosY == 0.

% check if border
isBorder([PosX,PosY], up):-
    not(isCorner([PosX,PosY],_)),
    PosY == 8.
isBorder([PosX,PosY], right):-
    not(isCorner([PosX,PosY],_)),
    PosX == 8.
isBorder([PosX,PosY], left):-
    not(isCorner([PosX,PosY],_)),
    PosX == 0.
isBorder([PosX,PosY], down):-
    not(isCorner([PosX,PosY],_)),
    PosY == 0.

% Remove Unavailable Tile where a pawn can't go
removeUnavailableTile(_, [], _, []).
removeUnavailableTile([PosX,PosY], [X|XS], Barrier, LastState):-
    barrierBlocking([PosX,PosY], X),
    removeUnavailableTile([PosX,PosY], XS, Barrier, LastState).
removeUnavailableTile([PosX,PosY], [X|XS], Barrier, [X|LastState]):-
    not(barrierBlocking([PosX,PosY], X)),
    removeUnavailableTile([PosX,PosY], XS, Barrier, LastState).

% Check if a barrier is blocking the way
barrierBlocking([X,Y], [X2, Y2]):- barrier_blocking_v([X,Y], [X2, Y2]); barrier_blocking_h([X,Y], [X2, Y2]).

barrier_blocking_h([X,Y], [X2, Y2]) :- DownY is Y + 1, (X2 = X + 1; X2 = X - 1), Y = Y2, (barrier([X2,Y], vertical); barrier([X2,DownY], vertical)).
barrier_blocking_v([X,Y], [X2, Y2]) :- RightX is X + 1, (Y2 = Y + 1; Y2 = y - 1), X = X2, (barrier([X,Y2], horizontal); barrier([RightX,Y2], horizontal)).


% Check if leapfrog is possible.
% [X, Y] : from position
% [X2, Y2] : to position
leapfrog([X,Y], [X2, Y2]):-
    leapfrog_right([X,Y], [X2, Y2]);
    leapfrog_left([X,Y], [X2, Y2]);
    leapfrog_up([X,Y], [X2, Y2]);
    leapfrog_down([X,Y], [X2, Y2]).


% Check if can do a leapfrog to the right.
leapfrog_left([X,Y], [X2, Y2]):-
    LeftX is X - 1, DownY is Y + 1, UpY is Y - 1, X2 = LeftX - 1,
    player_in_leapfrog([LeftX, Y], [X2, Y2]),
    % No barrier in front and down => Go straight.
    (Y2 = Y, barrier_not_A_not_B([X2, Y], [X2, DownY], vertical));
    % Barrier in front but not down => Go in diagonal down.
    (Y2 = DownY, barrier_in_A_not_B([X, Y2], [X2, DownY], vertical));
     % Barrier in front but not down => Go in diagonal up.
    (Y2 = UpY, barrier_in_B_not_A([X, Y2], [X2, DownY], vertical)).

% Check if can do a leapfrog to the right.
leapfrog_right([X,Y], [X2, Y2]):-
    RightX is X + 1, DownY is Y + 1, UpY is Y - 1, X2 = RigthX + 1,
    player_in_leapfrog([RightX, Y], [X2, Y2]),
    % No barrier in front and down => Go straight.
    (Y2 = Y, barrier_not_A_not_B([X2, Y], [X2, DownY], vertical));
    % Barrier in front but not down => Go in diagonal down.
    (Y2 = DownY, barrier_in_A_not_B([X, Y2], [X2, DownY], vertical));
    % Barrier in front but not down => Go in diagonal up.
    (Y2 = UpY, barrier_in_B_not_A([X, Y2], [X2, DownY], vertical)).

% Check if can do a leapfrog up.
leapfrog_up([X,Y], [X2, Y2]):-
    RightX is X + 1, LeftX is X - 1, UpY is Y - 1, Y2 = UpY - 1,
    player_in_leapfrog([X, UpY], [X2, Y2]),
    % No barrier in front and to the right => Go straight.
    (X2 = X, barrier_not_A_not_B([X, Y2], [RightX, Y2], horizontal));
    % Barrier in front but not to the right => Go in diagonal to the right.
    (X2 = RightX, barrier_in_A_not_B([X, Y2], [RightX, Y2], horizontal));
    % No barrier in front but one to the right => Go in diagonal to the left.
    (X2 = LeftX, barrier_in_B_not_A([X, Y2], [RightX, Y2], horizontal)).

% Check if can do a leapfrog down.
leapfrog_down([X,Y], [X2, Y2]):-
    RightX is X + 1, LeftX is X - 1, DownY is Y + 1, Y2 = DownY + 1,
    player_in_leapfrog([X, DownY], [X2, Y2]),
    % No barrier in front and to the right => Go straight.
    (X2 = X, barrier_not_A_not_B([X, Y2], [RightX, Y2], horizontal));
    % Barrier in front but not to the right => Go in diagonal to the right.
    (X2 = RightX, barrier_in_A_not_B([X, Y2], [RightX, Y2], horizontal));
    % No barrier in front but one to the right => Go in diagonal to the left.
    (X2 = LeftX, barrier_in_B_not_A([X, Y2], [RightX, Y2], horizontal)).

% Check if there is a player in the direction and no player behind it.
% [X, Y] position in front.
% [X2, Y2] the destination.
player_in_leapfrog([X, Y], [X2, Y2]) :- player(_,_, [X, Y]), not(player(_,_, [X2, Y2])).

% No barrier nor in position A nor in position B.
barrier_not_A_not_B([X, Y], [X2, Y2], Axe) :- not(barrier([X, Y], Axe)), barrier([X2, Y2], Axe).

% No barrier in position A but not B.
barrier_in_A_not_B([X, Y], [X2, Y2], Axe) :- barrier([X, Y], Axe), not(barrier([X2, Y2], Axe)).

% No barrier in position B but not A.
barrier_in_B_not_A([X, Y], [X2, Y2], Axe) :- not(barrier([X, Y], Axe)), barrier([X2, Y2], Axe).


/* --------------------------------------------------------------------- */
/*                                                                       */
/*                       Fonctionnal rules                               */
/*                                                                       */
/* --------------------------------------------------------------------- */
% possible actions
action(move).
action(barrierPlacing).

% create possible barriers placing action
barrierPlacing(state(Color,ListPlayer,SB),[action(barrierPlacing),Color,TNB,[Barrier|SB]]):-
                currentPlayerLastingBarriers(Color,ListPlayer,NumberBarrier),
                NumberBarrier > 0,
                position(Position),
                axe(Axe),
                Barrier = barrier(Position,Axe),
                setBarriers([Barrier|SB]),
                TNB is NumberBarrier - 1.

% create possible moving action
move(state(Color,ListPlayer,SetBarriers), [act(move),Color,M]):-
    currentPlayerPosition(Color,ListPlayer,Position),
    allPlayersPosition(ListPlayer,ListPos),
    %isAccessible(Position,ListPos,SetBarriers,LastState),
    member(M,LastState).
move(Pawn, NextPosition, ResponseString):-
    isAccessible(Pawn, NextPosition),
    %remove pawn from last position
    retract(position(Pawn,_)),
    string_concat("Pawn has been moved to",NextPosition, ResponseString).
barriercheck("WALL","INITIAL").



% create an action

action(state(Color,ListPlayer,SetBarriers),Action):-
    move(state(Color,ListPlayer,SetBarriers),Action).

action(state(Color,ListPlayer,SetBarriers),Action):-
    barrierPlacing(state(Color,ListPlayer,SetBarriers),Action).



/* --------------------------------------------------------------------- */
/*                                                                       */
/*                       Moving rules                                    */
/*                                                                       */
/* --------------------------------------------------------------------- */
%change state after moving

%blue
stateMove(state(blue,[player(blue,NumberBarrier,_),P2,P3,P4],SB),
           [act(move),blue,M],
           state(red,[player(blue,NumberBarrier,M),P2,P3,P4],SB)).

%red
stateMove(state(red,[P1,player(red,NumberBarrier,_),P3,P4],SB),
           [act(move),red,M],
           state(green,[P1,player(red,NumberBarrier,M),P3,P4],SB)).

%green
stateMove(state(green,[P1,P2,player(green,NumberBarrier,_),P4],SB),
           [act(move),green,M],
           state(yellow,[P1,P2,player(green,NumberBarrier,M),P4],SB)).

%yellow
stateMove(state(yellow,[P1,P2,P3,player(yellow,NumberBarrier,_)],SB),
           [act(move),yellow,M],
           state(blue,[P1,P2,P3,player(yellow,NumberBarrier,M)],SB)).

%change state after placing barriers
%blue
placeBar(state(blue,[player(blue,_,Pos),P2,P3,P4],_),
        [act(drop),blue,NB,TB],
        state(red,[player(blue,NB,Pos),P2,P3,P4],TB)).
%Red
placeBar(state(red,[P1,player(red,_,Pos),P3,P4],_),
        [act(drop),blue,NB,TB],
        state(green,[P1,player(red,NB,Pos),P3,P4],TB)).
%green
placeBar(state(green,[P1,P2,player(green,_,Pos),P4],_),
        [act(drop),blue,NB,TB],
        state(yellow,[P1,P2,player(green,NB,Pos),P4],TB)).

%yellow
placeBar(state(yellow,[P1,P2,P3,player(yellow,_,Pos)],_),
        [act(drop),blue,NB,TB],
        state(blue,[P1,P2,P3,player(yellow,NB,Pos)],TB)).

%do the transition after an action

trans(IS,Action,FS):-
    stateMove(IS,Action,FS).
trans(IS,Action,FS):-
    placeBar(IS,Action,FS).
/* --------------------------------------------------------------------- */
/*                                                                       */
/*                          usefull rules                                */
/*                                                                       */
/* --------------------------------------------------------------------- */

% Put X and Y in a list
pos(X, Y, [X, Y]).

% Get first element of a list.
first([First|_], First).
% Get second element of a list.
second([_,Second|_],Second).
% Get third element of a list.
third([_, _, Third| _], Third).

% Return current player color
currentPlayerColor(state(Color,_,_), Color).

% Return lasting barriers from a player
currentPlayerLastingBarriers(blue,[player(blue,NumberBarrier,_),_,_,_],NumberBarrier).
currentPlayerLastingBarriers(red,[player(red,NumberBarrier,_),_,_,_],NumberBarrier).
currentPlayerLastingBarriers(green,[player(green,NumberBarrier,_),_,_,_],NumberBarrier).
currentPlayerLastingBarriers(yellow,[player(yellow,NumberBarrier,_),_,_,_],NumberBarrier).

%return a player position
currentPlayerPosition(blue, [player(blue,_,Position),_,_,_],Position).
currentPlayerPosition(red, [player(red,_,Position),_,_,_],Position).
currentPlayerPosition(green, [player(green,_,Position),_,_,_],Position).
currentPlayerPosition(yellow, [player(yellow,_,Position),_,_,_],Position).

%return a list from all players positions
allPlayersPosition([player(_,_,Pos1),
                    player(_,_,Pos2),
                    player(_,_,Pos3),
                    player(_,_,Pos4)],[Pos1,Pos2,Pos3,Pos4]).


/* --------------------------------------------------------------------- */
/*                                                                       */
/*                              AI                                       */
/*                                                                       */
/* --------------------------------------------------------------------- */

shortestPath(_,Oi,Of,_,_,[P]):-
    intersection(Oi,Of,I),
    first(I,P),!.
shortestPath(true,Oi,Of,PP,B,[P|PATH]):-
    follower(Oi,PP,B,OFi,PAR),
    shortestPath(false,OFi,Of,PP,B,PATH),
    first(PATH,LINK),
    find_parent(LINK,PAR,P).
shortestPath(false,Oi,Of,PP,B,PATHP):-
    follower(Of,PP,B,OFf,PAR),
    shortestPath(true,Oi,OFf,PP,B,PATH),
    last(PATH,LINK),
    find_parent(LINK,PAR,P),
    append(PATH,[P],PATHP).

follower([],_,_,[],[]).
follower([O|OS],PP,Barrier,OF,PAR):-
    create_ref(CF,O,CPAR),
    follower(OS,PP,Barrier,TF,TPAR),
    append(CF,TF,OF),
    append(CPAR,TPAR,PAR).


% Create a reference map between a list and a variable
% Ex : LS :- [1,2,3]   E :- 5                       
% REF :- [ref(1,5),ref(2,5),ref(3,5)]              
create_ref([],_,[]).
create_ref([X|XS],E,[ref(X,E)|REF]):-
    create_ref(XS,E,REF).


find_parent(C,[ref(C,P)|_],P).
find_parent(C,[ref(H,_)|PARS],T):-
    H \= C,
    find_parent(C,PARS,T).
/* --------------------------------------------------------------------- */
/*                                                                       */
/*             Launch the program                                        */
/*                                                                       */
/* --------------------------------------------------------------------- */
:- start_server.