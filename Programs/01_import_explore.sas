/*********************************************************
 Program : 01_import_explore.sas
 Purpose : Import six CDISC pilot .xpt transport files into
           permanent SAS datasets, then run basic exploratory
           procedures to verify structure and content.
 Input   : &root/sdtm/dm.xpt, ae.xpt, vs.xpt, lb.xpt
           &root/adam/adsl.xpt, adae.xpt
 Output  : sdtm.dm, sdtm.ae, sdtm.vs, sdtm.lb
           adam.adsl, adam.adae
 Notes   : Run after 00_setup.sas.
           Expected observation counts (from CDISC pilot):
             sdtm.dm   306 obs  25 vars
             sdtm.ae  1191 obs  35 vars
             sdtm.vs 29643 obs  24 vars
             sdtm.lb 59580 obs  23 vars
             adam.adsl  254 obs  48 vars
             adam.adae 1191 obs  55 vars
           Check the log after PROC COPY for these counts.
**********************************************************/

/* ---- 1. Import SDTM domains ---- */
libname xdm  xport "&root/sdtm/dm.xpt";
proc copy inlib = xdm  outlib = sdtm; run;

libname xae  xport "&root/sdtm/ae.xpt";
proc copy inlib = xae  outlib = sdtm; run;

libname xvs  xport "&root/sdtm/vs.xpt";
proc copy inlib = xvs  outlib = sdtm; run;

libname xlb  xport "&root/sdtm/lb.xpt";
proc copy inlib = xlb  outlib = sdtm; run;

/* ---- 2. Import ADaM datasets ---- */
libname xadsl xport "&root/adam/adsl.xpt";
proc copy inlib = xadsl outlib = adam; run;

libname xadae xport "&root/adam/adae.xpt";
proc copy inlib = xadae outlib = adam; run;

/* ---- 3. Explore structure ---- */
proc contents data = sdtm.dm   varnum; run;
proc contents data = sdtm.ae   varnum; run;
proc contents data = adam.adsl varnum; run;

/* ---- 4. Arm and sex distribution in DM ---- */
proc freq data = sdtm.dm;
  tables arm sex race / missing;
run;

/* ---- 5. Age summary by arm ---- */
proc means data = sdtm.dm n nmiss mean std min max;
  var age;
  class arm;
run;

/* ---- 6. Distinct AE subjects ---- */
proc sort data = sdtm.ae out = ae_subj (keep = usubjid) nodupkey;
  by usubjid;
run;
/* Expected: 225 observations in ae_subj */

%put NOTE: 01_import_explore.sas completed successfully.;
