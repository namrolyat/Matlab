%This main code is to give instructions in the PD experiment and send codes to Bisti to add ...
%the corresponding time stamps in the EEG recordings
%Created by Ying Wang on 7th June 2017;
%Sereval audio files may used: "beep-15.wav" for a beep,
%Modified on 28th August 2017 by Ying

clear all

mode=0;%0 is trainning mode;1 is trial mode;
mode_Bitsi='';
%mode_Bitsi='com1';
still_state_begin=255;
still_state_stop=7;
done_state=127;
beep=struct('wavedata',[],'Fs',[],'nrchannels',[]);
stop=struct('wavedata',[],'Fs',[],'nrchannels',[],'state',[]);
turn=struct('name','Turn','wavedata',[],'Fs',[],'nrchannels',[],'state',[],'flag',[]);
rapid=struct('name','Rapid Turn','wavedata',[],'Fs',[],'nrchannels',[],'state',[],'flag',[]);
step=struct('name','Step','wavedata',[],'Fs',[],'nrchannels',[],'state',[],'flag',[]);
%% ----------------Initialization--------------------------------------------
turn.state=129;
step.state=157;
rapid.state=179;
stop.state=111;
addpath('D:\PD Measurement\Seting up\sounds stage\OfficalSounds');
if mode==0 %trainning mode
    time=15; %15s for each task
    N=1; %one session
else %trials
    time=120;%120s for each task
    N=1;% one seesions
end
% Initialize Sounddriver
InitializePsychSound(1);
% Setting parameters for beep
repetitions = 1;
%% Read WAV file 
% [beep.y,beep.Fs] =audioread('beep-15.wav');%import beep sound
% [step.y,step.Fs] =audioread('Normal SIP.MP4');%import step instrument
% [rapid.y,rapid.Fs] =audioread('Rapid half turn.MP4');%import rapid turn instrument
% [turn.y,turn.Fs] =audioread('Normal half turn.MP4');%import turn instrument
% [stop.y,stop.Fs] =audioread('Stop.MP4');%import stop instrument
% [y_done,Fs_done] =audioread('Einde.MP4');%import done instrument
%------------Beep------------------------------
[y, beep.Fs] = psychwavread('beepoffical.wav');
beep.wavedata = y';
nrchannels = size(beep.wavedata,1); 
if nrchannels < 2
    beep.wavedata = [beep.wavedata ; beep.wavedata];
    beep.nrchannels = 2;
end
pahandle_beep = PsychPortAudio('Open', [], [], 0, beep.Fs, beep.nrchannels);
% Fill the audio playback buffer with the audio data 'wavedata':
PsychPortAudio('FillBuffer', pahandle_beep, beep.wavedata);
%------------Stop------------------------------
[y, step.Fs] = psychwavread('Normalstepping_offical.MP4');
step.wavedata = y';
nrchannels = size(step.wavedata,1); 
if nrchannels < 2
    step.wavedata = [step.wavedata ; step.wavedata];
    step.nrchannels = 2;
end

%---------------Rapid---------------------------
[y, rapid.Fs] = psychwavread('Fasthalfturn_offical.MP4');
rapid.wavedata = y';
nrchannels = size(rapid.wavedata,1); 
if nrchannels < 2
    rapid.wavedata = [rapid.wavedata ; rapid.wavedata];
    rapid.nrchannels = 2;
end

%------------Turn-----------------------------
[y, turn.Fs] = psychwavread('Normalhalfturn_offical.MP4');
turn.wavedata = y';
nrchannels = size(turn.wavedata,1); 
if nrchannels < 2
    turn.wavedata = [turn.wavedata ; turn.wavedata];
    turn.nrchannels = 2;
end

%------------Stop------------------------------
[y, stop.Fs] = psychwavread('Stop_offical.MP4');
stop.wavedata = y';
nrchannels = size(stop.wavedata,1); 
if nrchannels < 2
    stop.wavedata = [stop.wavedata ; stop.wavedata];
    stop.nrchannels = 2;
end

%------------End------------------------------
[y, Fs_done] = psychwavread('End_offical.MP4');
wavedata_done = y';
nrchannels_done = size(wavedata_done,1); 
if nrchannels_done  < 2
    wavedata_done  = [wavedata_done; wavedata_done ];
    nrchannels_done  = 2;
end
pahandle_done = PsychPortAudio('Open', [], [], 0, Fs_done, nrchannels_done);
% Fill the audio playback buffer with the audio data 'wavedata':
PsychPortAudio('FillBuffer', pahandle_done, wavedata_done);

%[beep.y,beep.Fs] =audioread('beep-15.wav');%import beep sound
%[step.y,step.Fs] =audioread('Normal SIP.MP4');%import step instrument
%[rapid.y,rapid.Fs] =audioread('Rapid half turn.MP4');%import rapid turn instrument
%[turn.y,turn.Fs] =audioread('Normal half turn.MP4');%import turn instrument
%[stop.y,stop.Fs] =audioread('Stop.MP4');%import stop instrument
%[y_done,Fs_done] =audioread('Einde.MP4');%import done instrument


%------------Initialization: Change 7th bit to level mode------------------
b = Bitsi(mode_Bitsi); %Create a new 'bitsi' object
b.sendTrigger(0);
b.sendTrigger(2);
b.sendTrigger(128);
%-------------------Stand Still--------------------------------------------
%sound(beep.y(1:beep.Fs/10),beep.Fs);%play sound 100ms
t_beep = PsychPortAudio('Start', pahandle_beep, repetitions, 0, 1);
b.sendTrigger(still_state_begin); %begin the stand still state
count=0;
tic
while toc<10 %for 10s
      fprintf(1, repmat('\b',1,count));
      count=fprintf(1,'Stand still for %d seconds',floor(toc));
      pause(1);
end
fprintf(1,'\n');
t_beep = PsychPortAudio('Start', pahandle_beep, repetitions, 0, 1);
b.sendTrigger(still_state_stop); %end the stand still state
% sound(beep.y(1:beep.Fs/10),beep.Fs);%play sound 100ms
pause(1);
for i=1:N
    inx=randperm(3,3);%generate three numbers (from 1 to 3) in random order.
    for j=1:3
        switch inx(j) 
            case 1
                task_fun(b,turn,beep,stop,time)
            case 2
                task_fun(b,step,beep,stop,time)
            case 3
                task_fun(b,rapid,beep,stop,time)
            otherwise
                disp('random number generater is wrong!')
        end
    end
end
t_done = PsychPortAudio('Start', pahandle_done, repetitions, 0, 1);
b.sendTrigger(done_state); %end the stand still state
%sound(y_done,Fs_done);%play sound 100ms
% Stop playback
PsychPortAudio('Stop', pahandle_beep);
PsychPortAudio('Stop', pahandle_done);
% Close the audio device
PsychPortAudio('Close', pahandle_beep);
PsychPortAudio('Close', pahandle_done);
b.close();
