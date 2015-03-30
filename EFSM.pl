%% Top Level States
state(dormant).
state(init).
state(idle).
state(monitoring).
state(error_diagnosis).
state(safe_shutdown).

%% Init States
state(boot_hw).
state(senchk).
state(tchk).
state(psichk).
state(ready).

%% Monitoring States
state(monidle).
state(regulate_environment).
state(lockdown).

%% Lockdown States
state(prep_vpurge).
state(alt_temp).
state(alt_psi).
state(risk_assess).
state(safe_status).

%% Error Diagnosis States
state(error_rcv).
state(applicable_rescue).
state(reset_module_data).

%% Initial States
initial_state(dormant, null).
initial_state(boot_hw, init).
initial_state(monidle, monitoring).
initial_state(prep_vpurge, lockdown).
initial_state(error_rcv, error_diagnosis).

%% Superstates
superstate(init, boot_hw).
superstate(init, senchk).
superstate(init, tchk).
superstate(init, psichk).
superstate(init, ready).

superstate(monitoring, monidle).
superstate(monitoring, regulate_environment).
superstate(monitoring, lockdown).

superstate(lockdown, prep_vpurge).
superstate(lockdown, alt_temp).
superstate(lockdown, alt_psi).
superstate(lockdown, risk_assess).
superstate(lockdown, safe_status).

superstate(error_diagnosis, error_rcv).
superstate(error_diagnosis, applicable_rescue).
superstate(error_diagnosis, reset_module_data).


%% Top Level Transitions
transition(dormant, init, start, null, null).
transition(dormant, off, kill, null, null).
transition(init, idle, init_ok, null, null).
transition(init, error_diagnosis, init_crash, null, init_err_msg).
transition(idle, monitoring, begin_monitoring, null, null).
transition(idle, error_diagnosis, idle_crash, null, idle_err_msg).
transition(monitoring, error_diagnosis, monitoring_crash, 'inlockdown == false', moni_err_msg).		%% update monitor transition
transition(error_diagnosis, init, retry_init, 'retry < 3', 'retry++').			%% make increment counter
transition(error_diagnosis, idle, idle_rescue, null, null).
transition(error_diagnosis, monitoring, moni_rescue, null, null).
transition(error_diagnosis, safe_shutdown, shutdown, 'retry >= 3', null).
transition(safe_shutdown, dormant, sleep, null, null).
transition(dormant, dormant, off, null, null).

%% Init Transitions
transition(boot_hw, senchk, hw_ok, null, null).
transition(senchk, tchk, senok, null, null).
transition(tchk, psichk, t_ok, null, null).
transition(psichk, ready, psi_ok, null, null).

%% Monitoring Transitions
transition(monidle, regulate_environment, no_contagion, null, null).
transition(monidle, lockdown, contagion_alert, null, 'FACILITY_CRIT_MESG, inlockdown = true').
transition(regulate_environment, monidle, after_100ms, null, null).
transition(lockdown, monidle, purge_succ, null, 'inlockdown = false').

%% Lockdown Transitions
transition(prep_vpurge, alt_temp, initiate_purge, null, lock_doors).
transition(prep_vpurge, alt_psi, initiate_purge, null, lock_doors).
transition(alt_temp, risk_assess, tcyc_comp, null, null).
transition(alt_psi, risk_assess, psicyc_comp, null, null).
transition(risk_assess, prep_vpurge, null, 'risk >= 0.01', null).
transition(risk_assess, safe_status, null, 'risk < 0.01', unlock_doors).
transition(safe_status, exit, purge_succ, 'inlockdown == false', null).	

%% Error Diagnosis Transitions
transition(error_rcv, applicable_rescue, null, err_protocol_def, null).
transition(error_rcv, reset_module_data, null, 'err_protocol_def == false', null).
transition(applicable_rescue, exit, apply_protocol_rescues, null, null).
transition(reset_module_data, exit, reset_to_stable, null, null).

%% Rules
is_loop(Event, Guard):- transition(Source,Source,Event,Guard,_).
all_loops(Set):- findall([Event,Guard], isLoop(Event, Guard), List), list_to_set(List, Set).
is_edge(Event, Guard):- transition(_,_,Event,Guard,_).
size(Length):-findall([Event,Guard], isEdge(Event,Guard),List), length(List,Length).
is_link(Event, Guard):- isEdge(Event, Guard),not(isLoop(Event, Guard)).
all_superstates(Set):- findall(superstate(Super,Sub),superstate(Super,Sub),List),list_to_set(List, Set).
ancestor(Ancestor, Descendant):- superstate(Ancestor, Descendant).
ancestor(Ancestor, Descendant):- superstate(State,Descendant),ancestor(Ancestor,State).
inherits_transitions(State, List):- ancestor(Superstate,State),findall(transition(Previous,Superstate,Event,Guard,Action1),transition(Previous,Superstate,Event,Guard,Action1),List1),findall(transition(Superstate,Next,Event,Guard,Action2),transition(Superstate,Next,Event,Guard,Action2),List2),append(List1,List2,List).
all_states(L):- findall(state(State),state(State),L).
all_init_states(L):- findall(Init,initial_state(Init,_),L).
get_starting_state(State):- initial_state(State,null).
state_is_reflexive(State):- transition(State,State,_,_,_).
graph_is_reflexive:-findall(state(L),stateIsReflexive(L),List),length(List,L1),size(L2),L1==L2.
get_guards(Ret):- findall(Guard,transition(_,_,_,Guard,_),List1),delete(List1,null,List2),list_to_set(List2,Ret).
get_events(Ret):- findall(Event,transition(_,_,Event,_,_),List1),delete(List1,null,List2),list_to_set(List2,Ret).
get_actions(Ret):- findall(Action,transition(_,_,_,_,Action),List1),delete(List1,null,List2),list_to_set(List2,Ret).
get_only_guarded(Ret):- findall([State1,State2],(transition(State1,State2,_,Guard,_),Guard\=null),Ret).
legal_events_of(State, L):- findall([Event,Guard],(transition(State,_,Event,Guard,_),Event\=null,Guard\=null),L).