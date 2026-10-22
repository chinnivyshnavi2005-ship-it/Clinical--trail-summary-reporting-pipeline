/*********************************************************
 Program : run_all.sas
 Purpose : Master driver that runs the complete pipeline
           from a clean SAS session.
           Executes all seven programs in the correct order.
 Input   : All raw .xpt files in sdtm/ and adam/ folders.
 Output  : All permanent datasets in adam/ library.
           All output files in output/ folder.
 Notes   : Reset your SAS session before running this file
           (Session menu -> Reset SAS Session in SAS Studio).
           Check the Log tab for any ERROR or WARNING lines
           after the run completes.
           Expected log markers on success:
             NOTE: 00_setup.sas completed successfully.
             NOTE: 01_import_explore.sas completed successfully.
             NOTE: 02_derive_adsl.sas completed successfully.
             NOTE: 03_derive_ae_alt.sas completed successfully.
             NOTE: 04_table_demog.sas completed successfully.
             NOTE: 05_table_ae.sas completed successfully.
             NOTE: 06_figure_alt.sas completed successfully.
**********************************************************/

/* ---- Project root: change only this line if you move the folder ---- */
%let root = /home/u64551823/Cdisc_project;
%put NOTE: Project root is set to &root;

%include "&root/programs/00_setup.sas"          / source2;
%include "&root/programs/01_import_explore.sas" / source2;
%include "&root/programs/02_derive_adsl.sas"    / source2;
%include "&root/programs/03_derive_ae_alt.sas"  / source2;
%include "&root/programs/04_table_demog.sas"    / source2;
%include "&root/programs/05_table_ae.sas"       / source2;
%include "&root/programs/06_figure_alt.sas"     / source2;

%put NOTE: ===== run_all.sas completed =====;
%put NOTE: Check the Log tab for any ERROR or WARNING lines.;
