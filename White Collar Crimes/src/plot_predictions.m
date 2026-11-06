function fig = plot_predictions(results, names, model_name)
%PLOT_PREDICTIONS Predicted vs actual test-set M-scores, one panel per group.
%
%   fig = plot_predictions(results, names, model_name)
%     results     cell array of outputs from fit_mscore_shallow / fit_mscore_deep
%     names       cell array of group names (titles of the panels)
%     model_name  text for the figure title

n = numel(results);
fig = figure('Name', model_name, 'Color', 'w', 'Position', [100 100 max(300*n, 480) 330]);
tl = tiledlayout(1, n, 'TileSpacing', 'compact');
for k = 1:n
    r = results{k};
    nexttile
    scatter(r.actual(:), r.predicted(:), 30, 'filled', 'MarkerFaceAlpha', 0.7);
    lims = [min([r.actual(:); r.predicted(:)]), max([r.actual(:); r.predicted(:)])];
    hold on
    plot(lims, lims, 'k--');
    hold off
    axis equal tight
    grid on
    title(sprintf('%s\nRMSE %.2f (baseline %.2f)', names{k}, r.rmse, r.baseline_rmse), ...
        'FontWeight', 'normal');
    xlabel('Actual M-score')
    if k == 1, ylabel('Predicted M-score'), end
end
title(tl, sprintf('%s: held-out companies', model_name), 'FontWeight', 'bold');
apply_light_theme(fig);
end
