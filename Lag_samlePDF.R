## Combine PDFs using pdftools

## MAL-KOMMANDO:
## lag_samlePDF("FHP", "kommune", "2024", "PROD")			# Trenger ingen tilordning

##################################################
# Erstatter bruk av Acrobat Pro, som regelmessig ikke vil samarbeide, til å lage de samle-PDFene 
# vi bruker til siste sjekk.   
# (Hanna laget første utkast, stbj la det inn i felles "mal" for PDF-scriptene)
##################################################

# Install and load necessary packages
# install.packages("pdftools")

lag_samlePDF <- function(profiltype, geonivaa, aargang, modus) {
  # ARGUMENT LIST:
  # profiltype  <- "OVP"      # Tillatt: FHP OVP
  # geonivaa    <- "kommune"  # Tillatt: kommune bydel fylke      (Fylke ikke laget OVP 2020)
  # aargang     <- "2020"
  # modus       <- "prod"       # Tillatt: TEST eller PROD. For å velge path å lese batchen fra: TEST gir TEST, alt annet gir PROD.

start <- Sys.time()
library(pdftools)

# Set  directory PDF files
# Output lagres her:
arbeidskat <- file.path(paste("O:\\Prosjekt\\FHP\\PRODUKSJON\\VALIDERING\\PDF-SJEKK", 
                              profiltype, geonivaa, "Datafiler", sep = "\\"))

# Kildefiler:
# Modell: "N:\\Helseprofiler_Rapportgenerator\\Oppvekst\\Produkter\\PDF_filer\\kommune\\2020\\Bokmaal"
rotkatalog <- "O:\\Fagapplikasjoner\\Folkehelseprofiler\\Konfigurasjoner (PROD)"

if(profiltype =="FHP") {
  profilkat <- "Folkehelseprofiler"
}
if(profiltype =="OVP") {
  profilkat <- "Oppvekst"
}

# Velge riktig kildekatalog TEST eller PROD:
if(modus == "TEST") {
  serverkat <- "PDF_test"
} else {
  serverkat <- "PDF_filer"
}

# Bygge paths til kildekatalogene
# Bokmål
kildeBM <- file.path(paste(rotkatalog, profilkat, "Produkter", serverkat,
                             geonivaa, aargang, "Bokmaal", sep = "\\"))
# Nynorsk
kildeNN <- file.path(paste(rotkatalog, profilkat, "Produkter", serverkat,
                             geonivaa, aargang, "Nynorsk", sep = "\\"))

  # pdf_directory <- "N:/Helseprofiler_Rapportgenerator/Folkehelseprofiler/Produkter/PDF_filer/Kommune/2024/"
  # maalform <- "Nynorsk"

  # pdf_path <- file.path(pdf_directory, maalform)

# List all PDF files in the directory
pdf_filesBM <- list.files(kildeBM, pattern = "\\.pdf$", full.names = TRUE)
pdf_filesNN <- list.files(kildeNN, pattern = "\\.pdf$", full.names = TRUE)

# Output directory- if not existing
#output_directory <- file.path(pdf_directory, "combined_PDFs")
if (!file.exists(arbeidskat)) {
  dir.create(arbeidskat)
}

# Combine all PDF files into one
outputBM <- file.path(arbeidskat, "Fullt_sett_Bokmaal.pdf")
outputNN <- file.path(arbeidskat, "Fullt_sett_Nynorsk.pdf")

pdf_combine(pdf_filesBM, output = outputBM)
pdf_combine(pdf_filesNN, output = outputNN)

stop <- Sys.time()
runtime <- as.numeric(difftime(stop, start, units = "secs"))
cat("Kjøretid:", strftime(as.POSIXct(runtime, origin = "1970-01-01", tz = "UTC"), "%M:%S"), "\n")
}