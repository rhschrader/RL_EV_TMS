open_system("ev_tms_blower.slx")
p = parpool(2);
obs_dims = [11 1];
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

% Observation path
obsPath = [
    featureInputLayer(obsInfo.Dimension(1),Name="obsInputLayer")
    fullyConnectedLayer(100) % was 25 and 10
    reluLayer
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(50, Name="obsPathOutLayer")];

% Action path
actPath = [
    featureInputLayer(actInfo.Dimension(1),Name="actInputLayer")
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(50, Name="actPathOutLayer")];

% Common path
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
plot(criticNetwork)
criticNetwork = dlnetwork(criticNetwork);
%summary(criticNetwork)

critic = rlQValueFunction(criticNetwork, ...
    obsInfo,actInfo, ...
    ObservationInputNames="obsInputLayer", ...
    ActionInputNames="actInputLayer");

getValue(critic, ...
    {rand(obsInfo.Dimension)}, ...
    {rand(actInfo.Dimension)})

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
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(actInfo.Dimension(1))
    tanhLayer
    scalingLayer(Scale = .5, Bias = .5)
    ];

actorNetwork = dlnetwork(actorNetwork);
%summary(actorNetwork)
%plot(actorNetwork)

actor = rlContinuousDeterministicActor(actorNetwork,obsInfo,actInfo);

getAction(actor,{rand(obsInfo.Dimension)})

agent = rlDDPGAgent(actor,critic);
%x = load('/Users/rossschrader/Desktop/ML/ME/_Project/_v4/v4_2/Agent69.mat', 'saved_agent');
%agent = x.saved_agent;

agent.SampleTime = Ts;

agent.AgentOptions.InfoToSave.ExperienceBuffer = true;
agent.AgentOptions.ResetExperienceBufferBeforeTraining = false;

agent.AgentOptions.TargetSmoothFactor = 1e-3;
agent.AgentOptions.DiscountFactor = 0.95; % was 1
agent.AgentOptions.MiniBatchSize = 32;
%agent.AgentOptions.ExperienceBufferLength = 1e6; 

agent.AgentOptions.NoiseOptions.StandardDeviation = 0.1;
agent.AgentOptions.NoiseOptions.StandardDeviationDecayRate = 1e-4;
agent.AgentOptions.NoiseOptions.StandardDeviationMin = .03;

agent.AgentOptions.CriticOptimizerOptions.LearnRate = .001;
agent.AgentOptions.CriticOptimizerOptions.GradientThreshold = 1;
agent.AgentOptions.ActorOptimizerOptions.LearnRate = .001; %was 1e-4
agent.AgentOptions.ActorOptimizerOptions.GradientThreshold = 1;

getAction(agent,{rand(obsInfo.Dimension)})

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

trainOpts.UseParallel = true;
trainOpts.ParallelizationOptions.Mode = "async";
%%% To delete: myCluster = parcluster('Processes'); delete(myCluster.Jobs)

trainingStats = train(agent,env,trainOpts);

function in = localResetFcn(in)
run("ev_tms_blower_params.m");
mdlWks = get_param('ev_tms_blower', 'ModelWorkspace');
reload(mdlWks);
end
