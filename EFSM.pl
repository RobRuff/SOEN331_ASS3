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
transition(dormant, kill, kill, null, null).
transition(init, idle, init_ok, null, null).
transition(init, error_diagnosis, init_crash, null, init_err_msg).
transition(idle, monitoring, begin_monitoring, null, null).
transition(idle, error_diagnosis, idle_crash, null, idle_err_msg).
transition(monitoring, error_diagnosis, monitoring_crash, 'inlockdown == false', moni_err_msg).		%% update monitor transition
transition(error_diagnosis, init, retry_init, 'retry < 3', retry++).			%% make increment counter
transition(error_diagnosis, idle, idle_rescue, null, null).
transition(error_diagnosis, monitoring, moni_rescue, null, null).
transition(error_diagnosis, safe_shutdown, shutdown, 'retry >= 3', null).
transition(safe_shutdown, dormant, sleep, null, null).

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
transition(risk_assess, prep_vpurge, null, 'risk >= 0.01', null): transition(alt_temp, risk_assess, tcyc_comp, null, null), transition(alt_psi, risk_assess, psicyc_comp, null, null).
transition(risk_assess, safe_status, null, 'risk < 0.01', unlock_doors): transition(alt_temp, risk_assess, tcyc_comp, null, null), transition(alt_psi, risk_assess, psicyc_comp, null, null).
transition(safe_status, exit, purge_succ, 'inlockdown == false', null).	

%% Error Diagnosis Transitions
transition(error_rcv, applicable_rescue, null, err_protocol_def, null).
transition(error_rcv, reset_module_data, null, 'err_protocol_def == false', null).
transition(applicable_rescue, exit, apply_protocol_rescues, null, null).
transition(reset_module_data, exit, reset_to_stable, null, null).