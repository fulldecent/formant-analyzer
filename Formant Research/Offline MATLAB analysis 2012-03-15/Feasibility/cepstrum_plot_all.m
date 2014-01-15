load sounds
FS = 44100;   % Sampling frequency
seg_length = 4096;
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

eroded_energy_flag_vector = imerode(energy_flag_vector,ones(1,3));

figure(1)
subplot('position',[0.03 0.44 0.962 0.53])
time_v = [1:length(sounds)]/FS;
plot(time_v,sounds)
axis([0 max(time_v) -1 1])
set(gca,'XTick',[1:13])
set(gca,'YTick',[-1 -0.5 0 .5 1])
grid on

subplot('position',[0.03 0.01 0.962 0.32])
% plot(energy_flag_vector,'LineWidth',2)
plot(eroded_energy_flag_vector,'LineWidth',2)
axis([0 length(energy_flag_vector) -0.1 1.2])
grid on
% print -dmeta energy_plot

figure(2)
hold off

found_valid_flag = 0;
subplot_idx = 1;
segments_in_vowel = 0;
cum_seg_cep = zeros(1,512);

hamming_win = hamming(seg_length);
for seg_idx = 1:segments
    if (eroded_energy_flag_vector(seg_idx) == 1)
        found_valid_flag = 1;
        segments_in_vowel = segments_in_vowel + 1;
        fprintf(1,'Processing segment at time %f \n',seg_idx*seg_length/FS);
        sound_seg = sounds((1 + (seg_idx - 1)*seg_length):(seg_idx * seg_length));
        seg_fft = fft(sound_seg .* hamming_win');
        abs_seg_fft = abs(seg_fft(1:512));
        seg_cep = fft(log(abs_seg_fft+eps));
        cum_seg_cep = cum_seg_cep + abs(seg_cep);
    else
        if (found_valid_flag == 1)
            found_valid_flag = 0;
            ave_seg_cep = cum_seg_cep / segments_in_vowel;
            subplot(3,3,subplot_idx)
            plot(abs(ave_seg_cep));
            axis([0 120 0 200])
            subplot_idx = subplot_idx + 1;
            cum_seg_cep = zeros(1,512);
        end
    end
end
