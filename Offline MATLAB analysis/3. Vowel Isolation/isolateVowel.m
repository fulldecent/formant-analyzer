function [start, len] = isolateVowel(audioSamples)
% ISOLATEVOWEL Analyzes an audio recording and finds the vowel sound
%
% This is designed to work with a single recording that has a mono-
% syllabic utterance. Input format is raw audio samples, mono
%
% Algorithm description:
%
%   1. Break the input into NUM_SLICES time slices
%   2. Find total power of each slice and slice with maximum power
%   3. Set threshold based on maximum and THRESHOLD_FACTOR
%   4. Find contiguous slices with power greater than threshold
%   5. Trim off each end based on TRIM_FACTOR

    NUM_SLICES = 300;
    THRESHOLD_FACTOR = 0.1;
    TRIM_FACTOR = 0.15;

    % Divide the whole raw buffer into 300 chunks and process
    chunkSize = floor(length(audioSamples)/NUM_SLICES);

    energyValueVec = zeros(1,NUM_SLICES);
    for chunkIdx = 1:NUM_SLICES
        chunk = audioSamples(chunkIdx * chunkSize - chunkSize + 1:chunkIdx * chunkSize);
        chunkEnergy = sum (chunk .* chunk);
        energyValueVec(chunkIdx)=chunkEnergy;
    end

    maxEnergyValue = max(energyValueVec);
    energyValueThresh = maxEnergyValue * THRESHOLD_FACTOR;

    for dumidx=1:NUM_SLICES
        if (energyValueVec(dumidx) > energyValueThresh)
            startIdx = dumidx * chunkSize - chunkSize + 1;
            break;
        end
    end

    for dumidx=NUM_SLICES:-1:1
        if (energyValueVec(dumidx) > energyValueThresh)
            endIdx = dumidx * chunkSize;
            break;
        end
    end

    effectiveLength = endIdx - startIdx;
    effectiveStartIdx = startIdx + round(TRIM_FACTOR * effectiveLength);
    effectiveEndIdx = endIdx - round(TRIM_FACTOR * effectiveLength);

    fprintf('Energy envelope start: %d, length %d\n', startIdx, endIdx - startIdx + 1);
    fprintf('Vowel isolation start: %d, length %d\n', effectiveStartIdx, effectiveEndIdx - effectiveStartIdx + 1);

    start = effectiveStartIdx;
    len = effectiveEndIdx - effectiveStartIdx + 1;
end
