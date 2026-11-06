%% Example: run the full analysis on synthetic data
% The real study data is confidential and not included. This script
% generates random data with the same layout, runs every model on it,
% prints the results and saves the README figures to figures/.
%
% To use your own data, call run_analysis with your workbook paths:
%   run_analysis('my_mscores.xlsx', 'my_ratios.xlsx', 'figures')

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..');
addpath(fullfile(root, 'src'));

mscore_file = fullfile(root, 'data', 'synthetic_mscores.xlsx');
ratio_file  = fullfile(root, 'data', 'synthetic_ratios.xlsx');
if ~isfile(mscore_file) || ~isfile(ratio_file)
    run(fullfile(root, 'data', 'make_synthetic_data.m'));
end

rng(7);   % fixed train/test split and initial weights
out = run_analysis(mscore_file, ratio_file, fullfile(root, 'figures'));
