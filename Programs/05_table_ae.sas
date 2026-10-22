/*********************************************************
 Program : 05_table_ae.sas
 Purpose : Build Table 14.3.1 - Summary of Subjects with
           Adverse Events by Worst Severity.
           Each subject counted once at their worst AE.
           Denominators are the full arm sizes (254 total).
 Input   : adam.ae_analysis, adam.adsl_derived, WORK.bign
 Output  : &root/output/table_14_3_1.rtf
           &root/output/table_14_3_1.pdf
 Notes   : Run after 03_derive_ae_alt.sas and 04_table_demog.sas
           (bign and macro variables &n0 &n54 &n81 &n99 must
           exist in the current session; they are created in
           04_table_demog.sas).
           Expected results (verified against earlier run):
             Subjects with any AE: 225 (88.6%)
             Placebo:  69 (80.2%), Low: 77 (91.7%), High: 79 (94.0%)
             Mild:     77,  Moderate: 117,  Severe: 31
**********************************************************/

/* ---- 1. Worst severity per subject ---- */
data ae_sev;
  set adam.ae_analysis (keep = usubjid aesev);
  sev_u = upcase(strip(aesev));
  if      sev_u = 'MILD'     then sevn = 1;
  else if sev_u = 'MODERATE' then sevn = 2;
  else if sev_u = 'SEVERE'   then sevn = 3;
  else put 'WARNING: Unexpected AESEV value: ' aesev=;
run;

proc sort data = ae_sev; by usubjid sevn; run;

data worst;
  set ae_sev;
  by usubjid;
  if last.usubjid;   /* last after sorting by sevn = worst */
  keep usubjid sevn;
run;
/* Expected: 225 observations */

/* ---- 2. All 254 subjects, AE-free get sevn=0; duplicate as Total ---- */
proc sort data = adam.adsl_derived out = adsl_ae (keep = usubjid trt01pn);
  by usubjid;
run;

data ae_t;
  merge adsl_ae (in = insl) worst;
  by usubjid;
  if insl;
  if missing(sevn) then sevn = 0;
  anyae = (sevn > 0);
  output;
  trt01pn = 99;
  output;
run;
/* Expected: 508 observations (254 x 2) */

/* ---- 3. Count subjects per arm per category ---- */
proc freq data = ae_t noprint;
  tables trt01pn * sevn  / out = cnts (drop = percent) sparse;
run;

proc freq data = ae_t noprint;
  tables trt01pn * anyae / out = cnta (drop = percent) sparse;
run;

data cnts2;
  merge cnts bign;
  by trt01pn;
  length cell $20;
  if count = 0 then cell = '0';
  else cell = catx(' ', strip(put(count, 3.)),
                   cats('(', put(100*count/bign, 5.1), '%)'));
run;

data cnta2;
  merge cnta bign;
  by trt01pn;
  if anyae = 1;   /* keep only "has AE" row; drops the "no AE" row */
  length cell $20;
  if count = 0 then cell = '0';
  else cell = catx(' ', strip(put(count, 3.)),
                   cats('(', put(100*count/bign, 5.1), '%)'));
run;

/* ---- 4. Stack into long dataset, then transpose to wide ---- */
data ae_long;
  length rowlbl $60 cell $20;
  set cnta2 (in=a)
      cnts2 (in=b where=(sevn > 0));   /* drop the sevn=0 "No AE" row */
  if a then do;
    sec    = 1;
    roword = 1;
    rowlbl = 'Subjects with any AE';
  end;
  else do;
    sec    = 2;
    roword = sevn;
    rowlbl = put(sevn, sevf.);
  end;
  keep trt01pn sec roword rowlbl cell;
run;

proc sort data = ae_long; by sec roword rowlbl trt01pn; run;

proc transpose data = ae_long out = ae_wide (drop = _name_) prefix = t;
  by sec roword rowlbl;
  id trt01pn;
  var cell;
run;

/* ---- 5. Add section heading for severity block ---- */
data ae_hdr;
  length rowlbl $60;
  sec = 2; roword = 0; rowlbl = 'Subjects by worst severity';
run;

data ae_final;
  set ae_hdr ae_wide;
run;

proc sort data = ae_final; by sec roword; run;

/* ---- 6. PROC REPORT inside ODS ---- */
ods rtf file = "&root/output/table_14_3_1.rtf" style = journal bodytitle;
ods pdf file = "&root/output/table_14_3_1.pdf" style = journal;

title1 j=l 'Protocol CDISCPILOT01';
title2 j=c 'Table 14.3.1';
title3 j=c 'Summary of Subjects with Adverse Events by Worst Severity';
title4 j=c 'All Subjects in ADSL';
footnote1 j=l 'Source: ADSL, AE. Subjects are counted once, at their worst severity. Percentages are based on the number of subjects in each treatment group.';
footnote2 j=r 'Page ^{thispage} of ^{lastpage}';

proc report data = ae_final nowd split = '|' style(column) = [vjust=t];
  column sec roword rowlbl t0 t54 t81 t99;

  define sec    / order noprint;
  define roword / order noprint;
  define rowlbl / display ' '
                  style(column) = [cellwidth=3.0in just=l];
  define t0     / display "Placebo|(N=&n0)"
                  style(column) = [cellwidth=1.5in just=c]
                  style(header) = [just=c];
  define t54    / display "Xanomeline Low Dose|(N=&n54)"
                  style(column) = [cellwidth=1.5in just=c]
                  style(header) = [just=c];
  define t81    / display "Xanomeline High Dose|(N=&n81)"
                  style(column) = [cellwidth=1.5in just=c]
                  style(header) = [just=c];
  define t99    / display "Total|(N=&n99)"
                  style(column) = [cellwidth=1.5in just=c]
                  style(header) = [just=c];

  compute rowlbl;
    if roword = 0 or sec = 1 then
      call define(_row_, 'style', 'style=[font_weight=bold]');
    else
      call define(_col_, 'style', 'style=[leftmargin=0.2in]');
  endcomp;
run;

ods rtf close;
ods pdf close;
title;
footnote;

%put NOTE: 05_table_ae.sas completed successfully.;
