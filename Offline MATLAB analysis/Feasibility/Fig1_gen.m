%% FIGURE 1
%

recordings = {'arm', 'beat', 'bid', 'calm', 'cat', 'four', 'who'};
Fs = 44100;
sounds = [];

for recording = recordings
    inFile = ['../Audio files/2-' recording{1} '.raw'];
    base_file_name = recording{1};
    fileId = fopen(inFile, 'r');
    audioSamples = fread(fileId, 'int16');
    fclose(fileId);

    sounds = [sounds audioSamples'];
    fprintf('Analyzing %s\n', base_file_name);
    fprintf('\n')
end

subplot('position',[0.03 0.16 0.962 0.81])
time_v = [1:length(sounds)]/Fs;
plot(time_v,sounds)
axis([0 max(time_v) intmin('int16') intmax('int16')])
set(gca,'XTick',[1:13])
set(gca,'YTick',[-1 -0.5 0 .5 1])
grid on
