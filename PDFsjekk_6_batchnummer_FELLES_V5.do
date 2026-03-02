*FELLES SCRIPT
* V4: Kortere output fra batchnummersjekken (ny metode).
noisily display ///
 "{err:===============================================================================================}"
noisily display "Sjekker at batchnummer i PDFene = batchnummer i inndata, og datotagger i Friskvikfiler"
***************************************************************
*pause on

* Indikator.txt 
import delimited Indikator.txt, varnames(1) delimiter("\t") encoding("UTF-8") clear

levelsof lpnr, local(lnr)
keep if lpnr == real(word("`lnr'", 1)) 			//Beholde bare én indikator per kommune
sort spraak sted_kode lpnr 						// sortert slik PDFens linjer skal være

*Batchnr i datotag_side4_innfilutfil, to deler:
local godkjmappeIndik = substr(datotag, 1,10)	//Godkjentmappen brukt for å lage Indikator.txt
local datoIndik = substr(datotag, 12,10)		//Prod.tidspunkt Indikator.txt
												//(til evt. sjekk av samsvar mellom flatfilene, ikke implementert)

merge 1:1 _n using pdfdata_1LinjePrKommune.dta
noisily di "Sammenlikning batchnummer for Indikator.txt"
gen flagg = 1 if datotag != batchIndikator
count if flagg == 1
if r(N) > 0 {
	global feilfunnet = "$feilfunnet" + " 6"
	noisily list sted_k spraak datotag batchIndikator if datotag != batchIndikator
	noisily di as err "Det er " r(N) " avvikende batchnumre (se liste ovenfor)." _n ///
					`""datotag..." er fra inndata, "batchIndikator" er fra PDF. "'
}
else {
	noisily di "	-OK"
}
		
* Forside.txt  
import delimited Forside.txt, varnames(1) encoding("UTF-8") clear
*insheet using Forside.txt, tab clear

sort spraak sted_kode  // sortert slik PDFens linjer skal være

levelsof temanr, local(tema)
keep if temanr == real(word("`tema'", 1)) 		//Beholde bare én linje per kommune

	***** I UTVIKLINGEN: **************************
	*	keep if sted_kode==101 | sted_kode==104
	***********************************************

*Batchnr i datotag_side1_innfilutfil, to deler:
local godkjmappeForside = substr(datotag, 7,10)	//Godkjentmappen brukt for å lage Forside.txt
local datoForside = substr(datotag, 18,10)		//Prod.tidspunkt Forside.txt 
												//(til evt. sjekk av samsvar mellom flatfilene, ikke implementert)

merge 1:1 _n using pdfdata_1LinjePrKommune.dta
noisily di "Sammenlikning batchnummer for Forside.txt"
gen flagg = 1 if datotag != batchForside
count if flagg == 1
if r(N) > 0 {
	global feilfunnet = "$feilfunnet" + " 6"
	noisily list sted_k spraak datotag batchForside if datotag != batchForside
	noisily di as err "Det er " r(N) " avvikende batchnumre (se liste ovenfor)." _n ///
					`""datotag..." er fra inndata, "batchForside" er fra PDF. "'
}
else {
	noisily di "	-OK"
}

*Sjekke at samme godkjentmappe er brukt for begge flatfiler
noisily di _n "Sammenlikne Godkjentmappene:"
capture assert `godkjmappeIndik'==`godkjmappeForside'
if _rc==0 {
	noisily di "Begge flatfiler er laget fra samme Godkjentmappe (= OK)"
}
else {
	global feilfunnet = "$feilfunnet" + " 6"
	noisily di as err "(Forside.txt og Indikator.txt er produsert fra ulike Godkjentmapper. SJEKK at det er hensikten.)"
}

* Tidsdifferanse mellom eldste og nyeste PDF-fil, sikre at de er kjørt samtidig.
  * Må gjøres separat for målformene.
  
* Finne dato/klokkeslett ut fra string
gen PDFtid= clock(batchPDFdato,"DMYhm")
format PDFtid %tc

summarize PDFtid if spraakid=="BOKMAAL"
gen sistetid= r(max) if spraakid=="BOKMAAL"
format sistetid %tc

summarize PDFtid if spraakid=="NYNORSK"
replace sistetid= r(max) if spraakid=="NYNORSK"

gen diff= sistetid-PDFtid
format diff %tcDD_HH:mm:ss

noisily di _n "Antall tilfeller hvor tidsforskjell mellom produksjon av hver enkelt PDF og den siste som ble laget,"
noisily di "er mistenkelig stor, dvs. over en time:"
noisily count if (diff > tc(01:00:00)) //Dvs. 1:00 timer
if r(N) > 0 {
	global feilfunnet = "$feilfunnet" + " 6"
}

* KJØR DETTE HVIS DET TRENGS:
/*
noisily di "Tidsforskjell mellom produksjon av nedenstående PDF og den siste som ble laget, er mistenkelig stor:"
noisily di "(Basert på batchnummer. Forskjell gitt i DD HH:mm:ss)"
noisily li sted_kode komnavn diff if (diff > tc(01:00:00)) //Dvs. én time
*/


*-------------------------------------
* SJEKKE AT DATAFILENE ER DE GODKJENTE
* Sjekk at datotaggene på filene i Godkjentmappa er de som er godkjent i tab KUBESTATUS.

noisily di _n "Sjekk at datotag på alle Friskvikfiler stemmer med DATOTAG_KUBE" ///
	_n "i tabell KUBESTATUS_"$profilaar "."

* A) Lag filliste fra godkjentmappa
* -forutsetter at det er samme mappe for begge flatfiler

* Path til riktig profiltype
if "$profiltype" == "FHP" {
    local type = "FRISKVIK"
} 
else if "$profiltype" == "OVP" {
    local type = "OVP"
}
	*di "`type'"

* Path til riktig geonivå
local geoniv ""			//Sikre mot feil gjenbruk (er vel overflødig når makroen er local ...)
if "$geonivaa" == "bydel"   local geoniv "BYDEL"
if "$geonivaa" == "kommune" local geoniv "KOMM"
if "$geonivaa" == "fylke"   local geoniv "FYLKE"

* Bygge om batchnummer til datotag. OBS geonivå i path.
		* -bruker extended macro function "display med dette formatet" på tidsverdien fra clock().
		*  Se Statatips-filen min, under "Dato, tid".
local mappetagg: display %tcCCYY-NN-DD-HH-MM clock("`godkjmappeIndik'", "DM20Yhm")
local godkjmappe "O:\Prosjekt\FHP\PRODUKSJON\PRODUKTER\KUBER/`type'_`geoniv'/$profilaar\GODKJENT/`mappetagg'"
di "`godkjmappe'"

* Lage filliste
local filliste: dir "`godkjmappe'" files "*.csv", respectcase
		*di `"`filliste'"'	//Denne inneholder quotes, må aksesseres med compound double quotes.
local antwords = wordcount(`"`filliste'"')
		*di `antwords'

clear
gen filnavn = ""
set obs `antwords'
local nr = 0
foreach fil of local filliste {
	local nr = `nr' + 1
	quietly replace filnavn = "`fil'" in `nr'
}

* Dele opp i indikatornavn og datotag
gen datotag = substr(filnavn, -20, 16)
replace filnavn = regexs(1) if regexm(filnavn, "(.+)(_20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]\.csv)")

rename filnavn INDIKATOR
tempfile mellomlager
save `mellomlager', replace
*pause Indikatornavn og datotag fra godkjentmappa

* B) Finn de tilhørende kubenavnene, og deres datotagger.
*	 Jeg filtrerer fram Profiltype, Geonivå (MODUS), profilårgang, og de som faktisk 
*	 er med i tabellen s.4 (LNRtabells4).
*
*	 Jeg laget en query i Access som slår opp kubenavn og datotag i KUBESTATUS.
*	 Kopierte SQL View hit. Må være en sammenhengende tekst 
*	 (kan bruke #delimit i Stata for å dele den over flere linjer).
*	 Tabellnavnene er forkortet, definert i "FROM"-delen.

*	 OBS: Profiltype, aar og modus (=geonivå) er makroer.
*	 Jeg fikk kræsj med global macro for År, så jeg bruker locals hele veien.
*	 Om quotes i syntaksen: se notat nedenfor.

	/* 	HDIR 2025: Ikke lenger separate KH og NH-tabeller.
		Felles status: KUBESTATUS_2025
		Datotag i DATOTAG_KUBE.
		Godkjent kube: QC_OK == 1
	*/

if "$geonivaa" == "bydel"   {
	local modus "B"
}
if "$geonivaa" == "kommune" {
	local modus "K"
}
if "$geonivaa" == "fylke"   {
	local modus "F"
}
local aar $profilaar
local profiltype $profiltype

#delimit ;
odbc load, 
	exec(`"SELECT 
		F.INDIKATOR, 
		F.KUBE_NAVN, 
		KUBESTATUS.DATOTAG_KUBE, 
		KUBESTATUS.QC_OK 
		FROM FRISKVIK F 
		INNER JOIN KUBESTATUS_`aar' KUBESTATUS
		ON F.KUBE_NAVN = KUBESTATUS.KUBE_NAVN 
		WHERE (((F.MODUS)='`modus'') AND ((F.AARGANG)=`aar') 
			AND F.PROFILTYPE = '`profiltype'' AND ((F.LNRtabells4) > 0) )"') 
	dsn("MS Access Database;DBQ=$accessKILDEkat\\$accessKILDEfil;")   clear;
#delimit cr

	/*	OBS OM QUOTES:
		I where-delen er det en stringverdi 'K' (local `modus'). Med doble quotes kræsjer kommandoen 
		med "For få parametre. Ventet 1."
		Og det er ikke særlig intuitivt, siden jeg laget kommandoen i Access og kopierte SQL-view hit!
		Det betyr også: En local som inneholder string (profiltype, modus) må ha singlequotes rundt, 
		mens tall (aar) er uten.*/
*pause Dette er Access-dataene, joinet fra to tabeller
*exit 

* C) Sammenlikn datotagger med de i Kubestatus
*	 Godkjentmappa (i `mellomlager') kan inneholde flere filer enn de som faktisk er brukt i profilen.
*	 Derfor beholde bare de som matcher lista fra Kubestatus, og sammenlikne datotaggene for disse.
merge 1:1 INDIKATOR using `mellomlager', keep(match)

capture assert DATOTAG_KUBE == datotag
if _rc==0 {
	noisily di " -OK"
}
else {
	global feilfunnet = "$feilfunnet" + " 6"
	noisily di as err "Mismatch i følgende datotagger:"
	noisily list INDIKATOR-datotag if DATOTAG_KUBE != datotag
}
