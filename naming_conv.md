<<<<<<< HEAD
###Production Standard Name

Each file created in the Standard Processing follows this convention:
 
    intr_data.model.srf.calc.proc.yyyy.mm.dd.hhmmss_hhmmss.version.type
   
where
	
    intr_data 	: Instrument Data
    model     	: Atmospheric Model
    srf       	: Surface Model
    calc      	: Calculated Radiances
    proc      	: Processing
    yyyy.mm.dd	: Data date
    hhmmss_hhmmss: Data hours
    version 	: Version of the code that generated the files
    type	: file type

Example:

    cris_sdr60_noaa_ops.merra.udw.calc.clear.2012.09.20.200000_210000.R1.9g-M1.9e.rtpZ

####Instrument Data

Instrument name followed by the data discriptor, for example:

    airs_l1bcm
    cris_ccast_sdr60
    iasi_l1c


####Atmospheric Model
    Name of the atmospheric profiles: ecmwf, era, merra.

####Surface model
=======
<<<<<<< HEAD
####Calculated Radiances

Indicates if the file contains calculated radiances, and optionally which forward model was used. Eg: 

    calc
    s108
    kcarta

####Processing

Indicates further processing done to the data, as well as subsetting. For example, a clear subset file would have the "clear" identifier.

####Data date
Nominal date for the data in the file. In the yyyy.mm.dd format.

####Data hours
The nominal start time and end time (start\_end) for the data in this file. I say nominal because these times are usually associated with raw data file name times than with observation times.
Format is hhmmss\_hhmmss.

####Code Version 
String denoting the code version (see Version Numbering bellow).

####Type
File type (rtp or mat).


##Version Numbering:
=======

