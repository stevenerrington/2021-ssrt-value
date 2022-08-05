
%% Setup workspace
% Clear workspace and console.
close all; clear all; clc; warning off;

% Define data directories
getDirs_value;
dajo_metadata = load(fullfile(dirs.procData,'2021dajo_metadata.mat')); % 2021 dataset metadata
eux_metadata = load(fullfile(dirs.procData,'2012eux_data.mat'));

% Load in pre-processed data
load(fullfile(dirs.procData,'valuedata_curated.mat'));

% Define global model parameters
nModel_iter = 20; % Number of times to run model fit
nSim_iter = 1000; % Number of trials in simulation of model fit parameters
getColor_value

% Set seed for reproducability
rng(1) 


%% Setup data
session_i = 1;
fprintf(['Running model comparison for session %i of %i | ' valuedata_master.session{session_i} ' \n'],session_i,size(valuedata_master,1))

% Input RT from master table and configure data for use with the LBA analysis
clear model_input

model_input.rt_obs.lo = valuedata_master.valueRTdist(session_i).lo.nostop(:,1);
model_input.rt_obs.hi = valuedata_master.valueRTdist(session_i).hi.nostop(:,1);
model_input.data.rt = [model_input.rt_obs.lo;model_input.rt_obs.hi];
model_input.data.cond = [ones(length(model_input.rt_obs.lo),1);ones(length(model_input.rt_obs.hi),1)*2];
model_input.data.correct = ones(length(model_input.data.cond),1);
model_input.data.stim = ones(length(model_input.data.cond),1);
model_input.data.response = ones(length(model_input.data.cond),1);

%% Setup models (see help LBA_mle)

%{
###############################################################
LBA parameter defintions
    v: Drift rate
    A: Start point (upper end)
    b: Response threshold
    t0: Non-decision time
    sv: Standard deviation of drift rate samples

###############################################################
*** Model combinations

1) Null model: all factors fixed
2) Threshold model: all but threshold fixed
3) Rate model: all but rate fixed
4) Onset model: all but onset fixed
5) Start model: all but start point fixed
7) Rate SD model: all but standard deviation of the drift rate fixed

###############################################################
*** Info
Parameters are

###############################################################
%}
clear model init_params

model_labels = {'null','threshold','rate','onset','start','rate_sd'};

% Default parameters
param_def.v = 0.6;
param_def.A = 30;
param_def.b = 120;
param_def.t0 = 100;
param_def.sv = 0.8;

% Model 1 (Null model) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model_i = 1; model_label = 'null';
model(model_i).v = 1; 
model(model_i).A = 1; 
model(model_i).b = 1; 
model(model_i).t0 = 1; 
model(model_i).sv = 1;

init_params{model_i} = [param_def.v param_def.A param_def.b param_def.t0 param_def.sv];

% Model 2 (Threshold model) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model_i = 2; model_label = 'all';
model(model_i).v = 1; 
model(model_i).A = 2; 
model(model_i).b = 1; 
model(model_i).t0 = 1; 
model(model_i).sv = 1;

init_params{model_i} = ...
    [param_def.v, param_def.A, param_def.A, param_def.b, param_def.t0, param_def.sv] ;


%% Run model
% Model 1: null model
model_i = 2; 

% Run each model 20 times, each with a different starting point. With this,
% it allows for reliability - we start the optimization in different spots
% based within 5 x +/- the defined starting parameters.
for model_iter_i = 1:nModel_iter
    fprintf(['Running model iteration %i of %i | \n'],model_iter_i,nModel_iter)
    
    % Get the initial defined parameters (as done above)
    model_standard_params = init_params{model_i};
    
    % For each parameter
    for param_i = 1:length(model_standard_params)
        clear lower_bound upper_bound
        % Define a boundary - starting point must be 5 x more or less than
        % the defined boundary set above.
        lower_bound =  model_standard_params(param_i)/5;
        upper_bound =  model_standard_params(param_i)*5;
        
        % We then choose a random point between these two bounds as our
        % start point.
        param_rand_start(model_iter_i,param_i) =...
            lower_bound + (upper_bound-lower_bound) .* rand(1,1);        
    end

    % We then run the optimization script, getting the fit parameters
    % (params) and log Likelihood (logLikelihood) for the current iteration.
    [params{model_i}(model_iter_i,:), logLikelihood(model_iter_i,model_i)] =....
        LBA_mle(model_input.data, model(model_i), param_rand_start(model_iter_i,:));
end

%% Simulated data based on model parameters

for model_iter_i = 1:nModel_iter
    
    clear v A b sv t0
    [v, A, b, sv, t0] = LBA_parse(model(model_i), params{model_i}(model_iter_i,:), 2);
    
    clear  model_sim
    for trl_iter_i = 1:nSim_iter
        model_sim.sim_RT(trl_iter_i,:) = LBA_trial_RT(A, b, v, t0, sv, 2);
    end
    
    clear cdf_plot
    cdf_plot.lo.obs = cumulDist(model_input.rt_obs.lo); cdf_plot.lo.sim = cumulDist(model_sim.sim_RT(:,1));
    cdf_plot.hi.obs = cumulDist(model_input.rt_obs.hi); cdf_plot.hi.sim = cumulDist(model_sim.sim_RT(:,2));
    
    
    figure('Renderer', 'painters', 'Position', [100 100 300 600]);
    subplot(2,1,1); hold on
    plot(cdf_plot.lo.obs(:,1),cdf_plot.lo.obs(:,2),'-','color',colors.lo,'LineWidth',1.5)
    plot(cdf_plot.lo.sim(:,1),cdf_plot.lo.sim(:,2),'--','color',colors.lo,'LineWidth',0.5)
    xlim([0 600]); ylabel('CDF')
    
    subplot(2,1,2); hold on
    plot(cdf_plot.hi.obs(:,1),cdf_plot.hi.obs(:,2),'-','color',colors.hi,'LineWidth',1.5)
    plot(cdf_plot.hi.sim(:,1),cdf_plot.hi.sim(:,2),'--','color',colors.hi,'LineWidth',0.5)
    xlim([0 600]); xlabel('Response Latency (ms)'); ylabel('CDF')

end




