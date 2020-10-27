try 
   t = serial('/dev/ttyS3');
   set(t, 'BaudRate', 115200);
  
   WaitSecs(1.0);
   
   fopen(t);

   
   fwrite(t, 255);
   
   WaitSecs(0.5);
   
   fwrite(t, 255);

   
catch 
    fprintf('Error');
end
   fclose(t);
   
   delete(instrfindall);
   clc;
   
   clear t;
   