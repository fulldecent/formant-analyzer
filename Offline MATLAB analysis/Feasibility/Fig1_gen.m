data_present = 1;
if (data_present == 1)
    load sounds;
else
    [a,fs,nbits] = wavread('sample.wav');
    [b,fs,nb] = wavread('arm.wav');
    [c,fs,nb] = wavread('beat.wav');
    [d,fs,nb] = wavread('bid.wav');
    [e,fs,nb] = wavread('calm.wav');
    [f,fs,nb] = wavread('cat.wav');
    [g,fs,nb] = wavread('four.wav');
    [h,fs,nb] = wavread('who.wav');
    sounds = [a ; b ; c ; d ; e ; f ;g ;h];

    % Just take one channel. and make a row vector.
    sounds = sounds(:,1);
    sounds = sounds(:);
    sounds = sounds';
end

subplot('position',[0.03 0.16 0.962 0.81])
time_v = [1:length(sounds)]/fs;
plot(time_v,sounds)
axis([0 max(time_v) -1 1])
set(gca,'XTick',[1:13])
set(gca,'YTick',[-1 -0.5 0 .5 1])
grid on
%print -dmeta sounds_plot
%save sounds sounds