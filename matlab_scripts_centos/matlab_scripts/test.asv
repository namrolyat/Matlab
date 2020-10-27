%%
arduino = serial('com49');      % create serial object

set(arduino,'BaudRate', 115200)      % config
set(arduino,'DataBits', 8);
set(arduino,'Parity','none');
set(arduino,'StopBits', 1);
set(arduino,'Terminator','CR');

fopen(arduino);                      % create connection
%%

% fwrite(arduino, '$');               % send code
% fwrite(arduino, '?');
% fwrite(arduino, '%');
%fwrite(arduino,2);                   % send code


%  fwrite(arduino, 'A', 'uchar')      %prints 'A'
%  fwrite(arduino, 'A', 'uint')       %prints 'A'
%  fprintf(arduino,'%s','RS232?')     %prints 'RS232?'
%  fprintf(arduino,'%s','$RS232%')    %prints '$RS232%'
% % % S = '$amp 1%';
%  fprintf(arduino, '%s','$amp 1%');  %prints '$amp 1%'
%  fprintf(arduino,'%d',100);         %prints '100'
%  fwrite(arduino, 100, 'uchar');     %prints a 'd'
% 
%  fprintf(arduino, '%s', '$ramp 1000%'); %prints '$ramp 1000%'
  S = '$amp 1%';
  fprintf(arduino, '%s', S);
  pause(1);
  S = '$ramp 1000%';
  fprintf(arduino, '%s', S);          %prints '$ramp 1000%'
  pause(1); 
  S = '$stim 3%';
  fprintf(arduino,'%s', S);
  pause(1); 
  S = '$go%';
  fprintf(arduino, '%s', S);
  pause(10); 
 
 %%

fclose(arduino);    
clear;% close connection