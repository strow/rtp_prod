function [out,varargout] = meanbin(dat, bin_size, start_bin,style)
%MEANBIN   Moving average with bin sizes
%
%   MEANBIN(X, BIN_SIZE, BIN_START, STYLE) takes the moving mean along the 
%       first dimension of X starting at positions START_BIN with the bin 
%       size of BIN_SIZE.
%
%       STYLE arguments
%           'linear'    Moving average (default)
%           'circle'    does a circular average, the binsize is the 
%                       diameter of the circle of the moving average.
%           'square'    length of the side of square to do the moving
%                       average with.
%           'block'     data is chunked starting at BIN_START and stepping 
%                       by BIN_SIZE.  
%           'hardblock' A modification of 'block' which returns a condensed 
%                       matrix.  
%
%       A standard deviation can be acquired by using two output vars like
%       [MEAN_DAT, STD_DAT] = MEANBIN(X, BIN_SIZE, BIN_START, STYLE) .
%
%       An alternate usage when there is only one bin size to be used:
%           MEANBIN(X, BIN_SIZE, STYLE)
%
%   Class support for input X:
%       float: double, single
%
%   Example usage:
%       figure
%       dat=rand(50,1);
%       plot([dat,meanbin(dat, 5),meanbin(dat, 10)])
%       legend('orig 1','meanbin 5','meanbin 10')
%
%       figure
%       dat=rand(50);
%       imagesc(meanbin(dat, [1 5 10], [1 15 30]))
%
%       % To use circles for the averaging area
%       figure
%       dat=rand(50);
%       imagesc(meanbin(dat, [1 5 10], [1 15 30],'circle'))
%
%   See also MEAN, MEDIAN, STD.

%   Copyright 2006 Paul Schou (paulschou.com) 
%   $Revision: 1.6 $  $Date: 2006/07/11 15:40:26 $

if(nargin < 2 | length(bin_size) < 1)
    error('binsize needs to be specified');
end
if(nargin == 2)
    start_bin = 1;
end

if nargin < 4
    style = 'linear';
end

if(isstr(start_bin))
    style = start_bin;
    start_bin = 1;
else
    if(length(start_bin) ~= length(bin_size))
        error('start_bin should be the same size as the bin_size');
    end
end

if size(dat,1) == 1
    dat = dat';
    rot = 1;
else
    rot = 0;
end

out = zeros(size(dat));
if nargout > 1
    stdout = zeros(size(dat));
end

if strcmpi(style,'linear')
    % linear
    for i=1:length(bin_size)
        st = start_bin(i);
        if i < length(start_bin)
            en = start_bin(i+1)-1;
        else
            en = size(dat,1);
        end
        % the extra floor statements here deal with the even numbers
        for j = -floor(bin_size(i)/2-.5):floor(bin_size(i) / 2)
            sel = min(max((st:en)+j,1),size(dat,1));
            tmp = dat(sel,:);
            out(st:en,:) = out(st:en,:) + tmp;
        end
        out(st:en,:) = out(st:en,:) / bin_size(i);
        if nargout > 1
            for j = -floor(bin_size(i)/2-.5):floor(bin_size(i) / 2)
                sel = min(max((st:en)+j,1),size(dat,1));
                tmp = dat(sel,:);
                stdout(st:en,:) = stdout(st:en,:) + (out(st:en,:) - tmp).^2;
            end
            stdout(st:en,:) = sqrt(stdout(st:en,:) / bin_size(i));
        end
    end
end

if strcmpi(style,'circle')
    % if the dataset is 2d
    for i=1:length(bin_size)
        st = start_bin(i);
        if i < length(start_bin)
            en = start_bin(i+1)-1;
        else
            en = size(dat,1);
        end
        sel = -floor(bin_size(i)/2-.5):floor(bin_size(i) / 2);
        [x,y]=meshgrid(sel,sel);
        % we need to adjust the mesh a bit for even numbers
        if mod(bin_size,2) == 0
            x = x - .5;
            y = y - .5;
        end
        sel = sqrt(x.^2+y.^2) <= (bin_size(i)/2-.25);
        % debug: print out `sel' to see the selection grid(s) used:
        %sel
        os = -floor(bin_size(i)/2-.5):floor(bin_size(i) / 2);
        for j = 1:bin_size(i)
            for k = 1:bin_size(i)
                if sel(j,k) > 0
                    y = min(max( (st:en)+os(j) ,1),size(dat,1));
                    x = min(max( (1:size(dat,2))+os(k) ,1),size(dat,2));
                    out(st:en,:) = out(st:en,:) + dat(y,x);
                end
            end
        end
        out(st:en,:) = out(st:en,:) / sum(sum(sel));
        if nargout > 1
            for j = 1:bin_size(i)
                for k = 1:bin_size(i)
                    if sel(j,k) > 0
                        y = min(max( (st:en)+os(j) ,1),size(dat,1));
                        x = min(max( (1:size(dat,2))+os(k) ,1),size(dat,2));
                        stdout(st:en,:) = stdout(st:en,:) + (out(st:en,:) - dat(y,x)).^2;
                    end
                end
            end
            stdout(st:en,:) = sqrt(stdout(st:en,:) / sum(sum(sel)));
        end
    end
end


if strcmpi(style,'square')
    % if the dataset is 2d
    for i=1:length(bin_size)
        st = start_bin(i);
        if i < length(start_bin)
            en = start_bin(i+1)-1;
        else
            en = size(dat,1);
        end
        os = -floor(bin_size(i)/2-.5):floor(bin_size(i) / 2);
        for j = 1:bin_size(i)
            for k = 1:bin_size(i)
                    y = min(max( (st:en)+os(j) ,1),size(dat,1));
                    x = min(max( (1:size(dat,2))+os(k) ,1),size(dat,2));
                    out(st:en,:) = out(st:en,:) + dat(y,x);
            end
        end
        out(st:en,:) = out(st:en,:) / bin_size(i)^2;
        if nargout > 1
            for j = 1:bin_size(i)
                for k = 1:bin_size(i)
                    y = min(max( (st:en)+os(j) ,1),size(dat,1));
                    x = min(max( (1:size(dat,2))+os(k) ,1),size(dat,2));
                    stdout(st:en,:) = stdout(st:en,:) + (out(st:en,:) - dat(y,x)).^2;
                end
            end
            stdout(st:en,:) = sqrt(stdout(st:en,:) / bin_size(i)^2);
        end
    end
end

if strcmpi(style,'block')
    % block wise
    for i=1:length(bin_size)
        st = start_bin(i);
        if i < length(start_bin)
            en = start_bin(i+1)-1;
        else
            en = size(dat,1);
        end
        for j = st:bin_size(i):en
            t = dat(j:min(j+bin_size(i)-1,en),:);
            out(j:j+size(t,1)-1,:) = repmat(mean(t,1),size(t,1),1);
            if nargout > 1
                stdout(j:j+size(t,1)-1,:) = repmat(std(t,1,1),size(t,1),1);
            end
        end
        %out(st:en,:) = out(st:en,:) / sum(sum(sel));
    end    
end

if strcmpi(style,'hardblock')
    clear out
    clear stdout
    k = 1;
    % block wise
    for i=1:length(bin_size)
        st = start_bin(i);
        if i < length(start_bin)
            en = start_bin(i+1)-1;
        else
            en = size(dat,1);
        end

        for j = st:bin_size(i):en
            t = dat(j:min(j+bin_size(i)-1,en),:);
            out(k,:) = mean(t,1);
            if nargout > 1
                stdout(k,:) = std(t,1,1);
            end
            k = k + 1;
        end
        %out(st:en,:) = out(st:en,:) / sum(sum(sel));
    end    
end

if rot == 1
    out = out';
    if nargout > 1
        stdout = stdout';
    end
end

if nargout > 1
    varargout = { stdout };
end