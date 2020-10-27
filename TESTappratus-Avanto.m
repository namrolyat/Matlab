%% Testen van pompen
clear all
delete(instrfind)

%% test sound
nrchannels = 1; % One channel only -> Mono sound.
freq = round(440*2*pi);
snd=round(rand(1))

if snd==1
rat=[.4 .5 .6 .7 .8 .9];
elseif snd~=1
rat=[.9 .8 .7 .6 .5 .4];
end

for R=1:(2*3);
	rawsound(R,:)=sin((0:(2.5*440*2*pi))*rat(R));	% high tone
end

% Perform basic initialization of the sound driver:
InitializePsychSound;

% Open the default audio device [], with default mode [] (==Only playback),
% and a required latencyclass of zero 0 == no low-latency mode, as well as
% a frequency of freq and nrchannels sound channels.
% This returns a handle to the audio device:
% Fill the audio playback buffer with the audio data 'wavedata':
for R=1:(2*3);
	soundhandle(R) = PsychPortAudio('Open', [], [], 0, freq, 1);
	PsychPortAudio('FillBuffer', soundhandle(R), rawsound(R,:));
end

sound=input('do you want to test sound?');
if sound==1
    for i =1:10
for R=[1:6]
PsychPortAudio('Start', soundhandle(R),2,0,1);
WaitSecs(2);
PsychPortAudio('Stop', soundhandle(R),2);
end
    end
end

% Set up (comport of) pump
COM         = input('COM (0 if no pump): ');
home        = pwd;
if COM ~=0;
pump.runDuration   = 2000;     % duration of delivery
pump.flowRate      = 100;      % flowrate in % of maximum
pump.tubeLength    = input('Tubelength? (10=if patient is in scanner; 1000=to run it through)');     % in cm
pump.tubeDiam      = 2.54/32;  % in cm
pump.tubeVol       = pump.tubeDiam^2*pi*pump.tubeLength; % in ml

PTrigger=1;
while PTrigger==1;
PTrigger= input('Do you want to try both pumps together? (type 0=no 1=yes)'); 
if PTrigger==1
    stepdos = setupPump(COM,pump);
end


PAppTrigger=1;
while PAppTrigger==1
PAppTrigger= input('Do you want to try the appetitive pump? (type 0=no 1=yes)');    
if PAppTrigger==1    
stepdos.runPump(1);
end
end

PAvTrigger=1;
while PAvTrigger==1
PAvTrigger= input('Do you want to try the aversive pump? (type 0=no 1=yes)');    
if PAvTrigger==1    
stepdos.runPump(2);
end
end

end

end

%% Testen van BITSI --> eyetracker
% Bitsion=input('Do you want to test Bitsi? (0=no 1=yes)');

% if Bitsion==1
% bitsi = Bitsi('/dev/tty.usbserial-A9007NHK');
% BTrigger=1;
% while BTrigger==1
% BTrigger= input('Do you want to send a trigger now? (type 0=no 1=yes)');
% if BTrigger==1
% bitsi.sendTrigger(10);
% end
% end
% end
% 
% %Testen van scannerpulse --> Matlab
% % Wait for the scanner to start, turn the screen black (just a fixation
% % cross). Then wait until the dummy scans have past.
% fmri=input('do you want to test the fMRI? (1=yes 0=no)');
% delete(instrfind);
% bitsi = Bitsi('/dev/tty.usbserial-A9007Njc')
%     while kbcheck,end %make sure all keys are released
%     
%     % present a black screen saying 'waiting to start'
%     fprintf('Waiting for the scanner to start\n')
%     dummyStart=input('How many dummies do you want to test on?');
%     Trigger='5%';
%     Triggernr=53;
%     % wait for the scanner trigger
%     fprintf('Waiting for the scanner trigger\n')
%     scanTrigger = 0;
%     while (~scanTrigger)
%         [secs, keyCode, dSecs]  = KbWait;
%         st = find(keyCode);
%         if (st == Triggernr)
%             scanTrigger = 1;
%         end
%     end
%     tScanStart = GetSecs; % ASSUMING THIS HAPPENS AT THE START OF THE FIRST VOLUME!!
% %     fprintf(['Scantrigger' num2str(scanTrigger)],'\n');
%     % wait for the dummy scans
%     while scanTrigger <=dummyStart;
%         while kbcheck,end
%         [secs, keyCode, dSecs]  = kbWait;
%        st = find(keyCode);
%         if (st == Triggernr)
%             scanTrigger = scanTrigger+1;
%             fprintf(['Scantrigger' num2str(scanTrigger)],'\n');
%         end
%     end
% end

%Testen van scannerpulse --> SCR
fprintf('druk op scannerbox om te kijken of deze op SCR compu verschijnt\n')
KbWait

%Testen van Scanner --> eyetracker
fprintf('druk op scannerbox om te kijken of deze op eyetracker compu verschijnt\n')
KbWait

%End all aparatus. 
delete(instrfind)
clear all