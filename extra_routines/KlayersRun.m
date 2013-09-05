function [h ha p pa]=KlayersRun(a1,a2,a3,a4,a5,a6,a7)
% function [h ha p pa] = KlayersRun(fin,iklayers)
% function               KlayersRun(fin,fout,iklayers)
% function [h ha p pa] = KlayersRun(h1,h1a,p1,p1a,iklayers)
% function               KlayersRun(h1,h1a,p1,p1a,fout,iklayers)
%
% Run /asl/packages/klayers/Bin/klayers_airs
%
% Extra last argument: opt - string with Klayers options-structure with options
%		       opt.kopt - string with Klayers options
%		       opt.temp - type of temporary files - *'tmp'/'shm'/'here'
%
% iklayers(opt) - tell which klayers version to use.
%
%  Using RTP 105
%  1  - /asl/packages/klayersV205/BinV105/klayers_airs
%       klayersV205_BinV105
%
%  2  - /asl/packages/klayersV205/BinV105/klayers_airs nwant=-1 ';
%       klayersV205_BinV105_nwant_-1
%
%  3  - /asl/packages/klayersV205/BinV105/klayers_airs_v5_testme ';          
%       klayersV205_BinV105_v5_testme
%
%  4  - /asl/packages/klayersV205/BinV105/klayers_airs_v5_testme nwant=-1 ';
%       klayersV205_BinV105_v5_testme_nwant_-1
%
%
%  Using RTP 201
%  11 - /asl/packages/klayersV205/BinV201/klayers_airs
%       klayersV205_BinV201
%
%  12 - /asl/packages/klayersV205/BinV201/klayers_airs nwant=-1 '; 
%       klayersV205_BinV201_nwant_-1
%
%  13 - /asl/packages/klayersV205/BinV201/klayers_airs_v5_testme ';          
%       klayersV205_BinV201_v5_testme
%
%  14 - /asl/packages/klayersV205/BinV201/klayers_airs_v5_testme nwant=-1 ';
%       klayersV205_BinV201_v5_testme_nwant_-1
%
%  21 - /asl/packages/klayersV205/BinV201/klayers_airs_wetwater **RECOMENDED
%       klayersV205_BinV201_wetwater
%
%  22 - /asl/packages/klayersV205/BinV201/klayers_airs_wetwater nwant=-1 **RECOMENDED
%       klayersV205_BinV201_wetwater_nwant_-1
%%
% 101 - JPL
% 
% Breno Imbiriba - 2007.02.27
%                  2007.09.15 (optional command)
% 		   2010.09.02 working with IASI split files


  % Set up - 
  cklayers{1}='/asl/packages/klayersV205/BinV105/klayers_airs ';
  cklayers{2}='/asl/packages/klayersV205/BinV105/klayers_airs nwant=-1 ';
  cklayers{3}='/asl/packages/klayersV205/BinV105/klayers_airs_v5_testme ';
  cklayers{4}='/asl/packages/klayersV205/BinV105/klayers_airs_v5_testme nwant=-1 ';
  cklayers{11}='/asl/packages/klayersV205/BinV201/klayers_airs ';
  cklayers{12}='/asl/packages/klayersV205/BinV201/klayers_airs nwant=-1 ';
  cklayers{13}='/asl/packages/klayersV205/BinV201/klayers_airs_v5_testme ';
  cklayers{14}='/asl/packages/klayersV205/BinV201/klayers_airs_v5_testme nwant=-1 ';
  cklayers{21}='/asl/packages/klayersV205/BinV201/klayers_airs_wetwater';
  cklayers{22}='/asl/packages/klayersV205/BinV201/klayers_airs_wetwater nwant=-1';

  cklayers{101}='/somewhere/in/JPL/path/klayers';

  % distinguish calls via number of arguments:
  lreaddata=false;
  lsavedata=false;
  opt='';

  if    (nargin==2 & nargout==4)
    fin=a1;  
    iklayers=a2;
    lreaddata=true;
    lsavedata=false;
  elseif(nargin==3 & nargout==4)
    fin=a1;
    iklayers=a2;
    lreaddata=true;
    lsavedata=false; 
    opt=a3;
  elseif(nargin==3 & nargout==0)
    fin=a1;
    fout=a2;
    iklayers=a3;
    lreaddata=true;
    lsavedata=true;
  elseif(nargin==4 & nargout==0)
    fin=a1;
    fout=a2;
    iklayers=a3;
    lreaddata=true;
    lsavedata=true;
    opt=a4;
  elseif(nargin==5 & nargout==4)
    h1=a1;
    h1a=a2;
    p1=a3;
    p1a=a4;
    iklayers=a5;
    lreaddata=false;
    lsavedata=false;
  elseif(nargin==6 & nargout==4)
    h1=a1;
    h1a=a2;
    p1=a3;
    p1a=a4;
    iklayers=a5;
    lreaddata=false;
    lsavedata=false;
    opt=a6;
  elseif(nargin==6 & nargout==0)
    h1=a1;
    h1a=a2;
    p1=a3;
    p1a=a4;
    fout=a5;
    iklayers=a6;
    lreaddata=false;
    lsavedata=true;
  elseif(nargin==7 & nargout==0)
    h1=a1;
    h1a=a2;
    p1=a3;
    p1a=a4;
    fout=a5;
    iklayers=a6;
    lreaddata=false;
    lsavedata=true;
    opt=a7;
   else
    error('Wrong number of arguments')
  end

  % fix opt %%%%%%%%%%
  if(isstr(opt))
    kopt=opt;
    clear opt;
    opt.kopt=kopt;
    opt.temp='tmp'; % default
  else
    if(~isfield(opt,'kopt') | ~isfield(opt,'temp'))
      disp(opt)
      error('Calling KlayersRun with invalid opt structure');
    end
  end

  line_arguments='';
  if(ischar(iklayers))
    sspace=strfind(iklayers,' ');
    if(length(sspace)>0)
      line_arguments=iklayers(sspace(1):end);
      iklayers=iklayers(1:sspace(1)-1);
    else 
    end
  end 

  % Now a trick. If the sarta name is just one charactere, guess that it's 
  % a number coded as a char and retrieve the number
  if(length(iklayers)==1)
    iklayers=iklayers*1;
  end


  if(ischar(iklayers))
    if(strcmp(iklayers,'klayersV205_BinV105'))
      iklayers=1;
    elseif(strcmp(iklayers,'klayersV205_BinV105_nwant_-1'))
      iklayers=2;
    elseif(strcmp(iklayers,'klayersV205_BinV105_v5_testme'))
      iklayers=3;
    elseif(strcmp(iklayers,'klayersV205_BinV105_v5_testme_nwant_-1'))
      iklayers=4;
    elseif(strcmp(iklayers,'klayersV205_BinV201'))
      iklayers=11;
    elseif(strcmp(iklayers,'klayersV205_BinV201_nwant_-1'))
      iklayers=12;
    elseif(strcmp(iklayers,'klayersV205_BinV201_v5_testme'))
      iklayers=13;
    elseif(strcmp(iklayers,'klayersV205_BinV201_v5_testme_nwant_-1'))
      iklayers=14;
    elseif(strcmp(iklayers,'klayersV205_BinV201_wetwater'))
      iklayers=21;
    elseif(strcmp(iklayers,'klayersV205_BinV201_wetwater_nwant_-1'))
      iklayers=22;
    else
      warning('iklayers is an invalid string: %s.', iklayers);
      iklayers=1;
    end
  end

  if(iklayers<1 | iklayers>length(cklayers))
    iklayers=1;
    fprintf('Bad Klayers request. Setting to 1.\n');
  end


  %% Set up temporary files
  if(strcmpi(opt.temp,'tmp'))
    tempdir=getenv('TMPDIR');
    if(numel(tempdir)==0)
      tempdir='/tmp/';
    end
  elseif(strcmpi(opt.temp,'shm'))
    tempdir=getenv('SHMDIR');
    if(numel(tempdir)==0)
      tempdir='/dev/shm/';
    end
  elseif(strcmpi(opt.temp,'local'))
    tempdir=pwd; 
  else
    warning(['You requested for a unknown temp option: ' opt.temp '. Assuming it is a directory']);
    tempdir=opt.temp;
  end
  %fname1=[ num2str(floor(100000000*rand)) '.rtp'];
  %fname2=[ num2str(floor(100000000*rand)) '.rtp'];
  fname1=mktemp(tempdir,'KlayersRun.rtp');
  fname2=mktemp(tempdir,'KlayersRun.rtp');
  Sys_rm(fname1);
  Sys_rm(fname2);


  % Routine Core -

  if(lreaddata) % Read data from file - if needed.

    [h1 h1a p1 p1a]=rtpread_all(fin);
  end

  % Save data into temporay files
  ofnames=rtpwrite_all(fname1, h1,h1a,p1,p1a);


  if(h1.ptype==0)
    % loop over the files
    if(numel(ofnames)==1) % AIRS (single file) 
      fitmp{1}=ofnames{1};
      fotmp{1}=fname2;
      klayers_dump{1}=mktemp(tempdir,'klayers_dump');
      cmd=[cklayers{iklayers} ' ' opt.kopt ' fin=' fitmp{1} ' fout=' fotmp{1} ' > ' klayers_dump{1}];
      [status1 result1]=system(cmd);

      % Check output
      [status2 result2]=system(['/asl/packages/rtpV201/bin/rtpdump ' fname2]);

    else % IASI - two files 

      for iff=1:numel(ofnames)
	fitmp{iff}=ofnames{iff};
	fotmp{iff}=[fname2 '_' num2str(iff)];
	klayers_dump{iff}=mktemp(tempdir,'klayers_dump');
	cmd=[cklayers{iklayers} ' ' opt.kopt ' fin=' fitmp{iff} ' fout=' fotmp{iff} ' > ' klayers_dump{iff}];
	[status1 result1]=system(cmd);

	% Check output
	[status2 result2]=system(['/asl/packages/rtpV201/bin/rtpdump ' fotmp{iff}]);

      end
    end
  else % Layer profiles
    rtpcopy_all(fname1,fname2);
    status2=0; result2='copy';
  end

  if(~exist(fname2,'file')| status2~=0)
      fprintf('******************************\n');
      fprintf('KlayersRun: Error Running Klayers.\n');
      fprintf('******************************\n');
      disp(['status = ' num2str(status1)]);
      imx=min(1000,numel(result1));
      disp(['result = ' result1(1:imx)]);
      imx=min(1000,numel(result2));
      disp(['rtpdmp = ' result2(1:imx)]);
      fprintf('****** start dump **************\n');
      system(['cat ' klayers_dump{1}]);
      fprintf('****** end * dump **************\n');

      disp(['ls -l ' cklayers{iklayers} ':']);
      system(['ls -l ' cklayers{iklayers} ]);

      disp(['ls -l ' fitmp{1} ':']);
      system(['ls -l ' fitmp{1} ]);

      disp(['ls -l ' fotmp{1} ':']);
      system(['ls -l ' fotmp{1} ]);

      system(['df -H ' fitmp{1} ]);
  end

  % Read output data:
  [h ha p pa]=rtpread_all(fname2);

  % If needes, save data:
  if(lsavedata)
    rtpwrite_all(fout,h,ha,p,pa);
  end

  % Delete files:
  for iff=1:numel(ofnames)
    if(exist('fitmp','var')); Sys_rm(fitmp{iff}); end;
    if(exist('fotmp','var')); Sys_rm(fotmp{iff}); end;
    if(exist('klayers_dump','var')); Sys_rm(klayers_dump{iff}); end
  end
end

