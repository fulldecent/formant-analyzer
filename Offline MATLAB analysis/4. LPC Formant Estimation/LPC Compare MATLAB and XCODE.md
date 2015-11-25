This work compared LPC coefficients and roots of prediction filters obtained
from MATLAB and objective-C.

There is slight mismatch, most probably due to MATLAB implying windowing and us
not including that step.

Comparison of LPC Coefficients
==============================

We are implementing LPC based formant plotting on iOS platform. During the
development, we are verifying our work by comparing our results with the results
of MATLAB routines.

We observed that LPC coefficients obtained from two approaches are not EXACTLY
the same but the general trend is similar. In this short report, the frequency
responses of two prediction filters are plotted to see if the two sets of LPC
coefficients give significantly different formants. Figure 1 below shows the LPC
coefficients as well as the frequency response of prediction filter.

![](<compare1.png>)

Figure 1. Comparison of LPC coefficients and frequency response. Top two
subplots are from MATLAB based LPC computation of truncated 'arm' sound. The two
lower plots are from objective-C based computation for the same sound.

As can be seen from the output of MATLAB plotting routine, the two set of
formant frequencies are:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
MATLAB : 698.9 , 1235.5 , 1826.5 , 2508.8 , 2672.4  
Objective-C: 695.9 , 1229.0 , 1866.5 , 2410.9 , 2660.7
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Hence, we can see that our computations give quite accurate results and we can
go ahead with formant frequency measurement from LPC coefficients obtained from
objective-C routines.

Comparison of LPC Roots
=======================

We are implementing LPC based formant plotting on iOS platform. During the
development, we are verifying our work by comparing our results with the results
of MATLAB routines.

We observed that LPC coefficients obtained from two approaches are not EXACTLY
the same but the formant frequencies are not far away from each other. Here, we
list and plot the roots of prediction filter so that we can compare MATLAB
results with objective-C results. The graphical locations of the roots of
prediction filter are shown below in Figure 1.

![](<compare2.png>)

Figure 2. Location of roots of the prediction polynomial

The complete listing of roots is:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
0.7842 + 0.5946i 0.7842 - 0.5946i 0.8829 + 0.4436i 0.8829 - 0.4436i 0.9174 + 0.3672i  
0.9174 - 0.3672i 0.9475 + 0.2523i 0.9475 - 0.2523i 0.9723 + 0.1729i 0.9723 - 0.1729i  
0.9881 + 0.0987i 0.9881 - 0.0987i 0.8197 + 0.3061i 0.8197 - 0.3061i 0.6621 + 0.6240i  
0.6621 - 0.6240i 0.6111 + 0.6999i 0.6111 - 0.6999i 0.5329 + 0.7719i 0.5329 - 0.7719i  
0.4452 + 0.8184i 0.4452 - 0.8184i 0.3605 + 0.8642i 0.3605 - 0.8642i 0.2643 + 0.8980i  
0.2643 - 0.8980i 0.1676 + 0.9454i 0.1676 - 0.9454i 0.0585 + 0.9547i 0.0585 - 0.9547i  
-0.0268 + 0.9779i -0.0268 - 0.9779i -0.0980 + 0.9143i -0.0980 - 0.9143i -0.2181 + 0.8825i  
-0.2181 - 0.8825i -0.3591 + 0.8527i -0.3591 - 0.8527i -0.4645 + 0.8202i -0.4645 - 0.8202i  
-0.9212 + 0.0465i -0.9212 - 0.0465i -0.9127 + 0.1376i -0.9127 - 0.1376i -0.8942 + 0.2319i  
-0.8942 - 0.2319i -0.8635 + 0.3189i -0.8635 - 0.3189i -0.8285 + 0.4030i -0.8285 - 0.4030i  
-0.5514 + 0.7508i -0.5514 - 0.7508i -0.7831 + 0.4843i -0.7831 - 0.4843i -0.6479 + 0.6629i  
-0.6479 - 0.6629i -0.7316 + 0.5633i -0.7316 - 0.5633i -0.6189 + 0.6335i -0.6189 - 0.6335i  
-0.2677 + 0.8593i -0.2677 - 0.8593i 0.9511 0.9063
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
