function Experiment

clear all
Screen('Close');    %Closes any textures that might have been left open due to a dirty crash
close('all');       %Closes any open figures

addpath('Local_Functions');

try
    
%% Get Run Information

prompt = {'Subject ID:', 'Run Number:', 'Where are you?'};
title = 'Run Info';
rsp = inputdlg(prompt, title);

if (isempty(rsp{1}) || isempty(rsp{2}))
    error('Subject ID or Run Number field was left empty.')
else
    subj_id = rsp{1};
    if isnan(str2double(rsp{2}))
        error('Invalid run number entered.');
    else
        runnr = str2double(rsp{2});
    end
end

if isempty(rsp{3})
    errordlg('You must enter a location.', 'D''oh');
    return
else
    switch rsp{3}
        case 'Test'
            Situation = 0;
            LeftKeyCode = 30;
            RightKeyCode = 31;
            EscCode = 41;
            Windows = false;
        case 'Trio'
            Situation = 1;
            LeftKeyCode = 30;
            RightKeyCode = 31;
            EscCode = 1000;     %Doesn't exist;
            Windows = false;
        case 'Windows'
            Windows = true;
            Situation = 0;
            LeftKeyCode = 49;
            RightKeyCode = 50;
            EscCode = 27;
        otherwise
            errordlg('I do not recognize that place. Are you sure it exists? (Valid answers are ''Test'' or ''Trio'')', 'Really?');
            return
    end
end


savepath = 'Data_Scanning/';
filename = ['d', datestr(now,'ddmmyy'), subj_id, '_run', sprintf('%03d', runnr)];

if exist([savepath, filename, '.mat'], 'file')
    rsp = questdlg('WARNING: Data file for this subject & runnr already exists for this date. I will save the file from this session with suffix _TEMP. Continue?', 'Continue?', 'Yes', 'No', 'Yes');
    if strcmp(rsp, 'Yes')
        filename = [filename, '_TEMP'];
        if exist([savepath, filename, '.mat'], 'file')
          errordlg('Data file with suffix _TEMP already exists as well. Please start again.')
          return;
        end        
    else
        return;
    end    
end

ListenChar(2); %Now that information has been entered, stop characters leaking through                             

%% Set Global Parameters

Parameters = struct;

%SCREEN:
Parameters.Situation = Situation;
[scrnum,frameHz,pixPerDeg, wrect, calibrationFile] = GetMonitorInfo(Parameters.Situation); 
Parameters.pixPerDeg = pixPerDeg;
Parameters.frameHz = frameHz;
Parameters.calibrationFile = calibrationFile;
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

Parameters.NoiseOriProx = [15 30];  %Levels of noise orientation proximities
Parameters.NoiseContrast = 0.2;
Parameters.NoiseAmp = Parameters.SineMean*Parameters.NoiseContrast;
Parameters.NoiseUpdateFreq = 4;     %Update frequency of dynamic
                                    %noise (Hz), should prolly be faster than and perhaps integer multiple of SineTempFreq
Parameters.SFFilterLB = 0.5;        %Lower bound of noise SF bandpass filter (cyc/deg)
Parameters.SFFilterUB = 2;          %Upper bound of same
Parameters.OriFilterBW = 15;        %Bandwith (full range) of bandpasss ori filters (deg)
Parameters.SmoothSD = 4;            %Standard deviation of the Gaussian smoothing kernel applied to filters

Parameters.MatchMean = Parameters.SineMean;
Parameters.MatchContrast = Parameters.SineContrast;
Parameters.MatchAmp = Parameters.MatchMean*Parameters.MatchContrast;

Parameters.LineDiamDeg = 0.20;
Parameters.LineDiamPix = Parameters.LineDiamDeg*Parameters.pixPerDeg;

%DESIGN:
Parameters.TR = 2;                  %Duration in s of 1 TR (all other times are multiples of this)

Parameters.DummysBef = 1;           %Dummy volumes before first trial
Parameters.DummysAft = 0;           %Dummy volumes after last trial

Parameters.StimulusDuration = 0.75; 
Parameters.MatchStimType = 'Line'; %'Grating' or 'Line'
Parameters.MatchDelay = 3.25;       %Time between stimulus presentation and match task
Parameters.MatchDuration = 1.5;     %Time the match stimulus will be on screen for (=response epoch)
Parameters.MatchDim = 1;            %How far into the match task should the grating start to dim?
Parameters.ITI = 2.5;               %Inter-Trial Interval 

Parameters.TrialLength = Parameters.StimulusDuration + Parameters.MatchDelay + Parameters.MatchDuration; %Still in TRs
if mod((Parameters.TrialLength+Parameters.ITI)*Parameters.TR, Parameters.TR)
    errordlg('Trial length (including ITI) must be an integer multiple of TRs.', 'No can do!');
    return;
end

Parameters.pctFixTrials = 0.0;      %Percentage fixation trials            
Parameters.NumTrials = 20;          %NumTrials * pctFixTrials must be an integer number, and NumTrials must be an integer multiple of length(NoiseOriProx)


%% Gamma-Corrected CLUT

if Parameters.Situation ~= 0
    Parameters.meanLum = 0.5;
    Parameters.contrast = 1;
    Parameters.amp = Parameters.meanLum * Parameters.contrast;

    load(Parameters.calibrationFile, 'gamInverse', 'dacsize');
    ncolors = 255;
    mpcmaplist = zeros(256,3);
    temptrial = linspace(Parameters.meanLum-Parameters.amp, Parameters.meanLum+Parameters.amp, ncolors)';

%    bcolor_idx = find(temptrial==.5) -1;
%    black_idx = find(temptrial==0) -1;
%    white_idx = find(temptrial==1) -2;

    mpcmaplist(1:ncolors,:) = repmat(temptrial, [1 3]);
    mpcmaplist(256, 1:3) = 1;
    mpcmaplist = round(map2map(mpcmaplist, gamInverse));

    Parameters.CLUT = mpcmaplist;
end

%% Open Window

[wptr, wrect] = Screen('OpenWindow', scrnum, Parameters.BgdColor);

Screen('TextSize', wptr, Parameters.FontSize);
Screen('TextFont', wptr, Parameters.FontName);

if Parameters.Situation ~= 0
    HardwareCLUT = Screen('LoadCLUT', wptr);
    Screen('LoadCLUT', wptr, Parameters.CLUT);
end

HideCursor;

%% Make fixation bullseye & cue image

fixDiamPix = Parameters.fixDiamDeg*Parameters.pixPerDeg;
if mod(ceil(fixDiamPix),2)
    fixDiamPix = floor(fixDiamPix);
else
    fixDiamPix = ceil(fixDiampix);
end
fixRect = CenterRect([0 0 fixDiamPix fixDiamPix],wrect);
fixImg = MakeFixation(0, 255, 127, fixDiamPix*(1/3), fixDiamPix*(2/3), fixDiamPix);
fixTexture = Screen('MakeTexture', wptr, fixImg);

%cueImg = MakeFixation(0, 0, 127, fixDiamPix*(1/3), fixDiamPix*(2/3), fixDiamPix);
%cueTexture = Screen('MakeTexture', wptr, cueImg);

%% Put fixation + text on screen
%This allows subjects to start fixating while stimuli are being created

Screen('DrawTexture', wptr, fixTexture, [], fixRect);
DrawFormattedText(wptr, 'Creating first stimulus...', 50, 50, 255);
Screen('Flip', wptr);

%% Determine script for this run
%We want orientations to span the whole 180 degrees. However, orientations
%must be random. So a good way to go would be to start with n base
%orientations which are random for each run but evenly spaced, and add a
%random jitter to every presentation. 

Trial = struct;
Trial(Parameters.NumTrials).Orientation = [];
Trial(Parameters.NumTrials).Phase = [];

%Generate a list of random phases:
Phase = rand(Parameters.NumTrials,1)*2*pi;                          %Phase is in radians
PhaseList = num2cell(Phase);
[Trial(1:Parameters.NumTrials).Phase] = PhaseList{:};

%Determine proximity of noise orientation content for each trial:
PosPairs = [1 1; 1 2; 2 1; 2 2];
balanced = false;

while ~balanced; 
    paircount = nan(size(PosPairs,1),1);
    seq = shuffle(repmat([1 2], 1, Parameters.NumTrials/2));
    seqstr = num2str(seq);
    for pair_idx = 1:size(PosPairs,1);
        pairstr = num2str(PosPairs(pair_idx,:));
        found = findstr(pairstr, seqstr);
        paircount(pair_idx) = length(found);
    end
    
    paircount = paircount - max(paircount); %If all (but one) counts are the same this will make all (but one) 0 (easier to check)
    if sum(paircount==0) == size(PosPairs,1)-1, balanced = true; end
    
end

NoiseOriProx = num2cell(Parameters.NoiseOriProx(seq)');
[Trial(1:Parameters.NumTrials).NoiseOriProx] = NoiseOriProx{:};

%Determine stimulus orientation for each trial (fixation = NaN)
OriList = nan(Parameters.NumTrials, 1);
for i = 1:2
    BaseOris = linspace(0,180,Parameters.NumTrials/2+1);
    Oris = floor(BaseOris(1:end-1)' + rand(Parameters.NumTrials/2,1)*180/(length(BaseOris)-1)); %Orientation is in degrees and CW from horizontal (which means we need to use negative numbers for makeSineGrating which assumes CCW rotations)            
    OriList(seq==i) = shuffle(Oris);
end
OriList = num2cell(OriList);
[Trial(1:Parameters.NumTrials).Orientation] = OriList{:};

%% Make annulus, first stimulus, filters etc.

AnnInRadPix = ceil(Parameters.AnnInRad * Parameters.pixPerDeg);
AnnOutRadPix = ceil(Parameters.AnnOutRad * Parameters.pixPerDeg);
LinDecRadPix = ceil(Parameters.LinDecRad * Parameters.pixPerDeg);
stimRect = CenterRect([0 0 AnnOutRadPix*2 AnnOutRadPix*2],wrect);

AnnMask = makeLinearMaskCircleAnn(AnnOutRadPix*2, AnnOutRadPix*2, AnnInRadPix, LinDecRadPix, AnnOutRadPix);

LineMask = makeLinearMaskCircleAnn(AnnOutRadPix*2, AnnOutRadPix*2, ceil(sqrt((fixDiamPix)^2+(fixDiamPix)^2)/2), 0, AnnInRadPix);
LineImg = makeLine(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.LineDiamPix); 

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
        refori = Trial(trial_idx).Orientation+90; %OrientationBandpass works with direction so we need to add 90 deg. 
        OriFilter1 = OrientationBandpass([AnnOutRadPix*2 AnnOutRadPix*2], refori-Trial(trial_idx).NoiseOriProx-Parameters.OriFilterBW, refori-Trial(trial_idx).NoiseOriProx);
        OriFilter2 = OrientationBandpass([AnnOutRadPix*2 AnnOutRadPix*2], refori+Trial(trial_idx).NoiseOriProx, refori+Trial(trial_idx).NoiseOriProx+Parameters.OriFilterBW);
        OriFilter = or(OriFilter1, OriFilter2);
        OriFilter = filter2(SmoothFilter, OriFilter);
        CombFilter(:,:,trial_idx) = OriFilter .* SFFilter; %The reason we do this per trial is because the OriFilters will vary (i.e. NoiseOriProx will)
    end
end

%Create first stimulus:
if ~isnan(Trial(1).Orientation) %If this is a fixation trial, simply skip stimulus creation 
   SineImg = makeSineGrating(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.SineSpatFreq, -pi/180*Trial(1).Orientation, Trial(1).Phase, 0, 1, Parameters.pixPerDeg);         for frame_idx = 1:NumStimFrames;
       t = (frame_idx-1)*(1/Parameters.frameHz);
       contrast = sin(2*pi*t*Parameters.SineTempFreq);
       
       if ismember(frame_idx, NoiseUpdateFrames)
           noise = normrnd(0, 1, AnnOutRadPix*2, AnnOutRadPix*2);       %Generate normally distributed, 2D noise
           FreqNoise = fftshift(fft2(noise));                           %Take the Fourier transform to get to frequency domain
           FilteredFreqNoise = FreqNoise .* CombFilter(:,:,1);          %Filter with the pre-computed filter for this trial
           FilteredNoise = real(ifft2(ifftshift(FilteredFreqNoise)));   %Reverse Fourier Transform           
           FilteredNoise = FilteredNoise/(max(max(FilteredNoise)));     %Normalizing so max = 1
           FilteredNoise = FilteredNoise .* AnnMask * Parameters.NoiseAmp;
       end
       
       stim = SineImg .* AnnMask * contrast;
       stim = stim * Parameters.SineAmp + Parameters.SineMean;
       stim = stim + FilteredNoise;
       StimulusFramePtrs(frame_idx) = Screen('MakeTexture', wptr, stim);
   end       
end

%% Begin Experiment

Screen('DrawTexture', wptr, fixTexture, [], fixRect);
DrawFormattedText(wptr, 'Waiting for scanner...', 50, 50, 255);
Screen('Flip', wptr);

%SessStart = waitTrigger(Windows); 
[SessStart] = KbWait([],2);

%% Dummy volumes before first trial

Screen('DrawTexture', wptr, fixTexture, [], fixRect);
CurrTime = Screen('Flip', wptr);
if isnan(Trial(1).Orientation)
    Screen('DrawTexture', wptr, cueTexture, [], fixRect);   %Pre-draw cue in buffer for first trial (unless it is a fixtrial)
else
    Screen('DrawTexture', wptr, fixTexture, [], fixRect);
end

TrialOnsets = SessStart + Parameters.DummysBef*Parameters.TR + ((1:Parameters.NumTrials)-1)*(Parameters.TrialLength+Parameters.ITI)*Parameters.TR; %Exact timing

%% Begin trial

TrueTrialOnset = nan(Parameters.NumTrials,1);

for trial_idx = 1:Parameters.NumTrials
    
%% Stimulus presentation

    if ~isnan(Trial(trial_idx).Orientation)        
        Screen('DrawTexture', wptr, StimulusFramePtrs(1), [], stimRect);
        Screen('DrawTexture', wptr, fixTexture, [], fixRect);
        TrueTrialOnset(trial_idx) = Screen('Flip', wptr, TrialOnsets(trial_idx));                                %Presentation of first stimulus frame is synchronized to StimOnset
        for frame_idx = 2:length(StimulusFramePtrs);
            Screen('DrawTexture', wptr, StimulusFramePtrs(frame_idx), [], stimRect); 
            Screen('DrawTexture', wptr, fixTexture, [], fixRect);
            Screen('Flip', wptr);                                       %Every frame after that is just presented at each consecutive retrace
        end
        Screen('DrawTexture', wptr, fixTexture, [], fixRect);
        Screen('Flip', wptr);
    else
        Screen('DrawTexture', wptr, fixTexture, [], fixRect);
        Screen('Flip', wptr);
    end

%% Fixation period before match task
%This will take a few TRs, so enough time to do some slightly time-
%consuming stuff. So first close all stimulus textures, then generate the
%match grating movie. The remaining time will just be waited out.

    if ~isnan(Trial(trial_idx).Orientation)
        Screen('Close', StimulusFramePtrs);     %This closes all the stimulus textures (clears up vram)
        phase = rand*2*pi;
        MatchOri = rand*180;
        
        MatchDimDuration = (Parameters.MatchDuration-Parameters.MatchDim)*Parameters.TR;
        MatchDimFramePtrs = nan(MatchDimDuration*Parameters.frameHz,1);

        switch Parameters.MatchStimType
            case 'Grating'
                SineImg = makeSineGrating(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.SineSpatFreq, -MatchOri*pi/180, phase, 0, 1, Parameters.pixPerDeg);
                SineImg = SineImg .* AnnMask;
                MatchImg = SineImg * Parameters.SineAmp + Parameters.SineMean;

                MatchTexture = Screen('MakeTexture', wptr, MatchImg);

                for frame_idx = 1:length(MatchDimFramePtrs)        
                    contrast = 1 - frame_idx/length(MatchDimFramePtrs);             %Contrast decreases linearly with time
                    stim = SineImg*contrast*Parameters.SineAmp+Parameters.SineMean;
                    MatchDimFramePtrs(frame_idx) = Screen('MakeTexture', wptr, stim);        
                end 
                
                InitAngle = 0;
                
            case 'Line'
                               
                LineImg = LineImg .* LineMask;                
                MatchTexture = Screen('MakeTexture', wptr, (1-LineImg)*Parameters.BgdColor);
                
                for frame_idx = 1:length(MatchDimFramePtrs)
                    contrast = 1 - frame_idx/length(MatchDimFramePtrs);
                    stim = LineImg * contrast;
                    MatchDimFramePtrs(frame_idx) = Screen('MakeTexture', wptr, (1-stim)*Parameters.BgdColor);
                end            
                
                InitAngle = MatchOri;
                
            otherwise
                error('Match stimulus type not recognized!');
        end

        Screen('DrawTexture', wptr, MatchTexture, [], stimRect, InitAngle);        %Pre-draw match grating & fixation
        Screen('DrawTexture', wptr, fixTexture, [], fixRect);
        
        MatchOnset = TrialOnsets(trial_idx) + (Parameters.StimulusDuration+Parameters.MatchDelay)*Parameters.TR;
        MatchOffset = MatchOnset + Parameters.MatchDuration*Parameters.TR;
        MatchDimOnset = MatchOnset + Parameters.MatchDim*Parameters.TR;
        frame_idx = 1;  
    end
    
%% Match task
%Within the match duration defined in Parameters, the subject may press a
%key on their keypad to turn the grating left or right. If they press one
%of the allotted keys, that starts a keyPress. The more time elapses since
%the start of this keyPress, the faster the grating will turn in the
%corresponding direction. Keyboard status is checked continuously, except
%for short pauses in which the screen is refreshed.

    if ~isnan(Trial(trial_idx).Orientation)
        rotAngle = 0;
        prevAngle = 0;
        LastFlip = Screen('Flip', wptr, MatchOnset);
        FlushEvents('KeyDown');
        keyPress = false;
        keyPressStart = 0;
        keyPressKey = 0;        
        secs = LastFlip;
        
        while LastFlip < MatchOffset
            while secs < LastFlip + (1/Parameters.frameHz*0.5); %Check the keyboard status for 1/2 each refresh interval
              [keyIsDown, secs, keyCode] = KbCheck;
              key = find(keyCode);
              
              if keyPress
                if keyIsDown
                  if ismember(keyPressKey, key)
                    t = secs - keyPressStart;
                    if t>0  %Prevent weird things happening if t becomes negative through clock inaccuracies
                        dtAngle = 218*t^(2.13);
                        switch keyPressKey
                         case LeftKeyCode
                          rotAngle = prevAngle - dtAngle;
                         case RightKeyCode
                          rotAngle = prevAngle + dtAngle;
                        end
                    end
                  else
                    keyPress = false; %If none of the keys being pressed are the left/right keys, that ends the keypress               
                  end
                else
                  keyPress = false; %If no keys are being pressed, that ends the keypress
                end
                
              else
                
                if keyIsDown
                  if length(key) == 1 %Only start a keypress if there is only one key being pressed
                    if ismember(key, [LeftKeyCode RightKeyCode]) 
                      keyPress = true;
                      keyPressKey = key;
                      keyPressStart = secs;
                      prevAngle = rotAngle;                      
                    elseif key == EscCode, error('Experiment aborted by user.'); 
                    end %Exit on Esc press                     
                  end
                end
                
              end           
            end
         
            if LastFlip >= MatchDimOnset                
                if frame_idx <= length(MatchDimFramePtrs)
                    Screen('DrawTexture', wptr, MatchDimFramePtrs(frame_idx), [], stimRect, InitAngle + rotAngle);
                end
                frame_idx = frame_idx+1;
            else
                Screen('DrawTexture', wptr, MatchTexture, [], stimRect, InitAngle + rotAngle);
            end
            
            Screen('DrawTexture', wptr, fixTexture, [], fixRect);            

            LastFlip = Screen('Flip', wptr);
        end
        Trial(trial_idx).Response = mod(MatchOri+rotAngle,180);     %Rsp ori is the modulus of the initial match ori + the rotation angle (which are both in degrees) and 180 (so 185 deg. becomes 5 deg.)
    else
        Trial(trial_idx).Response = NaN;                            %If this is a fixtrial, explicitly identify no response
    end
    
%% Inter-Trial Interval
%Once again, nothing happens for a bit so we can use the time to clear up
%vram and generate the stimulus for the next trial (if there is one). Note
%that this interval should only occur if this not the last trial.

    Screen('DrawTexture', wptr, fixTexture, [], fixRect);           %Put (just) fixation on screen again (has to be done even if this is the last trial)
    Screen('Flip', wptr);

    if trial_idx ~= Parameters.NumTrials
        if ~isnan(Trial(trial_idx).Orientation)
            Screen('Close', [MatchTexture; MatchDimFramePtrs]);     %Close all texture in the match stimulus
        end
        
        if ~isnan(Trial(trial_idx+1).Orientation)                   %If next trial is fixation, simply skip stimulus creation 
           SineImg = makeSineGrating(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.SineSpatFreq, -pi/180*Trial(trial_idx+1).Orientation, Trial(trial_idx+1).Phase, 0, 1, Parameters.pixPerDeg);       
           for frame_idx = 1:Parameters.StimulusDuration * Parameters.TR * Parameters.frameHz;
               t = (frame_idx-1)*(1/Parameters.frameHz);
               contrast = sin(2*pi*t*Parameters.SineTempFreq);
               
               if ismember(frame_idx, NoiseUpdateFrames)
                   noise = normrnd(0, 1, AnnOutRadPix*2, AnnOutRadPix*2);       %Generate normally distributed, 2D noise
                   FreqNoise = fftshift(fft2(noise));                           %Take the Fourier transform to get to frequency domain
                   FilteredFreqNoise = FreqNoise .* CombFilter(:,:,trial_idx+1);%Filter with the pre-computed filter for this trial
                   FilteredNoise = real(ifft2(ifftshift(FilteredFreqNoise)));   %Reverse Fourier Transform           
                   FilteredNoise = FilteredNoise/(max(max(FilteredNoise)));     %Normalizing so max = 1
                   FilteredNoise = FilteredNoise .* AnnMask * Parameters.NoiseAmp;
               end

               stim = SineImg .* AnnMask * contrast;
               stim = stim * Parameters.SineAmp + Parameters.SineMean;
               stim = stim + FilteredNoise;
               StimulusFramePtrs(frame_idx) = Screen('MakeTexture', wptr, stim);

           end       
        end   
        
        Screen('DrawTexture', wptr, fixTexture, [], fixRect);    %Draw fixation for next trial        
        
    end
    
end %trial_idx

%% Dummy volumes after last trial

if Parameters.DummysAft > 0
    Screen('DrawTexture', wptr, fixTexture, [], fixRect);
    Screen('Flip', wptr);
    LastTrialEnd = TrialOnsets(end) + (Parameters.TrialDuration + Parameters.ITI)*Parameters.TR;
    while CurrTime < LastTrialEnd + Parameters.DummysAft*Parameters.TR
        WaitSecs(0.001)
        CurrTime = GetSecs;
    end
end


%% Feedback on Performance
%Compute the difference between the stimulus and response, taking
%into account the possibility that subjects are off by either + or
%-180 degrees. Then calculate accuracy as a percentage, taking into
%account the fact that deviation runs from 0-90. 

RespDeviation = nan(Parameters.NumTrials, 3);
RespDeviation(:,1) = abs([Trial.Response] - [Trial.Orientation]); 
RespDeviation(:,2) = abs([Trial.Response]+180 - [Trial.Orientation]);
RespDeviation(:,3) = abs([Trial.Response]-180 - [Trial.Orientation]);
RespDeviation = min(RespDeviation, [], 2);
AvgDeviation = round((90-nanmean(RespDeviation))/90*100);

%Screen('TextSize', wptr, 36);
%Screen('TextFont', wptr, 'Helvetica');
%FeedbackMsg = sprintf(['Accuracy in this run: ', num2str(AvgDeviation), '%%']);
%DrawFormattedText(wptr, FeedbackMsg, 'center', 'center', [0 255 0]);
%Screen('Flip', wptr);
%WaitSecs(2);

hist_x = 1:2:16;
RespDevHist = hist(RespDeviation, hist_x);
bar(hist_x, RespDevHist);
set(gca, 'XTick', 0:2:16);
axis([0 16 0 max(RespDevHist+2)]);
xlabel('Deviation (deg.)', 'FontSize', 14, 'FontWeight', 'b');
ylabel('Count', 'FontSize', 14, 'FontWeight', 'b');


%% Finish up

if Parameters.Situation == 0
  save([savepath, filename]); %If we're just testing, save everything
else
  save([savepath, filename], 'Parameters','Trial', 'RespDeviation', 'AvgDeviation'); %Otherwise, we're probably scanning, so only save the important data
end

ShowCursor;
Screen('Close');    %This closes all textures (should be done before CloseAll to prevent PTB whining)
Screen('CloseAll');
if Parameters.Situation ~= 0, Screen('LoadCLUT', wptr, HardwareCLUT); end
ListenChar(0);

%% Catch errors

catch ME
    ShowCursor;
    Screen('Close');
    Screen('CloseAll')
    if Parameters.Situation ~= 0, Screen('LoadCLUT', wptr, HardwareCLUT); end
    save DebugSaveFile;
    ListenChar(0);
    disp(ME);
    disp(ME.message);
    disp(ME.stack);
end

end

