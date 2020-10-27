%Sereval audio files may used: "beepoffical.wav" for a beep,

clear all

mode=1;%0 is trainning mode;1 is trial mode;
mode_Bitsi='';
%mode_Bitsi='com1';
LED_On=255;
LED_Off=5;
addpath('D:\PD Measurement\Seting up\sounds stage');
%[beep.y,beep.Fs] =audioread('beepoffical.wav');%import beep sound
wavfilename='beepoffical.wav';
%% Initialize Sounddriver
InitializePsychSound(1);
% How many times to we wish to play the sound
repetitions = 1;
% Should we wait for the device to really start (1 = yes)
% INFO: See help PsychPortAudio
waitForDeviceStart = 1;
%% Read WAV file from filesystem:
[y, freq] = psychwavread(wavfilename);
wavedata = y';
nrchannels = size(wavedata,1);
if nrchannels < 2
    wavedata = [wavedata ; wavedata];
    nrchannels = 2;
end
pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
% Fill the audio playback buffer with the audio data 'wavedata':
PsychPortAudio('FillBuffer', pahandle, wavedata);
b = Bitsi(mode_Bitsi); %Create a new 'bitsi' object

for i=1:1:30
    b.sendTrigger(LED_On);
    %sound(beep.y(1:beep.Fs/10),beep.Fs);%play sound 100ms
    % 0 for start immediatly
    t1 = PsychPortAudio('Start', pahandle, repetitions, 0, waitForDeviceStart);
    b.sendTrigger(LED_Off); %begin the stand still state
    pause(1)
end
pause(4)
for i=1:1:60
    t1 = PsychPortAudio('Start', pahandle, repetitions, 0, waitForDeviceStart);
    b.sendTrigger(LED_On);
    pause(2)
    t1 = PsychPortAudio('Start', pahandle, repetitions, 0, waitForDeviceStart);
    b.sendTrigger(LED_Off); %begin the stand still state
    pause(1)
end
% Stop playback:
PsychPortAudio('Stop', pahandle);

% Close the audio device:
PsychPortAudio('Close', pahandle);
b.close();

