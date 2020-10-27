

for Trial = (1:1000)

TrialMarker = Trial;
if TrialMarker >= 257 && TrialMarker<= 512;
    TrialMarker = (TrialMarker-256);
    PostInitiationMarker=2;
elseif TrialMarker >= 513 && TrialMarker<= 768;
    TrialMarker = (TrialMarker-512);
    PostInitiationMarker = 3;
elseif TrialMarker >= 769 && TrialMarker <=1024;
    TrialMarker = (TrialMarker - 768);
    PostInitiationMarker = 4;
end
TrialMarker;
end