% Raw Buffer Generating
% This routine reads a wav file and creates 16-bit 
% integer raw binary data to be put into iPhone.
%
% The buffer is saved by iPhone using [NSData writeToFile:*];

%[speech_in,Fs] = wavread('beat.wav');
%[speech_in,Fs] = wavread('cat.wav');
[speech_in,Fs] = wavread('four.wav');
speech_av = mean(speech_in');

%Resample to 44100 if Fs is different
if (Fs ~= 44100)
    speech_av = resample(speech_av,44100/Fs);
end

max_val = max(abs(speech_av));
speech_final = 10000 * speech_av / max_val;

%a = fopen('beat_raw','w');
%a = fopen('cat_raw','w');
a = fopen('four_raw','w');
fwrite(a,speech_final,'int16');
fclose(a);
