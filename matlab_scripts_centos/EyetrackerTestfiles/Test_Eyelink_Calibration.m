%%%% Test Eyelink calibration
%This script opens a small test screen, opens the connection to the Eyelink
%PC and starts the calibration window. Within th calibration window, the
%camera view, calibration and validation can be chosen. ESC will start a
%short demo recording. 
% See EyelinkInitDefaults for meaning of received Eyelink values
clear all;
close all;

%% Screen
%[w,screenRect] = Screen(0,'OpenWindow',0,[]); %opens fullscreen window 'w'
[w, screenRect] = Screen(0,'OpenWindow',0, [900 400 1700 1000 ]); %Preferably open non-fullscreen window 'w' in test mode
black=BlackIndex(w);

%%% properties of displayed text
xpos = (screenRect(3)/8);%start x position of displayed text
ypos = (screenRect(4)/2); %start y position of displayed text
textcolor = [255,255,255]; %text color of displayed text

HideCursor; %hide cursor on dislpayed window
%% Initialization of the connection with Eyelink.
%%% Dummy mode == 1 (yes) or 0
dummymode=0;
% exit program if this fails. 

if ~EyelinkInit(dummymode) %initialization of Eyelink system and connection. EyelinkInit is NOT the same as Eyelink('Initialize')!
    fprintf('Eyelink Init aborted.\n');
    return;
end

el = EyelinkInitDefaults(w);

el.backgroundcolour = [0,0,0]; %black background
el.window = w;

%EyelinkUpdateDefaults(el);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Opening file in eyelink

file_name = 'TestCal'; %NOTE: filename should have MAX 8 characters!
i = Eyelink('openfile',file_name);
if i~=0
    disp(['Cannot create EDF file: ' file_name]);
    return;
end

%% (OPTIONAL) SET UP TRACKER CONFIGURATIONS
%Eyelink('command', 'calibration_type = HV9');
%Eyelink('command', 'screen_distance = 1102 1138');
%Eyelink('command', 'screen_distance = 70');

%%%% set parser (conservative saccade thresholds)
%Eyelink('command', 'saccade_velocity_threshold = 35'); % based on previous experience, these are conservative to detect large saccades, see manual
%Eyelink('command', 'saccade_acceleration_threshold = 9500');% based on previous experience, these are conservative to detect large saccades, see manual
%Eyelink('command', 'saccade_motion_threshold = 0.15');% to try to ignore saccades smaller than this, a window

%% (OPTIONAL) set EDF file contents
%%%% note that it is recommended to offline search for your own saccades based on velocity and then position
% the important ones are ..._event_filter and ..._sample_data

%Eyelink('command', 'file_event_data = GAZE,AREA,VELOCITY');
%Eyelink('command', 'file_sample_data = LEFT,GAZE,AREA'); % what you want to record
%Eyelink('command', 'link_event_filter = LEFT,SACCADE,BLINK,MESSAGE'); % what you want in the file
% DATA.INI for types.
% Arguments: <list>: list of event types
% LEFT, RIGHT events for one or both eyes
% FIXATION fixation start and end events
% FIXUPDATE fixation (pursuit) state updates
% SACCADE saccade start and end
% BLINK blink start an end
% MESSAGE messages (user notes in file)
% BUTTON button 1..8 press or release
% INPUT changes in input port lines

%Eyelink('command', 'link_event_data = GAZE,AREA,VELOCITY');
%Eyelink('command', 'link_sample_data  = LEFT,GAZE,AREA'); % what you want to record
% Arguments: <list>: list of data types
% GAZE screen xy (gaze) position
% GAZERES units-per-degree screen resolution
% HREF head-referenced gaze
% PUPIL raw eye camera pupil coordinates
% AREA pupil area
% STATUS warning and error flags
% BUTTON button state and change flags
% INPUT input port data lines

%% Calibrate the eye tracker
%Eyelink('StartSetup');
EyelinkDoTrackerSetup(el);
%%%% OPTIONAL do a final check of calibration using driftcorrection
%  EyelinkDoDriftCorrection(el);

pause(.1)
%el.targetbeep=0;

Screen(w,'FillRect',black);
Screen('Flip',w,[],[]);

%% Start recording
Eyelink('startrecording');

CalibrationResult = Eyelink('CalResult');
if CalibrationResult == 27 || 1000 % i.e., reads the ESC key press (27) or received NO_REPLY (1000);
    Screen('DrawText', w, 'No eye found. Recording will be aborted in 3 seconds', xpos,ypos,textcolor);
else
    Screen('DrawText', w, 'End of demo. Recording will be aborted in 3 seconds', xpos,ypos,textcolor);
end



%ccv%%OTHER OPTION, USE 'eyeavailable', which indicated tracked eye. returns 0
%%%(LEFT), 1 (RIGHT), 2 (BOTH). Default use (without subject) == RIGHT.
%eye_used = Eyelink('eyeavailable'); % get eye that's tracked
%if eye_used == 1
%Screen('DrawText', w, 'No eye found. Recording will be aborted in 3 seconds', xpos,ypos,textcolor);
%else
%    Screen('DrawText', w, 'End of demo. Recording will be aborted in 3 seconds', xpos,ypos,textcolor);
%end

Screen('Flip',w,[],[]);

pause(3);

%% Stop recording and display
Eyelink('StopRecording');
Eyelink('CloseFile');
Eyelink('Shutdown');
Screen(w,'Close');
