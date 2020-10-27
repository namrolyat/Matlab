% This program reads 4 bytes (32 bits) data from the FORB and filters out 
% the joystick data. It Prints out the x- and y-values in 10 bits
% resolution.
%
% The 32 bit data format is as follows:
% Byte d7 d6 d5 d4 d3  d2 d1 d0
%  1   1  lb mb rb y10 y9 y8 y7
%  2   0  x6 x5 x4 x3  x2 x1 x0
%  3   0  y6 y5 y4 y3  y2 y1 y0
%  4   0   0  0  0 x10 x9 x8 x7
%
% Where:
% lb:   left button
% mb:   middle button (asserted when a TTL trigger is received)
% rb:   right button
% x10 ... x0: 11 bit word for x-position
% y10 ... y0: 11 bit word for y position


delete(instrfindall);
clc;  % clear command window
clear; % clear workspace

%appendFile = fopen('/data/users/tg/uriplo/outfile.txt', 'a');

% COM1 on Windows, /dev/tty.KeySerial1 (or like device) on Mac
s=serial('/dev/ttyS0');

% lets setup a helper function thats called everytime a byte is received
set(s, 'BaudRate', 115200);
set(s, 'BytesAvailableFcnMode', 'byte');
set(s, 'BytesAvailableFcnCount', 1);
%set(serialConnection, 'BytesAvailableFcn', {@serialEventHandler,
%appenderFile});
fopen(s);

oneByte = 1;
byteOne = 0;
bytesDumped =  3;
bytesExpected = 4;
result = 0;

while (s.BytesAvailable & (byteOne = fread(s, oneByte) >= 128)
    dump = fread(s, bytesDumped);
end

   
while 1
bytes = s.BytesAvailable;
if(bytes >= bytesExpected) 
    packet = fread(s, bytesExpected);
    dec1 = packet(1);
    dec2 = packet(2);
    dec3 = packet(3);
    dec4 = packet(4);

    % Y-value is bitwise AND packet bits1_shifted and dec3
    % X-value is bitwise AND packet dec2 and bits4_shifted
    y_value = dec1*2^8 + dec3; 

    x_value = dec4*2^8 + dec2; 

    fprintf('x: %d    y: %d\n', x_value, y_value);
    
end % end-if
end % end -while
fprintf('End!\n');

s.close;
delete (s);
clear;
