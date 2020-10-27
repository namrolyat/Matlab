 
% Clear the workspace and the screen
sca;
close all;
clearvars;

try
    %% Screen
    %Set parameters to build screen 
    %Skips the 'Welcome to psychtoolbox message' 
    Screen('Preference', 'VisualDebuglevel', 0);
    
    %At the beginning of each script matlab does synctests. Level 1 and 2
    %prevent those tests. What does 0 do?
    Screen('Preference', 'SkipSyncTests', 1);    
    
    % Get the screen numbers
    screens = Screen('Screens');

    % Draw to the external screen if avaliable
    screenNumber = max(screens);
    
    % Hide mouse
    HideCursor;
   
    %[w,screenRect] = Screen(0,'OpenWindow',0,[]); %opens fullscreen window 'w'
    [w, screenRect] = Screen(screenNumber,'OpenWindow',200, [100 100 800 800 ]); %Preferably open non-fullscreen window 'w' in test mode
    Screen('FillOval',w,[255, 125, 125], [100,100,300,300]);
    Screen('Flip',w);
    pause(2);
    
    % Text settings
    Screen('TextFont', w, 'Ariel');
    Screen('TextSize', w, 32);
    Screen('TextStyle', w, 0);
    KbName('UnifyKeyNames'); 
    
    Screen(w, 'DrawText', 'Hello World!', 300,500);
    Screen('Flip', w);
    pause(2);

catch ME
    Screen('CloseALL');
    rethrow(ME);
end
Screen('CloseAll');
