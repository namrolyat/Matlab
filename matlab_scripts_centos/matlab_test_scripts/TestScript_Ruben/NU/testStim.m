function testStim

addpath('Local_Functions');
ListenChar(2);

try

%% Set Parameters

Parameters = struct;

[scrnum,frameHz,pixPerDeg] = GetMonitorInfo(0); 
Parameters.pixPerDeg = pixPerDeg;
Parameters.BgdColor = 127;
Parameters.SineMean = Parameters.BgdColor;
Parameters.SineContrast = 1;
Parameters.SineAmp = Parameters.SineMean*Parameters.SineContrast;


%% Open Window

[wptr, wrect] = Screen('OpenWindow', scrnum, Parameters.BgdColor);
Screen('BlendFunction', wptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
DrawFormattedText(wptr, 'Creating textures...', 'center', 'center', 255);
Screen('Flip', wptr);

%% Create fixation bullseye

fixDiam = ceil(0.5*Parameters.pixPerDeg);
fixRect = [0 0 fixDiam fixDiam];
fixBgd = zeros(fixDiam,fixDiam,2)*0;
FixCrossTexture = Screen('MakeTexture', wptr, fixBgd);
elDiam = floor(fixDiam/3);
Screen('FillArc',FixCrossTexture,1,CenterRect([0 0 elDiam elDiam],fixRect),0,360);
Screen('FrameArc',FixCrossTexture,1,CenterRect([0 0 elDiam*3 elDiam*3],fixRect),0,360,elDiam/2,elDiam/2);

%% Create stimulus in two ways
%That is, see if there is a difference between using makeSineGrating with a
%specified angle, and using makeSineGrating with angle = 0 and applying a
%rotation at DrawTexture.

DrawFormattedText(wptr, 'Creating Stimuli...', 'center', 'center', 255);
Screen('Flip',wptr);

stimRect = [0 0 600 600];
rect = CenterRect(stimRect, wrect); 

mask = makeLinearMaskCircleAnn(stimRect(4), stimRect(3), 100, 50, 300)*255;

sine1 = makeSineGrating(stimRect(4), stimRect(3), 1, 0, 0, Parameters.SineMean, Parameters.SineAmp, pixPerDeg);
stim1 = cat(3, sine1, mask);
imgtext1 = Screen('MakeTexture', wptr, stim1);

sine2 = makeSineGrating(stimRect(4), stimRect(3), 1, -pi/180*45, -pi, Parameters.SineMean, Parameters.SineAmp, pixPerDeg);
stim2 = cat(3, sine2, mask);
imgtext2 = Screen('MakeTexture', wptr, stim2);

%% Present stimuli on screen 

key = 0;

while key(1) ~= 41
Screen('DrawTexture', wptr, FixCrossTexture, [], CenterRect(fixRect, wrect));
Screen('DrawTexture', wptr, imgtext1, [], rect);
Screen('Flip', wptr);

KbWait([],2);

Screen('DrawTexture', wptr, FixCrossTexture, [], CenterRect(fixRect, wrect));
Screen('DrawTexture', wptr, imgtext2, [], rect);
Screen('Flip', wptr);

[secs, keyCode] = KbWait([],2);
key = find(keyCode);

end


%% Finish up

Screen('Close');    %This closes all textures (should be done before CloseAll to prevent PTB whining)
Screen('CloseAll');
ListenChar(0);

%% Catch errors

catch ME
    disp('error');
    Screen('Close');
    Screen('CloseAll')
    ListenChar(0);
    disp(ME);
    disp(ME.message);
    disp(ME.stack);
end

end