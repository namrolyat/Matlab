function NoiseLevelsPilot(Parameters)

addpath('Local_Functions');

%% Allow start with default Parameters if none were given as argin:
if nargin == 0    

    Parameters = struct;

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
            case 'MacTest'
                Situation = 0;
                RspKeys = [30 31 32 33];            
                EscCode = 41;
                Windows = false;
                savepath = 'TestData/';
            case 'Trio'
                Situation = 1;
                RspKeys = [30 31 32 33];            
                EscCode = 1000;     %Doesn't exist;
                Windows = false;
                savepath = 'ScanData/';
            case 'BLab2'
                Situation = 2;
                RspKeys = [30 31 32 33];    %Verify this!
                EscCode = 41;
                Windows = false;  
                savepath = 'PilotData/';
            case 'WindowsTest'
                Windows = true;
                Situation = 0;
                RspKeys = [49 50 51 52];            
                EscCode = 27;
                savepath = 'TestData/';
            otherwise
                errordlg('I do not recognize that place. Are you sure it exists? (Valid answers are ''MacTest'', ''WindowsTest'',  ''Trio'' or ''BLab2'')', 'Really?');                
                return
        end
    end

    Parameters.LeftKeyCode = RspKeys(1);
    Parameters.RightKeyCode = RspKeys(2);
    Parameters.RspKeys = RspKeys;           %Consider counter-balancing the key-mapping here (i.e. l-r = 1-4 vs. l-r = 4-1)
    Parameters.Windows = Windows;
    Parameters.EscCode = EscCode;
    Parameters.RspKeys = RspKeys;

    if ~exist(savepath, 'dir'), mkdir(savepath); end
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

    Parameters.savepath = savepath;
    Parameters.filename = filename;   
    
    Parameters.Experiment = 'NoiseLevelsPilot';
    Parameters.CLabels = 0:3;


    %SCREEN:
    Parameters.Situation = Situation;
    [scrnum,frameHz,pixPerDeg, wrect, calibrationFile] = GetMonitorInfo(Parameters.Situation); 
    Parameters.scrnum = scrnum;
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
    Parameters.SineContrast = 0.1;
    Parameters.SineAmp = Parameters.SineMean*Parameters.SineContrast;
    Parameters.SineSpatFreq = 1;        %Spatial frequency of grating (cyc/deg)
    Parameters.SineTempFreq = 2;        %Temporal frequency of contrast modulation (Hz)

    %Parameters.NoiseOriProx = [15 30];  %Levels of noise orientation proximities
    Parameters.NoiseContrast = 0.3;
    Parameters.NoiseAmp = Parameters.SineMean*Parameters.NoiseContrast;
    Parameters.NoiseUpdateFreq = 4;     %Update frequency of dynamic noise (Hz), should prolly be faster than and perhaps (not) integer multiple of SineTempFreq
    Parameters.SFFilterLB = 0.5;        %Lower bound of noise SF bandpass filter (cyc/deg)
    Parameters.SFFilterUB = 2;          %Upper bound of same
    Parameters.SmoothSD = 4;            %Standard deviation of the Gaussian smoothing kernel applied to filters

    Parameters.MatchMean = Parameters.SineMean;
    Parameters.MatchContrast = Parameters.SineContrast;
    Parameters.MatchAmp = Parameters.MatchMean*Parameters.MatchContrast;

    Parameters.LineDiamDeg = 0.20;    
    Parameters.LineLengthDeg = 1.4;     %"Radius" from the centre    
    
    %DESIGN:
    Parameters.TR = 2;                  %Duration in s of 1 TR (all other times are multiples of this)

    Parameters.DummysBef = 2;           %Dummy volumes before first trial
    Parameters.DummysAft = 0;           %Dummy volumes after last trial

    Parameters.StimulusDuration = 0.75; 
    Parameters.MatchStimType = 'Line'; %'Grating' or 'Line'
    Parameters.MatchDelay = 3.25;       %Time between stimulus presentation and match task
    Parameters.MatchDuration = 1.5;     %Time the match stimulus will be on screen for (=response epoch)
    Parameters.MatchDim = 1;            %How far into the match task should the grating start to dim?
    Parameters.ITI = 2.5;               %Inter-Trial Interval 

    Parameters.CueDelay = 0.125;
    Parameters.CueDuration = 0.125;
    Parameters.CRInterval = 0.75;       %Leaves 1.5 TRs (3s) to build new stimuli (should be enough)

    Parameters.TrialLength = Parameters.StimulusDuration + Parameters.MatchDelay + Parameters.MatchDuration; %Still in TRs
    if mod((Parameters.TrialLength+Parameters.ITI)*Parameters.TR, Parameters.TR)
        errordlg('Trial length (including ITI) must be an integer multiple of TRs.', 'No can do!');
        return;
    end

    Parameters.pctFixTrials = 0.0;      %Percentage fixation trials            
    Parameters.NumTrials = 18;           %NumTrials * pctFixTrials must be an integer number, and NumTrials must be an integer multiple of length(NoiseOriProx)
    
    %RANDOMIZATION:
    Parameters.RandSeed = sum(100*clock); 
    
end

ListenChar(2); %Now that information has been entered, stop characters leaking through                             
rand('twister', Parameters.RandSeed); 

try

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

[wptr, wrect] = Screen('OpenWindow', Parameters.scrnum, Parameters.BgdColor);

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

cueImg = MakeFixation(0, 0, 127, fixDiamPix*(1/3), fixDiamPix*(2/3), fixDiamPix);
cueTexture = Screen('MakeTexture', wptr, cueImg);

failImg = MakeFixation(255, 255, 127, fixDiamPix*(1/3), fixDiamPix*(2/3), fixDiamPix);
failImg = cat(3, failImg, cueImg, cueImg);
failTexture = Screen('MakeTexture', wptr, failImg);

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

nconds = length(Parameters.CLabels);
if mod(Parameters.NumTrials,nconds), error('Number of trials must be an integer multiple of number of conditions.'); end
noiselevels = num2cell(shuffle(repmat((1:4)', Parameters.NumTrials/nconds,1)));
[Trial(1:Parameters.NumTrials).NoiseLevel] = noiselevels{:};

%Determine stimulus orientation for each trial (fixation = NaN)
BaseOris = linspace(0,180,Parameters.NumTrials/nconds+1);
Oris = floor(repmat(BaseOris(1:end-1),nconds,1) + rand(nconds,Parameters.NumTrials/nconds)*180/length(BaseOris)-1);

OriList = num2cell(shuffle(Oris));
[Trial(1:Parameters.NumTrials).Orientation] = OriList{:};

%% Make annulus, first stimulus, filters etc.

AnnInRadPix = ceil(Parameters.AnnInRad * Parameters.pixPerDeg);
AnnOutRadPix = ceil(Parameters.AnnOutRad * Parameters.pixPerDeg);
LinDecRadPix = ceil(Parameters.LinDecRad * Parameters.pixPerDeg);
stimRect = CenterRect([0 0 AnnOutRadPix*2 AnnOutRadPix*2],wrect);

AnnMask = makeLinearMaskCircleAnn(AnnOutRadPix*2, AnnOutRadPix*2, AnnInRadPix, LinDecRadPix, AnnOutRadPix);

Parameters.LineDiamPix = Parameters.LineDiamDeg*Parameters.pixPerDeg;
Parameters.LineLengthPix = Parameters.LineLengthDeg*Parameters.pixPerDeg;
LineMask = makeLinearMaskCircleAnn(AnnOutRadPix*2, AnnOutRadPix*2, ceil(sqrt((fixDiamPix)^2+(fixDiamPix)^2)/2), 0, Parameters.LineLengthPix);
LineImg = makeLine(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.LineDiamPix); 

%Frames:
NumStimFrames = Parameters.StimulusDuration * Parameters.TR * Parameters.frameHz/2; %Update every other frame (assuming 60 hz here; at much higher frame rates this may not work)
StimulusFramePtrs = nan(NumStimFrames,1);
StimFrameSequence = reshape(repmat(1:NumStimFrames,2,1),NumStimFrames*2,1)';

NoiseFrameSpacing = (frameHz/2)/Parameters.NoiseUpdateFreq;
NoiseUpdateFrames = floor(1:NoiseFrameSpacing:NumStimFrames);

%Filters:
fNyquist = pixPerDeg/2; 
SmoothFilter = fspecial('gaussian', 10, Parameters.SmoothSD);
SFFilter = Bandpass2([AnnOutRadPix*2 AnnOutRadPix*2], Parameters.SFFilterLB/fNyquist, Parameters.SFFilterUB/fNyquist);
SFFilter = filter2(SmoothFilter, SFFilter);

%Create first stimulus:

if ~isnan(Trial(1).Orientation) %If this is a fixation trial, simply skip stimulus creation 
   SineImg = makeSineGrating(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.SineSpatFreq, -pi/180*Trial(1).Orientation, Trial(1).Phase, 0, 1, Parameters.pixPerDeg);         
   noiseframe_idx = 1;
   Trial(1).SineImg = SineImg;
   for frame_idx = 1:NumStimFrames;
       t = (frame_idx-1)*(2/Parameters.frameHz);
       contrast = sin(2*pi*t*Parameters.SineTempFreq);
       
       if ismember(frame_idx, NoiseUpdateFrames)
           noise = normrnd(0, 1, AnnOutRadPix*2, AnnOutRadPix*2);       %Generate normally distributed, 2D noise
           FreqNoise = fftshift(fft2(noise));                           %Take the Fourier transform to get to frequency domain
           FilteredFreqNoise = FreqNoise .* SFFilter;                   %Filter with the pre-computed SF Filter
           FilteredNoise = real(ifft2(ifftshift(FilteredFreqNoise)));   %Reverse Fourier Transform           
           FilteredNoise = FilteredNoise/(max(max(FilteredNoise)));     %Normalizing so max = 1
           FilteredNoise = FilteredNoise .* AnnMask * Parameters.NoiseAmp;
           
           %Store all frames for saving:
           Trial(1).NoiseFrame(noiseframe_idx).noise = noise;
           Trial(1).NoiseFrame(noiseframe_idx).FilteredNoise = FilteredNoise;   
           noiseframe_idx = noiseframe_idx+1;
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

SessStart = waitTrigger(Parameters.Windows); 

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
        TrueTrialOnset(trial_idx) = Screen('Flip', wptr, TrialOnsets(trial_idx));   %Presentation of first stimulus frame is synchronized to StimOnset
        for frame_idx = StimFrameSequence(2:end);            
            Screen('DrawTexture', wptr, StimulusFramePtrs(frame_idx), [], stimRect); 
            Screen('DrawTexture', wptr, fixTexture, [], fixRect);
            Screen('Flip', wptr);                                                   %Every frame after that is just presented at each consecutive retrace
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
                         case Parameters.LeftKeyCode
                          rotAngle = prevAngle - dtAngle;
                         case Parameters.RightKeyCode
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
                    if ismember(key, [Parameters.LeftKeyCode Parameters.RightKeyCode]) 
                      keyPress = true;
                      keyPressKey = key;
                      keyPressStart = secs;
                      prevAngle = rotAngle;                      
                    elseif key == Parameters.EscCode, error('Experiment aborted by user.'); 
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
%that this interval should only occur if this not the last trial. Also, we
%first need to allow for the Confidence Rating buttonpress.
    
    %Flash cue for CR buttonpress:
    Screen('DrawTexture', wptr, cueTexture, [], fixRect);           
    CueOnset = MatchOffset+Parameters.CueDelay*Parameters.TR;
    Screen('Flip', wptr, CueOnset);
    CueOffset = CueOnset + Parameters.CueDuration*Parameters.TR;
    Screen('DrawTexture', wptr, fixTexture, [], fixRect);
    Screen('Flip', wptr, CueOffset);
    
    %Record CR buttonpress:
    CRIntervalEnd = CueOffset + Parameters.CRInterval*Parameters.TR;
    Responded = false;
    Trial(trial_idx).ConfidenceRating = NaN;
    while ~Responded && secs < CRIntervalEnd
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyIsDown
            key = find(keyCode);
            if length(key) == 1 && ismember(key(1), Parameters.RspKeys)
                Responded = true;
                Trial(trial_idx).ConfidenceRating = find(Parameters.RspKeys == key(1));
            end                
        end        
    end
    
    %If subject failed to respond, flash fail cue:
    if ~Responded        
        Screen('DrawTexture', wptr, failTexture, [], fixRect);
        LastFlip = Screen('Flip', wptr);
        Screen('DrawTexture', wptr, fixTexture, [], fixRect);
        Screen('Flip', wptr, LastFlip + Parameters.CueDuration*Parameters.TR);
    end        
    
    %Make stimulus for next trial:    
    if trial_idx ~= Parameters.NumTrials
        if ~isnan(Trial(trial_idx).Orientation)
            Screen('Close', [MatchTexture; MatchDimFramePtrs]);     %Close all texture in the match stimulus
        end
        
        if ~isnan(Trial(trial_idx+1).Orientation)                   %If next trial is fixation, simply skip stimulus creation 
           SineImg = makeSineGrating(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.SineSpatFreq, -pi/180*Trial(trial_idx+1).Orientation, Trial(trial_idx+1).Phase, 0, 1, Parameters.pixPerDeg);       
           Trial(trial_idx).SineImg = SineImg;
           noiseframe_idx = 1;
           for frame_idx = 1:NumStimFrames
               t = (frame_idx-1)*(2/Parameters.frameHz);
               contrast = sin(2*pi*t*Parameters.SineTempFreq);
               
               if ismember(frame_idx, NoiseUpdateFrames)
                   noise = normrnd(0, 1, AnnOutRadPix*2, AnnOutRadPix*2);       %Generate normally distributed, 2D noise
                   FreqNoise = fftshift(fft2(noise));                           %Take the Fourier transform to get to frequency domain
                   FilteredFreqNoise = FreqNoise .* SFFilter;                   %Filter with the pre-computed SF Filter
                   FilteredNoise = real(ifft2(ifftshift(FilteredFreqNoise)));   %Reverse Fourier Transform           
                   FilteredNoise = FilteredNoise/(max(max(FilteredNoise)));     %Normalizing so max = 1
                   FilteredNoise = FilteredNoise .* AnnMask * Parameters.NoiseAmp;
                   
                   %Store all frames for saving:
                   Trial(trial_idx).NoiseFrame(noiseframe_idx).noise = noise;
                   Trial(trial_idx).NoiseFrame(noiseframe_idx).FilteredNoise = FilteredNoise;     
                   noiseframe_idx = noiseframe_idx+1;
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
%-180 degrees. Then plot the distribution of these differences.

RespDeviation = nan(Parameters.NumTrials, 3);
RespDeviation(:,1) = [Trial.Response] - [Trial.Orientation]; 
RespDeviation(:,2) = [Trial.Response]+180 - [Trial.Orientation];
RespDeviation(:,3) = [Trial.Response]-180 - [Trial.Orientation];
[m,sortIdx] = sort(abs(RespDeviation),2);
for j = 1:size(sortIdx,1)
    RespDeviation(j,:) = RespDeviation(j,sortIdx(j,:)); %Sort so that the smallest deviations are in the first column (sort by lowest absolute value but don't *take* the absolute value)
end

hist_x = -15:6:15;
tick_x = -18:6:18;
RespDevHist = hist(RespDeviation(:,1), hist_x);
bar(hist_x, RespDevHist);
set(gca, 'XTick', tick_x);
axis([-18 18 0 max(RespDevHist)+2]);
xlabel('Deviation (deg.)', 'FontSize', 14, 'FontWeight', 'b');
ylabel('Count', 'FontSize', 14, 'FontWeight', 'b');


%% Finish up


save([Parameters.savepath, Parameters.filename]); %save *everything*

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

