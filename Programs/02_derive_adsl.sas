/*********************************************************
 Program : 02_derive_adsl.sas
 Purpose : Derive subject-level analysis dataset from SDTM DM.
           Excludes screen failures (arm = 'Screen Failure').
           Derives age groups, numeric treatment code,
           active treatment flag, race group, and treatment
           duration from ISO 8601 date variables.
 Input   : sdtm.dm
 Output  : adam.adsl_derived (254 observations, 14 variables)
 Notes   : Run after 00_setup.sas and 01_import_explore.sas.
           Uses index() on upcase(arm) to avoid hidden-character
           mismatches that caused trt01pn = missing in earlier
           testing. Any unexpected ARM value writes a WARNING
           to the log.
           Baseline rule: arm ne 'Screen Failure' applied via
           WHERE before any derivation.
**********************************************************/

data adam.adsl_derived;
  set sdtm.dm;
  where arm ne 'Screen Failure';

  length agegr1 $7 trt01p $20 racegr $60 activefl $1;

  /* ---- Age group (numeric for sort order, character for label) ---- */
  if      missing(age)  then agegr1n = .;
  else if age < 65      then agegr1n = 1;
  else if age <= 80     then agegr1n = 2;
  else                       agegr1n = 3;

  if      agegr1n = 1 then agegr1 = '<65';
  else if agegr1n = 2 then agegr1 = '65-80';
  else if agegr1n = 3 then agegr1 = '>80';
  else                     agegr1 = 'Missing';

  /* ---- Treatment variables (index avoids hidden-character mismatch) ---- */
  arm_u = upcase(arm);
  trt01p = arm;

  if      index(arm_u, 'PLACEBO') then trt01pn = 0;
  else if index(arm_u, 'LOW')     then trt01pn = 54;
  else if index(arm_u, 'HIGH')    then trt01pn = 81;
  else put 'WARNING: Unexpected ARM value: ' arm=;

  /* ---- Active treatment flag ---- */
  if      trt01pn = 0 then activefl = 'N';
  else if trt01pn > 0 then activefl = 'Y';

  /* ---- Race group (missing handling) ---- */
  if missing(race) then racegr = 'Missing';
  else                  racegr = race;

  /* ---- Date conversion: ISO 8601 character -> SAS numeric date ---- */
  rfstdt = input(rfstdtc, yymmdd10.);
  rfendt = input(rfendtc, yymmdd10.);
  format rfstdt rfendt date9.;

  /* ---- Treatment duration (days, inclusive) ---- */
  if nmiss(rfstdt, rfendt) = 0 then trtdurd = rfendt - rfstdt + 1;

  /* ---- Keep only the variables needed downstream ---- */
  keep usubjid siteid age agegr1 agegr1n sex race racegr
       arm trt01p trt01pn activefl rfstdt rfendt trtdurd;

  label
    agegr1   = 'Pooled Age Group 1'
    agegr1n  = 'Pooled Age Group 1 (N)'
    trt01p   = 'Planned Treatment for Period 01'
    trt01pn  = 'Planned Treatment for Period 01 (N)'
    activefl = 'Active Treatment Flag'
    trtdurd  = 'Treatment Duration (Days)';
run;

/* ---- QC: verify 254 observations and no unexpected ARM ---- */
proc freq data = adam.adsl_derived;
  tables trt01p * trt01pn / list nocum nopercent missing;
run;
/* Expected: Placebo 86, Xanomeline Low Dose 84, Xanomeline High Dose 84 */

%put NOTE: 02_derive_adsl.sas completed successfully.;
