addpath /asl/matlib/rtptools
addpath /asl/matlib/h4tools
addpath /asl/matlib/aslutil/

%[h,ha,p,pa] = rtpread('/asl/data/rtprod_old/2007/02/24/allfov111.rtp');
[h,ha,p,pa] = rtpread('/asl/data/rtprod_old/2007/02/24/allfov110.rtp');
%[h,ha,p,pa] = rtpread('/asl/data/rtprod_old/2007/02/24/allfov231.rtp');
%[h,ha,p,pa] = rtpread('/asl/data/rtprod_old/2007/02/24/allfov001.rtp');
%[h,ha,p,pa] = rtpread('/asl/data/rtprod_old/2007/02/24/allfov002.rtp');
[h,ha,p,pa] = rtpread('/asl/data/rtprod_old/2007/02/24/allfov003.rtp');

px = driver_gentemann_dsst(h,ha,p,pa);
scatter(px.rlon,px.rlat,20,px.stemp-p.stemp); title('dsst')