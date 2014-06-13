
 dd='/asl/data/rtprod_airs/2011/03/11/';
 rt='airs_l1b.ecmwf.umw.calc.2011.03.11.';
 sf='.R1.9l-M1.9k.rtpZ';
 tms=[0:6:(24*60-6)];
 for it=1:240;
   fn=[dd rt datestr(tms(it)/60/24,'HHMMSS') '_' datestr((tms(it)+6)/60/24,'HHMMSS') sf];

   if(exist(fn,'file'))
     disp(['Processing file ' fn]);

     [h ha p pa] = rtpread_all(fn);

     iclr = find(bitand(p.iudef(1,:),1)==1);

     disp(['Keeping ' num2str(numel(iclr)) ' profiles']);
     if(numel(iclr)>0)
       [hc pc] = subset_rtp(h,p,[],[],iclr);

       pp(it).rlat    = pc.rlat;
       pp(it).rlon    = pc.rlon;
       pp(it).stemp   = pc.stemp;
       pp(it).solzen  = pc.solzen;
       pp(it).scanang = pc.scanang;
       pp(it).satzen  = pc.satzen;
       pp(it).rtime   = pc.rtime;
       pp(it).robs1   = pc.robs1;
       pp(it).rcalc   = pc.rcalc;
       pp(it).reason  = pc.iudef(1,:);

     end
     clear h p
   else
     disp(['File ' fn ' does not exist']);
   end

 end
 
 pp = Prof_join_arr(pp);

 save('/asl/data/rtprod_airs/2011/03/11/airs_l1b.ecmwf.umw.calc.clear.2011.03.11.R1.9l-M1.9k.rtp','h','ha','pp','pa');





