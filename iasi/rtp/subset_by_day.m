iasi_paths
a=[1021        2345        3476        4401];

for f = findfiles(['/asl/data/rtprod_iasi/' datestr(JOB(1),'yyyy/mm/dd') '/ecm.iasi_l1c_full.*.v1.rtp_1Z'])
  if exist([dirname(f{1}) '/strowsubset_' basename(f{1})],'file');
    disp([dirname(f{1}) '/strowsubset_' basename(f{1})])
    [head1 hattr1 prof1 pattr1] = rtpread([dirname(f{1}) '/strowsubset_' basename(f{1})]);
  else
    disp(f{1})
    [head1 hattr1 prof1 pattr1] = rtpread_12(f{1});
    [head1 hattr1 prof1 pattr1] = rtpgrow(head1,hattr1,prof1,pattr1);
    [head1 prof1] = subset_rtp(head1,prof1,[],a,[])
    rtpwrite([dirname(f{1}) '/strowsubset_' basename(f{1})],head1,hattr1,prof1,pattr1);
  end
  
  if exist('head','var')
    [head prof] = cat_rtp(head, prof, head1, prof1);
  else
    head = head1;
    prof = prof1;
  end

end
save([dirname(f{1}) '/ecm.strowsubset_' datestr(JOB(1),'yyyymmdd') '.mat'],'-struct','prof')
%rtpwrite([dirname(f{1}) '/ecm.strowsubset_' datestr(JOB(1),'yyyymmdd') '.rtp'],head,hattr1,prof,pattr1);
