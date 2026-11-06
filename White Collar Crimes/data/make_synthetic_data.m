function make_synthetic_data(out_dir)
%MAKE_SYNTHETIC_DATA Create example input files with the same layout as the study data.
%
%   make_synthetic_data(out_dir) writes two Excel files into out_dir
%   (default: the folder of this file):
%
%   synthetic_mscores.xlsx  Beneish M-scores for 2012-2020, one sheet per group:
%                             Sh1  all countries
%                             Sh_c Colombia
%                             Sh_s Saudi Arabia
%                             Sh_u United Arab Emirates
%                           Columns: Company, Country, M2012 ... M2020, Manipulator
%
%   synthetic_ratios.xlsx   Sheet Model1: the eight Beneish ratios per company
%                           plus a 0/1 Manipulator label.
%
%   The numbers are RANDOM. The M-score workbook follows the sheet and
%   column layout the code expects, so that it can be run and tested. The
%   ratio workbook's feature columns are an illustrative choice.

if nargin < 1
    out_dir = fileparts(mfilename('fullpath'));
end
rng(2023);   % same files every time

years = 2012:2020;
countries = struct( ...
    'name',  {'Colombia', 'Saudi Arabia', 'United Arab Emirates'}, ...
    'sheet', {'Sh_c', 'Sh_s', 'Sh_u'}, ...
    'n',     {60, 80, 60}, ...         % number of companies
    'ifrs',  {2015, 2016, 2015}, ...   % first post-IFRS year (matches the original analysis split)
    'shift', {-0.35, -0.25, -0.15});   % change in mean M-score after IFRS

%% M-score panels
mscore_file = fullfile(out_dir, 'synthetic_mscores.xlsx');
if isfile(mscore_file), delete(mscore_file); end
all_rows = table();
for c = countries
    base  = -2.4 + 0.5*randn(c.n, 1);                 % company-specific level
    trend = 0.04*randn(c.n, 1) .* (years - years(1)); % slow company-specific drift
    post  = years >= c.ifrs;
    M = base + trend + c.shift*post + 0.25*randn(c.n, numel(years));

    T = table(compose("%s_%03d", erase(string(c.sheet), "Sh_"), (1:c.n)'), ...
        repmat(string(c.name), c.n, 1), 'VariableNames', {'Company', 'Country'});
    T = [T, array2table(round(M, 3), 'VariableNames', compose("M%d", years))]; %#ok<AGROW>
    T.Manipulator = double(mean(M(:, post), 2) > -1.78);   % Beneish threshold
    writetable(T, mscore_file, 'Sheet', c.sheet);
    all_rows = [all_rows; T]; %#ok<AGROW>
end
writetable(all_rows, mscore_file, 'Sheet', 'Sh1');

%% Beneish ratios for the classifier
n = 400;
ratios = { ...  name    mean   sd
    'DSRI', 1.05, 0.25;   % days sales in receivables index
    'GMI',  1.02, 0.20;   % gross margin index
    'AQI',  1.02, 0.30;   % asset quality index
    'SGI',  1.15, 0.25;   % sales growth index
    'DEPI', 1.00, 0.15;   % depreciation index
    'SGAI', 1.03, 0.20;   % SG&A expenses index
    'LVGI', 1.03, 0.20;   % leverage index
    'TATA', 0.02, 0.06};  % total accruals to total assets
X = zeros(n, size(ratios, 1));
for k = 1:size(ratios, 1)
    X(:, k) = ratios{k, 2} + ratios{k, 3}*randn(n, 1);
end
% Beneish (1999) 8-variable M-score, plus noise for realism
w = [0.920 0.528 0.404 0.892 0.115 -0.172 -0.327 4.679];
M = -4.84 + X*w' + 0.3*randn(n, 1);

R = array2table(round(X, 4), 'VariableNames', ratios(:, 1)');
R.Manipulator = double(M > -1.78);
ratio_file = fullfile(out_dir, 'synthetic_ratios.xlsx');
if isfile(ratio_file), delete(ratio_file); end
writetable(R, ratio_file, 'Sheet', 'Model1');

fprintf('Wrote %s\n      %s\n', mscore_file, ratio_file);
end
