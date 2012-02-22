function prof = strong_filter(head,prof,reason);
%function prof = strong_filter(head,prof,reason);

if ~isfield(prof,'robs1'); return; end

%        1231 2616 822 961 790  cm-1
tchan = [1291 2333 532  903 445];

solzen = prof.solzen;
landfrac = prof.landfrac;
robs1 = prof.robs1(tchan,:);
rcalc = prof.rcalc(tchan,:);
f = head.vchan(tchan);


    bias = rad2bt(f,robs1) - rad2bt(f,rcalc);

inight = find( mod(reason,2) == 1 & solzen >  90 & landfrac < 0.001);
iday   = find( mod(reason,2) == 1 & solzen <= 90 & landfrac < 0.001);

kn = find( abs(bias(2,inight))  < 3  & abs(bias(4,inight)-bias(3,inight)) < 0.4 & abs(bias(5,inight)) < 3);
kd = find( abs(bias(1,iday))    < 3  & abs(bias(4,iday)-bias(3,iday))     < 0.4 & abs(bias(5,iday)) < 3);

ikeep = [inight(kn) iday(kd)];
plist = sort(ikeep);

%keyboard
if isempty(plist)
  prof = mkdummy_rtp(prof,0);
else
  [head, prof]=subset_rtp(head, prof, [], [], plist);
end

return
