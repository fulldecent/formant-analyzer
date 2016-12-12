function [start, len] = isolateVowel(audioSamples)
% ISOLATEVOWEL Analyzes an audio recording and finds the vowel sound

    [strongStart, strongLen] = findStrongPartOfSignal(audioSamples);
    fprintf('Strong part: %d ..< %d\n', strongStart, strongStart + strongLen);
    [start, len] = truncateTailsOfRange(strongStart, strongLen);
end