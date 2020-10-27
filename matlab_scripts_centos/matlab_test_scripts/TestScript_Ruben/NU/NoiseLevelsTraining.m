function NoiseLevelsTraining

clear all
Screen('Close');    %Closes any textures that might have been left open due to a dirty crash
close('all');       %Closes any open figures

addpath('Local_Functions');

%% Get Run Information

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
            CRChars = 1:4;
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
        otherwise
            errordlg('I do not recognize that place. Are you sure it exists? (Valid answers are ''MacTest'', ''WindowsTest'',  ''Trio'' or ''BLab2'')', 'Really?');
            return
    end
end

Parameters.LeftKeyCode = RspKeys(1);
Parameters.RightKeyCode = RspKeys(2);
Parameters.Windows = Windows;
Parameters.EscCode = EscCode;
Parameters.RspKeys = RspKeys;
Parameters.CRChars = CRChars;

Parameters.runnr = runnr;

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

%% Set Parameters

Parameters.Experiment = 'NoiseLevelsTraining';
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
Parameters.FontSize = 0.5; %Deg.

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
Parameters.NoiseContrast = 0;
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
Parameters.ITI = 2.0;               %Inter-Trial Interval 

Parameters.CueDelay = 0.0;
Parameters.CueDuration = 0.125;
Parameters.CRInterval = 1.0;

Parameters.TrialLength = Parameters.StimulusDuration + Parameters.MatchDelay + Parameters.MatchDuration; %Still in TRs
if mod((Parameters.TrialLength+Parameters.ITI)*Parameters.TR, Parameters.TR)
    errordlg('Trial length (including ITI) must be an integer multiple of TRs.', 'No can do!');
    return;
end

Parameters.pctFixTrials = 0.0;      %Percentage fixation trials            
Parameters.NumTrials = 18;           %NumTrials * pctFixTrials must be an integer number, and NumTrials must be an integer multiple of length(NoiseOriProx)
Parameters.NumRuns = 8;

%CONFIDENCE RATINGS:
Parameters.Training = 'True';       %This determines, amongst other things, whether CI templates will be shown during the CR interval
Parameters.CIs = 8:8:32;      %Half-range of CIs (i.e. within how many degrees do people think they are)
Parameters.CIOffsetDeg = 2;
Parameters.CIOffsetPix = Parameters.CIOffsetDeg * Parameters.pixPerDeg;
Parameters.NumOffsetDeg = 1;
Parameters.NumOffsetPix = Parameters.NumOffsetDeg * Parameters.pixPerDeg;

%RANDOMIZATION:
Parameters.RandSeed = sum(100*clock);

%% Run sequence
%The condition in each run needs to be determined at the start for
%counterbalancing. So check if this is the first run, and if so, generate a
%run list and save it in the data file for the first run. Subsequent runs
%may load the data file from the first run, but should save the run list in
%their own file as well.

if Parameters.runnr == 1    
    nconds = length(Parameters.CLabels);
    if mod(Parameters.NumRuns, nconds), error('Number of runs must be an integer multiple of number of conditions.'); end    
    Parameters.CondList = [];
    for i = 1:Parameters.NumRuns/nconds
        Parameters.CondList = [Parameters.CondList; Shuffle(1:4)'];        
    end
else
    FirstRunDataFile = ['d', datestr(now,'ddmmyy'), subj_id, '_run', sprintf('%03d', 1)];
    FirstRun = load([Parameters.savepath, FirstRunDataFile], 'Parameters');
    Parameters.CondList = FirstRun.Parameters.CondList;
end
    

%% Call Task
%Call Experiment with the right Parameters for this run

noisecontrasts = [0 0.1 0.2 0.4];
Parameters.NoiseContrast = noisecontrasts(Parameters.CondList(Parameters.runnr));
Parameters.NoiseAmp = Parameters.SineMean*Parameters.NoiseContrast;

%msgbox(['In this run, the match stimulus will be a ', Parameters.CLabels(Parameters.CondList(Parameters.runnr))], 'Condition');

Experiment(Parameters);

end