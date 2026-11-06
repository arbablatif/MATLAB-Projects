function res = battery_task_sim(cfg)
%BATTERY_TASK_SIM Estimate battery state before and after a driving task.
%
%   res = battery_task_sim(cfg) simulates a battery that has already been
%   through a number of charge/discharge cycles at different depths of
%   discharge (DoD), then runs one driving task on it. It returns:
%
%     res.capacity_before   capacity left before the task [%]
%     res.voltage_after     battery voltage at the end of the task [V]
%     res.avg_power         average power drawn during the task [W]
%     res.runtime_left      time until the voltage reaches cfg.v_min [min]
%     res.cycles_left       remaining cycles per DoD (100/80/50) [-]
%     res.capacity_after    capacity per DoD after one more cycle [%]
%
%   plus the intermediate curves used by plot_battery_results.
%
%   Method
%   1. Cycle life. A table gives, for each DoD, how many cycles the battery
%      reaches at 100/90/80/70/60 % capacity. It is spline-interpolated
%      onto a fine capacity grid.
%   2. Usage order. The previous cycles are put in a random order, because
%      in real use the DoD changes from one charge to the next.
%   3. Capacity fade. Each cycle uses up 1/N of the battery's new life,
%      where N is the cycle count at 100 % capacity for that DoD. Once the
%      fractions add up to 1, every further cycle moves the battery one
%      cycle along its DoD curve, which lowers the capacity.
%   4. The task. Voltage-versus-time logs for three traction
%      settings give the voltage at the end of the task. The voltage is
%      then lowered by the capacity lost in step 3.
%
%   Example
%       cfg = battery_default_config();
%       cfg.cycles = [150 150 150];
%       res = battery_task_sim(cfg);
%
%   See also BATTERY_DEFAULT_CONFIG, PLOT_BATTERY_RESULTS, PRINT_BATTERY_REPORT.

arguments
    cfg (1,1) struct = battery_default_config()
end
validate_config(cfg);
S = load(cfg.data_file, 'data_1', 'sc_1', 'sc_2', 'sc_3');

%% 1. Cycle-life curves ---------------------------------------------------
% data_1 columns: [capacity, cycles@DoD100, capacity, cycles@DoD80, capacity, cycles@DoD50]
cap_table  = S.data_1(:,1);
life_table = S.data_1(:,[2 4 6]);
cap_grid   = (max(cap_table):-cfg.capacity_step:min(cap_table))';
life_curves = interp1(cap_table, life_table, cap_grid, 'spline');  % one column per DoD
cycles_new  = life_curves(1,:);   % cycles a new battery reaches at 100 % capacity

%% 2. Random order of previous cycles -------------------------------------
seq = random_dod_sequence(cfg.cycles);
n_cycles = numel(seq);

%% 3. Capacity fade -------------------------------------------------------
% Use up the battery's new life first, then start losing capacity.
used = zeros(1,3);
life_used = 0;
first_fade_cycle = n_cycles + 1;
for k = 1:n_cycles
    used(seq(k)) = used(seq(k)) + 1;
    life_used = sum(used ./ cycles_new);
    if life_used >= 1
        first_fade_cycle = k + 1;
        break
    end
end

capacity = 100;                       % [%]
capacity_history = 100*ones(n_cycles,1);
for i = first_fade_cycle:n_cycles
    curve = life_curves(:, seq(i));
    [~, i_cap] = min(abs(cap_grid - capacity));       % where we are on this DoD curve
    next_cycle = round(curve(i_cap)) + 1;             % move one cycle further
    [~, i_next] = min(abs(curve - next_cycle));
    capacity = cap_grid(i_next);
    capacity_history(i) = capacity;
end

%% 4. Driving task --------------------------------------------------------
scenarios = {S.sc_1, S.sc_2, S.sc_3};
s = find(cfg.traction_levels == cfg.traction);

t_grid = (0:cfg.time_step:cfg.time_max)';
V_curves = zeros(numel(t_grid), numel(scenarios));
for j = 1:numel(scenarios)
    [t, ~, ~, ~, ~, V] = extract_data(scenarios{j});
    V_curves(:,j) = interp1(t, V, t_grid, 'linear', 'extrap');
end

task_time  = cfg.distance_m / (cfg.avg_speed * 60 * cfg.speed_factor);  % [min]
[~, i_t]   = min(abs(t_grid - task_time));
fade_drop  = cfg.nominal_voltage * (1 - capacity/100);   % voltage lost to capacity fade [V]
voltage_after = V_curves(i_t, s) - fade_drop;

drive_time = task_time - cfg.standby_min;
avg_power  = (cfg.standby_min*cfg.standby_power + drive_time*cfg.drive_power(s)) / task_time;

[~, i_vmin]  = min(abs(V_curves(:,s) - cfg.v_min));
runtime_left = t_grid(i_vmin) - task_time;

%% 5. Remaining cycle life ------------------------------------------------
% Cycles left until the end of the table (lowest capacity) for each DoD.
% The "-2" offset is kept from the original model.
cycles_end = life_table(end,:);
if life_used < 1
    cycles_left    = cycles_end - round(life_used .* cycles_new) - 2;
    capacity_after = [100 100 100];
else
    [~, i_cap] = min(abs(cap_grid - capacity));
    cycles_left    = zeros(1,3);
    capacity_after = zeros(1,3);
    for c = 1:3
        prev = round(life_curves(i_cap, c));
        [~, i_next] = min(abs(life_curves(:,c) - (prev + 1)));
        cycles_left(c)    = cycles_end(c) - prev - 2;
        capacity_after(c) = cap_grid(i_next);
    end
end
cycles_left = max(cycles_left, 0);   % a worn-out battery has 0 cycles left, not negative

%% Results ----------------------------------------------------------------
res = struct( ...
    'cfg',              cfg, ...
    'capacity_before',  capacity, ...
    'voltage_after',    voltage_after, ...
    'avg_power',        avg_power, ...
    'runtime_left',     runtime_left, ...
    'cycles_left',      cycles_left, ...
    'capacity_after',   capacity_after, ...
    'task_time',        task_time, ...
    'life_used',        life_used, ...
    'dod_sequence',     seq, ...
    'capacity_history', capacity_history, ...
    'cap_table',        cap_table, ...
    'life_table',       life_table, ...
    'cap_grid',         cap_grid, ...
    'life_curves',      life_curves, ...
    't_grid',           t_grid, ...
    'V_curves',         V_curves);
end

% -------------------------------------------------------------------------
function seq = random_dod_sequence(counts)
%RANDOM_DOD_SEQUENCE Random order of cycles: 1 = DoD100, 2 = DoD80, 3 = DoD50.
% At each step one of the DoD types that still has cycles left is picked
% with equal probability.
remaining = counts(:)';
seq = zeros(sum(remaining), 1);
for k = 1:numel(seq)
    available = find(remaining > 0);
    pick = available(randi(numel(available)));
    seq(k) = pick;
    remaining(pick) = remaining(pick) - 1;
end
end

function validate_config(cfg)
validateattributes(cfg.cycles, {'numeric'}, {'vector', 'numel', 3, 'nonnegative', 'integer'}, '', 'cfg.cycles');
validateattributes(cfg.distance_m, {'numeric'}, {'scalar', 'positive'}, '', 'cfg.distance_m');
validateattributes(cfg.standby_min, {'numeric'}, {'scalar', 'nonnegative'}, '', 'cfg.standby_min');
if ~ismember(cfg.traction, cfg.traction_levels)
    error('battery_task_sim:traction', 'cfg.traction must be one of: %s', mat2str(cfg.traction_levels));
end
task_time = cfg.distance_m / (cfg.avg_speed * 60 * cfg.speed_factor);
if cfg.standby_min > task_time
    error('battery_task_sim:standby', ...
        'Standby time (%.1f min) is longer than the whole task (%.1f min).', cfg.standby_min, task_time);
end
end
