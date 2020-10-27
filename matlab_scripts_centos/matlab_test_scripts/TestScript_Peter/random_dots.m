function presentation = random_dots(window, width, height, time, trial_dur)

global distFromScreen;
global pixelsPerCm;
global input_device;
global b1;
global fixSize;
global background;

%basic parameters
dotsPerSquareDegree = 2.5;
outsideCircle_inDegrees = 7.5; % radius
insideCircle_inDegrees = 1.5; % radius
sizeOfEachDot_inDegrees = 0.1;
sizeOfEachDot = round(degrees2pixels(sizeOfEachDot_inDegrees, distFromScreen, pixelsPerCm));
dot_colour = 255;
fix_default_colour = 255;
fix_change_colour = 150;
fix_colour = fix_default_colour;

%present the annulus apperture visibly?
visible_apperture = 0;

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

%Get computer's frame rate
framerate = 60;
%number of frames per trial
nFramesPerTrial = round(framerate * trial_dur);
stim_dur = 60; % duration of static display in dots, in # frames

%number of dots
nDots = round(dotsPerSquareDegree*(outsideCircle_inDegrees^2*pi - insideCircle_inDegrees^2*pi));

%dimension of circles in pixels
insideCircle_inPixels = degrees2pixels(insideCircle_inDegrees, distFromScreen, pixelsPerCm);
outsideCircle_inPixels = degrees2pixels(outsideCircle_inDegrees, distFromScreen, pixelsPerCm);

% define dots' initial positions and lifetimes
DotPositions = zeros(2,nDots);

% How many times will the fixation point change colour in this
% block?
n_changes = round(trial_dur/8 * (1 + rand));
% When will these changes occur?
change_times = randperm(nFramesPerTrial - 10);
change_times = sort(change_times(1:n_changes));
% How long will they last (in # frames)
change_dur = 5;

response_count = 0;
response_time = [];

% Initialise dot positions
for newDot=1:nDots
    % create dot position randomly such that it's in the circle
    % NB! we are not checking if the position is unique since dots
    % will overlap later in each trial anyway
    angle = 2*pi*rand(1);
    distance = (outsideCircle_inPixels-insideCircle_inPixels)*sqrt(rand(1)) + insideCircle_inPixels;
    
    DotPositions(1,newDot) = width/2 + distance*sin(angle);
    DotPositions(2,newDot) = height/2 + distance*cos(angle);
end

for iframe=1:nFramesPerTrial
    
    if mod(iframe,stim_dur) == 0
        % choose new random dots each <stim_dur> frames.
        for newDot=1:nDots
            % create dot position randomly such that it's in the circle
            % NB! we are not checking if the position is unique since dots
            % will overlap later in each trial anyway
            angle = 2*pi*rand(1);
            distance = (outsideCircle_inPixels-insideCircle_inPixels)*sqrt(rand(1)) + insideCircle_inPixels;
            
            DotPositions(1,newDot) = width/2 + distance*sin(angle);
            DotPositions(2,newDot) = height/2 + distance*cos(angle);
        end
    end
    
    %Display the dots
    Screen('FillRect', window, background); %background
    if visible_apperture
        Screen('FillOval', window, 0, [width/2-outsideCircle_inPixels-1,height/2-outsideCircle_inPixels-1,...
            width/2+outsideCircle_inPixels+1,height/2+outsideCircle_inPixels+1]);
        Screen('FillOval', window, background, [width/2-insideCircle_inPixels+1,height/2-insideCircle_inPixels+1,...
            width/2+insideCircle_inPixels-1,height/2+insideCircle_inPixels-1]);
    end
    Screen('DrawDots', window, DotPositions, sizeOfEachDot, dot_colour);
    
    if ~isempty(find(change_times == iframe,1))
        fix_colour = fix_change_colour;
    elseif ~isempty(find(change_times == (iframe-change_dur),1))
        fix_colour = fix_default_colour;
    end
    %Screen('DrawDots', window, [width/2, height/2], dotSize, fix_colour);
    Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
    Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
    
    presentation_time = Screen('Flip',window,time);
    time = presentation_time + 0.01;
    
    % Check for responses
    if strcmp(input_device, 'bitsi')
        while b1.numberOfResponses() > 0
            [resp resp_time] = b1.getResponse(0.001, true);
            if resp == key_1
                response_count = response_count + 1;
                response_time(response_count) = resp_time;
            elseif resp == escape
                response_count = bbb; % forcefully break out
            end
        end
    elseif strcmp(input_device, 'keyboard')
        [keyIsDown,resp_time,keyCode]=KbCheck;
        if keyIsDown
            if keyCode(key_1)
                response_count = response_count + 1;
                response_time(response_count) = resp_time;
            elseif keyCode(escape)
                response_count = bbb; % forcefully break out
            end
        end
    end
    
    %Save data
    presentation.presentation_time(iframe) = presentation_time;
end

presentation.stim_type = 'static dots';
presentation.trial_dur = trial_dur;
presentation.stim_dur = stim_dur;
presentation.change_times = change_times;
presentation.change_pres_times = presentation.presentation_time(change_times);
presentation.response_count = response_count;
presentation.response_time = response_time;
presentation.time = time;