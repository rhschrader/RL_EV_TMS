open_system("ev_tms_blower.slx")

obs_dims = [10 1];
low_lim = ones(obs_dims) * -inf;
up_lim = ones(obs_dims) * inf;

obsInfo = rlNumericSpec(obs_dims, ...
    LowerLimit = low_lim, ...
    UpperLimit = up_lim);
obsInfo.Name = "observations";
obsInfo.Description = "p_cond, T_env, T_inverter, T_motor, p_evap, p_chiller, cmd_chiller_bypass, ac_onoff, T_cabin, T_setpoint, T_ptc, T_battery, cmd_comp2, cmd_fan2, I_battery, compressor_pwr, fan_pwr, 1";

actInfo = rlNumericSpec([1 1], LowerLimit = 0.01, UpperLimit = 1);
actInfo.Name = "cmd_blower";

env = rlSimulinkEnv("ev_tms_v4", "ev_tms_v4/RL Agent", obsInfo, actInfo, "UseFastRestart", 'on');

env.ResetFcn = @(in)localResetFcn(in);

Ts = 1;
Tf = 600;
rng(0);

x = load('/Users/rossschrader/Desktop/ML/ME/_Project/_v4/v4_2/Agent36.mat', 'saved_agent');
agent = x.saved_agent;

simOpts = rlSimulationOptions(NumSimulations=20);

experience = sim(env, agent, simOpts);


function in = localResetFcn(in)
run("ev_tms_v4_params.m");
mdlWks = get_param('ev_tms_v4', 'ModelWorkspace');
reload(mdlWks);
end
