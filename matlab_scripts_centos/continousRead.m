delete(instrfindall);
clc;  % clear command window
clear; % clear workspace

%appendFile = fopen('/data/users/tg/uriplo/outfile.txt', 'a');

% COM1 on Windows, /dev/tty.KeySerial1 (or like device) on Mac
s=serial('/dev/ttyS0');
size = 8;
% lets setup a helper function thats called everytime a byte is received
set(s, 'BaudRate', 115200);
set(s, 'BytesAvailableFcnMode', 'byte');
set(s, 'BytesAvailableFcnCount', 1);
%set(serialConnection, 'BytesAvailableFcn', {@serialEventHandler,
%appenderFile});
fopen(s);
while 1
   bytes = s.BytesAvailable;
   if(bytes > size)
      data = fread(s, size);    
      fprintf('%s\n', data);
   end
end

fprintf('End!\n');

s.close;
delete (s);
clear;
