* BACKUPRUTINE FOR PDF-BATCH
* Takler alle geonivå, se nedenfor.
* Bør kjøres etter PDF-sjekk, men KAN kjøres når som helst uten å kræsje pga manglende filer.

/*	Metode:
	Går til katalogen hvor SSRS lagrer originale PDF-er.
	LESER Windows' tidsstempel på første fil i Bokmål-katalogen, og bruker det som datotag.
	Oppretter target-overkatalog med datotag.
	Bruker "shell copy" dvs. Windows' copy-kommando, for å bevare tidsstempelet på filene.
	Kopierer Bokmål og Nynorsk til hver sine underkataloger.
	Kopierer datafilene for PDF-sjekken til overkatalogen.
	
	KREVER: Geonivå og profil-årgang settes øverst i scriptet.
	
	OBS: Scriptet leser altså datoen på eldste fil i Bokmål, dvs. den først genererte.
	Dersom en PDF var åpen/opptatt, og derfor ikke ble generert om igjen ved ny batchkjøring,
	vil dette slå inn her: Da vil denne gamle filens tidsstempel bli satt på den nye kopikatalogen.
	LAGET SJEKK for det, at nytt katalognavn ikke er likt det gamle -> overskrive ting.
	NB: Den sjekken krever lowercase i geonivå (-> katalognavn).
	
	ENDRINGER:
	(v2 ligger på F:/Forskningsprosjekter/PDB 2455 - Helseprofiler og til_/Kval-kontroll\Av_PDF-er)
	v3: Ny katalogstruktur, PDF-sjekken på PROD\BIN\VALIDERING. Excelfiler ist.f.txt-dump av PDFer.
	v4: Ny katalogstruktur, PDF-sjekk datafiler på PROD\VALIDERING. Kommunebatch oppdelt i fire halvparter.
	v5: Tilpasset ny lesing av PDF og dermed analysefiler, og Oppvekstprofiler, inkl. ny katalogstruktur.
*/

*	Katalognavn for Target, struktur: F:/Forskningsprosjekter/PDB 2455 - Helseprofiler og til_/Profiler\0_Sikkerhetskopier\...
*		2016_PDF_FRYS\Bydel\BYDEL-2016-02-12-19-48\Bokmaal
*-------------------------------------------------------------------------------
* REDIGER/SJEKK:
local profiltype	"OVP"		//Tillatt: FHP OVP
local aargang		"2024"		//Profilårgang
local geonivaa 		"bydel"		//Tillatte verdier: kommune fylke bydel
local analysefilkat /// Datafilene fra PDF-sjekken
	"F:/Forskningsprosjekter/PDB 2455 - Helseprofiler og til_/PRODUKSJON\VALIDERING\PDF-SJEKK/`profiltype'/`geonivaa'\Datafiler"
	*local analysefilkat "F:/Forskningsprosjekter/PDB 2455 - Helseprofiler og til_/TESTOMRAADE\PDF-analyse\2016\Datafiler\OLD"
local targetkatalog "F:/Forskningsprosjekter/PDB 2455 - Helseprofiler og til_/Profiler\0_Sikkerhetskopier"
	//OBS: Det bygges en struktur under denne, så filene lagres i underkataloger.
	*local targetkatalog "F:/Forskningsprosjekter/PDB 2455 - Helseprofiler og til_/TESTOMRAADE\PDF-analyse\Target"

*-----------------------------------------------------------------------------
* KJØRING:
pause on
local kilde_root "N:\Helseprofiler_Rapportgenerator"

if "`profiltype'" == "FHP" {
	local type "Folkehelseprofiler"
}
else if "`profiltype'" == "OVP" {
	local type "Oppvekst"
}
local kildekat "`kilde_root'/`type'\Produkter\PDF_filer\\`geonivaa'\\`aargang'"  //(ikke målform)
	*local kildekat "N:\Helseprofiler_Rapportgenerator\Folkehelseprofiler\Produkter\PDF_filer\Kommune\2021"

* 1. Finne/lage datotag.
*    Leser "sist lagret"-tid fra første fil i en DIR-kommando.
*------------------------
cd "`kildekat'"
shell dir .\Bokmaal\*.pdf > filnavn.txt /O:D /-C
	*  /O: DOS command switch som sorterer filene, D: eldste øverst.
	*  /C  fjerner tusenskilletegn i filstørrelser - antakelig unødv, men tegnene var scramblet.
	*shell dir .\Bokmaal\0105_2015_Bokmaal.pdf > filnavn.txt /-C  //Mer spesifikk, men krever et filnavn.

import delimited filnavn.txt, delimiter("    ", asstring) clear
	//Nå er rad 4 den interessante, og datotiden ligger alene i v1.
drop in 1/3
local datotagg : display %tcCCYY-NN-DD-HH-MM clock(v1, "DMYhm")

		/* Mer eksplisitt metode, med samme resultat:
		replace v2= clock(v1, "DMYhm")
		format v2 %tcCCYY-NN-DD-HH-MM
		tostring v2, usedisplayformat force replace
		local datotagg = v2
		*/
di "`datotagg'"
*pause

* 2. Sette opp kataloger.
*------------------------
capture mkdir "`targetkatalog'\\`aargang'_PDF_FRYS"
capture mkdir "`targetkatalog'\\`aargang'_PDF_FRYS\\`type'"
capture mkdir "`targetkatalog'\\`aargang'_PDF_FRYS\\`type'\\`geonivaa'"

* Verifisere at datotaggen er ny, så vi ikke overskriver forrige backup
cd "`targetkatalog'\\`aargang'_PDF_FRYS\\`type'\\`geonivaa'"
local liste : dir . dirs "*" 	//Dvs.: liste over underkataloger i PWD.
	*di `"`liste'"'

local feilkode=0
local nykatalog "`geonivaa'-`datotagg'"
foreach ord of local liste {
	if "`nykatalog'" == "`ord'" {
		di as err _n "Katalognavnet for backup-filene har vært brukt før! Sjekk om det ligger" _n ///
		"en gammel PDF-fil i batchen. " _n ///
		"Ta evt. backup manuelt, eller bytt navn på forrige backupkatalog."
		local feilkode=9
		exit
	} //end -if-
} //end -foreach ord-
if `feilkode'==9 exit

capture mkdir 		  "`targetkatalog'\\`aargang'_PDF_FRYS\\`type'\\`geonivaa'\\`geonivaa'-`datotagg'"
local targetkatalog = "`targetkatalog'\\`aargang'_PDF_FRYS\\`type'\\`geonivaa'\\`geonivaa'-`datotagg'"
di _n "Targetkatalog:" _n "`targetkatalog'"
*pause
	
* 3. Kopiere.
*------------------------
* a) PDF-batchen
cd "`kildekat'"
foreach maalform in "Bokmaal" "Nynorsk" {
	di "`maalform'" 
	capture mkdir "`targetkatalog'\\`maalform'"
	shell copy ".\\`maalform'\*.pdf" "`targetkatalog'\\`maalform'"
	}

* b) Analyse-datafilene
cd "`analysefilkat'"
shell copy *.* "`targetkatalog'"

di _n "Ferdig."
exit

/*
if "`geonivaa'" == "Kommune" {
	foreach fil in ///
		"Forste_halvpart_bokmaal.pdf" 	///
		"Forste_halvpart_bokmaal.xlsx"	///
		"Siste_halvpart_bokmaal.pdf" 	///
		"Siste_halvpart_bokmaal.xlsx"	///
		"Fullt_sett_bokmaal.dta"	///
		"Forste_halvpart_nynorsk.pdf"	///
		"Forste_halvpart_nynorsk.xlsx"	///
		"Siste_halvpart_nynorsk.pdf"	///
		"Siste_halvpart_nynorsk.xlsx"	///
		"Fullt_sett_nynorsk.dta"	///
		"Fullt_sett_beggemaalformer.dta" ///
	"baromtabPDF.dta"			///
	"pdfdata_1LinjePrKommune.dta"	///
	"pdfdata_AlleLinjerPrKommune.dta" {
			shell copy "`fil'" "`targetkatalog'"
	} //end -foreach fil-
} //end -if kommune-
else {
	foreach fil in ///
		"Fullt_sett_bokmaal.pdf" 	///
		"Fullt_sett_bokmaal.xlsx"	///
		"Fullt_sett_bokmaal.dta"	///
		"Fullt_sett_nynorsk.pdf"	///
		"Fullt_sett_nynorsk.xlsx"	///
		"Fullt_sett_nynorsk.dta"	///
		"Fullt_sett_beggemaalformer.dta" ///
		"baromtabPDF.dta"			///
		"pdfdata_1LinjePrKommune.dta"	///
		"pdfdata_3LinjerPrKommune.dta" {
			shell copy "`fil'" "`targetkatalog'"
	} //End -foreach fil-
} //end -else, geonivaa-
di _n "Ferdig." _n "Sjekk datotaggen: Hvis den har vært brukt før, tyder det på at det ligger" ///
	_n "en gammel PDF-fil i batchen - f.eks. om en fil var åpen/opptatt, så den" ///
	_n "ikke ble generert på nytt."
	
*/