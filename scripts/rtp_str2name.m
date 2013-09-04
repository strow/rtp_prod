function filename = rtp_str2name(varargin)
%function filename = rtp_str2name(str)
%function filename = make_rtprod_filename(instr,sat_data, atm_model, surfflags, calc, subset, infix, mdate, file_type, root);
%
% Create a systematic RTP Prod file name
%
% Input
%   str - name structure with the following fields:
%
%   instr 	= Instrument name (case insensitive) 	- 'cris'
%   sat_data 	= Satelite data label             	- 'sdr60_noaa_ops'
%   atm_model 	= Atm Model name                 	- 'merra'
%   surfflags 	= Surface flags                  	- 'udz'
%                  1. Topography: 'u' - usgs      / '_' - none
%                  2. Stemp     : 'd' - diurnal   / 'm' - model default
%                  3. Emissivity: 'z' - DanZhou's / 'w' - Wiscounsin
%   calc 	= Calculation string 			- 'calc'
%   subset 	= Subsetting string 			- 'subset'
%   infix 	= USER DEFINED STRING 			- PLEASE Do no use 
%                                                        "dots" '.' in the name.
%   mdate(:)  	=  matlab [start end] time for the data (end time is optional).
%                				- datenum(2012,09,20,[0 1],0,0)
%   ver 	= Version string 			- 'Rv1.A-Mv1.2'
%   file_type 	= File extension 			- 'rtp'
%   root 	= Root data location 			- '/asl'
% 
% This routine will evolve - Breno Imbiriba - 2013.07.30 


  if(isstruct(varargin{1}))
    str = varargin{1};
    if(isfield(str,'instr'));  instr  	= str.instr; else instr = ''; end

    if(isfield(str,'sat_data')); sat_data = str.sat_data; else sat_data 	= ''; end

    if(isfield(str,'atm_model')); atm_model = str.atm_model; else atm_model	= ''; end

    if(isfield(str,'surfflags')); surfflags 	= str.surfflags;	else surfflags = ''; end

    if(isfield(str,'calc')); calc 	= str.calc ; else calc = ''; end
    if(isfield(str,'subset')); subset 	= str.subset;	else subset = ''; end
    if(isfield(str,'infix')); infix 	= str.infix ; else infix = ''; end
    if(isfield(str,'mdate')); mdate  	= str.mdate; else mdate = []; end
    if(isfield(str,'ver')); ver 	= str.ver; else ver = ''; end
    if(isfield(str,'file_type')); file_type 	= str.file_type; else file_type = ''; end
    if(isfield(str,'root')); root 	= str.root; else root = ''; end

  else
    if(nargin()~=11)
      error('Str is not a structure');
    end
    instr  	= varargin{1};
    sat_data 	= varargin{2};
    atm_model 	= varargin{3};
    surfflags 	= varargin{4};
    calc 	= varargin{5};
    subset 	= varargin{6};
    infix 	= varargin{7};
    mdate  	= varargin{8};
    ver 	= varargin{9};
    file_type 	= varargin{10};
    root 	= varargin{11};
  end



  % Construct timestamp and data strings
  [yyyy mm dd HH MM SS] = timestring(mdate(1));
  gg = [HH MM SS];

  if(numel(mdate)>1)
    [yyy2 m2 d2 H2 M2 S2] = timestring(mdate(2));
    gg = [HH MM SS '_' H2 M2 S2];
  end


  % Set up output directory
  if(strcmpi(instr,'cris'))

    %sdr60_noaa_ops.merra.subset.2012.09.29.21.Rv2.0-Mv2.0.rtp
    %sdr60_noaa_ops.merra.calc.subset.yyyy.mm.dd.gg.RvTag-MvTag.rtpZ

    dirname = [root '/data/rtprod_cris/' yyyy '/' mm '/' dd '/'];
    

  elseif(strcmpi(instr,'airs'))

    dirname = [root '/data/rtprod_airs/' yyyy '/' mm '/' dd '/'];
    
  elseif(strcmpi(instr,'iasi'))

    dirname = [root '/data/rtprod_iasi/' yyyy '/' mm '/' dd '/'];
    
  else
    error(['Unknow instrument name: ' instr '.']);
  end

%    filename = [dirname concatdot(sat_data, atm_model, surfflags, calc, subset, yyyy, mm, dd, gg, ver, file_type)];
%    filename = [dirname concatdot([lower(instr) '_' sat_data], atm_model, surfflags, calc, subset, yyyy, mm, dd, gg, ver, file_type)];

    filename = [dirname concatdot([lower(instr) '_' sat_data], atm_model, surfflags, calc, subset, infix, yyyy, mm, dd, gg, ver, file_type)];


end

function [yyyy mm dd HH MM SS] = timestring(mdate)
% Return the string of the time components.

    [yyyy mm dd HH MM SS] = datevec(mdate);
    yyyy = num2str(yyyy,'%04d');
    mm = num2str(mm,'%02d');
    dd = num2str(dd,'%02d');
    HH = num2str(HH,'%02d');
    MM = num2str(MM,'%02d');
    SS = num2str(SS,'%02d');
end


function str=concatdot(varargin)
  str='';
  for ic=1:nargin-1
    if(length(varargin{ic})>0)
      str=[str varargin{ic} '.'];
    end
  end
  str=[str varargin{ic+1}];
  if(length(str)>0)
    if(str(end:end)=='.')
      str=str(1:end-1);
    end
  end
end

