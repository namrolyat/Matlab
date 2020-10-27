% Clear the workspace
close all;
clearvars;
sca;

%%
%----------------------------------------------------------------------
%                      Experiment softcode values
%----------------------------------------------------------------------
CharpresTime = 0.3; % presentation time per character in seconds
WaitITI = 2; % Grey screen waiting time in seconds (inter trial interval)
TimeUntilBreak = 300; % How many seconds per experimenting section/ How many seconds until a break
TimeConditionOne = 180; % We will give three minute typing time on the freestyle typing trials
DurationExperiment = 3600; % The experiment will take an hour
FactorStd = 1; % This is involved in the typing speed. Bigger std factor = longer typing time, lower std factor = shorter typing time.
PreInitiationMarker = 1; % This is the marker that will encode the trial number (marker send before and after the trial number marker)
PostInitiationMarker = 1; 
%%
% ----------------------------------------------------------------------
%                           Experimental input
% ----------------------------------------------------------------------
%This following code is for testing purposes. Sometimes the error occurs
%that there is a synchronization faillure.  This should cover up this
%error, though it must not be used in the real experiment!!!
realexperiment=input('Is this a real experiment 1 or 0?');
if realexperiment==0
    Screen('Preference', 'SkipSyncTests',1);
end

Participant = input('name: ','s');

% which keyboard should be listened to?
% ListenChar(0)

[KeyboardIndices, AvailableKeyboards, info] = GetKeyboardIndices;
% Define the keyboard keys that are listened for. We will be using the left
% and right arrow keys as response keys for the task and the escape key as
% a exit/reset key
KeyboardIndices
AvailableKeyboards
info

KbIdx = [input('Which keyboard should the participant use?')];
KbPauseIdx = [input('Which keyboard should the experimenter use?')];
FavorieteFilm = (input('Wat is de favoriete film?','s'));
FavorieteBoek = (input('Wat is het favoriete boek?','s'));

%%
%----------------------------------------------------------------------
%                         Psychtoolbox setup
%----------------------------------------------------------------------
% this section contains all presets for PTB.

% Setup PTB with some default values
PsychDefaultSetup(2);

% Seed the random number generator. Here we use the an older way to be
% compatible with older systems. Newer syntax would be rng('shuffle'). Look
% at the help function of rand "help rand" for more information
% rand('seed', sum(100 * clock));

% Set the screen number to the external secondary monitor if there is one
% connected
screenNumber = max(Screen('Screens'));

% Define colors
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);
Red = [255 0 0];
Blue = [0 0 255];

% Open the screen
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey,[]); %[], 32, 2

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set the text size
Screen('TextSize', window, 50);

% Query the maximum priority level
topPriorityLevel = MaxPriority(window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%%
%----------------------------------------------------------------------
%                       Timing Information
%----------------------------------------------------------------------
% Interstimulus interval time in seconds and frames
isiTimeSecs = 1;
isiTimeFrames = round(isiTimeSecs / ifi);

% Numer of frames to wait before re-drawing
waitframes = 1;

%%
%----------------------------------------------------------------------
%                        Initializing EEG codes
%----------------------------------------------------------------------

EEGmarker = Bitsi('/dev/ttyS0');

%%
%
TypingComplete = 0;
TimeOver = 0;
CompletedTrials = [];
SlowTrial = [];
quitprogram = 0;
PauseCounter = 0;
TotalTimeInPause = 0;
% these are counters for each condition

Counter= 2; %Counter for each character that is typed (used in the for loop to make sure timing data is coupled to the correct pressed character
presSecs = [3,2,1]; %Countdown

%----------------------------------------------------------------------
%                         Key Board Information
%----------------------------------------------------------------------
HideCursor;
KbName('UnifyKeyNames')

% to chech the name of a certain key on your operating system use
% KbName,press Enter,Wait,Press the key and the answer will be the name
% of the pressed key
EscapeKey = KbName('ESCAPE');           % Quit experiment
ReturnKey = KbName('Return');           % Return key for participant to validate input
UpKey = KbName('UpArrow');              % Stimulus perception left
DownKey = KbName('DownArrow');          % Stimulus perception right

% Retrieve actual keymap
Keymap = KbName(1:255);

%% ----------------------------------------------------------------------
%                     Selection of words and sentences
% -----------------------------------------------------------------------

%
% Here we implement the input of which book/ film into a string so it can
% be presented on the screen in the respective conditions.
FreestyleFilm = ['Typ gedurende 3 minuten\n het plot van\n',FavorieteFilm];
FreestyleBoek = ['Typ gedurende 3 minuten\n het plot van\n',FavorieteBoek];

freestyleWord_Sentence = (Shuffle({FreestyleFilm;FreestyleBoek;'Typ gedurende 3 minuten \n wat je gisteren heb gedaan'}));
pseudoWordSentenceList;
normalWordList;
normalWordSentenceList;
pseudoWordList;


% With Wordpreset each stimulus per trial is precalculated so this won't
% take up any calculation time during the experiment.  See script
% WOrdPreset for the forloop that calculates -->(cell word)
WordPreset;

%----------------------------------------------------------------------
%                         Drawing fixation cross
%----------------------------------------------------------------------
% Here we set the size of the arms of our fixation cross still in pixels
fixCrossDimPix = 20;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% Set the line width for our fixation cross
lineWidthPix = 4;

[RecordedKey,RecordedTime] = deal( zeros(length(ConditionRandomizer),2050) );

%% ----------------------------------------------------------------------
%                       Experimental loop
% -----------------------------------------------------------------------
try
    % Message for what is expected
    DrawFormattedText(window, 'Type de volgende woorden of zinnen zo snel mogelijk na. \n Corrigeer indien nodig met backspace. \n Met de enter toets bevestigt u een antwoord. \n\n Druk op een toets te beginnen',...
        'center', 'center', black);
    vbl = Screen('Flip', window);
    WaitSecs(0.2);
    KbWait(KbIdx);
    
    StartExperiment = GetSecs;
    TimeSinceBreak = GetSecs;
    
    %% Start of the whole experiment loop
    for Trial = 1:length(ConditionRandomizer);
        
        % Logrithm to adjust typing speed while doing the task
        % This allows dynamic typing speed alteration towards a good typign
        % speed per participant.
        if Trial >= 5;
            d=diff(RecordedTime(:,2:end),[],2);                              % Transpose get secs data to milliseconds and the difference to subsequent keypress
            d=d(d>0);                                               % Only include values greater than zero, because we want absolute values
            threshold = median(d) + FactorStd*std(d);               % Median with 2 times std to calculate optimal average typing speed
            CharpresTime = threshold;
        end
        
        % This selects the word to be presented in that trial
        WordStim = Word(Trial);
        if ConditionRandomizer(Trial,1) == (1);
            % here we tell that in condition 1 we have a 3 minute timelimit.
            % This timelimit will be implemented with typing complete
            GivenTime = TimeConditionOne;
            % defining presentation color
            WordColor = [0 0 255];
        elseif ConditionRandomizer(Trial,1) ~=(1);    %-----------------------------------------------------------
            GivenTime = (length(char(WordStim{1,1})) * CharpresTime);
            % defining presentation color
            WordColor = [0 0 0];
        end
        
        Stimulus =char(WordStim{1,1});
        if ConditionRandomizer(Trial,1) == (1);
            DrawFormattedText(window, 'Druk op een toets voor de 3 minuten type sessie','center', 'center', black);
            vbl = Screen('Flip', window);
            WaitSecs(0.2);
            KbWait(KbIdx);
        end
        
        TrialMarker = Trial;
        if TrialMarker >= 257 && TrialMarker<= 512;
            TrialMarker = (TrialMarker-256);
            PostInitiationMarker=2;       % Second bitsi cycle
        elseif TrialMarker >= 513 && TrialMarker<= 768;
            TrialMarker = (TrialMarker-512);
            PostInitiationMarker = 3;     % Third bitsi cycle
        elseif TrialMarker >= 769 && TrialMarker <=1024;
            TrialMarker = (TrialMarker - 768);
            PostInitiationMarker = 4;     % Fourth bitsi cycle
        end
        
        %% Typingtask
        PsychHID('KbQueueCreate',KbIdx);                                       % Create the queue
        PsychHID('KbQueueStart',KbIdx);
        StartWordTimer = GetSecs;                            % With this timer we calculate when the typing time is over according to the word length
        
        
        % PResetting eaach trial number in each row so the data doesn't mix
        % up and we can easily trace back the trail number with the
        % corresponding trial data
        RecordedKey(Trial,1) = Trial;
        RecordedTime(Trial,1) = Trial;
        
        % here we send a marker before we jump into the while loop.
        % This allows us to track to the moment of stimulus presentation.
        EEGmarker.sendTrigger(PreInitiationMarker);
        WaitSecs(0.01);
        EEGmarker.sendTrigger(TrialMarker);
        WaitSecs(0.01);
        EEGmarker.sendTrigger(PostInitiationMarker);
        
        while TimeOver==0 || TypingComplete==0; %
            
            % present the word/ sentence (select the word/sentence from a poule)
            
            DrawFormattedText(window, Stimulus,'center', 'center', WordColor);
            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
            % vbl  = , vbl + (waitframes - 0.5) * ifi
            % Collect keyboard events since KbQueueStart was invoked
            [pressed, firstPress, firstRelease, lastPress, lastRelease] = PsychHID('KbQueueCheck',KbIdx);
            
            %% Recording press sequence
            if pressed;
                if Trial==1;
                    startTime=GetSecs;
                end
                
                PressedKeys=find(firstPress);
                % for i=1:size(PressedKeys,2)
                %fprintf('The %s key was pressed at time %.3f seconds\n',KbName(PressedKeys(i)), firstPress(PressedKeys(i))-startTime);
                RecordedKey(Trial,(Counter)) = PressedKeys(1);
                
                % this sends the EEg markers. should be fixed to the button
                % presses
                EEGmarker.sendTrigger(PressedKeys(1));
                
                RecordedTime(Trial,(Counter))=(firstPress(PressedKeys(1))-startTime);
                
                %  end
                % Here we calculate whether the 300ms p/character are
                % exceeded.Only for conditions 2-5 so if not condition 1
                % Condition randomizer randomly presents a value of 1 up to
                % 5 for each condition that we have
                if ConditionRandomizer(Trial,1) ~=(1);
                    PassedTime = GetSecs;
                    PassedTime = PassedTime-StartWordTimer;
                    % when time is exceeded ==> Time is over message
                    if PassedTime >= GivenTime;
                        TimeOver = 1;
                    end
                    
                elseif ConditionRandomizer(Trial,1) ==(1);
                    PassedTime = GetSecs;
                    PassedTime = PassedTime-StartWordTimer;
                    if PassedTime >= GivenTime;
                        TimeOver = 1;
                        TypingComplete=1;
                        break;
                    end
                end
                % If the input is the Return button, leave the while loop
                if ConditionRandomizer(Trial,1) ~= (1);
                    RecordedKey(Trial,(Counter))=PressedKeys(1);
                    if PressedKeys == ReturnKey(1,1);
                        RecordedTime(Trial,(Counter))=(firstPress(PressedKeys(1))-startTime);
                        TypingComplete = 1;
                        Counter = Counter +1;
                        break;
                    end
                end
                % This makes sure that all character + time info will be stored in the correct column
                % corresponding to the position where the character belongs (see RecordedKey and RecordedTime)
                Counter = Counter +1;
            end
            % Here we can stop measuring the EEG, thus give a EEG stop
            % command
        end          % End of while loop
        
        %% Last commands before running a new trial.
        % Conditions 3 to 6 have a time limit according to the length
        % of the word/sentence. In these conditions we want to alert the participant that he/she is typing too slow.
        if ConditionRandomizer(Trial,1) ~= (1);
            if TimeOver; %If typing too slow, tell them to type faster.
                DrawFormattedText(window, 'Sneller typen!','center', 'center', Red);
                vbl = Screen('Flip', window);
                WaitSecs(1);
                % If this was a too slow trial,  record with 1 in slowtrial
                % vector.  This allows tracking the slow tials
                SlowTrial(Trial)=1;
                CompletedTrials(ConditionRandomizer(Trial,1),Trial) = 0;
            elseif Counter <= ((0.8)*length(Stimulus));
                DrawFormattedText(window, 'Je hebt niet de volledige stimulus getypt','center', 'center', Red);
                vbl = Screen('Flip', window);
                WaitSecs(1.5);
            elseif TypingComplete;
                SlowTrial(ConditionRandomizer(Trial,1),Trial)=0;
                CompletedTrials(ConditionRandomizer(Trial,1),Trial) = 1;
            end
        end
        
        % Resetting parameters for next trial
        PsychHID('KbQueueFlush',KbIdx);
        %Reset Typing complete and Timeover for the next stimulus
        %presentation
        TypingComplete = 0;
        TimeOver = 0;
        % Reset counter for the next word and accurate timing information
        Counter = 2;
        
        % Record the time at this point for break
        TimeInExperiment = GetSecs;
        BreakTimer = ((TimeInExperiment) - (TimeSinceBreak));
        EndTimer = ((TimeInExperiment) - (StartExperiment));
        % If expired time is more than preset breaktime flipscreen for a
        % break message.
        if EndTimer >= (DurationExperiment);
            % Here we quit the experiment and save all data.
            time=datestr(clock,30);
            filename = sprintf('%s%s%s%s%s%s.mat',['Deelnemer'],Participant,['TrialNumber'],num2str(Trial),'_',time);
            save(['ExperimentalData/',fullfile(filename)]);             % This only saves the data in the directory if there is a folder called "ExperimentalData"
            
            DrawFormattedText(window, 'Het experiment is afgelopen','center', 'center', black);
            vbl = Screen('Flip', window);
            WaitSecs(2);
            TimeSinceBreak = GetSecs;
            KbWait(KbIdx);
            sca;
            
        elseif BreakTimer >= (TimeUntilBreak);
            time=datestr(clock,30);
            filename = sprintf('%s%s%s%s%s%s.mat',['Deelnemer'],Participant,['TrialNumber'],num2str(Trial),'_',time);
            save(['ExperimentalData/',fullfile(filename)]);             % This only saves the data in the directory if there is a folder called "ExperimentalData"
            
            DrawFormattedText(window, 'Neem een pauze\n als je uitgerust bent ga je verder door op een toets te drukken',...
                'center', 'center', black);
            vbl = Screen('Flip', window);
            WaitSecs(2);
            TimeSinceBreak = GetSecs;
            KbWait(KbIdx);
        end
        
        TimeITI1 = GetSecs;
        while 1;
            
            % Flip the screen for 1s grey screen
            Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 0);
            vbl = Screen('Flip', window);
            
            TimeITI2 = GetSecs;
            if TimeITI2-TimeITI1>2;
                break;
            end
            
            % possibility for experimenter to pause the script during ITI
            [keyIsDown,secs,keyCode] = PsychHID('KbCheck',KbPauseIdx);
            if keyIsDown;
                TimeInPause = GetSecs;
                DrawFormattedText(window, 'Een ogenblik a.u.b. \n er komt een medewerker naar je toe',...
                    'center', 'center', black);
                vbl = Screen('Flip', window);
                WaitSecs(2);
                KbWait(KbPauseIdx);
                DrawFormattedText(window, 'Druk op een toets om verder te gaan','center', 'center', black);
                vbl = Screen('Flip', window);
                WaitSecs(0.2);
                KbWait(KbIdx);
            end
        end
    end% All trials within the conditions length are done, step to the next condition
catch me
end
% shutting down the EEG port
%fclose(EEGmarker.serial);
ShowCursor
sca;


%


%------------------------------------------------------------------------------------------------------------------------
