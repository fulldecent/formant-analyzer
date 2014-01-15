function fmnts = fmntest2(b,a,fs)

%
% function fmnts = fmntest2(b,a,fs)
%
%	b,a are transfer function coefficients returned by the 
%	autoregressive model in which roots of the transfer function 
%	are too close together to find distinct formant peaks
%
%	Ghael-Sandgathe method:
%	method 2 multiplies the roots by a coefficient which makes the two 
%	formants which are closest together straddle the unit circle,
%	forcing the transfer function to have distinct peaks at each 
%

% create a vector of the poles with positive angles

r1 = roots(a);
r2 = r1(find(imag(r1)>0));

% find the distance between each pair of consecutive poles

for i = 1:length(r2)-1
	dif(i) = abs(r2(i)-r2(i+1));
end % i

% now find the pair of poles that are closest to each other

[m,i] = min(dif);

% now scale the magnitude of each pole so that the two 
% adjacent poles straddle the unit circle

radius1 = abs(r2(i));
radius2 = abs(r2(i+1));

scale = 1/(((radius2-radius1)/2)+radius1);

ra = roots(a)*scale;
rb = roots(b);

% now get the transfer function and find the peaks

[bnew,anew] = zp2tf(rb,ra,1);
[hnew,wnew] = freqz(bnew,anew);
fnew = wnew.*fs/(2*pi);

semilogy(fnew,abs(hnew))
xlabel('Frequeny (Hz)')
ylabel('log scale frequency response')
title('Auto-Regressive Model of Vocal Tract')
hold on

[floc,fmag] = peaks(abs(hnew));
allfmnts = fnew(floc);
semilogy(allfmnts,fmag,'x');
