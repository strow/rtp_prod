# ASL Matlab RTP Generation System

## Naming Convention

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

The surface model is represented by three letters:
 
    x||  Topography: 			x="u" USGS (only choice for now)
    |x|  Surface Temperature: 	x="m" default model or x="d" Sergio's diurnal
    ||x  Emissivity: 			x="w" wisconsin's or x="z" DanZhou's

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

Following "Semantic Versioning" (http://semver.org/), version numbers have three components: 

    Major.minor.patch

Major number changes indicate Non-backward compatible changes in the routines. 
Minor number changes indicates Backward compatible extensions of the routines.
Patch change indicate backward compatible debugging/improvement changes.

Because of name size, we will replace ".patch" by a letter, without the "dot", e.g:

     1.9f  

which indicates Major version "1", Minor version "9", patch "f". These numbers/letters can go beyond 9 or z (e.g. 1.10.ac), etc...

This is implemented using git's tagging system, e.g.:

    git tag 2.0a -m "Release RTPCORE version 2" 


##AIRS Data Holdings

OpenDat (and web access) are found here:

    http://disc.sci.gsfc.nasa.gov/services/opendap/AIRS/airs_dp.shtml

## Examples

###Practical Example 1

The request was:

Hi Breno -

I was just talking with Larrabee about RTP and radiative transfer calcs for CrIS and he said to contact you.  He said it's fairly easy for you to provide RTP files for specific SCRIS files and I should ask for your "allFOV" runs containing "RTP obs" and "RTP calc" variables, with the calcs based on ECMWF fields and the profiles in "layer" form.

I'll use these to perform some RT calcs for comparing our aircraft sensor S-HIS with under flights of CrIS via the "double obs-calc" methodology, and I will include you on any presentations or papers that result from it.  Attached is a sample comparison from an under flight on 5/31, but before the double obs-calc methodology.

There are 6 under flights we are analyzing, with the SCRIS files listed below:

    20130510 / SCRIS_npp_d20130510_t2029459_e2037437_b07952_c20130511023743801999_noaa_ops.h5
    20130515 / SCRIS_npp_d20130515_t2037059_e2045037_b08023_c20130516024502741669_noaa_ops.h5
    20130516 / SCRIS_npp_d20130516_t2020579_e2028557_b08037_c20130517022855059234_noaa_ops.h5
    20130530 / SCRIS_npp_d20130530_t0939059_e0947037_b08229_c20130530154704782914_noaa_ops.h5
    20130531 / SCRIS_npp_d20130531_t0922579_e0930557_b08243_c20130531153057447240_noaa_ops.h5
    20130601 / SCRIS_npp_d20130601_t0906499_e0914477_b08257_c20130601151448862865_noaa_ops.h5

Thanks very much,
Dave


1. Figure out necessary steps for the request:

   a. Input is a file list

   b. Wants EMCWF

   c. Calculation

   d. Profile data returned in layers (i.e. After Klayers).

   (It's still missing emissivity, surface temperature, and topography. I'll use:)

   e. Wisconsin Emissivity (if over ocean defaults to an internal sea surface emissivity)

   f. Default USGS topo

   g. Default surface temp from model.


2. Use the Matlab file templates (sample scripts), for example: `rtp_prod/scripts/cris_sdr60_merra_udw_clear.m`, and construct the building blocks:

  a. Read input file

  b. Add Model data

  c. Run klayers and sarta

  d. trim/cut/save data


See the Matlab code below for the actual implementation:
    scripts/example_cris_sdr_files.m
 
 
###Practical Example 2

Process the following dates, using "standard-like" process code:

        /asl/data/cris/ccast/sdr60/2012/264/
        /asl/data/cris/ccast/sdr60_dt1/2012/264
        /asl/data/cris/ccast/sdr60_dt2/2012/264

These are from 2012/09/20, ccast processing.


1. To process a day of data we can use the example scripts:

	    cris_sdr60_ecmwf_umw_clear.m
		cris_ccast_sdr60dt_merra_udw.m

The first computes the standard sdr60 (noaa) using ecmwf, keeping the model surface temperature from ecmwf and using Wisconsin's emissivity. See Naming Convention.

The second script is for "CCAST sdr60 dt" Howard's data, using merra, and Sergio's diurnal surface temperature.

We want to process these three data type for these three dates using `cris_ccast_sdr60dt_merra_udw.m` as a template.

1. Copy the template with the new names:

    	cris_ccast_sdr60_ecmwf_umw.m
	    cris_ccast_sdr60_dt1_ecmwf_umw.m
	    cris_ccast_sdr60_dt1_ecmwf_umw.m


2. Make sure `/extra_routines/cris_ccast_filenames.m` will generate appropriated file names. (Section 1 in the code)

3. Modify the "output name structure" to reflect what's being calculated (Section 2 in the code)

4. Make sure we're using the correct raw data reader (Section 3)

5. CrIS data has systematic gaps in the records (whether in the beginning or end of the granule files). This is represented by NaNs in the CCAST data. (I think it's -9999 for IDPS data). This must be removed for Sarta to work.


6. Make sure you're calling the procedures you want to add model data. (section 4)

7. Make sure you're calling the correct Klayers and Sarta code (section 6 in the code).

8. Repeat the same for the other two cases.


The actual script code is here:

    cris_ccast_sdr60_ecmwf_umw.m
    cris_ccast_sdr60_dt1_ecmwf_umw.m
    cris_ccast_sdr60_dt2_ecmwf_umw.m



##How to run using the UMBC HPC cluster

###Standard processing using dates

For each matlab code example there's a shell script that calls it. 

These example shell scripts do the call to the slurm queueing system from withing - calling srun on itself. The code identifies that is being called from the cluster and then invoke matlab.

Here, look at 
`cris_ccast_sdr60dt_merra_udw_run.sh`

There are three important things:

1. Invoke the correct Matlab routine: Look at the Matlab call like, where it calls `timeblock_dealer` - a utility function to distribute date chunks among processors. Its last argument is a handler to the Matlab routine to call.

2. Start time, end time, and Delta time. Make sure you declare the time you want to process - these times are the first three arguments in `timeblock_dealer.m`
NOTE That for ALLFOVS you must choose SMALL Delta Times:

	a.  AIRS - [0 0 0 0 6 0]  (six minutes)

	b.  CrIS - [0 0 0 0 10 0]  (ten minutes)

3. The Slurm command line. Here we set up the job properties: number of CPUs, job name, etc....

4. Call the shell scripts from the shell.


Maintainer:
Breno Imbiriba
