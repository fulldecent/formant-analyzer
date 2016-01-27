function [start, len] = findStrongPartOfSignal(audioSamples)
% FINDSTRONGPARTOFSIGNAL Analyzes a signal to find the significant part
%
% This is designed to work with a single recording that has a mono-
% syllabic utterance. Input format is raw audio samples, mono
%
% Algorithm description:
%
%   1. Break the input into NUM_CHUNKS time chunks
%   2. Find total power of each chunk and chunk with maximum power
%   3. Set threshold of maximum times SENSITIVITY
%   4. Trim slices off ends with power less than threshold

    NUM_CHUNKS = 300;
    SENSITIVITY = 0.1;

    % Divide the whole raw buffer into 300 chunks and process
    chunkSize = floor(length(audioSamples)/NUM_CHUNKS);

    energyValueVec = zeros(1,NUM_CHUNKS);
    for chunkIdx = 1:NUM_CHUNKS
        chunk = audioSamples((chunkIdx - 1) * chunkSize + 1 : chunkIdx * chunkSize);
        chunkEnergy = sum (chunk .* chunk);
        energyValueVec(chunkIdx) = chunkEnergy;
    end

    maxEnergyValue = max(energyValueVec);
    energyValueThresh = maxEnergyValue * SENSITIVITY;

    for chunkIdx = 1 : NUM_CHUNKS
        if (energyValueVec(chunkIdx) > energyValueThresh)
            startIdx = (chunkIdx - 1) * chunkSize + 1;
            break;
        end
    end

    for chunkIdx = NUM_CHUNKS : -1 : 1
        if (energyValueVec(chunkIdx) > energyValueThresh)
            lastIdx = chunkIdx * chunkSize;
            break;
        end
    end

    start = startIdx;
    len = lastIdx - startIdx + 1;
end
