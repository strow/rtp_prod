function [iremis_files_ndate]=iremis_filedates();
%function [iremis_files_ndate]=iremis_filedates();
%
%  Basic function to find available emissivity dates and return the datenums of these

% Written by Breno
%
% Updated by Paul Schou to automate the file searching for the proper dates


% this array must be in order!

% Run make_iremis_files_date.sh at the CIMSS to create this array:

%iremis_files_dates=[ 2003 001; 2003 032; 2003 060; 2003 091; 2003 121; 2003 152; 2003 182; 2003 213; 2003 244; 2003 274; 2003 305; 2003 335; 2004 001; 2004 032; 2004 061; 2004 092; 2004 122; 2004 153; 2004 183; 2004 214; 2004 245; 2004 275; 2004 306; 2004 336; 2005 001; 2005 032; 2005 060; 2005 091; 2005 121; 2005 152; 2005 182; 2005 213; 2005 244; 2005 274; 2005 305; 2005 335; 2006 001; 2006 032; 2006 060; 2006 091; 2006 121; 2006 152; 2006 182; 2006 213; 2006 244; 2006 274; 2006 305; 2006 335; 2007 001; 2007 032; 2007 060; 2007 091; 2007 121; 2007 152; 2007 182; 2007 213; 2007 244; 2007 274; 2007 305; 2007 335; 2008 001; 2008 032; 2008 061; 2008 092; 2008 122; 2008 153; 2008 183; 2008 214; 2008 245; 2008 275; 2008 306; 2008 336; 2009 001; 2009 032; 2009 060; 2009 091; 2009 121; 2009 152; 2009 182; 2009 213; 2009 244; 2009 274; 2009 305; 2009 335;];

addpath /asl/data/iremis/CIMSS

iremis_files_dates_load();

% the array is in [YEAR , DOY] but datestr doesn't know to read DOY. 
% So, convert to string, and then read with datenum (it will undestand that);
iremis_files_date_str=num2str(iremis_files_dates);
iremis_files_ndate=datenum(iremis_files_date_str,'yyyy dd');

% The other option could be to add a column on 0 months... 

   
end
