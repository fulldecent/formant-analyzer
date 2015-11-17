% Truncated LPC Plot
% This routine reads 7 raw buffers with 15% tails already clipped.
% Then it applies LPC modeling to find the formant frequencies.

clear all
lpc_coeff = 50;
FS = 44100;

figure(1)
clf
subplot1 = subplot('position',[0.01 0.51 0.24 0.48]);
subplot2 = subplot('position',[0.26 0.51 0.24 0.48]);
subplot3 = subplot('position',[0.51 0.51 0.24 0.48]);
subplot4 = subplot('position',[0.76 0.51 0.24 0.48]);

subplot5 = subplot('position',[0.01 0.01 0.24 0.48]);
subplot6 = subplot('position',[0.26 0.01 0.24 0.48]);
subplot7 = subplot('position',[0.51 0.01 0.24 0.48]);
% subplot8 = subplot('position',[0.76 0.01 0.24 0.48]);

figure(2)
clf
subplot('position',[0.06 0.06 0.93 0.92])
hold off

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
    raw_file_name = ['../Sounds/' base_file_name '_raw_truncated'];
    a = fopen(raw_file_name);
    speech_seg = fread(a,'int16');
    eval(['speech' base_file_name '= speech_seg;']);
    fclose(a);

    [a,e] = lpc(speech_seg,lpc_coeff);
    fprintf(1,'LPC error for %s is %f\n',base_file_name,e);

    % Plot format frequencies for just this segment
    r = roots(a);
    r = r(imag(r) > 0);
    ffreq = sort(atan2(imag(r),real(r))*FS/(2*pi));
    fprintf(1,'First five format frequencies are: ');
    for root_idx = 1:4
        fprintf(1,'%.1f ',ffreq(root_idx));
    end
    fprintf(1,'%.1f \n',ffreq(5));

    figure(1)

    eval(['subplot(subplot' num2str(sound_file_id) ');']);
    
    %%%%%%%%%%% Plot poles
%     zplane(r);
%     xlabel('')
%     ylabel('')     
%     set(gca,'XTick',[])
%     set(gca,'YTick',[])
%     axis([-0.1 1.1 -0.1 1.1])
    
    %%%%%%%%%%% Plot transfer function
    [h,f] = freqz(1,a,1024,FS);
    plot(f,20*log10(abs(h)),'LineWidth',2);
    axis tight
     set(gca,'XTick',[])
     set(gca,'YTick',[])


    figure(2)
    plot(ffreq(1),ffreq(2),'*');
    text(ffreq(1)+2,ffreq(2)+2,base_file_name,'Color','blue');
    hold on
end

figure(1)
% print -dmeta ARModel_plots

figure(2)
axis tight
axin = axis;
axis(axis .* [0.9 1.1 0.9 1.1])
grid on
% print -dmeta average_formant_cluster

