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

% create a serial object
b1 = Bitsi('com1');
b1.setTriggerMode();


% set bitsi to level mode
b1.sendTrigger(0);              % change mode
b1.sendTrigger(2);              % start level mode
b1.sendTrigger(255);            % set level mask for all bits

% write in level mode
b1.sendTrigger(255);            % set all outputs high

% wait
pause(5);                       % wait for 5 seconds

% clear all outputs
b1.sendTrigger(0);              % all outputs low
b1.sendTrigger(0);

% wait
pause(5);                      % wait for 5 seconds

% set bitsi to trigger mode
b1.sendTrigger(0);             % change mode
b1.sendTrigger(2);             % start level mode
b1.sendTrigger(0);             % set level mask 0 => back to trigger mode

% wait
pause(1);                      % pause for 1 second

% write in trigger mode
b1.sendTrigger(255);           % trigger all output bits

% close serial connection
b1.close;                      % close connection and delete serial object