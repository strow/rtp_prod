function [varargout]=rtpcalc_hr_cris(varargin)
% function [h ha p pa]=rtpcalc_hr_cris(h,ha,p,pa)
% function             rtpcalc_hr_cris(rtpin, rtpout)
%
% Compute calculated radiances for the High Resolution Cris Data
% using the IASI wrapper.



  if(nargin()==2)
    rtpin=varargin{1};
    rtpout=varargin{2};
  elseif(nargin()==4)
    h=varargin{1};
    ha=varargin{2};
    p=varargin{3};
    pa=varargin{4};
  else
    error('Wrong number of input arguments');
  end


  if(nargin()==2) 
    [a b]=system(['rtpdump -h ' rtpin ' | grep ^nchan']);
    ii=strfind(b,'nchan');
    nchan = sscanf(b(ii:end),'nchan = %d');
  else
    nchan = h.nchan;
  end

  if(nchan==2211)
    nguard=0;
  elseif(nchan==2223)
    nguard=2;
  elseif(nchan==2235)
    nguard=4;
  elseif(nchan==2217)
    nguard=1;
  elseif(nchan==2229)
    nguard=3;
  else
    error(['Wrong number of channels or guard channels: nchan = ' num2str(nchan)]);
  end


  if(nargin()==4)
    rtpin=mktemp();
    rtpwrite(rtpin,h,ha,p,pa)
  end


  %%%%%%%%%%%%%%%%%%%
  % Run Sarta Wrapper  

  [r888 klayers sarta] = cris888_sarta_wrapper_bc(rtpin, nguard);

  %%%%%%%%%%%%%%%%%%%


  if(nargin()==2)
    [h ha p pa]=rtpread(rtpin);
  end

  p.rcalc = r888;

  ha=set_attr(ha,'klayers',klayers);
  ha=set_attr(ha,'sarta',['cris888_sarta_wrapper_bc - ' sarta]);
  h.pfields = h.pfields + 2;

  if(nargin()==2)
    rtpwrite(rtpout,h,ha,p,pa); 
  end

end
