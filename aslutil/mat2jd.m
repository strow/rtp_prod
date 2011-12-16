function jd = mat2jd(mdate)

[yy xx xx] = datevec(mdate);
jd = mdate - datenum(yy,1,1)+1;
