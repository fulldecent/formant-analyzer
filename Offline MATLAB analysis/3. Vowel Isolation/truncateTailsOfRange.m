function [start, len] = truncateTailsOfRange(startIn, lenIn)
% TRUNCATETAILSOFRANGE Will remove a fractional portion of ends of a range
%
% With a given range of start and length, the PORTION will be removed from
% the beginning and the end

    PORTION = 0.15;

    start = startIn + round(lenIn * PORTION);
    len = round(lenIn * (1.0 - PORTION)) + startIn - start;
end
