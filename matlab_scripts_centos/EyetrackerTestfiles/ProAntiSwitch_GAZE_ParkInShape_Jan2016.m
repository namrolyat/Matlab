function ProAntiSwitch_GAZE_ParkInShape_Jan2016
% Initialization
%%%% TO INITIALIZE make sure the Ethernet IP on the host(display) computer:
%%%% IP:        100.1.1.2
%%%% Subnet:    255.255.255.0
%%%% (Eyelink Computer can be 0.0.0.0)

%%%% Use 32-bit Matlab (e.g., 2011b)

%%%% Make sure XX cables, XX power cable, and XX Eyelink Interface cable are connected to Eyetracker
%%%% connect Eyelink ethernet cable to host computer
%%%% connect VGA dislay to host computer

%%%% Make sure file name is MAX 8 characters, follow DOS convention

%%%% Base the screens on 1024 X 768
%%%% After setting screen to above resolution, make sure monitor is on 'Aspect'

%%%% needs  trial_gen as function (here) or separate script
%%%% using a 6th order 'derivative' of stim_location repetitions in trial_gen,
%%%% prevents more than 5 stimuli appearing in the same location in a row

%% Other NOTES:

%%%% uses Psychtoolbox
%%%% screens are pre-drawn then "flipped" with a screen refresh
%%%% uses WaitSecs('UntilTime') timings for each new experimental state
%%%% WaitSecs('UntilTime') prevents accumulation of timing errors. Individual states may therefore be shortened accordingly
%%%% to maintain appropriate time sync with new events

%%%% do not use exact time durations except for initial pre-trial
%%%% time delays will accumulate, and does not bring benefit to the within
%%%% trial timings in actual eye data, eg. wakeup=WaitSecs(2); % DO NOT DO THIS!
%%%% it is not necessary to subtract refreshrates when using 'WaitSecs('UntilTime')

%%%% do not use the Eyelink TIME STAMP e.g.:
%trialtimestart=Eyelink('trackertime');

%%%% (all event Messages are time locked to occur after INIT, INST, RESP and FIX periods start, and AFTER a screen is flipped.
%%%% EDF2ASC creates ascii text file with experimental events documented as messages, and the recodings of eye position and pupil area
%%%% uses GetSecs for recording of timings of events in a .mat file (optional)

%%%% to quit while running: Ctrl +C; enter; then 'sca'; enter




%%%% NOTES:

%IAN2014 DCCN, Nijmegen,the Netherlandds
%%


clear all;
close all;
FlushEvents('keyDown');	% discard all the chars from the Event Manager queue.
commandwindow;



%% variables:


% 64 switch trials / 4 switch times = 16 per switch time, 8 per task, 4 per direction
% 128 non-switch trials
% assumes max amount of time per trial at 2.16 s = 2.16 X 192 X 4 blocks (min 16 per condition) = 35 minutes

maxwait = 2.16; % max time in seconds per trial befpre ITI [900 + 1000 to react + 100 to land saccade + 160 to hold)

dontsync = 2;
%"dontsync" If set to zero (default), Flip will sync to the vertical
%retrace and will pause execution of your script until the Flip has happened. If
%set to 1, Flip will still synchronize stimulus onset to the vertical retrace,
%but will *not* wait for the flip to happen: Flip returns immediately and all
%returned timestamps are invalid. A value of 2 will cause Flip to show the
%stimulus *immediately* without waiting/syncing to the vertical retrace
%%% Note: value 2 does make the events on time (speeds up flip), and no
%%% noticeable problems. Timing delays, however, are not affected by the
%%% flip as mentioned above (e.g., WaitSecs). Delays may be in switching
%%% states

%INITIALIZE VARIABLES

%Assigning the SPATIAL coordinates of the stimuli in the experiment
%SetRect(left, top, right, bottom)
%MUST DETERMINE PROJECTOR RESOLUTION FOR COORDINATES


%%  here assumes 1024 X 768
% (X1 Y1 X2 Y2)

% for 10 degree targets, have the subject sit at 57 cm from screen
L_stim_wide = SetRect(241, 369, 271, 399); % 10 cm from center fix to center stim
R_stim_wide = SetRect(753, 369, 783, 399); % 10 cm is thus 256 pixels

%short  eccentricity
% L_stim_short = SetRect(220, 364, 260, 404);
% R_stim_short = SetRect(764, 364, 804, 404);

Fix_stim = SetRect(497, 369, 527, 399); % normal fixation crosses

ITI_stim = SetRect(1, 1, 1024, 768);


%% Size of window for gaze contingent displays
gaze_pix_h=40;
gaze_pix_v=100;
gaze_pix_fix=100;

% uses rectangles, so crosses coded differently
% this box should be a square around fixation
Fix_gaze = SetRect((497-gaze_pix_fix), (369-gaze_pix_fix), (527+gaze_pix_fix), (399+gaze_pix_fix));

% this box can be a elongated rectangle in the vertical around fixation
L_target_gaze = SetRect((241-gaze_pix_h), (369-gaze_pix_v), (271+gaze_pix_h), (399+gaze_pix_v));
R_target_gaze = SetRect((753-gaze_pix_h), (369-gaze_pix_v), (783+gaze_pix_h), (399+gaze_pix_v));

%%

clc;

% %% Start Info about the participant
% participant_info = input('Enter the subject number:  ');
% if participant_info ~= [1:30]
%     disp(' ');
%     disp('Must select one number between 1 and 30');
%     disp(' ');
%     while participant_info ~= [1:30]
%         participant_info = input('Enter the subject number:  ');
%     end
% end

% %% End Info about the participant

%pro = 1; anti = 2; anti2pro = 3; pro2anti = 4
trial_seq = input('Task: pro (1) anti (2) or switch (0) : ');
if trial_seq ~= [1 2 0]
    disp(' ');
    disp('Must select 1 2 or 0');
    disp(' ');
    while trial_seq ~= [1 2 0]
        trial_seq = input('Task: pro (1) anti (2) or switch (0) : ');
    end
end

if trial_seq == 0
    max_trials = 192; % per block, divisible by 3 for 33 % switch
else
    max_trials = 96;
end
% 64 switch trials / 4 switch times = 16 per switch time, 8 per task, 4 per direction
% 128 non-switch trials
% assumes max amount of time per trial at 2.16 s = 2.16 X 192 X 4 blocks (min 16 per condition) = 35 minutes

color_ver = input('Pro = green? (1), or Pro = red? (2): ');
if color_ver ~= [1 2]
    disp(' ');
    disp('Must select 1 or 2');
    disp(' ');
    while color_ver ~= [1 2]
        color_ver = input('Pro = green? (1), or Pro = red? (2) :');
    end
end

[task_inst, stim_location, resp_period, sw_time] = trial_gen(trial_seq, max_trials);% calls trial gen function max_trials);% calls trial gen function


%%%% Create a single 'variable' that includes all of the information that
%%%% can be SAVED from this experiment to a matlab file
%%%% EDF file contains messages of events, and should normally be enough
A=[];
A.clock=round(clock);
A.inst = task_inst; % note, task instruction will be 1 pro, 2 anti, 3 anti2pro, 4 pro2anti
A.stim = stim_location;
A.resp = resp_period;
A.sw_time = sw_time;



%%%% Set up the trial states and their relative timing in seconds when constant -- synched to refresh_rate rate
clear t_state;
% for use with variable presentation_display
S_INST               =1;  t_state(S_INST,:)                =' INST        ';  % duration of instruction (900 ms)
S_RESP               =2;  t_state(S_RESP,:)                =' RESP        ';  % response epoch (160 ms)
S_ITI                =3;  t_state(S_ITI,:)                 =' ITI         ';  % response epoch (600 ms)

A.t_state=t_state;

%%%% setting matrix delineating the saved experimental events for every trial -- to be used with A.file_events
clear exp_state;
exp_state(1,:)       =' tr_num        '; % trial number
exp_state(2,:)       =' t_state       '; % trial state (1,2)
exp_state(3,:)       =' task_inst     '; % task instruction (pro or anti)
exp_state(4,:)       =' stim_loc      '; % stimulus location (0-Right, or 180-Left)
exp_state(5,:)       =' resp_period   '; % response made
exp_state(6,:)       =' sw_time       '; % switch time
exp_state(7,:)       =' C_start       '; % provides event time
exp_state(8,:)       =' C_end         '; % provides event time
exp_state(9,:)       =' C_dur         '; % time that event was presented
exp_state(10,:)      =' Csw_actual    '; % provides actual time from inst onset
exp_state(11,:)      =' Csw_length    '; % provides actual switch time, should be same as 6

% note if we make it gaze contingent on advancing, then we don't really need these
% these values will be 1 if in the right location, 9 if in the wrong location
exp_state(12,:)      =' Eye_InstStart '; % location of eye at the inst start
exp_state(13,:)      =' Eye_RespStart '; % location of eye at the resp start
exp_state(14,:)      =' Eye_RespEnd   '; % location of eye at the end

A.exp_state=exp_state;

%setting up matrix to indicate eye location -- to be used with A.location
% goes with eye_is
% For all locations  --  5=fixation, 0=right target, 180=left target, 9 = elsewhere

where_is_it(1,:)       =' tr_num        ';  % trial number
where_is_it(2,:)       =' Eye@InstStart '; % Location of eye at inst start
where_is_it(3,:)       =' Eye@RespStart '; % Location of eye at target
where_is_it(4,:)       =' Eye@RespEnd   '; % Location of eye at response end

A.where_is_it=where_is_it;



clc;

%Defining colors used for the Stimuli
% colors = [];
% colors.PRO = [0 186 0];
% colors.ANTI = [256 30 30];
% colors.STIM = [15 75 256];
% colors.GREY = [200 200 200];
% colors.BACKGROUND = [0 0 0];

if color_ver ==1
    colors.PRO = [0 186 0];
    colors.ANTI = [256 30 30];
    colors.STIM = colors.PRO;
    colors.GREY = [100 100 100];
    colors.BACKGROUND = [0 0 0];
elseif color_ver ==2
    colors.ANTI = [0 186 0];
    colors.PRO = [256 30 30];
    colors.STIM = colors.PRO;
    colors.GREY = [100 100 100];
    colors.BACKGROUND = [0 0 0];
end

A.colors=colors;

%Create file name

file_name=input('Input file name:','s');

if exist(strcat(file_name,'.mat'))
    file_name=input('Filename exists: Input new file name:','s');
    while exist(strcat(file_name,'.mat'))
        file_name=input('Filename exists: Input new file name:','s');
    end
end

tr_num=1;


file_events=[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]; %match with exp_state listed above
file_events=[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; %match with exp_state listed above

% add one 0 for each new experimental event
f_e_index=1;

location_events=[0, 0, 0, 0]; %match with where is it
location_row=1;
location_column=1;




FlushEvents('keyDown');	% discard all the chars from the Event Manager queue.



presentation_display = 1;


%%%% option to suppress warning printouts, setting flag to 1 to do this
oldEnableFlag = Screen('Preference', 'SuppressAllWarnings', 1);

%%%% option to Make screen black on startup
Screen('Preference', 'VisualDebugLevel', 1);

%[w,screenRect] = Screen(0,'OpenWindow',0,[0 0 1280 500],16); % debugging MAC
[w,screenRect] = Screen(0,'OpenWindow',0,[]);
pause(.01);
%Screen(colors.BACKGROUND);
black=BlackIndex(w);
HideCursor;

%% if no eyelink
eye_at_fix = NaN;
eye_is = NaN;
eye_at_resp = NaN;
%
%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% eyelink connection section

%%% New simple Dummy mode == 1 (yes) or 0
dummymode=0;

% Initialization of the connection with the Eyelink Gazetracker.
% exit program if this fails.
if ~EyelinkInit(dummymode)
    fprintf('Eyelink Init aborted.\n');
    cleanup;  % cleanup function
    return;
end

%%% eyelink section
el = EyelinkInitDefaults(w);

el.backgroundcolour = colors.BACKGROUND(1);
el.targetbeep=1;
el.window = w;

% EyelinkUpdateDefaults(el);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Opening file in eyelink
i = Eyelink('openfile',file_name);
if i~=0
    disp(['Cannot create EDF file: ' file_name]);
    %cleanup; % cleanup function called
    return;
end


%%%% SET UP TRACKER CONFIGURATIONS
%Eyelink('command', 'calibration_type = HV9');
%Eyelink('command', 'screen_distance = 1102 1138');
%Eyelink('command', 'screen_distance = 70');

%%%% set parser (conservative saccade thresholds)
Eyelink('command', 'saccade_velocity_threshold = 35'); % based on previous experience, these are conservative to detect large saccades, see manual
Eyelink('command', 'saccade_acceleration_threshold = 9500');% based on previous experience, these are conservative to detect large saccades, see manual
Eyelink('command', 'saccade_motion_threshold = 0.15');% to try to ignore saccades smaller than this, a window

%%%% set EDF file contents
%%%% note that it is recommended to offline search for your own saccades based on velocity and then position
% the important ones are ..._event_filter and ..._sample_data

Eyelink('command', 'file_event_filter = LEFT,SACCADE,BLINK,MESSAGE'); % what you want in the file
% Sets which types of events will be written to EDF file. See tracker file
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

Eyelink('command', 'file_event_data = GAZE,AREA,VELOCITY');

Eyelink('command', 'file_sample_data = LEFT,GAZE,AREA'); % what you want to record

Eyelink('command', 'link_event_filter = LEFT,SACCADE,BLINK,MESSAGE'); % what you want in the file
% DATA.INI for types.
% Arguments: <list>: list of event types
% LEFT, RIGHT events for one or both eyes
% FIXATION fixation start and end events
% FIXUPDATE fixation (pursuit) state updates
% SACCADE saccade start and end
% BLINK blink start an end
% MESSAGE messages (user notes in file)
% BUTTON button 1..8 press or release

Eyelink('command', 'link_event_data = GAZE,AREA,VELOCITY');

Eyelink('command', 'link_sample_data  = LEFT,GAZE,AREA'); % what you want to record
% Arguments: <list>: list of data types
% GAZE screen xy (gaze) position
% GAZERES units-per-degree screen resolution
% HREF head-referenced gaze
% PUPIL raw eye camera pupil coordinates
% AREA pupil area
% STATUS warning and error flags
% BUTTON button state and change flags
% INPUT input port data lines




%     %%%% Calibrate the eye tracker
EyelinkDoTrackerSetup(el);


%%%% optional do a final check of calibration using driftcorrection
%  EyelinkDoDriftCorrection(el);


pause(.1)
el.targetbeep=0;

%Screen(colors.BACKGROUND); % A shortcut to Screen(w,'FillRect',colors.BACKGROUND); better timing
Screen(w,'FillRect',black);
Screen('Flip',w,[],[],dontsync);

Eyelink('startrecording');


eye_used = Eyelink('eyeavailable'); % get eye that's tracked




%%%% Sets up where to get gaze contingent data (i.e., what part of the index should be used

if eye_used == el.BINOCULAR | eye_used==el.LEFT_EYE; % if left eye or both eyes are tracked
    eye_used = el.LEFT_EYE; % use left eye
    eyetracked=1;
elseif eye_used == el.RIGHT_EYE;
    eyetracked=2;
end


if eye_used==-1
    eye_used=0;
    Screen(w,'close');
    Screen(buffer,'Close');
    
    Eyelink('stoprecording');
    Eyelink('closefile');
    Eyelink('shutdown');
    %error('eye_used==~1');
    return
end
x=[];
y=[];



%%%% record a few samples before we actually start displaying
WaitSecs(0.1);

%
Eyelink('Message', 'SYNCTIME');
firsttimeis = GetSecs;

while tr_num <= max_trials
    %FlushEvents('keyDown');	% discard all the chars from the Event Manager queue.
    
    %%%% eyelink section
    % Check recording status, stop display if error
    %     error=Eyelink('CheckRecording');
    %     if(error~=0)
    %         break;
    %     end
    %
    switch presentation_display
        
        case S_INST
            
            
            %% present the fixation stimulus first
            switch task_inst(tr_num)
                
                case 1 % pro
                    %%%%%
                    
                    Screen(w, 'FillOval',colors.PRO, Fix_stim);
                    Screen('Flip',w,[],[],dontsync)
                    Eyelink('Message', 'sINSTpro');
                    
                    %%%%%
                case 2 % anti
                    %%%%%
                    
                    Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                    Screen('Flip',w,[],[],dontsync)
                    Eyelink('Message', 'sINSTanti');
            end
            
            
            %% Gaze Contingent if we don't let it continue, then file events where eye is is irrelevant
            stopwhile = 0;
            while ~ stopwhile
                if Eyelink( 'NewFloatSampleAvailable') > 0
                    % get the sample in the form of an event structure
                    evt = Eyelink( 'NewestFloatSample');
                    x = evt.gx(eyetracked);       % get gaze position from sample */
                    y = evt.gy(eyetracked);
                    
                end
                
                %%
                if IsInRect(x,y, Fix_gaze)==1;
                    eye_at_fix=1;
                    eye_is=5;
                    stopwhile = 1;
                    % %%                    information on where eye is (irrelevant if gaze contingent to continue
                    %                 elseif IsInRect(x,y, L_target_gaze)==1;
                    %                     eye_at_fix=9;
                    %                     eye_is=180;
                    %                 elseif IsInRect(x,y, R_target_gaze)==1;
                    %                     eye_at_fix=9;
                    %                     eye_is=0;
                    %                 else
                    %                     eye_at_fix=9;
                    %                     eye_is=9;
                end %% end information on where the eye is
            end
            %%%%%
            trialtimestart = GetSecs; % especially important if maintainging trial time
            
            location_events(location_row, location_column)=[tr_num]; %match with f_events listed above
            location_column=location_column+1;
            
            %Present Instruction
            switch task_inst(tr_num)
                
                case 1 % pro
                    %%%%%
                    
                    Screen(w, 'FillOval',colors.PRO, Fix_stim);
                    Screen('Flip',w,[],[],dontsync)
                    Eyelink('Message', 'sINSTpro');
                    
                    
                    %%%% Get the clock time
                    timeis = GetSecs;
                    
                    WaitSecs('UntilTime', trialtimestart + 0.9);
                    
                    %%%% record current time
                    C_end = GetSecs;
                    
                    %%%% record the data from before pause
                    C_start=timeis;
                    
                    C_dur=C_end-C_start;
                    
                    Csw_acutal = NaN; % no switch times
                    Csw_length = NaN;
                    
                    
                    %%%% Increment to next display
                    presentation_display=presentation_display+1;
                    
                    %%%% save data
                    file_events(f_e_index,:)=[tr_num, S_INST, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, eye_at_fix, NaN, NaN]; %match with f_events listed above
                    f_e_index=f_e_index+1;
                    location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                    location_column=location_column+1;
                    
                    
                    %%%%%
                case 2 % anti
                    %%%%%
                    
                    Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                    Screen('Flip',w,[],[],dontsync)
                    Eyelink('Message', 'sINSTanti');
                    
                    %%%% Get the clock time
                    timeis = GetSecs;
                    
                    %%% wait the desired time
                    WaitSecs('UntilTime', trialtimestart + 0.9);
                    
                    %%%% record current time
                    C_end = GetSecs;
                    
                    %%%% record the data from before pause
                    C_start=timeis;
                    
                    
                    C_dur=C_end-C_start;
                    
                    Csw_acutal = NaN;
                    Csw_length = NaN;
                    
                    
                    %%%% Increment to next display
                    presentation_display=presentation_display+1;
                    
                    %%%% save data
                    file_events(f_e_index,:)=[tr_num, S_INST, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, eye_at_fix, NaN, NaN]; %match with f_events listed above
                    f_e_index=f_e_index+1;
                    location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                    location_column=location_column+1;
                    
                    
                case 3 % anti 2 pro
                    
                    if sw_time(tr_num)==-200
                        
                        Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                        Screen('Flip',w,[],[],dontsync)
                        Eyelink('Message', 'sINSTanti2proM200');
                        
                        
                        %%%% Get the clock time
                        timeis = GetSecs;
                        
                        %%% wait the desired time
                        WaitSecs('UntilTime', trialtimestart + 0.7);
                        
                        %%% here switch
                        Screen(w, 'FillOval',colors.PRO, Fix_stim);
                        Screen('Flip',w,[],[],dontsync)
                        
                        %%%% record current time
                        Csw = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        
                        Csw_actual = Csw - C_start;
                        
                        WaitSecs('UntilTime', trialtimestart + 0.9);
                        
                        
                        
                        %%%% record current time
                        C_end = GetSecs;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_length = C_end-Csw_actual;
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_INST, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, eye_at_fix, NaN, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                    elseif sw_time(tr_num)==-100
                        
                        Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                        Screen('Flip',w,[],[],dontsync)
                        Eyelink('Message', 'sINSTanti2proM100');
                        
                        
                        %%%% Get the clock time
                        timeis = GetSecs;
                        
                        %%% wait the desired time
                        WaitSecs('UntilTime', trialtimestart + 0.8);
                        
                        %%% here switch
                        Screen(w, 'FillOval',colors.PRO, Fix_stim);
                        Screen('Flip',w,[],[],dontsync)
                        
                        %%%% record current time
                        Csw = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        
                        Csw_actual = Csw - C_start;
                        
                        WaitSecs('UntilTime', trialtimestart + 0.9);
                        
                        
                        
                        %%%% record current time
                        C_end = GetSecs;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_length = C_end-Csw_actual;
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_INST, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, eye_at_fix, NaN, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                    elseif sw_time(tr_num)== 0
                        
                        Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                        Screen('Flip',w,[],[],dontsync)
                        Eyelink('Message', 'sINSTanti2proZero');
                        
                        
                        %%%% Get the clock time
                        timeis = GetSecs;
                        
                        %%% wait the desired time
                        WaitSecs('UntilTime', trialtimestart + 0.9);
                        
                        
                        %%%% record current time
                        Csw = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        
                        Csw_actual = Csw - C_start;
                        
                        
                        %%%% record current time
                        C_end = GetSecs;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_length = C_end-Csw_actual;
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_INST, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, eye_at_fix, NaN, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                    elseif sw_time(tr_num)== 100
                        
                        Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                        Screen('Flip',w,[],[],dontsync)
                        Eyelink('Message', 'sINSTanti2proP100');
                        
                        
                        %%%% Get the clock time
                        timeis = GetSecs;
                        
                        WaitSecs('UntilTime', trialtimestart + 0.9);
                        
                        %%%% record current time
                        C_end = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_acutal = NaN; % no switch times
                        Csw_length = NaN;
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_INST, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, eye_at_fix, NaN, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                    end
                    
                    
                    %%%%
                case 4 % pro 2 anti
                    
                    if sw_time(tr_num)==-200
                        
                        Screen(w, 'FillOval',colors.PRO, Fix_stim);
                        Screen('Flip',w,[],[],dontsync)
                        Eyelink('Message', 'sINSTpro2antiM200');
                        
                        
                        %%%% Get the clock time
                        timeis = GetSecs;
                        
                        %%% wait the desired time
                        WaitSecs('UntilTime', trialtimestart + 0.7);
                        
                        %%% here switch
                        Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                        Screen('Flip',w,[],[],dontsync)
                        
                        %%%% record current time
                        Csw = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        
                        Csw_actual = Csw - C_start;
                        
                        WaitSecs('UntilTime', trialtimestart + 0.9);
                        
                        
                        
                        %%%% record current time
                        C_end = GetSecs;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_length = C_end-Csw_actual;
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_INST, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, eye_at_fix, NaN, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                    elseif sw_time(tr_num)==-100
                        
                        Screen(w, 'FillOval',colors.PRO, Fix_stim);
                        Screen('Flip',w,[],[],dontsync)
                        Eyelink('Message', 'sINSTpro2antiM100');
                        
                        
                        %%%% Get the clock time
                        timeis = GetSecs;
                        
                        %%% wait the desired time
                        WaitSecs('UntilTime', trialtimestart + 0.8);
                        
                        %%% here switch
                        Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                        Screen('Flip',w,[],[],dontsync)
                        
                        %%%% record current time
                        Csw = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        
                        Csw_actual = Csw - C_start;
                        
                        WaitSecs('UntilTime', trialtimestart + 0.9);
                        
                        
                        
                        %%%% record current time
                        C_end = GetSecs;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_length = C_end-Csw_actual;
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_INST, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, eye_at_fix, NaN, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                    elseif sw_time(tr_num)== 0
                        
                        Screen(w, 'FillOval',colors.PRO, Fix_stim);
                        Screen('Flip',w,[],[],dontsync)
                        Eyelink('Message', 'sINSTpro2antiZero');
                        
                        
                        %%%% Get the clock time
                        timeis = GetSecs;
                        
                        %%% wait the desired time
                        WaitSecs('UntilTime', trialtimestart + 0.9);
                        
                        
                        %%%% record current time
                        Csw = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        
                        Csw_actual = Csw - C_start;
                        
                        
                        
                        
                        %%%% record current time
                        C_end = GetSecs;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_length = C_end-Csw_actual;
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_INST, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, eye_at_fix, NaN, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                    elseif sw_time(tr_num)== 100
                        
                        Screen(w, 'FillOval',colors.PRO, Fix_stim);
                        Screen('Flip',w,[],[],dontsync)
                        Eyelink('Message', 'sINSTpro2antiP100');
                        
                        
                        %%%% Get the clock time
                        timeis = GetSecs;
                        
                        WaitSecs('UntilTime', trialtimestart + 0.9);
                        
                        %%%% record current time
                        C_end = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_acutal = NaN; % no switch times
                        Csw_length = NaN;
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_INST, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, eye_at_fix, NaN, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                    end
                    
                    
            end % end switch task_inst
            
            
            
        case S_RESP
            
            
            %Present Instruction
            switch resp_period(tr_num)
                %%%%
                
                
                case 1 % pro
                    
                    
                    if stim_location(tr_num)==0 % right stim right targ
                        Screen(w, 'FillOval',colors.PRO, Fix_stim);
                        Screen(w, 'FillOval',colors.STIM,R_stim_wide);
                        Screen('Flip',w,[],[],dontsync)
                        Eyelink('Message', 'sRESPproright');
                        
                        Correct_Gaze_Rect = R_target_gaze;
                        
                    elseif stim_location(tr_num)==180 % left stim left targ
                        Screen(w, 'FillOval',colors.PRO, Fix_stim);
                        Screen(w, 'FillOval',colors.STIM,L_stim_wide);
                        Screen('Flip',w,[],[],dontsync)
                        Eyelink('Message', 'sRESPproleft');
                        
                        Correct_Gaze_Rect = L_target_gaze;
                        
                    end
                    
                    %%%% Get the clock time
                    timeis=GetSecs;
                    startwhile = GetSecs;
                    % this all works except for exiting out of the loop
                    stopwhile = 0;
                    while ~ stopwhile
                        if Eyelink( 'NewFloatSampleAvailable') > 0
                            % get the sample in the form of an event structure
                            evt = Eyelink( 'NewestFloatSample');
                            x = evt.gx(eyetracked);       % get gaze position from sample */
                            y = evt.gy(eyetracked);
                            
                        end
                        
                        if IsInRect(x,y, Correct_Gaze_Rect)==1;
                            eye_at_resp=1;
                            if IsInRect(x,y, L_target_gaze)==1;
                                eye_is=180;
                            elseif IsInRect(x,y, R_target_gaze)==1;
                                eye_is=0;
                            end
                            WaitSecs(0.16); %160 ms
                            %Snd('Play', el.calibrationsuccesssound)
                            break
                        end
                        
                        stopwhile = GetSecs - startwhile > maxwait - 0.9; % here can't use WaitSecs, otherwise will not enter above If statement
                        
                        eye_at_resp=9;
                        eye_is=9;
                        
                    end  % end GCD stopwhile
                    
                    % WaitSecs('UntilTime', trialtimestart + maxwait)
                    
                    %%%% record current time
                    C_end = GetSecs;
                    
                    %%%% record the data from before pause
                    C_start=timeis;
                    
                    C_dur=C_end-C_start;
                    
                    Csw_acutal = NaN; % no switch times
                    Csw_length = NaN;
                    
                    
                    %%%% Increment to next display
                    presentation_display=presentation_display+1;
                    
                    %%%% save data
                    file_events(f_e_index,:)=[tr_num, S_RESP, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, NaN, eye_at_resp, NaN]; %match with f_events listed above
                    f_e_index=f_e_index+1;
                    location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                    location_column=location_column+1;
                    
                    
                    
                    
                    %%%%%
                case 2 % anti
                    %%%%%
                    
                    
                    if stim_location(tr_num)==0 % right stim right targ
                        Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                        Screen(w, 'FillOval',colors.STIM,R_stim_wide);
                        Screen('Flip',w,[],[],dontsync)
                        Eyelink('Message', 'sRESPantileft');
                        
                        Correct_Gaze_Rect = L_target_gaze;
                        
                    elseif stim_location(tr_num)==180 % left stim left targ
                        Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                        Screen(w, 'FillOval',colors.STIM,L_stim_wide);
                        Screen('Flip',w,[],[],dontsync)
                        Eyelink('Message', 'sRESPantiright');
                        
                        Correct_Gaze_Rect = R_target_gaze;
                        
                    end
                    
                    %%%% Get the clock time
                    timeis=GetSecs;
                    startwhile = GetSecs;
                    stopwhile = 0;
                    while ~ stopwhile
                        if Eyelink( 'NewFloatSampleAvailable') > 0
                            % get the sample in the form of an event structure
                            evt = Eyelink( 'NewestFloatSample');
                            x = evt.gx(eyetracked);       % get gaze position from sample */
                            y = evt.gy(eyetracked);
                            
                        end
                        
                        if IsInRect(x,y, Correct_Gaze_Rect)==1;
                            eye_at_resp=1;
                            if IsInRect(x,y, L_target_gaze)==1;
                                eye_is=180;
                            elseif IsInRect(x,y, R_target_gaze)==1;
                                eye_is=0;
                            end
                            WaitSecs(0.16); %160 ms
                            
                            %Snd('Play', el.calibrationsuccesssound)
                            break
                        end
                        
                        stopwhile = GetSecs - startwhile > maxwait - 0.9; % here can't use WaitSecs, otherwise will not enter above If statement
                        
                        eye_at_resp=9;
                        eye_is=9;
                        
                    end  % end GCD stopwhile
                    
                    % WaitSecs('UntilTime', trialtimestart + maxwait)
                    
                    %%%% record current time
                    C_end = GetSecs;
                    
                    %%%% record the data from before pause
                    C_start=timeis;
                    
                    C_dur=C_end-C_start;
                    
                    Csw_acutal = NaN; % no switch times
                    Csw_length = NaN;
                    
                    
                    %%%% Increment to next display
                    presentation_display=presentation_display+1;
                    
                    %%%% save data
                    file_events(f_e_index,:)=[tr_num, S_RESP, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, NaN, eye_at_resp, NaN]; %match with f_events listed above
                    f_e_index=f_e_index+1;
                    location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                    location_column=location_column+1;
                    
                    %%%%%
                    
                    
                    %%%%%
                case 3 % anti2pro
                    %%%%%
                    if sw_time(tr_num)==-200
                        
                        if stim_location(tr_num)==0 % right stim right targ
                            Screen(w, 'FillOval',colors.PRO, Fix_stim); % at -200 it has already switched
                            Screen(w, 'FillOval',colors.STIM,R_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPanti2prorightM200');
                            
                            Correct_Gaze_Rect = R_target_gaze;
                            
                        elseif stim_location(tr_num)==180 % left stim left targ
                            Screen(w, 'FillOval',colors.PRO, Fix_stim);% at -200 it has already switched
                            Screen(w, 'FillOval',colors.STIM,L_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPanti2proleftM200');
                            
                            Correct_Gaze_Rect = L_target_gaze;
                            
                        end
                        
                        %%%% Get the clock time
                        timeis=GetSecs;
                        startwhile = GetSecs;
                        stopwhile = 0;
                        while ~ stopwhile
                            if Eyelink( 'NewFloatSampleAvailable') > 0
                                % get the sample in the form of an event structure
                                evt = Eyelink( 'NewestFloatSample');
                                x = evt.gx(eyetracked);       % get gaze position from sample */
                                y = evt.gy(eyetracked);
                                
                            end
                            
                            if IsInRect(x,y, Correct_Gaze_Rect)==1;
                                eye_at_resp=1;
                                if IsInRect(x,y, L_target_gaze)==1;
                                    eye_is=180;
                                elseif IsInRect(x,y, R_target_gaze)==1;
                                    eye_is=0;
                                end
                                WaitSecs(0.16); %160 ms
                                
                                %Snd('Play', el.calibrationsuccesssound)
                                break
                            end
                            
                            stopwhile = GetSecs - startwhile > maxwait - 0.9; % here can't use WaitSecs, otherwise will not enter above If statement
                            
                            eye_at_resp=9;
                            eye_is=9;
                            
                        end  % end GCD stopwhile
                        
                        % WaitSecs('UntilTime', trialtimestart + maxwait)
                        %%%% record current time
                        C_end = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_acutal = NaN; % no switch times
                        Csw_length = NaN;
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_RESP, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, NaN, eye_at_resp, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                    elseif sw_time(tr_num)==-100
                        
                        if stim_location(tr_num)==0 % right stim right targ
                            Screen(w, 'FillOval',colors.PRO, Fix_stim); % at -100 it has already switched
                            Screen(w, 'FillOval',colors.STIM,R_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPanti2prorightM100');
                            
                            Correct_Gaze_Rect = R_target_gaze;
                            
                        elseif stim_location(tr_num)==180 % left stim left targ
                            Screen(w, 'FillOval',colors.PRO, Fix_stim);% at -100 it has already switched
                            Screen(w, 'FillOval',colors.STIM,L_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPanti2proleftM100');
                            
                            Correct_Gaze_Rect = L_target_gaze;
                            
                        end
                        
                        %%%% Get the clock time
                        timeis=GetSecs;
                        startwhile = GetSecs;
                        stopwhile = 0;
                        while ~ stopwhile
                            if Eyelink( 'NewFloatSampleAvailable') > 0
                                % get the sample in the form of an event structure
                                evt = Eyelink( 'NewestFloatSample');
                                x = evt.gx(eyetracked);       % get gaze position from sample */
                                y = evt.gy(eyetracked);
                                
                            end
                            
                            if IsInRect(x,y, Correct_Gaze_Rect)==1;
                                eye_at_resp=1;
                                if IsInRect(x,y, L_target_gaze)==1;
                                    eye_is=180;
                                elseif IsInRect(x,y, R_target_gaze)==1;
                                    eye_is=0;
                                end
                                WaitSecs(0.16); %160 ms
                                
                                %Snd('Play', el.calibrationsuccesssound)
                                break
                            end
                            
                            stopwhile = GetSecs - startwhile > maxwait - 0.9; % here can't use WaitSecs, otherwise will not enter above If statement
                            
                            eye_at_resp=9;
                            eye_is=9;
                            
                        end  % end GCD stopwhile
                        
                        % WaitSecs('UntilTime', trialtimestart + maxwait)
                        %%%% record current time
                        C_end = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_acutal = NaN; % no switch times
                        Csw_length = NaN;
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_RESP, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, NaN, eye_at_resp, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                    elseif sw_time(tr_num)== 0
                        
                        if stim_location(tr_num)==0 % right stim right targ
                            Screen(w, 'FillOval',colors.PRO, Fix_stim);
                            Screen(w, 'FillOval',colors.STIM,R_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPanti2prorightZero');
                            
                            Correct_Gaze_Rect = R_target_gaze;
                            
                        elseif stim_location(tr_num)==180 % left stim left targ
                            Screen(w, 'FillOval',colors.PRO, Fix_stim);%
                            Screen(w, 'FillOval',colors.STIM,L_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPanti2proleftZero');
                            
                            Correct_Gaze_Rect = L_target_gaze;
                            
                        end
                        
                        %%%% Get the clock time
                        timeis=GetSecs;
                        %%%% record current time
                        Csw = GetSecs;
                        startwhile = GetSecs;
                        stopwhile = 0;
                        while ~ stopwhile
                            if Eyelink( 'NewFloatSampleAvailable') > 0
                                % get the sample in the form of an event structure
                                evt = Eyelink( 'NewestFloatSample');
                                x = evt.gx(eyetracked);       % get gaze position from sample */
                                y = evt.gy(eyetracked);
                                
                            end
                            
                            if IsInRect(x,y, Correct_Gaze_Rect)==1;
                                eye_at_resp=1;
                                if IsInRect(x,y, L_target_gaze)==1;
                                    eye_is=180;
                                elseif IsInRect(x,y, R_target_gaze)==1;
                                    eye_is=0;
                                end
                                WaitSecs(0.16); %160 ms
                                
                                %Snd('Play', el.calibrationsuccesssound)
                                break
                            end
                            
                            stopwhile = GetSecs - startwhile > maxwait - 0.9; % here can't use WaitSecs, otherwise will not enter above If statement
                            
                            eye_at_resp=9;
                            eye_is=9;
                            
                        end  % end GCD stopwhile
                        
                        % WaitSecs('UntilTime', trialtimestart + maxwait)
                        %%%% record current time
                        C_end = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_acutal = Csw - C_start; % sanity check - zero
                        Csw_length = NaN; % irrelevant
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_RESP, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, NaN, eye_at_resp, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                        
                    elseif sw_time(tr_num)== 100
                        
                        if stim_location(tr_num)==0 % right stim right targ
                            Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                            Screen(w, 'FillOval',colors.STIM,R_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPanti2prorightP100');
                            
                            Correct_Gaze_Rect = R_target_gaze;
                            
                            
                            %%%% Get the clock time
                            timeis=GetSecs;
                            
                            
                            %%% wait the desired time
                            WaitSecs('UntilTime', trialtimestart + 1);
                            
                            %%% here switch
                            Screen(w, 'FillOval',colors.PRO, Fix_stim);
                            Screen(w, 'FillOval',colors.STIM,R_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            
                            %%%% record current time
                            Csw = GetSecs;
                            
                        elseif stim_location(tr_num)==180 % left stim left targ
                            Screen(w, 'FillOval',colors.ANTI, Fix_stim);%
                            Screen(w, 'FillOval',colors.STIM,L_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPanti2proleftP100');
                            
                            Correct_Gaze_Rect = L_target_gaze;
                            
                            %%%% Get the clock time
                            timeis=GetSecs;
                            
                            
                            %%% wait the desired time
                            WaitSecs('UntilTime', trialtimestart + 1);
                            
                            %%% here switch
                            Screen(w, 'FillOval',colors.PRO, Fix_stim);
                            Screen(w, 'FillOval',colors.STIM,L_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            
                            %%%% record current time
                            Csw = GetSecs;
                            
                            
                        end
                        
                        startwhile = GetSecs;
                        stopwhile = 0;
                        while ~ stopwhile
                            if Eyelink( 'NewFloatSampleAvailable') > 0
                                % get the sample in the form of an event structure
                                evt = Eyelink( 'NewestFloatSample');
                                x = evt.gx(eyetracked);       % get gaze position from sample */
                                y = evt.gy(eyetracked);
                                
                            end
                            
                            if IsInRect(x,y, Correct_Gaze_Rect)==1;
                                eye_at_resp=1;
                                if IsInRect(x,y, L_target_gaze)==1;
                                    eye_is=180;
                                elseif IsInRect(x,y, R_target_gaze)==1;
                                    eye_is=0;
                                end
                                WaitSecs(0.16); %160 ms
                                
                                %Snd('Play', el.calibrationsuccesssound)
                                break
                            end
                            
                            stopwhile = GetSecs - startwhile > maxwait - 0.9; % here can't use WaitSecs, otherwise will not enter above If statement
                            
                            eye_at_resp=9;
                            eye_is=9;
                            
                        end  % end GCD stopwhile
                        
                        % WaitSecs('UntilTime', trialtimestart + maxwait)
                        
                        %%%% record current time
                        C_end = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_acutal = Csw - C_start; % sanity check - zero
                        Csw_length = NaN; % irrelevant
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_RESP, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, NaN, eye_at_resp, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                        
                        
                    end
                    %%%%%
                    
                    
                    %%%%%
                case 4 % pro2anti
                    %%%%%
                    if sw_time(tr_num)==-200
                        
                        if stim_location(tr_num)==0 % right stim right targ
                            Screen(w, 'FillOval',colors.ANTI, Fix_stim); % at -200 it has already switched
                            Screen(w, 'FillOval',colors.STIM,R_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPpro2antileftM200');
                            
                            Correct_Gaze_Rect = L_target_gaze;
                            
                        elseif stim_location(tr_num)==180 % left stim left targ
                            Screen(w, 'FillOval',colors.ANTI, Fix_stim);% at -200 it has already switched
                            Screen(w, 'FillOval',colors.STIM,L_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPpro2antileftM200');
                            
                            Correct_Gaze_Rect = L_target_gaze;
                            
                        end
                        
                        %%%% Get the clock time
                        timeis=GetSecs;
                        startwhile = GetSecs;
                        stopwhile = 0;
                        while ~ stopwhile
                            if Eyelink( 'NewFloatSampleAvailable') > 0
                                % get the sample in the form of an event structure
                                evt = Eyelink( 'NewestFloatSample');
                                x = evt.gx(eyetracked);       % get gaze position from sample */
                                y = evt.gy(eyetracked);
                                
                            end
                            
                            if IsInRect(x,y, Correct_Gaze_Rect)==1;
                                eye_at_resp=1;
                                if IsInRect(x,y, L_target_gaze)==1;
                                    eye_is=180;
                                elseif IsInRect(x,y, R_target_gaze)==1;
                                    eye_is=0;
                                end
                                WaitSecs(0.16); %160 ms
                                
                                %Snd('Play', el.calibrationsuccesssound)
                                break
                            end
                            
                            stopwhile = GetSecs - startwhile > maxwait - 0.9; % here can't use WaitSecs, otherwise will not enter above If statement
                            
                            eye_at_resp=9;
                            eye_is=9;
                            
                        end  % end GCD stopwhile
                        
                        % WaitSecs('UntilTime', trialtimestart + maxwait)
                        %%%% record current time
                        C_end = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_acutal = NaN; % no switch times
                        Csw_length = NaN;
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_RESP, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, NaN, eye_at_resp, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                    elseif sw_time(tr_num)==-100
                        
                        if stim_location(tr_num)==0 % right stim right targ
                            Screen(w, 'FillOval',colors.ANTI, Fix_stim); % at -100 it has already switched
                            Screen(w, 'FillOval',colors.STIM,R_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPpro2antileftM100');
                            
                            Correct_Gaze_Rect = L_target_gaze;
                            
                        elseif stim_location(tr_num)==180 % left stim left targ
                            Screen(w, 'FillOval',colors.ANTI, Fix_stim);% at -100 it has already switched
                            Screen(w, 'FillOval',colors.STIM,L_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPpro2antirightM100');
                            
                            Correct_Gaze_Rect = R_target_gaze;
                            
                        end
                        
                        %%%% Get the clock time
                        timeis=GetSecs;
                        startwhile = GetSecs;
                        stopwhile = 0;
                        while ~ stopwhile
                            if Eyelink( 'NewFloatSampleAvailable') > 0
                                % get the sample in the form of an event structure
                                evt = Eyelink( 'NewestFloatSample');
                                x = evt.gx(eyetracked);       % get gaze position from sample */
                                y = evt.gy(eyetracked);
                                
                            end
                            
                            if IsInRect(x,y, Correct_Gaze_Rect)==1;
                                eye_at_resp=1;
                                if IsInRect(x,y, L_target_gaze)==1;
                                    eye_is=180;
                                elseif IsInRect(x,y, R_target_gaze)==1;
                                    eye_is=0;
                                end
                                WaitSecs(0.16); %160 ms
                                
                                %Snd('Play', el.calibrationsuccesssound)
                                break
                            end
                            
                            stopwhile = GetSecs - startwhile > maxwait - 0.9; % here can't use WaitSecs, otherwise will not enter above If statement
                            
                            eye_at_resp=9;
                            eye_is=9;
                            
                        end  % end GCD stopwhile
                        
                        % WaitSecs('UntilTime', trialtimestart + maxwait)
                        %%%% record current time
                        C_end = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_acutal = NaN; % no switch times
                        Csw_length = NaN;
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_RESP, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, NaN, eye_at_resp, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                    elseif sw_time(tr_num)== 0
                        
                        if stim_location(tr_num)==0 % right stim right targ
                            Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                            Screen(w, 'FillOval',colors.STIM,R_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPpro2antileftZero');
                            
                            Correct_Gaze_Rect = L_target_gaze;
                            
                        elseif stim_location(tr_num)==180 % left stim left targ
                            Screen(w, 'FillOval',colors.ANTI, Fix_stim);%
                            Screen(w, 'FillOval',colors.STIM,L_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPpro2antirightZero');
                            
                            Correct_Gaze_Rect = R_target_gaze;
                            
                        end
                        
                        %%%% Get the clock time
                        timeis=GetSecs;
                        %%%% record current time
                        Csw = GetSecs;
                        startwhile = GetSecs;
                        stopwhile = 0;
                        while ~ stopwhile
                            if Eyelink( 'NewFloatSampleAvailable') > 0
                                % get the sample in the form of an event structure
                                evt = Eyelink( 'NewestFloatSample');
                                x = evt.gx(eyetracked);       % get gaze position from sample */
                                y = evt.gy(eyetracked);
                                
                            end
                            
                            if IsInRect(x,y, Correct_Gaze_Rect)==1;
                                eye_at_resp=1;
                                if IsInRect(x,y, L_target_gaze)==1;
                                    eye_is=180;
                                elseif IsInRect(x,y, R_target_gaze)==1;
                                    eye_is=0;
                                end
                                WaitSecs(0.16); %160 ms
                                
                                %Snd('Play', el.calibrationsuccesssound)
                                break
                            end
                            
                            stopwhile = GetSecs - startwhile > maxwait - 0.9; % here can't use WaitSecs, otherwise will not enter above If statement
                            
                            eye_at_resp=9;
                            eye_is=9;
                            
                        end  % end GCD stopwhile
                        
                        % WaitSecs('UntilTime', trialtimestart + maxwait)
                        
                        %%%% record current time
                        C_end = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_acutal = Csw - C_start; % sanity check - zero
                        Csw_length = NaN; % irrelevant
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_RESP, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, NaN, eye_at_resp, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                        
                    elseif sw_time(tr_num)== 100
                        
                        if stim_location(tr_num)==0 % right stim right targ
                            Screen(w, 'FillOval',colors.PRO, Fix_stim);
                            Screen(w, 'FillOval',colors.STIM,R_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPpro2antileftP100');
                            
                            Correct_Gaze_Rect = L_target_gaze;
                            
                            
                            %%%% Get the clock time
                            timeis=GetSecs;
                            
                            
                            %%% wait the desired time
                            WaitSecs('UntilTime', trialtimestart + 1);
                            
                            %%% here switch
                            Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                            Screen(w, 'FillOval',colors.STIM,R_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            
                            %%%% record current time
                            Csw = GetSecs;
                            
                        elseif stim_location(tr_num)==180 % left stim left targ
                            Screen(w, 'FillOval',colors.PRO, Fix_stim);%
                            Screen(w, 'FillOval',colors.STIM,L_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            Eyelink('Message', 'sRESPpro2antirightP100');
                            
                            Correct_Gaze_Rect = R_target_gaze;
                            
                            %%%% Get the clock time
                            timeis=GetSecs;
                            
                            
                            %%% wait the desired time
                            WaitSecs('UntilTime', trialtimestart + 1);
                            
                            %%% here switch
                            Screen(w, 'FillOval',colors.ANTI, Fix_stim);
                            Screen(w, 'FillOval',colors.STIM,L_stim_wide);
                            Screen('Flip',w,[],[],dontsync)
                            
                            %%%% record current time
                            Csw = GetSecs;
                            
                            
                        end
                        
                        startwhile = GetSecs;
                        stopwhile = 0;
                        while ~ stopwhile
                            if Eyelink( 'NewFloatSampleAvailable') > 0
                                % get the sample in the form of an event structure
                                evt = Eyelink( 'NewestFloatSample');
                                x = evt.gx(eyetracked);       % get gaze position from sample */
                                y = evt.gy(eyetracked);
                                
                            end
                            
                            if IsInRect(x,y, Correct_Gaze_Rect)==1;
                                eye_at_resp=1;
                                if IsInRect(x,y, L_target_gaze)==1;
                                    eye_is=180;
                                elseif IsInRect(x,y, R_target_gaze)==1;
                                    eye_is=0;
                                end
                                WaitSecs(0.16); %160 ms
                                
                                %Snd('Play', el.calibrationsuccesssound)
                                break
                            end
                            
                            stopwhile = GetSecs - startwhile > maxwait - 0.9; % here can't use WaitSecs, otherwise will not enter above If statement
                            
                            eye_at_resp=9;
                            eye_is=9;
                            
                        end  % end GCD stopwhile
                        
                        % WaitSecs('UntilTime', trialtimestart + maxwait)
                        %%%% record current time
                        C_end = GetSecs;
                        
                        %%%% record the data from before pause
                        C_start=timeis;
                        
                        C_dur=C_end-C_start;
                        
                        Csw_acutal = Csw - C_start; % sanity check - zero
                        Csw_length = NaN; % irrelevant
                        
                        
                        %%%% Increment to next display
                        presentation_display=presentation_display+1;
                        
                        %%%% save data
                        file_events(f_e_index,:)=[tr_num, S_RESP, task_inst(tr_num), stim_location(tr_num), resp_period(tr_num),sw_time(tr_num), C_start, C_end,C_dur, Csw_acutal, Csw_length, NaN, eye_at_resp, NaN]; %match with f_events listed above
                        f_e_index=f_e_index+1;
                        location_events(location_row, location_column)=[eye_is]; %match with f_events listed above
                        location_column=location_column+1;
                        
                        
                        
                    end
                    %%%%%
                    
            end % end switch or while
            
        case S_ITI
            
            Screen(w, 'FillRect',colors.GREY, ITI_stim);
            Screen('Flip',w,[],[],dontsync)
            %%%% write a message
            Eyelink('Message', sprintf('sITIafter%i',tr_num)); % TFIX = trial end fixation
            
            %%% pause for FIXED time
            WaitSecs(0.6);
            
            %%%% Reset to first display
            presentation_display=1;
            
            tr_num = tr_num+1;
            
            
            %                 %%%% optional:drift correction
            %                 % if tr_num ~= max_trials
            %                 % do a drift correction after calibration using driftcorrection
            %                 % Eyelink('stoprecording');
            %                 % EyelinkDoDriftCorrection(el);
            %
            %                 %eye_used = Eyelink('eyeavailable'); % get eye that's tracked
            %                 %Eyelink('startrecording');
            %                 %end
            
    end % end switch presentation display
    
end % while loop


%%%% Present cross at end for hemodynamic return (16s)
Screen(w, 'FillRect',[200 200 200], ITI_stim);%
Screen('Flip',w,[],[],dontsync)
endfix = 2;
WaitSecs(endfix);


lasttimeis = GetSecs;

A.total_trial_time = lasttimeis - firsttimeis - endfix;
A.file_events=file_events;
text_file=A.file_events; % text events contains basic info on trial parameters and whether eye was at the right place
header_file={};
header_file = [header_file [ A.exp_state(1,:)] [ A.exp_state(2,:)] [ A.exp_state(3,:)] [ A.exp_state(4,:)] [ A.exp_state(5,:)] [ A.exp_state(6,:)] ...
    [ A.exp_state(7,:)] [ A.exp_state(8,:)] [ A.exp_state(9,:)] [ A.exp_state(10,:)] [ A.exp_state(11,:)] [ A.exp_state(12,:)] [ A.exp_state(13,:)] [ A.exp_state(14,:)] ];

% output directory
%cd c:\_ian\EDF_data\TSwitch\text_files\
dlmwrite(file_name, text_file,'delimiter','\t'); % text_events variable will be saved in an ASCII file, delimited by tab for use in other programs
dlmwrite(file_name, header_file,'delimiter','','-append');

%cd c:\_ian\EDF_data\TSwitch\EDF_and_Mat_files\
save(file_name, 'A'); % saves all of 'A.' structure into a .mat file. Can be loaded using load('filename')

FlushEvents('keyDown');	% discard all the chars from the Event Manager queue.

Screen(colors.BACKGROUND); % erase entire screen, s



pause(1)
ShowCursor;
Screen(w,'close');
commandwindow;


%% eyelink section
Eyelink('stoprecording');
Eyelink('closefile');
Eyelink('receivefile');
Eyelink('setofflinemode');


%restore
Screen('Preference', 'SuppressAllWarnings', oldEnableFlag);


%%% trial Gen
function [task_inst, stim_location, resp_period, sw_time] = trial_gen(trial_seq, max_trials)
% function [returned fields] = trial_gen(user_entry)
% takes user's entry [1, 2, 3, 4] corresponding to 4 preset trial orders
% (generated externally in a pseudorandom order)
% 16 trial version matches those 4 trial orders of SingleERDProAntiSwitch EPRIME paradigms
% created by Ian C at Queen's University, Kingston, Canada

%%% for task_inst 1 = pro, 2 = anti
%%% for resp_period 1 = pro, 2 = anti, 3 = anti2pro, 4 = pro2anti
%%% for stim_location R = 0, L = 180 (based on ISCAN EPRIME2 programs
%%% for sw_time -1 = nonswitch, 100 = 100ms, 150 = 150ms, 200 = 200ms
task_inst = [];
resp_period = [];
stim_location = [];
sw_time = [];


%%% 48 trial repeat version 33% switch

trial_elements = [1:1:max_trials];


switch trial_seq
    
    case 0 % build in repetitions of 24 trials
        % addition of zero switch trials, balanced with other switch times and conditions
        %         task_inst = [2 1 2 ZERO2 2 1 ZERO1 2 2 1 2 1 2 1 1 2 1 2 ZERO2 2 1 1 1 ZERO1];
        %         resp_period = [2 4 3 0ZERO3 2 4 180ZERO4 3 3 1 3 4 3 1 1 3 4 2 180ZERO3 2 4 1 4 0ZERO4];
        %         stim_location = [180 0 180 0ZERO 0 0 180ZERO 180 0 0 0 0 180 180 180 0 180 0 180ZERO 180 180 0 180 0ZERO];
        %         sw_time = [-1 100 -100 ZERO -1 -100 ZERO 100 -200 -1 100 -200 -200 -1 -1 -100 100 -1 ZERO -1 -100 -1 -200 ZERO];
        
        task_inst = [ones(24,1)' ones(24,1)'*2];
        stim_location = [zeros(12,1)' ones(12,1)'*180 zeros(12,1)' ones(12,1)'*180];
        resp_period = [ones(8,1)' 4 4 4 4  ones(8,1)' 4 4 4 4  ones(8,1)'*2 3 3 3 3 ones(8,1)'*2 3 3 3 3];
        sw_time = [ones(8,1)'*-1 -200 -100 0 100 ones(8,1)'*-1 -200 -100 0 100 ones(8,1)'*-1 -200 -100 0 100 ones(8,1)'*-1 -200 -100 0 100];
        
        task_inst = repmat(task_inst,1,ceil(max_trials/48));
        stim_location = repmat(stim_location,1,ceil(max_trials/48));
        resp_period = repmat(resp_period,1,ceil(max_trials/48));
        sw_time = repmat(sw_time,1,ceil(max_trials/48));
        
        % make sure there are no more than five in a row of stimulus in
        % same locaiton
        while find(diff(stim_location,6)==0)
            neworder = randperm(length(trial_elements)); % resorts trial_elements,
            % then selects corresponding elements of
            % task_inst, resp_period, stim_location and sw_time,
            % keeping their relationship with one another the same (based on version 1)
            
            
            task_inst = task_inst(neworder);
            resp_period = resp_period(neworder);
            stim_location = stim_location(neworder);
            sw_time = sw_time(neworder);
        end
        
    case 1
        task_inst = ones(48,1)';
        stim_location = [zeros(24,1)' ones(24,1)'*180];
        resp_period = ones(48,1)';
        sw_time = ones(48,1)'*-1;
        
        task_inst = repmat(task_inst,1,ceil(max_trials/48));
        stim_location = repmat(stim_location,1,ceil(max_trials/48));
        resp_period = repmat(resp_period,1,ceil(max_trials/48));
        sw_time = repmat(sw_time,1,ceil(max_trials/48));
        
        % make sure there are no more than five in a row of stimulus in
        % same locaiton
        while find(diff(stim_location,6)==0)
            neworder = randperm(length(trial_elements)); % resorts trial_elements,
            % then selects corresponding elements of
            % task_inst, resp_period, stim_location and sw_time,
            % keeping their relationship with one another the same (based on version 1)
            task_inst = task_inst(neworder);
            resp_period = resp_period(neworder);
            stim_location = stim_location(neworder);
            sw_time = sw_time(neworder);
        end
        
    case 2
        task_inst = ones(48,1)'*2;
        stim_location = [zeros(24,1)' ones(24,1)'*180];
        resp_period = ones(48,1)'*2;
        sw_time = ones(48,1)'*-1;
        
        task_inst = repmat(task_inst,1,ceil(max_trials/48));
        stim_location = repmat(stim_location,1,ceil(max_trials/48));
        resp_period = repmat(resp_period,1,ceil(max_trials/48));
        sw_time = repmat(sw_time,1,ceil(max_trials/48));
        
        % make sure there are no more than five in a row of stimulus in
        % same locaiton
        while find(diff(stim_location,6)==0)
            neworder = randperm(length(trial_elements)); % resorts trial_elements,
            % then selects corresponding elements of
            % task_inst, resp_period, stim_location and sw_time,
            % keeping their relationship with one another the same (based on version 1)
            task_inst = task_inst(neworder);
            resp_period = resp_period(neworder);
            stim_location = stim_location(neworder);
            sw_time = sw_time(neworder);
        end
        
        
end








