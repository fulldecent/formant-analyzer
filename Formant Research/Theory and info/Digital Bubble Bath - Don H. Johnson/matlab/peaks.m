function [loc,mag] = peaks(x)

%
% function [loc,mag] = peaks(x)
%
% locates local maxima of a signal x
% returns index number and magnitude of the maxima
% simplest algorithm: no noise reduction. works for 
% smooth data input only
%
% by joel s.  12/96
%

b = zeros(length(x));

for i = 2:length(x)-1

	if ( (x(i) >= x(i-1)) & (x(i) >= x(i+1)) & ( x(i) ~= x(i+1) ) )
		b(i) = 1;
	end % if

end % i

loc = find(b==1);
mag = x(loc);

