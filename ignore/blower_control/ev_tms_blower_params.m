%% Code to define parameters for sscfluids_ev_thermal_management
% Open Model Workspace in the Model Explorer to view and modify parameter
% values. Click 'Reinitialize from Source' to reset to the parameter values
% in this script.

% Copyright 2020-2021 The MathWorks, Inc.

%% Initial conditions

t_ = [0 5 15 20 25 30 40];
x = randi(length(t_));
T_env = t_(x);
fprintf('\nT_env = %f', T_env);
t_2 = [19 20 21 22];
x2 = randi(length(t_2));
T_setpoint = t_2(x2);
fprintf('\nT_setpoint = %f\n', T_setpoint);
if T_env > T_setpoint
    ac_onoff = 1;
else
    ac_onoff = 0;
end

init_T = 21;%randi([-10 50]); % C
scope_T = 600;

cabin_p_init = 0.101325; % [MPa] Initial air pressure
cabin_T_init = init_T; % [degC] Initial air temperature
cabin_RH_init = 0.4; % Initial relative humidity
cabin_CO2_init = 4e-4; % Initial CO2 mole fraction

coolant_p_init = 0.101325; % [MPa] Initial coolant pressure
coolant_T_init = init_T; % [degC] Initial coolant temperature

refrigerant_p_init = 0.8; % [MPa] Initial refrigerant pressure
refrigerant_alpha_init = 0.6; % Initial refrigerant vapor void fraction

battery_T_init = init_T; % [degC] Initial battery temperature
%fprintf("\n%f \n", battery_T_init);
battery_Qe_init = 0; % [A*hr] Initial charge deficit

%% Vehicle Cabin

cabin_duct_area = 0.04; % [m^2] Air duct cross-sectional area

%% Liquid Coolant System

coolant_pipe_D = 0.019; % [m] Coolant pipe diameter
coolant_channel_D = 0.0092; % [m] Coolant jacket channels diameter

coolant_valve_displacement = 0.0063; % [m] Max spool displacement
coolant_valve_S_max       = 0.0053;  % [m] Spool position when valve is fully shut or open
coolant_valve_D_ratio_max = 0.95;    % Max orifice diameter to pipe diameter ratio
coolant_valve_D_ratio_min = 1e-3;    % Leakage orifice diameter to pipe diameter ratio

pump_displacement = 0.02; % [l/rev] Coolant pump volumetric displacement
pump_speed_max = 1000; % [rpm] Coolant pump max shaft speed

coolant_tank_volume = 5;%2.5 / 2; % [l] Volume of each coolant tank
coolant_tank_area = 0.11^2; % [m^2] Area of one side of coolant tank

%% Refrigeration System

refrigerant_pipe_D = 0.01; % [m] Refrigerant pipe diameter

% Compressor map table
compressor_p_ratio_LUT = [0; 1; 4.28795213348131; 7.57590426696263; 10.8638564004439; 14.1518085339253]; % Pressure ratio
compressor_rpm_LUT = [0, 1800, 3600]; % [rpm] Shaft speed
compressor_mdot_corr_LUT = [
0, 0, 0;
0, 0.0136946156177912, 0.0273892312355827;
0, 0.0102709617133435, 0.0205419234266869;
0, 0.00684730780889566, 0.0136946156177912;
0, 0.00342365390444783, 0.00684730780889563;
0, 0, 0]; % [kg/s] Corrected mass flow rate

%% Radiator

radiator_L = 0.6; % [m] Overall radiator length
radiator_W = 0.015; % [m] Overall radiator width
radiator_H = 0.2; % [m] Overal radiator height
radiator_N_tubes = 25; % Number of coolant tubes
radiator_tube_H = 0.0015; % [m] Height of each coolant tube
radiator_fin_spacing = 0.002; % Fin spacing
radiator_wall_thickness = 1e-4; % [m] Material thickness
radiator_wall_conductivity = 240; % [W/m/K] Material thermal conductivity

radiator_gap_H = (radiator_H - radiator_N_tubes*radiator_tube_H) / (radiator_N_tubes - 1); % [m] Height between coolant tubes
radiator_air_area_flow = (radiator_N_tubes - 1) * radiator_L * radiator_gap_H; % [m^2] Air flow cross-sectional area
radiator_air_area_primary = 2 * (radiator_N_tubes - 1) * radiator_W * (radiator_L + radiator_gap_H); % [m^2] Primary air heat transfer surface area
radiator_N_fins = (radiator_N_tubes - 1) * radiator_L / radiator_fin_spacing; % Total number of fins
radiator_air_area_fins = 2 * radiator_N_fins * radiator_W * radiator_gap_H; % [m^2] Total fin surface area
radiator_tube_Leq = 2*(radiator_H + 20*radiator_tube_H*radiator_N_tubes); % [m] Additional equivalent tube length for losses due to manifold and splits

%% Condenser

condenser_L = 0.63 * 2; % [m] Overall condenser length (2 condensers)
condenser_W = 0.015; % [m] Overall condenser width
condenser_H = 0.39; % [m] Overall condenser height
condenser_N_tubes = 40; % Number of refrigerant tubes
condenser_N_tube_channels = 12; % Number of channels per refrigerant tube
condenser_tube_H = 0.002; % [m] Height of each refrigerant tube
condenser_fin_spacing = 0.0005; % [m] Fin spacing
condenser_wall_thickness = 1e-4; % [m] Material thickness
condenser_wall_conductivity = 240; % [W/m/K] Material thermal conductivity

condenser_gap_H = (condenser_H - condenser_N_tubes*condenser_tube_H) / (condenser_N_tubes - 1); % [m] Height between refrigerant tubes
condenser_air_area_flow = (condenser_N_tubes - 1) * condenser_L * condenser_gap_H; % [m^2] Air flow cross-sectional area
condenser_air_area_primary = 2 * (condenser_N_tubes - 1) * condenser_W * (condenser_L + condenser_gap_H); % [m^2] Primary air heat transfer surface area
condenser_N_fins = (condenser_N_tubes - 1) * condenser_L / condenser_fin_spacing; % Total number of fins
condenser_air_area_fins = 2 * condenser_N_fins * condenser_W * condenser_gap_H; % [m^2] Total fin surface area
condenser_tube_area_webs = 2 * condenser_N_tubes * (condenser_N_tube_channels - 1) * condenser_tube_H * condenser_L; % [m^2] Total surface area of webs in refrigerant tubes
condenser_tube_Leq = 2*(condenser_H + 20*condenser_tube_H*condenser_N_tubes) ...
    + (condenser_N_tube_channels - 1)*condenser_L*condenser_tube_H/(condenser_W + condenser_tube_H); % [m] Additional equivalent tube length for losses due to manifold, splits, and webs

%% Evaporator

evaporator_P_target = 0.3; % MPa
evaporator_L = 0.75; % [m] Overall evaporator length
evaporator_W = 0.015; % [m] Overall evaporator width
evaporator_H = 0.2; % [m] Overall evaporator height
evaporator_N_tubes = 20; % Number of refrigerant tubes
evaporator_N_tube_channels = 12; % Number of channels per refrigerant tube
evaporator_tube_H = 0.002; % [m] Height of each refrigerant tube
evaporator_fin_spacing = 0.0005; % Fin spacing
evaporator_wall_thickness = 1e-4; % [m] Material thickness
evaporator_wall_conductivity = 240; % [W/m/K] Material thermal conductivity

evaporator_gap_H = (evaporator_H - evaporator_N_tubes*evaporator_tube_H) / (evaporator_N_tubes - 1); % [m] Height between refrigerant tubes
evaporator_air_area_flow = (evaporator_N_tubes - 1) * evaporator_L * evaporator_gap_H; % [m^2] Air flow cross-sectional area
evaporator_air_area_primary = 2 * (evaporator_N_tubes - 1) * evaporator_W * (evaporator_L + evaporator_gap_H); % [m^2] Primary air heat transfer surface area
evaporator_N_fins = (evaporator_N_tubes - 1) * evaporator_L / evaporator_fin_spacing; % Total number of fins
evaporator_air_area_fins = 2 * evaporator_N_fins * evaporator_W * evaporator_gap_H; % [m^2] Total fin surface area
evaporator_tube_area_webs = 2 * evaporator_N_tubes * (evaporator_N_tube_channels - 1) * evaporator_L * evaporator_tube_H; % [m^2] Total surface area of webs in refrigerant tubes
evaporator_tube_Leq = 2*(evaporator_H + 20*evaporator_tube_H*evaporator_N_tubes); ...
    + (evaporator_N_tube_channels - 1)*evaporator_L*evaporator_tube_H/(evaporator_W + evaporator_tube_H); % [m] Additional equivalent tube length for losses due to manifold, splits, and webs

%% Chiller

chiller_N_tubes = 100; % Number of refrigerant tubes
chiller_tube_L = 0.4; % [m] Length of each refrigerant tube
chiller_tube_D = 0.0035; % [m] Diameter of each refrigerant tube
chiller_wall_thickness = 1e-4; % [m] Material thickness
chiller_wall_conductivity = 240; % [W/m/K] Material thermal conductivity
chiller_N_baffles = 3; % Number of coolant baffles

chiller_area_primary = chiller_N_tubes * pi * chiller_tube_D * chiller_tube_L; % [m^2] Primary heat transfer surface area
chiller_area_baffles = chiller_N_baffles * 0.7 * 2 * chiller_N_tubes*((2*chiller_tube_D)^2 - pi*chiller_tube_D^2/4); % [m^2] Total surface area of coolant baffles
chiller_tube_Leq = 2*0.2*chiller_tube_D*chiller_N_tubes; % [m] Additonal equivalent tube length for losses due to manifold and splits.

%% Batteries

battery_N_cells = 20; % Number of cells per pack
battery_cell_mass = 2.5; % [kg] Cell mass
battery_cell_cp = 795; % [J/kg/K] Cell specific heat

battery_SOC_LUT = [0 0.1 0.25 0.5 0.75 0.9 1]'; % [Ohm] State of charge table breakpoints
battery_temperature_LUT = [5 20 40]; % [degC] Temperature table breakpoints
battery_capacity_LUT = [28.0081 27.6250 27.6392]; % [A*hr] Battery capacity
battery_Em_LUT = [
    3.4966    3.5057    3.5148
    3.5519    3.5660    3.5653
    3.6183    3.6337    3.6402
    3.7066    3.7127    3.7213
    3.9131    3.9259    3.9376
    4.0748    4.0777    4.0821
    4.1923    4.1928    4.1930]; % [V] Em open-circuit voltage vs SOC rows and T columns
battery_R0_LUT = [
    0.0117    0.0085    0.0090
    0.0110    0.0085    0.0090
    0.0114    0.0087    0.0092
    0.0107    0.0082    0.0088
    0.0107    0.0083    0.0091
    0.0113    0.0085    0.0089
    0.0116    0.0085    0.0089]; % [Ohm] R0 resistance vs SOC rows and T columns
battery_R1_LUT = [
    0.0109    0.0029    0.0013
    0.0069    0.0024    0.0012
    0.0047    0.0026    0.0013
    0.0034    0.0016    0.0010
    0.0033    0.0023    0.0014
    0.0033    0.0018    0.0011
    0.0028    0.0017    0.0011]; % [Ohm] R1 Resistance vs SOC rows and T columns
battery_C1_LUT = [
    1913.6    12447    30609
    4625.7    18872    32995
    23306     40764    47535
    10736     18721    26325
    18036     33630    48274
    12251     18360    26839
    9022.9    23394    30606]; % [F] C1 Capacitance vs SOC rows and T columns