open_system("ev_tms_PID.slx");
set_param("ev_tms_PID","StopTime", '600');
set_param("ev_tms_PID","FastRestart","on");
set_param("ev_tms_PID", "FixedStep", '1');
open_system("ev_tms_blower.slx");

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

env = rlSimulinkEnv("ev_tms_blower", "ev_tms_blower/RL Agent", obsInfo, actInfo, "UseFastRestart", 'on');

env.ResetFcn = @(in)localResetFcn(in);

Ts = 1;
Tf = 600;
rng(0);

x = load('/Users/rossschrader/Desktop/ML/ME/_Project/savedAgents/blower/Agent385.mat', 'saved_agent');
agent = x.saved_agent;

simOpts = rlSimulationOptions(MaxSteps=600);

temps = [0 5 15 20 25 30 40];

for i=1:length(temps)
    T_env = temps(i);
    T_setpoint = 20;
    if T_env > T_setpoint
        ac_onoff = 1;
    else
        ac_onoff = 0;
    end
    set_param('ev_tms_PID/Scenario/Temperature [degC]', 'Value', num2str(T_env));
    set_param('ev_tms_PID/Scenario/Temperature Setpoint [degC]', 'Value', num2str(T_setpoint));
    set_param('ev_tms_PID/Scenario/AC On_Off', 'Value', num2str(ac_onoff));
    set_param('ev_tms_blower/Scenario/Temperature [degC]', 'Value', num2str(T_env));
    set_param('ev_tms_blower/Scenario/Temperature Setpoint [degC]', 'Value', num2str(T_setpoint));
    set_param('ev_tms_blower/Scenario/AC On_Off', 'Value', num2str(ac_onoff));

    pid_exp = sim('ev_tms_PID');
    pid_T_cabin(:,1) = pid_exp.logsout{1}.Values.Data(:,1);
    rl_exp = sim(env, agent, simOpts);
end


