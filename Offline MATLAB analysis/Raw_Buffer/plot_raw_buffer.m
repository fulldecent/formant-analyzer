% Raw Buffer Processing
% This routine reads raw binary data from a buffer
% and performs offline processing on the data.
%
% The buffer is saved by iPhone using [NSData writeToFile:*];

Fs = 44100;

%a = fopen('lastSpeech');
%a = fopen('beat_raw');
%a = fopen('cat_raw');
a = fopen('four_raw');
speech_in = fread(a,'int16');

%plot the waveform in a wide window
fig1 = figure(1);
set(fig1,'position',[50 600 1100 100])
subplot('position',[0 0 1 1])
plot(speech_in)
axis tight
axis off

% listen to verify
soundsc(speech_in,Fs);
fclose(a);
