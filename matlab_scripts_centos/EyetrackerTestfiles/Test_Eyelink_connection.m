
%Test Eyelink connection
%This script can be run on the stimulus PC to check the connection between the stimulus and Eyelink PC. 
%This script runs through %the following steps: Open eyelink connection
%(see 'Link Open' on Eyelink PC) - pause 3sec - open 'TestEC' file and start recording - pause 3sec -
%stop recording - pause 3sec - close file and connection (see 'Link 
%Closed' on Eyelink PC).

%%%% TO INITIALIZE make sure the Ethernet IP on the host(display) computer:
%%%% IP:        100.1.1.2
%%%% Subnet:    255.255.255.0
%%%% (Eyelink Computer can be 0.0.0.0)
%%%% Make sure file name is MAX 8 characters
clear all;
close all;

%% Initialization
%Eyelink('Initializedummy'); %allows to run script without Eyelink being
%connected
Eyelink('Initialize');
pause(3);

EyelinkConnected = Eyelink('IsConnected');
File_name = 'TestEC'; %NOTE: filename should have MAX 8 characters!

%Open EDF file. Display error if file cannot be opened.
i = Eyelink('OpenFile', File_name);
if i~=0
    disp(['Cannot create EDF file:' File_name]);
    return;
end

%% Start recording
Eyelink('StartRecording');

Error = Eyelink('CheckRecording');
EyeUsed = Eyelink('eyeavailable'); %receive info about which eye is tracked. Default is 1 (RIGHT).
pause(3);

%% Stop recording and close file and connection
Eyelink('StopRecording');
pause(3);
Eyelink('CloseFile');
Eyelink('Shutdown');



