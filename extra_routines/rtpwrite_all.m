function ofname=rtpwrite_all(fname,h,ha,p,pa)
% function ofname=rtpwrite_all(fname,h,ha,p,pa)
%
%fname can be:   <=4231  >4231
%*.rtp           *.rtp   *.rtp_1/*.rtp_2
%*.rtpZ          *.rtpZ  *.rtp_1Z/*.rtp_2Z
%*.rtp_1         Error   *.rtp_1/*.rtp_2
%*.rtp_1Z        Error   *.rtp_1Z/*.rtp_2Z
%
%*.mat  -> save as head,hattr,prod,pattr
%
% If present, `ofname' is the will return the actuall file names associated to the data - usefull for IASI data.
%
% Breno Imbiriba - 2010.08.25


nchan=h.nchan;
[fnd fnb fne]=fileparts(fname);
if(numel(fnd)>0)
  fnd=[fnd '/'];
end

if(strcmp(fne,'.mat'))
  head=h; hattr=ha; prof=p; pattr=pa;
  save(fname,'head','hattr','prof','pattr');
  return
end

if(nchan<=4231)   	% AIRS FILES
  if(strcmp(fne,'.rtp'))	% RTP 
    rtpwrite(fname,h,ha,p,pa);
    ofname={fname};
    return
  elseif(strcmp(fne,'.rtpZ'))	% TRIM RTP
    [h ha p pa]=rtptrim(h,ha,p,pa,'allowempty');
    rtpwrite(fname,h,ha,p,pa);
    ofname={fname};
    return
  else
    error(['Invalid file extension ' fne '.']);
  end

else 		% It's an IASI file - split in two
  indpt1 = 1:4231;
  indpt2 = 4232:8461;


  [h1 p1]=subset_rtp(h,p,[],indpt1,[]);
  [h2 p2]=subset_rtp(h,p,[],indpt2,[]);
  ha1=ha; ha2=ha;
  pa1=pa; pa2=pa;

  fn1=[fnd fnb '.rtp_1'];
  fn2=[fnd fnb '.rtp_2'];

  if(strcmp(fne,'.rtp') | strcmp(fne,'.rtp_1'))	% RTP_1/2
    rtpwrite(fn1,h1,ha1,p1,pa1);
    rtpwrite(fn2,h2,ha2,p2,pa2);
    ofname={fn1,fn2};
    return
  elseif(strcmp(fne,'.rtpZ') | strcmp(fne,'.rtp_1Z')) 	% TRIM RTP
    [fpd fpb fpe]=fileparts(deblank(get_attr(ha,'rtpfile')));
    fpd=[fpd '/'];

    if(strcmp(fpe,'.rtp_1') | strcmp(fpe,'.rtp')) 	% are the parents Z?
      ha1=set_attr(ha,'rtpfile',[fpd fpb '.rtp_1']);
      ha2=set_attr(ha,'rtpfile',[fpd fpb '.rtp_2']);
    elseif(strcmp(fpe,'.rtp_1Z') | strcmp(fpe,'.rtpZ'))
      ha1=set_attr(ha,'rtpfile',[fpd fpb '.rtp_1Z']);
      ha2=set_attr(ha,'rtpfile',[fpd fpb '.rtp_2Z']);
    else
      error(['Invalid parent name ' fpd fpb fpe '.']);
    end

    fn1=[fn1 'Z'];
    fn2=[fn2 'Z'];

    [h1 ha1 p1 pa1]=rtptrim(h1,ha1,p1,pa1,'allowempty');
    [h2 ha2 p2 pa2]=rtptrim(h2,ha2,p2,pa2,'allowempty');

    rtpwrite(fn1,h1,ha1,p1,pa1);
    rtpwrite(fn2,h2,ha2,p2,pa2);
    ofname={fn1,fn2};
    return
  else
    error(['Invalid  file name ' fname ]);
  end
end

