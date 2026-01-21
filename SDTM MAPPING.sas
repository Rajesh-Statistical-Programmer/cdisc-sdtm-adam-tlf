/*
1. DEMOGRAPHIC DOMAIN

CREATED BY: R. RAJESH KUMAR
POSITION: CLINICAL SAS PROGRAMMER

*/

PROC IMPORT DATAFILE = "/home/u64036442/dm.csv" DBMS = CSV OUT = DM_RAW REPLACE;
RUN;

PROC FORMAT;
	VALUE $GENDER "MALE" = "M" "FEMALE" = "F";
RUN;

DATA DM1;
SET DM_RAW;
	STUDYID  =  UPCASE(STRIP(study_id));
	DOMAIN   =  "DM";
	SUBJID   =  UPCASE(STRIP(subject_id));
	SITEID   =  PUT(site_number, 8.);
	USUBJID  =  STRIP(STUDYID)||"-"||STRIP(SITEID)||"-"||STRIP(SUBJID);
	RFSTDTC  =  PUT(enrollment_date, IS8601DA.);
	RFICDTC  =  PUT(informed_consent_date, IS8601DA.);
	BRTHDTC  =  PUT(birth_date, IS8601DA.);
	AGE      =  age_years;
	AGEU     =  "YEARS";
	SEX      =  PUT(gender, $gender.);
	RACE     =  STRIP(race_category);
	ETHNIC   =  STRIP(ethnicity);
	COUNTRY  =  STRIP(country_code);
RUN;

/* CREATING MACROS FOR KEEP LENGHT AND LABEL STATEMENT */

%MACRO DM_KEEP;
	(KEEP = STUDYID DOMAIN SUBJID SITEID USUBJID RFSTDTC 
	        RFICDTC BRTHDTC AGE AGEU SEX RACE ETHNIC COUNTRY);
%MEND DM_KEEP;

%MACRO DM_LENGTH;
LENGTH 
STUDYID  $20
DOMAIN   $2
USUBJID  $40
SUBJID   $20
RFSTDTC  $20
RFICDTC  $20
SITEID   $20
BRTHDTC  $20
AGE       8.
AGEU     $10
SEX      $1
RACE     $30
ETHNIC   $30
COUNTRY  $3;
%MEND DM_LENGTH;

%MACRO DM_LABEL;
LABEL 
STUDYID  =  "Study Identifier"
DOMAIN   =  "Domain Abbreviation"
USUBJID  =  "Unique Subject Identifier"
SUBJID   =  "Subject Identifier for the Study"
RFSTDTC  =  "Subject Reference Start Date/Time"
RFICDTC  =  "Date/Time of Informed Consent"
SITEID   =  "Study Site Identifier"
BRTHDTC  =  "Date/Time of Birth"
AGE      =  "Age"
AGEU     =  "Age Units"
SEX      =  "Sex"
RACE     =  "Race"
ETHNIC   =  "Ethnicity"
COUNTRY  =  "Country";
%MEND DM_LABEL;

/* CREATING FINAL DM DATASET FROM DM1 */

PROC SORT DATA = DM1; BY USUBJID; RUN; 

DATA DM %DM_KEEP; %DM_LENGTH; %DM_LABEL;
SET DM1; RUN; 

/*-----------------------------------------------*/
/*
	2. DM SUPPLEMENTRY DOMAIN
	CREATED BY: R. RAJESH KUMAR
	
	
*/

/* RENAMEING study_id and subject_id FOR MERGING RAW DATA AND INTERMEDIATE DM DATA */

DATA DM_RAW1; 
SET DM_RAW (RENAME = (study_id = STUDYID subject_id = SUBJID));
RUN;

/* SORTING DM_RAW1 AND DM1 BEFORE MERGING BY COMMON VARIABLES */

PROC SORT DATA = DM_RAW1 ; BY SUBJID STUDYID; RUN;
PROC SORT DATA = DM1; BY SUBJID STUDYID; RUN;

/* 
1.MERGING INTERMEDICATE DM DATASET AND RAW DATASET
2. IT WILL CONTAIN USUBJID AND OTHER SUPPDM VARIABLES
3. IT WILL BE EASY FOR COMBINING DM AND SUPPDM WHILE VALIDATING */

DATA SUPPDM1;
MERGE DM1 (IN = A) DM_RAW1  (IN = B) ;
BY STUDYID SUBJID; IF A; RUN;

PROC SORT DATA = SUPPDM1; BY USUBJID; RUN;

/* FINAL SUPPDM DATASET */
DATA SUPPDM 
(KEEP =STUDYID DOMAIN USUBJID RDOMAIN IDVAR IDVARVAL QNAM QLABEL QVAL QORIG);
LENGTH STUDYID $20 USUBJID $40 RDOMAIN $2 IDVAR $8 IDVARVAL $40 
       QNAM $8 QLABEL $40 QVAL $200 QORIG $10;
SET SUPPDM1;
        DOMAIN   =  "SUPPDM";
		RDOMAIN  =  DOMAIN; 
		IDVAR    =  "";
		IDVARVAL =  "";
		
		QNAM     =  "HEIGHT";
		QLABEL   =  "HEIGHT (CM)";
		QVAL     =  STRIP(PUT(height_cm, best.));
		QORIG    =  "CRF";
		OUTPUT;
		
		QNAM     =  "WEIGHT";
		QLABEL   =  "WEIGHT (KG)";
		QVAL     =  STRIP(PUT(weight_kg, best.));
		QORIG    =  "CRF";
		OUTPUT;
		
		QNAM     =  "MEDHIST";
		QLABEL   =  "MEDICAL HISTORY";
		QVAL     =  STRIP(medical_history);
		QORIG    =  "CRF";
		OUTPUT;
		
		QNAM     =  "SMOSTS";
		QLABEL   =  "SMOKING STATUS";
		QVAL     =  STRIP(smoking_status);
		QORIG    =  "CRF";
		OUTPUT;
		
		QNAM     =  "ACLUSE";
		QLABEL   =  "ALCOOL USE";
		QVAL     =  STRIP(alcohol_use);
		QORIG    =  "CRF";
		OUTPUT;
RUN;

/* STRONG THE DATASET IN PERMANENT LIBRARY */

LIBNAME SDTM "/home/u64036442/sasuser.v94";

DATA SDTM.DM;
SET WORK.DM; RUN; 

DATA SDTM.SUPPDM;
SET WORK.SUPPDM; RUN;

/* CREATING XPT FILE FOR VALIDATION PURPOSE */

LIBNAME XPTDM XPORT "/home/u64036442/sasuser.v94/DM.XPT";

DATA XPTDM.DM;
SET SDTM.DM; RUN; 

LIBNAME XPTSDM XPORT "/home/u64036442/sasuser.v94/SUPPDM.XPT";

DATA XPTSDM.SUPPDM;
SET SDTM.SUPPDM; RUN; 

/* -------------------------------------------------------------
3. ADVERSE EVENT
CREATED BY: R. RAJESH KUMAR

*/

/* IMPORTING AE.CSV FILE AND NAMING IT AS RAW_AE */

PROC IMPORT DATAFILE = "/home/u64036442/ae_raw_20251213_041915.csv" DBMS = CSV 
OUT = RAW_AE REPLACE; RUN;

PROC FORMAT;
VALUE $YESORNO "Yes"="Y" "No"="N";
RUN;

DATA AE1; LENGTH STUDYID $20 SUBJID $20 AEACN $12 AEREL $8 AEOUT $12;
SET RAW_AE;
		STUDYID  =  UPCASE(STRIP(study_id));
		DOMAIN   =  "AE";
		SUBJID   =  UPCASE(STRIP(subject_id));
		AETERM   =  strip(event_term);
		AESPID   =  strip(ae_number);
		AESEV    =  UPCASE(strip(severity));
		AESER    =  PUT(serious, $YESORNO.);
		AEREL    =  UPCASE(strip(relationship_to_study_drug));
		AEACN    =  UPCASE(strip(action_taken));
		AEACNOTH =  UPCASE(strip(treatment_details));
		AEOUT    =  UPCASE(strip(outcome));
		AESCONG  =  PUT(congenital_anomaly, $YESORNO.);
		AESDISAB =  PUT(disability, $YESORNO.);
		AESHOSP  =  PUT(hospitalization, $YESORNO.);
		AESLIFE  =  PUT(life_threatening, $YESORNO.);
		AESDTH   =  PUT(death, $YESORNO.);
		AESMIE   =  PUT(medically_important, $YESORNO.);
RUN;

	
/* RAW_AE DOES NOT CONTAIN SITEID DETAILS, 
SO WE NEED TO MERGE DM DATASET TO CREATE USUBJID */

DATA DM_DUP;
SET DM (KEEP = STUDYID SUBJID SITEID USUBJID);
RUN;

PROC SORT DATA = AE1; BY STUDYID SUBJID; RUN; 
PROC SORT DATA = DM_DUP; BY STUDYID SUBJID; RUN; 

DATA AE2;
MERGE AE1 (IN = A) DM_DUP (IN = B);
BY STUDYID SUBJID; IF A; RUN; 

/* CREATING AE SEQUENCE NUMBER */

PROC SORT DATA = AE2; BY USUBJID; RUN; 

DATA AE3;
SET AE2; 
BY USUBJID; 

IF FIRST.USUBJID THEN AESEQ=1;
ELSE AESEQ +1; RUN; 

/* CREATING AE DATE VARIABLES */

DATA AE4;
SET AE3;
		
AESTDTC1 = DHMS((start_date), hour(start_time), minute(start_time), second(start_time));
AESTDTC  = PUT(AESTDTC1, IS8601DT.);

AEENDTC1 = DHMS((end_date), hour(end_time), minute(end_time), second(end_time));
IF ongoing = "No" AND NOT MISSING(AEENDTC1) THEN AEENDTC = PUT(AEENDTC1, IS8601DT.);
ELSE IF ongoing = "Yes" AND MISSING(AEENDTC1) THEN AEENDTC = " ";
RUN; 

/* 1. CREATING FINAL AE DATASET
   2. CREATING MACRO FOR KEEP LENGTH AND LABEL STATEMENT AND UTILIZE THEM IN THE CODE */


%MACRO AE_KEEP;
(KEEP = STUDYID DOMAIN USUBJID AESEQ AESPID AETERM AESEV AESER AEACN 
		AEACNOTH AEREL AEOUT AESCONG AESDISAB AESDTH AESHOSP AESLIFE 
		AESMIE AESTDTC AEENDTC);
%MEND AE_KEEP;

%MACRO AE_LENGTH;
LENGTH 
STUDYID   $20
DOMAIN    $2
USUBJID   $40
AESEQ      8.
AESPID    $20
AETERM    $200
AESEV     $8
AESER     $1
AEACN     $12
AEACNOTH  $200
AEREL     $8
AEOUT     $12
AESCONG   $1
AESDISAB  $1
AESDTH    $1
AESHOSP   $1
AESLIFE   $1
AESMIE    $1
AESTDTC   $19
AEENDTC   $19 ;
%MEND AE_LENGTH;

%MACRO AE_LABEL;
LABEL 
STUDYID   =  "Study Identifier"
DOMAIN    =  "Domain Abbreviation"
USUBJID   =  "Unique Subject Identifier"
AESEQ     =  "Sequence Number"
AESPID    =  "Sponsor-Defined Identifier"
AETERM    =  "Reported Term for the Adverse Event"
AESEV     =  "Severity/Intensity"
AESER     =  "Serious Event"
AEACN     =  "Action Taken with Study Treatment"
AEACNOTH  =  "Other Action Taken"
AEREL     =  "Causality"
AEOUT     =  "Outcome of Adverse Event"
AESCONG   =  "Congenital Anomaly or Birth Defect"
AESDISAB  =  "Persist or Signif Disability/Incapacity"
AESDTH    =  "Results in Death"
AESHOSP   =  "Requires or Prolongs Hospitalization"
AESLIFE   =  "Is Life Threatening"
AESMIE    =  "Other Medically Important Serious Event"
AESTDTC   =  "Start Date/Time of Adverse Event"
AEENDTC   =  "End Date/Time of Adverse Event"
%MEND AE_LABEL;

/* FINAL AE DATASET */

DATA AE %AE_KEEP; %AE_LENGTH; %AE_LABEL;
SET AE4; RUN; 

DATA SDTM.AE;
SET WORK.AE; RUN; 


/* CREATING SUPPAE DOMAIN  */

DATA RAW_AE1;
SET RAW_AE(RENAME = (study_id = STUDYID subject_id = SUBJID));
RUN;

PROC SORT DATA = RAW_AE1; BY SUBJID STUDYID; RUN;
PROC SORT DATA = AE4; BY SUBJID STUDYID; RUN; 

/* MERGING RAW_AE DATASET AND INTERMEDIATE AE1 DATASET,
SO THAT WE CAN ACCESS USUBJID AND OTHER DETAILS */

DATA SUPPAE1; 
MERGE AE4 (IN = A) RAW_AE1 (IN = B);
BY SUBJID STUDYID;
IF A ;
RUN;

DATA SUPPAE (KEEP = STUDYID RDOMAIN USUBJID IDVAR IDVARVAL 
QNAM QLABEL QVAL QORIG QEVAL);
SET SUPPAE1;

LENGTH 
    STUDYID    $20
    RDOMAIN    $2
    USUBJID    $40
    IDVAR      $8
    IDVARVAL   $40
    QNAM       $8
    QLABEL     $40
    QVAL       $200
    QORIG      $10
    QEVAL      $20
;
DOMAIN   = "SUPPAE";
RDOMAIN  = DOMAIN;
IDVAR    = "AESEQ";
IDVARVAL = STRIP(PUT(AESEQ, BEST8.));
QORIG    = "CRF";


IF NOT MISSING(reporter) THEN DO;
QNAM     = "REPORTER";
QLABEL   = "AE Reporter";
QVAL     = STRIP(REPORTER);
OUTPUT; END;

IF NOT MISSING(report_date) THEN DO;
QNAM     = "RPTDATE";
QLABEL   = "AE Report Date";

IF report_date NE "." THEN QVAL = PUT(report_date, IS8601DA.);
ELSE QVAL = "."; 
OUTPUT; END;
 
IF NOT MISSING(treatment_given) THEN DO;
QNAM   = "TRTGIVEN";
QLABEL = "Treatment Given for AE";
QVAL   = STRIP(treatment_given);
OUTPUT; END;

RUN;

/* STORING AE AND SUPPAE IN THE PERMENANET LIBRARY */

DATA SDTM.AE;
SET WORK.AE; RUN;


DATA SDTM.SUPPAE;
SET WORK.SUPPAE; RUN;

LIBNAME XPTAE XPORT "/home/u64036442/sasuser.v94/AE.XPT";

DATA XPTAE.AE;
SET SDTM.AE; RUN; 

LIBNAME XPTSAE XPORT "/home/u64036442/sasuser.v94/SUPPAE.XPT";

DATA XPTSAE.SUPPAE;
SET SDTM.SUPPAE; RUN;

/*-------------------------------------------------------------------*/
/* 5. MEDICAL HISTORY DOMAIN

CREATED BY: R. RAJESH KUMAR

*/

PROC IMPORT DATAFILE = "/home/u64036442/mh_raw_20251213_041915.csv"
DBMS = CSV OUT = RAW_MH REPLACE; RUN;

PROC FORMAT;
VALUE $YESORNO "Yes"="Y" "No"="N";
RUN;

DATA MH1; LENGTH STUDYID $20 SUBJID $20 MHENDTC $20 MHENRF $20 ;
SET RAW_MH;

STUDYID = STRIP(study_id);
SUBJID  = STRIP(subject_id);
DOMAIN  = "MH";
MHSPID  = STRIP(condition_number);
MHTERM  = STRIP(medical_condition);
MHSTDTC = PUT(start_date, IS8601DA.);

IF MISSING(end_date) AND ongoing = "Yes" THEN DO;
MHENDTC = " ";
MHENRF  = "ONGOING"; END;


ELSE IF NOT MISSING(end_date) AND ongoing = "No" THEN DO;
MHENDTC = PUT(end_date, IS8601DA.);
MHENRF = " "; 
END;
RUN;

/* CREATING UNIQUE SUBJECT IDENTIFIER */

PROC SORT DATA = MH1; BY SUBJID STUDYID; RUN;
PROC SORT DATA = DM; BY SUBJID STUDYID; RUN; 

DATA MH2;
MERGE  MH1 (IN = A) DM (IN = B);
BY SUBJID STUDYID; 
IF A; 
RUN; 

/* CREATING MH SEQUENCE NUMBER */

PROC SORT DATA = MH2; BY USUBJID; RUN; 

DATA MH3; 
SET MH2;
BY USUBJID; 

IF FIRST.USUBJID THEN MHSEQ = 1;
ELSE MHSEQ+1;
RUN;


/*CREATING MACRO FOR KEEP LENGTH AND LABEL STATEMENT 
AND UTILIZING THEM IN THE FINAL MH DATASET */

%MACRO MH_KEEP;
(KEEP = STUDYID DOMAIN USUBJID MHSEQ MHSPID MHTERM MHSTDTC MHENDTC MHENRF);
%MEND MH_KEEP;

%MACRO MH_LENGTH;
LENGTH 
    STUDYID   $20
    DOMAIN    $2
    USUBJID   $40
    MHSEQ      8.
    MHSPID    $20
    MHTERM    $200
    MHSTDTC   $20
    MHENDTC   $20
    MHENRF    $20
%MEND MH_LENGTH;

%MACRO MH_LABEL;
LABEL 
    STUDYID = "Study Identifier"
    DOMAIN  = "Domain Abbreviation" 
    USUBJID = "Unique Subject Identifier"
    MHSEQ   = "Sequence Number"
    MHSPID  = "Sponsor-Defined Identifier"
    MHTERM  = "Reported Ter for the  Medical History"
    MHSTDTC = "Start Date/Time of History Collection" 
    MHENDTC = "End Date/Time of History Collection"
    MHENRF  = "End Relative to Reference Period";
 %MEND MH_LABEL;


DATA MH %MH_KEEP; %MH_LENGTH; %MH_LABEL; 
SET MH3; 
RUN; 

/* STORING MH DATASET IN PERMANENT SDTM LIBRARY */

DATA SDTM.MH;
SET WORK.MH; RUN; 

LIBNAME XPTMH XPORT "/home/u64036442/sasuser.v94/MH.XPT";

DATA XPTMH.MH;
SET SDTM.MH; RUN; 

/*--------------------------------------------------*/

/* 6. CREATING LABORATORY TEST RESULTS (LB) DATASET */

PROC IMPORT DATAFILE = "/home/u64036442/rawlb1_raw_20251213_041915.csv"
DBMS = CSV OUT = LB1 REPLACE; RUN; 

DATA LB2; LENGTH STUDYID $20 SUBJID $20;
SET LB1; 

STUDYID  =  STRIP(study_id);
DOMAIN   =  "LB";
SUBJID   =  STRIP(subject_id);
VISIT    =  STRIP(visit_name);
LBTEST   =  STRIP(test_name);
LBORRES  =  PUT(result_value, 8.2);
LBORRESU =  STRIP(result_unit);
LBORNRLO =  PUT(reference_range_low, 8.);
LBORNRHI =  PUT(reference_range_high, 8.);
LBNRIND  =  STRIP(abnormal_flag);
LBDATE   =  INPUT(PUT(collection_date, DATE10.), DATE10.);
LBTIME   =  INPUT(PUT(collection_time, TIME8.), TIME8.);
LBDTC    =  PUT(DHMS(LBDATE, HOUR(LBTIME), MINUTE(LBTIME), SECOND(LBTIME)), IS8601DT.);

IF clinical_significance = "Clinically significant" THEN LBCLSIG = "Y";
ELSE IF clinical_significance = "Not clinically significant" THEN LBCLSIG = "N";
ELSE IF clinical_significance = "Not applicable" THEN LBCLSIG = ".";
IF fasting_status = "Yes" THEN LBFAST = "Y";
ELSE IF fasting_status = "No" THEN LBFAST = "N";
ELSE IF fasting_status = "Not applicable" THEN LBFAST = ".";
RUN;

PROC SORT DATA = DM; BY STUDYID SUBJID; RUN; 
PROC SORT DATA = LB2; BY STUDYID SUBJID; RUN; 

DATA LB3; 
MERGE LB2 (IN = A) DM (IN = B);
BY STUDYID SUBJID; IF A;
RUN; 

PROC SORT DATA = LB3; BY USUBJID; RUN;

DATA LB4; 
SET LB3; 
BY USUBJID; 

IF FIRST.USUBJID THEN LBSEQ = 1;
ELSE LBSEQ + 1; 

RUN;


/* CREATING MACRO FOR KEEP AND LENGTH AND LABEL STATEMENTS */

%MACRO LB_KEEP;
(KEEP = STUDYID DOMAIN USUBJID LBSEQ LBTEST LBORRES
LBORRESU LBORNRLO LBORNRHI LBNRIND LBFAST LBCLSIG VISIT 
LBDTC );
%MEND LB_KEEP;

%MACRO LB_LENGTH;
LENGTH 
STUDYID   $20
DOMAIN    $2
USUBJID   $40
LBSEQ      8.
LBTEST    $40
LBORRES   $40
LBORRESU  $20
LBORNRLO  $20
LBORNRHI  $20
LBNRIND   $8
LBFAST    $1
LBCLSIG   $1
VISIT     $40
LBDTC     $25
;
%MEND LB_LENGTH;

%MACRO LB_LABEL;
LABEL
STUDYID   = "Study Identifier"
DOMAIN    = "Domain Abbreviation"
USUBJID   = "Unique Subject Identifier"
LBSEQ     = "Sequence Number"
LBTEST    = "Laboratory Test Name"
LBORRES   = "Original Result"
LBORRESU  = "Original Units"
LBORNRLO  = "Reference Range Lower Limit-Original Units"
LBORNRHI  = "Reference Range Upper Limit-Original Units"
LBNRIND   = "Reference Range Indicator"
LBFAST    = "Fasting Status"
LBCLSIG   = "Clinically Significant"
VISIT     = "Visit Name"
LBDTC     = "Date/Time of Specimen Collection"
;
%MEND LB_LABEL;

DATA LB %LB_KEEP; %LB_LENGTH; %LB_LABEL;
SET LB4;
RUN;

DATA SDTM.LB;
SET WORK.LB; RUN;

LIBNAME XPTLB XPORT "/home/u64036442/sasuser.v94/LB.XPT";

DATA XPTLB.LB;
SET SDTM.LB; RUN; 


/*--------------------------------------------------------------------------*/

/* CREATING EXPOSURE DOMAIN (EX)

CREATED BY: R. RAJESH KUMAR

*/

PROC IMPORT DATAFILE = "/home/u64036442/ex_raw_20251213_041915.csv"
DBMS = CSV OUT = EX1 REPLACE; RUN; 

DATA EX2 ; LENGTH STUDYID $20 SUBJID $20; 
SET EX1; 
STUDYID   =   STRIP(study_id);
DOMAIN    =   "EX";
SUBJID    =   STRIP(subject_id);
EXSTDTC   =   PUT(DHMS((administration_date), HOUR(administration_time), MINUTE(administration_time), SECOND(administration_time)), IS8601DT.);
EXTRT     =   STRIP(study_drug_name);
EXDOSE    =   dose_administered;
EXDOSEU   =   STRIP(dose_unit);
EXROUTE   =   STRIP(route_of_administration);
EXDOSFRM  =   STRIP(formulation);
EXLOT     =   lot_number;
EXADJ     =   STRIP(modification_reason);
RUN;

/* CREATING USUBJID FOR EXPOSURE DOMAIN */

PROC SORT DATA = EX2; BY SUBJID STUDYID; RUN;
PROC SORT DATA = DM; BY SUBJID STUDYID; RUN;

DATA EX3;
MERGE EX2 (IN = A) DM (IN = B);
BY SUBJID STUDYID; IF A;
RUN;

PROC SORT DATA = EX3; BY USUBJID; RUN; 

DATA EX4; 
SET EX3;
BY USUBJID; 

IF FIRST.USUBJID THEN EXSEQ = 1;
ELSE EXSEQ + 1;
RUN; 

/* CREATING MACROS FOR KEEP LENGTH AND LABEL STATEMENTS */

%MACRO EX_KEEP; 
(KEEP = STUDYID DOMAIN USUBJID EXSEQ EXTRT EXDOSE EXDOSEU
EXROUTE EXDOSFRM EXLOT EXADJ);
%MEND EX_KEEP;

%MACRO EX_LENGTH;
LENGTH
STUDYID  $20
DOMAIN   $2
USUBJID  $40
EXSEQ     8.
EXTRT    $200
EXDOSE    8.
EXDOSEU  $40
EXROUTE  $40
EXDOSFRM $40
EXLOT    $40
EXADJ    $40
%MEND EX_LENGTH;

%MACRO EX_LABEL;
LABEL
STUDYID  = "Study Identifier"
DOMAIN   = "Domain Abbreviation"
USUBJID  = "Unique Subject Identifier"
EXSEQ    = "Sequence Number"
EXTRT    = "Name of Treatment"
EXDOSE   = "Dose"
EXDOSEU  = "Dose Unit"
EXROUTE  = "Route of Administration"
EXDOSFRM = "Dosage Form"
EXLOT    = "Lot Number"
EXADJ    = "Dose Adjustment Reason"
%MEND EX_LABEL;

DATA EX %EX_KEEP; %EX_LENGTH; %EX_LABEL;
SET EX4; RUN; 

/* CREATING PERMANENT EX DATASET */

DATA SDTM.EX;
SET WORK.EX; 
RUN; 



/* CREATING EXPOSURE SUPPLEMENTRY DOMAIN  */
  
/* DM SUPPLEMENTRY DOMAIN

	CREATED BY: R. RAJESH KUMAR

/* RENAMEING study_id and subject_id FOR MERGING RAW EX DATA AND EX DATA */

DATA EX_DUP; LENGTH SUBJID $20 STUDYID $20;
SET EX1 (RENAME = (study_id = STUDYID subject_id = SUBJID));
RUN;

/* SORTING DM_RAW1 AND DM1 BEFORE MERGING BY COMMON VARIABLES */

PROC SORT DATA= EX4 ; BY SUBJID STUDYID; RUN;
PROC SORT DATA= EX_DUP; BY SUBJID STUDYID; RUN;

/* 
1.MERGING DUP_EX DATASET AND EX DATASET TO CREATE SUPP DOMAIN
2. EX_DUP WILL CONTAIL ALL THE RAW VARIABLES AND EX4 WILL CONTAIN USUBJID --> FOR MERGING
3. IT WILL BE EASY FOR COMBINING EX AND SUPPEX WHILE VALIDATING */

DATA SUPPEX1;
MERGE EX_DUP (IN = A) EX4 (IN = B);
BY SUBJID STUDYID;
IF A; RUN; 

PROC SORT DATA=SUPPEX1; BY USUBJID; RUN;

/* FINAL SUPPDM DATASET */

DATA SUPPEX 
(KEEP=STUDYID USUBJID RDOMAIN IDVAR IDVARVAL QNAM QLABEL QVAL QORIG);
LENGTH STUDYID $20 USUBJID $40 RDOMAIN $2 IDVAR $8 IDVARVAL $40 QNAM $8 QLABEL $40 QVAL $200 QORIG $10;
SET SUPPEX1;
		
        RDOMAIN  = "EX";
        IDVAR    = "EXSEQ";
        IDVARVAL = STRIP(PUT(EXSEQ, BEST.));
		
		QNAM   =  "VISIT";
		QLABEL =  "NAME OF THE VISIT";
		QVAL   =  STRIP(visit_name);
		QORIG  =  "CRF";
		OUTPUT;
		
		QNAM   =  "COMPLPCT";
		QLABEL =  "Compliance Percentage";
		QVAL   =  STRIP(PUT(compliance_percent, BEST.));
		QORIG  =  "CRF";
		OUTPUT;
		
		QNAM   =  "MISSDOSE";
		QLABEL =  "Missed Dose";
		QVAL   =  STRIP(PUT(missed_doses, BEST.));
		QORIG  =  "CRF";
		OUTPUT;
		
		QNAM   =  "DOSEMOD";
		QLABEL =  "Dose Modification";
		QVAL   =  PUT(dose_modification, $YESORNO.);
		QORIG  =  "CRF";
		OUTPUT;
		
		QNAM   =  "ADMINBY";
		QLABEL =  "Dose Administered By";
		QVAL   =  STRIP(administered_by);
		QORIG  =  "CRF";
		OUTPUT;
		
		QNAM   =  "STORCOND";
		QLABEL =  "Storage Condition Met";
		QVAL   =  PUT(storage_condition_met, $YESORNO.);
		QORIG  =  "CRF";
		OUTPUT;
RUN;

DATA SDTM.SUPPEX;
SET WORK.SUPPEX; RUN; 

LIBNAME XPTEX XPORT "/home/u64036442/sasuser.v94/EX.XPT";

DATA XPTEX.EX;
SET SDTM.EX; RUN; 

LIBNAME XPTSEX XPORT "/home/u64036442/sasuser.v94/SUPPEX.XPT";

DATA XPTSEX.SUPPEX;
SET SDTM.SUPPEX; RUN;

/* CREATING VITAL SCIENCE DATASET 

CREATED BY: R. RAJESH KUMAR

*/


PROC IMPORT DATAFILE = "/home/u64036442/rawvs1_raw_20251213_041915.csv"
DBMS = CSV OUT = VS1 REPLACE; RUN;

PROC FORMAT ;
VALUE $VISITNUM
"Baseline"  = 1
"Screening" = 2
"Week 2" = 3
"Week 4" = 4
"Week 8" = 5
"Week 12" = 6
;
RUN; 

DATA VS2; LENGTH SUBJID $20 STUDYID $20;
SET VS1;

STUDYID   =  STRIP(study_id);
DOMAIN    =  "VS";
SUBJID    =  STRIP(subject_id); 
VSDTC     =  PUT(DHMS((assessment_date), HOUR(assessment_time), MINUTE(assessment_time), SECOND(assessment_time)), IS8601DT.);
VISIT     =  STRIP(visit_name);
VISITNUM = input(put(VISIT, $VISITNUM.), best.);
RUN; 

PROC SORT DATA = VS2; BY SUBJID VISITNUM VSDTC; RUN; 

PROC TRANSPOSE DATA = VS2 OUT = VS3 (RENAME= (_NAME_ = TEST_NAME col1 = VSORRES1)); 
BY SUBJID VISITNUM VSDTC; 
VAR 
diastolic_bp_mmhg
oxygen_saturation_percent
pulse_rate_bpm
respiratory_rate_breaths_per_min
systolic_bp_mmhg
temperature_celsius
; 
RUN; 

PROC SORT DATA = VS2; BY SUBJID VISITNUM VSDTC ; RUN;
PROC SORT DATA = VS3; BY SUBJID VISITNUM VSDTC ; RUN; 

DATA VS4;
MERGE VS2 (IN = A) VS3 (IN = B);
BY SUBJID VISITNUM VSDTC;
IF A; 
RUN; 


DATA VS5;
SET VS4; 

IF TEST_NAME = "diastolic_bp_mmhg" THEN DO;
VSTEST   = "Diastolic Blood Pressure";
VSTESTCD = "DIABP";
VSORRESU = "mmHg";
END;

ELSE IF TEST_NAME = "systolic_bp_mmhg" THEN DO;
VSTEST   = "Systolic Blood Pressure";
VSTESTCD = "SYSBP";
VSORRESU = "mmHg"; 
END;

ELSE IF TEST_NAME = "pulse_rate_bpm" THEN DO;
VSTEST   = "Pulse Rate";
VSTESTCD = "PULSE";
VSORRESU = "beats/min"; 
END;

ELSE IF TEST_NAME = "respiratory_rate_breaths_per_min" THEN DO;
VSTEST   = "Respiratory Rate";
VSTESTCD = "RESP";
VSORRESU = "breaths/min";
END;

ELSE IF TEST_NAME = "oxygen_saturation_percent" THEN DO;
VSTEST   = "Oxygen Saturation";
VSTESTCD = "O2SAT";
VSORRESU = "%";
END;  

ELSE IF TEST_NAME = "temperature_celsius" THEN DO;
VSTEST   = "Body Temperature";
VSTESTCD = "TEMP"; 
VSORRESU = "C"; END; 

VSPOS    =  STRIP(position_during_measurement);
VSLOC    =  "ARM";
VSLAT    =  "RIGHT"; 
VSORRES  =  STRIP(VSORRES1);
VSSTRESC =  strip(VSORRES1);
VSSTRESN =  input(VSORRES1, best.);
VSSTRESU =  VSORRESU;

RUN; 

PROC SORT DATA = VS5; BY SUBJID ; RUN; 
PROC SORT DATA = DM_DUP; BY SUBJID; RUN;

DATA VS6;
MERGE VS5 (IN = A) DM_DUP (IN = B);
BY SUBJID;
RUN;


PROC SORT DATA = VS6; BY USUBJID VISITNUM VSDTC; RUN;

DATA VS7;
SET VS6;
BY USUBJID VISITNUM VSDTC; 

IF FIRST.USUBJID THEN VSSEQ = 1;
ELSE VSSEQ + 1;
RUN; 

/* CREATING FINAL VS DATASET */

%MACRO VS_KEEP;
(KEEP = STUDYID DOMAIN USUBJID VSSEQ VSTESTCD VSTEST VSORRES VSORRESU
        VSSTRESC VSSTRESN VSSTRESU VSLOC VSLAT VISITNUM VISIT VSDTC);
%MEND VS_KEEP;

%MACRO VS_LENGTH;
LENGTH 
STUDYID   $20
DOMAIN    $2
USUBJID   $40
VSSEQ      8.
VSTESTCD  $8
VSTEST    $40
VSORRES   $40
VSORRESU  $20
VSSTRESC  $40
VSSTRESN   8.
VSSTRESU  $20
VSLOC     $20
VSLAT     $20
VISITNUM   8.
VISIT     $40
VSDTC     $20
;
%MEND VS_LENGTH;

%MACRO VS_LABEL;
LABEL
STUDYID   = "Study Identifier"
DOMAIN    = "Domain Abbreviation"
USUBJID   = "Unique Subject Identifier"
VSSEQ     = "Sequence Number"
VSTESTCD  = "Vital Signs Test Short Name"
VSTEST    = "Vital Signs Test Name"
VSORRES   = "Result or Finding in Original Units"
VSORRESU  = "Original Units"
VSSTRESC  = "Character Result/Finding in Standardized Units"
VSSTRESN  = "Numeric Result/Finding in Standardized Units"
VSSTRESU  = "Standardized Units"
VSLOC     = "Location of Vital Signs Measurement"
VSLAT     = "Laterality of Vital Signs Measurement"
VISITNUM  = "Numeric Version Of Visit"
VISIT     = "Visit Name"
VSDTC     = "Date/Time of Vital Signs"
;
%MEND VS_LABEL;


DATA VS %VS_KEEP; %VS_LENGTH; %VS_LABEL;
SET VS7;
RUN; 

/* MAKING VS DATAST PERMANENT */

DATA SDTM.VS;
SET WORK.VS; 
RUN;

LIBNAME XPTVS XPORT "/home/u64036442/sasuser.v94/VS.XPT";

DATA XPTVS.VS;
SET SDTM.VS; RUN; 

/* ------------------------------------------------------- */



