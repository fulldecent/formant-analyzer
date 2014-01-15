load sounds
FS = 44100;   % Sampling frequency
seg_length = FS/10;
energy_threshold = 1;

data_length = length(sounds);
segments = floor(data_length/seg_length)

energy_flag_vector = zeros(1,segments);
for seg_idx = 1:segments
    sound_seg = sounds((1 + (seg_idx - 1)*seg_length):(seg_idx * seg_length));
    energy = sum(sound_seg .* sound_seg);
    if (energy > 1)
        energy_flag_vector(seg_idx) = 1;
    end
end

subplot('position',[0.03 0.44 0.962 0.53])
time_v = [1:length(sounds)]/fs;
plot(time_v,sounds)
axis([0 max(time_v) -1 1])
set(gca,'XTick',[1:13])
set(gca,'YTick',[-1 -0.5 0 .5 1])
grid on

subplot('position',[0.03 0.01 0.962 0.32])
plot(energy_flag_vector,'LineWidth',3)
axis([0 length(energy_flag_vector) -0.1 1.2])
grid on
print -dmeta energy_plot
