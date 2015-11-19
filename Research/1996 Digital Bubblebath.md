Formant Research in Digital Bubblebath Project
==============================================

This page reviews and summarizes work done by the "Digital Bubblebath" team at
Rice University in 1996. The original project web page is available at
https://www.clear.rice.edu/elec431/projects96/digitalbb/index.html

Project Scope and Updates
-------------------------

The project started with an original motivation to "recognize words, recognize a
string of words and identify a voice." [At first, the approach
was](<https://www.clear.rice.edu/elec431/projects96/digitalbb/original_proposal.html>)
to use continious wavelet transform to do wavelet analysis for recognizing
vowels however, [this was quickly
updated](<https://www.clear.rice.edu/elec431/projects96/digitalbb/new_proposal.html>)
to target formant analysis and pitch determination with a new goal of
"extracting vowel sounds, identifying vowel sounds and identifying a speaker."
As the project progressed, the difficulties of isolation were seen and [the main
focus became](<https://www.clear.rice.edu/elec431/projects96/digitalbb/update1>)
simply "vowel recognition". The approach was [established shortly
thereafter](<https://www.clear.rice.edu/elec431/projects96/digitalbb/update2>).

1.  Input recordings were manually isolated for vowel sounds

2.  The human vocal system would be modeled as an all-pole system

3.  A forward-backward autoregressive model would find formant components

Formant Analysis
----------------

Human speech consists of vowels and consonants. [This analysis
considers](<https://www.clear.rice.edu/elec431/projects96/digitalbb/formants.html>)
phonemes as time-invarient systems. Specifically, the vowel is "a series of
pulses (generated at the voice box) [passing] through a filter (the vocal tract)
that is essentially a pipe. More precisely, a series of linked cylindrical
pipes."

To characterize this cylindrical pipe model, [autoregression (AR) analysis is
used](<https://www.clear.rice.edu/elec431/projects96/digitalbb/autoregression.html>).
Because of its simplicity and because there is no access to the inputs of the
vocal tract, a *forward-backward autoregressive* model is chosen.

Formants are sought for each 1 kHz band, and an empirical adjustment is used to
find the model order:

$$
order = f_s / 2 + 2
$$

**WE NOTE**: this is `f_2 / 2` in the text but `f_2 / 1000` in the code.

The code to implement this analysis is given in
[formants.m](<https://www.clear.rice.edu/elec431/projects96/digitalbb/formantscode.html>),
[peaks.m](<https://www.clear.rice.edu/elec431/projects96/digitalbb/peaks.html>)
and
[fmntest1.m/fmntest2.m](<https://www.clear.rice.edu/elec431/projects96/digitalbb/fmnts.html>).

Recognizing the Vowel
---------------------

The algorithm is:

1.  Manually isolate the vowel from the recording

2.  [Normalize
    amplitude](<https://www.clear.rice.edu/elec431/projects96/digitalbb/normalize.html>)
    and center (remove DC offset)  
    `t1 = (t1 - mean(t1)) / max(abs((t1 - mean(t1))));`

3.  Estimate the formant using the McCandless method (fmntest1) if they are
    distinct or the Ghael-Sandgathe method (fmntest2) if they are close together

4.  [Calculate
    distance](<https://www.clear.rice.edu/elec431/projects96/digitalbb/vowelrec.html>)
    to known vowel formants and select the closest one

**WE NOTE**: Their algorithm uses a proprietary "weighted formant" approach to
select a distance score by overweighting the first of three formants. It may be
interesting to consider the Mel scale as something more natural.

Data
----

The following vowel characterization was used by this project, but not cited.

| IY ("heed")  | 255 | 2330 | 3000 |
|--------------|-----|------|------|
| IH ("hid")   | 350 | 1975 | 2560 |
| EH ("head")  | 560 | 1875 | 2550 |
| AE ("had")   | 735 | 1625 | 2465 |
| AA ("hod")   | 760 | 1065 | 2550 |
| AO ("hawed") | 610 | 865  | 2540 |
| UW ("who'd") | 290 | 940  | 2180 |
| UH ("hood")  | 475 | 1070 | 2410 |
| AH ("bud")   | 640 | 1250 | 2610 |

Other Good Stuff
----------------

The project also discusses Parson's[^1] [pitch
determination](<https://www.clear.rice.edu/elec431/projects96/digitalbb/pitch.html>)
and has implemented a simple algorithm that clips the waveform to find the
fundamental frequency. A goal was use this to identify speakers.

[^1]: T. W. Parsons, *Voice and speech processing*. New York: McGraw-Hill, 1986,
p. 201.

Conclusions
-----------

This project
[concluded](<https://www.clear.rice.edu/elec431/projects96/digitalbb/conclusion.html>)
that successful identification of vowels was found with this technique.
[Recommended
improvements](<https://www.clear.rice.edu/elec431/projects96/digitalbb/pursue.html>)
include:

-   Increasing the recorded sampling rate beyond 8 kHz

-   Automating vowel extraction (possibly with wavelet analysis)

-   Perform continuous frequency analysis, a technique from [Their Finest Hour's
    team](<https://www.clear.rice.edu/elec431/projects96/finest/>)

-   Analyze harmonics rather than pitch to recognize speakers

-   Improve peak detection with a technique from the [P-Squared
    team](<https://www.clear.rice.edu/elec431/projects95/psquared/psquared.html>)

References
----------

Hess, Wolfgang. (1983) "Pitch Determination of Speech Signals", Springer-Verlag,
New York.

Oppenheim, Alan. Schafer, Ronald. (1989) "Discrete Time Signal Processing",
Prentice Hall, New Jersey.

Parsons, Thomas. (1986) "Voice and Speech Processing", McGraw-Hill, New York.
