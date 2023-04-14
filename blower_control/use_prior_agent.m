open_system("ev_tms_blower.slx")
p = parpool(2);
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

x = load('/Users/rossschrader/Desktop/ML/ME/_Project/savedAgents/blower/Agent36.mat', 'saved_agent');
agent = x.saved_agent;

% agent.SampleTime = Ts;
% 
% agent.AgentOptions.TargetSmoothFactor = 1e-3;
% agent.AgentOptions.DiscountFactor = 0.95; % was 1
% agent.AgentOptions.MiniBatchSize = 32;
% %agent.AgentOptions.ExperienceBufferLength = 1e6; 
% 
% agent.AgentOptions.NoiseOptions.Variance = 0.1;
% agent.AgentOptions.NoiseOptions.VarianceDecayRate = 0;
% %agent.AgentOptions.NoiseOptions.Mean = 0;
% 
% agent.AgentOptions.CriticOptimizerOptions.LearnRate = .0001;
% agent.AgentOptions.CriticOptimizerOptions.GradientThreshold = 1;
% agent.AgentOptions.ActorOptimizerOptions.LearnRate = .0001; %was 1e-4
% agent.AgentOptions.ActorOptimizerOptions.GradientThreshold = 1;

getAction(agent,{rand(obsInfo.Dimension)})

trainOpts = rlTrainingOptions(...
    MaxEpisodes=200, ...
    MaxStepsPerEpisode=ceil(Tf/Ts), ...
    ScoreAveragingWindowLength=20, ...
    Verbose=false, ...
    SaveAgentCriteria="EpisodeCount",...
    SaveAgentValue=1,...
    SaveAgentDirectory="/Users/rossschrader/Desktop/ML/ME/_Project/savedAgents/blower/36plus",...
    UseParallel=true,...
    Plots="training-progress",...
    StopTrainingCriteria="AverageReward",...
    StopTrainingValue=6000);

trainOpts.ParallelizationOptions.Mode = "async";

trainingStats = train(agent,env,trainOpts);

function in = localResetFcn(in)
run("ev_tms_blower_params.m");
mdlWks = get_param('ev_tms_blower', 'ModelWorkspace');
reload(mdlWks);
end