%% Repeat the model comparison over several random train/test splits
% A single test set has only 9-30 companies, so one split can be lucky or
% unlucky. This script reruns the models with different seeds and reports
% how often each one beats the baseline. Takes several minutes.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'src'));
mscore_file = fullfile(root, 'data', 'synthetic_mscores.xlsx');
ratio_file  = fullfile(root, 'data', 'synthetic_ratios.xlsx');

n_seeds = 10;
n_out = 3;
names = {'All countries', 'Colombia', 'Saudi Arabia', 'UAE'};
sheets = {'Sh1', 'Sh_c', 'Sh_s', 'Sh_u'};
n_pre = [3 3 4 3];
M = cellfun(@(s) load_mscores(mscore_file, s), sheets, 'UniformOutput', false);
R = rmmissing(readtable(ratio_file, 'Sheet', 'Model1', 'VariableNamingRule', 'preserve'));

shallow = zeros(n_seeds, 2);       % [model rmse, baseline rmse]
deep = zeros(n_seeds, 2, 4);
cls = zeros(n_seeds, 2);           % [accuracy, share of manipulators caught]
for seed = 1:n_seeds
    rng(seed);
    r = fit_mscore_shallow(M{1}, n_pre(1), n_out);
    shallow(seed,:) = [r.rmse r.baseline_rmse];
    for g = 1:4
        r = fit_mscore_deep(M{g}, n_pre(g), n_out);
        deep(seed,:,g) = [r.rmse r.baseline_rmse];
    end
    c = classify_manipulators(R{:,1:end-1}, R{:,end});
    cls(seed,:) = [c.accuracy, c.confusion(2,2)/sum(c.confusion(2,:))];
end

fprintf('\n%-10s %-14s %10s %10s %14s\n', 'Model', 'Group', 'RMSE', 'Baseline', 'Beat baseline');
report('Shallow', names{1}, shallow, n_seeds);
for g = 1:4
    report('Deep', names{g}, deep(:,:,g), n_seeds);
end
fprintf('\nClassifier accuracy: mean %.1f %% (range %.1f-%.1f)\n', ...
    100*mean(cls(:,1)), 100*min(cls(:,1)), 100*max(cls(:,1)));
fprintf('Manipulators caught: mean %.1f %% (range %.1f-%.1f)\n', ...
    100*mean(cls(:,2)), 100*min(cls(:,2)), 100*max(cls(:,2)));

function report(model, group, v, n)
fprintf('%-10s %-14s %10.3f %10.3f %9d of %d\n', model, group, ...
    mean(v(:,1)), mean(v(:,2)), sum(v(:,1) < v(:,2)), n);
end
