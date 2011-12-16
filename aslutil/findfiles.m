function [ret dates bytes] = findfiles(search_path,name_pattern)
% A function that returns a cell array of files matching a specified pattern.
%
% Usage:  f = files('/tmp');          % returns all files in /tmp and subfolders there of
%         f = files('/tmp/*.mat');    % returns all files in a dir matching the pattern
%         f = files('/tmp','*.mat');  % recursively searches a tree for the pattern *.mat
%
% By default the function searches recursively

% Written by Paul Schou - 1 July 2009  (paulschou.com)

% if the first argument is a directory and doesn't end in / then add a / for printing
if(exist(search_path,'dir') & search_path(end) ~= '/')
    search_path = [search_path '/'];
end

recurse = 1;  % default to recursive
if(nargin == 1);
    if exist(search_path,'dir') % if one arg is given and it is a directory, find everything
        name_pattern = '*';
    else
        [search_path name_pattern ext]= fileparts(search_path);
        if length(search_path) == 0; search_path = './'; end
        name_pattern = [name_pattern ext];
        recurse = 0;
    end
end
%if(search_path(end) ~= '/')
%    search_path = strcat(search_path,'/');
%end

% if more than one directory level has a * then break apart the parts
ret = [];
dates = [];
bytes = [];
if any(search_path == '*')
    mkpath = [];
    if search_path(1) == '/'; mkpath = '/'; end % if the path is absolute
    [left right]=strtok(search_path,'/');
    while length(left)
      if any(left == '*')
        g = dir([mkpath left]);
        for i = 1:size(g,1)
          if(g(i).isdir & ~strcmp(g(i).name(1),'.'))
            [r d b] = findfiles([mkpath g(i).name right],name_pattern);
            ret = [ret, r];
            dates = [dates, d];
            bytes = [bytes, b];
          end
        end
        return
      end
      mkpath = [mkpath left '/'];
      [left right]=strtok(right,'/');
    end 
end

% asthetics of a tailing directory slash
if ~isempty(search_path) && strcmp(search_path(end),'/')
  search_path = search_path(1:end-1);
end

% search for files in the current directory
ret = {};
dates = [];
bytes = [];
g = dir([search_path '/' name_pattern]);
for i = 1:size(g,1)
    if(~g(i).isdir & ~strcmp(g(i).name(1),'.'))
        ret = [ret, strcat([search_path '/'], g(i).name)];
        dates = [dates,  g(i).datenum];
        bytes = [bytes,  g(i).bytes];
    end
end

% search sub directories if recursive
if(recurse)
    g = dir(search_path);
    for i = 1:size(g,1)
        if(g(i).isdir & ~strcmp(g(i).name(1),'.'))
            [r d b] = findfiles([search_path '/' g(i).name],name_pattern);
            ret = [ret, r];
            dates = [dates, d];
            bytes = [bytes, b];
        end
    end
end
