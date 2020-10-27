function run_instructions(window, width, height)%, background, tone_orientation)

global distFromScreen;
global pixelsPerCm;
%global environment;
global input_device;
global b1;

global pahandle;
PsychPortAudio('RunMode', pahandle, 1);

%Define the keys
if strcmp(input_device, 'keyboard')
    key_1 = KbName('1!');
    key_2 = KbName('2@');
    key_3 = KbName('3#');
    escape = KbName('escape');
elseif strcmp(input_device, 'bitsi')
    key_1 = 97;
    key_2 = 98;
    key_3 = 99;
    escape = 102;
end

wrapat = 55;
vspacing = 1.5;

dotSize = 4; % size of the fixation dot

% attributes of the auditory cue tone
tone_freq1 = 450;
tone_freq2 = 1000;
tone_duration = 0.2;
samplerate = 44100;

% attributes of response display
response_line_length_inDegrees = 1;
response_line_length = degrees2pixels(response_line_length_inDegrees, distFromScreen, pixelsPerCm);
response_line_width = 3;

%What the stimuli are like
text = 'Thank you for participating in our study!\n\nIn each trial of the experiment, you will see a field of moving dots.\n\nPress any key to see what the moving dots will look like.';
DrawFormattedText(window, text, width/2 - 300, 'center', 255, wrapat,0,0,vspacing);
Screen('Flip',window);
WaitSecs(1);
if strcmp(input_device,'keyboard')
    KbWait;
elseif strcmp(input_device,'bitsi')
    b1.clearResponses();
    while b1.numberOfResponses() == 0
        WaitSecs(0.001);
    end;
end

%Show moving dots
trial_dur = 5;
cur_direction = 0;
percentCoherentMovement = .9;
time = GetSecs;
moving_dots(window, width, height, time, trial_dur, cur_direction, percentCoherentMovement, 0, 0);

%Remind them to fixate
text = 'Please note that during the experiment, it is important that you keep your eyes fixed on the fixation cross in the center of the screen.\n\nPlease do not move your gaze to the moving dots.';
DrawFormattedText(window, text, width/2 - 300, 'center', 255, wrapat,0,0,vspacing);
Screen('Flip',window);
WaitSecs(0.5);
if strcmp(input_device,'keyboard')
    KbWait;
elseif strcmp(input_device,'bitsi')
    b1.clearResponses();
    while b1.numberOfResponses() == 0
        WaitSecs(0.001);
    end;
end

%What the trials are like
text = 'In each trial, a proportion of the dots will move in a certain direction, while the rest of the dots move randomly. Your task will be to report the main direction of movement present in the field of moving dots.\n\nIn the example you just saw, the direction of movement was upward. Press any key to see some more examples.';
DrawFormattedText(window, text, width/2 - 300, 'center', 255, wrapat,0,0,vspacing);
Screen('Flip',window);
WaitSecs(1);
if strcmp(input_device,'keyboard')
    KbWait;
elseif strcmp(input_device,'bitsi')
    b1.clearResponses();
    while b1.numberOfResponses() == 0
        WaitSecs(0.001);
    end;
end

%Show moving dots
trial_dur = 5;
cur_direction = pi/8;
percentCoherentMovement = .9;
time = GetSecs;
moving_dots(window, width, height, time, trial_dur, cur_direction, percentCoherentMovement, 0, 0);
Screen('Flip',window);

cur_direction = 3*pi/8;
time = GetSecs+2;
moving_dots(window, width, height, time, trial_dur, cur_direction, percentCoherentMovement, 0, 0);
Screen('Flip',window);
WaitSecs(1);

%Which directions will be present
text = 'The main direction of the dots will always be up and to the right. That is, the movement can be upward (12 o''clock), rightward (3 o''clock), or anywhere in between. In other words, the main direction of the dots will never be down or left.\n\nPress any key to continue.';
DrawFormattedText(window, text, width/2 - 300, 'center', 255, wrapat,0,0,vspacing);
Screen('Flip',window);
WaitSecs(1);
if strcmp(input_device,'keyboard')
    KbWait;
elseif strcmp(input_device,'bitsi')
    b1.clearResponses();
    while b1.numberOfResponses() == 0
        WaitSecs(0.001);
    end;
end

%What the trials are like
text = 'After the dots disappear, you will be asked to report the direction of movement of the dots. You can do this by positioning a red line such that it points in the direction you observed.\n\n\n\n\n\n\nThe example presented here illustrates a response indicating that the direction of movement was upward and to the right. Press any key to practice the response procedure.';
DrawFormattedText(window, text, width/2 - 300, 'center', 255, wrapat,0,0,vspacing);
answer = pi/4;
% Draw the response display
toH = width/2 + sin(answer)*response_line_length;
toV = height/2 - cos(answer)*response_line_length; % minus cos since y is defined top to bottom.
Screen('DrawLine', window, [255 0 0], width/2, height/2, toH, toV, response_line_width);
Screen('FrameOval', window, 0, [width/2-response_line_length,height/2-response_line_length,...
    width/2+response_line_length,height/2+response_line_length], response_line_width);
Screen('Flip',window);
WaitSecs(1);
if strcmp(input_device,'keyboard')
    KbWait;
elseif strcmp(input_device,'bitsi')
    b1.clearResponses();
    while b1.numberOfResponses() == 0
        WaitSecs(0.001);
    end;
end

%Show a response collection display, to play around with.
text = 'button 1: rotate anti-clockwise.\nbutton 2: rotate clockwise\nbutton 3: stop response practice.';
answer = rand*pi - pi/4; % initialise the answer at a random value between -45 and 135.
key_pressed = 0; % used for bitsi responses only.
%Collect responses until stopped by the user.
stop_response = 0;
while stop_response == 0
    
    % Draw the response display
    toH = width/2 + sin(answer)*response_line_length;
    toV = height/2 - cos(answer)*response_line_length; % minus cos since y is defined top to bottom.
    Screen('DrawLine', window, [255 0 0], width/2, height/2, toH, toV, response_line_width);
    Screen('FrameOval', window, 0, [width/2-response_line_length,height/2-response_line_length,...
        width/2+response_line_length,height/2+response_line_length], response_line_width);
    DrawFormattedText(window, text, width/2 - 300, height/2 + 100, 255, wrapat,0,0,vspacing);
    Screen('Flip', window, time);
    
    % Check for responses
    if strcmp(input_device, 'bitsi')
        if b1.numberOfResponses > 0
            [resp resp_time] = b1.getResponse(0.001, true);
            if resp == key_1
                key_pressed = 1;
                key_time = resp_time;
                no_response_given = 0;
            elseif resp == key_2
                key_pressed = 2;
                key_time = resp_time;
                no_response_given = 0;
            elseif resp == key_3
                stop_response = 1;
            elseif resp == escape
                answer = bbb; % forcefully break out
            else
                key_pressed = 0;
            end
        end
        
        if key_pressed == 1
            answer = answer - 0.1*(GetSecs-key_time);
        elseif key_pressed == 2
            answer = answer + 0.1*(GetSecs-key_time);
        end
    elseif strcmp(input_device, 'keyboard')
        [keyIsDown,resp_time,keyCode]=KbCheck;
        if keyIsDown
            if keyCode(key_1)
                answer = answer - 0.05;
                no_response_given = 0;
            elseif keyCode(key_2)
                answer = answer + 0.05;
                no_response_given = 0;
            elseif keyCode(key_3)
                stop_response = 1;
            elseif keyCode(escape)
                answer = bbb; % forcefully break out
            end
        end
    end
end

%What the trials are like
text = 'In the actual experiment, the moving dots will be presented for 1 second, and you will have 3 seconds to respond. \n\nEach trial will start with a short tone, indicating that the moving dots will appear within one second. There are two different tones, a high and a low tone, one of which will be presented at the start of each trial. The pitch of the tone is not relevant for your task. Press a key to hear the tones.';
DrawFormattedText(window, text, width/2 - 300, 'center', 255, wrapat,0,0,vspacing);
Screen('Flip',window);
WaitSecs(1);
if strcmp(input_device,'keyboard')
    KbWait;
elseif strcmp(input_device,'bitsi')
    b1.clearResponses();
    while b1.numberOfResponses() == 0
        WaitSecs(0.001);
    end;
end

%Present the beeps.
[wavedata, samplerate] = MakeBeep(tone_freq1, tone_duration, samplerate);
PsychPortAudio('FillBuffer', pahandle, wavedata);
PsychPortAudio('Start', pahandle, 1, 0, 1);
WaitSecs(1);
[wavedata, samplerate] = MakeBeep(tone_freq2, tone_duration, samplerate);
PsychPortAudio('FillBuffer', pahandle, wavedata);
PsychPortAudio('Start', pahandle, 1, 0, 1);
WaitSecs(1);

%What the trials are like
text = 'You are now ready to do some practice trials. If you have any questions about the experiment, you can ask the experimenter about them now.\n\nDuring the practice, you will get feedback on your response after each trial. During the actual experiment, there will be no feedback.\n\nPress any key to start the practice trials.';
DrawFormattedText(window, text, width/2 - 300, 'center', 255, wrapat,0,0,vspacing);
Screen('Flip',window);
WaitSecs(1);
if strcmp(input_device,'keyboard')
    KbWait;
elseif strcmp(input_device,'bitsi')
    b1.clearResponses();
    while b1.numberOfResponses() == 0
        WaitSecs(0.001);
    end;
end

%What the trials are like
text = 'Please remember to keep your eyes fixed on the fixation cross in the center of the screen, and not move your gaze to the moving dots.\n\nPress any key to continue.';
DrawFormattedText(window, text, width/2 - 300, 'center', 255, wrapat,0,0,vspacing);
Screen('Flip',window);
WaitSecs(1);
if strcmp(input_device,'keyboard')
    KbWait;
elseif strcmp(input_device,'bitsi')
    b1.clearResponses();
    while b1.numberOfResponses() == 0
        WaitSecs(0.001);
    end;
end

end
