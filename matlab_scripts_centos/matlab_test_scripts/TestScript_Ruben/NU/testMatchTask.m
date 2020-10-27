function testMatchTask

addpath('Local_Functions');
ListenChar(2);

try

[wptr, wrect] = Screen('OpenWindow', 0, 127);
Screen('BlendFunction', wptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

SineMean = 127;
SineAmp = 64;
SineDimAmount = 0.75*SineAmp;
frameHz = 60;

%% Make the dimming movie

DrawFormattedText(wptr, 'Creating Stimuli...', 'center', 'center', 255);
Screen('Flip',wptr);

stimRect = [0 0 600 600];

mask = makeLinearMaskCircleAnn(stimRect(4), stimRect(3), 100, 50, 300)*255;
DimSineText = zeros(frameHz,1);

for frame_idx = 1:frameHz
    amp = SineAmp - (frame_idx/frameHz*SineDimAmount);
    DimSine = makeSineGrating(stimRect(4), stimRect(3), 10, 0, 0, SineMean, amp);
    img = cat(3, DimSine, mask);
    DimSineText(frame_idx) = Screen('MakeTexture', wptr, img);
end

Sine = makeSineGrating(stimRect(4),stimRect(3),10,0,0,SineMean,SineAmp);
img = cat(3, Sine, mask);
imgtext = Screen('MakeTexture', wptr, img);
rect = CenterRect(stimRect, wrect); 
conKey = 0;

DrawFormattedText(wptr, 'Press any key to begin.', 'center', 'center', 255);
Screen('Flip', wptr);
KbWait([],2);

%% Begin 'trial'

while conKey ~= 41

rotAngle = round(rand*180);
    
Screen('DrawTexture', wptr, imgtext, [], rect, rotAngle);
[OnsetTime] = Screen('Flip', wptr);

lastFlipTime = OnsetTime;
CurrTime = GetSecs;
frame_idx = 1;

FlushEvents('KeyDown');
keyReleased = true;

while CurrTime <= OnsetTime + 3    
    while (CurrTime < lastFlipTime + 1/frameHz - 0.005) %In the inter-draw interval, this code checks if a key is down and adds the appropriate amount to the rotAngle
        [keyIsDown, secs, keyCode] = KbCheck;
        key = find(keyCode);
        if keyReleased                                  %Only consider separate keypresses. I.e. if keys haven't been released since the previous time keyIsDown occured, then don't do anything
            if ~isempty(key) && keyIsDown
                keyReleased = false;
                switch key(1)
                    case 30
                        rotAngle = rotAngle - 15;
                    case 33
                        rotAngle = rotAngle + 15;
                    case 31
                        rotAngle = rotAngle - 2;
                    case 32
                        rotAngle = rotAngle + 2;
                end
            end
        else
            if ~keyIsDown, keyReleased = true; end      %If keyReleased was false on the last check but now keyIsDown is false, keys have been released so keyReleased is true
        end
        CurrTime = GetSecs;
    end

    if CurrTime > OnsetTime + 2    %If we're 2 seconds into the matching period, the stimulus needs to dim
        if frame_idx < frameHz
            Screen('DrawTexture', wptr, DimSineText(frame_idx), [], rect, rotAngle);
            frame_idx = frame_idx + 1;
        end
    else
        Screen('DrawTexture', wptr, imgtext, [], rect, rotAngle);
    end    
    lastFlipTime = Screen('Flip',wptr);
    CurrTime = GetSecs;
    
end

Screen('Flip',wptr);

rotAngle = mod(mod(rotAngle,360)+360,360);
disp(rotAngle);

[secs, keyCode] = KbWait([],2);
conKey = find(keyCode);

end

Screen('Close');    %This closes all textures (should be done before CloseAll to prevent PTB whining)
Screen('CloseAll');

catch ME
    disp('error');
    Screen('Close');
    Screen('CloseAll')
    ListenChar(0);
    disp(ME);
    disp(ME.message);
    disp(ME.stack);
end

ListenChar(0);

end