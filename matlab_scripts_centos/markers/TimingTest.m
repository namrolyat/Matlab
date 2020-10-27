%Testscript BITSI for testing markers sent by PC and markers by lightsensor
%detections of white rectangle in left upper corner of screen

%This script will present a white square in the upper left corner (duration: 100 ms) and at the same time send a trigger to the specified COM port, 
%then wait for 900 ms (black screen) and restart, until all codes 1- 255
%were sent.

b = Bitsi('/dev/ttyS0'); % or '\dev\ttyS0'
i=1;

%make images
window=Screen('OpenWindow', 0, 0);
rect=[0 0 75 75]; % create rect = rectangle at location 0,0 (left upper corner) of size 75 x 75 pixels
white = WhiteIndex(window); %make rectangle white
black = BlackIndex(window); %make rectangle black

try
    HideCursor;
   moviewhite=Screen('OpenOffscreenWindow', window, 0, rect);
   Screen('FillRect', moviewhite, white, rect);
   movieblack=Screen('OpenOffscreenWindow', window, 0, rect);
   Screen('FillRect', movieblack, black, rect);

   %loop movie, presenting white rectangle in upper left corner and send
   %marker i, then again presenting black rectangle
   while i < 5
       Screen('CopyWindow',moviewhite,window,rect,rect);
       Screen('Flip', window);
       b.sendTrigger(i);
       pause(0.100);
       Screen('CopyWindow',movieblack,window,rect,rect);
       Screen('Flip', window);
       pause(0.900);
       i=i+1;
   end
   Screen('CloseAll');
   b.close();
catch
    sca;
    ShowCursor;
    psychrethrow(psychlasterror);
end; % try .. catch

