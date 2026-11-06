function cfg = battery_default_config()
%BATTERY_DEFAULT_CONFIG Default inputs and model constants for battery_task_sim.
%
%   cfg = battery_default_config() returns a struct you can edit before
%   passing it to battery_task_sim. The first block holds the scenario
%   inputs you will usually change; the second holds model constants that
%   describe the battery and the drive logs.
%
%   See also BATTERY_TASK_SIM.

% ---- Scenario inputs ---------------------------------------------------
cfg.cycles      = [0 0 0];  % Charge/discharge cycles already done at DoD [100% 80% 50%]
cfg.distance_m  = 5000;     % Driving distance of the task [m]
cfg.standby_min = 30;       % Standstill (standby) time within the task [min]
cfg.traction    = 0;        % Traction load setting: 0, 100 or 200

% ---- Data --------------------------------------------------------------
cfg.data_file = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'data.mat');

% ---- Battery and vehicle constants -------------------------------------
cfg.nominal_voltage = 52;    % Total battery voltage [V]
cfg.v_min           = 44;    % Minimum usable voltage [V]
cfg.avg_speed       = 0.36;  % Average driving speed during a task [m/s]
cfg.speed_factor    = 0.9;   % Factor on the average speed, kept from the original model

% Average power draw [W] for each traction setting (0, 100, 200)
cfg.traction_levels = [0 100 200];
cfg.standby_power   = 243.5;                    % same for all settings
cfg.drive_power     = [386.28 395.07 408.2];    % while moving

% ---- Numerical settings ------------------------------------------------
cfg.capacity_step = 100/9e5;  % Resolution of the capacity grid [%]
cfg.time_step     = 0.5;      % Resolution of the voltage-time grid [min]
cfg.time_max      = 1360;     % Voltage curves are extrapolated up to this time [min]

cfg.dod_labels = {'DoD 100%', 'DoD 80%', 'DoD 50%'};
end
