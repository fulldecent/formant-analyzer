%% CONVERT WAV FILES
% We convert all input WAV files to raw files with our preferred format:
%
%  - Raw audio samples
%  - 44 100 Hz sample rate
%  - Mono channel
%  - 16-bit signed integer samples written little-endian
%

recordings = {'arm', 'beat', 'bid', 'calm', 'cat', 'four', 'who'};

for recording = recordings
    inFile = ['../Audio files/1-' recording{1} '.wav'];
    outFile = ['../Audio files/2-' recording{1} '.raw'];
    fprintf('Converting %s\n',recording{1});
    convertAudioToRaw(inFile, outFile);
    fprintf('\n');
end
