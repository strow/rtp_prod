

% srun --partition=batch --cpus-per-task=1 --ntasks=8 --exclusive --job-name=Run1 --qos=long_contrib --output=dump-%j.%t.out matlab -nodesktop -nosplash -r 'test; exit'


rtprod='/asl/rtp_prod/';
matlib='/asl/matlib/';
addpath(rtprod);
paths;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cluster Wrapper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Total number of processors N
NPE=str2num(getenv('SLURM_NPROCS'));
% Who am I (I like it to go from 1 to N, hence the +1)
PE = str2num(getenv('SLURM_PROCID'))+1;

% Number of Jobs
NJOBS = 144;

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
   disp([NPE PE this_job]);

   gran = this_job-1;
   fname = ['/asl/data/rtprod_cris/2012/09/20/ecm.cris_cspp_dev.2012.09.20.' num2str(gran,'%03d') '.Rv1.1d-Mv1.1c-1-g90d9ac4.rtpZ'];

   if(~exist(fname,'file'))
     disp(['Warning: file ' fname ' not present.']);a
     continue
   end
   % load data
   [h ha p pa] = rtpread(fname);
%   % fix parent file name
%   rtpfile = get_attr(ha,'rtpfile'); 
%   [xxa xxb xxc] = fileparts(rtpfile);
%   [yya yyb yyc] = fileparts(fname);
%   rtpfile = [yya '/' xxb xxc];
%   if(exist(rtpfile,'file')
%     ha = set_attr(ha,'rtpfile',rtpfile);
%   end
%   [h ha p pa] = rtpgrow(h,ha,p,pa);
%

   % Add ECMWF data with extra fields:
   [h ha p pa] = rtpadd_ecmwf_data(h,ha,p,pa,{'SP','SKT','10U','10V','TCC','CI','T','Q','O3','CC','CIWC','CLWC'});
%   % Split data:
%   [h ha p pa] = rtptrim(h,ha,p,pa);

   rtpwrite(fname,h,ha,p,pa);


   %%% End of Serial Code

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% END of Wrapper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


