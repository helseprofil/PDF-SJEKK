noisily display "{err:===============================================================================================}"
noisily display "Script 3: Barometertabellen s.4."
		* Har pdf'ene på side 4 rett barometertabell til rett kommune?
		* Samtidig: Er numre, tall og enheter riktige?
		* Deretter: Årstall i profilheading(s.1) og bunntekster.

		* Endring: Unicode-aware.
		* Tilpasset til tekstdump fra R pdftools, 2020
* 
* Sile ut linjene fra barometertabellen på side 4 i PDF'ene
		/*	Tekstdumpen er laget med bare side 1 og side 4, og bunntekster er bevart.
			Jeg bruker heading og bunntekster til å flagge og droppe side 1.
		   */
cd "$datafiler"
use Begge_maalformer, clear
rename tekst content 	//Ny innlesing, nytt var-navn ...


keep if side == 4
*exit

* RENSE TALLKOLONNENE:
	* Har nå tekster over og under tabellen, og temaoverskrifter både på egne linjer
	* og først på tall-linjene.
	* Alle tabellrader starter egentlig med indikatornummeret. Bruker det.


***********INCLUDE**********************************************************
if "$geonivaa" == "fylke"   global geofork = "F"
if "$geonivaa" == "kommune" global geofork = "K"
if "$geonivaa" == "bydel"   global geofork = "B"

local filnavn = "$skript/$profiltype/$geonivaa/$profiltype" + "-$geofork" + "_Include_3_barometertabell.do"
di "`filnavn'"
include "`filnavn'"

***********SLUTT INCLUDE*******************************************************

	
* Sjekker om tabellen er komplett
count
noisily di "Sjekker at antall obs er lik ant.GEO*ant.målformer*ant.indikatorer ($antkommuner*2*$antindik):"
capture noisily assert `r(N)' == $antkommuner * 2 * $antindik //Antall indik ganger antall profiler
if _rc == 9 {		//hvis antallet ikke stemmer, sett flagg
	global feilfunnet = "$feilfunnet" + " 3"
}

*exit
rename content btabOUT // inneholder indikator-nr og verdier fra side 4 i PDF-ene
save baromtabPDF, replace 	// Innhold i PDFenes barometertabeller, slått
							// sammen etter sortering på i) målform og 2) kommunenummer



******************************************************************************************************
* Hente ut tilsvarende linjer fra Indikator.txt, filen som lastes opp til rapportgeneratorens database
* a) Ta en kopi som kan herjes med - ER ALLEREDE GJORT I SCRIPT 0 
*copy "$Importkatalog/Indikator.txt" "$datafiler/", replace

* b) Oversette kopien til unicode: Gjøres i importen. 
		/*	noisily di "(Unicode translate:)"
			clear
			unicode encoding set Latin1 				//Som regel riktig, men KAN ENDRES hvis det trengs.
			unicode RETRANSLATE Indikator.txt, replace 	MÅ IKKE BRUKES, DEN TAR IKKE NY FIL MEN GAMMEL!*/

import delimited Indikator.txt, varnames(1) delimiter("\t") encoding("UTF-8") clear	//2017 er den allerede Unicode
		*insheet using Indikator.txt, tab clear
		*cd "$datafiler" // med unicode-funksjonene er vi her allerede
sort spraak sted_kode lpnr 				// sortert slik PDFens linjer skal være
drop tidsserieurl metadataurl			//Lang string, gjør filen vanskelig å se på.
*exit

*** Lagt inn "periode" i concat for FHP-F. Hvis det ikke matcher de andre profilene, 
*** bruk i stedet "Fjerne..."-bolken som nå er kommentert ut i Include.
	*** Matchet ikke de andre, der er Periode missing.
	
if "$geonivaa" == "fylke" {
	egen btabIN = concat(lpnr indikator verdi_m verdi_ref enhet periode), punct(" ")
}
else {
	egen btabIN = concat(lpnr indikator verdi_l verdi_m verdi_ref enhet ), punct(" ") 
}

*replace btabIN = usubinstr(btabIN, " år", " ....",.) //Enhet, bakerst, scramblet i PDF.
replace btabIN = usubinstr(btabIN, " ", " ", .) //Hard space, fra Excels tusenskilletegn, erstatt med vanlig space
replace btabIN = ustrtrim(stritrim(btabIN))		//itrim har fått nytt navn, men ingen unicode-parallell

		***** I UTVIKLINGEN: **************************
		*	keep if sted_kode==101 | sted_kode==104
		***********************************************
merge 1:1 _n using baromtabPDF.dta
compress
*exit
		************************ UTVIKLINGEN
		*			drop if strmatch(btabOUT, "*lokalmiljøet, Ungd. 2018-*")
		************************

noisily di _n "Sammenlikne PDF-tabellen med input-tabellen:"
capture noisily assert btabOUT == btabIN
if _rc == 9 {		//hvis de ikke er like, sett flagg
	global feilfunnet = "$feilfunnet" + " 3"
}
noisily compare btabOUT btabIN

		*noisily di `"VED MISMATCH: Sjekk antall desimaler (parameterfil, enFastDesimal=="JA"). Scriptlinje 55.)"'
noisily di "List rader med mismatch: <SLÅTT AV NÅ>"
/*
noisily list sted_k spraak btabOUT btabIN if btabOUT != btabIN
exit
*/

****************************************************
* OBS:
* De fleste delscript 3 har markert EXIT her, og
* "overfør resten til neste script".
* Flere av dem har variabelnavn H for barometerheadingen, som her heter "sted". 
* 
* Og flere av dem har sjekk av årstall i profilens heading (aar-i-heading) i den bolken som er merket Flytt.
* 
* Det ligger også igjen en sjekk av årstall i bunntekst, som er merket "går ikke i 2017".
* Er den gjeninnført med ny PDF-lesemetode?
*
****************************************************

* Kontrollere kommunenavnene i barometer mot tittel
keep if lpnr == 1
drop _merge
merge 1:1 _n using pdfdata_1LinjePrKommune

noisily di _n "Sammenlikner barometerheadingen (sted) med kommunenavn i tittel (komnavn_iPDF):"
capture noisily assert sted == komnavn_iPDF
if _rc == 9 {		//hvis de ikke er like, sett flagg
	global feilfunnet = "$feilfunnet" + " 3"
}
noisily compare sted komnavn_iPDF
	
noisily di _n "Script 3 barometertabell ferdig"
