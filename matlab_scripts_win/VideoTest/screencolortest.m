function RT=screencolortest(colorseq,runexp)

clc;
% check for Opengl compatibility, abort otherwise:
AssertOpenGL;


% Make sure keyboard mapping is the same on all supported operating systems
% Apple MacOS/X, MS-Windows and GNU/Linux:
KbName('UnifyKeyNames');
%esc = 27;
%esc_key = KbName(esc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                         Triggers (through Bitsi)                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%if (runexp)
%    b = Bitsi('/dev/ttyS0');   %b = Bitsi('com1');
%    b.autoForwardResponseCodes = true;
%    close_b = onCleanup(@() {fclose(b); delete(b); clear(b);});
%else
%    b = Bitsi('');
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                         PARAMETERS EXPERIMENT                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%sound
%sound(y,Fs,bits)=wavread('1000HZ.WAV');
% Open serial connection to the bitsi

s = serial('com1');  %  s = serial('/dev/ttyS0');    % create serial object
set(s,'BaudRate',115200,'DataBits',8,'Parity','none','StopBits', 1);% config
fopen(s);                      % create connection

%colors with grey background
white                   = [255 255 255];
black                   = [  0   0   0];
params.colors           = [white; black];
params.ncol             = 1:size(params.colors,1);
params.screenduration   = 0.05;%duration in Seconds

try
    screens=Screen('Screens');   % 
    screenNumber=max(screens);
    KbCheck;
    % Screen('OpenWindow', windowwPtr [,color] [,rect]
    
    % Initial grey screen
    %[w,rect]=Screen('OpenWindow',screens,[128 128 128], [0 0 200 200]); %small screen
    [w,rect]=Screen('OpenWindow',screens,[128 128 128]);% big screen
    Screen('TextFont', w, 'TimesNewRoman');
    Screen('TextSize', w, 15);
    HideCursor;
    
    GetSecs;
    priorityLevel=MaxPriority(w);
    Priority(priorityLevel);

    RT=[];   %screen reaction time dummy variable
    
    % set bitsi bits to level mode
        fwrite(s, 0);  
        fwrite(s, 2);
        fwrite(s, 255);
        
    %while 1 % 
    for i=1:size(colorseq,2)
        %b.sendTrigger(1); %Set trigger high
        Screen('FillRect', w, params.colors(params.ncol(colorseq(i)),1), rect);
    
        %b.sendTrigger(1); %Set trigger high
        [~, startrt]=Screen('Flip', w);    
        
        if mod(i,2) 
            fwrite(s,255);
            %fwrite(s,0);
        else
            fwrite(s,0);
            fwrite(s,0);
        end
        
        %sound(y,Fs,bits)
        %b.sendTrigger(0);  %set trigger low
        
        
        a=GetSecs - startrt;
        %b.sendTrigger(0);  %code added
        RT(i,:)=a;
        clear a;
        %while (GetSecs - startrt)<=params.screenduration-0.018; 
        %   WaitSecs(0.001);
        %end %here you can choose the duration of the screen with params.screenduration
        
    end % while 1
    %b.close();
catch ME_1   
    %fprintf('Error!!\n');
    fclose(instrfindall);
    delete(instrfindall);
    Screen('CloseAll');
    ShowCursor
    rethrow(ME_1)  
end 





