clear all
Screen('Close');    %Closes any textures that might have been left open due to a dirty crash

addpath('Local_Functions');

%% Set Global Parameters

Parameters = struct;

%SCREEN:
[scrnum,frameHz,pixPerDeg] = GetMonitorInfo(0); 
Parameters.pixPerDeg = pixPerDeg;
Parameters.frameHz = frameHz;
Parameters.BgdColor = 127;
Parameters.FontName = 'Verdana';
Parameters.FontSize = 16;

%FIXATION:
Parameters.fixDiamDeg = 0.50;

%STIMULI:
Parameters.AnnInRad = 1.5;          %Inner radius of annulus mask (deg)
Parameters.AnnOutRad = 7.5;         %Outer radius of annulus mask (deg)
Parameters.LinDecRad = 0.5;         %Start of linear decay (deg from perimeter)

Parameters.SineMean = Parameters.BgdColor;
Parameters.SineContrast = 0.2;
Parameters.SineAmp = Parameters.SineMean*Parameters.SineContrast;
Parameters.SineSpatFreq = 1;        %Spatial frequency of grating (cyc/deg)
Parameters.SineTempFreq = 2;        %Temporal frequency of contrast modulation (Hz)

Parameters.NoiseContrast = 0.6;
Parameters.NoiseAmp = Parameters.SineMean * Parameters.NoiseContrast;
Parameters.NoiseUpdateFreq = 4;     %Update frequency of dynamic noise (Hz), should prolly be faster than and/or integer multiple of SineTempFreq
Parameters.SFFilterLB = 0;        %Lower bound of noise SF bandpass filter (cyc/deg)
Parameters.SFFilterUB = 10;          %Upper bound of same
Parameters.OriFilterBW = 25;        %Bandwith (full range) of bandpasss ori filters (deg)
Parameters.SmoothSD = 4;            %Standard deviation of the Gaussian smoothing kernel applied to filters

Parameters.MatchMean = Parameters.SineMean;
Parameters.MatchContrast = 1;
Parameters.MatchAmp = Parameters.MatchMean*Parameters.MatchContrast;


%DESIGN:
Parameters.TR = 2;                  %Duration in s of 1 TR (all other times are multiples of this)

Parameters.DummysBef = 1;           %Dummy volumes before first trial
Parameters.DummysAft = 0;           %Dummy volumes after last trial

Parameters.CueDuration = 0.125;     %How long should the cue be on screen for (each trial starts with the presentation of the cue, i.e. CueOnsetTime = 0)
Parameters.StimulusOnset = 0.25;    %This implicitly defines the pause between cue and stimulus
Parameters.StimulusDuration = 0.75; 
Parameters.MatchDelay = 2.5;        %Time between stimulus presentation and match task
Parameters.MatchDuration = 1.5;     %Time the match stimulus will be on screen for (=response epoch)
Parameters.MatchDim = 1;            %How far into the match task should the grating start to dim?
Parameters.ITI = 2;                 %Inter-Trial Interval 

Parameters.TrialLength = Parameters.StimulusOnset + Parameters.StimulusDuration + Parameters.MatchDelay + Parameters.MatchDuration;

Parameters.pctFixTrials = 0.0;                  
Parameters.NumTrials = 1;          %NumTrials * pctFixTrials must be an integer number

%% Determine script for this run
%We want orientations to span the whole 180 degrees. However, orientations
%must be random. So a good way to go would be to start with n base
%orientations which are random for each run but evenly spaced, and add a
%random jitter to every presentation. 

Trial = struct;
Trial(Parameters.NumTrials).Orientation = [];
Trial(Parameters.NumTrials).Phase = [];

%Determine number of trials in each condition:
NumFixTrials = Parameters.NumTrials * Parameters.pctFixTrials;
if mod(NumFixTrials,1), error('Non-integer number of fixation trials.'); end
NumOriTrials = Parameters.NumTrials-NumFixTrials;

%Determine stimulus orientation for each trial (fixation = NaN)
BaseOris = linspace(0,180,NumOriTrials+1);
Oris = floor(BaseOris(1:end-1)' + rand(NumOriTrials,1)*180/(length(BaseOris)-1)); %Orientation is in degrees and CW from horizontal (which means we need to use negative numbers for makeSineGrating which assumes CCW rotations)            
OriList = num2cell([Oris; nan(NumFixTrials,1)]);

%Keep Shuffling until there are no consecutive NaNs (i.e. fixTrials) in the
%OriList:
DoubleNans = true;
while DoubleNans
    OriList = Shuffle(OriList);
    DoubleNans = false;
    prevTrial = OriList{1};
    for trial_idx = 2:Parameters.NumTrials
        if isnan(OriList{trial_idx}) && isnan(prevTrial), DoubleNans = true; end
        prevTrial = OriList{trial_idx};        
    end
end    
OriList = num2cell(77);
[Trial(1:Parameters.NumTrials).Orientation] = OriList{:};

%Generate a list of random phases:
Phase = rand(Parameters.NumTrials,1)*2*pi;                          %Phase is in radians
Phase(isnan(cell2mat(OriList))) = NaN;
PhaseList = num2cell(Phase);
[Trial(1:Parameters.NumTrials).Phase] = PhaseList{:};

%Determine proximity of noise orientation content for each trial:
%NoiseOriProx = num2cell(linspace(80,10,Parameters.NumTrials)');           %For now this is all the same
NoiseOriProx = num2cell(ones(Parameters.NumTrials,1)*30);
[Trial(1:Parameters.NumTrials).NoiseOriProx] = NoiseOriProx{:};

%% Make annulus, first stimulus, possible filters etc.

AnnInRadPix = ceil(Parameters.AnnInRad * Parameters.pixPerDeg);
AnnOutRadPix = ceil(Parameters.AnnOutRad * Parameters.pixPerDeg);
LinDecRadPix = ceil(Parameters.LinDecRad * Parameters.pixPerDeg);
%stimRect = CenterRect([0 0 AnnOutRadPix*2 AnnOutRadPix*2],wrect);

AnnMask = makeLinearMaskCircleAnn(AnnOutRadPix*2, AnnOutRadPix*2, AnnInRadPix, LinDecRadPix, AnnOutRadPix);

NumStimFrames = Parameters.StimulusDuration * Parameters.TR * Parameters.frameHz;
StimulusFramePtrs = nan(NumStimFrames,1);

NoiseFrameSpacing = frameHz/Parameters.NoiseUpdateFreq;
NoiseUpdateFrames = 1:NoiseFrameSpacing:NumStimFrames;

%Filters:
fNyquist = pixPerDeg/2; %This is a simplification of the original computation (terms canceled out)
SmoothFilter = fspecial('gaussian', 10, Parameters.SmoothSD);
SFFilter = Bandpass2([AnnOutRadPix*2 AnnOutRadPix*2], Parameters.SFFilterLB/fNyquist, Parameters.SFFilterUB/fNyquist);
SFFilter = filter2(SmoothFilter, SFFilter);

CombFilter = nan(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.NumTrials);

for trial_idx = 1:Parameters.NumTrials
    if ~isnan(Trial(trial_idx).Orientation)
        refori = Trial(trial_idx).Orientation+90;
        
        oLow1 = refori-Trial(trial_idx).NoiseOriProx-Parameters.OriFilterBW;
        oHigh1 = refori-Trial(trial_idx).NoiseOriProx;
        oLow2 = refori+Trial(trial_idx).NoiseOriProx;
        oHigh2 = refori+Trial(trial_idx).NoiseOriProx+Parameters.OriFilterBW;
        
        %oLow1 = 0;
        %oHigh1 = 45;
        
        %oLow
        
        %OriFilter1 = OrientationBandpass([AnnOutRadPix*2 AnnOutRadPix*2], oLow1, oHigh1);
        %OriFilter2 = OrientationBandpass([AnnOutRadPix*2 AnnOutRadPix*2], oLow2, oHigh2);
        %OriFilter = or(OriFilter1, OriFilter2);
        %OriFilter = OriFilter1;
        %OriFilter = filter2(SmoothFilter, OriFilter);
        %CombFilter(:,:,trial_idx) = OriFilter .* SFFilter; %The reason we do this per trial is because the OriFilters will vary (i.e. NoiseOriProx will)
        CombFilter(:,:,trial_idx) = SFFilter;
    end
end

%Create max contrast stimulus frame

%%% create a grating
imagesize = AnnOutRadPix*2;
[x,y] = meshgrid(-imagesize/2:imagesize/2-1,-imagesize/2:imagesize/2-1);
sigma = 1/10*length(x);                                                            % gaussian s.d.                                                     
gaussian = 1*exp((-2.77*x.^2)/(2.35*sigma)^2).*exp((-2.77*y.^2)/(2.35*sigma)^2);   % gaussian envelope

SineImg = makeSineGrating(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.SineSpatFreq, -pi/180*Trial(1).Orientation, Trial(1).Phase, 0, 1, Parameters.pixPerDeg);       
SineImg = SineImg.*AnnMask;
SineImg = SineImg*Parameters.SineAmp+Parameters.SineMean;

noise = normrnd(0, 1, AnnOutRadPix*2, AnnOutRadPix*2);       %Generate normally distributed, 2D noise
FreqNoise = fftshift(fft2(noise));                           %Take the Fourier transform to get to frequency domain
FilteredFreqNoise = FreqNoise .* CombFilter(:,:,1);          %Filter with the pre-computed filter for this trial
FilteredNoise = real(ifft2(ifftshift(FilteredFreqNoise)));   %Reverse Fourier Transform           
FilteredNoise = FilteredNoise/(max(max(FilteredNoise)));     %Normalize so FilteredNoise has a max of 1
FilteredNoise = FilteredNoise.*AnnMask*Parameters.NoiseAmp;

img = SineImg + FilteredNoise;



%% Plot everything
%{
figure;

%Top row: freq domain
fft_stim = fftshift(fft2(SineImg));  
stim_power_spectrum = abs(fft_stim);
subplot(2,4,1)
imshow(stim_power_spectrum, [0 10000]); 
subplot(2,4,2);
imshow(abs(FreqNoise), [0 1000]);
subplot(2,4,3);
imshow(CombFilter(:,:,1));
subplot(2,4,4);
imshow(abs(FilteredFreqNoise), [0 1000]);

%Bottom row: real
subplot(2,4,5);
imshow(SineImg, [0 255]);
subplot(2,4,6);
imshow(noise);
subplot(2,4,7);
imshow(FilteredNoise, [0 max(max(FilteredNoise))]);
subplot(2,4,8);
imshow(img, [0 255]);
%}
%{
%% Put on screen

[wptr, wrect] = Screen('OpenWindow', 0, Parameters.BgdColor);
tex = Screen('MakeTexture', wptr, FilteredNoise);
Screen('DrawTexture', wptr, tex, [], CenterRect([0 0 AnnOutRadPix*2 AnnOutRadPix*2], wrect));
Screen('Flip', wptr);
KbWait([],2);
Screen('Close');
Screen('CloseAll');
%}


fixDiamPix = ceil(Parameters.fixDiamDeg*Parameters.pixPerDeg)/2;
fixImg = MakeFixation(0, 255, 127, fixDiamPix*(1/3), fixDiamPix*(2/3), fixDiamPix);

 Parameters.LineDiamDeg = 0.20;
 Parameters.LineDiamPix = Parameters.LineDiamDeg*Parameters.pixPerDeg;
 LineMask = makeLinearMaskCircleAnn(AnnOutRadPix*2, AnnOutRadPix*2, ceil(sqrt((fixDiamPix)^2+(fixDiamPix)^2)/2), 0, AnnInRadPix);
 LineImg = makeLine(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.LineDiamPix); 
 LineImg(ceil(AnnOutRadPix-fixDiamPix:AnnOutRadPix+fixDiamPix-1), ceil(AnnOutRadPix-fixDiamPix:AnnOutRadPix+fixDiamPix-1)) = fixImg; 
 imshow(LineImg, [0 255]);
 

%SineImg = ones(size(SineImg))*Parameters.BgdColor;
%img(ceil(AnnOutRadPix-fixDiamPix:AnnOutRadPix+fixDiamPix-1), ceil(AnnOutRadPix-fixDiamPix:AnnOutRadPix+fixDiamPix-1)) = fixImg; 

%figure;
%imshow(img, [0 255]);

%figure;
%imshow(FilteredNoise+Parameters.SineMean, [0 255]);
%figure;
%imshow(img, [0 255]);
  

