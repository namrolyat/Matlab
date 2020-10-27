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

bytesExpected = 4;
result = 0;

while 1
bytes = s.BytesAvailable;
if(bytes >= bytesExpected) 
    packet = fread(s, bytesExpected);
%    fprintf('Packet : %s\n', packet); % => OK
    %disp(dec2hex(packet));  % incomming package => OK
    
    % Wrong values!!
    %hexPacket = dec2hex(packet);
    %fprintf('hexPacket: 0x%s \n', hexPacket);  % => NOK!
    
    % This prints the wrong values!
    %fprintf('Packet: 0x%s%s-%s%s-%s%s-%s%s\n', hexPacket(1),hexPacket(2), ...
    %hexPacket(3),hexPacket(4),hexPacket(5),hexPacket(6),hexPacket(7),hexPacket(8));
    dec1 = packet(1);
    dec2 = packet(2);
    dec3 = packet(3);
    dec4 = packet(4);
%    fprintf('Decimal: %d-%d-%d-%d\n',dec1,dec2,dec3,dec4); % => OK
    %hexToBinaryVector(hexPacket(1));
%    fprintf('Hex    : %s-%s-%s-%s\n',dec2hex(packet(1)),dec2hex(packet(2)),dec2hex(packet(3)),dec2hex(packet(4)) );
%{     
    bits1 = dec2bin(dec1);   %fprintf('Byte 1: %s\n',bits1); % => OK!
    bits2 = dec2bin(dec2);   %fprintf('Byte 2: %s\n',bits2);
    bits3 = dec2bin(dec3);   %fprintf('Byte 3: %s\n',bits3);
    bits4 = dec2bin(dec4);   %fprintf('Byte 4: %s\n',bits4);
       
    bits1_16 = dec2bin(dec1, 16); disp(bits1_16);
    bits2_16 = dec2bin(dec2, 16); disp(bits2_16);
    bits3_16 = dec2bin(dec3, 16); disp(bits3_16);
    bits4_16 = dec2bin(dec4, 16); disp(bits4_16);
    
    % shift bits to the left 8 times
   
    bits1_shifted = dec2bin(dec1*2^8, 16); disp(bits1_shifted);
    bits4_shifted = dec2bin(dec4*2^8, 16); disp(bits4_shifted);
    
    num1 = typecast(int32(dec1), 'uint16'); disp(num1);
    num2 = typecast(int32(dec2), 'uint16'); disp(num2);
    num3 = typecast(int32(dec3), 'uint16'); disp(num3);
    num4 = typecast(int32(dec4), 'uint16'); disp(num4);   
 %}
    %num1_shifted = typecast(int32(num1*2^8), 'uint16');
    %num4_shifted = typecast(int32(num4*2^8), 'uint16');
    % Y-value is bitwise AND packet bits1_shifted and dec3
    % X-value is bitwise AND packet dec2 and bits4_shifted
    y_value = dec1*2^8 + dec3; 
%{    
    fprintf('Byte 1 shifted: %s\n', bits1_shifted);
    fprintf('Byte 3        : %s\n', bits3_16);
    fprintf('Y-value       : %s\n', dec2bin(y_value,16));
%}    
    x_value = dec4*2^8 + dec2; 
%{
    fprintf('Byte 4 shifted: %s\n', bits4_shifted);
    fprintf('Byte 2        : %s\n', bits2_16);
    fprintf('X-value       : %s\n', dec2bin(x_value,16));
%}   
    fprintf('x: %d    y: %d\n', x_value, y_value);
    
end % end-if
end % end -while
fprintf('End!\n');

s.close;
delete (s);
clear;
