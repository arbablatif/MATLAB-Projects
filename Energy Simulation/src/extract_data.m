function [t, P, T, d, s, V] = extract_data(data)
%EXTRACT_DATA Split a drive log into its columns.
%
%   [t, P, T, d, s, V] = extract_data(data) takes an N-by-6 log matrix
%   (sc_1, sc_2 or sc_3 in data/data.mat) and returns:
%
%     t  time                     [min]
%     P  power                    [W]
%     T  temperature              [deg C]
%     d  cumulative distance      [m]
%     s  average speed            [m/s]
%     V  battery voltage          [V]

t = data(:,1);
P = data(:,2);
T = data(:,3);
d = data(:,4);
s = data(:,5);
V = data(:,6);
end
