function apply_light_theme(fig)
%APPLY_LIGHT_THEME Use a white background in MATLAB R2025a+ (no-op on older releases).
if exist('theme', 'file') == 2 || exist('theme', 'builtin') == 5
    theme(fig, 'light');
end
end
