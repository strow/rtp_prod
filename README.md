# ASL Matlab RTP Generation System

This document provides overview of the ASL system for generating RTP
files from hyperspectral IR satellite instrument, specifically AIRS,
CrIS, and IASI.  RTP stands for Raditative Transfer Profile.  An RTP
file contains radiance data, and profile data that matches to the
degree possible in space and time.  The profile data usually comes
from NWP model data, but could also come from retrievals or
radiosondes, etc.  Details on RTP fields can be found at the 
[RTP format definition page.](http://asl.umbc.edu/software/rtp/rtpspec201.html) 

## Naming Conventions

See
[RTP naming conventions](http://asl.umbc.edu/softare/rtp_generation/naming_convention.html)
for details on how RTP files are named.  Much of this is automatic,
but below we mention a few extra name conventions not discussed in the
previous link:

###Version Numbering:

Following "Semantic Versioning" (http://semver.org/), the RTP
generation software has version numbers with three components: 

    Major.minor.patch

Major number changes indicate Non-backward compatible changes in the routines. 
Minor number changes indicates Backward compatible extensions of the routines.
Patch change indicate backward compatible debugging/improvement changes.

Because of name size, we will replace ".patch" by a letter, without the "dot", e.g:

     1.9f  

which indicates Major version "1", Minor version "9", patch "f". These numbers/letters can go beyond 9 or z (e.g. 1.10.ac), etc...

This is implemented using git's tagging system, e.g.:

    git tag 2.0a -m "Release RTPCORE version 2" 

###Surface Model Naming Convention

The surface model is represented by three letters:
 
    x||  Topography: 			x="u" USGS (only choice for now)
    |x|  Surface Temperature: 	x="m" default model or x="d" Sergio's diurnal
    ||x  Emissivity: 			x="w" wisconsin's or x="z" DanZhou's

These letters are used in the example Mfiles discussed below.

##How to run using the UMBC HPC cluster

###Standard processing using dates

Two high-level scripts are used to process the data, a Matlab mfile,
and a unix shell script that calls that mfile.  A number of examples
can be found in the ``scripts`` directory, for example see 
``cris_ccast_sdr60dt_merra_udw_run.sh``

There are three main parameters in the shell scripts:

1. The Matlab routine to use.  This is the last argument to the 
   "timeblock_dealer" mfile that starts Matlab.

2. The times to process, which include: ``start_time``, ``end_time``,
   and ``delta_time``. For clear subset data we usually use
   ``delta_time`` of 1 hour.  For ALLFOV data (where every footprint
   is including in the RTP file) you must choose *small* delta times,
   other wise the files will be far too large.  Reasonable times for
   ALLFOV data might be:

	a.  AIRS - [0 0 0 0 6 0]  (six minutes)

	b.  CrIS - [0 0 0 0 10 0]  (ten minutes)

3. The HPC queueing system (Slurm) command line, which starts with
   ``srun``. This command sets up the HPC job properties: number of
   CPUs, job name, etc....

The job is executed by calling the shell script on your shell command
line. 

## Examples

###Practical Example 1

The request was:

Hi Breno -

I was just talking with Larrabee about RTP and radiative transfer
calcs for CrIS and he said to contact you.  He said it's fairly easy
for you to provide RTP files for specific SCRIS files and I should ask
for your "allFOV" runs containing "RTP obs" and "RTP calc" variables,
with the calcs based on ECMWF fields and the profiles in "layer" form.

I'll use these to perform some RT calcs for comparing our aircraft
sensor S-HIS with under flights of CrIS via the "double obs-calc"
methodology, and I will include you on any presentations or papers
that result from it.  Attached is a sample comparison from an under
flight on 5/31, but before the double obs-calc methodology.

There are 6 under flights we are analyzing, with the SCRIS files
listed below:

    20130510 / SCRIS_npp_d20130510_t2029459_e2037437_b07952_c20130511023743801999_noaa_ops.h5
    20130515 / SCRIS_npp_d20130515_t2037059_e2045037_b08023_c20130516024502741669_noaa_ops.h5
    20130516 / SCRIS_npp_d20130516_t2020579_e2028557_b08037_c20130517022855059234_noaa_ops.h5
    20130530 / SCRIS_npp_d20130530_t0939059_e0947037_b08229_c20130530154704782914_noaa_ops.h5
    20130531 / SCRIS_npp_d20130531_t0922579_e0930557_b08243_c20130531153057447240_noaa_ops.h5
    20130601 / SCRIS_npp_d20130601_t0906499_e0914477_b08257_c20130601151448862865_noaa_ops.h5

Thanks very much,
Dave

This request was fullfilled by:

1.  Creating the file ``example_cris_sdr_files.m`` in the scripts
directory.  Since there are a small number of files, they can just be
written as a list in this mfile.  Since ECMWF model data will give the
best estimate for the atmospheric state the routine
``rtpadd_ecmwf_data`` is used to generate the profile data.
``klayers`` and ``sarta`` are run and the data is written out.
Hopefully most of this sample file is self-explanatory.


2.  Creating an associate run file for this, which might be named
    ``example_cris_sdr_files_run`` to actually execute the processing. 
  
###Practical Example 2

Create clear RTP subsets for the CrIS SDR (.mat) files created using
the CCAST algorithm (1<sup>st</sup> four entries) and the standard NOAA IDPS
SDR output (last entry below) that reside in the following directories:

        /asl/data/cris/ccast/sdr60/2012/264/
        /asl/data/cris/ccast/sdr60_dt1/2012/264
        /asl/data/cris/ccast/sdr60_dt2/2012/264
		/asl/data/cris/sdr60/hdf/2012/264

1. To created RTP files for this day of SDR data processed several
   ways by CCAST and by NOAA's IDPS we start with the example scripts:

	    cris_sdr60_ecmwf_umw_clear.m
		cris_ccast_sdr60dt_merra_udw.m

	The first script creates RTP files for the NOAA IDPS SDR output
	using the ECMWF model, surface temperature from ECWMF, and
	Univ. Wisconsin's emissivity model.

	The second script processes the CCAST SDR (.mat) output, using
	NASA's MERRA reanalysis fields, where the MERRA SST has been
	modified to include diurnal variability (need URL to Sergio's
	model here).

1. For the CCAST data, create two new file from the above ccast mfile
   template, for a total of three mfiles to do the processing:

    	cris_ccast_sdr60_ecmwf_umw.m
	    cris_ccast_sdr60_dt1_ecmwf_umw.m
	    cris_ccast_sdr60_dt1_ecmwf_umw.m

	The following steps mostly refer to changes you might have to make
    in each of these files.

2. But, first check to make sure
   `/extra_routines/cris_ccast_filenames.m` will generate appropriated
   file names (see Section 1 of that mfile).

3. Modify the output name structure to reflect what's being
   calculated (Section 2).

4. Make sure you are using the correct raw data reader (Section 3).

5. CrIS data has systematic gaps in the records (whether in the
   beginning or end of the granule files). This is represented by NaNs
   in the CCAST data. (I think it's -9999 for IDPS data). This must be
   removed for Sarta to run successfully.

6. Make sure you're calling the proper procedures for adding in model
   data. (Section 4)

7. Make sure you're calling the correct versions of Klayers and Sarta
   (Section 6).

##AIRS Data Holdings (is this needed?)

OpenDat (and web access) are found here:

    http://disc.sci.gsfc.nasa.gov/services/opendap/AIRS/airs_dp.shtml

Maintainer:
Breno Imbiriba
