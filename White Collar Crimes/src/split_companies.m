function [train_idx, test_idx] = split_companies(n, test_fraction)
%SPLIT_COMPANIES Random split of n companies into training and test sets.
%
%   The test companies are never seen during training, so the test error
%   shows how well the model generalises to new companies.
order = randperm(n);
n_test = max(1, round(test_fraction * n));
test_idx  = sort(order(1:n_test));
train_idx = sort(order(n_test+1:end));
end
