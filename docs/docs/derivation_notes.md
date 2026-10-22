# Derivation Notes — CDISCPILOT01 Summary Reporting Pipeline

## Analysis population

- **Source:** SDTM DM (306 observations)
- **Exclusion:** subjects with ARM = 'Screen Failure' (52 subjects)
- **Result:** 254 subjects in `adsl_derived` (Placebo 86, Low Dose 84, High Dose 84)
- **Reference:** `02_derive_adsl.sas`

## Treatment arm mapping

ARM is a character variable in SDTM. A numeric twin `trt01pn` was derived
using `index(upcase(arm), keyword)` rather than exact string comparison, to
guard against hidden characters (non-breaking spaces) observed during testing.

| trt01pn | trt01p |
|---|---|
| 0 | Placebo |
| 54 | Xanomeline Low Dose |
| 81 | Xanomeline High Dose |

The codes 54 and 81 correspond to the mg doses of xanomeline.

## Age groups

Derived from continuous AGE in `adsl_derived`:

| agegr1n | agegr1 | Count |
|---|---|---|
| 1 | <65 | 33 |
| 2 | 65-80 | 144 |
| 3 | >80 | 77 |

## AE worst severity

Each subject in the AE summary table is counted once, at their worst
(most severe) adverse event. Severity order: Mild (1) < Moderate (2) < Severe (3).

Subjects with no AE (29 of 254) are excluded from the severity rows but
are included in the denominator for all percentages.

- **Reference:** `05_table_ae.sas`, `last.usubjid` after sorting by `sevn`

## ALT baseline definition

- **Baseline** = last non-missing ALT result at visitnum < 4
  (Screening 1 and unscheduled retests 1.1, 1.2, 1.3)
- **Rationale:** There is no Week 0 visit in this dataset. The last pre-dose
  value is the ADaM convention for "last observation carried forward to baseline."
- **Coverage:** 254/254 subjects have a baseline (228 from visit 1; 26 from retests)
- **Reference:** `03_derive_ae_alt.sas`, `base` dataset

## ALT scheduled visits

Post-baseline summaries use only visits whose VISIT value begins with 'WEEK'
(the `=:` begins-with operator). Excluded from summaries:
unscheduled visits (1.1, 4.1, etc.), AMBUL ECG REMOVAL, and RETRIEVAL.

## ALT notable finding

Subject 01-708-1286 (Placebo) had ALT rise from 13 to 124 U/L at Week 24.
This is approximately 3× the typical upper limit of normal (~40 U/L) and
inflates the Placebo Week 24 SD (16.2 vs 5.8–8.0 in the active arms).
The value was not removed; it is real data and would be raised as a data
query in a live study. The README summary notes this explicitly.

## SDTM-to-ADaM transformation summary

| SDTM variable | ADaM variable | Derivation |
|---|---|---|
| ARM (char) | trt01p (char) | direct copy after screen-failure exclusion |
| ARM (char) | trt01pn (num) | index() keyword mapping |
| AGE (num) | agegr1 (char) | age < 65 / ≤80 / >80 cut-points |
| AGE (num) | agegr1n (num) | numeric twin for sort ordering |
| RFSTDTC (char) | rfstdt (num) | input(..., yymmdd10.) |
| RFENDTC (char) | rfendt (num) | input(..., yymmdd10.) |
| rfstdt, rfendt | trtdurd (num) | rfendt - rfstdt + 1 (inclusive) |
| LBSTRESN, base | chg (num) | lbstresn - base |
