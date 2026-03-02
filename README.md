* BRUKSANVISNING:

* Masterscriptet "...000..." kjøres med "do". Del-scriptene kjøres da med "run" (dvs. quietly), og bare 
* de tilsiktede beskjedene vises på skjermen. Der settes noen globale makroer (parametre) som brukes av delscriptene.
* Alle delscript kjøres i ett. Til slutt kommer melding dersom noen av testene har slått ut, 
* da blar du bakover i console-output til angitt delscript og leser meldinger.

* PROFILTYPE-SPESIFIKK TEKSTHÅNDTERING er skilt ut i egne Include-script for script 0, 2 og 3.
* Hvis fiksing trengs, gjør det i Include-scriptene. De ligger i egne underkataloger \Profiltype\Geonivå.
* Include-scriptene er unntatt (ignore) fra Git-versjonshåndteringen, for de må endres så mye og i så
* mange omganger at det blir tungvint å ha dem innenfor.
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


	Svakhet om målformer:
	Det må være balanse mellom bokmåls- og nynorskversjonene for at scriptene skal kjøre uten feil eller falske funn.
	- Tekstsøk brukes til å merke og rydde, så arbeidsfiler blir ikke skikkelige før BM og NN tekst er tilsvarende.
	- Det må være minst én dynamisk setning på NN for at batchnummer skal bli med i PDF, og batchnummer brukes i 
	  ryddingen for å konstruere arbeidsfilene.
	

	TESTMODUS FOR LOKAL TILPASNING i script 2 (feb-26):
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

