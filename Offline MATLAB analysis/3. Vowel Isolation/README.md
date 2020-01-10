Vowel Isolation
===============

The prerecorded utterances are analyzed to find the relevant vowel signal and
this signal is extracted.

Algorithm Description
---------------------

1.  Break the input into `NUM_SLICES` time slices

2.  Find total power of each slice and slice with maximum power

3.  Set threshold based on maximum and `THRESHOLD_FACTOR`

4.  Find contiguous slices with power greater than threshold

5.  Trim off each end based on `TRIM_FACTOR`

And the chosen constants are given as:

-   `NUM_SLICES` = 300;

-   `THRESHOLD_FACTOR` = 0.1;

-   `TRIM_FACTOR` = 0.15;

**Warning: The results of this algorithm should be off-by-one compared to the
iOS project because Matlab counts indices starting with 1 but Swift counts starting with 0.**

Analysis
========

You can hear the isolations with the program `play.m`. To visualize, see
`show.m`.

![](<vowelIsolation.png>)

Processing
==========

Run the file `main.m` to analyze audio files from the "Audio Format Conversion"
step which are saved in the `Audio files` folder with names starting with `2-`.
This saves the isolations to files with names starting with `3-`.

Program output should be as follows:

 > Analyzing arm

 > Strong part: 22265 ..< 36543

 > Vowel part: 24407 ..< 34401

 > Analyzing beat

 > Strong part: 28659 ..< 37353

 > Vowel part: 29963 ..< 36049

 > Analyzing bid

 > Strong part: 23815 ..< 32698

 > Vowel part: 25147 ..< 31366

 > Analyzing calm

 > Strong part: 28584 ..< 42451

 > Vowel part: 30664 ..< 40371

 > Analyzing cat

 > Strong part: 23521 ..< 40671

 > Vowel part: 26094 ..< 38099

 > Analyzing four

 > Strong part: 32852 ..< 46931

 > Vowel part: 34964 ..< 44819

 > Analyzing who

 > Strong part: 20203 ..< 34399

 > Vowel part: 22332 ..< 32270
 
