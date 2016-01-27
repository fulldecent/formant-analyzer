function [start, len] = isolateVowel(audioSamples)
% ISOLATEVOWEL Analyzes an audio recording and finds the vowel sound

    [strongStart, strongLen] = findStrongPartOfSignal(audioSamples);
    fprintf('Strong part: %d ... %d\n', strongStart, strongStart + strongLen - 1);
    [start, len] = truncateTailsOfRange(strongStart, strongLen);
end