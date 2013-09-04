function [h ha p pa]=rtpread_all(fname)
% function [h ha p pa]=rtpread_all(fname)
%
% *.rtp           -> rtp/rtpZ/rtp_1/rtp_1Z
% *.rtpZ          -> rtpZ/rtp_1Z
% *.rtp_1         -> rtp_1/rtp_1Z
% *.rtp_1Z        -> rtp_1Z
%
% *.mat -> will read h,ha,p,pa or some variants
%
% Breno Imbiriba - 2010.08.25


  [fnd fnb fne]=fileparts(fname);
  if(numel(fnd)>0)
    fnd=[fnd '/'];
  end

  if(strcmp(fne,'.mat'))
    tdat=load(fname);
    % header
    h=structfieldlookup(tdat,{'h','head','header'}); %h1=tdat.h;
    % header attribute
    ha=structfieldlookup(tdat,{'ha','hattr'}); %ha1=tdat.ha;
    % profile
    p=structfieldlookup(tdat,{'p','prof','profiles'}); %p1=tdat.p;
    % prof attr
    pa=structfieldlookup(tdat,{'pa','pattr'}); %pa1=tdat.pa;
    return
  end

  if(strcmp(fne,'.rtp')) % rtp/rtpZ/rtp_1/rtp_1Z
    if(exist([fnd  fnb '.rtp']))
      [h ha p pa]=rtpread([fnd  fnb '.rtp']);
      return
    elseif(exist([fnd  fnb '.rtpZ']))
      disp('Asked rtp, Found Z')
      [h ha p pa]=rtpread([fnd  fnb '.rtpZ']);
      [h ha p pa]=rtpgrow(h,ha,p,pa);
      return
    elseif(exist([fnd  fnb '.rtp_1'])) 
      disp('Asked rtp Found IASI')
      [h ha p pa]=rtpread_iasi([fnd  fnb '.rtp']);
      return
    elseif(exist([fnd  fnb '.rtp_1Z']))
      disp('Asked rtp Found IASI Z')
      [h ha p pa]=rtpread_iasi([fnd  fnb '.rtp']);
      return
    else
      error(['Invalid file name ' fname ]);
    end

  elseif(strcmp(fne,'.rtpZ')) % rtpZ, rtp_1Z
    if(exist([fnd  fnb '.rtpZ']))
      [h ha p pa]=rtpread([fnd  fnb '.rtpZ']);
      [h ha p pa]=rtpgrow(h,ha,p,pa);
      return
    elseif(exist([fnd  fnb '.rtp_1Z'])) 
      disp('Asked rtpZ Found IASI Z')
      [h ha p pa]=rtpread_iasi([fnd  fnb '.rtp']);
      return
    else
      error(['Invalid file name ' fname ]);
    end

  elseif(strcmp(fne,'.rtp_1')) % rtp_1, rtp_1Z
    if(exist([fnd  fnb '.rtp_1'])) 
      [h ha p pa]=rtpread_iasi([fnd  fnb '.rtp']);
      return
    elseif(exist([fnd  fnb '.rtp_1Z']))
      disp('Asked IASI Found IASI Z')
      [h ha p pa]=rtpread_iasi([fnd  fnb '.rtp']);
      return
    else
      error(['Invalid file name ' fname ]);
    end

  elseif(strcmp(fne,'.rtp_1Z')) % rtp_1Z
    if(exist([fnd  fnb '.rtp_1Z']))
      [h ha p pa]=rtpread_iasi([fnd  fnb '.rtp']);
      return
    else
      error(['Invalid file name ' fname ]);
    end
  else
    error(['Invalid file name ' fname ]);
  end
end
