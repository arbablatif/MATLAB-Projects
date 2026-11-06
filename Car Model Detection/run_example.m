%% Example: run the V2 classifier on the saved features
% Trains the classifiers for one target car (Honda City 2012) from the
% feature files in V2/Features, prints the accuracy table and saves a
% summary chart to figures/v2_results.png. No images are needed.
%
% Requires Statistics and Machine Learning Toolbox.

cd(fullfile(fileparts(mfilename('fullpath')), 'V2'));
rng(1);                 % the train/test sampling is random
Classification_Auto
