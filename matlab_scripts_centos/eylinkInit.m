try
    %Eyelink('Initialize');
    status = Eyelink('InitializeDummy');
catch ME_1
    rethrow( ME_1 );
end
