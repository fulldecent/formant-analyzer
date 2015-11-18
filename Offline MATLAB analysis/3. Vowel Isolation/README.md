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

**Warning: The results of this algorithm should be off by one compared to the
iOS project because Matlab counts indices starting with 1 but Objective-C and
Swift count starting with 0.**

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

>   Analyzing arm

>   Energy envelope start: 22265, length 14278

>   Vowel isolation start: 24407, length 9994

>    

>   Analyzing beat

>   Energy envelope start: 28659, length 8694

>   Vowel isolation start: 29963, length 6086

>    

>   Analyzing bid

>   Energy envelope start: 23815, length 8883

>   Vowel isolation start: 25147, length 6219

>    

>   Analyzing calm

>   Energy envelope start: 28584, length 13867

>   Vowel isolation start: 30664, length 9707

>    

>   Analyzing cat

>   Energy envelope start: 23521, length 17150

>   Vowel isolation start: 26093, length 12006

>    

>   Analyzing four

>   Energy envelope start: 32852, length 14079

>   Vowel isolation start: 34964, length 9855

>    

>   Analyzing who

>   Energy envelope start: 20203, length 14196

>   Vowel isolation start: 22332, length 9938

 
