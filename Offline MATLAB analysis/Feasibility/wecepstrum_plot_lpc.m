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

found_valid_flag = 0;
subplot_idx = 1;
segments_in_vowel = 0;

lpc_coeff = 50;
cum_seg_cep = zeros(1,1+lpc_coeff);

figure(2)
subplot1 = subplot('position',[0.01 0.51 0.24 0.48])
subplot2 = subplot('position',[0.26 0.51 0.24 0.48])
subplot3 = subplot('position',[0.51 0.51 0.24 0.48])
subplot4 = subplot('position',[0.76 0.51 0.24 0.48])

subplot5 = subplot('position',[0.01 0.01 0.24 0.48])
subplot6 = subplot('position',[0.26 0.01 0.24 0.48])
subplot7 = subplot('position',[0.51 0.01 0.24 0.48])
subplot8 = subplot('position',[0.76 0.01 0.24 0.48])

figure(3)
subplot('position',[0.07 0.04 0.92 0.95])
hold off

hamming_win = hamming(seg_length);
for seg_idx = 1:segments
    if (eroded_energy_flag_vector(seg_idx) == 1)
        found_valid_flag = 1;
        segments_in_vowel = segments_in_vowel + 1;
        sound_seg = sounds((1 + (seg_idx - 1)*seg_length):(seg_idx * seg_length));
        a = lpc(sound_seg,lpc_coeff);
        cum_seg_cep = cum_seg_cep + a;

        % Plot format frequencies for just this segment
        r = roots(a);
        r = r(imag(r) > 0.01);
        ffreq = sort(atan2(imag(r),real(r))*FS/(2*pi));
        fprintf(1,'First five format frequencies are: ');
            for root_idx = 1:4
                fprintf(1,'%.1f ',ffreq(root_idx));
            end
            fprintf(1,'%.1f \n',ffreq(5));
        figure(3)
        plot(ffreq(1),ffreq(2),'*');
        text(ffreq(1)-20,ffreq(2)+10,num2str(subplot_idx),'Color','blue');
        axis([0 850 0 2300])
        hold on
    else
        if (found_valid_flag == 1)
            found_valid_flag = 0;
            ave_seg_cep = cum_seg_cep / segments_in_vowel;

            figure(2)
            eval(['subplot(subplot' num2str(subplot_idx) ');']);
            [h,f] = freqz(1,ave_seg_cep,1024,FS);
            plot(f,20*log10(abs(h)),'LineWidth',2);
            axis tight
            set(gca,'XTick',[])
            set(gca,'YTick',[])
            cum_seg_cep = zeros(1,1+lpc_coeff);

            r = roots(ave_seg_cep);
            r = r(imag(r) > 0.01);
            ffreq = sort(atan2(imag(r),real(r))*FS/(2*pi));
        fprintf(1,'First five format frequencies of average filter are: ');
            for root_idx = 1:4
                fprintf(1,'%.1f ',ffreq(root_idx));
            end
            fprintf(1,'%.1f \n',ffreq(5));

            figure(3)
            plot(ffreq(1),ffreq(2),'go');
            text(ffreq(1)+10,ffreq(2)+10,num2str(subplot_idx),'Color','green');
            axis([0 850 0 2300])
            set(gca,'XTick',[0 250 500 750])
            set(gca,'YTick',[0 500 1000 1500 2000])
            hold on
            grid on
            subplot_idx = subplot_idx + 1;

        end
    end
end

figure(2)
print -dmeta ARModel_plots

figure(3)
print -dmeta average_formant_cluster

