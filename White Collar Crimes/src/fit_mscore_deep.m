function res = fit_mscore_deep(M, n_in, n_out, opts)
%FIT_MSCORE_DEEP Predict post-IFRS M-scores with a deep (fully connected + LSTM) network.
%
%   res = fit_mscore_deep(M, n_in, n_out) is the deep-learning counterpart
%   of fit_mscore_shallow. The inputs, targets, train/test split and output
%   struct are the same. The architecture is the one used in the original
%   study:
%
%     input -> FC100 -> FC60 -> FC50 -> FC58 -> ReLU -> FC50
%           -> LSTM(200) -> FC100 -> ReLU -> FC(n_out)
%
%   Each company is one sequence of length 1, so the LSTM behaves like a
%   gated fully connected layer.
%
%   15 % of the training companies are used for early stopping, so
%   MaxEpochs is an upper limit.
%
%   Options (name-value):
%     MaxEpochs     maximum training epochs      (default 1500)
%     TestFraction  share of companies held out  (default 0.15)
%
%   Requires Deep Learning Toolbox R2024a or newer (minibatchpredict).
%   Tested on R2025b.

arguments
    M (:,:) double
    n_in (1,1) {mustBePositive, mustBeInteger}
    n_out (1,1) {mustBePositive, mustBeInteger}
    opts.MaxEpochs (1,1) double = 1500
    opts.TestFraction (1,1) double = 0.15
end

X = M(:, 1:n_in);             % companies x pre-IFRS years
Y = M(:, end-n_out+1:end);    % companies x post-IFRS years
[train_idx, test_idx] = split_companies(size(M,1), opts.TestFraction);

layers = [
    sequenceInputLayer(n_in)
    fullyConnectedLayer(100)
    fullyConnectedLayer(60)
    fullyConnectedLayer(50)
    fullyConnectedLayer(58)
    reluLayer
    fullyConnectedLayer(50)
    lstmLayer(200, 'OutputMode', 'last')
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(n_out)];

to_seq = @(A) num2cell(A, 2);   % one 1-by-n_in sequence (1 time step) per company

% Hold back 15 % of the training companies for early stopping: training
% stops once the validation error has not improved for 20 checks, and the
% best network seen on the validation set is kept.
[fit_k, val_k] = split_companies(numel(train_idx), 0.15);
fit_idx = train_idx(fit_k);
val_idx = train_idx(val_k);

options = trainingOptions('adam', ...
    'MaxEpochs', opts.MaxEpochs, ...
    'GradientThreshold', 1, ...
    'ExecutionEnvironment', 'cpu', ...
    'ValidationData', {to_seq(X(val_idx,:)), Y(val_idx,:)}, ...
    'ValidationFrequency', 10, ...
    'ValidationPatience', 20, ...
    'OutputNetwork', 'best-validation', ...
    'Verbose', false, ...
    'Plots', 'none');

net = trainnet(to_seq(X(fit_idx,:)), Y(fit_idx,:), layers, 'mse', options);

pred   = minibatchpredict(net, to_seq(X(test_idx,:)));
actual = Y(test_idx,:);
naive  = repmat(mean(X(test_idx,:), 2), 1, n_out);

% Same orientation as fit_mscore_shallow: years x companies
res.net           = net;
res.actual        = actual';
res.predicted     = pred';
res.rmse          = sqrt(mean((pred(:) - actual(:)).^2));
res.baseline_rmse = sqrt(mean((naive(:) - actual(:)).^2));
res.n_train       = numel(train_idx);
res.n_test        = numel(test_idx);
end
