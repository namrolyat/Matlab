%run_localiser

clear all

global distFromScreen;
global pixelsPerCm;
global environment;
global input_device;
global b1;
global fixSize;
global background;

try
    environment_id = input('Which environment? (work station = 1, mri = 2, dummy scanner = 3, behavioural lab 1 = 4): ');
    switch environment_id
        case 1
            environment = 'workstation'
            input_device = 'keyboard'
            distFromScreen = 60
            pixelsPerCm = 39
        case 2
            environment = 'mri'
            input_device = 'bitsi'
            b1 = Bitsi('com6');
            b2 = Bitsi('com7');
            scannertrigger = 97;
            distFromScreen = 80
            pixelsPerCm = 26.5
            %Scanner parameters
            TR = 1.95
            wait_time = TR*4 %TR*6
        case 3
            environment = 'dummy'
            distFromScreen = 68;
            pixelsPerCm = 33.7;
        case 4
            environment = 'beh1'
            distFromScreen = 50
            pixelsPerCm = 26.3
            input_device = 'bitsi'
            b1 = Bitsi('com1');
    end
    
    %If the subfolder 'results' does not exist, create it
    if ~exist('results','dir')
        x = mkdir(pwd,'results');
        if ~x
            disp('Couldn''t create results dir')
            background = bbb;
        end
    end
    
    %Open window and do useful stuff
    [window,width,height] = openScreen();
    
    background = 50;
    
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
    
    %Motion directions presented during the localiser
    %0=down, pi=up, pi/2=right,3*pi/2=left
    %motion_direction = -42.5:17.5:132.5;
    motion_direction = -7.5:17.5:97.5;
    % convert to radians.
    motion_direction = (motion_direction ./ 360) * 2 * pi;
    percentCoherentMovement = 1; %1
    
    n_blocks = 12; %12
    n_trials_per_block = length(motion_direction);% + 1;
    trial_dur = 12; %12
    
    %Pseudo-randomize trial order
    for i=1:n_blocks
        sequence{i} = randperm(n_trials_per_block);
    end
    
    %Take current time. The results will be saved with the current time
    %appended to the file name as to prevent overwriting from one subject
    %to another
    current_time = round(clock);
    text_results = sprintf('results_localiser_discrete_%d_%d_%d_%d_%d_%d',current_time);
    
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
                %Screen('DrawDots', window, [width/2, height/2], fixSize, 255);
                Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
                Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
                Screen('Flip',window);
            end;
        end;
        %Wait until scanner stabilizes before continuing with experiment
        time = time + wait_time;
    else
        % program a different startup screen for non-mri sessions.
        text = 'Press any key to continue';
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
                    %Screen('DrawDots', window, [width/2, height/2], fixSize, 255);
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
                    %Screen('DrawDots', window, [width/2, height/2], fixSize, 255);
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
    for iblock = 1:n_blocks
        trial_index = 0;
        % Remove any keypresses that occured before presentation of the
        % stimuli.
        if strcmp(input_device, 'keyboard')
            FlushEvents('keyDown');
        elseif strcmp(input_device, 'bitsi')
            b1.clearResponses();
        end
        for itrial = 1:n_trials_per_block
            trial_index = trial_index + 1;
            %if sequence{iblock}(itrial) <= length(motion_direction)
                %Display moving dots
                data{iblock,trial_index} = moving_dots(window, width, height, time, trial_dur, motion_direction(sequence{iblock}(itrial)), percentCoherentMovement,1,0);
                time = data{iblock,trial_index}.time;
            %elseif sequence{iblock}(itrial) == length(motion_direction) + 1
            %    %Display static dots
            %    data{iblock,trial_index} = random_dots(window, width, height, time, trial_dur);
            %    time = data{iblock,trial_index}.time;
            %end
            
            if itrial == n_trials_per_block%ceil(n_trials_per_block/2)
                % present a fixation block
                trial_index = trial_index+1;
                data{iblock,trial_index} = fixation(window, width, height, time, trial_dur);
                time = data{iblock,trial_index}.time;
            end
        end

        if mod(iblock,4) == 0 && iblock < n_blocks
            % put in a short break
            break_dur = 30;
            %text = sprintf('END OF BLOCK %d/%d',iblock,n_blocks);
            %DrawFormattedText(window, text, 'center', height/2-100, 255, wrapat,0,0,vspacing);
            text = sprintf('%d SECOND BREAK',break_dur);
            DrawFormattedText(window, text, 'center', height/2-100, 255, wrapat,0,0,vspacing);
            Screen('Flip',window,time);
            time = time + 2;
            % 30 second break: empty screen for 26 seconds
            Screen('Flip', window, time);
            time = time + break_dur-4;
            %Screen('DrawDots', window, [width/2, height/2], fixSize, 255);
            Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
            Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
            Screen('Flip',window,time);
            time = time + 2;
        end
        %Save the data
        save(fullfile(pwd,'results',text_results),'data')
    end
    
    % Clear the screen
    Screen('Flip', window);
    
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
    
    %End. Get end time, save results and close all windows
    finish_time = GetSecs;
    data{1,1}.finish_time = finish_time;
    data{1,1}.initial_time = initial_time;
    save(fullfile(pwd,'results',text_results),'data')
    
    Screen('CloseAll');
    
    if strcmp(input_device,'bitsi')
        if strcmp(environment,'mri')
            b2.close();
        end
        b1.close();
        delete(instrfind);
    end
    
catch
    Screen('CloseAll');
    
    if strcmp(input_device,'bitsi')
        if strcmp(environment,'mri')
            b2.close();
        end
        b1.close();
        delete(instrfind);
    end
    
    psychrethrow(psychlasterror);
end