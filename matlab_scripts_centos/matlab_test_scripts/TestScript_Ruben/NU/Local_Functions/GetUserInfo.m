function [subName, scanNum, theDate] = GetUserInfo();% function [subName, scanNum, theDate] = GetUserInfo();% gets user info: subject's name, scan/experiment number, & also current date % % created by Frank Tong on 2000/05/10	(previous date format: mmddyy)% modified on 2001/08/09 to date format yymmddsubName = input('Initials of subject? (default="tmp")  ','s');		% get subject's initials from userif isempty(subName); subName = 'tmp'; endscanNum = input('Series number for this scan?  ','s');			theDate = datestr(date,2);											% current date on computer, 'mm/dd/yy'theDate(6) = []; theDate(3) = [];									% delete '/', convert to 'mmddyy'theDate = [theDate(5:6) theDate(1:2) theDate(3:4)];					% LINE ADDED ON 2001/08/09