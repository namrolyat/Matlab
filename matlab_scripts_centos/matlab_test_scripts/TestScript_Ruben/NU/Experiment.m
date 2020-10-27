function Experiment(Parameters)

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
                CRChars = 1:4; 
            case 'Trio'
                Situation = 1;
                RspKeys = [30 31 32 33];            
                EscCode = 1000;     %Doesn't exist;
                Windows = false;
                savepath = 'ScanData/';                
                CRChars = 1:4;      %CHECK THIS BEFORE SCANNING!!
            case 'BLab2'
                Situation = 2;
                RspKeys = [30 31 32 33];    %Verify this!
                EscCode = 41;
                Windows = false;  
                savepath = 'PilotData/';
                CRChars = 1:4; 
            case 'WindowsTest'
                Windows = true;
                Situation = 0;
                RspKeys = [49 50 51 52];            
                EscCode = 27;
                savepath = 'TestData/';
                CRChars = 1:4; 
            case 'LinuxTest'
                Windows = true;
                Situation = 0;
                RspKeys = [11 12 13 14];
                EscCode = 10;
                savepath = 'TestData/';
                CRChars = 1:4;
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
    Parameters.CRChars = CRChars;

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

    %SCREEN:
    Parameters.Situation = Situation;
    [scrnum,frameHz,pixPerDeg, wrect, calibrationFile] = GetMonitorInfo(Parameters.Situation); 
    Parameters.scrnum = scrnum;
    Parameters.pixPerDeg = pixPerDeg;
    Parameters.frameHz = frameHz;
    Parameters.calibrationFile = calibrationFile;
    Parameters.BgdColor = 127;
    Parameters.FontName = 'Verdana';
    Parameters.FontSize = 0.5; %In degrees :)

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
    Parameters.NoiseContrast = 0.4;
    Parameters.NoiseAmp = Parameters.SineMean*Parameters.NoiseContrast;
    Parameters.NoiseUpdateFreq = 7;     %Update frequency of dynamic noise (Hz), should prolly be faster than and perhaps (not) integer multiple of SineTempFreq
    Parameters.SFFilterLB = 0.5;        %Lower bound of noise SF bandpass filter (cyc/deg)
    Parameters.SFFilterUB = 2;          %Upper bound of same
    Parameters.SmoothSD = 4;            %Standard deviation of the Gaussian smoothing kernel applied to filters

    Parameters.MatchMean = Parameters.SineMean;
    Parameters.MatchContrast = Parameters.SineContrast;
    Parameters.MatchAmp = Parameters.MatchMean*Parameters.MatchContrast;

    Parameters.LineDiamDeg = 0.10;    
    Parameters.LineLengthDeg = 1.4;     %"Radius" from the centre    
    
    %DESIGN:
    Parameters.TR = 2;                  %Duration in s of 1 TR (all other times are multiples of this)

    Parameters.DummysBef = 2;           %Dummy volumes before first trial
    Parameters.DummysAft = 0;           %Dummy volumes after last trial

    Parameters.StimulusDuration = 0.75; 
    Parameters.MatchStimType = 'Line'; %'Grating' or 'Line'
    Parameters.MatchDelay = 3.25;       %Time between stimulus presentation and match task
    Parameters.MatchDuration = 2.0;     %Time the match stimulus will be on screen for (=response epoch)
    Parameters.MatchDim = 1.5;          %How far into the match task should the grating start to dim?
    Parameters.ITI = 2;                 %Inter-Trial Interval 

    Parameters.CueDelay = 0.0;
    Parameters.CueDuration = 0.125;
    Parameters.CRInterval = 1.0;       

    Parameters.TrialLength = Parameters.StimulusDuration + Parameters.MatchDelay + Parameters.MatchDuration; %Still in TRs
    if mod((Parameters.TrialLength+Parameters.ITI)*Parameters.TR, Parameters.TR)
        errordlg('Trial length (including ITI) must be an integer multiple of TRs.', 'No can do!');
        return;
    end

    Parameters.pctFixTrials = 0.0;      %Percentage fixation trials            
    Parameters.NumTrials = 10   ;           %NumTrials * pctFixTrials must be an integer number, and NumTrials must be an integer multiple of length(NoiseOriProx)
    
    %CONFIDENCE RATINGS:
    Parameters.Training = true;       %This determines, amongst other things, whether CI templates will be shown during the CR interval
    Parameters.CIs = 8:8:32;      %Half-range of CIs (i.e. within how many degrees do people think they are)
    Parameters.CIOffsetDeg = 2;
    Parameters.CIOffsetPix = Parameters.CIOffsetDeg * Parameters.pixPerDeg;
    Parameters.NumOffsetDeg = 1;
    Parameters.NumOffsetPix = Parameters.NumOffsetDeg * Parameters.pixPerDeg;
        
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
Screen('BlendFunction', wptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

Parameters.FontSize = round(Parameters.FontSize*Parameters.pixPerDeg);
if Parameters.Windows, Parameters.FontSize = round(Parameters.FontSize * 72/96); end %Fix the Mac/Windows font size problem (read: the Steve Jobs/Bill Gates penis problem)x

Screen('Preference', 'DefaultFontSize', Parameters.FontSize);
Screen('Preference', 'DefaultFontName', Parameters.FontName);
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

% failImg = MakeFixation(255, 255, 127, fixDiamPix*(1/3), fixDiamPix*(2/3), fixDiamPix);
% failImg = cat(3, failImg, cueImg, cueImg);
% failTexture = Screen('MakeTexture', wptr, failImg);

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

%Determine stimulus orientation for each trial (fixation = NaN)
BaseOris = linspace(0,180,Parameters.NumTrials+1);
Oris = floor(BaseOris(1:end-1)' + rand(Parameters.NumTrials,1)*180/(length(BaseOris)-1)); %Orientation is in degrees and CW from horizontal (which means we need to use negative numbers for makeSineGrating which assumes CCW rotations)            
OriList = num2cell(Shuffle(Oris));
[Trial(1:Parameters.NumTrials).Orientation] = OriList{:};

ConfidenceRatings = nan(2, Parameters.NumTrials);

%% Make annulus, first stimulus, filters etc.

%Annulus:
AnnInRadPix = ceil(Parameters.AnnInRad * Parameters.pixPerDeg);
AnnOutRadPix = ceil(Parameters.AnnOutRad * Parameters.pixPerDeg);
LinDecRadPix = ceil(Parameters.LinDecRad * Parameters.pixPerDeg);
stimRect = CenterRect([0 0 AnnOutRadPix*2 AnnOutRadPix*2],wrect);
AnnMask = makeLinearMaskCircleAnn(AnnOutRadPix*2, AnnOutRadPix*2, AnnInRadPix, LinDecRadPix, AnnOutRadPix);

%Match bar
Parameters.LineDiamPix = Parameters.LineDiamDeg*Parameters.pixPerDeg;
Parameters.LineLengthPix = Parameters.LineLengthDeg*Parameters.pixPerDeg;
LineMask = makeLinearMaskCircleAnn(AnnOutRadPix*2, AnnOutRadPix*2, ceil(sqrt((fixDiamPix)^2+(fixDiamPix)^2)/2), 0, Parameters.LineLengthPix);
LineImg = makeLine(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.LineDiamPix); 
LineImg = LineImg .* LineMask;             

%CI template stuff:
if Parameters.Training  
    disp('here');
    CITextures = zeros(4,1);
    CIbgd = cat(3,ones(ceil(Parameters.LineLengthPix*2))*Parameters.BgdColor,ones(ceil(Parameters.LineLengthPix*2))*255);    
    CILineImg = makeLine(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.LineDiamPix); 
    CILineImg = CILineImg .* LineMask;  
    CILineImg = CILineImg*255;
    CILineImg = cat(3,zeros(AnnOutRadPix*2),CILineImg);
    CILineTexture = Screen('MakeTexture', wptr, CILineImg);
    CIArcRect = [0 0 floor(Parameters.LineLengthPix*2) ceil(Parameters.LineLengthPix*2)];
    
    Numbers = 1:4;
    NumTextures = zeros(length(Numbers),1);
    numRects = nan(length(Numbers),4);      
        
    CIFixRects = nan(4,4);
    CILineRects = nan(4,4);
    CIArcRects = nan(4,4);    
    
    for CI_idx = 1:4        
        [x,y] = RectCenter(wrect);
        if mod(CI_idx,2)
            x_offset = -Parameters.CIOffsetPix; 
        else
            x_offset = Parameters.CIOffsetPix;
        end
        if CI_idx <= 2
            y_offset = -Parameters.CIOffsetPix;
        else
            y_offset = Parameters.CIOffsetPix;
        end        
        
        CITextures(CI_idx) = Screen('MakeTexture', wptr, CIbgd);
        Screen('FillArc', CITextures(CI_idx), [255 0 0], CIArcRect, 0-90-Parameters.CIs(CI_idx), Parameters.CIs(CI_idx)*2);
        Screen('FillArc', CITextures(CI_idx), [255 0 0],  CIArcRect, 0-90-Parameters.CIs(CI_idx)-180, Parameters.CIs(CI_idx)*2);
        CutOutRect = CenterRect([0 0 ceil(sqrt((fixDiamPix)^2+(fixDiamPix)^2)) ceil(sqrt((fixDiamPix)^2+(fixDiamPix)^2))], CIArcRect);
        Screen('FillArc', CITextures(CI_idx), [127 127 127], CutOutRect, 0,360);
        
        CIFixRects(CI_idx,:) = round(CenterRectOnPoint(fixRect, x+x_offset, y+y_offset));
        CILineRects(CI_idx,:) = round(CenterRectOnPoint(stimRect, x+x_offset, y+y_offset));
        CIArcRects(CI_idx,:) = round(CenterRectOnPoint(CIArcRect, x+x_offset, y+y_offset));
        
        tb = Screen('TextBounds', wptr, num2str(Numbers(CI_idx)));
        numBgd = ones(tb(4), tb(3))*Parameters.BgdColor;    
        NumTextures(CI_idx) = Screen('MakeTexture', wptr, numBgd);
        DrawFormattedText(NumTextures(CI_idx), num2str(Numbers(CI_idx)), 0, 0, 0);        
        
        [x,y] = RectCenter(CIFixRects(CI_idx,:));        
        if mod(CI_idx,2)
            numRects(CI_idx,:) = round(CenterRectOnPoint(tb, CIArcRects(CI_idx,1)-Parameters.NumOffsetPix, y));
        else
            numRects(CI_idx,:) = round(CenterRectOnPoint(tb, CIArcRects(CI_idx,3)+Parameters.NumOffsetPix, y));
        end            
    end    
end          

%Frames:
NumStimFrames = Parameters.StimulusDuration * Parameters.TR * Parameters.frameHz/2; %Update every other frame (assuming 60 hz here; at much higher frame rates this may not work)
StimulusFramePtrs = nan(NumStimFrames,1);
StimFrameSequence = reshape(repmat(1:NumStimFrames,2,1),NumStimFrames*2,1)';

NoiseFrameSpacing = (Parameters.frameHz/2)/Parameters.NoiseUpdateFreq;
NoiseUpdateFrames = floor(1:NoiseFrameSpacing:NumStimFrames);

%Filters:
fNyquist = Parameters.pixPerDeg/2; 
SmoothFilter = fspecial('gaussian', 10, Parameters.SmoothSD);
SFFilter = Bandpass2([AnnOutRadPix*2 AnnOutRadPix*2], Parameters.SFFilterLB/fNyquist, Parameters.SFFilterUB/fNyquist);
SFFilter = filter2(SmoothFilter, SFFilter);

%Create first stimulus:
if ~isnan(Trial(1).Orientation) %If this is a fixation trial, simply skip stimulus creation 
   SineImg = makeSineGrating(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.SineSpatFreq, -pi/180*Trial(1).Orientation, Trial(1).Phase, 0, 1, Parameters.pixPerDeg);         
   noiseframe_idx = 1;
   %TrialImages(1).SineImg = SineImg;
   for frame_idx = 1:NumStimFrames;
       t = (frame_idx-1)*(2/Parameters.frameHz);
       contrast = sin(2*pi*t*Parameters.SineTempFreq);
       
       if ismember(frame_idx, NoiseUpdateFrames)
           %noise = normrnd(0, 1, AnnOutRadPix*2, AnnOutRadPix*2);       %Generate normally distributed, 2D noise
           noise = randn(AnnOutRadPix*2, AnnOutRadPix*2);
           FreqNoise = fftshift(fft2(noise));                           %Take the Fourier transform to get to frequency domain
           FilteredFreqNoise = FreqNoise .* SFFilter;                   %Filter with the pre-computed SF Filter
           FilteredNoise = real(ifft2(ifftshift(FilteredFreqNoise)));   %Reverse Fourier Transform           
           FilteredNoise = FilteredNoise/(max(max(FilteredNoise)));     %Normalizing so max = 1
           FilteredNoise = FilteredNoise .* AnnMask * Parameters.NoiseAmp;
           
           %Store all frames for saving:           
           %TrialImages(1).NoiseFrame(noiseframe_idx).Image = FilteredNoise;   
           noiseframe_idx = noiseframe_idx+1;
       end
       
       stim = SineImg .* AnnMask * contrast;
       stim = stim * Parameters.SineAmp + Parameters.SineMean;
       stim = stim + FilteredNoise;
       StimulusFramePtrs(frame_idx) = Screen('MakeTexture', wptr, stim);              
   end       
end

%% Begin Experiment

%If scanning, display waiting for scanner in the upper left corner. If not,
%display in center so subjects can see it, and ask them for a keypress to
%start.

%This is for simulating keypresses to allow GetChar later on:
import java.awt.Robot; 
import java.awt.event.*; 
SimKey=Robot; 

switch Parameters.Situation
    case 1
        msg = 'Waiting for scanner...';
        sx = 50;
        sy = 50;
        Screen('DrawTexture', wptr, fixTexture, [], fixRect);
    otherwise
        msg = 'Press any key to begin...';
        %msg = 'Parse any kid to beguile...';
        sx = 'center';
        sy = 'center';
end
DrawFormattedText(wptr, msg, sx, sy, 255);
Screen('Flip', wptr);

SessStart = waitTrigger(Parameters.Situation, Parameters.Windows); 

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
                               
                
                MatchTexture = Screen('MakeTexture', wptr, (1-LineImg*0.5)*Parameters.BgdColor);
                
                for frame_idx = 1:length(MatchDimFramePtrs)
                    contrast =  0.5 - 0.5*frame_idx/length(MatchDimFramePtrs);
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
              [keyIsDown, secs, keyCode] = KbCheck();
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
%that this interval should only occur even if this is the last trial,
%because we also want to record the CR buttonpress. We will do this in a
%way that doesn't require listening to the keyboard the whole time, i.e.
%using the event queue. 
    
    %Flash cue for CR buttonpress:
    Screen('DrawTexture', wptr, cueTexture, [], fixRect);           
    CueOnset = MatchOffset+Parameters.CueDelay*Parameters.TR;
    Screen('Flip', wptr, CueOnset);
    CueOffset = CueOnset + Parameters.CueDuration*Parameters.TR;
    
    %Optionally, put CI interval templates on screen
    if Parameters.Training        
        for CI_idx = 1:4         
            Screen('DrawTexture', wptr, CITextures(CI_idx), [], CIArcRects(CI_idx,:), InitAngle + rotAngle);
            Screen('DrawTexture', wptr, fixTexture, [], CIFixRects(CI_idx,:));
            Screen('DrawTexture', wptr, CILineTexture, [], CILineRects(CI_idx,:), InitAngle + rotAngle);
            Screen('DrawTexture', wptr, NumTextures(CI_idx), [], numRects(CI_idx,:));        
        end    
    end    
    
    Screen('DrawTexture', wptr, fixTexture, [], fixRect);   Screen('DrawTexture', wptr, fixTexture, [], fixRect);   
    Screen('Flip', wptr, CueOffset);   
    CREnd = CueOffset + Parameters.CRInterval*Parameters.TR;    
    
    FlushEvents('KeyDown');
    TrialCRs = [];
    
    %Make stimulus for next trial:

    if trial_idx ~= Parameters.NumTrials
        if ~isnan(Trial(trial_idx).Orientation)
            Screen('Close', [MatchTexture; MatchDimFramePtrs]);     %Close all texture in the match stimulus
        end

        if ~isnan(Trial(trial_idx+1).Orientation)                   %If next trial is fixation, simply skip stimulus creation 
           SineImg = makeSineGrating(AnnOutRadPix*2, AnnOutRadPix*2, Parameters.SineSpatFreq, -pi/180*Trial(trial_idx+1).Orientation, Trial(trial_idx+1).Phase, 0, 1, Parameters.pixPerDeg);       
           %TrialImages(trial_idx).SineImg = SineImg;
           noiseframe_idx = 1;
           for frame_idx = 1:NumStimFrames
               t = (frame_idx-1)*(2/Parameters.frameHz);
               contrast = sin(2*pi*t*Parameters.SineTempFreq);

               if ismember(frame_idx, NoiseUpdateFrames)
                   %noise = normrnd(0, 1, AnnOutRadPix*2, AnnOutRadPix*2);       %Generate normally distributed, 2D noise
                   noise = randn(AnnOutRadPix*2, AnnOutRadPix*2);               %Using randn bypasses the Statistics Toolbox (which has a limited number of licenses) and presumably does the same?
                   FreqNoise = fftshift(fft2(noise));                           %Take the Fourier transform to get to frequency domain
                   FilteredFreqNoise = FreqNoise .* SFFilter;                   %Filter with the pre-computed SF Filter
                   FilteredNoise = real(ifft2(ifftshift(FilteredFreqNoise)));   %Reverse Fourier Transform           
                   FilteredNoise = FilteredNoise/(max(max(FilteredNoise)));     %Normalizing so max = 1
                   FilteredNoise = FilteredNoise .* AnnMask * Parameters.NoiseAmp;

                   %Store all frames for saving:                   
                   %TrialImages(trial_idx).NoiseFrame(noiseframe_idx).Image = FilteredNoise;     
                   noiseframe_idx = noiseframe_idx+1;
               end

               stim = SineImg .* AnnMask * contrast;
               stim = stim * Parameters.SineAmp + Parameters.SineMean;
               stim = stim + FilteredNoise;
               StimulusFramePtrs(frame_idx) = Screen('MakeTexture', wptr, stim);            

           end       
        end   
    end

    
    while secs < CREnd
        WaitSecs(0.001);
        secs = GetSecs;
    end
    
    if Parameters.Training
        Screen('DrawTexture', wptr, fixTexture, [], fixRect);   
        Screen('Flip', wptr);
    end
    
    %This bit of code checks whether any keys were pressed during the CR
    %Interval, which is to say in the background, while our script was
    %running. THIS FEATURE IS NOT SUPPORTED FOR WINDOWS. In fact, running
    %this code on Windows will cause the programme to halt, which is why
    %it's turned off. Note that this means no CRs are recorded under
    %Windows.
    if ~Parameters.Windows

        SimKey.keyPress(KeyEvent.VK_E); %This ensures the last keypress is always 'e'
        ch = 'b';

        while ~strcmp(ch,'e')
            ch = GetChar;
            if ismember(str2double(ch), Parameters.CRChars)             
                TrialCRs = [TrialCRs; find(Parameters.CRChars == str2double(ch))];             
            end
        end
        
        if ~isempty(TrialCRs)
            ConfidenceRatings(1,trial_idx) = TrialCRs(1);                   %Store both the first and last entered confidence rating. Do this in rows to preserve compatibility.
            if length(TrialCRs) > 1 
                ConfidenceRatings(2,trial_idx) = TrialCRs(end);
            else
                ConfidenceRatings(2,trial_idx) = NaN;
            end
        end
    
    end
    
    if trial_idx ~= Parameters.NumTrials
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

clear('noise', 'SineImg', 'FilteredNoise', 'stim', 'FilteredFreqNoise', 'SimKey'); %Prevent double (already in Trial struct) and unnecessary storage

save([Parameters.savepath, Parameters.filename]); %save *everything*

ShowCursor;
if Parameters.Situation ~= 0, Screen('LoadCLUT', Parameters.scrnum, HardwareCLUT); end
Screen('Close');    %This closes all textures (should be done before CloseAll to prevent PTB whining)
Screen('CloseAll');
ListenChar(0);

%% Catch errors

catch ME
    ShowCursor;
    disp(ME);
    disp(ME.message);
    disp(ME.stack);
    if Parameters.Situation ~= 0, Screen('LoadCLUT', Parameters.scrnum, HardwareCLUT); end
    Screen('Close');
    Screen('CloseAll')    
    clear('SimKey'); %Can't be saved, prevent error
    save DebugSaveFile;
    ListenChar(0);
    disp(ME);
    disp(ME.message);
    disp(ME.stack);
end

end

