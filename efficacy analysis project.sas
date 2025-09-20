
/*efficacy analysis*/
/*1.import all datasets*/
/*creating of macro*/
%macro imprt(path,opdt); 
    proc import datafile=&path
                out=&opdt
                dbms=csv replace;
             getnames=yes;
%mend;
/*calling of macro*/
%imprt("/home/u64255837/sas_proj_data/SUBJECT.csv",sej_proj.sub_macro);
%imprt("/home/u64255837/sas_proj_data/LB.csv",sej_proj.lb_macro);
%imprt("/home/u64255837/sas_proj_data/TR.csv",sej_proj.tr_macro);
%imprt("/home/u64255837/sas_proj_data/VS.csv",sej_proj.vs_macro);
/* Check datasets */
proc contents data=sej_proj.sub_macro; 
run;
proc contents data=sej_proj.lb_macro; 
run;
proc contents data=sej_proj.tr_macro; 
run;
proc contents data=sej_proj.vs_macro; 
run;

/*merging the datasets*/
/*lb and sub*/
proc sql;
     create table sej_proj.lb_final as
     select a.*,b.TRT, b.TRTLabel
     from sej_proj.lb_macro a left join sej_proj.sub_macro b
     on a.usubjid=b.usubjid;
quit;
/*vs and sub*/
proc sql;
     create table sej_proj.vs_final as
     select a.*,b.TRT, b.TRTLabel
     from sej_proj.vs_macro a left join sej_proj.sub_macro b
     on a.usubjid=b.usubjid;
quit;
/*tr and sub*/
proc sql;
     create table sej_proj.tr_final as
     select a.*,b.TRT, b.TRTLabel
     from sej_proj.tr_macro a left join sej_proj.sub_macro b
     on a.usubjid=b.usubjid;
quit;

/*3.creating the baseline change "lb"*/
proc sql;
     create table sej_proj.lb_chng as
     select a.*, 
            base.LBSTRESN as base,
            a.LBSTRESN-base.LBSTRESN as change
     from sej_proj.lb_final a left join (select usubjid,lbstresn
                                          from sej_proj.lb_final
                                          where visitnum=0) base
     on a.usubjid=base.usubjid;
quit;
/*creating percent change"lb"*/
proc sql;
     create table sej_proj.lb_chng_2 as
     select a.*,
            b.lbstresn as base_hba1c,
            a.lbstresn-b.lbstresn as change,
            case when b.lbstresn>0
            then 100*(a.lbstresn-b.lbstresn)/b.lbstresn
            else . end as pct_chng
      from sej_proj.lb_final a left join (select usubjid,lbstresn
                                          from sej_proj.lb_final
                                          where visitnum=0) b
      on a.usubjid=b.usubjid;
quit;
/*craeting percent change and chnage from baseline "vs"*/
proc sql;
     create table sej_proj.vs_chng as
     select a.*,
            b.vsorres as base_sbp,
            a.vsorres-b.vsorres as change,
            case when b.vsorres>0
            then 100*(a.vsorres-b.vsorres)/b.vsorres
            else . end as pct_chng
     from sej_proj.vs_final a left join (select usubjid,vsorres
                                         from sej_proj.vs_final
                                         where visitnum=0) b 
     on a.usubjid=b.usubjid;
quit;
/*craeting percent change and chnage from baseline "tr"*/
proc sql;
     create table sej_proj.tr_chng as
     select a.*,
            b.TRORRES as base_tumsiz,
            a.TRORRES-b.TRORRES as change,
            case when b.TRORRES>0
            then 100*(a.TRORRES-b.TRORRES)/b.TRORRES
            else . end as pct_chng
     from sej_proj.tr_final a left join (select usubjid,TRORRES
                                         from sej_proj.tr_final
                                         where visitnum=0) b 
     on a.usubjid=b.usubjid;
quit;

/*4.1.calculating the mean and std dev "lb"
  (Summarize endpoints by treatment arm (mean ± SD))*/
proc means data=sej_proj.lb_chng_2 noprint n mean median min max stddev uclm lclm;
     class trtlabel visitnum;
     var change;
     output out=sej_proj.lb_summary n=n mean=mean median=median min=min max=max 
                                    stddev=stddev uclm=uclm lclm=lclm;
run;
/*print the summary*/
proc print data=sej_proj.lb_summary;
run;
/*mean+-stddev*/
data sej_proj.lb_summary_2;
     set sej_proj.lb_summary;
     if _type_=3;
     mean_sd = cats(put(Mean,5.2), ' ± ', put(SD,5.2));
run;
/*print*/
proc print data=sej_proj.lb_summary_2 noobs;
     var trtlabel visitnum mean_sd n;
run;
/*4.2.calculating the mean and std dev "vs"
  (Summarize endpoints by treatment arm (mean ± SD))*/
proc means data=sej_proj.vs_chng noprint n mean median min max stddev uclm lclm;
     class trtlabel visitnum;
     var change;
     output out=sej_proj.vs_summary n=n mean=mean median=median min=min max=max 
                                    stddev=stddev uclm=uclm lclm=lclm;
run;
/*print the summary*/
proc print data=sej_proj.vs_summary;
run;
/*mean+-stddev*/
data sej_proj.vs_summary_2;
     set sej_proj.vs_summary;
     if _type_=3;
     mean_sd = cats(put(Mean,5.2), ' ± ', put(SD,5.2));
run;
/*print*/
proc print data=sej_proj.vs_summary_2 noobs;
     var trtlabel visitnum mean_sd n;
run;
/*4.3.calculating the mean and std dev "tr"
  (Summarize endpoints by treatment arm (mean ± SD))*/
proc means data=sej_proj.tr_chng noprint n mean median min max stddev uclm lclm;
     class trtlabel visitnum;
     var change;
     output out=sej_proj.tr_summary n=n mean=mean median=median min=min max=max 
                                    stddev=stddev uclm=uclm lclm=lclm;
run;
/*print the summary*/
proc print data=sej_proj.tr_summary;
run;
/*mean+-stddev*/
data sej_proj.tr_summary_2;
     set sej_proj.tr_summary;
     if _type_=3;
     mean_sd = cats(put(Mean,5.2), ' ± ', put(SD,5.2));
run;
/*print*/
proc print data=sej_proj.tr_summary_2 noobs;
     var trtlabel visitnum mean_sd n;
run;

/*5.create efficacy graph*/
/*5.1. for "lb"*/
/*make a summary datasets*/
proc sql;
   create table sej_proj.lb_agg as
   select TRTLabel, VISITNUM,
          mean(CHANGE) as MEAN,
          std(CHANGE) as SD,
          count(CHANGE) as N
   from sej_proj.lb_chng_2
   group by TRTLabel, VISITNUM;
quit;
/*calculate error bars*/
data sej_proj.lb_agg_1;
   set sej_proj.lb_agg;
   SE = SD/sqrt(N);                /* Standard Error */
   LOWER = MEAN - 1.96*SE;         /* Lower 95% CI */
   UPPER = MEAN + 1.96*SE;         /* Upper 95% CI */
run;
/*graph plot by using cl band and series*/
proc sgplot data=sej_proj.lb_agg_1;
   band x=VISITNUM lower=LOWER upper=UPPER / group=TRTLabel transparency=0.4;
   series x=VISITNUM y=MEAN / group=TRTLabel markers;
   xaxis values=(0 4 12 24) label="Visit (weeks)";
   yaxis label="Mean change from baseline (HbA1c)";
   title "Mean change from baseline by treatment arm";
run;
/*5.2. for "vs"*/
/*make a summary datasets*/
proc sql;
   create table sej_proj.vs_agg as
   select TRTLabel, VISITNUM,
          mean(CHANGE) as MEAN,
          std(CHANGE) as SD,
          count(CHANGE) as N
   from sej_proj.vs_chng
   group by TRTLabel, VISITNUM;
quit;
/*calculate error bars*/
data sej_proj.vs_agg_1;
   set sej_proj.vs_agg;
   SE = SD/sqrt(N);                /* Standard Error */
   LOWER = MEAN - 1.96*SE;         /* Lower 95% CI */
   UPPER = MEAN + 1.96*SE;         /* Upper 95% CI */
run;
/*graph plot by using cl band and series*/
proc sgplot data=sej_proj.vs_agg_1;
   band x=VISITNUM lower=LOWER upper=UPPER / group=TRTLabel transparency=0.4;
   series x=VISITNUM y=MEAN / group=TRTLabel markers;
   xaxis values=(0 4 12 24) label="Visit (weeks)";
   yaxis label="Mean change from baseline (sbp)";
   title "Mean change from baseline by treatment arm";
run;
/*5.3. for "tr"*/
/*make a summary datasets*/
proc sql;
   create table sej_proj.tr_agg as
   select TRTLabel, VISITNUM,
          mean(CHANGE) as MEAN,
          std(CHANGE) as SD,
          count(CHANGE) as N
   from sej_proj.tr_chng
   group by TRTLabel, VISITNUM;
quit;
/*calculate error bars*/
data sej_proj.tr_agg_1;
   set sej_proj.tr_agg;
   SE = SD/sqrt(N);                /* Standard Error */
   LOWER = MEAN - 1.96*SE;         /* Lower 95% CI */
   UPPER = MEAN + 1.96*SE;         /* Upper 95% CI */
run;
/*graph plot by using cl band and series*/
proc sgplot data=sej_proj.tr_agg_1;
   band x=VISITNUM lower=LOWER upper=UPPER / group=TRTLabel transparency=0.4;
   series x=VISITNUM y=MEAN / group=TRTLabel markers;
   xaxis values=(0 4 12 24) label="Visit (weeks)";
   yaxis label="Mean change from baseline (tumsiz)";
   title "Mean change from baseline by treatment arm";
run;

/*6.Define & analyze primary and secondary endpoints*/
/*6.1primary end point "lb"*/
/*adding sex and age*/
proc sql;
   create table sej_proj.lb_chng_2_sub as
   select a.*, b.AGE, b.SEX
   from sej_proj.lb_chng_2 a
   left join sej_proj.sub_macro b
   on a.USUBJID = b.USUBJID;
quit;

/*extract data for 24 week*/
data sej_proj.hbaw24;   
   set sej_proj.lb_chng_2_sub;   
   where VISITNUM = 24; 
run;
/*summarize mean+-sd treatment*/
proc means data=sej_proj.hbaw24 mean std n;   
   class TRTLabel;   
   var CHANGE; 
run;
/*perform ancova*/
proc glm data=sej_proj.lb_chng_2_sub(where=(VISITNUM=24));   
   class TRTLabel;   
   model LBSTRESN = TRTLabel BASE_HBA1C AGE;   
   lsmeans TRTLabel / pdiff=all cl; 
   title "ANCOVA: HbA1c at Week 24 adjusted for baseline"; 
run; 
quit;
/*6.2.secondary end point "vs"*/
/*6.2.1.for "vs"*/
/*adding sex and age*/
proc sql;
   create table sej_proj.vs_chng_sub as
   select a.*, b.AGE, b.SEX
   from sej_proj.vs_chng a
   left join sej_proj.sub_macro b
   on a.USUBJID = b.USUBJID;
quit;

/*extract data for 24 week*/
data sej_proj.sbp24;   
   set sej_proj.vs_chng_sub;   
   where VISITNUM = 24; 
run;
/*summarize mean+-sd treatment*/
proc means data=sej_proj.sbp24 mean std n;   
   class TRTLabel;   
   var CHANGE; 
run;
/*perform ancova*/
proc glm data=sej_proj.vs_chng_sub(where=(VISITNUM=24));   
   class TRTLabel;   
   model vsorres = TRTLabel BASE_sbp AGE;   
   lsmeans TRTLabel / pdiff=all cl; 
   title "ANCOVA: sbp at Week 24 adjusted for baseline"; 
run; 
quit;
/*6.2.2.for "tr"*/
/*adding sex and age*/
proc sql;
   create table sej_proj.tr_chng_sub as
   select a.*, b.AGE, b.SEX
   from sej_proj.tr_chng a
   left join sej_proj.sub_macro b
   on a.USUBJID = b.USUBJID;
quit;

/*extract data for 24 week*/
data sej_proj.tumsiz24;   
   set sej_proj.tr_chng_sub;   
   where VISITNUM = 24; 
run;
/*summarize mean+-sd treatment*/
proc means data=sej_proj.tumsiz24 mean std n;   
   class TRTLabel;   
   var CHANGE; 
run;
/*perform ancova*/
proc glm data=sej_proj.tr_chng_sub(where=(VISITNUM=24));   
   class TRTLabel;   
   model trorres = TRTLabel BASE_tumsiz AGE;   
   lsmeans TRTLabel / pdiff=all cl; 
   title "ANCOVA: tumsize at Week 24 adjusted for baseline"; 
run; 
quit;

/*7.exporting the results*/
/* export summary datasets */
proc export data=sej_proj.lb_summary_2 
           outfile="/home/u64255837/result_sas_proj.csv" 
           dbms=csv replace;
run;
proc export data=sej_proj.lb_agg_1 
            outfile="/home/u64255837/result_sas_proj.csv" 
            dbms=csv replace; 
run;

/* create single PDF with all graphs (optional) */
ods pdf file="/home/u64255837/result_sas_proj.pdf";
proc sgplot data=sej_proj.lb_agg_1; /* plot code repeated or use ODS LAYOUT */ 
run;
proc sgplot data=sej_proj.vs_agg_1; 
run;
proc sgplot data=sej_proj.tr_agg_1; 
run;
ods pdf close;













