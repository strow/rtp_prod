function [RetQAFlag, Qual] = readl2std_qa(fn);

% function [RetQAFlag, Qual] = readl2std_qa(fn);
%
% Read the quality assurance variables from an AIRS L2.RetStd granule file.
%
% Input:
%    fn = (string) Name of an AIRS L2 granule file, something like
%         'AIRS.2003.09.01.074.L2.RetStd.v3.1.9.0.A03261142940.hdf'
%
% Output:
%     RetQAFlag = [1 x 30*45] retrieval quality integer of 16 bit flags.
%       The following bit flags are only valid for version 4 files:
%       16  2^15 (32768) = spare
%       15  2^14 (16384) = ozone retrieval rejected
%       14  2^13 ( 8192) = water vapor retrieval rejected
%       13  2^12 ( 4096) = top part of T profile failed quality check
%       12  2^11 ( 2048) = middle part of T profile failed quality check
%       11  2^10 ( 1024) = bottom part of T profile failed quality check
%       10  2^09 (  512) = surface retrieval is suspect or rejected
%       09  2^08 (  256) = This record type is not yet valided
%       08  2^07 (  128) = spare
%       07  2^06 (   64) = spare
%       06  2^05 (   32) = cloud/OLR retrieval rejected
%       05  2^04 (   16) = final retrieval rejected
%       04  2^03 (    8) = final cloud clearing rejected
%       03  2^02 (    4) = initial regression rejected
%       02  2^01 (    2) = initial cloud clearing rejected
%       01  2^00 (    1) = MW retrieval rejected
%       Hint: use /asl/packages/aslutil/int2bits.m to convert to bit flags
%    Qual = {structure} each field [1 x 30*45] integer {0=best, 1=OK, 2=bad}
%       MW_Only_Temp_Strat : MW-only temperature above 201 mb
%       MW_Only_Temp_Tropo : MW-only temperature from Tsurf to 201 mb
%       MW_Only_H2O : MW-only water, both liquid & vapor {1=only total pwv OK}
%       Cloud_OLR : cloud parameters and OLR
%       H2O : water vapor
%       O3 : ozone
%       Temp_Profile_Top : temperature above 200 mb
%       Temp_Profile_Mid : temperature between Top & Bot
%       Temp_Profile_Bot : temperature within 3 km of surface
%       Surf : surface temperature, emissivty, and reflectivity
%       Guess_PSurf : surface pressure guess input {0=forecast; 1=climatology}
%

% Created: 19 May 2005, Scott Hannon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Granule dimensions
nxtrack = 30;
natrack = 45;
nobs = nxtrack*natrack;


% Check fn
d = dir(fn);
if (length(d) ~= 1)
   disp(['Error, bad fn: ' fn])
   return
end


% Open granule file
file_name = fn;
file_id   = hdfsw('open',file_name,'read');
swath_str = 'L2_Standard_atmospheric&surface_product';
swath_id  = hdfsw('attach',file_id,swath_str);


% Read RetQAFlag
[junk,s] = hdfsw('readfield',swath_id,'RetQAFlag',[],[],[]);
if s == -1; disp('Error reading RetQAFlag');end;
RetQAFlag = reshape( double(junk), 1,nobs);


% Read Qual_MW_Only_Temp_Strat
[junk,s] = hdfsw('readfield',swath_id,'Qual_MW_Only_Temp_Strat',[],[],[]);
if s == -1; disp('Error reading Qual_MW_Only_Temp_Strat');end;
Qual.MW_Only_Temp_Strat = reshape( double(junk), 1,nobs);

% Read Qual_MW_Only_Temp_Tropo
[junk,s] = hdfsw('readfield',swath_id,'Qual_MW_Only_Temp_Tropo',[],[],[]);
if s == -1; disp('Error reading Qual_MW_Only_Temp_Tropo');end;
Qual.MW_Only_Temp_Tropo = reshape( double(junk), 1,nobs);

% Read Qual_MW_Only_H2O
[junk,s] = hdfsw('readfield',swath_id,'Qual_MW_Only_H2O',[],[],[]);
if s == -1; disp('Error reading Qual_MW_Only_H2O');end;
Qual.MW_Only_H2O = reshape( double(junk), 1,nobs);

% Read Qual_Cloud_OLR
[junk,s] = hdfsw('readfield',swath_id,'Qual_Cloud_OLR',[],[],[]);
if s == -1; disp('Error reading Qual_Cloud_OLR');end;
Qual.Cloud_OLR = reshape( double(junk), 1,nobs);

% Read Qual_H2O
[junk,s] = hdfsw('readfield',swath_id,'Qual_H2O',[],[],[]);
if s == -1; disp('Error reading Qual_H2O');end;
Qual.H2O = reshape( double(junk), 1,nobs);

% Read Qual_O3
[junk,s] = hdfsw('readfield',swath_id,'Qual_O3',[],[],[]);
if s == -1; disp('Error reading Qual_O3');end;
Qual.O3 = reshape( double(junk), 1,nobs);

% Read Qual_Temp_Profile_Top
[junk,s] = hdfsw('readfield',swath_id,'Qual_Temp_Profile_Top',[],[],[]);
if s == -1; disp('Error reading Qual_Temp_Profile_Top');end;
Qual.Temp_Profile_Top = reshape( double(junk), 1,nobs);

% Read Qual_Temp_Profile_Mid
[junk,s] = hdfsw('readfield',swath_id,'Qual_Temp_Profile_Mid',[],[],[]);
if s == -1; disp('Error reading Qual_Temp_Profile_Mid');end;
Qual.Temp_Profile_Mid = reshape( double(junk), 1,nobs);

% Read Qual_Temp_Profile_Bot
[junk,s] = hdfsw('readfield',swath_id,'Qual_Temp_Profile_Bot',[],[],[]);
if s == -1; disp('Error reading Qual_Temp_Profile_Bot');end;
Qual.Temp_Profile_Bot = reshape( double(junk), 1,nobs);

% Read Qual_Surf
[junk,s] = hdfsw('readfield',swath_id,'Qual_Surf',[],[],[]);
if s == -1; disp('Error reading Qual_Surf');end;
Qual.Surf = reshape( double(junk), 1,nobs);

% Read Qual_Guess_PSurf
[junk,s] = hdfsw('readfield',swath_id,'Qual_Guess_PSurf',[],[],[]);
if s == -1; disp('Error reading Qual_Guess_PSurf');end;
Qual.Guess_PSurf = reshape( double(junk), 1,nobs);


% Close granule file
s = hdfsw('detach',swath_id);
if s == -1; disp('Swatch detach error');end;   
s = hdfsw('close',file_id);
if s == -1; disp('File close error');end;

%%% end of function %%%
