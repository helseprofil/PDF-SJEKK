* Samla analyse -

**	SAMORDNET FELLESSCRIPT FOR ALLE PROFILER

quietly {

***************************************************************************************
* REDIGER/SJEKK:
* (Se også antall-parameterne nedenfor)

macro drop _all
global root "O:/Prosjekt/FHP"
 
*global servernavn "Test" // Sett stjerne foran den som IKKE skal brukes.
global servernavn "Produksjon" 	// Sett stjerne foran den som IKKE skal brukes.

global profilaar = 2026
global profiltype "FHP" 		// Tillatt: FHP OVP
global geonivaa   "bydel"		// Tillatt: bydel kommune fylke 	OBS: Ikke fylke for OVP.

global Geofasitkat "$root/Masterfiler/$profilaar" 
global Geofasitfil "Stedsnavn_SSB_Unicode.dta" //OBS bruk Unicode-versjonen

global accessKILDEkat "$root/PRODUKSJON/STYRING"
global accessKILDEfil "KHELSA.mdb"


***************************************************************************************
* Parametre avledet av ovenstående
if "$profiltype" == "FHP" local typekat "Folkehelseprofiler"  
if "$profiltype" == "OVP" local typekat "Oppvekst"  

local Testfasit  "O:/Fagapplikasjoner/Folkehelseprofiler/Konfigurasjoner (PROD)/`typekat'/Importfiler/TEST/$geonivaa/Flatfiler"
local PRODfasit  "O:/Fagapplikasjoner/Folkehelseprofiler/Konfigurasjoner (PROD)/`typekat'/Importfiler/PROD/$geonivaa/Flatfiler"
global datafiler "$root/PRODUKSJON/VALIDERING/PDF-SJEKK/$profiltype/$geonivaa/Datafiler"

*global skript "O:\Prosjekt\FHP\PRODUKSJON\BIN\VALIDERING\PDF-SJEKK\TEST\Script med Include"
global skript    "$root/PRODUKSJON/BIN/VALIDERING/PDF-SJEKK/"

********************

* Sette riktig server (test eller produksjon) i følge valget øverst
if "$servernavn"=="Test" global Importkatalog "`Testfasit'"
else if "$servernavn"=="Produksjon" global Importkatalog "`PRODfasit'"
else {
	di "{err: Sjekk at servernavn er riktig skrevet}"
	exit
	}

* Antall GEO i hvert geonivå
if "$geonivaa" == "bydel"   global antkommuner = 36
if "$geonivaa" == "kommune" global antkommuner = 357
if "$geonivaa" == "fylke"   global antkommuner = 15

* Antall indikatorer i barometeret side 4
if "$profiltype" == "FHP" & "$geonivaa" == "bydel"   global antindik = 30
if "$profiltype" == "FHP" & "$geonivaa" == "kommune" global antindik = 34
if "$profiltype" == "FHP" & "$geonivaa" == "fylke"   global antindik = 34

if "$profiltype" == "OVP" & "$geonivaa" == "bydel"   global antindik = 28
if "$profiltype" == "OVP" & "$geonivaa" == "kommune" global antindik = 30

***************************************************************************************
* KJØRING:
pause on	/* "pause on" gjør det mulig å ta pause i kjøringen etter hvert delscript. 
			Det går an å kjøre andre kommandoer i pausen.
			Bruk kommando BREAK (med store bokstaver!) for å avbryte kjøring 
			av det pausede scriptet.
			*/
 
global feilfunnet = ""		//Endres i delscriptene, så alle kan kjøres uten pause og EVT sjekkes til slutt.
global RUNDETELLER = 1		//Til styring av kjøringen ved mekking i Include script 2
cd "$datafiler"

* SI FRA HVA SOM ANALYSERES
***************************
di as err "Kjører mot: $profiltype $geonivaa" _n

* SJEKKE AT ANALYSEFILENE ER FRA NYESTE BATCH
*********************************************
/*	Metode: DIR-kommando med "sist lagret"-datotid, plukke den siste (nyeste) fila i Nynorsk-katalogen,
	og sammenlikne med "sist lagret" for outputfila fra LesPDF.
	*/

* Sette opp Path til produktkatalogen fra rapportgeneratoren
if "$servernavn" == "Produksjon" local PDFkat = "PDF_filer"
else local PDFkat = "PDF_test"

if "$profiltype" == "FHP" local profilkat = "Folkehelseprofiler"
else if "$profiltype" == "OVP" local profilkat = "Oppvekst"

* Vi trenger bare å lese nynorskfilene, som er laget sist.
local nynorskkat = 	"O:\Fagapplikasjoner\Folkehelseprofiler\Konfigurasjoner (PROD)\\`profilkat'\Produkter"   ///
	+ "\\`PDFkat'\\$geonivaa\\$profilaar\Nynorsk"
	di "`nynorskkat'"

* Hente filenes datoer og ta vare på den nyeste
shell dir "`nynorskkat'" > pdffilliste.txt /O:D /-C
	*  /O: DOS command switch som sorterer filene, D: eldste øverst.
	*  /C  fjerner tusenskilletegn i filstørrelser - antakelig unødv, men tegnene var scramblet.
	*      (Se også script 1-taBackup_V5_avPDF-batch.do, litt mer notert)

import delimited pdffilliste.txt, delimiter("    ", asstring) clear
	*	her blir v1 filens dato.
	*	Det er to oppsummeringsrader nederst, en for antall filer og en for antall dirs (som er "." og ".."),
	*	så jeg trekker 2 fra antall obs og angir dermed radnummer for nederste dato.
	*   Bruker extended macro function "display med dette formatet" på tidsverdien fra clock().
	*   Se Statatips-filen min, under "Dato, tid".
count
local sistefil: display %tcCCYY-NN-DD-HH-MM clock(v1[`r(N)'-2], "DM20Yhm")
	* TESTFASE: sammenlikne med en nyere tid, for å trigge feil.
	*local sistefil: display %tcCCYY-NN-DD-HH-MM now()
	di "`sistefil'"

* Hente dato for outputfila fra LesPDF-R-scriptet (samme metode)
shell dir Nynorsk_lespdf.csv > nynorskdato.txt /O:D /-C
import delimited nynorskdato.txt, delimiter("    ", asstring) clear
local analysefildato: display %tcCCYY-NN-DD-HH-MM clock(v1[`r(N)'-2], "DM20Yhm")
	di "`analysefildato'"

* Og sammenlikne
noisily di "Sjekker at analysefilen er nyere enn PDF-batchen:"
capture assert "`analysefildato'" >= "`sistefil'"
if _rc == 9 noisily di as err "Tekstdumpen er gammel! Sjekk at LesPDF.R er kjørt for nyeste batch."
else noisily di "  - OK"

noisily pause Detaljscriptene starter (BREAK her for å kjøre dem manuelt, q for å kjøre alle):


***************************************************************************************
noisily di "0_Lage arbeidsfiler:"
noisily run "$skript\PDFsjekk_0_lage arbeidsfiler.do" 
*noisily pause Gi kommando 'q' for å fortsette, BREAK for å avbryte helt.

/* Sjekker at det er riktige dynamiske setninger til riktig kommune/geo, 
   og at geonavnene kommer i riktig rekkefølge.  */
noisily di "2_Dynamiske setninger:"
noisily run "$skript\PDFsjekk_2_dynamiske setninger.do"   
*noisily pause Gi kommando 'q' for å fortsette, BREAK for å avbryte helt.
 
/* Sjekker linje for linje at tallene på side 4 stemmer med inputfilen Indikator.txt. 
   Dessuten at årstallene i profilens
   heading (s.1) stemmer med samme inputfil. */
noisily di "3_Barometertabell:"
noisily run "$skript\PDFsjekk_3_barometertabell_v6.do"    
*noisily pause Gi kommando 'q' for å fortsette, BREAK for å avbryte helt.


/* Sjekker at like geonavn opptrer i) samlet (egentlig to og to i 2017-profilene, nemlig i tittel
   og barometer), og at  ii) antall unike kombinasjoner av geonavn, -batchnummer er lik antall geo på dette geonivået. */
noisily di "4_Geonavn i Tittel, bunntekst, barometerhode, etc"
noisily run "$skript\PDFsjekk_4_v2_tittel-bunntxt-baromhode_antall unike komb.do"  
*noisily pause Gi kommando 'q' for å fortsette, BREAK for å avbryte helt.


/* Sjekker at geonavn og -nummer stemmer overens, og stemmer med SSB-kilde. 
   (Separat for målformer)   */
noisily di "5_Kommunenavn og nummer"
noisily run "$skript\PDFsjekk_5_kommunenavn og -nummer_korrekte komb_V4.do"
*noisily pause Gi kommando 'q' for å fortsette, BREAK for å avbryte helt.


/* Sjekker batchnummer i PDF mot hver av de to inputfilene Forside.txt og Indikator.txt.
   Sjekker tidsrom (avstand nyeste til eldste) for når PDF ble generert, for å 
   sikre at alle er kjørt samtidig.*/
noisily di "6_Batchnummer, produksjonstid, datotagger i inndata"
noisily run "$skript\PDFsjekk_6_batchnummer_FELLES_V5.do"   

pause off
noisily di _n "Samlescript ferdig."

if "$feilfunnet" == "" {
	noisily di _n "Ingen utslag i testene."
}
else {
	noisily di as err _n "Testfunn: Sjekk i script $feilfunnet"
}

di as err _n _n "Hvis release candidate: Lag samle-PDF." _n "TA BACKUP AV PDF-BATCHEN?"



********************************************************
* Testfasit/Prodfasit:
* Scriptet er lagt opp til at vi har et testsystem (dev, eller Stage). 
* Systemet har ikke vært lagt opp slik etter flyttingen til HDir.
********************************************************

* BRUKSANVISNING:

* Dette hovedscriptet kjøres med "do". Del-scriptene kjøres da med "run" (dvs. quietly), og bare 
* de tilsiktede beskjedene vises på skjermen.
* Alle delscript kjøres i ett. Til slutt kommer melding dersom noen av testene har slått ut, 
* da blar du bakover i console-output til angitt delscript og leser meldinger.

* PROFILTYPE-SPESIFIKK TEKSTHÅNDTERING er skilt ut i egne Include-script for script 0, 2 og 3.
* Hvis fiksing trengs, gjør det i Include-scriptene. De ligger i egne underkataloger \Profiltype\Geonivå.
/*

**********************************************************
FORARBEID: Lage tekstdump av alle PDF-ene i aktuell batch.

	Bruker R-script lesPDF_v#.R, som bruker Yusmans package lespdf.
	Lager separate filer for Bokmål og Nynorsk, pluss filer for å telle sidetall i PDF'ene.

	OBS: R-scriptet kan ta mange minutter å kjøre fra hjemmekontor, prøv på arbeidsstasjon.
	
 ==> Script: O:\Prosjekt\FHP\PRODUKSJON\BIN\VALIDERING\PDF-SJEKK\LesPDF_v#.R
 ==> Åpne det scriptet i R-studio og Source det.
 ==> Kopier følgende kommando til Console i RStudio: (Sett modus = "TEST" for å hente PDF-filer fra TEST-serveren.)
	 LesPDF("FHP", "kommune", "2022", "PROD")			# Trenger ingen tilordning
		 Funksjonsdefinisjon:
		 LesPDF <- function(profiltype, geonivaa, aargang, TEST) {
		  # ARGUMENT LIST:
		  # profiltype  <- "OVP"      # Tillatt: FHP OVP
		  # geonivaa    <- "kommune"  # Tillatt: kommune bydel fylke      (Fylke ikke laget OVP 2020)
		  # aargang     <- "2020"
		  # modus       <- TEST       # For å velge path å lese batchen fra: TEST gir TEST, alt annet gir PROD.
*/
/*
	Svakhet om målformer:
	Det må være balanse mellom bokmåls- og nynorskversjonene for at scriptene skal kjøre uten feil eller falske funn.
	- Tekstsøk brukes til å merke og rydde, så arbeidsfiler blir ikke skikkelige før BM og NN tekst er tilsvarende.
	- Det må være minst én dynamisk setning på NN for at batchnummer skal bli med i PDF, og batchnummer brukes i 
	  ryddingen for å konstruere arbeidsfilene.
	
*/
/*	TESTMODUS FOR LOKAL TILPASNING i script 2 (feb-26):
	Prøver å gjøre så jeg kan sette "testmodus" ett sted i scriptet, og så bare kjøre.
	For script 2 dynamiske setninger krever det at jeg kan kjøre i to runder - først for å få 
	listet ut setninger med mismatch, og så for å stoppe i pdf-dataene og mekke. 
	Dette gjøres ved kjøring av skript 2 separat (etter at skript 000 har satt de nødvendige globale parameterne).
	Systemet er slik:
	- Startscriptet 000 oppretter global RUNDETELLER == 1 .
	- I script 2 brukes denne til å styre om hele eller bare første del av scriptet skal kjøres.
	  Først skriver jeg inn en global TESTMODUS == "TRUE". Hvis denne er TRUE, styres kjøringen i to runder.
	  I runde 1 kjøres hele, og RUNDETELLER økes med én (til 2).
	  I runde 2 stopper scriptet halvveis (for mekking), og RUNDETELLER økes med én igjen (til 3).
	  I neste runde etter mekking resettes RUNDETELLER fra >2 til 1 i starten av scriptet, og da 
	  kjøres hele scriptet igjen.
*/


}