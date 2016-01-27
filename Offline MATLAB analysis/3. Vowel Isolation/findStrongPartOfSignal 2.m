function [start, len] = findStrongPartOfSignal(startIn, lenIn)
% TRUNCATETAILSOFRANGE Will remove a fractional portion of ends of a range
%
% With a given range of start and length, the PORTION will be removed from
% the beginning and the end

    PORTION = 0.15;

    amountToTrim = round(lenIn * PORTION);
    start = startIn + amountToTrim;
    len = lenIn - amountToTrim * 2;
end
