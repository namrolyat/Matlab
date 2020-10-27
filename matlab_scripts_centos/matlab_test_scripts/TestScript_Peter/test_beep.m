%Play a sound

%What kind of beeps?
% Thut et al, JNS 2006: 50 ms auditory cue, instructing subjects to
% covertly direct their attention either to the left (100 Hz tone) or to the right (800 Hz tone)
% Den Ouden et al, CerCor 2009: 450 and 1000 Hz. But 500 ms long!

freq1 = 450;
freq2 = 1000;
freq3 = 2000;
duration = 0.05;
samplerate = 44100;

freq = freq1;

% Perform basic initialization of the sound driver:
InitializePsychSound;

nrchannels = 1; % One channel only -> Mono sound.

[wavedata, samplerate] = MakeBeep(freq, duration , samplerate);
%freq = Fs;      % Fs is the correct playback frequency for handel.
%wavedata = y';  % Need sound vector as row vector, one row per channel.

% Open the default audio device [], with default mode [] (==Only playback),
% and a required latencyclass of zero 0 == no low-latency mode, as well as
% a frequency of freq and nrchannels sound channels.
% This returns a handle to the audio device:
device_id = 0

%for a list of devices, do:
% devices = PsychPortAudio('GetDevices')

pahandle = PsychPortAudio('Open', device_id, [], 1, samplerate, nrchannels);

PsychPortAudio('RunMode', pahandle, 1);

% Fill the audio playback buffer with the audio data 'wavedata':
PsychPortAudio('FillBuffer', pahandle, wavedata);

% Start audio playback for 'repetitions' repetitions of the sound data,
% start it immediately (0) and wait for the playback to start, return onset
% timestamp.
time = GetSecs;
for i = 1:5
    time = time + 0.5;
    t1 = PsychPortAudio('Start', pahandle, 1, time, 1);
    WaitSecs(0.1);
end
% Stop playback:
PsychPortAudio('Stop', pahandle);

% Close the audio device:
PsychPortAudio('Close', pahandle);
