%% VOWEL ISOLATION
% We process all recordings to isolate just the vowel sound
% Then we play the two original and the isolation back-to-back
%

recordings = {'arm', 'beat', 'bid', 'calm', 'cat', 'four', 'who'};
Fs = 44100;

for recording = recordings
    inFile = ['../Audio files/2-' recording{1} '.raw'];

    base_file_name = recording{1};
    fileId = fopen(inFile, 'r');
    audioSamples = fread(fileId, 'int16');
    fclose(fileId);

    fprintf('Analyzing %s\n', base_file_name);
    [start, length] = isolateVowel(audioSamples);

    fprintf('Playing original recording\n');
    pause(1)
    soundsc(audioSamples,Fs);

    fprintf('Playing isolation\n');
    pause(1)
    soundsc(audioSamples(start:start + length - 1),Fs);    

    fprintf('\n')
end
