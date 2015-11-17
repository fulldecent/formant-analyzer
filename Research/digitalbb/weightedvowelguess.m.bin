function y = weightedvowelguess(Formant)

% will guess the vowel according to formant frequencies
% f1, f2, and f3 in vector Formant as determined by the
% "formants.m" function

% Weighted matrix
w = [2 1 1];

% "heed"
IY = [255 2330 3000];

% "hid"
IH = [350 1975 2560];

% "head"
EH = [560 1875 2550];

% "had"
AE = [735 1625 2465];

% "hod"
AA = [760 1065 2550];

% "hawed"
AO = [610 865 2540];

% "who'd"
UW = [290 940 2180];

% "hood"
UH = [475 1070 2410];

% "bud"
AH = [640 1250 2610];

% calculates euclidean distance
distIY = norm(w.*(IY-Formant'));
distIH = norm(w.*(IH-Formant'));
distEH = norm(w.*(EH-Formant'));
distAE = norm(w.*(AE-Formant'));
distAA = norm(w.*(AA-Formant'));
distAO = norm(w.*(AO-Formant'));
distUW = norm(w.*(UW-Formant'));
distUH = norm(w.*(UH-Formant'));
distAH = norm(w.*(AH-Formant'));

% distance vector
distances = [distIY distIH distEH distAE distAA distAO distUW distUH distAH];

% min of distance vector
vowel = min(distances);

% decides which vowel and outputs to y
if vowel == distIY
   y = ['IY'];
elseif vowel == distIH
   y = ['IH'];
elseif vowel == distEH
   y = ['EH'];
elseif vowel == distAE
   y = ['AE'];
elseif vowel == distAA
   y = ['AA'];
elseif vowel == distAO
   y = ['AO'];
elseif vowel == distUH
   y = ['UH'];
elseif vowel == distUW
   y = ['UW'];
else
   y = ['AH'];
end
