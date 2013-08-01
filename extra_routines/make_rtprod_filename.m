function filename = make_rtprod_filename(instr, sat_data, atm_model, surfflags, calc, subset, mdate, ver, file_type, asldata);
%function filename = make_rtprod_filename(instr,sat_data, atm_model, surfflags, calc, subset, mdate, file_type, asldata);
%
% Create a systematic RTP Prod file name
%
% Example:
%   instr = 'cris' % case insensitive
%   sat_data = 'sdr60_noaa_ops'
%   atm_model = 'merra'
%   surfflags = 'udz' - u-usgs topo, d-diurnal stemp, z-DanZhou's emissivity
%                                    m-model default, w-Wiscounsin emissivity
%   calc = 'calc'
%   subset = 'subset'
%   mdate  =  datenum(yyyy,mm,dd) for this file
%   ver = 'Rv1.A-Mv1.2'
%   file_type = 'rtp'
%   asldata = '/asl/data/'
% 
% This routine will evolve - Breno Imbiriba - 2013.07.30 

  if(strcmpi(instr,'cris'))

    %sdr60_noaa_ops.merra.subset.2012.09.29.21.Rv2.0-Mv2.0.rtp
    %sdr60_noaa_ops.merra.calc.subset.yyyy.mm.dd.gg.RvTag-MvTag.rtpZ

    [yyyy mm dd HH MM SS] = datevec(mdate);
    yyyy = num2str(yyyy,'%04d');
    mm = num2str(mm,'%02d');
    dd = num2str(dd,'%02d');
    HH = num2str(HH,'%02d');
    MM = num2str(MM,'%02d');
    SS = num2str(SS,'%02d');

    gg = [HH MM SS];

    dirname = [asldata '/rtprod_cris/' yyyy '/' mm '/' dd '/'];
    
    filename = [dirname concatdot(sat_data, atm_model, surfflags, calc, subset, yyyy, mm, dd, gg, ver, file_type)];
  elseif(strcmpi(instr,'airs'))
    [yyyy mm dd HH MM SS] = datevec(mdate);
    yyyy = num2str(yyyy,'%04d');
    mm = num2str(mm,'%02d');
    dd = num2str(dd,'%02d');
    HH = num2str(HH,'%02d');
    MM = num2str(MM,'%02d');
    SS = num2str(SS,'%02d');

    gg = [HH MM SS];

    dirname = [asldata '/rtprod_airs/' yyyy '/' mm '/' dd '/'];
    
    filename = [dirname concatdot([lower(instr) '_' sat_data], atm_model, surfflags, calc, subset, yyyy, mm, dd, gg, ver, file_type)];

  elseif(strcmpi(instr,'iasi'))
  else
    error(['Unknow instrument name: ' instr '.']);
  end

    


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

