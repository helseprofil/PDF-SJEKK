* FELLES SCRIPT FOR ALLE PROFILER

/*	FOR Å MEKKE PÅ TEKSTKRITERIENE I INCLUDE-FILEN:
	- Sett Testmodus = TRUE.
	- Kjør scriptet herfra - og kjør en gang til.
	  Systemet stopper kjøring 2 ved mekkepunktet (provosert kræsj).
	- Gå i Include-filen og mekk.
	- Etter mekking, bare kjør herfra igjen. Systemet starter på Runde 1 igjen.
	
*/
global TESTMODUS = "FALSE" 	// Tillatt: TRUE (FALSE - men det testes bare mot "true")

*---------------------------------------------------------------------
noisily display "{err:===============================================================================================}"
* Har profilene rett setninger til rett kommune?

*---------------------------------------------------------------------
* Styre til kjøring i to og to runder under mekking på tekstkriteriene
if "$TESTMODUS" == "TRUE" & $RUNDETELLER > 2 {
	global RUNDETELLER = 1
}
*---------------------------------------------------------------------

cd "$datafiler"
use Begge_maalformer, clear

* 1. Rekonstruere setningene fra PDF'ene (hver setning i PDF-en kan være spredt over flere linjer tekst-dumpen).
*---------------------------------------------------------------------------------------------------------------
rename tekst content 	//Ny innlesing, nytt var-navn ...

***********INCLUDE**********************************************************
if "$geonivaa" == "fylke"   global geofork = "F"
if "$geonivaa" == "kommune" global geofork = "K"
if "$geonivaa" == "bydel"   global geofork = "B"

local filnavn = "$skript/$profiltype/$geonivaa/$profiltype" + "-$geofork" + "_Include_2_dynamiske_setninger.do"
di "`filnavn'"
include "`filnavn'"

***********SLUTT INCLUDE*******************************************************

* 2. Hente ut setningene fra Forside.txt, filen som lastes opp til rapportgeneratorens database
*---------------------------------------------------------------------------------------------------------------
* a) Ta en kopi som kan herjes med - ER ALLEREDE GJORT I SCRIPT 0 
*copy "$Importkatalog/Forside.txt" "$datafiler/", replace
* b) Lese inn
import delimited Forside.txt, encoding("UTF-8") clear //Laget med Stata 14 -> er Unicode

* Rense vekk overflødige linjeskift og spesialtegn, og rydde litt
replace pkt_tekst=usubinstr(pkt_tekst, " ", " ", .) //Hard space, fra Excels tusenskilletegn, erstatt med vanlig space. 
replace pkt_tekst=usubinstr(pkt_tekst, " ", " ", .) //En variant av space, vet ikke hvilken, kopiert fra datasettet.
replace pkt_tekst=usubinstr(pkt_tekst, "$", "", .)  //Kode til rapportgeneratoren om å legge inn linjeskift.

	************
*	replace pkt_tekst=ustrrtrim(pkt_tekst)	//Fjerne trailing Unicode whitespace characters and blanks
											//OBS da detekterer vi dem ikke heller, bør jo rettes i SETNINGER_S1 i Access.
	************
	
sort spraak sted_kode temanr  //sortere for å komme i samme rekkefølge som PDFene

* 2a (V-23): Telle at alle GEO har samme antall setninger i Forside-filen.
*-------------------------------------------------------------------------
	* Erfaring: bysort er rask. egen(group) er treg.
	*drop in 7	//GENERERE EN FEIL for utviklingen
bysort regiontypeid spraakid sted_kode  : egen telling = count(temanr)	
	//Gir antall temanr. for hver sted_kode, BM og NN hver for seg. Det skal være én verdi for hele filen.
levelsof telling, local(opptelling)
di "Sjekker om alle GEO har samme antall setninger i Forside.txt."
if wordcount("`opptelling'") == 1 {
	di "	- OK"
}
else {
		global feilfunnet = "$feilfunnet" + " 2"
		di as err "Noen GEO har avvikende antall setninger i Forside.txt!"
		di as err "Gå inn i scriptet for å vise hvilke Geo. Kode ligger klar."
		*pause
}
	**************************************************
	* Se sted_kode og målform for de radene der 'telling' ENDRES:
	* Sjekk manuelt i filen - det kan jo være flere Geo etter hverandre.
	* (Første rad hoppes over, siden den ikke har noen rad [_n-1].)
		/*  KJØR DENNE:
		list sted_kode spraakid if telling != telling[_n-1] & (_n > 1)
		*/
	***************************************************
capture drop telling


/***********************************************
		* I UTVIKLINGEN:
		keep if sted_kode==101 | sted_kode==104
***********************************************/
*pause
*Original merge: linje for linje, uten match. Tryner hvis det er kommet med flere punktmerkede setninger i pdf-en.
merge 1:1 _n using pdf-setninger.dta //koble PDFene sammen med Forside.txt

* 3. Selve likhetstesten, om setningene ligger i samme rekkefølge. 
noisily display as res _n "Sjekker at det er riktige dynamiske setninger til riktig kommune."
capture assert setnOUT == pkt_tekst
if _rc == 9 {		//hvis det er mismatch, sett flagg
	global feilfunnet = "$feilfunnet" + " 2"
}
	noisily compare setnOUT pkt_tekst
	noisily di "Antall rader mismatch mellom PDF-setninger og innfil-setninger (RÅ):"
	noisily count if setnOUT!=pkt_tekst
	noisily tab setnOUT if setnOUT!=pkt_tekst
	noisily di "List alle rader som ikke matcher:" // <SLÅTT AV NÅ>"

*************************************************************	
if "$TESTMODUS" == "TRUE" {	
*	VED FIKSING PÅ SETNINGER:
*	OBS språkID, hvis du vil hoppe over Nynorsk eller begrense output.
*	BRUK "NOTRIM" for å se hele setningene (ellers kommer bare første del, i bokser)
*noisily list  sted_kode setnOUT pkt_tekst if setnOUT != pkt_tekst & spraakid == "BOKMAAL"
noisily list  sted_kode setnOUT pkt_tekst if setnOUT != pkt_tekst , notrim
}
************************************************************


	*Sammenlikning uten hensyn til space and punctuation:
	*Funksjonen sammenlikner unicode-stringer og returnerer 0 hvis de er like, -1 eller 1 hvis de er ulike.
	*Nest siste tall lik 1 gjør at space og skilletegn ignoreres, så feil bindestreker etc. detekteres ikke.
	*(parameter "alt" i hjelpefilen)
	gen smlikn = ustrcompareex(setnOUT,pkt_tekst,"no",-1,-1,-1,-1,-1,1,-1)
	noisily di _n "Antall rader mismatch uten hensyn til space og skilletegn (unicode):"
	noisily count if smlikn!=0

*******************************************
if "$TESTMODUS" == "TRUE" {
	exit
}
*******************************************

* 4. Kontrollere at kommunenumrene OGSÅ ligger i samme rekkefølge
*
levelsof temanr, local(tema)
keep if temanr == real(word("`tema'", 1)) 		//Beholde bare én linje per kommune
drop _merge
merge 1:1 _n using pdfdata_1LinjePrKommune
gen komnr_iPDF_num= real(komnr_iPDF)

noisily di "Kontrollere at kommunenumrene OGSÅ ligger i samme rekkefølge"
capture assert sted_kode == komnr_iPDF_num
if _rc == 9 {		//hvis det er mismatch, sett flagg
	global feilfunnet = "$feilfunnet" + " 2"
}
noisily compare sted_kode komnr_iPDF_num
*/
noisily di "script 2 dynamiske setninger ferdig"

exit

/* Verktøy   ====================================================================

* Krever at avsnitt 4 kommenteres ut:
noisily tab setnOUT sted_kode if setnOUT!=pkt_tekst

* Eller, hvis too many values:
gen flagg = 1 if setnOUT != pkt_tekst
replace flagg = . if strmatch(setnOUT, "*ndelen 17-åringer som oppgir at de trener sjeldnere enn ukentlig, *")
tab sted_kode if flagg == 1

*/