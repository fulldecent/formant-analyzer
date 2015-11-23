%% LPC Formant Estimation
% This routine reads 7 raw buffers with tails already clipped.
% Then it applies LPC modeling to find the formant frequencies.
%

LPC_COEFF = 50;

recordings = {'arm', 'beat', 'bid', 'calm', 'cat', 'four', 'who'};
index = 1;

for recording = recordings
    base_file_name = recording{1};
    inFile = ['../Audio files/3-' recording{1} '-isolated.raw'];

    Fs = 44100;
    fileId = fopen(inFile, 'r');
    audioSamples = fread(fileId, 'int16');
    fclose(fileId);

    % Perform the LPC estimation
    [a,e] = lpc(audioSamples, LPC_COEFF);
    fprintf(1,'LPC error for %s is %0.f\n', base_file_name, e);

    % Plot format frequencies for just this segment
    r = roots(a);
    r = r(imag(r) > 0);
    ffreq = sort(atan2(imag(r), real(r)) * Fs / (2*pi));
    fprintf(1, 'First five format frequencies are: ');
    fprintf('%0.f ',ffreq(1:5));
    fprintf('\n');


    % Plot #1: transfer function
    [h,f] = freqz(1, a, 1024, Fs);
    figure(1)
    subplot(7, 1, index)
    plot(f, 20*log10(abs(h)), 'LineWidth', 2);
    title(base_file_name)
    axis tight


    % Plot #2: the poles
    figure(2)
    subplot(7, 1, index)
    hold off
    zplane(r);
    xlabel('')
    ylabel('')
    axis([0 1 0 1])


    % Plot #3: plot with all formants
    figure(3)
    hold on
    plot(ffreq(1), ffreq(2), '*');
    text(ffreq(1)+2, ffreq(2)+2, base_file_name, 'Color', 'blue');

    index = index + 1;
end


figure(3)
axis tight
axis(axis .* [0.9 1.1 0.9 1.1])
grid on
