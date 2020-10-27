%run_retinotopy_wedge
%
%A simple code that does retinotopic mapping. It calls the function
%wedge_one_location.m to actually present the stimuli. The current
%parameters are: 90 degree wedge, which does 9 rotations in both CW and CCW
%direction, extra half a cycle in the beginning of each type of motion.
%Colours are black and white but this can be changed easily too. My TR is 1.95
%sec and I've chosen 12 positions for the wedge (1 per TR) which
%gives me 23.4 sec per cycle.
%Currently the code takes 2*9.5*12*1.95 + 12*1.95 = 468 sec = 7:48 min = 240 scans (for
%TR of 1.95)
%
% with the current settings, scans 7-114 and 133-240 are the ones of
% interest.

clear all

global distFromScreen;
global pixelsPerCm;
global fixSize;

try
    environment_id = input('Which environment? (work station = 1, mri = 2, dummy scanner = 3, behavioural lab 1 = 4): ');
    switch environment_id
        case 1
            environment = 'workstation'
            input_device = 'keyboard'
            distFromScreen = 40
            pixelsPerCm = 39
        case 2
            environment = 'mri'
            input_device = 'bitsi'
            b1 = Bitsi('com6');
            b2 = Bitsi('com7');
            scannertrigger = 97;
            distFromScreen = 80
            pixelsPerCm = 26.4
            %Scanner parameters
            TR = 1.95
            %wait_time = TR*4 %TR*6
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
    
    %Open window and do useful stuff
    [window,width,height] = openScreen();
    
    background = 50;
    
    Screen('TextFont',window, 'Arial');
    Screen('TextSize',window, 20);
    Screen('FillRect', window, background);
    wrapat = 55;
    vspacing = 1.5;
    
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
    
    %Parameters
    TR = 1.95;
    number_rotations = 9; %9
    number_positions = 12;
    number_flickers_per_position = 12; %for a 3Hz flicker: 18/2 = 9 cycles per 3s wedge.
    time_per_position = TR;
    time_per_one_wedge = time_per_position/number_flickers_per_position;
    starting_angle = 0;
    parity = 1;
    response_count = 0;
    response_time = [];
    
    dotSize = 4;
    fix_colour = 255;
    fixSize_inDegrees = 0.3;
    % (make sure the size can be divided by four, so that the fixation cross
    % is symmetrical.)
    fixSize = 4*round(degrees2pixels(fixSize_inDegrees, distFromScreen, pixelsPerCm)/4);
    
    %Take current time
    current_time = round(clock);
    text_results = sprintf('results_wedge_%d_%d_%d_%d_%d_%d',current_time);
    
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
        %time = time + wait_time; % don't wait, the first half-cycle of the
        %wedge is discarded anyway.
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
        %time = time + 2;
    end
    
    % store the time at which the experiment actually starts
    initial_time = time;
    
    
    %% Clockwise motion
    
    %Do a half-rotation in the begining
    % How many times will the fixation point change colour during this
    % half-rotation? 2-4 times.
    n_changes = 2 + round(2*rand);
    % When will these changes occur?
    change_times{1} = randperm(number_positions*number_flickers_per_position);
    change_times{1} = change_times{1}(change_times{1} > (number_positions/2 + 1)*number_flickers_per_position);
    change_times{1} = sort(change_times{1}(1:n_changes));
    task_pres = change_times{1};
    change_pres_times{1} = [];
    
    % Remove any keypresses that occured before presentation of the
    % stimuli.
    if strcmp(input_device, 'keyboard')
        FlushEvents('keyDown');
    elseif strcmp(input_device, 'bitsi')
        b1.clearResponses();
    end
    for j=number_positions/2+1:number_positions
        starting_angle = (j-1)*360/number_positions;
        for k=1:number_flickers_per_position %flash many times at each location
            % Check if the fixation dot should change colour
            if find(task_pres == (k + (j-1)*number_flickers_per_position))
                change_fix = 1;
            else
                change_fix = 0;
            end
            parity = 3 - parity;
            times{1}(j,k) = wedge_one_location(window, width, height, background, starting_angle, parity, time, change_fix);
            if change_fix
                change_pres_times{1} = [change_pres_times{1}, times{1}(j,k)];
            end
            time = time + time_per_one_wedge;
            
            % Check for inputs
            if strcmp(input_device, 'bitsi')
                while GetSecs < time - 0.030
                    timeout = time - GetSecs - 0.030;
                    [resp resp_time] = b1.getResponse(timeout, true);
                    if resp == key_1
                        response_count = response_count + 1;
                        response_time(response_count) = resp_time;
                    elseif resp == escape
                        response_count = bbb; % forcefully break out
                    end
                end
            elseif strcmp(input_device, 'keyboard')
                while GetSecs < time - 0.030
                    [keyIsDown,resp_time,keyCode]=KbCheck;
                    if keyIsDown
                        if keyCode(key_1)
                            response_count = response_count + 1;
                            response_time(response_count) = resp_time;
                            break;
                        elseif keyCode(escape)
                            response_count = bbb; % forcefully break out
                        end
                    end
                end
            end
            
        end
    end
    
    %Start the rotation
    for i=1:number_rotations
        
        % How many times will the fixation point change colour during this
        % rotation? 4-8 times.
        n_changes = 4 + round(4*rand);
        % When will these changes occur?
        change_times{i+1} = randperm(number_positions*number_flickers_per_position);
        change_times{i+1} = sort(change_times{i+1}(1:n_changes));
        task_pres = change_times{i+1};
        change_pres_times{i+1} = [];
    
%         % When will these changes occur?
%         change_times{i+1} = randperm(number_positions*time_per_position);
%         change_times{i+1} = sort(change_times{i+1}(1:n_changes));
%         % change_times is in seconds, to which wedge presentations do these
%         % correspond? Each rotation takes
%         % number_positions*time_per_position in seconds, and
%         % number_positions*number_flickers_per_position in wedge
%         % presentations
%         task_pres = (change_times{i+1}/time_per_position)*number_flickers_per_position;
%         % adjust change_times.
%         change_times{i+1} = change_times{i+1} + (number_positions/2)*time_per_position + (i-1)*number_positions*time_per_position;
        
        for j=1:number_positions
            starting_angle = (j-1)*360/number_positions;
            for k=1:number_flickers_per_position %flash many times at each location
                % Check if the fixation dot should change colour
                if find(task_pres == (k + (j-1)*number_flickers_per_position))
                    change_fix = 1;
                else
                    change_fix = 0;
                end
                parity = 3 - parity;
                times{2}(i,j,k) = wedge_one_location(window, width, height, background, starting_angle, parity, time, change_fix);
                if change_fix
                    change_pres_times{i+1} = [change_pres_times{i+1}, times{2}(i,j,k)];
                end
                time = time + time_per_one_wedge;
                
                % Check for inputs
                if strcmp(input_device, 'bitsi')
                    while GetSecs < time - 0.030
                        timeout = time - GetSecs - 0.030;
                        [resp resp_time] = b1.getResponse(timeout, true);
                        if resp == key_1
                            response_count = response_count + 1;
                            response_time(response_count) = resp_time;
                        elseif resp == escape
                            response_count = bbb; % forcefully break out
                        end
                    end
                elseif strcmp(input_device, 'keyboard')
                    while GetSecs < time - 0.030
                        [keyIsDown,resp_time,keyCode]=KbCheck;
                        if keyIsDown
                            if keyCode(key_1)
                                response_count = response_count + 1;
                                response_time(response_count) = resp_time;
                                break;
                            elseif keyCode(escape)
                                response_count = bbb; % forcefully break out
                            end
                        end
                    end
                end
            end
        end
    end
    
    %empty screen between the two types of motion
    %Screen('DrawDots', window, [width/2, height/2], dotSize, 255);
    Screen('Flip',window);
    
    %Wait for 12 TRs
    break_time = TR*12;
    time = time + break_time;
    
    %% Counter-clockwise motion
    
    %Do a half-rotation in the begining
    % How many times will the fixation point change colour during this
    % half-rotation? 2-4 times.
    n_changes = 2 + round(2*rand);
    % When will these changes occur?
    change_times{number_rotations+2} = randperm(number_positions*number_flickers_per_position);
    change_times{number_rotations+2} = change_times{number_rotations+2}(change_times{number_rotations+2} > (number_positions/2 + 1)*number_flickers_per_position);
    change_times{number_rotations+2} = sort(change_times{number_rotations+2}(1:n_changes));
    task_pres = change_times{number_rotations+2};
    change_pres_times{number_rotations+2} = [];
    
%     %Do a half-rotation in the begining
%     % How many times will the fixation point change colour during this
%     % half-rotation? 2-4 times.
%     n_changes = 2 + round(2*rand);
%     % When will these changes occur?
%     change_times{number_rotations+2} = randperm(number_positions*time_per_position);
%     change_times{number_rotations+2} = change_times{number_rotations+2}(change_times{number_rotations+2} > (number_positions/2 + 1)*time_per_position);
%     change_times{number_rotations+2} = sort(change_times{number_rotations+2}(1:n_changes));
%     % change_times is in seconds, to which wedge presentations do these
%     % correspond? Each rotation takes
%     % number_positions*time_per_position in seconds, and
%     % number_positions*number_flickers_per_position in wedge
%     % presentations
%     task_pres = (change_times{number_rotations+2}/time_per_position)*number_flickers_per_position;
%     % adjust change_times; subtract half a cycle because we only do a
%     % half-rotation here.
%     change_times{number_rotations+2} = change_times{number_rotations+2} + number_rotations*number_positions*time_per_position + break_time;
    
    % Remove any keypresses that occured before presentation of the
    % stimuli.
    if strcmp(input_device, 'keyboard')
        FlushEvents('keyDown');
    elseif strcmp(input_device, 'bitsi')
        b1.clearResponses();
    end
    for j=number_positions/2+1:number_positions
        starting_angle = (number_positions+1-j)*360/number_positions;
        
        for k=1:number_flickers_per_position %flash many times at each location
            % Check if the fixation dot should change colour
            if find(task_pres == (k + (j-1)*number_flickers_per_position))
                change_fix = 1;
            else
                change_fix = 0;
            end
            parity = 3 - parity;
            times{3}(j,k) = wedge_one_location(window, width, height, background, starting_angle, parity, time, change_fix);
            if change_fix
                change_pres_times{number_rotations+2} = [change_pres_times{number_rotations+2}, times{3}(j,k)];
            end
            time = time + time_per_one_wedge;
            
            % Check for inputs
            if strcmp(input_device, 'bitsi')
                while GetSecs < time - 0.030
                    timeout = time - GetSecs - 0.030;
                    [resp resp_time] = b1.getResponse(timeout, true);
                    if resp == key_1
                        response_count = response_count + 1;
                        response_time(response_count) = resp_time;
                    elseif resp == escape
                        response_count = bbb; % forcefully break out
                    end
                end
            elseif strcmp(input_device, 'keyboard')
                while GetSecs < time - 0.030
                    [keyIsDown,resp_time,keyCode]=KbCheck;
                    if keyIsDown
                        if keyCode(key_1)
                            response_count = response_count + 1;
                            response_time(response_count) = resp_time;
                            break;
                        elseif keyCode(escape)
                            response_count = bbb; % forcefully break out
                        end
                    end
                end
            end
        end
    end
    
    %Start the rotation
    for i=1:number_rotations
        
        % How many times will the fixation point change colour during this
        % rotation? 4-8 times.
        n_changes = 4 + round(4*rand);
        % When will these changes occur?
        change_times{i+number_rotations+2} = randperm(number_positions*number_flickers_per_position);
        change_times{i+number_rotations+2} = sort(change_times{i+number_rotations+2}(1:n_changes));
        task_pres = change_times{i+number_rotations+2};
        change_pres_times{i+number_rotations+2} = [];
        
%         % How many times will the fixation point change colour during this
%         % rotation? 4-8 times.
%         n_changes = 4 + round(4*rand);
%         % When will these changes occur?
%         change_times{i+number_rotations+2} = randperm(number_positions*time_per_position);
%         change_times{i+number_rotations+2} = sort(change_times{i+number_rotations+2}(1:n_changes));
%         % change_times is in seconds, to which wedge presentations do these
%         % correspond? Each rotation takes
%         % number_positions*time_per_position in seconds, and
%         % number_positions*number_flickers_per_position in wedge
%         % presentations
%         task_pres = (change_times{i+number_rotations+2}/time_per_position)*number_flickers_per_position;
%         % adjust change_times; I've already had
%         % (number_rotations + 1 + (i-1)) rotations and a short break
%         change_times{i+number_rotations+2} = change_times{i+number_rotations+2} + (number_rotations+i)*number_positions*time_per_position + break_time;
        
        for j=1:number_positions
            starting_angle = (number_positions+1-j)*360/number_positions;
            
            for k=1:number_flickers_per_position %flash many times at each location
                % Check if the fixation dot should change colour
                if find(task_pres == (k + (j-1)*number_flickers_per_position))
                    change_fix = 1;
                else
                    change_fix = 0;
                end
                parity = 3 - parity;
                times{4}(i,j,k) = wedge_one_location(window, width, height, background, starting_angle, parity, time, change_fix);
                if change_fix
                    change_pres_times{i+number_rotations+2} = [change_pres_times{i+number_rotations+2}, times{4}(i,j,k)];
                end
                time = time + time_per_one_wedge;
                
                % Check for inputs
                if strcmp(input_device, 'bitsi')
                    while GetSecs < time - 0.030
                        timeout = time - GetSecs - 0.030;
                        [resp resp_time] = b1.getResponse(timeout, true);
                        if resp == key_1
                            response_count = response_count + 1;
                            response_time(response_count) = resp_time;
                        elseif resp == escape
                            response_count = bbb; % forcefully break out
                        end
                    end
                elseif strcmp(input_device, 'keyboard')
                    while GetSecs < time - 0.030
                        [keyIsDown,resp_time,keyCode]=KbCheck;
                        if keyIsDown
                            if keyCode(key_1)
                                response_count = response_count + 1;
                                response_time(response_count) = resp_time;
                                break;
                            elseif keyCode(escape)
                                response_count = bbb; % forcefully break out
                            end
                        end
                    end
                end
            end
        end
    end
    
    finish_time = GetSecs;
    
    save(fullfile(pwd,'results',text_results), 'initial_time', 'finish_time', 'times', 'change_times', 'change_pres_times', 'response_count', 'response_time');
    
    if strcmp(input_device,'bitsi')
        if strcmp(environment,'mri')
            b2.close();
        end
        b1.close();
        delete(instrfind);
    end
    
    %End. Close all windows
    Screen('CloseAll');
    
catch
    if strcmp(input_device,'bitsi')
        if strcmp(environment,'mri')
            b2.close();
        end
        b1.close();
        delete(instrfind);
    end
    
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end
