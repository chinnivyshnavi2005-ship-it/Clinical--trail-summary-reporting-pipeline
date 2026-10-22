/*********************************************************
 Program : 04_table_demog.sas
 Purpose : Build Table 14.1.1 - Summary of Demographic and
           Baseline Characteristics.
           Produces one landscape table with n (%) cells,
           arm names in headers, and page numbers.
 Input   : adam.adsl_derived
 Output  : &root/output/table_14_1_1.rtf
           &root/output/table_14_1_1.pdf
 Notes   : Run after 02_derive_adsl.sas.
           Each subject appears twice (own arm + Total=99)
           to generate the Total column from the same code.
           Column denominators come from bign (WORK).
           Formats must be available: run 00_setup.sas first.
**********************************************************/

/* ---- A. Column denominators ---- */
data adsl_t;
  set adam.adsl_derived;
  output;
  trt01pn = 99;   /* duplicate as Total */
  output;
run;

proc freq data = adsl_t noprint;
  tables trt01pn / out = bign (drop = percent rename = (count = bign));
run;

/* ---- B. Macro variable denominators for column headers ---- */
proc sql noprint;
  select bign into :n0  trimmed from bign where trt01pn = 0;
  select bign into :n54 trimmed from bign where trt01pn = 54;
  select bign into :n81 trimmed from bign where trt01pn = 81;
  select bign into :n99 trimmed from bign where trt01pn = 99;
quit;

/* ---- C. Age block: continuous statistics ---- */
proc means data = adsl_t noprint nway;
  class trt01pn;
  var age;
  output out = agest (drop = _type_ _freq_) n=n mean=mean std=std min=min max=max;
run;

data age_long;
  set agest;
  length rowlbl $60 cell $20;
  roword = 1; rowlbl = 'n';
    cell = strip(put(n, 3.)); output;
  roword = 2; rowlbl = 'Mean (SD)';
    cell = catx(' ', put(mean, 5.1), cats('(', put(std, 6.2), ')')); output;
  roword = 3; rowlbl = 'Min';
    cell = strip(put(min, 3.)); output;
  roword = 4; rowlbl = 'Max';
    cell = strip(put(max, 3.)); output;
  keep trt01pn roword rowlbl cell;
run;

proc sort data = age_long; by roword rowlbl trt01pn; run;

proc transpose data = age_long out = age_wide (drop = _name_) prefix = t;
  by roword rowlbl;
  id trt01pn;
  var cell;
run;

data age_wide; set age_wide; sec = 1; run;

/* ---- D. Categorical blocks via macro ---- */
%macro cat(var=, fmt=, ord=);
  proc freq data = adsl_t noprint;
    tables trt01pn * &var / out = cnt (drop = percent) sparse;
  run;

  data cnt2;
    merge cnt bign;
    by trt01pn;
    length cell $20;
    if count = 0 then cell = '0';
    else cell = catx(' ', strip(put(count, 3.)),
                     cats('(', put(100*count/bign, 5.1), '%)'));
  run;

  proc sort data = cnt2; by &var trt01pn; run;

  proc transpose data = cnt2 out = w_&ord (drop = _name_) prefix = t;
    by &var;
    id trt01pn;
    var cell;
  run;

  data w_&ord;
    set w_&ord;
    length rowlbl $60;
    format &var &fmt;
    rowlbl = vvalue(&var);
    sec    = &ord;
    roword = _n_;
    keep sec roword rowlbl t0 t54 t81 t99;
  run;
%mend cat;

%cat(var = sex,     fmt = $sexf.,  ord = 2);
%cat(var = agegr1n, fmt = agegrf., ord = 3);
%cat(var = racegr,  fmt = $racef., ord = 4);

/* ---- E. Section headings ---- */
data hdr;
  length rowlbl $60;
  sec = 1; roword = 0; rowlbl = 'Age (years)'; output;
  sec = 2; roword = 0; rowlbl = 'Sex';         output;
  sec = 3; roword = 0; rowlbl = 'Age Group';   output;
  sec = 4; roword = 0; rowlbl = 'Race';        output;
run;

/* ---- F. Final stacked dataset ---- */
data t1_final;
  set hdr age_wide w_2 w_3 w_4;
run;

proc sort data = t1_final; by sec roword; run;

/* ---- G. PROC REPORT inside ODS ---- */
ods rtf file = "&root/output/table_14_1_1.rtf" style = journal bodytitle;
ods pdf file = "&root/output/table_14_1_1.pdf" style = journal;

title1 j=l 'Protocol CDISCPILOT01';
title2 j=c 'Table 14.1.1';
title3 j=c 'Summary of Demographic and Baseline Characteristics';
title4 j=c 'All Subjects in ADSL';
footnote1 j=l 'Source: ADSL. Percentages are based on the number of subjects in each treatment group.';
footnote2 j=r 'Page ^{thispage} of ^{lastpage}';

proc report data = t1_final nowd split = '|' style(column) = [vjust=t];
  column sec roword rowlbl t0 t54 t81 t99;

  define sec    / order noprint;
  define roword / order noprint;
  define rowlbl / display ' '
                  style(column) = [cellwidth=2.8in just=l];
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
    if roword = 0 then
      call define(_row_, 'style', 'style=[font_weight=bold]');
    else
      call define(_col_, 'style', 'style=[leftmargin=0.2in]');
  endcomp;
run;

ods rtf close;
ods pdf close;
title;
footnote;

%put NOTE: 04_table_demog.sas completed successfully.;
