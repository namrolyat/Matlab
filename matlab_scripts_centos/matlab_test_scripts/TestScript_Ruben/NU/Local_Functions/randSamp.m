function randlist = randSamp(varset,num,type);%% randlist = randSamp(varset,num,type);%% Returns a randomized list of num elements sampled from varset.% Types are: 'r' for independent random samples with replacement, % 	'n' for random samples without replacement %		(a new sampling is started after the set is exhausted).% 	'e' for with replacement, but constrained to have equal numbers of each item%   'o' for in order(not random) again a new sampling is started after the set is exhausted% 8/1/97 sae created itif(size(varset,1) == 1)	varset = varset'; % the first dim is the number of elements to be sampled from, the second is the stim as a number of elements/ array, eg movie?/endrandlist = zeros(num,size(varset,2)); setsize = size(varset,1); % size of the list of variables to be sampled fromif type == 'n'		%No replacement, start over when set depleted	nlists = ceil(num/setsize); % # of random list to be drawn from the list of variables	for i = 1:nlists		ind = [((i-1)*(setsize)+1):(i*setsize)];		[srt ord] = sort(rand(1,setsize));		randlist(ind,:) = varset(ord,:);	end	randlist = randlist(1:num,:);elseif type == 'e'	%Equal total numbers	nlists = ceil(num/setsize);	for i = 1:nlists		ind = [((i-1)*(setsize)+1):(i*setsize)];		randlist(ind,:) = varset;	end	randlist = randlist(1:num,:);	[srt ord] = sort(rand(1,num));	randlist = randlist(ord,:);elseif type == 'o'		%In order, start over when set depleted	nlists = ceil(num/setsize);	for i = 1:nlists		ind = [((i-1)*(setsize)+1):(i*setsize)];		randlist(ind,:) = varset(:,:);	end	randlist = randlist(1:num,:);else				%Random	randlist = varset(ceil(rand(1,num)*setsize),:);end