% Offline tail clipping
% This routine reads 7 buffers, finds energy in them, finds the
% region where high energy waveform eists, finds the extent of 
% this strong waveform, and then performs 15% clipping on start 
% and the end of the speech seciton.
%
for sound_file_id = 1:7
    switch (sound_file_id)
        case 1
            base_file_name = 'arm';
        case 2
            base_file_name = 'beat';
        case 3
            base_file_name = 'bid';
        case 4
            base_file_name = 'calm';
        case 5
            base_file_name = 'cat';
        case 6
            base_file_name = 'four';
        case 7
            base_file_name = 'who';
    end




    % Sounds are loaded from a folder in the parent folder
%    wav_file_name = ['../Sounds/' base_file_name '.wav'];
%    [speech_in,Fs] = wavread(wav_file_name);
%    speech_av = mean(speech_in');
    %Resample to 44100 if Fs is different
%    if (Fs ~= 44100)
%        speech_av = resample(speech_av,44100/Fs);
%    end
    
fprintf (['../Sounds/' base_file_name '.raw']);
    myfid = fopen(['../Sounds/' base_file_name '.raw'], 'r')
    speech_av = fread(myfid, 'int16');

    
    % Convert float type samples to 16 bit short integers
    max_val = max(abs(speech_av));
    speech_final = int16(10000 * speech_av / max_val);

    % Save the buffer to local hard disk. Will be moved to xCode
    raw_file_name = [base_file_name '_rawin'];
    a = fopen(raw_file_name,'w');
    fwrite(a,speech_final,'int16');
    fclose(a);

    % Process for 15% tail clipping. Mimic the xCode algorithm

    % Divide the whole raw buffer into 300 chunks and process
    chunkSize = floor(length(speech_av)/300);

    energyValueVec = zeros(1,300);
    for chunkIdx = 1:300
        chunk = speech_av(chunkIdx * chunkSize - chunkSize + 1:chunkIdx * chunkSize);
        chunkEnergy = sum (chunk .* chunk);
        energyValueVec(chunkIdx)=chunkEnergy;
    end

    maxEnergyValue = max(energyValueVec);
    energyValueThresh = maxEnergyValue/10;

    for dumidx=1:300
        if (energyValueVec(dumidx) > energyValueThresh)
            startIdx = dumidx * chunkSize - chunkSize + 1;
            break;
        end
    end

    for dumidx=300:-1:1
        if (energyValueVec(dumidx) > energyValueThresh)
            endIdx = dumidx * chunkSize;
            break;
        end
    end

    effectiveLength = endIdx - startIdx;
    effectiveStartIdx = startIdx + round(15*effectiveLength/100);
    effectiveEndIdx = endIdx - round(15*effectiveLength/100);

    fprintf(1,'For file base name of %s,\n',base_file_name);
    fprintf('Start/end indices before 15%% clipping are at %d and %d\n',startIdx,endIdx);
    fprintf('Start/end indices after  15%% clipping are at %d and %d\n',effectiveStartIdx,effectiveEndIdx);
    raw_file_name = [base_file_name '_rawbefore'];
    a = fopen(raw_file_name,'w');
    fwrite(a,speech_final(startIdx:endIdx),'int16');
    fclose(a);    
    raw_file_name = [base_file_name '_rawafter'];
    a = fopen(raw_file_name,'w');
    fwrite(a,speech_final(effectiveStartIdx:effectiveEndIdx),'int16');
    fclose(a);    
    fprintf('\n')
end
