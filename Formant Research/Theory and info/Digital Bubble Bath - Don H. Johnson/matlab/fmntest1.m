function fmnts = fmntest1(b,a,fs)

%
% function fmnts = fmntest1(b,a,fs)
%
%	b,a are transfer function coefficients returned by the 
%	autoregressive model in which roots of the transfer function 
%	are too close together to find distinct formant peaks
%
%	method 1 involves making an approximation of each formant based on the
%	angle of the complex roots
%

r1 = roots(a);
r2 = r1(find(angle(r1)>0));

angles = angle(r2);
fmnts = (fs/2)*(angles/pi);


