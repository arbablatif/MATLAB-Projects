function figs = plot_battery_results(res)
%PLOT_BATTERY_RESULTS Plot the cycle-life curves, capacity fade and task voltage.
%
%   figs = plot_battery_results(res) draws three figures from the output of
%   battery_task_sim and returns their handles:
%
%     figs(1)  capacity versus cycles for each DoD (input table + spline)
%     figs(2)  capacity over the previous cycles
%     figs(3)  battery voltage versus time for the three traction settings
%
%   See also BATTERY_TASK_SIM.

cfg = res.cfg;
colors = lines(3);
use_light = exist('theme', 'file') == 2 || exist('theme', 'builtin') == 5;  % R2025a+ has themes

%% 1. Cycle-life curves
figs(1) = figure('Name', 'Cycle life', 'Color', 'w');
hold on
step = max(1, floor(numel(res.cap_grid)/2000));   % thin out the dense grid for plotting
for c = 1:3
    plot(res.life_curves(1:step:end, c), res.cap_grid(1:step:end), ...
        'LineWidth', 2, 'Color', colors(c,:), 'DisplayName', cfg.dod_labels{c});
    plot(res.life_table(:, c), res.cap_table, 'o', 'Color', colors(c,:), ...
        'MarkerFaceColor', colors(c,:), 'HandleVisibility', 'off');
end
hold off
grid on
xlabel('Cycles')
ylabel('Capacity [%]')
title('Cycle life per depth of discharge (markers: table values)')
legend('Location', 'southwest')

%% 2. Capacity fade over the previous cycles
figs(2) = figure('Name', 'Capacity fade', 'Color', 'w');
n = numel(res.capacity_history);
if n > 0
    plot(1:n, res.capacity_history, 'LineWidth', 2, 'Color', colors(1,:));
    ylim([min(res.capacity_history) - 2, 102])
    xlim([1, max(n, 2)])
end
grid on
xlabel('Cycle number')
ylabel('Capacity [%]')
title(sprintf('Capacity before the task: %.2f %%', res.capacity_before))

%% 3. Voltage during the task
figs(3) = figure('Name', 'Task voltage', 'Color', 'w');
t_end = min(cfg.time_max, max(res.task_time, 480) * 1.15);
show = res.t_grid <= t_end;
hold on
for j = 1:3
    plot(res.t_grid(show), res.V_curves(show, j), 'LineWidth', 2, 'Color', colors(j,:), ...
        'DisplayName', sprintf('Traction %d (new battery)', cfg.traction_levels(j)));
end
yline(cfg.v_min, '--k', sprintf('V_{min} = %g V', cfg.v_min), 'HandleVisibility', 'off');
xline(res.task_time, ':k', 'End of task', 'HandleVisibility', 'off');
plot(res.task_time, res.voltage_after, 'kp', 'MarkerSize', 14, 'MarkerFaceColor', 'y', ...
    'DisplayName', sprintf('This battery: %.2f V', res.voltage_after));
hold off
grid on
xlabel('Time [min]')
ylabel('Battery voltage [V]')
title('Battery voltage during the task')
legend('Location', 'southwest')

% Always draw on a white background so saved figures look the same everywhere
if use_light
    for f = figs
        theme(f, 'light');
    end
end
end
