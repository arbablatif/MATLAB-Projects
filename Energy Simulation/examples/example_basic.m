%% Example: battery state after 450 mixed cycles and one 5 km task
% Run this script from any folder. It adds src/ to the path, runs the
% simulation with fixed inputs, prints the results and saves the figures
% used in the README to figures/.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));

rng(42);   % the order of previous cycles is random; fix it so results repeat

cfg = battery_default_config();
cfg.cycles      = [150 150 150];  % previous cycles at DoD 100 / 80 / 50 %
cfg.distance_m  = 5000;           % task: drive 5 km ...
cfg.standby_min = 30;             % ... including 30 min standing still
cfg.traction    = 100;            % traction setting 0, 100 or 200

res = battery_task_sim(cfg);
print_battery_report(res);

figs = plot_battery_results(res);
names = {'cycle_life.png', 'capacity_fade.png', 'task_voltage.png'};
out_dir = fullfile(here, '..', 'figures');
for k = 1:numel(figs)
    exportgraphics(figs(k), fullfile(out_dir, names{k}), 'Resolution', 150);
end
