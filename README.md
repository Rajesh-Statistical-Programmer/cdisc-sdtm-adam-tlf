**Clinical SAS SDTM Mapping Project**

This repository contains a complete end-to-end Clinical SAS SDTM mapping project created to demonstrate real-world CDISC SDTM implementation using raw clinical trial data, developed in accordance with the CDISC SDTM Implementation Guide (IG) v3.4 standards.

**The project covers:**

Transformation of multiple raw CSV files into standard SDTM domains

Creation of Supplementary Qualifier datasets

Generation of permanent SDTM libraries

Export of XPT files for validation and submission

**Domains Implemented**

**The following SDTM domains are created in this project:**

Domain	Description
DM	Demographics
SUPPDM	Supplemental Qualifiers for DM
AE	Adverse Events
SUPPAE	Supplemental Qualifiers for AE
MH	Medical History
LB	Laboratory Test Results
EX	Exposure
SUPPEX	Supplemental Qualifiers for EX
VS	Vital Signs

**Each domain follows CDISC SDTM structure with:**

Proper variable naming and standardization

ISO 8601 date/time formatting

USUBJID creation using STUDYID, SITEID, and SUBJID

Sequence number generation (e.g., AESEQ, MHSEQ, LBSEQ, VSSEQ)

Controlled terminology using PROC FORMAT

Domain-specific KEEP, LENGTH, and LABEL logic

Permanent storage in SDTM library

XPT file creation for validation

**Key Features**

Realistic raw-to-SDTM transformation workflow

Use of macros for reusability and consistency

Supplementary domain creation using vertical structure (QNAM, QVAL, etc.)

Date and datetime handling using ISO 8601 standards

Transposition logic for Vital Signs (VS)

Industry-style programming practices

**Project Structure**

Raw data imported from CSV files

Intermediate datasets created for transformation

Final SDTM datasets stored in a permanent library

XPT files generated for submission and validation

**Purpose**

**This project is designed to:**

Demonstrate hands-on SDTM mapping skills

Showcase real-world Clinical SAS programming

**Author**

R. Rajesh Kumar
Clinical SAS Programmer
Background: B. Pharm Graduate with Clinical Research & SAS Programming Experience
