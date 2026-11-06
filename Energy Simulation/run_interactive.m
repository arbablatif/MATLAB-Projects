%% Interactive battery task simulation
% Asks for the previous cycles and the task in the Command Window, then
% runs battery_task_sim and shows the results.
% For a non-interactive run, see examples/example_basic.m.

clear; clc; close all;
addpath(fullfile(fileparts(mfilename('fullpath')), 'src'));

cfg = battery_default_config();

% Previous charge/discharge cycles at each depth of discharge
cfg.cycles(1) = input('Cycles already done at 100% DoD: ');
cfg.cycles(2) = input('Cycles already done at  80% DoD: ');
cfg.cycles(3) = input('Cycles already done at  50% DoD: ');

% The driving task
cfg.distance_m  = input('Driving distance [m]: ');
cfg.standby_min = input('Standby time [min]: ');
cfg.traction    = input('Traction (0/100/200): ');

res = battery_task_sim(cfg);
print_battery_report(res);
plot_battery_results(res);
