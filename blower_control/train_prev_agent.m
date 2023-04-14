open_system("ev_tms_blower.slx")
%p = parpool(2);
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

x = load('savedAgents/Agent8.mat', 'saved_agent');
agent = x.saved_agent;
agent.AgentOptions.SaveExperienceBufferWithAgent = true;
agent.AgentOptions.ResetExperienceBufferBeforeTraining = false;

agent.AgentOptions.NoiseOptions.StandardDeviation = 0.05;
agent.AgentOptions.NoiseOptions.StandardDeviationDecayRate = 1e-4;
agent.AgentOptions.NoiseOptions.StandardDeviationMin = 0.01;

getAction(agent,{rand(obsInfo.Dimension)})

trainOpts = rlTrainingOptions(...
    MaxEpisodes=200, ...
    MaxStepsPerEpisode=ceil(Tf/Ts), ...
    ScoreAveragingWindowLength=20, ...
    Verbose=false, ...
    SaveAgentCriteria="EpisodeCount",...
    SaveAgentValue=1,...
    SaveAgentDirectory="savedAgents",...
    Plots="training-progress",...
    StopTrainingCriteria="AverageReward",...
    StopTrainingValue=400);

%trainOpts.UseParallel = true;
%trainOpts.ParallelizationOptions.Mode = "async";

trainingStats = train(agent,env,trainOpts);

function in = localResetFcn(in)
run("ev_tms_blower_params.m");
mdlWks = get_param('ev_tms_blower', 'ModelWorkspace');
reload(mdlWks);
end