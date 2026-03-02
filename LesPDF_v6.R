# Lese inn PDF-fil: 
##################################################################################################

## MAL-KOMMANDO:
## LesPDF("FHP", "kommune", "2026", "PROD")			# Trenger ingen tilordning

    # Yusmans pakke lespdf: ?lespdf

    # INSTALLERES SLIK:
    # Best å installere pdftools og data.table først. De er regulare pakker som lastes fra CRAN uten tull.
    # Da kan lespdf installeres med "dependencies=FALSE".
      # install.packages("pdftools")
      # install.packages("data.table")
      # if (!require("remotes")) install.packages("remotes")
      # remotes::install_github("folkehelseprofil/lespdf", dependencies=F)
    
    # Er basert på pdftools. Leverer tilbake en data.frame.
    # Legg inn paths til hhv. Bokmål- og nynorsk-PDF, så leses hele katalogen (hvis du ikke oppgir et filnavn også).
    # Legg evt. inn hvilke sider fra hver PDF som skal leses inn - vanlig er 1 og 4.
    # Ferdig tekstdump lagres i Arbeidskatalogen, hvor den analyseres videre av en samling statascript.
    
    # Aktuelle kataloger (opprinnelig FHP-oppsett):
    # F:\\Prosjekter\\Kommuneprofiler\\PDF_filer\\Kommune\\2020\\Bokmaal                    -originalmappene
    # F:\\Prosjekter\\Kommunehelsa\\PRODUKSJON\\VALIDERING\\PDF-SJEKK\\Kommune\\Datafiler   -min arbeidskatalog
    

    # OBS FOR IMPORT TIL STATA:
    # write.csv lager en fil med komma som separator og punktum som desimaltegn.

    # ENDRINGSLOGG:
    # v2 - bruke en variabel for å styre geonivå (som makro i Stata) i stedet for separate script
    # V3 - klargjøre for Oppvekstprofiler
    # V4 - Gjøre om til function med parametre, så jeg kan bruke samme function i alle geonivåer etc.
    #      Samtidig legge inn den nye katalogstrukturen for produktfilene (fra aug-2020),
    #      inkl. flyttingen til N:\
    # V5 - Legge inn tydelig feilmelding hvis produktkatalogen for SSRS ikke eksisterer (så batch ikke er lagret)
    # V6 - HDIR-kataloger

LesPDF <- function(profiltype, geonivaa, aargang, modus) {
  # ARGUMENT LIST:
  # profiltype  <- "OVP"      # Tillatt: FHP OVP
  # geonivaa    <- "kommune"  # Tillatt: kommune bydel fylke      (Fylke ikke laget OVP 2020)
  # aargang     <- "2020"
  # modus       <- "prod"       # Tillatt: TEST eller PROD. For å velge path å lese batchen fra: TEST gir TEST, alt annet gir PROD.
  
  library(lespdf)         # Yusmans pakke  
  library(assertthat)
  
  # Min egen function for å telle sider:  (det ligger kopier flere steder, bør systematiseres)
  source("O:\\Prosjekt\\FHP\\PRODUKSJON\\BIN\\VALIDERING\\PDF-SJEKK\\TellSider_fcn.R")
  

  arbeidskat <- file.path(paste("O:\\Prosjekt\\FHP\\PRODUKSJON\\VALIDERING\\PDF-SJEKK", 
                                profiltype, geonivaa, "Datafiler", sep = "\\"))
  # For sikkerhets skyld: (selv om dette gir en warning når katalogen allerede finnes).
  dir.create(arbeidskat)
  
  
  
  # Ny katalogstruktur aug-2020 - parallell for TEST og PROD.
  # Deretter flyttet til ny felles filserver N:\
  # Skal være: "N:\\Helseprofiler_Rapportgenerator\\Oppvekst\\Produkter\\PDF_filer\\kommune\\2020\\Bokmaal"
  # Jeg leker med å tillate flere skrivemåter, selv om det ikke vil funke for "arbeidskat" ovenfor ...
  rotkatalog <- "O:\\Fagapplikasjoner\\Folkehelseprofiler\\Konfigurasjoner (PROD)"
  
  if(profiltype %in% c("FHP", "Folkehelse", "Folkehelseprofil")) {
    profilkat <- "Folkehelseprofiler"
  }
  if(profiltype %in% c("OVP", "Oppvekst", "Oppvekstprofil")) {
    profilkat <- "Oppvekst"
  }
    
  
  # Velge riktig kildeserver TEST eller PROD:
  if(modus == "TEST") {
    serverkat <- "PDF_test"
  } else {
    serverkat <- "PDF_filer"
  }
  
  # Bygge paths til kildekatalogene
  # Bokmål
  inndata_1 <- file.path(paste(rotkatalog, profilkat, "Produkter", serverkat,
                               geonivaa, aargang, "Bokmaal", sep = "\\"))
  # Nynorsk
  inndata_2 <- file.path(paste(rotkatalog, profilkat, "Produkter", serverkat,
                               geonivaa, aargang, "Nynorsk", sep = "\\"))
  
  
  # SJEKK AT KILDEKATALOGEN EKSISTERER OG SI FRA HVIS IKKE
  # Hvis jeg har glemt å opprette produktkataloger for SSRS, kræsjet scriptet uten forståelig feilmelding.
  assertthat::assert_that(is.dir(inndata_1), msg = "Sjekk om produktkatalog er riktig opprettet!")
  
  
  # LESE FILENE OG LAGRE RESULTATER

  # Bokmål
  analysefil <- lespdf(pdfmappe = inndata_1, filnavn = NULL, valgside = c(1,4))
  sidetall <- tellsider(inndata_1)
  write.csv(analysefil, file = paste(arbeidskat,"/","Bokmaal_lespdf.csv", sep=""), fileEncoding = "UTF-8")
  write.csv(sidetall, file = paste(arbeidskat,"/","Bokmaal_sidetall.csv", sep=""), fileEncoding = "UTF-8")
  
  # Nynorsk
  analysefil <- lespdf(pdfmappe = inndata_2, filnavn = NULL, valgside = c(1,4))
  sidetall <- tellsider(inndata_2)
  write.csv(analysefil, file = paste(arbeidskat,"/","Nynorsk_lespdf.csv", sep=""), fileEncoding = "UTF-8")
  write.csv(sidetall, file = paste(arbeidskat,"/","Nynorsk_sidetall.csv", sep=""), fileEncoding = "UTF-8")
  
}
