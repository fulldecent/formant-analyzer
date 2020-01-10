%% VOWEL ISOLATION
% We process all recordings to isolate just the vowel sound
% Then we play the original and the isolation back-to-back
%

recordings = {'arm', 'beat', 'bid', 'calm', 'cat', 'four', 'who'};
Fs = 44100;

index = 1

for recording = recordings
    inFile = ['../Audio files/2-' recording{1} '.raw'];

    base_file_name = recording{1};
    fileId = fopen(inFile, 'r');
    audioSamples = fread(fileId, 'int16');
    fclose(fileId);

    fprintf('Analyzing %s\n', base_file_name);
    [start, length_] = isolateVowel(audioSamples);

    % Plot the waveform in a wide window
    fig1 = figure(1);
    set(fig1,'position',[50 600 500 700])
    subplot(7, 1, index)
    plot(audioSamples)
    axis tight
    axis off
    title(base_file_name)
    
    % Show the isolation
    hold on;
    selector = [1:length(audioSamples)];
    band = 10000 * (selector >= start & selector <= start+length_);
    plot(band, 'Color', 'r');
    band = -10000 * (selector >= start & selector <= start+length_);
    plot(band, 'Color', 'r');
    hold off;
    
    index = index + 1;
end
