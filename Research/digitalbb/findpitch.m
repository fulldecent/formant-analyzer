function p = findpitch(data,fs)

%
% function p = findpitch(data,fs)
%
%	data is a (preferably) periodic vowel speech signal
%	fs is the sampling frequency
%
%	output is the fundamental pitch frequency
%

% first remove the signal below a threshhold of .5

clipped = cubeclip(data);
clipped2 = tclip(clipped,.4*max(clipped));

% next the data is put through a weighted moving average filter
% to smooth out jagged peaks (which would be read as multiple
% peaks by the peak-finding function)

smoothed = conv(clipped2,[.05 .1 .2 .3 .2 .1 .05]);

% now find the location of the remaining local maxima

[p,m] = peaks(smoothed);

% calculate the distance between each successive pair of peaks

for i = 1:(length(p)-1)
	d(i) = p(i+1) - p(i);
end % i

% assuming that the signal is periodic as expected, the peaks
% should be pretty regularly spaced...

dm = mean(d);
ds = std(d);

% seemingly aberrant peaks are removed, and the distance between 
% the remaining peaks should be recalculated..

check = (abs(d-dm) < ds);

for i = 1:(length(check)-1)
	if ( (check(i) == 0) & ( d(i) < dm ) )
		d(i+1) = d(i)+d(i+1);	% removing peak i so distance from peak i+1
		i = i+1;		% to peak i-1 = d(i) + d(i+1)
	elseif  (check(i) == 0)
		dnew(i) = round(.5*d(i));
	else				% note this works for successive spurient
		dnew(i) = d(i);		% points
	end % if
end % i

dnew = dnew(find(dnew>0));

pitchperiod = mean(dnew);

p = fs/pitchperiod;



