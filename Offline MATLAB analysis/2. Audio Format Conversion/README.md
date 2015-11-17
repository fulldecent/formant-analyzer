Audio Format Conversion
=======================

The prerecorded utterances are converted into a standardized format for
processing in Matlab. To ensure identical results with offline processing as
when using the Formant Analyzer iOS app, we have chosen a very simple preferred
format for storing the audio.

Working Audio Format
--------------------

-   Raw audio samples with `.raw` file extension

-   44 100 Hz sample rate

-   Mono channel

-   16-bit signed integer samples written little-endian

Processing
==========

Run the file `main.m` to convert WAV audio files from the `Input Sounds` to raw
audio in this folder.
