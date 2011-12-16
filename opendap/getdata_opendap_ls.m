function results = getdata_opendap_ls(url,preface)
%
% A simple function that takes a url string a returns a list of available
% files in full URL format
%

%url = 'http://airscal1u.ecs.nasa.gov/opendap/Aqua_AIRS_Level1/AIRIBRAD.005/2007/055/';

if(url(end) ~= '/')
    url = [url '/'];
end

disp(['url_ls ' url])

g = urlread(url);
results = regexpi(g,'[a-z0-9-_.]*.hdf.info','match');

for i = 1:length(results)
    if nargin == 2
        results{i} = [preface results{i}(1:end-5)];
    else
        results{i} = [url results{i}(1:end-5)];
    end
end