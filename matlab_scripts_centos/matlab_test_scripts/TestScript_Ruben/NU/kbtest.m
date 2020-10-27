ListenChar(2);
key = 0;
FlushEvents('KeyDown');
while isempty(key) || key(1) ~= 27     
    [keyIsDown, secs, keyCode] = KbCheck; 
    disp(keyIsDown); 
    key = find(keyCode); 
end
ListenChar(0);