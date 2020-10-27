% File Name:  receive_trigger_code
%
% Description: 
% The code sets the bitsi to it's initial trigger mode and receives a 
% trigger on one of its 8 inputs. We assume that the button boxes are
% connected through the bitsi. The inputs are genereted by pressing one of
% the buttons on the butttons boxes.
%
% -Trigger mode refers to a bitsi functionality where the output will be a
% 30ms TTL active high pulse.
%
% Programmer: Uriel Plones
% 
% Date: 2-3-2016
% 
% Version: 0.0: Initial versions  

% Open serial connection to the bitsi
s = serial('/dev/ttyS0');      % create serial object
set(s,'BaudRate',115200,'DataBits',8,'Parity','none','StopBits', 1);% config
fopen(s);                      % create connection

% set bitsi to level mode
fwrite(s,0);                   % change mode
fwrite(s,0);                   % set bitsi to initial (trigger) state

% write in trigger mode
%fwrite(s,255);                 % trigger all outputs

% wait
pause(1);                      % pause for 1 second

% close serial connection
fclose(s);                     % close connection
delete(s);                     % clear memory
clear s;                       % clear workspace