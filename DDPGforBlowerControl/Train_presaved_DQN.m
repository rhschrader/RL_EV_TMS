open_system("ev_tms_blower.slx") % open simulink model

% Observation Info
obs_dims = [10 1];
low_lim = ones(obs_dims) * -inf;
up_lim = ones(obs_dims) * inf;
obsInfo = rlNumericSpec(obs_dims, ...
    LowerLimit = low_lim, ...
    UpperLimit = up_lim);
obsInfo.Name = "observations";
obsInfo.Description = "p_cond, T_env, T_inverter, T_motor, p_evap, p_chiller, cmd_chiller_bypass, ac_onoff, T_cabin, T_setpoint, T_ptc, T_battery, cmd_comp2, cmd_fan2, I_battery, compressor_pwr, fan_pwr, 1";

% Action Info
actInfo = rlFiniteSetSpec([0.01, 0.1, 0.2, 0.3, 0.4, 0.5, 0.7, 0.9, 1.0]);
actInfo.Name = "cmd_blower";

% Create RL environment - this activates the RL Agent block in simulink
% essential to use fast restart
env = rlSimulinkEnv("ev_tms_blower", "ev_tms_blower/RL Agent", obsInfo, actInfo, "UseFastRestart", 'on');
env.ResetFcn = @(in)localResetFcn(in);

Ts = 1; % step size
Tf = 600; % final time - this is set by length of US06 cycle
rng(0); % random number seed

%% -- Load a saved Agent - this will change
x = load('savedAgents/LastAgent.mat', 'saved_agent');
agent = x.saved_agent;
agent.AgentOptions.SaveExperienceBufferWithAgent = true;
agent.AgentOptions.ResetExperienceBufferBeforeTraining = false;

agent.AgentOptions.UseDoubleDQN = true;
agent.AgentOptions.TargetSmoothFactor = 1;
agent.AgentOptions.TargetUpdateFrequency = 4;
agent.AgentOptions.ExperienceBufferLength = 1e5;
agent.AgentOptions.MiniBatchSize = 256;
agent.AgentOptions.CriticOptimizerOptions.LearnRate = 1e-3;
agent.AgentOptions.CriticOptimizerOptions.GradientThreshold = 1;
agent.AgentOptions.EpsilonGreedyExploration.EpsilonDecay = 1e-6;
agent.AgentOptions.EpsilonGreedyExploration.EpsilonMin = 0.2;

% validate agent by getting action
getAction(agent,{rand(obsInfo.Dimension)})

%% --- Training Options ---
% save agent after every episode - this requires lots of memory, but is
% essential since Matlab will crash during training
trainOpts = rlTrainingOptions(...
    MaxEpisodes=1000, ...
    MaxStepsPerEpisode=ceil(Tf/Ts), ...
    ScoreAveragingWindowLength=20, ...
    Verbose=false, ...
    SaveAgentCriteria="EpisodeCount",...
    SaveAgentValue=10,...
    SaveAgentDirectory="savedAgents",...
    Plots="training-progress",...
    StopTrainingCriteria="AverageReward",...
    StopTrainingValue=600);

% --- Uncomment to Use Parallel Computing --- 
%p = parpool(2);
%trainOpts.UseParallel = true;
%trainOpts.ParallelizationOptions.Mode = "async";
%%% To delete: myCluster = parcluster('Processes'); delete(myCluster.Jobs)


%% Perform Training
trainingStats = train(agent,env,trainOpts);


% Reset Function to reset variables between training episodes
function in = localResetFcn(in)
run("ev_tms_blower_params.m"); % randomizes variables
mdlWks = get_param('ev_tms_blower', 'ModelWorkspace');
reload(mdlWks); % reloads the model workspace
end
