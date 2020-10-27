try 
   s = serial('/dev/ttyS5');
   set(s, 'BaudRate', 115200);
  
   WaitSecs(1.0);
   
   fopen(s);

   
   fwrite(s, 255);
   
   WaitSecs(0.5);
   
   fwrite(s, 255);

   
catch 
    fprintf('Error');
end
   fclose(s);
   
   delete(instrfindall);
   clc;
   
   clear s;
   