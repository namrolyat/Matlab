% This script will allow you to test a keyboard with KbQueue.
% It has been tested succesfully with a dell keyboard, however the
% Corsair low latency gaming keyboard failed to function in the KbQueue.
% the code supplied below is a destilled part of the original EEG script
% just to test the functioning of the keyboard itself. Functions are
% commented and for any questions reach out for
% mitchel.stokkermans@gmail.com or s4021657@ru.nl

% Make sure you have psychtoolbox properly istalled
% Error reports will be stored in me, see try --> cacth me

%----------------------------------------------------------------------
% if script is stuck press ctrl + c  followed by sca (screen close all)
%----------------------------------------------------------------------

%%
% Softcode for experiment

TaskDuration = 300;  % this means that the experiment will take 5 minutes.
Counter = 1;         % Start value for key recording
TaskDone = 0; 
%%
%----------------------------------------------------------------------

% This will provide information about all connected devices

[KeyboardIndices, AvailableKeyboards] = GetKeyboardIndices;
% Define the keyboard keys that are listened for. We will be using the left
% and right arrow keys as response keys for the task and the escape key as
% a exit/reset key
KeyboardIndices
AvailableKeyboards

% which keyboard should be listened to?
KbIdx = (input('Which keyboard should the participant use?'));

try
    %%
    %----------------------------------------------------------------------
    %                         Psychtoolbox setup
    %----------------------------------------------------------------------
    % this section contains all presets for PTB.
    
    % Setup PTB with some default values
    PsychDefaultSetup(2);
    
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
    % this might sometimes give a vbl error. If you run the script again it will run without a problem.
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, []); % 32, 2)
    
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
    %                   Retrieving keyboard information
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
    %                      Stimulus information
    %----------------------------------------------------------------------
    
    Stimulus = ('Type hier je bericht, na 5 minuten stopt de opname\n druk op escape om eerder te stoppen');
    
    PsychHID('KbQueueCreate',KbIdx);    % Create the Queue
    PsychHID('KbQueueStart',KbIdx);     % start the Queue
    
    %%
    %----------------------------------------------------------------------
    %                        Start Experiment
    %----------------------------------------------------------------------
    while TaskDone == 0;
        % present the word/ sentence (select the word/sentence from a poule)
        
        DrawFormattedText(window, Stimulus,'center', 'center', black);
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        % vbl  = , vbl + (waitframes - 0.5) * ifi
        % Collect keyboard events since KbQueueStart was invoked
        [pressed, firstPress, firstRelease, lastPress, lastRelease] = PsychHID('KbQueueCheck',KbIdx);
        
        %% Recording press sequence
        if pressed;
            
            if Counter == 1;
                % this will record the time at the start of the typing
                startTime=GetSecs;
            end
            
            PressedKeys=find(firstPress);
            % for i=1:size(PressedKeys,2)
            %fprintf('The %s key was pressed at time %.3f seconds\n',KbName(PressedKeys(i)), firstPress(PressedKeys(i))-startTime);
            RecordedKey(1,Counter) = PressedKeys(1);
            % this sends the EEg markers. should be fixed to the button
            % presses
            %EEGmarker.sendTrigger(PressedKeys(1));
            
            RecordedTime(1,Counter)=(firstPress(PressedKeys(1))-startTime);
            
            % This makes sure that all character + time info will be stored in the correct column
            % corresponding to the position where the character belongs (see RecordedKey and RecordedTime)
            Counter = Counter +1;
            
            if PressedKeys == EscapeKey(1,1)
                TaskDone = 1;
            end
            TimeInBetween = GetSecs;
            if TimeInBetween - startTime >= TaskDuration;
                TaskDone = 1;
            end
        end   
    end
    sca;
    ShowCursor
    PsychHID('KbQueueFlush',KbIdx);
catch me
end
sca;