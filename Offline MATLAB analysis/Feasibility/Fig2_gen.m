%% FIGURE 2
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

seg_length = Fs/10;
energy_threshold = intmax('int32');

data_length = length(sounds);
segments = floor(data_length/seg_length)

energy_flag_vector = zeros(1,segments);
for seg_idx = 1:segments
    sound_seg = sounds((1 + (seg_idx - 1)*seg_length):(seg_idx * seg_length));
    energy = sum(sound_seg .* sound_seg);
    if (energy > energy_threshold)
        energy_flag_vector(seg_idx) = 1;
    end
end

subplot('position',[0.03 0.44 0.962 0.53])
time_v = [1:length(sounds)]/Fs;
plot(time_v,sounds)
axis([0 max(time_v) intmin('int16') intmax('int16')])
set(gca,'XTick',[1:13])
set(gca,'YTick',[-1 -0.5 0 .5 1])
grid on

subplot('position',[0.03 0.01 0.962 0.32])
plot(energy_flag_vector,'LineWidth',3)
axis([0 length(energy_flag_vector) -0.1 1.2])
grid on
