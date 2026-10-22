/*********************************************************
 Program : 00_setup.sas
 Purpose : Set global options, library references, and
           user-defined formats for the entire pipeline.
           Must be run before all other programs.
 Input   : None
 Output  : Libraries sdtm, adam, outd assigned.
           Formats stored permanently in adam library.
 Notes   : Run this program first in every new SAS session.
           Formats are stored in adam (not WORK) so they
           survive session restarts. fmtsearch tells SAS
           where to look for them.
**********************************************************/

/* ---- 1. Project root (one place to change if you move the folder) ---- */
%let root = /home/u64551823/Cdisc_project;
%put NOTE: Project root is set to &root;

/* ---- 2. Global options ---- */
options
  dlcreatedir        /* create folder if it doesn't exist        */
  nodate             /* suppress run date from output headers    */
  nonumber           /* suppress page numbers (ODS supplies own) */
  orientation = landscape
  fmtsearch = (adam work);  /* search adam library first for formats */

ods escapechar = '^';   /* enables ^{thispage}, ^{lastpage}, ^{nbspace} */
ods noproctitle;        /* suppress "The XXXX Procedure" headings       */

/* ---- 3. Library references ---- */
libname sdtm "&root/sdtm";
libname adam "&root/adam";
libname outd "&root/output";

/* ---- 4. Permanent user-defined formats (stored in adam library) ---- */
proc format library = adam;

  /* Treatment arm: numeric code -> readable label              */
  /* 99 = Total column used in the t1_final / ae_final stacks  */
  value trtf
    0  = 'Placebo'
    54 = 'Xanomeline Low Dose'
    81 = 'Xanomeline High Dose'
    99 = 'Total';

  /* Age group: numeric order -> readable label */
  value agegrf
    1 = '<65 years'
    2 = '65-80 years'
    3 = '>80 years';

  /* Sex: single character -> readable label */
  value $sexf
    'F' = 'Female'
    'M' = 'Male';

  /* Race: upper-case SDTM value -> title-case label */
  value $racef
    'AMERICAN INDIAN OR ALASKA NATIVE' = 'American Indian or Alaska Native'
    'BLACK OR AFRICAN AMERICAN'        = 'Black or African American'
    'WHITE'                            = 'White';

  /* AE worst severity: numeric code -> readable label */
  value sevf
    1 = 'Mild'
    2 = 'Moderate'
    3 = 'Severe';

run;

%put NOTE: 00_setup.sas completed successfully.;
