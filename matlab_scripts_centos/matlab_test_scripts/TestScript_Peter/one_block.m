function presentation = one_block(window, width, height, time, tone_orientation, coherence, cur_sequence, feedback, mri_timing)

global distFromScreen;
global pixelsPerCm;
global input_device;
global b1;
global fixSize;
%global background;

global pahandle;
PsychPortAudio('RunMode', pahandle, 1);

%Define the keys
if strcmp(input_device, 'keyboard')
    key_1 = KbName('1!');
    key_2 = KbName('2@');
    escape = KbName('escape');
elseif strcmp(input_device, 'bitsi')
    key_1 = 97;
    key_2 = 98;
    escape = 102;
end
    
% attributes of the auditory cue tone
tone_freq1 = 450;
tone_freq2 = 1000;
tone_duration = 0.2;
samplerate = 44100;

cue_stim_soa = 0.75; % time between cue and stimulus

% attributes of the moving dots
%percentCoherentMovement = .7;
% if coherence is varied randomly over trials, draw from this range:
%coherence_range = 0.1:0.1:0.5;
trial_dur = 1;
%Motion directions presented
%0=down, pi=up, pi/2=right,3*pi/2=left
motion_direction_range = 10:17.5:80;
% convert to radians.
motion_direction_range = (motion_direction_range ./ 360) * 2 * pi;

% save the dot positions, for later motion energy analysis?
save_stim = 1;

% attributes of response display
response_line_length_inDegrees = 1;
response_line_length = degrees2pixels(response_line_length_inDegrees, distFromScreen, pixelsPerCm);
response_line_width = 3;

fix_colour = 255;

number_trials = size(cur_sequence,1);
shuffled_trial_nrs = randperm(number_trials);

%Start the sequence of trials
for i=1:number_trials
   
    % if coherence is an array, pseudo-randomly choose a value from it.
    if sum(size(coherence)) > 2
        coherence_index = ceil(shuffled_trial_nrs(i)/(number_trials/length(coherence)));
        percentCoherentMovement = coherence(coherence_index);
        if cur_sequence(i,3)
            % trial gets high coherence
            percentCoherentMovement = .5;
        end
    elseif sum(size(coherence)) == 2 %coherence is just a single number
        percentCoherentMovement = coherence;
        if cur_sequence(i,3)
            % trial gets higher coherence
            percentCoherentMovement = 2*coherence;
        end
    end
    
    % which tone?
    if cur_sequence(i,1) == 0;
        tone = 1;
        tone_freq = tone_freq1;
    elseif cur_sequence(i,1) == 1;
        tone = 2;
        tone_freq = tone_freq2;
    end
    
        % which orientation?
    if (tone_orientation == 1 && tone == 1) || (tone_orientation == 2 && tone == 2)
        % low tone predicts 27.5 deg and the cue was a low
        % tone, or high tone predicts 27.5 deg and the cue
        % was a high tone.
        pred_direction_cat = 2; % direction categorically represented (1-5)
        pred_direction = motion_direction_range(pred_direction_cat);
        unpred_direction_cat = [1 3 4 5];
        unpred_direction = motion_direction_range(unpred_direction_cat);
    elseif (tone_orientation == 1 && tone == 2) || (tone_orientation == 2 && tone == 1)
        % low tone predicts 27.5 deg and the cue was a high
        % tone, or high tone predicts 27.5 deg and the cue
        % was a low tone.
        pred_direction_cat = 4; % direction categorically represented (1-5)
        pred_direction = motion_direction_range(pred_direction_cat);
        unpred_direction_cat = [1 2 3 5];
        unpred_direction = motion_direction_range(unpred_direction_cat);
    else
        % all options should have been covered above, something has
        % gone wrong.
        pred_direction = bbb; %forcefully break out
    end
    if cur_sequence(i,2) == 0
        % the direction prediction will come true
        cur_direction_cat = pred_direction_cat;
        cur_direction = pred_direction;
    else
        % the orientation prediction will not come true.
        cur_direction_cat = unpred_direction_cat(cur_sequence(i,2));
        cur_direction = unpred_direction(cur_sequence(i,2));
    end
    
    %Present the auditory cue.
    [wavedata, samplerate] = MakeBeep(tone_freq, tone_duration, samplerate);
    % Fill the audio playback buffer with the audio data 'wavedata':
    PsychPortAudio('FillBuffer', pahandle, wavedata);
    % Start audio playback at time 'time', return onset timestamp.
    cue_time = PsychPortAudio('Start', pahandle, 1, time, 1);
    time = time + cue_stim_soa; % Present the stimulus after the cue
    
    %Present the moving dots
    moving_dots_data = moving_dots(window, width, height, time, trial_dur, cur_direction, percentCoherentMovement, 0, save_stim);
    time = moving_dots_data.time;
    
    %Remove the stimulus and display the fixation square again.
    %Screen('DrawDots', window, [width/2, height/2], dotSize, fix_colour);
    Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
    Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
    moving_dots_offset_time = Screen('Flip', window, time);
    
    %Interval between stimulus and response
    if mri_timing
        time = time + 1 + rand;
    else
        %Adjust timing for psychophysical session or training
        time = time + 0.5;
    end
    response_display_time(1) = time;
    
    % Remove any keypresses that occured before presentation of the
    % response screen.
    if strcmp(input_device, 'keyboard')
        FlushEvents('keyDown');
    elseif strcmp(input_device, 'bitsi')
        b1.clearResponses();
    end
    
    %Program the response collection here
    %answer = rand*2*pi;
    answer = rand*pi - pi/4; % initialise the answer at a random value between -45 and 135.
    key_pressed = 0; % used for bitsi responses only.
    no_response_given = 1;
    %Collect responses until within one frame of time + 3s.
    while GetSecs < time + 3 - 0.010
        
        % Draw the response display
        toH = width/2 + sin(answer)*response_line_length;
        toV = height/2 - cos(answer)*response_line_length; % minus cos since y is defined top to bottom.
        Screen('DrawLine', window, [255 0 0], width/2, height/2, toH, toV, response_line_width);
        Screen('FrameOval', window, 0, [width/2-response_line_length,height/2-response_line_length,...
            width/2+response_line_length,height/2+response_line_length], response_line_width);
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
                elseif keyCode(escape)
                    answer = bbb; % forcefully break out
                end
            end
        end
        
    end
    
    %Remove the response display and show the fixation square again.
    if ~feedback
    %Screen('DrawDots', window, [width/2, height/2], dotSize, fix_colour);
    Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
    Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
    response_display_time(2) = Screen('Flip', window);
    time = response_display_time(2);
    end
    
    answer = mod(answer,2*pi); % map the answer onto the 0-2pi range.
    error = answer - cur_direction;
    if error > pi
        error = error-2*pi; % map the error onto the 0-pi range; the error can never be larger than half a cycle.
    end

    %Give feedback
    if feedback == 1
        text = sprintf('correct answer');
        DrawFormattedText(window, text, width/2+50, height/2-120, fix_colour);
        % Draw the correct answer
        toH = width/2 + sin(cur_direction)*response_line_length;
        toV = height/2 - cos(cur_direction)*response_line_length; % minus cos since y is defined top to bottom.
        Screen('DrawLine', window, [255 0 0], width/2, height/2-100, toH, toV-100, response_line_width);
        Screen('FrameOval', window, 0, [width/2-response_line_length,height/2-response_line_length-100,...
            width/2+response_line_length,height/2+response_line_length-100], response_line_width);
        text = sprintf('answer given');
        DrawFormattedText(window, text, width/2+50, 'center', fix_colour);
        % Draw the answer given
        toH = width/2 + sin(answer)*response_line_length;
        toV = height/2 - cos(answer)*response_line_length; % minus cos since y is defined top to bottom.
        Screen('DrawLine', window, [255 0 0], width/2, height/2, toH, toV, response_line_width);
        Screen('FrameOval', window, 0, [width/2-response_line_length,height/2-response_line_length,...
            width/2+response_line_length,height/2+response_line_length], response_line_width);
        text = sprintf('offset: %d degrees',round(error .* 360/(2*pi)));
        DrawFormattedText(window, text, 'center', height/2+100, fix_colour);
        Screen('Flip',window,time);

        %remove feedback after 4 seconds
        %Screen('DrawDots', window, [width/2, height/2], dotSize, fix_colour);
        Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
        Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
        Screen('Flip', window, time + 4);
        
        time = GetSecs;
    end

    %Update time
    if mri_timing
        % this is the time between the offset of the response display and the onset
        % of the next stimulus.
        time = time + 2 + 3*rand - cue_stim_soa;
    else
        %Adjust timing for psychophysical session or training
        time = time + 1.5;
    end

    %Save data
    presentation.tone(i) = tone;
    presentation.tone_freq(i) = tone_freq;
    presentation.pred_direction(i) = pred_direction;
    presentation.pred_direction_cat(i) = pred_direction_cat;
    presentation.motion_direction(i) = cur_direction;
    presentation.motion_direction_cat(i) = cur_direction_cat;
    presentation.percentCoherentMovement(i) = percentCoherentMovement;
    presentation.motion_presentation_times{i} = moving_dots_data.presentation_time;
    presentation.answer(i) = answer;
    presentation.error(i) = error;
    presentation.no_response_given(i) = no_response_given;
    presentation.cue_time(i) = cue_time;
    presentation.moving_dots_offset_time(i) = moving_dots_offset_time;
    presentation.response_display_time{i} = response_display_time;
    
    if save_stim
        %Take current time. The stimulus will be saved with the current time
        %appended to the file name as to prevent overwriting from one subject
        %to another. This file name will also be stored in the 'presentation'
        %variable, so we can identify the stimulus files later on.
        current_time = round(clock);
        stim_filename = sprintf('moving dots_%d_%d_%d_%d_%d_%d',current_time);
        presentation.stim_filename{i} = stim_filename;
        save(fullfile(pwd,'results','stimuli',stim_filename), 'moving_dots_data')
    end
end

presentation.number_trials = number_trials;
presentation.cur_sequence = cur_sequence;
presentation.motion_direction_range = motion_direction_range;
if sum(size(coherence)) > 2
    presentation.coherence_range = coherence;
end
presentation.tone_orientation = tone_orientation;
presentation.cue_stim_soa = cue_stim_soa;
presentation.feedback = feedback;
presentation.time = time;

Screen('Close');