% Truncated LPC Comparison
%
% This script compares the frequency response of LPC 
% coefficients obtained from MATLAB and objective-C

clear all
figure(1)

load a_xcode_arm
Fs = 44100;
lpc_coeff = 64;

base_file_name = 'who';

% Sounds are loaded from a folder in the parent folder
raw_file_name = ['../Sounds/' base_file_name '_raw_truncated'];
a = fopen(raw_file_name);
speech_seg = fread(a,'int16');
fclose(a);

[a,e] = lpc(speech_seg,lpc_coeff);

r = roots(a);
r = r(imag(r) > 0);
ffreq = sort(atan2(imag(r),real(r))*Fs/(2*pi));
fprintf(1,'First five formants for MATLAB are:\n');
fprintf(1,' %.1f %.1f %.1f %.1f %.1f \n',ffreq(1),ffreq(2),ffreq(3),ffreq(4),ffreq(5));

r = roots(a_xcode_arm);
r = r(imag(r) > 0);
ffreq = sort(atan2(imag(r),real(r))*Fs/(2*pi));
fprintf(1,'First five formants for objecive-C are:\n');
fprintf(1,' %.1f %.1f %.1f %.1f %.1f \n',ffreq(1),ffreq(2),ffreq(3),ffreq(4),ffreq(5));

subplot('position',[0.03 0.76 0.96 0.24])
stem(a,'.');
axis tight;
axin = axis;
axis([axin + [-1 .5 -.2 .2]]);
set(gca,'XTickLabel',[])

subplot('position',[0.03 0.51 0.96 0.24])
[h,f] = freqz(1,a,1024,Fs);
plot(f,20*log10(abs(h)),'LineWidth',2);
axis tight
grid on
set(gca,'XTickLabel',[])
% set(gca,'YTickLabel',[])

subplot('position',[0.03 0.26 0.96 0.24])
stem(a_xcode_arm,'.');
axis tight;
axin = axis;
axis([axin + [-1 .5 -.2 .2]]);
set(gca,'XTickLabel',[])

subplot('position',[0.03 0.01 0.96 0.24])
[h,f] = freqz(1,a_xcode_arm,1024,Fs);
plot(f,20*log10(abs(h)),'LineWidth',2);
axis tight
grid on
set(gca,'XTickLabel',[])
set(gca,'YTickLabel',[])

print -dmeta lpc_comparison_plots







