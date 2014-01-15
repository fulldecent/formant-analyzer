function y = vowelguess(Formant)

% will guess the vowel according to formant frequencies
% f1 and f2 as determined by the "formants.m" function

% defined vowel frequencies [defined freq1, defined freq2]:

% "heed"
IY = [255 2330];

% "head"
EH = [560 1875];

% "hawed"
AO = [610 856];

% "who'd"
UW = [290 940];

% "bud"
AH = [640 1250];

% calculates euclidean distance
distIY = dist(IY,Formant');
distEH = dist(EH,Formant');
distA0 = dist(AO,Formant');
distUW = dist(UW,Formant');
distAH = dist(AH,Formant');

% distance vector
distances = [distIY distEH distA0 distUW distAH];

% min of distance vector
vowel = min(distances);

% decides which vowel and outputs to y
if vowel == distIY
   y = ['IY'];
elseif vowel == distEH
   y = ['EH'];
elseif vowel == distAO
   y = ['AO'];
elseif vowel == distUW
   y = ['UW'];
else
   y = ['AH'];
end
