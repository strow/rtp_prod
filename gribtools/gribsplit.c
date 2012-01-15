/*

Basic GRIB reader / writer to split up GRIB files into version 1 & 2 parts so that they may be read in using wgrib / wgrib2.

Written by Paul Schou (16 June 2011)

*/
#include <stdio.h>
#include <inttypes.h>
#define maxFilename 120
#define maxbuffer 4096

#ifndef min
   #define min(a,b)  ((a) < (b) ? (a) : (b))
#endif

unsigned char *seek_grib(FILE *file, uint64_t *pos, uint64_t *len_grib,
        unsigned char *buffer, unsigned int buf_len, int *grib_ver);

int main(int argc, char *argv[])
{
   void PrintFileContents(FILE **filePoint);

   // File name / handles
   char *gribFile = argv[1];
   char gribFile1[maxFilename];
   char gribFile2[maxFilename];
   FILE *gribin, *gribout1, *gribout2;

   // Data buffers
   unsigned char buffer[maxbuffer];
   int grib_ver, old_gv;
   uint64_t old_pos, pos, len_grib, read_len, len;
   long i;
   unsigned char *msg;


   // Setup the output file names:
   sprintf(gribFile1, "%s.1", argv[1]);
   sprintf(gribFile2, "%s.2", argv[1]);

   // Print a help message
   if ( argc == 1 ) {
     printf("  Usage: gribsplit [grib_file]\n");
     printf("    Two files are made, grib_file.1 grib_file.2, with the seperate grib parts.\n");
     return 0;
   }

   printf("file \"%s\" is being opened for reading...\n",gribFile);
   if ((gribin = fopen(gribFile,"r")) == NULL) {
      printf("Can't open %s for reading \n",gribFile);
      return -1;
   }

   printf("file \"%s\" is being opened for writing...\n",gribFile1);
   if ((gribout1 = fopen(gribFile1,"w")) == NULL) {
      printf("Can't open %s for reading \n",gribFile1);
      return -1;
   }
   printf("file \"%s\" is being opened for writing...\n",gribFile2);
   if ((gribout2 = fopen(gribFile2,"w")) == NULL) {
      printf("Can't open %s for reading \n",gribFile2);
      return -1;
   }

   // Read in the file until the ending finding each record and splitting them by version
   pos = 0;
   for (i = 0; !feof(gribin); i++) {
      old_pos = pos;
      old_gv = grib_ver;
      msg = seek_grib(gribin, &pos, &len_grib, buffer, maxbuffer, &grib_ver);

      if ( len_grib == 0 ) pos = pos + 100;
      if ( pos > old_pos ) {
         if (fseek(gribin, old_pos, SEEK_SET) == -1) break;
         len = fread(buffer, sizeof (unsigned char), pos - old_pos, gribin);
         if (old_gv == 1)
           fwrite(buffer, sizeof (unsigned char), len, gribout1);
         else if (old_gv == 2)
           fwrite(buffer, sizeof (unsigned char), len, gribout2);
      }
      if ( len_grib == 0 ) break;
      printf("Rec %d, offset %d, ver %d, size %d\n",i,pos,grib_ver,len_grib);

      if (fseek(gribin, pos, SEEK_SET) == -1) break;
      read_len = 0;
      while( read_len < len_grib && !feof(gribin)) {
         len = fread(buffer, sizeof (unsigned char), min(maxbuffer, len_grib - read_len), gribin);
         if (grib_ver == 1)
           fwrite(buffer, sizeof (unsigned char), len, gribout1);
         else if (grib_ver == 2)
           fwrite(buffer, sizeof (unsigned char), len, gribout2);
         read_len = read_len + len;
      }
      pos = pos + len_grib;
   }

   fclose(gribin);
   fclose(gribout1);
   fclose(gribout2);

return 0;
}



#define NTRY 100
/* #define LEN_HEADER_PDS (28+42+100) */
#define LEN_HEADER_PDS (28+8)

unsigned char *seek_grib(FILE *file, uint64_t *pos, uint64_t *len_grib,
        unsigned char *buffer, unsigned int buf_len, int *grib_ver) {
    
    int i, j, len;
    
    j = 1;
    clearerr(file);
    while ( !feof(file) ) {
    
        if (fseek(file, *pos, SEEK_SET) == -1) break;
        i = fread(buffer, sizeof (unsigned char), buf_len, file);
        if (ferror(file)) break;
        len = i - LEN_HEADER_PDS;

        for (i = 0; i < len; i++) {
            if (buffer[i] == 'G' && buffer[i+1] == 'R' && buffer[i+2] == 'I'
                && buffer[i+3] == 'B') {
                    *pos = i + *pos;
                    *grib_ver = buffer[i+7];
                    if (buffer[i+7] == 1)
                      *len_grib = (buffer[i+4] << 16) + (buffer[i+5] << 8) +
                            buffer[i+6];
                    else if (buffer[i+7] == 2)
                      *len_grib = 
                            ((uint64_t)buffer[i+8]  << 56) + ((uint64_t)buffer[i+9] << 48) +
                            ((uint64_t)buffer[i+10] << 40) + ((uint64_t)buffer[i+11] << 32) +
                            ((uint64_t)buffer[i+12] << 24) + ((uint64_t)buffer[i+13] << 16) +
                            ((uint64_t)buffer[i+14] << 8) + (uint64_t)buffer[i+15];
                    return (buffer+i);
            }
        }

  if (j++ == NTRY) {
      fprintf(stderr,"found unidentified data \n");
           /* break; // stop seeking after NTRY records */
        }

  *pos = *pos + (buf_len - LEN_HEADER_PDS);
    }

    *len_grib = 0;
    return (unsigned char *) NULL;
}
