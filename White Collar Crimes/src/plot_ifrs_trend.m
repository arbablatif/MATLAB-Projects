function fig = plot_ifrs_trend(groups, years)
%PLOT_IFRS_TREND Mean M-score per year, before and after IFRS adoption.
%
%   fig = plot_ifrs_trend(groups, years) draws one pre-IFRS and one
%   post-IFRS line for each group. groups is a struct array with fields
%     name   label for the legend, e.g. 'Colombia'
%     M      n_companies-by-n_years matrix of M-scores
%     n_pre  number of years before IFRS adoption
%   years is the vector of calendar years (default 2012:2020).
%
%   A falling mean M-score after adoption suggests less earnings
%   manipulation. A value above -1.78 flags a likely manipulator.

if nargin < 2
    years = 2012:2020;
end

fig = figure('Name', 'IFRS trend', 'Color', 'w');
colors = lines(numel(groups));
markers = 'so^vdph*';
hold on
for g = 1:numel(groups)
    G = groups(g);
    pre  = 1:G.n_pre;
    post = G.n_pre+1:numel(years);
    mk = markers(mod(g-1, numel(markers)) + 1);
    plot(years(pre), mean(G.M(:, pre)), ['--' mk], 'LineWidth', 2, 'MarkerSize', 8, ...
        'Color', colors(g,:), 'MarkerFaceColor', 'w', 'DisplayName', ['Pre-IFRS ' G.name]);
    plot(years(post), mean(G.M(:, post)), ['-' mk], 'LineWidth', 2, 'MarkerSize', 8, ...
        'Color', colors(g,:), 'MarkerFaceColor', colors(g,:), 'DisplayName', ['Post-IFRS ' G.name]);
end
yline(-1.78, ':k', 'Manipulation threshold (-1.78)', 'HandleVisibility', 'off', ...
    'LabelHorizontalAlignment', 'left');
hold off
grid on
xlabel('Year')
ylabel('Mean M-score')
title('Mean Beneish M-score before and after IFRS adoption')
legend('Location', 'eastoutside')
set(gca, 'FontSize', 12)
apply_light_theme(fig);
end
