function [pd pd_file_a pd_aggr_a pd_sdr_a pd_gran0_a geo_a] = readsdr_rawpd_all(file);

%function [pd pd_file_a pd_aggr_a pd_sdr_a pd_gran0_a geo_a]=readsdr_rawpd_all(file);
%
% Read a CrIS HDF5 SDR "Product_Data" file and return the entire
% contents in a structure, now including attributes
% Note: see "readsdr_rawgeo.m" for CrIS HDF5 SDR "Geolocation" file.
%
% Input:
%    hfile : [string] name of CrIS HDF5 SDR "Product_Data" file
%
% Output:
%    pd   : [structure] CrIS SDR Product_Data with 28 fields
%

% Created: 18 Nov. 2011, L. Strow, starting with readsdr_rawpd.m, Mostly from
%                        UW version (Lori B.), moved attributes to different
%                        structures.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

d = dir(file);
if (length(d) ~= 1)
   error(['bad filename: ' file ]);
end

%Get hdf5 file info
info=hdf5info(file);

%Read in GroupHierarchy.Attributes 	'/'
% File attributes
nfields = length(info.GroupHierarchy.Attributes);
pd=[];
for ii=1:nfields
    fname = basename(info.GroupHierarchy.Attributes(ii).Name);
    eval(['pd_file_a.' fname '=info.GroupHierarchy.Attributes(ii).Value.Data;'])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read Groups(1).Groups.Datasets	'/All_Data/CrIS-SDR_All/*'
% All data, main pd structure
for ii=1:numel(info.GroupHierarchy.Groups)
  if(strcmp(info.GroupHierarchy.Groups(ii).Name,'/All_Data'))
    ig1=ii;
    break;
  end
end
for ii=1:numel(info.GroupHierarchy.Groups(ig1).Groups)
  if(strcmp(info.GroupHierarchy.Groups(ig1).Groups(ii).Name,'/All_Data/CrIS-SDR_All'));
    ig2=ii;
    break;
  end
end

nfields = length(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets);
for ii=1:nfields
   fname = basename(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(ii).Name);
   eval(['pd.' fname '=hdf5read(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(ii));'])
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in Groups(2).Groups.Attributes	'/Data_Products/CrIS-SDR/(attributes) '
% Data product attributes cris-sdr

for ii=1:numel(info.GroupHierarchy.Groups)
  if(strcmp(info.GroupHierarchy.Groups(ii).Name,'/Data_Products'))
    ig1=ii;
    break;
  end
end
for ii=1:numel(info.GroupHierarchy.Groups(ig1).Groups)
  if(strcmp(info.GroupHierarchy.Groups(ig1).Groups(ii).Name,'/Data_Products/CrIS-SDR'))
    ig2=ii;
    break;
  end
end


nfields = length(info.GroupHierarchy.Groups(ig1).Groups(ig2).Attributes);
for ii=1:nfields
   fname = basename(info.GroupHierarchy.Groups(ig1).Groups(ig2).Attributes(ii).Name);
   if strcmp(class(info.GroupHierarchy.Groups(ig1).Groups(ig2).Attributes(ii).Value),'hdf5.h5string')==1
      nh5str=length(info.GroupHierarchy.Groups(ig1).Groups(ig2).Attributes(ii).Value);
      for jj=1:nh5str
         eval(['pd_sdr_a.' fname '{jj}=(info.GroupHierarchy.Groups(ig1).Groups(ig2).Attributes(ii).Value(jj).Data);'])
      end
   else
      eval(['pd_sdr_a.' fname '=(info.GroupHierarchy.Groups(ig1).Groups(ig2).Attributes(ii).Value);'])
   end
end


% Read in Groups(2).Groups.Datasets(1).Attributes	'/Data_Products/CrIS-SDR/CrIS-SDR_Aggr->(attributes) '
% CrIS-SDR_Aggr attributes

for ii=1:numel(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets)
  if(strcmp(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(ii).Name,'/Data_Products/CrIS-SDR/CrIS-SDR_Aggr'))
    id1=ii;
    break
  end
end

nfields = length(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(id1).Attributes);
for ii=1:nfields
   fname = basename(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(id1).Attributes(ii).Name);
   if strcmp(class(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(id1).Attributes(ii).Value),'hdf5.h5string')==1
      nh5str=length(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(id1).Attributes(ii).Value);
      for jj=1:nh5str
         eval(['pd_aggr_a.' fname '{jj}=(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(id1).Attributes(ii).Value(jj).Data);'])
      end
   else
      eval(['pd_aggr_a.' fname '=(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(id1).Attributes(ii).Value);'])
   end
end

% Read in Groups(2).Groups.Datasets(2).Attributes	'/Data_Products/CrIS-SDR/CrIS-SDR_Gran_0->(attributes)'
% CrIS-SDR_Gran_0 info (assuming 1 granule??)

for ii=1:numel(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets)
  if(strcmp(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(ii).Name,'/Data_Products/CrIS-SDR/CrIS-SDR_Gran_0'))
    id2=ii;
    break
  end
end


nfields = length(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(id2).Attributes);
for ii=1:nfields
   fname = basename(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(id2).Attributes(ii).Name);
   fname= strrep(fname,'-','_');
   if strcmp(class(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(id2).Attributes(ii).Value),'hdf5.h5string')==1
      nh5str=length(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(id2).Attributes(ii).Value);
      for jj=1:nh5str
         eval(['pd_gran0_a.' fname '{jj}=(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(id2).Attributes(ii).Value(jj).Data);'])
      end
   else
      eval(['pd_gran0_a.' fname '=(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(id2).Attributes(ii).Value);'])
   end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read GEO info if it exists


% Read all fields -     '/All_Data/CrIS-SDR-GEO_All/*'
geo_a =[];

for ii=1:numel(info.GroupHierarchy.Groups)
  if(strcmp(info.GroupHierarchy.Groups(ii).Name,'/All_Data'))
    ig1=ii;
    break;
  end
end
ig2=0;
for ii=1:numel(info.GroupHierarchy.Groups(ig1).Groups)
  if(strcmp(info.GroupHierarchy.Groups(ig1).Groups(ii).Name,'/All_Data/CrIS-SDR-GEO_All'));
    ig2=ii;
    break;
  end
end
if(ig2>0)
  nfields = length(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets);
  for ii=1:nfields
    fname = basename(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(ii).Name);
    geo_a.(fname)=hdf5read(info.GroupHierarchy.Groups(ig1).Groups(ig2).Datasets(ii));
  end
end

         

end
