clear all

%%% stimulus parameters
orientation = 45;   % orientation (degrees)
f = 1;             % spatial frequency (c/deg)
imagesize = 10;      % image size (deg)

contrast_noise = 1;
contrast_signal= 1;
oLow = 60; % low cutoff orientation
oHigh = 75; % high cutoff orientation
fLow=0;% noise bandpass frequency (low)
fHigh=1;% noise bandpass frequency (high)

dpi = 96;                        % display dpi
viewdist = 52;                   % observer's viewing distance (cm)
background=128; %color of background
max_ampl=128;

pixPerDegree = (viewdist*(tan(1*pi/180)))*dpi/2.54;
checkDeg=viewdist*(1/dpi)*2.54/100; %in m
fNyquist=0.5/checkDeg;

%%% minor conversions
f = f*2*pi/pixPerDegree;                            % convert to cycles per degree
imagesize = round(imagesize*pixPerDegree);          % convert size from degrees to pixels
orientation = orientation*pi/180;                   % convert orientation from deg to radians
fLow = fLow/fNyquist;
fHigh = fHigh/fNyquist;

%%% create a grating
[x,y] = meshgrid(-imagesize/2:imagesize/2,-imagesize/2:imagesize/2);                   
sinusoid = ((sin((cos(orientation)*f)*x+(sin(orientation)*f)*y))); % create 2d sinusoid
sigma = 1/10*length(x);                                                            % gaussian s.d.                                                     
gaussian = 1*exp((-2.77*x.^2)/(2.35*sigma)^2).*exp((-2.77*y.^2)/(2.35*sigma)^2);   % gaussian envelope
gabor =  background + gaussian .* sinusoid *max_ampl *contrast_signal;                                         % put together gabor

%%% show gabor
subplot(2,3,1)
imshow(gabor, [0 255]);
title('original gabor')

fft_gabor = fftshift(fft2(gabor));  

gabor_power_spectrum = abs(fft_gabor);
subplot(2,3,2)
imshow(gabor_power_spectrum, [0 10000]); 
title('represented in frequency domain')

%%% make orientation filter
o_bandpass_filter = OrientationBandpass(size(gabor), oLow, oHigh); % make orientation bandpass filter

%%% make s.f. filter
sf_bandpass_filter = Bandpass2(size(gabor), fLow, fHigh); % create 2d bandpass filter

%%% get rid of gibbs ringing artifacts
smoothfilter = fspecial('gaussian', 10, 4);   % make small gaussian blob
o_bandpass_filter = filter2(smoothfilter, o_bandpass_filter); % convolve smoothing blob w/ orient. filter
subplot(2,3,3)
imshow(o_bandpass_filter);
title('orientation bandpass filters')

%sf_bandpass_filter = filter2(smoothfilter, sf_bandpass_filter);

%%% create noise
noise=normrnd(0, contrast_noise, size(gabor)); %this should be in units of contrast?
fn = fftshift(fft2(noise)); %in frequency domain

subplot(2,3,4)
imshow(abs(fn), [0 1000]);
% imshow(abs(fn));
title('noise in frequency domain')

%%% apply filter & show it
fn_filtered_noise=o_bandpass_filter .*fn;
%.* sf_bandpass_filter .*fn;
subplot(2,3,5)
imagesc(abs(fn_filtered_noise), [0 200]);
% imshow(abs(fn_filtered_noise));
title('filter applied to noise in frequency domain')

%%% transform back to real domain & show it
filterednoise=real(ifft2(ifftshift(fn_filtered_noise))) .* gaussian *max_ampl ;
stimulus = gabor + filterednoise; %gabor already has background
subplot(2,3,6)
imshow(stimulus, [0 255]);
title('transformed gabor')

