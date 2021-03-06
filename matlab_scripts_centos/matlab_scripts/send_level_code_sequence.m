% File Name:  send_level_code
%
% Description: 
% The code sets the bitsi to level mode, sends code $255 and waits for 5
% seconds. After that the bitsi is put back in trigger mode and all outputs
% become low. After 1 second a trigger puls is send to all outputs.
%
% -Level mode refers to a bitsi functionality where all outputs will
% remain in the current state.
%
% -Trigger mode refers to a bitsi functionality where the output will be a
% 30ms TTL active high pulse.
%
% Programmer: Uriel Plones
% 
% Date: 25-2-2016
% 
% Version: 0.0: Initial version

% Open serial connection to the bitsi
s = serial('com1');      % create serial object
%set(s,'BaudRate',115200,'DataBits',8,'Parity','none','StopBits', 1);% config
set(s,'BaudRate',115200);      % this will be enough, the rest is default
fopen(s);                      % open the serial connection

% set bitsi to level mode
fwrite(s,0);                   % change mode
fwrite(s,2);                   % start level mode
fwrite(s,255);                 % set level mask for all bits

% clear all outputs
fwrite(s,0);                   % all outputs low
fwrite(s,0);

% write in level mode
fwrite(s,255);                 % set all outputs high
pause(100);

for i = (60:75)
    fwrite(s, i);
    pause(0.5);
end


% set bitsi to trigger mode
fwrite(s,0);                   % change mode
fwrite(s,2);                   % start level mode
fwrite(s,0);                   % set level mask 0 => back to trigger mode

% wait
pause(1);                      % pause for 1 second

% write in trigger mode
fwrite(s,255);                 % trigger all output bits

% close serial connection
fclose(s);                     % close connection
delete(s);                     % clear from memory
clear s;                       % clear from workspace