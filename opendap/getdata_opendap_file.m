function varargout = getdata_opendap_file(file)
% Usage: getdata_opendap_file(file)
%
% file - predownloaded opendap file
%
% note all fields must be known/predefinied and in order to retrieve data from the file correctly
%


%disp([url '.dods?' field])

types = [];
var_dims = [];
count = 1;
h=fopen(file,'r','ieee-be');
for i=1:30
    str = fgets(h);
    if(strcmp(['Data:'],str(1:5)))
        break
    end
    
    % clear out spaces
    s = str(str ~= ' ');
    
    if ~ischar(s)
        continue
    end
    re = regexp(str,'= \d*]','match'); % Dies if improper dimensionality is requested
    dims = [];
    for j = 1:length(re)
        dims(length(re) - j + 1) = str2num(re{j}(2:end-1));
    end
    
    if length(dims) < 1
        continue
    end

    if(strcmp('Float64',s(1:7)))
        types(count) = 82;
        var_dims{count} = dims;
        count = count + 1;
    elseif(strcmp('Float32',s(1:7)))
        types(count) = 42;
        var_dims{count} = dims;
        count = count + 1;
    end
    
    if(strcmp('Byte',s(1:4)))
        types(count) = 10;
        var_dims{count} = dims;
        count = count + 1;
    elseif(strcmp('Int8',s(1:4)))
        types(count) = 11;
        var_dims{count} = dims;
        count = count + 1;
    elseif(strcmp('Int16',s(1:5)))
        types(count) = 21;
        var_dims{count} = dims;
        count = count + 1;
    elseif(strcmp('Int32',s(1:5)))
        types(count) = 41;
        var_dims{count} = dims;
        count = count + 1;
    elseif(strcmp('Int64',s(1:5)))
        types(count) = 81;
        var_dims{count} = dims;
        count = count + 1;
    end
end

%types
%var_dims

for i = 1:length(types)
    dims = fread(h,2,'int32');
    if dims(1) ~= dims(2)
      % A weird thing in OpenDAP, that two 0 bytes get inserted in the binary stream...
      %   to avoid running into trouble let's skip these.  This normally shows up after type 10.
      %disp('padding')
      fseek(h,-6,0);
      dims = fread(h,2,'int32');
    end

    if length(var_dims{i}) == 1; var_dims{i} = [var_dims{i} 1]; end %make 2d
    if prod(var_dims{i}) ~= dims(1)
        error(['getdata_opendap:  Dimensions on OpenDAP request field ' num2str(i) ' is not consistent with what was returned.']);
    end

    if(types(i) == 82)
        varargout(i) = {reshape(fread(h,dims(1),'float64'),var_dims{i})};
    elseif(types(i) == 42)
        varargout(i) = {reshape(fread(h,dims(1),'float32'),var_dims{i})};
    elseif(types(i) == 10)
        varargout(i) = {reshape(fread(h,dims(1),'uint8'),var_dims{i})};
        % normally two bytes are padded here (very odd!)
    elseif(types(i) == 11)
        varargout(i) = {reshape(fread(h,dims(1),'int8'),var_dims{i})};
    elseif(types(i) == 21)
        varargout(i) = {reshape(fread(h,dims(1),'int32'),var_dims{i})};
    elseif(types(i) == 41)
        varargout(i) = {reshape(fread(h,dims(1),'int32'),var_dims{i})};
    elseif(types(i) == 81)
        varargout(i) = {reshape(fread(h,dims(1),'int64'),var_dims{i})};
    end
end
%dat = fread(h,inf);
fclose(h);
