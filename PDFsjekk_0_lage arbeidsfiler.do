* FELLES SCRIPT FOR ALLE PROFILER
* (Bruksanvisning og notater: se nederst)	

********************************************************************
******      REDIGERINGSBEHOV i scriptet: 
******		Hele metoden for kommunenavn. LIGGER I SEPARAT FIL.	****
********************************************************************
* KJØRING
*pause off


* SAMLE TIL ÉN FIL
*************************
cd "$datafiler"
noisily di "Arbeidskatalog:"
noisily pwd

* Tekstfilen
import delimited Nynorsk_lespdf.csv, varnames(1) encoding("UTF-8") favorstrfixed clear
	*import delimited Lest_18-02_Nynorsk_lespdf.csv, /*delimiter(";")*/ varnames(1) encoding("Windows-1252") clear
save Nynorsk, replace 	//må på .dta-format for senere å kunne appendes

import delimited Bokmaal_lespdf.csv, varnames(1) encoding("UTF-8") favorstrfixed clear
	*import delimited Lest_18-02_Bokmaal_lespdf.csv, /*delimiter(";")*/ varnames(1) encoding("Windows-1252") clear
append using Nynorsk
save Begge_maalformer, replace 

* Sidetallfilen
import delimited Nynorsk_sidetall.csv, varnames(1) encoding("UTF-8") clear
save Nynorsk_sidetall, replace 	//må på .dta-format for senere å kunne appendes

import delimited Bokmaal_sidetall.csv, varnames(1) encoding("UTF-8") clear
append using Nynorsk_sidetall
save Begge_maalformer_sidetall, replace 

*exit

* TELLE SIDER - OG SPØR OM STOPP
*****************************
summarize antsider
if `r(max)' > 4 {
	count if antsider > 4
	local overfire = `r(N)'
	noisily di as err _n "Det er `overfire' profiler med mer enn 4 sider. "
	noisily di "Dette vil gi følgefeil i de neste testene!"	
	pause Skriv q for å vise liste, BREAK for å stoppe.
	noisily list if antsider > 4
	pause
	}
	else noisily di _n "Ingen profiler har over fire sider."

	*exit
*pause
	
* EKSTRAHERE RELEVANTE DATA
*****************************
use Begge_maalformer, clear
rename tekst content		// Ny innlesing, nytt var.navn ...

***********INCLUDE**********************************************************
if "$geonivaa" == "fylke"   global geofork = "F"
if "$geonivaa" == "kommune" global geofork = "K"
if "$geonivaa" == "bydel"   global geofork = "B"

local filnavn = "$skript/$profiltype/$geonivaa/$profiltype" + "-$geofork" + "_Include_0_lage_arbeidsfiler.do"
di "`filnavn'"
include "`filnavn'"

***********SLUTT INCLUDE*******************************************************


* d) Ekstrahere Batchnummer.
  //ANM: Batchnummerne er på format ddMMååttmm !
gen batchnr = regexs(0) if regexm(content, "Batch [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\.[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9][ ][0-9]?[0-9][:][0-9][0-9]")
gen batchForside=usubstr(batchnr,1,28) if ustrword(batchnr,1)=="Batch"
gen batchIndikator=usubstr(batchnr,29,22) if ustrword(batchnr,1)=="Batch"
gen batchPDFdato=substr(content,51,16) if word(content,1)=="Batch" //dato-delen - OBS: én- eller tosifret timetall,
	// hvis énsifret er det med en space bak.

		*replace batchPDFdato=batchPDFdato + " " + content[_n+1] if batchPDFdato!="" //Klokkeslett-delen ligger på linja under. IKKE I EXCELDUMP.
		*noisily di "Sjekke om noen klokkeslett ikke ligger på linja nedenfor resten av batchnummerne: Antallet skal være null."
		*noisily	count if ( usubstr(content[_n+1],-4,1)!=":" ) &  ustrword(content,1)=="Batch" //2.2.16: Endret fra -3 til -4 i usubstr().

* e) Ekstrahere målform og telle opp
gen maalform = "Bokmål" if word(content, 1) == "Bokmål"
replace maalform = "Nynorsk" if word(content, 1) == "Nynorsk"
count if maal == "Bokmål"
capture assert `r(N)' == $antkommuner
if _rc != 0 {
	noisily di as err "Antall Bokmål != antall GEO" 
	global feilfunnet = "$feilfunnet" + " 0"
	}
	else noisily di "Antall Bokmål stemmer med antall GEO"
count if maal == "Nynorsk"
capture assert `r(N)' == $antkommuner
if _rc != 0 {
	noisily di as err "Antall Nynorsk != antall GEO" 
	global feilfunnet = "$feilfunnet" + " 0"
	}
	else noisily di "Antall Nynorsk stemmer med antall GEO"
*noisily di "hei"

		*replace maalform= ustrregexs(0) if ustrregexm(maalform, "([A-ZÆØÅa-zæøå]+)") & ustrword(content,1)=="Batch"
		  //dvs. rense vekk alt som ikke er bokstaver, som komma o.l.
		*assert (maalform=="Bokmål" | maalform=="Nynorsk") if maalform!=""


* Flytte ekstraherte data til samme rad - den med batchnumre.

* Flytte kommunenavn: nedover
gen tillegg=0 if komnavn_iPDF!=""								//Flagge startlinjer direkte, slipper hardkodet linjetall!
replace tillegg=tillegg[_n-1]+1 if tillegg==. & tillegg[_n-1]<.   // nummerere tilleggslinjene 
replace komnavn_iPDF	=komnavn_iPDF[_n-tillegg] if batchForside!=""

	*pause Flyttet kommunenavn

* Flytte aar_i_heading: nedover
replace tillegg=.												  //Starte på nytt
replace tillegg=0 if aar_i_heading!=""
replace tillegg=tillegg[_n-1]+1 if tillegg==. & tillegg[_n-1]<.   // nummerere tilleggslinjene 
replace aar_i_heading	=aar_i_heading[_n-tillegg] if batchForside!=""
*exit

* Flytte maalform: nedover
replace tillegg=.												  //Starte på nytt
replace tillegg=0 if maalform!=""
replace tillegg=tillegg[_n-1]+1 if tillegg==. & tillegg[_n-1]<.   // nummerere tilleggslinjene 
replace maalform	=maalform[_n-tillegg] if batchForside!=""

* Flytte aar_i_bunntxt: Må flyttes oppover.
* Det er ikke mulig med []-notasjon, men det blir lett hvis filen er sortert opp ned!
gen linjenr = _n
gsort -linjenr

replace tillegg=.												  //Starte på nytt
replace tillegg=0 if aar_i_bunntxt != ""
replace tillegg=tillegg[_n-1]+1 if tillegg==. & tillegg[_n-1] < .   // nummerere tilleggslinjene 
replace aar_i_bunntxt	= aar_i_bunntxt[_n-tillegg] if batchForside != ""
*exit

* komnr_iPDF
replace tillegg=.												  //Starte på nytt
replace tillegg=0 if komnr_iPDF!=""
replace tillegg=tillegg[_n-1]+1 if tillegg==. & tillegg[_n-1]<.   // nummerere tilleggslinjene 
replace komnr_iPDF	=komnr_iPDF[_n-tillegg] if batchForside!=""

* komfolketall_iPDF
replace tillegg=.												  //Starte på nytt
replace tillegg=0 if komfolketall_iPDF!=""
replace tillegg=tillegg[_n-1]+1 if tillegg==. & tillegg[_n-1]<.   // nummerere tilleggslinjene 
replace komfolketall_iPDF	=komfolketall_iPDF[_n-tillegg] if batchForside!=""

gsort +linjenr
*exit

drop tillegg linjenr
*exit
*pause før lagring	
* LAGRE ARBEIDSFILER
**************************
* Disse er til spes. sjekker. Tabellen hentes fram separat.
keep komnavn_iPDF aar_i_heading aar_i_bunntxt komnr_iPDF komfolketall_iPDF batchForside batchIndikator batchPDFdato maalform
keep if komnavn_iPDF != ""
save pdfdata_AlleLinjerPrKommune, replace
keep if batchForside != "" // beholde 1 linje per kommune
save pdfdata_1LinjePrKommune, replace
	/*foreach file in Fullt_sett_nynorsk.dta {
		capture erase `file'
		} */

* Ta kopier av flatfilene til arbeidskatalogen
copy "$Importkatalog/Forside.txt" "$datafiler/", replace
copy "$Importkatalog/Indikator.txt" "$datafiler/", replace

noisily di "Arbeidsfiler lagret."

*********************************************************************
* BRUKSANVISNING OG NOTATER
* Slå sammen bokmålsProfilene med nynorskprofilene, og lage filer 
* som trengs i kvalitetskontrollen.

/* Dette skriptet er basert på at pdf'ene på forhånd er sortert etter
navn, slått sammen og konvertert til txt-filer av R. For beskr. av dette, 
se hovedscriptet "..000_SAMLA_ANALYSE".
	
Endringer i V3: Unicode translate før innlesing av txt-filene.
V3-1: Unicode-versjoner av tekstfunksjonene. Tilhørende endringer.
v3-1_TEST: Kommentert ut håndtering av kommunenavn, beholdt tallbehandling.
	Endret til 5 linjer per kommune i første arbeidsfil (fra 6).
	
Endringer i V4: Tilpasse til bruk av Excelfiler.
	Leser inn Bokmåls-excelfil i to porsjoner.
	Lar Fullt_sett_BM og NN  -.dta ligge, så jeg slipper å Excel-importere dem om igjen.

Endringer i V5: Tilbake til txt-filer, laget av R pdftools.
Endringer i V6: Ny R-function leser sidetall, analyserer det først.
Endringer i V7: Samordnet scriptene og skilt ut de profiltype/geonivå-spesifikke delene i INCLUDE-script.

*/ 

	
