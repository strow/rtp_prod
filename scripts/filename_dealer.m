function filename_dealer(varargin)
% function filename_dealer(PE, NPE, file1, ..., fileN, cmd)
%          filename_dealer PE NPE file1 ... fileN @cmd
%   Given a list of files (file1, ..., fileN) as input arguments,
%   divide the files among all processors (npe),
%   and call the desired matlab routine (cmd) for the current processor (pe).
%
%   PE - (string or number) - this processor
%   NPE - (string or number) - number of processors
%   file1 - (string) - 1st file to be processed
%   ...
%   fileN - (string) - Nth file to be processed
%   cmd - (string or handle) - Matlab function accepting ONE string .
%     
% Eg.
%   filename_dealer(2,4,'file1','file2','file3','file4',@test);
%   filename_dealer 2 4 file1 file2 file3 file4 @test;
%
% Breno Imbiriba - 2013.10.26


% Command may be:
% 'cmd', 'cmd.m', @cmd, '@cmd' (this last is a mistake but we treat it)
cmdstr = strtrim(varargin{end});

if(isstr(cmdstr))
  % It is a string, so remove any '@' and '.m' that may appear:
  if(cmdstr(1)=='@')
    cmdstr = cmdstr(2:end);
  end
  if(cmdstr(end-1:end)=='.m')
    cmdstr = cmdstr(1:end-2);
  end
  % Convert to function hanfler
  cmd = str2func(cmdstr);
end
 
file_list = varargin(3:end-1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dealer Wrapper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Total number of processors N
if(isstr(varargin{2}))
  NPE = str2num(varargin{2});
else
  NPE = varargin{2};
end
% Who am I (I like it to go from 1 to N, hence the +1)
if(isstr(varargin{1}))
  PE = str2num(varargin{1});
else
  NPE = varargin{1};
end

disp(['PE = ' num2str(PE) ' NPE = ' num2str(NPE) ' Total Number of Files = ' num2str(numel(file_list))]);

% Number of Jobs
NJOBS = numel(file_list);

% Create a matrix of which Jobs to run
% Zero means no job. - This is the "tricky" part (not really).
% You have to deal the work accordingly.
All_jobs_array = zeros([NPE, ceil(NJOBS./NPE)]);
All_jobs_array(1:NJOBS) = [1:NJOBS];

% Each Row represents a processor:
My_jobs = All_jobs_array(PE,:);

for fn1=1:numel(My_jobs)
  this_job = My_jobs(fn1);
  if(this_job==0) continue; end

  %%% Your code goes here %%%
  disp(['Job = ' num2str(this_job) ' Fn = ' file_list{this_job}]);
  cmd(file_list{this_job});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% END of Dealer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
