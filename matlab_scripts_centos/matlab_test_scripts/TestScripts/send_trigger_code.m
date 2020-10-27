% File Name:  send_trigger_code
%
% Description: 
% The code sets the bitsi to it's initial trigger mode and sends a trigger 
% to all outputs.
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
s = serial('/dev/ttyS0');      % create serial object
%set(s,'BaudRate',115200,'DataBits',8,'Parity','none','StopBits', 1);% config
set(s,'BaudRate',115200);      % this will be enough, the rest is default
fopen(s);                      % create connection

% set bitsi to level mode
fwrite(s,0);                   % change mode
fwrite(s,0);                   % set bitsi to initial (trigger) state

% write in trigger mode
fwrite(s,255);                 % trigger all outputs

% wait
pause(1);                      % pause for 1 second

% close serial connection
fclose(s);                     % close connection
delete(s);                     % clear memory
clear s;                       % clear workspace