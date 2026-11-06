function res = fit_mscore_shallow(M, n_in, n_out, opts)
%FIT_MSCORE_SHALLOW Predict post-IFRS M-scores from pre-IFRS M-scores (fitnet).
%
%   res = fit_mscore_shallow(M, n_in, n_out) trains a one-hidden-layer
%   feed-forward network that takes a company's first n_in yearly M-scores
%   (pre-IFRS) and predicts its last n_out yearly M-scores (post-IFRS).
%
%   Companies are split into a training set and a held-out test set. The
%   reported error is measured on the test companies only.
%
%   Options (name-value):
%     HiddenSize    neurons in the hidden layer        (default 10)
%     TestFraction  share of companies held out        (default 0.15)
%     TrainFcn      training algorithm                 (default 'trainlm')
%
%   Output struct:
%     net, actual, predicted   network and test-set targets/predictions
%     rmse                     test RMSE of the network
%     baseline_rmse            test RMSE when every post year is predicted
%                              as the company's own pre-IFRS mean
%
%   Requires Deep Learning Toolbox.

arguments
    M (:,:) double
    n_in (1,1) {mustBePositive, mustBeInteger}
    n_out (1,1) {mustBePositive, mustBeInteger}
    opts.HiddenSize (1,:) double = 10
    opts.TestFraction (1,1) double = 0.15
    opts.TrainFcn (1,:) char = 'trainlm'
end

X = M(:, 1:n_in)';            % inputs:  pre-IFRS years  (features x companies)
Y = M(:, end-n_out+1:end)';   % targets: last post-IFRS years
[train_idx, test_idx] = split_companies(size(M,1), opts.TestFraction);

net = fitnet(opts.HiddenSize, opts.TrainFcn);
net.divideParam.trainRatio = 0.85;   % of the training companies; the rest
net.divideParam.valRatio   = 0.15;   % is used for early stopping
net.divideParam.testRatio  = 0;
net.trainParam.showWindow  = false;
net = train(net, X(:, train_idx), Y(:, train_idx));

pred   = net(X(:, test_idx));
actual = Y(:, test_idx);
naive  = repmat(mean(X(:, test_idx), 1), n_out, 1);

res.net           = net;
res.actual        = actual;
res.predicted     = pred;
res.rmse          = sqrt(mean((pred(:) - actual(:)).^2));
res.baseline_rmse = sqrt(mean((naive(:) - actual(:)).^2));
res.n_train       = numel(train_idx);
res.n_test        = numel(test_idx);
end
