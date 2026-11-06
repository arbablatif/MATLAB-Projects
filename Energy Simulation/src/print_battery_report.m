function print_battery_report(res)
%PRINT_BATTERY_REPORT Print the main results of battery_task_sim.
%
%   See also BATTERY_TASK_SIM.

cfg  = res.cfg;
line = repmat('=', 1, 72);

fprintf('%s\n', line);
fprintf('Previous cycles (DoD 100/80/50): %d / %d / %d\n', cfg.cycles);
fprintf('Task: %.0f m, %.0f min standby, traction %d  ->  %.1f min\n', ...
    cfg.distance_m, cfg.standby_min, cfg.traction, res.task_time);
fprintf('%s\n', line);
fprintf('Capacity before the task            %6.2f %%\n', res.capacity_before);
fprintf('Battery voltage after the task      %6.2f V\n', res.voltage_after);
fprintf('Average power during the task       %6.2f W\n', res.avg_power);
if res.runtime_left >= 0
    fprintf('Time left until %.0f V                %6.2f min\n', cfg.v_min, res.runtime_left);
else
    fprintf('Battery reaches %.0f V %.2f min BEFORE the task ends\n', cfg.v_min, -res.runtime_left);
end
fprintf('%s\n', line);
for c = 1:3
    fprintf('%-8s  %5d cycles left, %6.2f %% capacity after the task\n', ...
        cfg.dod_labels{c}, res.cycles_left(c), res.capacity_after(c));
end
fprintf('%s\n', line);
end
