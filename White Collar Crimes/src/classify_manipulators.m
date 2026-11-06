function res = classify_manipulators(X, y, opts)
%CLASSIFY_MANIPULATORS Classify companies as manipulators / non-manipulators.
%
%   res = classify_manipulators(X, y) trains a pattern-recognition network
%   with NO hidden layer (patternnet([])). That is a linear classifier, so
%   its decision can be written out as a single formula, which section 3
%   below does by hand to show that the model is transparent.
%
%     X  n_companies-by-n_features (e.g. the eight Beneish ratios)
%     y  n_companies-by-1 label, 1 = manipulator, 0 = not
%
%   Options (name-value):
%     TestFraction  share of companies held out  (default 0.15)
%
%   Output struct:
%     net, test_idx, y_test, y_pred    network and test-set labels
%     accuracy                         test-set accuracy
%     confusion                        2x2 confusion matrix (rows = actual 0/1)
%     weight, bias                     the linear decision rule (see below)
%     manual_agreement                 share of companies where the hand-written
%                                      rule gives the same class as the network
%
%   Requires Deep Learning Toolbox.

arguments
    X (:,:) double
    y (:,1) double
    opts.TestFraction (1,1) double = 0.15
end

%% 1. Train on the training companies
[train_idx, test_idx] = split_companies(size(X,1), opts.TestFraction);
inputs  = X';
targets = [1 - y'; y'];                 % one-hot: row 1 = clean, row 2 = manipulator

net = patternnet([], 'trainlm');        % no hidden layer -> linear classifier
                                        % (trainlm makes MATLAB switch the loss to mse)
net.divideParam.trainRatio = 0.85;      % of the training companies
net.divideParam.valRatio   = 0.15;      % early stopping
net.divideParam.testRatio  = 0;
net.trainParam.showWindow  = false;
net = train(net, inputs(:, train_idx), targets(:, train_idx));

%% 2. Evaluate on the held-out companies
scores = net(inputs(:, test_idx));
y_pred = double(scores(2,:) > scores(1,:))';
y_test = y(test_idx);

res.net       = net;
res.test_idx  = test_idx;
res.y_test    = y_test;
res.y_pred    = y_pred;
res.accuracy  = mean(y_pred == y_test);
res.confusion = [sum(y_test==0 & y_pred==0), sum(y_test==0 & y_pred==1);
                 sum(y_test==1 & y_pred==0), sum(y_test==1 & y_pred==1)];

%% 3. The same decision written out by hand
% The network scales each input to [-1, 1] (mapminmax), computes
% z = W*x + b for the two classes and applies softmax. A company is a
% manipulator when z(2) > z(1), i.e. when
%       (W(2,:) - W(1,:)) * x_scaled + (b(2) - b(1)) > 0
ps = net.inputs{1}.processSettings;
x_scaled = inputs;
for k = 1:numel(ps)
    x_scaled = feval(net.inputs{1}.processFcns{k}, 'apply', x_scaled, ps{k});
end
W = net.IW{1,1};
b = net.b{1};
res.weight = W(2,:) - W(1,:);
res.bias   = b(2) - b(1);
manual = double(res.weight * x_scaled + res.bias > 0)';

all_scores = net(inputs);
network = double(all_scores(2,:) > all_scores(1,:))';
res.manual_agreement = mean(manual == network);
end
