% http://peterscarfe.com/beepdemo.html

% Clear the workspace
clearvars;
close all;
sca;

% Create serial port, configure and open
s = serial('com1');      % create serial object
set(s,'BaudRate',115200,'DataBits',8,'Parity','none','StopBits', 1);% config
fopen(s);                      % create connection

% set bitsi bits to trigger mode
fwrite(s, 0);  
fwrite(s, 2);
fwrite(s, 255);
WaitSecs(1);

% Initialize Sounddriver
InitializePsychSound(1);

% Number of channels and Frequency of the sound
nrchannels = 2;
freq = 48000;

% How many times to we wish to play the sound
repetitions = 1;

% Length of the beep
beepLengthSecs = 0.03;

% Length of the pause between beeps
beepPauseTime = 1;

% Start immediately (0 = immediately)
startCue = 0;

% Should we wait for the device to really start (1 = yes)
% INFO: See help PsychPortAudio
waitForDeviceStart = 1;

% Open Psych-Audio port, with the follow arguements
% (1) [] = default sound device
% (2) 1 = sound playback only
% (3) 1 = default level of latency
% (4) Requested frequency in samples per second
% (5) 2 = stereo putput
pahandle = PsychPortAudio('Open', [], 1, 1, freq, nrchannels);

% Set the volume to half for this demo
PsychPortAudio('Volume', pahandle, 0.5);

% Make a beep which we will play back to the user
myBeep = MakeBeep(1000, beepLengthSecs, freq);

% Fill the audio playback buffer with the audio data, doubled for stereo
% presentation
PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);


while ~KbCheck
    WaitSecs(0.06);   
    
    % Start audio playback
    PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
    
    fwrite(s,255);
    WaitSecs(0.5);
    
    fwrite(s,0);
    fwrite(s,0);
    
    WaitSecs(0.5);
    
    % The beep will play for one second, so we have to wait for that length of
    % time, PLUS the amount of time we want between beeps
    %WaitSecs(beepLengthSecs + beepPauseTime)
    
    % Start audio playback
    %PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);

    % Wait for the length of time of the beep is playing for
    %WaitSecs(beepLengthSecs + beepPauseTime)

end

% Stop playback
PsychPortAudio('Stop', pahandle);

% Close the audio device
PsychPortAudio('Close', pahandle);

fclose(instrfindall);
delete(instrfindall);