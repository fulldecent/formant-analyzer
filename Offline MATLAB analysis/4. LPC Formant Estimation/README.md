LPC Formant Estimation
======================

The isolated signals are analyzed with a Linear Predictive Coding model to find
the formants.

Algorithm Description
---------------------

1.  Perform autocorrelation autoregressive model (LPC) of order `LPC_COEFF`

2.  Calculate the complex roots of the LPC model

3.  Ignore roots with positive imaginary part (arbitrary, could have also
    ignored the negatives)

4.  Convert roots to frequency domain based on sampling frequency

And the chosen constants are given as:

-   `LPC_COEFF` = 10;

Source for model length choice is based on https://www.mathworks.com/examples/signal/mw/signal-ex82230229-formant-estimation-with-lpc-coefficients

**Warning: MATLAB documentation for the **`LPC`** function notes that windowing
is implicitly implied. However, this might be a problem because our input is a
periodic signal which does not go to zero at the beginning and end.**

Analysis
========

You can perform this analysis by running `estimateFormants.m`.

Following are the transfer functions for each recording.

![](<transferFunctions.png>)

Following are the complex roots.

![](<poles.png>)

Lastly, all the vowels are plotted on the common two formant plot. The first
formant is the X axis and the second formant is the Y axis.

![](<formantPlots.png>)

Processing
==========

Following is the full output:

>   LPC error for arm is 2421

>   First five format frequencies are: 697 1218 1845 2656 3253

>   LPC error for beat is 2515

>   First five format frequencies are: 329 2209 2224 2823 3245

>   LPC error for bid is 2220

>   First five format frequencies are: 463 1715 2633 3054 3271

>   LPC error for calm is 2158

>   First five format frequencies are: 449 750 1310 2900 2959

>   LPC error for cat is 7835

>   First five format frequencies are: 754 1650 2433 2827 3386

>   LPC error for four is 3009

>   First five format frequencies are: 411 612 1832 2810 3341

>   LPC error for who is 3897

>   First five format frequencies are: 455 1319 2363 2962 3427
