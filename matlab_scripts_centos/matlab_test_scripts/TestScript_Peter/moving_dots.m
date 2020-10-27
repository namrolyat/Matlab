function presentation = moving_dots(window, width, height, time, trial_dur, motion_direction, percentCoherentMovement, fix_task, save_stim)

% Note petkok (01-11-2011): in this code, each dot has a limited lifetime
% (x frames). It also offers the option of choosing a different set of
% dots as moving coherently each frame, but this seems undesirable; a dot
% will likely move in the coherent direction for just one frame, and move
% randomly for the next one. It seems more straightforward to let each dot
% move in just one direction for its lifetime. For a subset, this will be
% the direction specified by motion_direction, for the rest of the dots it
% will be random. Technically, this means the coherent motion is carried by
% the same dots for the whole stimulus duration, but in practice this does
% not matter since all dots get replotted each 3-5 frames anyway. For the
% 'random' dots, it might be good to give them a new random direction after
% each lifetime, to increase 'randomness' of the stimulus.

global distFromScreen;
global pixelsPerCm;
global input_device;
global b1;
global fixSize;
global background;

%basic parameters
dotsPerSquareDegree = 2.5;
dotSpeed_inDegPerSec = 6;
outsideCircle_inDegrees = 7.5; % radius
insideCircle_inDegrees = 1.5; % radius
sizeOfEachDot_inDegrees = 0.1;
sizeOfEachDot = round(degrees2pixels(sizeOfEachDot_inDegrees, distFromScreen, pixelsPerCm));
dotLifeTime = 12; % in frames
dot_colour = 255;
fix_default_colour = 255;
fix_change_colour = 100;
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

%speed variables
dotSpeed_inPixelsPerSec = degrees2pixels(dotSpeed_inDegPerSec, distFromScreen, pixelsPerCm);
dotSpeed_inPixelsPerFrame = dotSpeed_inPixelsPerSec / framerate;

%number of dots
nDots = round(dotsPerSquareDegree*(outsideCircle_inDegrees^2*pi - insideCircle_inDegrees^2*pi));

%number of frames per trial
nFramesPerTrial = round(framerate * trial_dur);

%dimension of cirlces in pixels
insideCircle_inPixels = degrees2pixels(insideCircle_inDegrees, distFromScreen, pixelsPerCm);
outsideCircle_inPixels = degrees2pixels(outsideCircle_inDegrees, distFromScreen, pixelsPerCm);
%difference_inPixels = outsideCircle_inPixels - insideCircle_inPixels;

% define dots' initial positions and lifetimes
DotPositions = zeros(2,nDots);
if save_stim; AllDotPositions = zeros(nFramesPerTrial,2,nDots); end;
DotLifetimes = ceil(dotLifeTime*rand(1,nDots)); % each dot starts with a random lifetime
DotDirectionsInRadians = zeros(1,nDots);
for newDot=1:nDots
    % create dot position randomly such that it's in the circle
    % NB! we are not checking if the position is unique since dots
    % will overlap later in each trial anyway
    angle = 2*pi*rand(1);
    distance = (outsideCircle_inPixels-insideCircle_inPixels)*sqrt(rand(1)) + insideCircle_inPixels;
    
    DotPositions(1,newDot) = width/2 + distance*sin(angle);
    DotPositions(2,newDot) = height/2 + distance*cos(angle);
    
    %Give the dot a random direction of movement (only to be used if
    %it's not one of the coherently moving dots)
    DotDirectionsInRadians(newDot) = 2*pi*rand;
end

if fix_task
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
end

%Start the actual sequence
for iframe=1:nFramesPerTrial
    
    %Store the dot positions for later analysis.
    if save_stim
        AllDotPositions(iframe,:,:) = DotPositions;
    end
    
    %Display the current dots
    Screen ('FillRect', window, background); %background
    if visible_apperture
        Screen('FillOval', window, 0, [width/2-outsideCircle_inPixels-1,height/2-outsideCircle_inPixels-1,...
            width/2+outsideCircle_inPixels+1,height/2+outsideCircle_inPixels+1]);
        Screen('FillOval', window, background, [width/2-insideCircle_inPixels+1,height/2-insideCircle_inPixels+1,...
            width/2+insideCircle_inPixels-1,height/2+insideCircle_inPixels-1]);
    end
    Screen('DrawDots', window, DotPositions, sizeOfEachDot, dot_colour);
    
    if fix_task && ~isempty(find(change_times == iframe,1))
        fix_colour = fix_change_colour;
    elseif fix_task && ~isempty(find(change_times == (iframe-change_dur),1))
        fix_colour = fix_default_colour;
    end
    %Screen('DrawDots', window, [width/2, height/2], dotSize, fix_colour);
    Screen('DrawLine', window, fix_colour, width/2-fixSize/2, height/2, width/2+fixSize/2, height/2, 2);
    Screen('DrawLine', window, fix_colour, width/2, height/2-fixSize/2, width/2, height/2+fixSize/2, 2);
    
    presentation_time = Screen('Flip',window,time);
    time = presentation_time + 0.01;
    
    for j=1:nDots
        %First, take care of dots with expired lifetime
        if DotLifetimes(j) == 0
            %Put them in a random new location
            angle = 2*pi*rand(1);
            distance = (outsideCircle_inPixels-insideCircle_inPixels)*sqrt(rand(1)) + insideCircle_inPixels;
            
            DotPositions(1,j) = width/2 + distance*sin(angle);
            DotPositions(2,j) = height/2 + distance*cos(angle);
            
            %Give the dot a new random direction of movement (only to be used if
            %it's not one of the coherently moving dots)
            DotDirectionsInRadians(j) = 2*pi*rand;
            
            %Reset the dot life of the new dot
            DotLifetimes(j) =  dotLifeTime;
            
            %Take care of dots with coherent motion
        elseif j <= percentCoherentMovement*nDots
            
            %Determine the direction of the dot
            directionInRadians = motion_direction;
            DotPositions(1,j) = DotPositions(1,j) + sin(directionInRadians)*dotSpeed_inPixelsPerFrame;
            DotPositions(2,j) = DotPositions(2,j) - cos(directionInRadians)*dotSpeed_inPixelsPerFrame; % minus cos since y is defined top to bottom.
            
        else %Take care of dots with random motion
            
            %%Determine the direction of these dots
            %Get the direction of movement for this dot
            directionInRadians = DotDirectionsInRadians(j);
            DotPositions(1,j) = DotPositions(1,j) + sin(directionInRadians)*dotSpeed_inPixelsPerFrame;
            DotPositions(2,j) = DotPositions(2,j) - cos(directionInRadians)*dotSpeed_inPixelsPerFrame; % minus cos since y is defined top to bottom.
            
        end
        
        %if dot is outside the annulus (either on the inside or the outside), randomly replot it
        if ((width/2-DotPositions(1,j))^2 + (height/2-DotPositions(2,j))^2 > outsideCircle_inPixels^2) || ((width/2-DotPositions(1,j))^2 + (height/2-DotPositions(2,j))^2 < insideCircle_inPixels^2)
            %Put it in a random new location
            angle = 2*pi*rand(1);
            distance = (outsideCircle_inPixels-insideCircle_inPixels)*sqrt(rand(1)) + insideCircle_inPixels;
            
            DotPositions(1,j) = width/2 + distance*sin(angle);
            DotPositions(2,j) = height/2 + distance*cos(angle);
            
            %Give the dot a new random direction of movement (only to be used if
            %it's not on of the coherently moving dots)
            DotDirectionsInRadians(j) = 2*pi*rand;
            
            %Reset the dot life of the new dot
            DotLifetimes(j) =  dotLifeTime;
        end
        
        %Decrease dot life
        DotLifetimes(j) = DotLifetimes(j) - 1;
    end
    
    if fix_task
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
    end
    
    %Save data
    presentation.presentation_time(iframe) = presentation_time;
end

presentation.stim_type = 'moving dots';
presentation.trial_dur = trial_dur;
presentation.motion_direction = motion_direction;
presentation.percentCoherentMovement = percentCoherentMovement;
if fix_task
    presentation.change_times = change_times;
    presentation.change_pres_times = presentation.presentation_time(change_times);
    presentation.response_count = response_count;
    presentation.response_time = response_time;
end
presentation.time = time;
if save_stim
    presentation.AllDotPositions = AllDotPositions;
end