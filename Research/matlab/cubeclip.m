function xc = cubeclib(x)

% cubed signal to suppress low values
% signals normalized to 1 are doubled so that small values
% decrease, large values increase

xa = 2*x;
xc = xa.^3;

% messier than threshhold clip, more computations too
% a threshhold clip should be applied afterwards
