%% VOWEL ISOLATION
% We process all recordings to isolate just the vowel sound
% This is the region where the waveform has high energy, with ends trimmed off
%

recordings = {'arm', 'beat', 'bid', 'calm', 'cat', 'four', 'who'};

for recording = recordings
    inFile = ['../Audio files/2-' recording{1} '.raw'];
    outFile = ['../Audio files/3-' recording{1} '-isolated.raw'];

    base_file_name = recording{1};
    fileId = fopen(inFile, 'r');
    audioSamples = fread(fileId, 'int16');
    fclose(fileId);

    fprintf('Analyzing %s\n', base_file_name);
    [start, length] = isolateVowel(audioSamples);
    fileId = fopen(outFile,'w');
    fwrite(fileId, audioSamples(start:start + length - 1), 'int16');
    fclose(fileId);
    fprintf('\n')
end
