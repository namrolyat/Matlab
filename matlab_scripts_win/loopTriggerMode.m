% File Name:  send_level_code
%
% Description: 
% 
%
% Programmer: Uriel Plones
% 
% Date: 4-9-2019
% 
% Version: 0.0: Initial version

% Open serial connection to the bitsi
s = serial('com6');      % create serial object
%set(s,'BaudRate',115200,'DataBits',8,'Parity','none','StopBits', 1);% config
set(s,'BaudRate',115200);      % this will be enough, the rest is default
fopen(s);                      % open the serial connection

pause(2);

% set bitsi to level mode
for i=0:10
    fwrite(s,1);                 % set all outputs high
    pause(1);
end



% close serial connection
fclose(s);                     % close connection
delete(s);                     % clear from memory
clear s;                       % clear from workspace