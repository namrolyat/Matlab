% This function is made as an example of how to read the scan trigger in 
% the MRI. Tt can be used in different environments though and at the 
% time, only two environments are setup. Skyra, meaning all scanners, and 
% test, which can be used with a bitsi and a right hand button box.

function [ onset_first_trigger] = wait_for_scanner()

% Delete any open port; 
delete(instrfindall())

SCANNER = {'Skyra','Dummy','Debugging','Keyboard','buttonbox','test'}; 
SCANNER = SCANNER{5};

% Create objects of used serial ports depending on environment
switch SCANNER
    case 'Skyra'
        scannertrigger = 97;
        bitsiboxScanner = Bitsi('/dev/ttyS1');
        bitsiboxButtons = Bitsi('/dev/ttyS5');
    case 'buttonbox'
        scannertrigger = 97;
        bitsiboxScanner = Bitsi('com5');
    case 'test' 
        scannertrigger = 100;
        quit_loop = 97;
        bitsiboxScanner = Bitsi('/dev/ttyS0');

end
% remove all previous codes from Bitsibox
bitsiboxScanner.clearResponses();

nEvents = 0;
nScans = 30;
txt = 'Waiting for Scanner';

mainstart=tic;
my_debug = 1;

try
    
    %%                     Screen stuff   
    
    %Skips the 'Welcome to psychtoolbox message' 
%     Screen('Preference', 'VisualDebuglevel', 0); %Gives an error in Window 7

    %At the beginning of each script matlab does synctests. Level 1 and 2.
    % some internal self-tests and calibrations are skipped when
    % SkipSyncTests is 1. When running study set it to 0
%     if my_debug
%         Screen('Preference', 'SkipSyncTests', 1);
%     else
%         Screen('Preference', 'SkipSyncTests', 0);
%     end
    % Get the screen numbers
    screens = Screen('Screens');

    % Draw to the external screen if avaliable
    screenNumber = max(screens);

    % Open an on screen window
    white = 255;
    black = 0;
    if my_debug
        [window, ~] = Screen('OpenWindow',screenNumber,white, [1280 0 1980 900]);
    else
    [window, ~] = Screen('OpenWindow',screenNumber,white);
        HideCursor;
    end      
    % Text settings
    Screen('TextFont', window, 'Ariel');
    Screen('TextSize', window, 32);
    Screen('TextStyle', window, 0);
    KbName('UnifyKeyNames');       
        
    windowpointers=Screen('Windows');
    window = windowpointers(1);
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    textRect = Screen('TextBounds', window , txt);
    Screen('DrawText',window, txt, (screenXpixels/2)-(textRect(3)/2), (screenYpixels/2), 0);
    Screen('DrawText',window, int2str(nScans-nEvents), 500,680, 255);
    Screen(window,'Flip');
    %%
    
    % wait for trigger-events
    while nEvents < nScans;
        [response, timestamp] = bitsiboxScanner.getResponse(1, true);
        if response == scannertrigger;
            nEvents = nEvents + 1;
            if nEvents == 1
                onset_first_trigger=timestamp;
            end
        
            % clear response from buffer
            bitsiboxScanner.clearResponses();
        
            % show countdown on screen
            if true  %PTB
                Screen('DrawText',window, txt, (screenXpixels/2)-(textRect(3)/2), (screenYpixels/2), 0);
                if nScans-nEvents > 0 % don't show zero
                    Screen('DrawText',window, int2str(nScans-nEvents), 500,680, 0);
                end
                Screen(window,'Flip');
            end
            time_past = toc(mainstart);
            fprintf('%f\t%i\t%f\t%f\n', time_past, nEvents, timestamp, (timestamp - time_past) );
        
        elseif response == quit_loop
             break;   
        end
        
    end

    %%                                                                   %%
    Screen('CloseAll');
    switch SCANNER
        case 'Skyra'
            close(bitsiboxScanner);
            delete(bitsiboxScanner);
            close(bitsiboxButtons);
            delete(bitsiboxButtons);
        case 'test' 
            close(bitsiboxScanner);
            delete(bitsiboxScanner);
    end

catch me
    me.message
    me.stack.line
    Screen('CloseAll');    
    delete( instrfindall() );
end
end