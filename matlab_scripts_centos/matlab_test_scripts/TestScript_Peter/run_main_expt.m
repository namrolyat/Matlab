% run the attractive bias experiment
clear all

% Reset the state of the random number generator.
RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));

global distFromScreen;
global pixelsPerCm;
global environment;
global input_device;
global b1;
global fixSize;
global background;
global pahandle;

try
    
    environment_id = input('Which environment? (work station = 1, mri = 2, dummy scanner = 3, behavioural lab 1 = 4, work station test bitsi = 5): ');
    switch environment_id
        case 1
            environment = 'workstation'
            input_device = 'keyboard'
            mri_timing = 0;
            audio_device_id = 8
            distFromScreen = 60
            pixelsPerCm = 39
        case 2
            environment = 'mri'
            input_device = 'bitsi'
            b1 = Bitsi('com6');
            b2 = Bitsi('com7');
            scannertrigger = 97;
            mri_timing = 1;
            scanner = 'trio';
            audio_device_id = 10
            distFromScreen = 80
            pixelsPerCm = 26.4
            %Scanner parameters
            TR = 1.95
            wait_time = TR*4 %TR*6
        case 3
            environment = 'dummy'
            mri_timing = 0;
            audio_device_id = 10
            distFromScreen = 68;
            pixelsPerCm = 33.7;
        case 4
            environment = 'beh1'
            mri_timing = 0;
            audio_device_id = []
            distFromScreen = 50
            pixelsPerCm = 26.3
            input_device = 'bitsi'
            b1 = Bitsi('com1');
        case 5
            environment = 'workstation'
            mri_timing = 0;
            audio_device_id = 8
            distFromScreen = 40
            pixelsPerCm = 39
            input_device = 'bitsi'
            b1 = Bitsi('com3');
    end
    
    % Perform basic initialization of the sound driver:
    InitializePsychSound;
    nrchannels = 1; % One channel only -> Mono sound.
    samplerate = 44100;
    % Open the default audio device device_id, with default mode [] (==Only playback),
    % and a required latencyclass of zero 0 == no low-latency mode, as well as
    % a frequency of freq and nrchannels sound channels.
    % This returns a handle to the audio device:
    pahandle = PsychPortAudio('Open', audio_device_id, [], 1, samplerate, nrchannels);
    
    % Ask about instructions
    instructions = input('Do you want instructions? (1: yes, 2: no, but I do want a practice block, 3: no): ');
    
    % set coherence level
    coherence = .5;
    if strcmp(environment,'mri')
        % Ask about coherence level
        coherence = input('What coherence level do you want? : ');
    end
    
    % Ask about predicted orientation
    tone_orientation = input('Tone-orientation association? (1: low-27.5, 2: low-62.5): ');
    % 1: Low tone predicts 27.5 deg movement, high tone
    % predicts 62.5 deg.
    % 2: Low tone predicts 62.5 deg movement, high tone
    % predicts 27.5 deg.
    
    background = 50;
    
    %If the subfolder 'results' does not exist, create it
    if ~exist('results','dir')
        x = mkdir(pwd,'results');
        if ~x
            disp('Couldn''t create results dir')
            background = bbb;
        end
    end
    %Also make a subfolder within 'results' for 'stimuli'.
    if ~exist('results/stimuli','dir')
        x = mkdir(pwd,'results/stimuli');
        if ~x
            disp('Couldn''t create stimuli dir')
            background = bbb;
        end
    end
    
    %Open window and do useful stuff
    [window,width,height] = openScreen();
    
    Screen('TextFont',window, 'Arial');
    Screen('TextSize',window, 20);
    Screen('FillRect', window, background);
    wrapat = 55;
    vspacing = 1.5;
    
    dotSize = 4;
    fix_colour = 255;
    fixSize_inDegrees = 0.3;
    % (make sure the size can be divided by two, so that the fixation cross
    % is symmetrical.)
    fixSize = 2*round(degrees2pixels(fixSize_inDegrees, distFromScreen, pixelsPerCm)/2);
    
    %Instructions
    if instructions == 1
        run_instructions(window, width, height);%, background,tone_orientation);
        n_blocks = 1;
        n_trials_per_block = 20;
        n_trials_total = n_blocks*n_trials_per_block;
        % turn on feedback for the subsequent (practice) trials
        feedback = 1;
    elseif instructions == 2
        % no instructions, but this is a practice block
        % 1 block for an MRI run, 1 for a behavioural session(?)
        if strcmp(environment, 'mri')
            n_blocks = 1;
        else
            n_blocks = 1;
        end
        n_trials_per_block = 20;
        n_trials_total = n_blocks*n_trials_per_block;
        % turn on feedback for the subsequent (practice) trials
        feedback = 1;
    elseif instructions == 3
        % run the experiment
        % 3 blocks for an MRI run, 12 for a behavioural session(?)
        if strcmp(environment, 'mri')
            n_blocks = 3;
        else
            n_blocks = 12;
            % for the behavioural session, make coherence an array of
            % values to choose from (pseudo)randomly.
            coherence = 0.1:0.1:0.3;
        end
        n_trials_per_block = 40; %multiple of 20; 40 or 60?
        n_trials_total = n_blocks*n_trials_per_block;
        feedback = 0;
    end
    
    % create a counterbalanced trial structure for each block. We want just as many trials of each type
    % for all blocks. Therefore, they have separate sets of trials, all counterbalanced.
    trial_structure = zeros(n_trials_per_block,3);
    trial_structure(1:2:end,1) = 1; % half of the trials get tone1 as the cue, the other half get tone2
    trial_structure([1:8:end 2:8:end],2) = 1; % each of the trials gets assigned one of the four unpredicted orientations
    trial_structure([3:8:end 4:8:end],2) = 2;
    trial_structure([5:8:end 6:8:end],2) = 3;
    trial_structure([7:8:end 8:8:end],2) = 4;
    trial_structure(1:end*3/5,2) = 0; % but for 60% this is overwritten by the predicted orientation
    trial_structure(1:end/5,3) = 1; % 20% of trials (only predicted trials) get higher coherence.
    
    %Take current time. The results will be saved with the current time
    %appended to the file name as to prevent overwriting from one subject
    %to another
    current_time = round(clock);
    text_results = sprintf('results_attract_bias_%d_%d_%d_%d_%d_%d',current_time);
    
    if strcmp(environment,'mri')
        %Wait for the first scanner pulse
        text = 'Waiting for scanner';
        DrawFormattedText(window, text, 'center', height/2-100, 255, wrapat,0,0,vspacing);
        Screen('Flip',window);
        WaitSecs(.5);
        %Wait for scanner back tick
        b2.clearResponses();
        first_scan = 0;
        while first_scan == 0
            while b2.numberOfResponses() == 0
                WaitSecs(0.001);
            end;
            [resp, time_resp] = b2.getResponse(0.001, true);
            if resp == scannertrigger
                first_scan = 1;
                time = time_resp;
                %Screen('DrawDots', window, [width/2, height/2], dotSize, 255);
                Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
                Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
                Screen('Flip',window);
            end;
        end;
        %Wait until scanner stabilizes before continuing with experiment
        time = time + wait_time;
    else
        % program a different startup screen for non-mri sessions.
        %Wait for the first scanner pulse
        text = 'Press any key to start';
        DrawFormattedText(window, text, 'center', height/2-100, 255, wrapat,0,0,vspacing);
        Screen('Flip',window);
        WaitSecs(.5);
        %Wait for button press
        buttonpress = 0;
        if strcmp(input_device,'keyboard')
            while buttonpress == 0
                [keyIsDown,secs,keyCode]=KbCheck;
                if keyIsDown
                    buttonpress = 1;
                    %Screen('DrawDots', window, [width/2, height/2], dotSize, 255);
                    Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
                    Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
                    Screen('Flip',window);
                    time = GetSecs;
                end
            end
        elseif strcmp(input_device,'bitsi')
            b1.clearResponses();
            while buttonpress == 0
                while b1.numberOfResponses() == 0
                    WaitSecs(0.001);
                end;
                [resp, time_resp] = b1.getResponse(0.001, true);
                if resp > 0
                    buttonpress = 1;
                    time = time_resp;
                    %Screen('DrawDots', window, [width/2, height/2], dotSize, 255);
                    Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
                    Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
                    Screen('Flip',window);
                end;
            end;
        end
        
        %Wait a few seconds before the experiment begins
        time = time + 2;
    end
    
    % store the time at which the experiment actually starts
    initial_time = time;
    
    %Display blocks
    for i_block = 1:n_blocks
        
        % The current sequence of trials should be a random permutation of
        % the counterbalanced trial structure
        cur_sequence = trial_structure(randperm(n_trials_per_block),:);
        
        %Present a block of trials
        data{i_block} = one_block(window, width, height, time, tone_orientation, coherence, cur_sequence, feedback, mri_timing);
        if i_block == 1
            data{i_block}.initial_time = initial_time;
        end
        
        %Save the data
        save(fullfile(pwd,'results',text_results),'data')
        
        %Update the time
        time = data{i_block}.time;
        
        % Show 'end of block' screen
        text = sprintf('End of block %d/%d',i_block,n_blocks);
        DrawFormattedText(window, text, 'center', height/2-75, 255, wrapat,0,0,vspacing);
        if strcmp(environment, 'mri')
            if i_block < n_blocks
                text = '30 second break';
                DrawFormattedText(window, text, 'center', height/2+75, 255, wrapat,0,0,vspacing);
            end
            Screen('Flip',window, time);
            time = time + 2;
            if i_block < n_blocks
                % 30 second break: empty screen for 26 seconds
                Screen('Flip', window, time);
                time = time + 26;
                % let the fixation point come back 2 seconds before the
                % next block starts.
                %Screen('DrawDots', window, [width/2, height/2], dotSize, 255);
                Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
                Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
                Screen('Flip', window, time);
                time = time + 2;
            end
        else
            text = 'press any key to continue';
            DrawFormattedText(window, text, 'center', height/2+75, 255, wrapat,0,0,vspacing);
            Screen('Flip',window, time);
            WaitSecs(.5);
            
            %Wait for button press
            buttonpress = 0;
            if strcmp(input_device,'keyboard')
                while buttonpress == 0
                    [keyIsDown,secs,keyCode]=KbCheck;
                    if keyIsDown
                        buttonpress = 1;
                        %Screen('DrawDots', window, [width/2, height/2], dotSize, 255);
                        Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
                        Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
                        Screen('Flip',window);
                        time = GetSecs;
                    end
                end
            elseif strcmp(input_device,'bitsi')
                b1.clearResponses();
                while buttonpress == 0
                    while b1.numberOfResponses() == 0
                        WaitSecs(0.001);
                    end;
                    [resp, time_resp] = b1.getResponse(0.001, true);
                    if resp > 0
                        buttonpress = 1;
                        time = time_resp;
                        %Screen('DrawDots', window, [width/2, height/2], dotSize, 255);
                        Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
                        Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
                        Screen('Flip',window);
                    end;
                end;
            end
            
            time = time + 2;
        end
    end
    
    if instructions == 1
        text = 'Please note that during the actual experiment, the percentage of randomly moving dots will vary on each trial. This might make the direction of movement hard to see, but always try to give a response, even if you feel it might be just a guess.\n\nPress any key to continue.';
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
    
    if strcmp(environment,'mri')
        %Stop the program after the next scanner pulse
        b2.clearResponses();
        last_scan = 0;
        while last_scan == 0
            while b2.numberOfResponses() == 0
                WaitSecs(0.001);
            end;
            [resp, time_resp] = b2.getResponse(0.001, true);
            if resp == scannertrigger
                last_scan = 1;
            end;
        end;
    end
    
    %Take the time when the program was stopped
    finish_time = GetSecs;
    data{1}.finish_time = finish_time;
    save(fullfile(pwd,'results',text_results), 'data')
    
    % Close the audio device:
    PsychPortAudio('Close');
    
    %End. Close all windows
    Screen('CloseAll');
    
    if strcmp(input_device,'bitsi')
        if strcmp(environment,'mri')
            b2.close();
        end
        b1.close();
        delete(instrfind);
    end
    
catch
    
    if strcmp(input_device,'bitsi')
        if strcmp(environment,'mri')
            b2.close();
        end
        b1.close();
        delete(instrfind);
    end
    
    % Close the audio device:
    PsychPortAudio('Close');
    
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end