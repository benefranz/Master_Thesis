************************************************************************
* TABLE OF CONTENTS
************************************************************************

* Project: 
* Creator: Benedikt Franz, bfranz@mail.uni-mannheim.de, 07.10.2021
* Last data update: 07.10.2021

/* Data In: 
	1. Tankerkönig Preise
	2. Tankerkönig Tankstellen
	3. ich-tanke Autbahntankstellen und Bundesstraßentankstellen
*/
/* Data Out: 
	1. 

*/

* Purpose of do-file: Create data set for the analysis of the temporary VAT reduction in Germany

/*		Outline:
		1. 
*/


clear all
set more off
cap log close



*-------------------------------------------------*
*--					Packages					--*
*-------------------------------------------------*
cap ssc install geonear
cap ssc install asgen



*-------------------------------------------------*
*--					Directories					--*
*-------------------------------------------------*

global main "/Users/benediktfranz/OneDrive - bwedu/Studium/Master/MasterThesis/Replication" // Global to define main location
cd "$main"
global data_in "$main/Data Input"
global data_out "$main/Data Output"
global source "$data_out/Source"
global intermediate "$data_out/Intermediate"
global final "$data_out/Final"
global graphs "$main/Graphs"
global tables "$main/Tables"
global dofiles "$main/Do-Files"

cap mkdir "$data_in"
cap mkdir "$data_out"
cap mkdir "$source" 
cap mkdir "$source/Prices_Germany"
cap mkdir "$source/Stations_Germany"
cap mkdir "$source/Mobility"
cap mkdir "$intermediate"
cap mkdir "$final"
cap mkdir "$graphs"
cap mkdir "$tables"
cap mkdir "$dofiles"




*-------------------------------------------------*
*--					Do-Files					--*
*-------------------------------------------------*

do "$dofiles/01_data_replication"
*do "$dofiles/02_analysis_thesis"
*do "$dofiles/03_graphs_thesis"	
