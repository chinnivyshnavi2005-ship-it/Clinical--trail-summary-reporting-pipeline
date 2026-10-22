/*********************************************************
 Program : 06_figure_alt.sas
 Purpose : Produce Figure 14.3.2 - Mean Change from Baseline
           in ALT (U/L) by Visit.
           Line plot with error bars (+/- 1 SE), n table
           under the x-axis. Output as PDF and PNG.
 Input   : adam.alt_stats (from 03_derive_ae_alt.sas)
 Output  : &root/output/figure_14_3_2.pdf
           &root/output/figure_14_3_2.png
 Notes   : Run after 03_derive_ae_alt.sas.
           PROC MEANS autoname produces variables named
           lbstresn_N, lbstresn_Mean, chg_N, chg_Mean,
           chg_StdDev. Confirm these names in alt_stats if
           the program errors on "variable not found".
           xpos offsets each arm by 0.3 weeks to prevent
           overlapping error bars (cosmetic only; x=week
           drives axis labels and n table).
           image_dpi=200 gives a sharp PNG for README.
**********************************************************/

/* ---- 1. Build plot dataset ---- */
data alt_plot;
  set adam.alt_stats;
  week  = input(scan(visit, 2, ' '), best.);   /* extract "12" from "WEEK 12" */
  se    = chg_StdDev / sqrt(chg_N);
  lower = chg_Mean - se;
  upper = chg_Mean + se;

  /* Horizontal dodge to separate error bars */
  if      trt01pn = 0  then xpos = week - 0.3;
  else if trt01pn = 54 then xpos = week;
  else if trt01pn = 81 then xpos = week + 0.3;
run;

proc sort data = alt_plot; by trt01pn week; run;

/* ---- 2. Open both destinations ---- */
ods pdf     file = "&root/output/figure_14_3_2.pdf" style = journal;
ods listing gpath = "&root/output" image_dpi = 200;
ods graphics / reset = index imagename = 'figure_14_3_2'
               imagefmt = png width = 8in height = 5in;

title1 j=l 'Protocol CDISCPILOT01';
title2 j=c 'Figure 14.3.2';
title3 j=c 'Mean Change from Baseline in ALT (U/L) by Visit';
footnote1 j=l 'Source: ADSL, LB. Error bars show mean +/- 1 standard error. Table shows subjects with an ALT result at each visit.';
footnote2 j=r 'Page ^{thispage} of ^{lastpage}';

proc sgplot data = alt_plot;
  format trt01pn trtf.;
  series  x = xpos y = chg_Mean / group = trt01pn markers name = 'ser';
  scatter x = xpos y = chg_Mean / group = trt01pn
          yerrorlower = lower yerrorupper = upper
          markerattrs = (size=0);
  refline 0 / axis=y lineattrs=(pattern=shortdash color=gray);
  xaxis label = 'Week' values = (2 4 6 8 12 16 20 24 26);
  yaxis label = 'Mean change from baseline (U/L)';
  xaxistable chg_N / x = week class = trt01pn title = 'n';
  keylegend 'ser' / title = 'Treatment';
run;

ods listing close;
ods pdf     close;
title;
footnote;

%put NOTE: 06_figure_alt.sas completed successfully.;
