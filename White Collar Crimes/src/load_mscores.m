function [M, label] = load_mscores(file, sheet, n_years)
%LOAD_MSCORES Read the yearly M-scores of all companies from one sheet.
%
%   [M, label] = load_mscores(file, sheet) reads the sheet and returns
%     M      n_companies-by-9 matrix of M-scores (one column per year)
%     label  the last column of the sheet (e.g. a 0/1 manipulator flag)
%
%   The layout follows the study workbook: one header row, any identifier
%   columns first, then the yearly M-scores, then one final column.
%   Companies with a missing value anywhere are dropped.
%
%   load_mscores(file, sheet, n_years) reads n_years M-score columns
%   instead of 9.

if nargin < 3
    n_years = 9;
end

T = readtable(file, 'Sheet', sheet, 'VariableNamingRule', 'preserve');
T = rmmissing(T);
n_cols = width(T);
M = T{:, n_cols-n_years : n_cols-1};
label = T{:, n_cols};
end
