proc import datafile='/folders/myfolders/sample/file.xls' out=mydata dbms=xls 
		replace;
	guessingrows=100;
	getnames=yes;
run;

data mydata;
	set mydata;
	drop VAR1 response A;
		
run;

/*Data spliiting in new and existing customers*/
data existing_cust new_cust;
	set mydata;

	if pdays=999 then
		output new_cust;
	else
		output existing_cust;
run;

/*Outliers Treatment*/
proc means data=new_cust n nmiss mean std min p1 p10 p25 p50 p75 p95 p99 max;
run;

data new_cust;
	set new_cust;

	if duration>=1276 then
		duration=1276;
	pdays=0;
run;

proc means data=existing_cust n nmiss mean std min p1 p10 p25 p50 p75 p95 p99 
		max;
run;

data existing_cust;
	set existing_cust;

	if duration>=1176 then
		duration=1176;
run;

proc means data=mydata n nmiss mean std min p1 p10 p25 p50 p75 p95 p99 
		max;
run;

data mydata;
	set mydata;

	if duration>=1271 then
		duration=1271;
run;




/*Corelation Matrix*/
proc corr data=mydata;
var  age job marital education 
	default housing loan contact
	  month	day_of_week
		duration
		 campaign
		  pdays
		   previous
		    poutcome emp_var_rate
		      cons_price_idx 
		cons_conf_idx
		 euribor3m 
		 nr_employed response_c
		     ; 
		run;
		
		
PROC FACTOR DATA= mydata
METHOD = PRINCIPAL SCREE MINEIGEN=0 NFACTOR = 11
ROTATE = VARIMAX REORDER OUT= Factor;
var age job marital education 
	default housing loan contact
	  month	day_of_week
		duration
		 campaign
		  pdays
		   previous
		    poutcome emp_var_rate
		      cons_price_idx 
		cons_conf_idx
		 euribor3m 
		 nr_employed response;
run;



data development val;
set mydata;
if ranuni(12345)<=0.7 then output development;
else output val;
run;


		

proc logistic data = development DESCENDING/*by default it models for zero(ascending option)*/ 
outest=model;

model response_c = 
age  marital education 
	default housing loan contact
	  month	day_of_week
		duration
		 campaign
		  pdays
		   previous
		    poutcome emp_var_rate/ selection=stepwise  stb lackfit;
output out =temp p=newpred;
/*where New_customer=0;*/
run;



proc sort data=temp;
by descending newpred;
run;

proc rank data=temp groups=10 out=dev1;
/*by descending prob;*/
var newpred;
ranks probrank;
run;

data dev1;
set dev1;
probrank=probrank+1;
run;

proc sql;
select probrank, count(probrank) as cnt,sum(response_c) as response_cnt, min(newpred) as min_p, max(newpred) as max_p from dev1
group by probrank
order by probrank desc;
quit;



data val;
set val;
Odds_ratio=EXP(-0.8161+(employ*-0.2601)+(address*-0.0812)+(debtinc*0.0936)+(creddebt*0.5843));
Prob=(Odds_ratio/(1+Odds_ratio));
if Prob>0.4 then preD=1;
else preD=0;
run;

proc sort data=val;
by descending Prob;
run;

proc rank data=val groups=10 out=val1;
/*by descending prob;*/
var Prob;
ranks probrank;
run;

data val1;
set val1;
probrank=probrank+1;
run;

proc sql;
select probrank,
 count(probrank) as cnt,
 sum(default) as default_cnt,
 sum(preD) as Pred_cnt, 
 min(Prob) as min_p, 
 max(Prob) as max_p 
 from val1
group by  probrank
order by probrank desc;
quit;








































proc freq data=existing_cust;
	table poutcome pdays;
run;

proc freq data=new_cust;
	table poutcome pdays;
run;

proc freq data=mydata;
	table poutcome;
run;

proc means data=mydata n nmiss mean std min p1 p10 p25 p50 p75 p95 p99 max;
run;

proc contents data=mydata;
run;

proc freq data=mydata;
	table job marital education default housing loan pdays /norow nopercent nocol;
run;

data mydata;
	set mydata;
	where (job ne "unknown") and (marital ne "unknown") and (education ne 
		"unknown") and (housing ne "unknown") and (loan ne "unknown");
run;
proc export data=mydata outfile='/folders/myfolders/file.csv' dbms=csv replace;
run;