function [h ha p pa] = SartaRun(a1,a2,a3,a4,a5,a6,a7)
% function [h ha p pa] = SartaRun(fin,isarta)
% function               SartaRun(fin,fout,isarta)
% function [h ha p pa] = SartaRun(h1,h1a,p1,p1a,isarta)
% function               SartaRun(h1,h1a,p1,p1a,fout,isarta)
%
% function [sartacmd] = SartaRun('',isarta) 
% 
% Run the V107 SARTA program on the provided profile p1. 
% It create two temporary files and then call the SARTA program.
%
% isarta(opt) - tell which sarta version to use:
%               isarta may contain extra input arguments like:
%               isarta='107_jan04 lrhot=true' 
%               
%               custom case: you can specify any Sarta code by using the
%               `!' symbol as the 1st character of the isarta string, 
%               followed by sarta's full path name. 
%
% Extra last argument: opt - string to Sarta options - structure with options
%		       opt.sopt - string with Sarta options
%                      opt.temp - type of temporary files - *'tmp'/'shm'/'here'
%
%
% Sarta V108 - BinV201 (/asl/packages/sartaV108/BinV201/)
%
%  1 - sarta_airs_PGEv6_postNov2003
%  2 - sarta_airs_PGEv6_postNov2003_wcon_nte
%  3 - sarta_airs_PGEv6_preNov2003
%  4 - sarta_airs_PGEv6_preNov2003_wcon_nte
%
%  5 - sarta_apr08_m140
%  6 - sarta_apr08_m140_iceaggr_waterdrop_desertdust_slabcloud_hg3
%  7 - sarta_apr08_m140_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte
%  8 - sarta_apr08_m140_wcon_nte
%  9 - sarta_apr08_m140_wcon_nte_nh3
% 10 - sarta_apr08_m140x_370_wcon_nte
%
% 11 - sarta_crisg4_nov09_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte
% 12 - sarta_crisg4_nov09_wcon_nte
% 13 - sarta_crisg4_nov09_wcon_nte_nh3
%
% 14 - sarta_iasi_may09_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte_swch4
% 15 - sarta_iasi_may09_wcon_nte
% 16 - sarta_iasi_may09_wcon_nte_swch4
% 17 - sarta_iasi_may09_wcon_nte_swch4_nh3
%
%
% Sarta V108 - BinV105 (/asl/packages/sartaV108/BinV105/)
%
% 21 - sarta_apr08_m130_m150
% 22 - sarta_apr08_m130x_370
% 23 - sarta_apr08_m130x_m140x_370
% 24 - sarta_apr08_m130x_m140x_370_exper
% 25 - sarta_apr08_m140_wcon_nte
% 26 - sarta_apr08_m140x_370
% 27 - sarta_apr08_m140x_385
%
% Sarta V108_PGEv6_postNov2003 - (/asl/packages/sartaV108_PGEv6/Bin)
%
% 30 - sarta_airs_PGEv6_postNov2003
%
%
% SERGIO Sarta codes - (/home/sergio/SARTA_CLOUDY/Bin/)
%
% 101 - sarta_2_andesite
% 102 - sarta_2_basalt
% 103 - sarta_2_ddlognorm
% 104 - sarta_2_desertdust
% 105 - sarta_2_desertdust_gamma4
% 106 - sarta_2_desertdust_small
% 107 - sarta_2_desertdust_small_log2_absonly
% 108 - sarta_2_desertdust_small_log2_new
% 109 - sarta_2_desertdust_small_log2_new_1_May07
% 110 - sarta_2_desertdust_small_log2_newApr07
% 111 - sarta_2_desertdust_small_log2_newMay07
% 112 - sarta_2_gou_seasalt
% 113 - sarta_2_opac_seasalt
% 114 - sarta_2_sand
% 115 - sarta_2_shettle_e_small
% 116 - sarta_2_shettle_o_small
% 117 - sarta_2_solubleaerosol
% 118 - sarta_2_volz_gamma6_small
% 119 - sarta_2_volz_lognormal2_small_absonly
% 120 - sarta_2_volz_lognormal2_small_new
% 121 - sarta_2_volz_lognormal2_small_newApr07
% 122 - sarta_dec05_iceaggr_carb_volz_May09
% 123 - sarta_dec05_iceaggr_iceaggr
% 124 - sarta_dec05_iceaggr_iceaggr.orig
% 125 - sarta_dec05_iceaggr_iceaggr_wcononly
% 126 - sarta_dec05_iceaggr_waterdrop_andesite
% 127 - sarta_dec05_iceaggr_waterdrop_basalt
% 128 - sarta_dec05_iceaggr_waterdrop_biom
% 129 - sarta_dec05_iceaggr_waterdrop_biom_sig1p5_WORKS
% 130 - sarta_dec05_iceaggr_waterdrop_biomWORKS
% 131 - sarta_dec05_iceaggr_waterdrop_carb_Aug08
% 132 - sarta_dec05_iceaggr_waterdrop_gyps_Aug08
% 133 - sarta_dec05_iceaggr_waterdrop_illn_Aug08
% 134 - sarta_dec05_iceaggr_waterdrop_kaol70carb30
% 135 - sarta_dec05_iceaggr_waterdrop_kaol_Aug08
% 136 - sarta_dec05_iceaggr_waterdrop_obsidian
% 137 - sarta_dec05_iceaggr_waterdrop_opac_1_Mar08
% 138 - sarta_dec05_iceaggr_waterdrop_opac_1_May07
% 139 - sarta_dec05_iceaggr_waterdrop_opac_1_May10
% 140 - sarta_dec05_iceaggr_waterdrop_opac_test
% 141 - sarta_dec05_iceaggr_waterdrop_qrtz_Aug08
% 142 - sarta_dec05_iceaggr_waterdrop_volz
% 143 - sarta_dec05_iceaggr_waterdrop_volz_1_Mar08
% 144 - sarta_dec05_iceaggr_waterdrop_volz_1_Mar08_scottversion
% 145 - sarta_dec05_iceaggr_waterdrop_volz_1_May07
% 146 - sarta_dec05_iceaggr_waterdrop_volz_1_May07_100layer_testme
% 147 - sarta_dec05_iceaggr_waterdrop_volz_1_May10
% 148 - sarta_dec05_iceaggr_waterdrop_volz70carb30
% 149 - sarta_dec05_iceaggr_waterdrop_volzApr07
% 150 - sarta_dec05_iceaggr_waterdrop_volz_dumpOD
% 151 - sarta_dec05_iceaggr_waterdrop_volzMay07
% 152 - sarta_dec05_iceaggr_waterdrop_volzMay07_100layer_testme
% 153 - sarta_dec05_opaclog_opaclog_pclsam_1_May07
% 154 - sarta_dec05_sphcirrus_waterdrop_andesite
% 155 - sarta_dec05_sphcirrus_waterdrop_obsidian
% 156 - sarta_dec05_volzlog_volzlog_pclsam
% 157 - sarta_dec05_volzlog_volzlog_pclsam_1_May07
% 158 - sarta_dec05_volzlog_volzlog_pclsamApr07
% 159 - sarta_dec05_volzlog_volzlog_pclsamMay07
% 160 - sarta_iasi_may09_wcon_nte_swch4
% 161 - sarta_iasi_nte_blkcld_gamma1
% 162 - sarta_iasi_sep08_wcon_nte
% 163 - sarta_jan04_pclsam_iceaggr_iceaggr
% 164 - sarta_jan04_pclsam_iceaggr_iceaggr_wcononly
% 165 - sarta_modis
% 166 - sarta_strow_mar06
%
%             2 slab clouds with ctype : 0  - 99 = black 
%                                 100-199 = water
%                                 200-299 = ice
%                                 300-399 = aerosol
%
%  For the 2-Cloud versions:
%
%  Water : p.gas_201, p.ctype=101;
%  Ice   : p.gas_202, p.udef(17,:)=201
%  Dust  : p.gas_201, p.ctype=301;
%



%
% (31) My105solar
%      	   /home/imbiriba/asl/packages/sartaV105/Bin/sarta_jan04_solar 
%          
%          !! Requires 'solar=ddd' input argument.


%
% (101) JPL_V107 - For running on JPL
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Kcarta Run (Not Sarta!!! - Uses the cluster!) 
% 
% (9998) Kcarta_local - Run kCarta V14 - Locally
% (9999) Kcarta - Run kCarta V14 - On the Cluster
%
% Breno Imbiriba - 2007.01.30

  csarta{ 1}='/asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_postNov2003';
  csarta{ 2}='/asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_postNov2003_wcon_nte';
  csarta{ 3}='/asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_preNov2003';
  csarta{ 4}='/asl/packages/sartaV108/BinV201/sarta_airs_PGEv6_preNov2003_wcon_nte';
  
  csarta{ 5}='/asl/packages/sartaV108/BinV201/sarta_apr08_m140';
  csarta{ 6}='/asl/packages/sartaV108/BinV201/sarta_apr08_m140_iceaggr_waterdrop_desertdust_slabcloud_hg3';
  csarta{ 7}='/asl/packages/sartaV108/BinV201/sarta_apr08_m140_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte';
  csarta{ 8}='/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte';
  csarta{ 9}='/asl/packages/sartaV108/BinV201/sarta_apr08_m140_wcon_nte_nh3';
  csarta{10}='/asl/packages/sartaV108/BinV201/sarta_apr08_m140x_370_wcon_nte';
  
  csarta{11}='/asl/packages/sartaV108/BinV201/sarta_crisg4_nov09_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte';
  csarta{12}='/asl/packages/sartaV108/BinV201/sarta_crisg4_nov09_wcon_nte';
  csarta{13}='/asl/packages/sartaV108/BinV201/sarta_crisg4_nov09_wcon_nte_nh3';

  csarta{14}='/asl/packages/sartaV108/BinV201/sarta_iasi_may09_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte_swch4';
  csarta{15}='/asl/packages/sartaV108/BinV201/sarta_iasi_may09_wcon_nte';
  csarta{16}='/asl/packages/sartaV108/BinV201/sarta_iasi_may09_wcon_nte_swch4';
  csarta{17}='/asl/packages/sartaV108/BinV201/sarta_iasi_may09_wcon_nte_swch4_nh3';



  csarta{21}='/asl/packages/sartaV108/BinV105/sarta_apr08_m130_m150';
  csarta{22}='/asl/packages/sartaV108/BinV105/sarta_apr08_m130x_370';
  csarta{23}='/asl/packages/sartaV108/BinV105/sarta_apr08_m130x_m140x_370';
  csarta{24}='/asl/packages/sartaV108/BinV105/sarta_apr08_m130x_m140x_370_exper';
  csarta{25}='/asl/packages/sartaV108/BinV105/sarta_apr08_m140_wcon_nte';
  csarta{26}='/asl/packages/sartaV108/BinV105/sarta_apr08_m140x_370';
  csarta{27}='/asl/packages/sartaV108/BinV105/sarta_apr08_m140x_385';



  csarta{30}='/asl/packages/sartaV108_PGEv6/Bin/sarta_airs_PGEv6_postNov2003';




  csarta{101}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_andesite';
  csarta{102}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_basalt';
  csarta{103}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_ddlognorm';
  csarta{104}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_desertdust';
  csarta{105}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_desertdust_gamma4';
  csarta{106}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_desertdust_small';
  csarta{107}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_desertdust_small_log2_absonly';
  csarta{108}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_desertdust_small_log2_new';
  csarta{109}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_desertdust_small_log2_new_1_May07';
  csarta{110}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_desertdust_small_log2_newApr07';
  csarta{111}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_desertdust_small_log2_newMay07';
  csarta{112}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_gou_seasalt';
  csarta{113}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_opac_seasalt';
  csarta{114}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_sand';
  csarta{115}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_shettle_e_small';
  csarta{116}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_shettle_o_small';
  csarta{117}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_solubleaerosol';
  csarta{118}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_volz_gamma6_small';
  csarta{119}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_volz_lognormal2_small_absonly';
  csarta{120}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_volz_lognormal2_small_new';
  csarta{121}='/home/sergio/SARTA_CLOUDY/Bin/sarta_2_volz_lognormal2_small_newApr07';
  csarta{122}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_carb_volz_May09';
  csarta{123}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_iceaggr';
  csarta{124}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_iceaggr.orig';
  csarta{125}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_iceaggr_wcononly';
  csarta{126}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_andesite';
  csarta{127}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_basalt';
  csarta{128}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_biom';
  csarta{129}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_biom_sig1p5_WORKS';
  csarta{130}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_biomWORKS';
  csarta{131}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_carb_Aug08';
  csarta{132}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_gyps_Aug08';
  csarta{133}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_illn_Aug08';
  csarta{134}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_kaol70carb30';
  csarta{135}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_kaol_Aug08';
  csarta{136}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_obsidian';
  csarta{137}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_opac_1_Mar08';
  csarta{138}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_opac_1_May07';
  csarta{139}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_opac_1_May10';
  csarta{140}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_opac_test';
  csarta{141}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_qrtz_Aug08';
  csarta{142}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_volz';
  csarta{143}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_volz_1_Mar08';
  csarta{144}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_volz_1_Mar08_scottversion';
  csarta{145}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_volz_1_May07';
  csarta{146}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_volz_1_May07_100layer_testme';
  csarta{147}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_volz_1_May10';
  csarta{148}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_volz70carb30';
  csarta{149}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_volzApr07';
  csarta{150}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_volz_dumpOD';
  csarta{151}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_volzMay07';
  csarta{152}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_iceaggr_waterdrop_volzMay07_100layer_testme';
  csarta{153}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_opaclog_opaclog_pclsam_1_May07';
  csarta{154}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_sphcirrus_waterdrop_andesite';
  csarta{155}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_sphcirrus_waterdrop_obsidian';
  csarta{156}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_volzlog_volzlog_pclsam';
  csarta{157}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_volzlog_volzlog_pclsam_1_May07';
  csarta{158}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_volzlog_volzlog_pclsamApr07';
  csarta{159}='/home/sergio/SARTA_CLOUDY/Bin/sarta_dec05_volzlog_volzlog_pclsamMay07';
  csarta{160}='/home/sergio/SARTA_CLOUDY/Bin/sarta_iasi_may09_wcon_nte_swch4';
  csarta{161}='/home/sergio/SARTA_CLOUDY/Bin/sarta_iasi_nte_blkcld_gamma1';
  csarta{162}='/home/sergio/SARTA_CLOUDY/Bin/sarta_iasi_sep08_wcon_nte';
  csarta{163}='/home/sergio/SARTA_CLOUDY/Bin/sarta_jan04_pclsam_iceaggr_iceaggr';
  csarta{164}='/home/sergio/SARTA_CLOUDY/Bin/sarta_jan04_pclsam_iceaggr_iceaggr_wcononly';
  csarta{165}='/home/sergio/SARTA_CLOUDY/Bin/sarta_modis';
  csarta{166}='/home/sergio/SARTA_CLOUDY/Bin/sarta_strow_mar06';
  %

  csarta{1000}='/somewhere/in/JPL/path/sarta';
  csarta{8888}='CUSTOM_CASE';  
  csarta{9998}='KCARTA_LOCAL';
  csarta{9999}='KCARTA';

  % distinguish calls via number of arguments:
  lreaddata=false;
  lsavedata=false;
  opt='';

  if    ( (nargin==2 & nargout==4) | (nargin==2 & nargout==1) )
    fin=a1;  
    isarta=a2;
    lreaddata=true;
    lsavedata=false;
  elseif(nargin==3 & nargout==4)
    fin=a1;
    isarta=a2;
    lreaddata=true;
    lsavedata=false; 
    opt=a3;
  elseif(nargin==3 & nargout==0)
    fin=a1;
    fout=a2;
    isarta=a3;
    lreaddata=true;
    lsavedata=true;
  elseif(nargin==4 & nargout==0)
    fin=a1;
    fout=a2;
    isarta=a3;
    lreaddata=true;
    lsavedata=true;
    opt=a4;
  elseif(nargin==5 & nargout==4)
    h1=a1;
    h1a=a2;
    p1=a3;
    p1a=a4;
    isarta=a5;
    lreaddata=false;
    lsavedata=false;
  elseif(nargin==6 & nargout==4)
    h1=a1;
    h1a=a2;
    p1=a3;
    p1a=a4;
    isarta=a5;
    lreaddata=false;
    lsavedata=false;
    opt=a6;
  elseif(nargin==6 & nargout==0)
    h1=a1;
    h1a=a2;
    p1=a3;
    p1a=a4;
    fout=a5;
    isarta=a6;
    lreaddata=false;
    lsavedata=true;
  elseif(nargin==7 & nargout==0)
    h1=a1;
    h1a=a2;
    p1=a3;
    p1a=a4;
    fout=a5;
    isarta=a6;
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

%  if(nargin==2)
%    if(nargout~=4 & nargout~=1 & ~(nargout==0 & strcmp(a1,'')))
%      warning('Wrong number of return arguments.\n');
%      return
%    end
%    fin=a1;  
%    isarta=a2;
%    lreaddata=true;
%    lsavedata=false;
%  elseif(nargin==3)
%    if(nargout~=0)
%      warning('Wrong number of return arguments.\n');
%      return
%    end 
%  elseif(nargin==3 & nargout==0)
%    fin=a1;
%    fout=a2;
%    isarta=a3;
%    lreaddata=true;
%    lsavedata=true;
%  elseif(nargin==5)
%    if(nargout~=4)
%      warning('Wrong number of return arguments.\n');
%      return
%    end 
%   h1=a1;
%   h1a=a2;
%   p1=a3;
%   p1a=a4;
%   isarta=a5;
%   lreaddata=false;
%   lsavedata=false;
% elseif(nargin==6)
%   if(nargout~=0)
%     warning('Wrong number of return arguments.\n');
%     return
%   end 
%   h1=a1;
%   h1a=a2;
%   p1=a3;
%   p1a=a4;
%   fout=a5;
%   isarta=a6;
%   lreaddata=false;
%   lsavedata=true;
% else
%   warning('Wrong number of input arguments.\n');
%   return
% end 

  % new piece of code:
  % isarta may be a string with arguments, like '107_dec05 lrhot=true'
  % Will separate the actual sarta command from the argument.


  line_arguments='';
  if(ischar(isarta))
    sspace=strfind(isarta,' ');
    if(length(sspace)>0)
      line_arguments=isarta(sspace(1):end);
      isarta=isarta(1:sspace(1)-1);
    else 
    end
  end 

  % Now a trick. If the sarta name is just one charactere, guess that it's 
  % a number coded as a char and retrieve the number
  if(length(isarta)==1)
    isarta=isarta*1;
  end

  if(ischar(isarta))
    if(isarta(1)=='!')
      csarta{8888} = isarta(2:end); %CUSTOM CASE
      if(~exist(csarta{8888},'file'))
        error(['Curtom Sarta code ' csarta{8888} ' does not exist.']);
      end
      isarta=8888;

      %
% Sarta V108 - BinV201 (/asl/packages/sartaV108/BinV201/)
%
    elseif(strcmp(isarta,'sarta_airs_PGEv6_postNov2003'))
      isarta=(1);
    elseif(strcmp(isarta,'sarta_airs_PGEv6_postNov2003'))
      isarta=1;
    elseif(strcmp(isarta,'sarta_airs_PGEv6_postNov2003_wcon_nte'))
      isarta=2;
    elseif(strcmp(isarta,'sarta_airs_PGEv6_preNov2003'))
      isarta=3;
    elseif(strcmp(isarta,'sarta_airs_PGEv6_preNov2003_wcon_nte'))
      isarta=4;
%
    elseif(strcmp(isarta,'sarta_apr08_m140'))
      isarta=5;
    elseif(strcmp(isarta,'sarta_apr08_m140_iceaggr_waterdrop_desertdust_slabcloud_hg3'))
      isarta=6;
    elseif(strcmp(isarta,'sarta_apr08_m140_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte'))
      isarta=7;
    elseif(strcmp(isarta,'sarta_apr08_m140_wcon_nte'))
      isarta=8;
    elseif(strcmp(isarta,'sarta_apr08_m140_wcon_nte_nh3'))
      isarta=9;
    elseif(strcmp(isarta,'sarta_apr08_m140x_370_wcon_nte'))
      isarta=10;
%
    elseif(strcmp(isarta,'sarta_crisg4_nov09_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte'))
      isarta=11;
    elseif(strcmp(isarta,'sarta_crisg4_nov09_wcon_nte'))
      isarta=12;
    elseif(strcmp(isarta,'sarta_crisg4_nov09_wcon_nte_nh3'))
      isarta=13;
%
    elseif(strcmp(isarta,'sarta_iasi_may09_iceaggr_waterdrop_desertdust_slabcloud_hg3_wcon_nte_swch4'))
      isarta=14;
    elseif(strcmp(isarta,'sarta_iasi_may09_wcon_nte'))
      isarta=15;
    elseif(strcmp(isarta,'sarta_iasi_may09_wcon_nte_swch4'))
      isarta=16;
    elseif(strcmp(isarta,'sarta_iasi_may09_wcon_nte_swch4_nh3'))
      isarta=17;
%
%
% Sarta V108 - BinV105 (/asl/packages/sartaV108/BinV105/)
%
    elseif(strcmp(isarta,'sarta_apr08_m130_m150'))
      isarta=21;
    elseif(strcmp(isarta,'sarta_apr08_m130x_370'))
      isarta=22;
    elseif(strcmp(isarta,'sarta_apr08_m130x_m140x_370'))
      isarta=23;
    elseif(strcmp(isarta,'sarta_apr08_m130x_m140x_370_exper'))
      isarta=24;
    elseif(strcmp(isarta,'sarta_apr08_m140_wcon_nte'))
      isarta=25;
    elseif(strcmp(isarta,'sarta_apr08_m140x_370'))
      isarta=26;
    elseif(strcmp(isarta,'sarta_apr08_m140x_385'))
      isarta=27;
%
% Sarta V108_PGEv6_postNov2003 - (/asl/packages/sartaV108_PGEv6/Bin)
%
    elseif(strcmp(isarta,'sarta_airs_PGEv6_postNov2003'))
      isarta=30;
%
%
% SERGIO Sarta codes - (/home/sergio/SARTA_CLOUDY/Bin/)
%
    elseif(strcmp(isarta,'sarta_2_andesite'))
      isarta=101;
    elseif(strcmp(isarta,'sarta_2_basalt'))
      isarta=102;
    elseif(strcmp(isarta,'sarta_2_ddlognorm'))
      isarta=103;
    elseif(strcmp(isarta,'sarta_2_desertdust'))
      isarta=104;
    elseif(strcmp(isarta,'sarta_2_desertdust_gamma4'))
      isarta=105;
    elseif(strcmp(isarta,'sarta_2_desertdust_small'))
      isarta=106;
    elseif(strcmp(isarta,'sarta_2_desertdust_small_log2_absonly'))
      isarta=107;
    elseif(strcmp(isarta,'sarta_2_desertdust_small_log2_new'))
      isarta=108;
    elseif(strcmp(isarta,'sarta_2_desertdust_small_log2_new_1_May07'))
      isarta=109;
    elseif(strcmp(isarta,'sarta_2_desertdust_small_log2_newApr07'))
      isarta=110;
    elseif(strcmp(isarta,'sarta_2_desertdust_small_log2_newMay07'))
      isarta=111;
    elseif(strcmp(isarta,'sarta_2_gou_seasalt'))
      isarta=112;
    elseif(strcmp(isarta,'sarta_2_opac_seasalt'))
      isarta=113;
    elseif(strcmp(isarta,'sarta_2_sand'))
      isarta=114;
    elseif(strcmp(isarta,'sarta_2_shettle_e_small'))
      isarta=115;
    elseif(strcmp(isarta,'sarta_2_shettle_o_small'))
      isarta=116;
    elseif(strcmp(isarta,'sarta_2_solubleaerosol'))
      isarta=117;
    elseif(strcmp(isarta,'sarta_2_volz_gamma6_small'))
      isarta=118;
    elseif(strcmp(isarta,'sarta_2_volz_lognormal2_small_absonly'))
      isarta=119;
    elseif(strcmp(isarta,'sarta_2_volz_lognormal2_small_new'))
      isarta=120;
    elseif(strcmp(isarta,'sarta_2_volz_lognormal2_small_newApr07'))
      isarta=121;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_carb_volz_May09'))
      isarta=122;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_iceaggr'))
      isarta=123;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_iceaggr.orig'))
      isarta=124;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_iceaggr_wcononly'))
      isarta=125;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_andesite'))
      isarta=126;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_basalt'))
      isarta=127;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_biom'))
      isarta=128;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_biom_sig1p5_WORKS'))
      isarta=129;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_biomWORKS'))
      isarta=130;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_carb_Aug08'))
      isarta=131;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_gyps_Aug08'))
      isarta=132;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_illn_Aug08'))
      isarta=133;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_kaol70carb30'))
      isarta=134;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_kaol_Aug08'))
      isarta=135;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_obsidian'))
      isarta=136;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_opac_1_Mar08'))
      isarta=137;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_opac_1_May07'))
      isarta=138;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_opac_1_May10'))
      isarta=139;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_opac_test'))
      isarta=140;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_qrtz_Aug08'))
      isarta=141;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_volz'))
      isarta=142;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_volz_1_Mar08'))
      isarta=143;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_volz_1_Mar08_scottversion'))
      isarta=144;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_volz_1_May07'))
      isarta=145;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_volz_1_May07_100layer_testme'))
      isarta=146;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_volz_1_May10'))
      isarta=147;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_volz70carb30'))
      isarta=148;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_volzApr07'))
      isarta=149;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_volz_dumpOD'))
      isarta=150;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_volzMay07'))
      isarta=151;
    elseif(strcmp(isarta,'sarta_dec05_iceaggr_waterdrop_volzMay07_100layer_testme'))
      isarta=152;
    elseif(strcmp(isarta,'sarta_dec05_opaclog_opaclog_pclsam_1_May07'))
      isarta=153;
    elseif(strcmp(isarta,'sarta_dec05_sphcirrus_waterdrop_andesite'))
      isarta=154;
    elseif(strcmp(isarta,'sarta_dec05_sphcirrus_waterdrop_obsidian'))
      isarta=155;
    elseif(strcmp(isarta,'sarta_dec05_volzlog_volzlog_pclsam'))
      isarta=156;
    elseif(strcmp(isarta,'sarta_dec05_volzlog_volzlog_pclsam_1_May07'))
      isarta=157;
    elseif(strcmp(isarta,'sarta_dec05_volzlog_volzlog_pclsamApr07'))
      isarta=158;
    elseif(strcmp(isarta,'sarta_dec05_volzlog_volzlog_pclsamMay07'))
      isarta=159;
    elseif(strcmp(isarta,'sarta_iasi_may09_wcon_nte_swch4'))
      isarta=160;
    elseif(strcmp(isarta,'sarta_iasi_nte_blkcld_gamma1'))
      isarta=161;
    elseif(strcmp(isarta,'sarta_iasi_sep08_wcon_nte'))
      isarta=162;
    elseif(strcmp(isarta,'sarta_jan04_pclsam_iceaggr_iceaggr'))
      isarta=163;
    elseif(strcmp(isarta,'sarta_jan04_pclsam_iceaggr_iceaggr_wcononly'))
      isarta=164;
    elseif(strcmp(isarta,'sarta_modis'))
      isarta=165;
    elseif(strcmp(isarta,'sarta_strow_mar06'))
      isarta=166;

    elseif(strcmp(isarta,'JPL_V107'))
      isarta=1000; 

    elseif(strcmp(isarta,'Kcarta_local'))
      isarta=(9998);
    elseif(strcmp(isarta,'Kcarta'))
      isarta=(9999);
    else
      warning('isarta is an invalid string: %s.', isarta)
      isarta=1;
      return
    end
  end  

  if(isarta<1 | isarta>length(csarta))
    warning('isarta argument invalid: %i.',isarta);
    isarta=1;
  end

  if(exist('fin','var') && length(fin)==0)
    h=csarta{isarta};
    return;
  end

%  Not important anymore - we'll use all kinds of SARTAs
%  % TEMPORARY - Fail if asking for the wrong sarta
%  if(isarta~=1);
%%    warning('SartaRun: Warning - YOU ARE NOT RUNNING SARTA V107 (sarta=1)');
%    fprintf('SartaRun: You are running sarta %d - %s\n',isarta, csarta{isarta});
%  end
  % Generate random temporaty names.

  if(isarta==9999 | isarta==9998) % kCarta - save locally
    locdir=pwd;
    tempdir='./'
    fname1=mktemp(locdir,'SartaRun.rtp');
    fname2=mktemp(locdir,'SartaRun.rtp');
  else
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
    fname1=mktemp(tempdir,'SartaRun.rtp');
    fname2=mktemp(tempdir,'SartaRun.rtp');
  end
  %tempname1=[ num2str(floor(100000000*rand)) '.rtp'];
  %tempname2=[ num2str(floor(100000000*rand)) '.rtp'];
  Sys_rm(fname1);
  Sys_rm(fname2);


  % Routine Core - 

  if(lreaddata) % Read data from file - if needed

    [h1 h1a p1 p1a]=rtpread_all(fin);
  end

  % Save data into temporay files
  ofnames=rtpwrite_all(fname1, h1,h1a,p1,p1a);

  % loop over the files
  if(numel(ofnames)==1) % AIRS (single file) -------------
    fitmp{1}=ofnames{1};
    fotmp{1}=fname2;
    sarta_dump{1} = mktemp(tempdir,'sarta_dump');
    core_sarta_run(fitmp{1},fotmp{1}, sarta_dump{1});

  else % ----- 
    for iff=1:numel(ofnames) 
      fitmp{iff}=ofnames{iff};
      fotmp{iff}=[fname2 '_' num2str(iff)];
      sarta_dump{iff} = mktemp(tempdir,'sarta_dump');

      core_sarta_run(fitmp{iff}, fotmp{iff}, sarta_dump{iff});
    end
  end

  % Read output data:
  [h ha p pa]=rtpread_all(fname2);

  % If needed, save data:
  if(lsavedata)
    rtpwrite_all(fout,h,ha,p,pa);
  end

  % Delete files:
  for iff=1:numel(ofnames)
    Sys_rm(fitmp{iff});
    Sys_rm(fotmp{iff});
    Sys_rm(sarta_dump{iff});
  end


%%%%%%%%%%%%%%%%%%%%%%%
%  main sarta run code

function core_sarta_run(fitmp,fotmp,sarta_dump)

%    fitmp{1}=ofnames{1};
%    fotmp{1}=fname2;

  % Run Sarta
  if(~exist(fitmp,'file'))
    disp(['Wowa... file ' fitmp ' which was created before, does not exist!']);
    error('Some fucked up I/O problem here');
  end

  % If this is a KcartaRun:
  if(isarta==9999)
    disp('This is a KcartaRun. Calling KcartaRun_on_cluster.m');
    KcartaRun_on_cluster(fitmp,fotmp);
  elseif(isarta==9998)
    disp('This is a KcartaRun. Calling KcartaRun locally.');
    KcartaRun_chunks(fitmp,fotmp);
  else

  cmd=[ csarta{isarta} ' ' line_arguments ' fin=' fitmp ' fout=' fotmp ' 2>&1 > ' sarta_dump];
  % DEBUG LINE - Commented out
  %fprintf('%s\n',cmd);

  % try to run sarta up to 3 times
  for itries=1:3
    [status1 result1]=system(cmd);
    [status2 result2]=system(['/asl/packages/rtpV201/bin/rtpdump ' fotmp]);

    if(~exist(fotmp,'file') | status2~=0)
      fprintf('******************************\n');
      fprintf('SartaRun: Error Running Sarta.\n');
      fprintf('******************************\n');
      disp(['status = ' num2str(status1)]);
      idx1=min(1000,numel(result1));
      disp(['result = ' result1(1:idx1)]);
      idx2=min(1000,numel(result2));
      disp(['rtpdmp = ' result2(1:idx2)]);
      %fprintf('****** start dump **************\n');
      %system(['cat ' sarta_dump]);
      %fprintf('****** end * dump **************\n');
      system(['ls -l ' csarta{isarta} ]);
      system(['ls -l ' fitmp ]);
      system(['ls -l ' fotmp ]);
      system(['df -H ' fitmp ]);
      fprintf('******** trying once more ******\n');
      system('sleep 3');
    else 
      break
    end
    if(~exist(fitmp,'file'))
      disp(['Wowa... file ' fitmp ' which I did check for its existence, is not here anymore!!!']);
      error('Some fucked up I/O problem here');
    end
  end

  end % if kcarta run

end


end
