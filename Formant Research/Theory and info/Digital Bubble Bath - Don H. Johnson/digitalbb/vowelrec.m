function output = vowelrec(file,samprate);

% This function takes a sound file name and the sample rate, and outputs
% the vowel being read in

% read in sound file
inputsamp = auread(file);

% normalize sound
inputnorm = normalize(inputsamp);

% calculated three frequency formant vector for vowel
inputform = formants(inputnorm, samprate);

% guess vowel by matching distance to standard formant frequency
output = weightedvowelguess(inputform);
