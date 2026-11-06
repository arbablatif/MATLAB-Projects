function out = run_analysis(mscore_file, ratio_file, fig_dir, opts)
%RUN_ANALYSIS Run the full M-score / IFRS study and save the figures.
%
%   out = run_analysis(mscore_file, ratio_file, fig_dir) runs:
%     1. the pre/post-IFRS M-score trend for every country
%     2. a shallow network predicting post-IFRS from pre-IFRS M-scores
%     3. the deep (FC + LSTM) network for the same task, per country
%     4. a linear manipulator classifier on the ratio workbook
%   and saves the figures as PNG files in fig_dir (skip with fig_dir = '').
%
%   Expected workbooks (see data/make_synthetic_data.m for the exact layout):
%     mscore_file  sheets Sh1 (all), Sh_c (Colombia), Sh_s (Saudi Arabia),
%                  Sh_u (UAE); yearly M-scores 2012-2020
%     ratio_file   sheet Model1; feature columns then a 0/1 label column
%
%   Option: 'DeepEpochs' (default 1500); lower it for a quick run.

arguments
    mscore_file (1,:) char
    ratio_file (1,:) char
    fig_dir (1,:) char = ''
    opts.DeepEpochs (1,1) double = 1500
end

years = 2012:2020;
n_out = 3;   % predict the last three post-IFRS years
groups = struct( ...
    'name',  {'All countries', 'Colombia', 'Saudi Arabia', 'UAE'}, ...
    'sheet', {'Sh1', 'Sh_c', 'Sh_s', 'Sh_u'}, ...
    'n_pre', {3, 3, 4, 3}, ...   % years before IFRS adoption
    'M',     {[], [], [], []});
for g = 1:numel(groups)
    groups(g).M = load_mscores(mscore_file, groups(g).sheet, numel(years));
end

%% 1. Trend
figs.trend = plot_ifrs_trend(groups(2:end), years);
fprintf('\n%-14s %6s %10s %10s\n', 'Group', 'n', 'pre mean', 'post mean');
for G = groups
    fprintf('%-14s %6d %10.2f %10.2f\n', G.name, size(G.M,1), ...
        mean(G.M(:, 1:G.n_pre), 'all'), mean(G.M(:, G.n_pre+1:end), 'all'));
end

%% 2. Shallow network (all countries)
shallow = fit_mscore_shallow(groups(1).M, groups(1).n_pre, n_out);
fprintf('\nShallow network, all countries: test RMSE %.3f (baseline %.3f), %d test companies\n', ...
    shallow.rmse, shallow.baseline_rmse, shallow.n_test);
figs.shallow = plot_predictions({shallow}, {'All countries'}, 'Shallow network');

%% 3. Deep network per country
deep = cell(1, numel(groups));
fprintf('\nDeep network (test RMSE vs baseline):\n');
for g = 1:numel(groups)
    deep{g} = fit_mscore_deep(groups(g).M, groups(g).n_pre, n_out, 'MaxEpochs', opts.DeepEpochs);
    fprintf('  %-14s %.3f  (%.3f)\n', groups(g).name, deep{g}.rmse, deep{g}.baseline_rmse);
end
figs.deep = plot_predictions(deep, {groups.name}, 'Deep network');

%% 4. Manipulator classifier
R = readtable(ratio_file, 'Sheet', 'Model1', 'VariableNamingRule', 'preserve');
R = rmmissing(R);
cls = classify_manipulators(R{:, 1:end-1}, R{:, end});
fprintf('\nClassifier: test accuracy %.1f %% on %d companies; hand-written rule matches network on %.1f %%\n', ...
    100*cls.accuracy, numel(cls.y_test), 100*cls.manual_agreement);
fprintf('Decision weights (scaled inputs):\n');
names = R.Properties.VariableNames(1:end-1);
for k = 1:numel(names)
    fprintf('  %-6s %+7.3f\n', names{k}, cls.weight(k));
end
fprintf('  bias   %+7.3f\n', cls.bias);

figs.classifier = figure('Name', 'Classifier', 'Color', 'w');
class_names = {'Not manipulator', 'Manipulator'};
to_cat = @(v) categorical(v, [0 1], class_names);   % fixed class order
confusionchart(to_cat(cls.y_test), to_cat(cls.y_pred), ...
    'Title', sprintf('Test-set accuracy %.1f %%', 100*cls.accuracy), ...
    'RowSummary', 'row-normalized');
apply_light_theme(figs.classifier);

%% Save
if ~isempty(fig_dir)
    for name = string(fieldnames(figs))'
        exportgraphics(figs.(name), fullfile(fig_dir, name + ".png"), 'Resolution', 150);
    end
end

out = struct('groups', groups, 'shallow', shallow, 'deep', {deep}, 'classifier', cls, 'figs', figs);
end
