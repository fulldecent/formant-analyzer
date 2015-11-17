function convertAudioToRaw(inputFileName, outputFileName)
% CONVERTAUDIOTORAW Converts audio to raw mono 44.1k little-endian 16-bit
%
% CONVERTAUDIOTORAW works with WAV input files and other formats
% which explicitly define sample rate, bit-depth and byte ordering.

    [speech_in,Fs] = audioread(inputFileName);
    speech_av = mean(speech_in');

    %Resample to 44100 if Fs is different
    if (Fs ~= 44100)
        speech_av = resample(speech_av,44100/Fs);
    end

    max_val = max(abs(speech_av));
    speech_final = 10000 * speech_av / max_val;

    a = fopen(outputFileName,'w');
    fwrite(a,speech_final,'int16');
    fclose(a);
end