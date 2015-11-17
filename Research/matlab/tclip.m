function xc = tclip(x,threshhold)

%
% function xc = tclip(x,threshhold)
%
% see p.201, Parson's Voice and Speech Processing
%

xa = abs(x);

xb = (xa > threshhold);

xc = xb.*(xa-threshhold);

