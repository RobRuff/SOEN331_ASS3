%% Rules

is_loop(Event, Guard):- transition(Source,Source,Event,Guard,_).
all_loops(Set):- findall([Event,Guard], is_loop(Event, Guard), List), list_to_set(List, Set).

is_edge(Event, Guard):- transition(_,_,Event,Guard,_).
size(Length):-findall([Event,Guard], is_edge(Event,Guard),List), length(List,Length).

is_link(Event, Guard):- is_edge(Event, Guard),not(isLoop(Event, Guard)).
all_superstates(Set):- findall(superstate(Super,Sub),superstate(Super,Sub),List),list_to_set(List, Set).

ancestor(Ancestor, Descendant):- superstate(Ancestor, Descendant).
ancestor(Ancestor, Descendant):- superstate(State,Descendant),ancestor(Ancestor,State).

inherits_transitions(State,[]):- not(superstate(_,State)).
inherits_transitions(State, List):- superstate(Superstate,State),findall(transition(Previous,Superstate,Event,Guard,Action1),transition(Previous,Superstate,Event,Guard,Action1),List1),findall(transition(Superstate,Next,Event,Guard,Action2),transition(Superstate,Next,Event,Guard,Action2),List2),append(List1,List2,List3),inherits_transitions(Superstate,List4),append(List3,List4,List).

all_states(L):- findall(state(State),state(State),L).
all_init_states(L):- findall(Init,initial_state(Init,_),L).
get_starting_state(State):- initial_state(State,null).

state_is_reflexive(State):- transition(State,State,_,_,_).
graph_is_reflexive:-findall(state(L),state_is_reflexive(L),List1),findall(state(S),state(S),List2),List1==List2.

get_guards(Ret):- findall(Guard,transition(_,_,_,Guard,_),List1),delete(List1,null,List2),list_to_set(List2,Ret).
get_events(Ret):- findall(Event,transition(_,_,Event,_,_),List1),delete(List1,null,List2),list_to_set(List2,Ret).
get_actions(Ret):- findall(Action,transition(_,_,_,_,Action),List1),delete(List1,null,List2),list_to_set(List2,Ret).
get_only_guarded(Ret):- findall([State1,State2],(transition(State1,State2,_,Guard,_),Guard\=null),Ret).
legal_events_of(State, L):- findall([Event,Guard],(transition(State,_,Event,Guard,_),Event\=null,Guard\=null),L).