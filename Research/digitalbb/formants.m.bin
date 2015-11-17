function fmnts = formants(x,fs)

%
% function fmnts = formants(x,fs)
%
%   returns a column vector containing the locations
%   of the formants of the speech signal x
%   fs is the sampling frequency of x
%   n is the order of the auto-regressive model
%

n = round(fs/1000) + 2;

w = hamming(length(x));
x = x.*w;


th = ar(x,n)		% auto-regressive model of voice

[b,a] = th2tf(th)	% transfer function of vocal tract

[h,w] = freqz(b,a);	% frequency response of vocal tract

f = w.*fs/(2*pi);

semilogy(f,abs(h))
xlabel('Frequeny (Hz)')
ylabel('log scale frequency response')
title('Auto-Regressive Model of Vocal Tract')
hold on

[floc,fmag] = peaks(abs(h));
allfmnts = f(floc);
semilogy(allfmnts,fmag,'x');

if ( length(allfmnts) < 3 )
	fmnts = fmntest1(b,a,fs);
else
	fmnts = allfmnts(1:3);
end % if

%p = roots(a)

hold off
