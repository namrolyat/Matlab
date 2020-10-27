function RT=screencolortest(colorseq,runexp)

clc;
% check for Opengl compatibility, abort otherwise:
AssertOpenGL;


% Make sure keyboard mapping is the same on all supported operating systems
% Apple MacOS/X, MS-Windows and GNU/Linux:
KbName('UnifyKeyNames'); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                         Triggers (through Bitsi)                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (runexp)
    b = Bitsi('/dev/ttyS0');   %b = Bitsi('com1');
    b.autoForwardResponseCodes = true;
else
    b = Bitsi('');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                         PARAMETERS EXPERIMENT                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%sound
sound(y,Fs,bits)=wavread('1000HZ.WAV');


%colors with grey background
white                   = [255 255 255];
black                   = [  0   0   0];
params.colors           = [white; black];
params.ncol             = 1:size(params.colors,1);
params.screenduration   = 0.05;%duration in Seconds

screens=Screen('Screens');
screenNumber=max(screens);
KbCheck;
[w,rect]=Screen('OpenWindow',screens,[128 128 128]);%initial grey screen
Screen('TextFont', w, 'TimesNewRoman');
Screen('TextSize', w, 15);
HideCursor;
GetSecs;
priorityLevel=MaxPriority(w);
Priority(priorityLevel);

RT=[];%screen reaction time dummy variable
 
for i=1:size(colorseq,2);
    %b.sendTrigger(1); %Set trigger high
    Screen('FillRect', w, params.colors(params.ncol(colorseq(i)),1), rect);
    
    b.sendTrigger(1); %Set trigger high
    [~, startrt]=Screen('Flip', w); 
    sound(y,Fs,bits)
    b.sendTrigger(0);  %set trigger low
    
    a=GetSecs - startrt;
    %b.sendTrigger(0);  %code added
    RT(i,:)=a;
    clear a;
   % while (GetSecs - startrt)<=params.screenduration-0.018; 
   %    WaitSecs(0.001);
   % end%here you can choose the duration of the screen with params.screenduration
end

b.close();

Screen('CloseAll');
ShowCursor



