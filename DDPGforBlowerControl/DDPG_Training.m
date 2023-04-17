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
actInfo = rlNumericSpec([1 1], LowerLimit = 0.01, UpperLimit = 1);
actInfo.Name = "cmd_blower";

% Create RL environment - this activates the RL Agent block in simulink
% essential to use fast restart
env = rlSimulinkEnv("ev_tms_blower", "ev_tms_blower/RL Agent", obsInfo, actInfo, "UseFastRestart", 'on');
env.ResetFcn = @(in)localResetFcn(in);

Ts = 1; % step size
Tf = 600; % final time - this is set by length of US06 cycle
rng(0); % random number seed

%% --- Critic Network ---

% Observation DNN path
obsPath = [
    featureInputLayer(obsInfo.Dimension(1),Name="obsInputLayer")
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(25, Name="obsPathOutLayer")];

% Action DNN path
actPath = [
    featureInputLayer(actInfo.Dimension(1),Name="actInputLayer")
    fullyConnectedLayer(100)
    tanhLayer
    fullyConnectedLayer(100)
    tanhLayer
    fullyConnectedLayer(25, Name="actPathOutLayer")];

% Common DNN path
commonPath = [
    additionLayer(2,Name="add")
    tanhLayer
    fullyConnectedLayer(25)
    tanhLayer
    fullyConnectedLayer(1,Name="CriticOutput")];

criticNetwork = layerGraph();
criticNetwork = addLayers(criticNetwork,obsPath);
criticNetwork = addLayers(criticNetwork,actPath);
criticNetwork = addLayers(criticNetwork,commonPath);

criticNetwork = connectLayers(criticNetwork, ...
    "obsPathOutLayer","add/in1");
criticNetwork = connectLayers(criticNetwork, ...
    "actPathOutLayer","add/in2");

figure
plot(criticNetwork) % show structure
criticNetwork = dlnetwork(criticNetwork); % activate dlnetwork
%summary(criticNetwork)

% Activate as Q-Value Function
critic = rlQValueFunction(criticNetwork, ...
    obsInfo,actInfo, ...
    ObservationInputNames="obsInputLayer", ...
    ActionInputNames="actInputLayer");

% Get random value to validate it works
getValue(critic, ...
    {rand(obsInfo.Dimension)}, ...
    {rand(actInfo.Dimension)})

%% --- Actor Network ---

actorNetwork = [
    featureInputLayer(obsInfo.Dimension(1))
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(actInfo.Dimension(1))
    tanhLayer
    scalingLayer(Scale = .5, Bias = .5) % scale -1,1 to 0,1
    ];

actorNetwork = dlnetwork(actorNetwork);
%summary(actorNetwork)
%plot(actorNetwork) % show structure

% activate actor
actor = rlContinuousDeterministicActor(actorNetwork,obsInfo,actInfo);

% get random action as validation
getAction(actor,{rand(obsInfo.Dimension)})

%% --- DDPG Agent ---

% create agent object with actor and critic network
agent = rlDDPGAgent(actor,critic);

agent.SampleTime = Ts; % time step

agent.AgentOptions.InfoToSave.ExperienceBuffer = true; % save experience buffer so training can continue
agent.AgentOptions.ResetExperienceBufferBeforeTraining = false; % do not reset experience buffer

agent.AgentOptions.TargetSmoothFactor = 1e-3;
agent.AgentOptions.DiscountFactor = 0.95;
agent.AgentOptions.MiniBatchSize = 32;

% Ornstein–Uhlenbeck Noise Object - this is to encourage exploration
agent.AgentOptions.NoiseOptions.StandardDeviation = 0.09; % should be 1-10% of action space
agent.AgentOptions.NoiseOptions.StandardDeviationDecayRate = 1e-4; %halflife = log(0.5)/log(1-DecayRate)
agent.AgentOptions.NoiseOptions.StandardDeviationMin = .02; % min to still promote exploration

agent.AgentOptions.CriticOptimizerOptions.LearnRate = .001;
agent.AgentOptions.CriticOptimizerOptions.GradientThreshold = 1;
agent.AgentOptions.ActorOptimizerOptions.LearnRate = .001;
agent.AgentOptions.ActorOptimizerOptions.GradientThreshold = 1;

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
    SaveAgentValue=1,...
    SaveAgentDirectory="savedAgents",...
    Plots="training-progress",...
    StopTrainingCriteria="AverageReward",...
    StopTrainingValue=400);

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
