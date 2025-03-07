open_system("ev_tms_PID.slx");
open_system("ev_tms_blower.slx");

set_param("ev_tms_PID","StopTime", '600');
set_param("ev_tms_PID","FastRestart","on");
set_param("ev_tms_PID", "FixedStep", '1');
set_param("ev_tms_blower","FastRestart","on");


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

x = load('FinalAgent.mat', 'saved_agent');
agent = x.saved_agent;

simOpts = rlSimulationOptions(MaxSteps=600);

temps = [0 5 10 15 20 25 30 35];

% for i=1:length(temps)
%     % set T_env
%     T_env = temps(i);
%     T_setpoint = 20;
% 
%     % adjust AC based on T_env
%     if T_env > T_setpoint
%         ac_onoff = 1;
%     else
%         ac_onoff = 0;
%     end
% 
%     % reset arrays
%     agent_pwr = [];
%     agent_t_diff = [];
%     pid_pwr = [];
%     pid_t_diff = [];
% 
%     % set PID block parameters
%     set_param('ev_tms_PID/Scenario/Temperature [degC]', 'Value', num2str(T_env));
%     set_param('ev_tms_PID/Scenario/Temperature Setpoint [degC]', 'Value', num2str(T_setpoint));
%     set_param('ev_tms_PID/Scenario/AC OnOff', 'Value', num2str(ac_onoff));
% 
%     % set DDPG Agent block parameters
%     set_param('ev_tms_blower/Scenario/Temperature [degC]', 'Value', num2str(T_env));
%     set_param('ev_tms_blower/Scenario/Temperature Setpoint [degC]', 'Value', num2str(T_setpoint));
%     set_param('ev_tms_blower/Scenario/AC OnOff', 'Value', num2str(ac_onoff));
% 
%     % Sim DDPG Agent
%     agent_exp = sim(env, agent, simOpts);
% 
%     % Get relevant statistics from logs
%     agent_pwr(:,1) = agent_exp.SimulationInfo.logsout{3}.Values.Time; % time vector
%     agent_pwr(:,2) = reshape(agent_exp.SimulationInfo.logsout{3}.Values.Data, length(agent_pwr(:,1)), 1); % instantaneous power
%     total_agent_pwr(i) = trapz(agent_pwr(:,1), agent_pwr(:,2)); % integral approximation
%     agent_t_diff = abs(agent_exp.SimulationInfo.logsout{4}.Values.Data - agent_exp.SimulationInfo.logsout{6}.Values.Data); % temp diff
%     avg_agent_t_diff(i) = sum(agent_t_diff) / length(agent_t_diff); % calculate average
% 
%     % Sim PI controller (I accidentally named it PID)
%     pid_exp = sim('ev_tms_PID');
% 
%     % Get relevant statistics from logs
%     pid_pwr(:,1) = pid_exp.logsout{4}.Values.Time;
%     pid_pwr(:,2) = reshape(pid_exp.logsout{4}.Values.Data, length(pid_pwr(:,1)), 1);
%     total_pid_pwr(i) = trapz(pid_pwr(:,1), pid_pwr(:,2));
%     pid_t_diff = abs(pid_exp.logsout{1}.Values.Data - pid_exp.logsout{3}.Values.Data);
%     avg_pid_t_diff(i) = sum(pid_t_diff) / length(pid_t_diff);
% end
T_env = 25;
T_setpoint = 20;

% adjust AC based on T_env
if T_env > T_setpoint
    ac_onoff = 1;
else
    ac_onoff = 0;
end

% reset arrays
agent_pwr = [];
agent_t_diff = [];
pid_pwr = [];
pid_t_diff = [];

% set PID block parameters
set_param('ev_tms_PID/Scenario/Temperature [degC]', 'Value', num2str(T_env));
set_param('ev_tms_PID/Scenario/Temperature Setpoint [degC]', 'Value', num2str(T_setpoint));
set_param('ev_tms_PID/Scenario/AC OnOff', 'Value', num2str(ac_onoff));

% set DDPG Agent block parameters
set_param('ev_tms_blower/Scenario/Temperature [degC]', 'Value', num2str(T_env));
set_param('ev_tms_blower/Scenario/Temperature Setpoint [degC]', 'Value', num2str(T_setpoint));
set_param('ev_tms_blower/Scenario/AC OnOff', 'Value', num2str(ac_onoff));

% Sim DDPG Agent
agent_exp = sim(env, agent, simOpts);

% Sim PI controller (I accidentally named it PID)
pid_exp = sim('ev_tms_PID');


% Save Statistics
save('total_agent_pwr.mat', 'total_agent_pwr');
save('avg_agent_t_diff.mat', 'avg_agent_t_diff');
save('total_pid_pwr.mat', 'total_pid_pwr');
save('avg_pid_t_diff.mat', 'avg_pid_t_diff');

% agent_temps(:,1) = agent_exp.SimulationInfo.logsout{3}.Values.Time
% agent_temps(:,2) = reshape(agent_exp.SimulationInfo.logsout{4}.Values.Data, length(agent_temps(:,1)), 1)
% agent_temps(:,3) = reshape(agent_exp.SimulationInfo.logsout{5}.Values.Data, length(agent_temps(:,1)), 1);
% agent_temps(:,3) = ones(length(agent_temps(:,1)), 1) * 20
% agent_temps(:,3) = ones(length(agent_temps(:,1)), 1) * 25;
% agent_temps(:,4) = ones(length(agent_temps(:,1)), 1) * 20;
% pid_temps(:,1) = pid_exp.logsout{4}.Values.Time
% pid_temps(:,1) = pid_exp.logsout{1}.Values.Time
% pid_temps(:,1) = reshape(pid_exp.logsout{1}.Values.Data, length(pid_pwr(:,1)), 1);

% figure(1);
% plot(agent_pwr(:,1), agent_pwr(:,2), pid_pwr(:, 1), pid_pwr(:,2), 'LineWidth', 3);
% title('Instantaneous Power [W]')
% legend('DDPG', 'PI')
% xlabel('Time [s]')
% ylabel('Power [W]')

figure(2);
plot(agent_temps(:,1), agent_temps(:,2), pid_temps(:,1), pid_temps(:,2),agent_temps(:,1), agent_temps(:,3), agent_temps(:,1), agent_temps(:,4), 'LineWidth', 2);
title('Temperature Comparison [degC]')
legend('DDPG', 'PI', 'Tenv', 'Tsetpoint')
xlabel('Time [s]')
ylabel('Temperature [degC]') 
ylim([19 26])

function in = localResetFcn(in)
% we are manually changing these variable, don't want them to reset
%run("ev_tms_blower_params.m");
%mdlWks = get_param('ev_tms_blower', 'ModelWorkspace');
%reload(mdlWks);
end


