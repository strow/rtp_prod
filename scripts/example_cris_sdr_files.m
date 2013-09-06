% Input directory
idir = '/home/imbiriba/tmp/ftp.ssec.wisc.edu/pub/ssec/davet/';

% Input file names
fnames={'SCRIS_npp_d20130510_t2029459_e2037437_b07952_c20130511023743801999_noaa_ops.h5', 'SCRIS_npp_d20130515_t2037059_e2045037_b08023_c20130516024502741669_noaa_ops.h5', 'SCRIS_npp_d20130516_t2020579_e2028557_b08037_c20130517022855059234_noaa_ops.h5', 'SCRIS_npp_d20130530_t0939059_e0947037_b08229_c20130530154704782914_noaa_ops.h5', 'SCRIS_npp_d20130531_t0922579_e0930557_b08243_c20130531153057447240_noaa_ops.h5', 'SCRIS_npp_d20130601_t0906499_e0914477_b08257_c20130601151448862865_noaa_ops.h5'};

% Loop over file names
for ifile = 5:numel(fnames)

  % 1. Read File
  [head hattr prof pattr] = sdr2rtp_h5([idir '/' fnames{ifile}]);

  % 1.1 Remove bad cris data
  lbad_rtime = (tai2mattime(prof.rtime,2000)<datenum(2008,1,1) |...
                tai2mattime(prof.rtime,2000)>now);
  lbad_geo = (abs(prof.rlat)>90 | prof.rlon<-180 | prof.rlon > 360);
  if(numel(find(lbad_rtime | lbad_geo))>0)
    disp(['Warning: There are ' num2str(numel(find(lbad_rtime | lbad_geo))) ...
        ' FoVs with bad GEO/TIME. Removing']);
    [head prof] = subset_rtp(head, prof, [], [], find(~lbad_rtime & ~lbad_geo));
  end

  % 2. Add Model, etc...

  % Add Topography 
  [head hattr prof pattr] = rtpadd_usgs_10dem(head,hattr,prof,pattr);

  % Add Atm Model
  [head hattr prof pattr] = rtpadd_ecmwf_data(head,hattr,prof,pattr);
 
  % Add diurnal Stemp 
  %[head hattr prof pattr] = driver_gentemann_dsst(head,hattr, prof,pattr);

  % Add surface Emissivity
  [head hattr prof pattr] = rtpadd_emis_Wisc(head,hattr,prof,pattr);

  % 3. Run CLEAR flag detection

% Do clear selection - for now this is instrument dependent
  instrument='CRIS'; %'IASI','CRIS'
  [head hattr prof pattr summary] = ...
                   compute_clear_wrapper(head, hattr, prof, pattr, instrument);

  % 4. Run Calcs:
  tempfile = mktemp('temp.rtp');
  KlayersRun(head,hattr,prof,pattr,tempfile,11);
  [head hattr prof pattr] = SartaRun(tempfile, 12);
   
  % 5. Save data
  [dd nn ex] = fileparts(fnames{ifile});
  fout = [idir '/' nn '.rtp'];

  rtpwrite(fout, head,hattr,prof,pattr);

end

