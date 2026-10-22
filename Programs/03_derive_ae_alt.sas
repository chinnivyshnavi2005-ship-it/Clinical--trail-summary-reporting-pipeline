/*********************************************************
 Program : 03_derive_ae_alt.sas
 Purpose : (A) Merge AE with ADSL to create the AE analysis
               dataset (treatment arm on every event row).
           (B) Build ALT lab datasets: raw, baseline,
               change from baseline, and visit-level summary
               statistics for the Phase 4 figure.
 Input   : sdtm.ae, adam.adsl_derived, sdtm.lb
 Output  : adam.ae_analysis  (1191 obs)
           adam.alt_chg      (scheduled post-baseline ALT rows)
           adam.alt_stats    (PROC MEANS summary for plotting)
 Notes   : Run after 02_derive_adsl.sas.
           Inner join (if inae and insl) keeps only the 254-
           subject analysis population. 0 unmatched AE rows
           expected (verified in earlier testing).
           Baseline ALT = last non-missing result at visits
           1, 1.1, 1.2, 1.3 (visitnum < 4). All 254 subjects
           have a baseline value; 228 from visit 1, 26 from
           retests 1.1-1.3.
**********************************************************/

/* ---- PART A: AE analysis dataset ---- */

proc sort data = sdtm.ae       out = ae_sorted;  by usubjid aeseq; run;
proc sort data = adam.adsl_derived out = adsl_s;  by usubjid;       run;

data adam.ae_analysis;
  merge ae_sorted  (in = inae)
        adsl_s     (in = insl keep = usubjid trt01p trt01pn);
  by usubjid;
  if inae and insl;   /* inner join: analysis population only */

  /* Convert AE start date; ?? suppresses notes for partial dates */
  aestdt = input(aestdtc, ?? yymmdd10.);
  format aestdt date9.;

  keep usubjid aeseq aebodsys aedecod aesev aeser aestdt trt01p trt01pn;
run;

/* QC: 0 unmatched AE subjects */
data notmatched;
  merge ae_sorted (in = inae keep = usubjid)
        adsl_s    (in = insl keep = usubjid);
  by usubjid;
  if inae and not insl;
run;
/* Expected: 0 observations in notmatched */

/* ---- PART B: ALT lab dataset ---- */

/* B1. Merge LB (ALT only) with ADSL to get treatment arm */
proc sort data = sdtm.lb out = lb_s; by usubjid; run;

data adam.alt;
  merge lb_s   (in = inlb where = (upcase(lbtestcd) = 'ALT'))
        adsl_s (in = insl keep = usubjid trt01pn);
  by usubjid;
  if inlb and insl;
  if not missing(lbstresn);
run;

/* B2. Sort for baseline derivation */
proc sort data = adam.alt out = alt_s; by usubjid visitnum; run;

/* B3. Baseline = last non-missing ALT before first dose (visitnum < 4) */
data base;
  set alt_s;
  by usubjid;
  where visitnum < 4;
  if last.usubjid;
  base    = lbstresn;
  basevis = visitnum;   /* renamed: avoids overwriting visitnum in merge */
  keep usubjid base basevis;
run;
/* Expected: 254 observations (228 from visit 1, 26 from retests) */

/* B4. Scheduled post-baseline visits with change from baseline */
data adam.alt_chg;
  merge alt_s (in = ina) base;
  by usubjid;
  if ina and visit =: 'WEEK';   /* =: means "begins with" */
  if not missing(base) then chg = lbstresn - base;
run;

/* B5. Visit-level summary statistics (saved for figure) */
proc means data = adam.alt_chg n mean std min max maxdec = 1 nway;
  class trt01pn visitnum visit;
  var lbstresn chg;
  format trt01pn trtf.;
  output out = adam.alt_stats (drop = _type_ _freq_)
         n = mean = std = min = max = / autoname;
run;

%put NOTE: 03_derive_ae_alt.sas completed successfully.;
