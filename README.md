FORMANT PLOTTER
------------------------

This is an iOS project to analyze formants. The user speaks and the formant is plotted on the screen immediately. It is designed for speaking a single vowel syllable. It will try to isolate the vowel sound from any surrounding consonants if it can.

<img src="http://i.imgur.com/PnmTS53.png">


Formant Research
------------------------

Other related tools and formant information

  * Praat: http://www.fon.hum.uva.nl/praat/
  * WaveSurfer: https://sourceforge.net/projects/wavesurfer/
  * Perry R. Cook, "Identification of control parameters in an articulatory vocal tract model, with applications to the synthesis of singing", 1990, Ph.D Dissertation, CCRMA
    https://ccrma.stanford.edu/~kglee/m220c/formant.html

````
Vowel formant chart:

vowel		F1	F2	F3
ee	male	270	2290	3010
	female	310	2790	3310
	child	370	3200	3730
e	male	530	1840	2480
	female	610	2330	2990
	child	690	2610	3570
ae	male	660	1720	2410
	female	850	2050	2850
	child	1030	2320	3320
ah	male	730	1090	2440
	female	590	1220	2810
	child	680	1370	3170
oo	male	300	870	2240
	female	370	950	2670
	child	430	1170	3260
````

  * Speech Acoustics Made Easy http://web.archive.org/web/20120914101638/http://www.cochlear.com/files/assets/speech_acoustics_made_easy.pdf
  * English vowel word reference http://www.fonetiks.org/engsou2am.html
  * Chinese vowel diagram http://en.wikipedia.org/wiki/Chinese_vowel_diagram
  * Wiki page http://en.wikipedia.org/wiki/Formant
  * The National Center for Voice and Speech http://www.ncvs.org/ncvs/tutorials/voiceprod/tutorial/filter.html
  * Linguistics 110 Berkeley http://linguistics.berkeley.edu/~kjohnson/ling110/Homework_assignments/HW7_PlotVowels/PlotYourVowels.pdf
  * MATLAB Speech Signal Analysis http://www.phon.ucl.ac.uk/courses/spsci/matlab/lect10.html
  * MATLAB Formant Tracker example http://www.mathworks.com/matlabcentral/fileexchange/8959-formant-tracker
  * Formant Java example http://chronos.ece.miami.edu/~dasp/SeniorProject/Presentation/416Presentation.pdf
  * Digital Bubble Bath - Don H. Johnson Great discussion on formant analysis and practical implementation http://www.clear.rice.edu/elec431/projects96/digitalbb/formants.html

The Formant Plotter
------------------------

The program starts in green state. When the user starts talking (i.e. RMS goes above 0dBm for at least 0.1 seconds), the program goes into listening state and records the sound. When the user stops talking (i.e. RMS goes below 0dBm for at least 0.1 seconds), the program returns to ready state and draws graphs.

Graph drawing is done as follows:
The recorded sound is truncated to remove the first and last 10% of the data. Then perform a Fast Fourier Transform (FFT) with autocorrelation. The result is plotted linear from 0 - 4000 Hz on the X axis and from -60 to 0 dB log scale on the Y axis.

The second graph is drawn as follows:
An image is placed on the background for the chart (you create an image to start with) and two dots are plotted on the chart, representing the highest and lowest sample value from the recording. That's it.

The correct algorithm which takes the FFT results which were plotted above and creates the vowel plot is discussed in Formant Research above.

Some potential next steps include:
* Use autocorrelation to increase trimming accuracy
* Windowing on the truncated sound buffer so that edge samples have an attenuated effect
* Root polishing. The code has been written but commented out (please see PlotView.m). If we can test and refine this part, we will have better estimates of roots of LPC polynomials, and formant frequencies. We may not want VERY accurate estimates of formant frequencies and may not need root polishing.
* Elimination of weak roots (far away from unit circle). They do not produce a peak in H(w) and should be ignored. I hope that if we reduce order of LPC, we may not see such weak roots. This should be investigated after reduction of LPC filter order.
