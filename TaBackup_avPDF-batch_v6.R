# SKARP ØVELSE: Lag et R-script som tar backup av en PDF-batch.

# Har et Statascript som gjør det: 
# F:\Prosjekter\Kommunehelsa\PRODUKSJON\BIN\VALIDERING\PDF-SJEKK\1-taBackup_V<n>_avPDF-batch.do

# MAL-KOMMANDO:
# ta_backup(2025, "FHP", "Bydel")   # Trenger ingen tilordning

    # Metode:
    # Går til katalogen hvor SSRS lagrer originale PDF-er.
    # LESER Windows' tidsstempel på første fil i Bokmaal-katalogen, og bruker det som datotag.
    # Oppretter target-overkatalog med datotag.
    # Bruker "shell copy" dvs. Windows' copy-kommando, for å bevare tidsstempelet på filene.
    # Kopierer Bokmaal og Nynorsk til hver sine underkataloger.
    # Kopierer datafilene for PDF-sjekken til overkatalogen.
    
    # KREVER: Geonivå og profil-årgang settes øverst i scriptet.
    
    # OBS: Scriptet leser altså datoen på første fil i Bokmaal, dvs. den først i alfabetet.
    # LAGET SJEKK for at nytt katalognavn ikke er likt det gamle -> unngå å overskrive ting.

# v2: Analysefiler nå i PROD\VALIDERING, og kommunebatch er delt opp i fire halvparter.
# v3: Analysefiler litt endret etter R-funksjon for å lage dem. Kopierer hele analysefil-katalogen.
# v5: Ny katalogstruktur (PDB 2455 og N:\Helseprofiler_Rapportgenerator). Parallell til Stata v5.
# V6: Skrevet om til function med parametre i stedet for å måtte redigere scriptet før kjøring.

# ----------------------------------------------------------------------


ta_backup <- function(profilaargang, profiltype, geonivaa) {
# Nullstille fra tidligere kjøringer  - TRENGS IKKE i en function!
# rm(list = ls())

# ARGUMENT LIST:
# profilaargang       <- 2024
# profiltype     # Tillatt: "FHP"  "OVP"
# geonivaa       # Tillatt: "Kommune" "Fylke" "Bydel"
root <- "O:\\Prosjekt\\FHP\\"

prof_typ <- switch(profiltype,
                   FHP = "Folkehelseprofiler",
                   OVP = "Oppvekst")
  
analysefilkat <- paste(root, "\\PRODUKSJON\\VALIDERING\\PDF-SJEKK\\", profiltype, "\\", geonivaa, "\\Datafiler", sep = "")
targetkatalog <- paste(root, "\\Profiler\\0_Sikkerhetskopier", sep = "")

# ----------------------------------------------------------------------
# KJØRING
  #N:\Helseprofiler_Rapportgenerator\Folkehelseprofiler\Produkter\PDF_filer\Kommune\2023
kildekat <- paste("O:\\Fagapplikasjoner\\Folkehelseprofiler\\Konfigurasjoner (PROD)\\", prof_typ, "\\Produkter\\PDF_filer\\", geonivaa, "\\", profilaargang, sep = "")    # (ikke målform))

  # Under utviklingen: 
  #print(profilaargang)
  #print(geonivaa)
  #print(analysefilkat)
  #print(targetkatalog)
  #print(kildekat)


# 1. Finne/lage datotag.
#------------------------
setwd(kildekat)
filnavn <- shell("dir ./Bokmaal/*.pdf", intern = TRUE, translate = TRUE)
# Nå ligger første bokmålsprofil i element [6] av 'filnavn'. Datotid ligger forrest.

datotid <- substr(filnavn[6], 1, 17)                       # Men den må omformateres fra DOS-liste-formatet.
datotid.fmt <- "%d.%m.%Y  %H:%M"                           # Fortell hvordan den ser ut nå.
tidsverdi <- as.POSIXlt(datotid, format = datotid.fmt)       # Tidsfunksjon som tolker formatet og lager tidsverdi.
datotag <- format(tidsverdi, format = "%Y-%m-%d-%H-%M")


      #format(datotag, "%Y-%m-%d-%H-%M")                          # Nå ser 'datotag' riktig ut!
      #print(datotag)
      #dato <- substr(datotag, 1, 10)
      #klokke <- substr(datotag, 12, 5)



# 2. Sette opp kataloger. 'recursive' gjør at hele kjeden opprettes.
#------------------------
  # dir.create(file.path(targetkatalog, paste(profilaargang, "_PDF_FRYS", sep = "")))
  # dir.create(file.path(targetkatalog, paste(profilaargang, "_PDF_FRYS", sep = ""), prof_typ))
  # dir.create(file.path(targetkatalog, paste(profilaargang, "_PDF_FRYS\\", prof_typ, sep = ""), geonivaa))

if(!dir.exists(file.path(targetkatalog, paste(profilaargang, "_PDF_FRYS\\", prof_typ, sep = ""), geonivaa))) {
  dir.create(file.path(targetkatalog, paste(profilaargang, "_PDF_FRYS\\", prof_typ, sep = ""), geonivaa), recursive = TRUE)
  }

# Sjekke targetkatalognavnet, så vi ikke overskriver forrige backup
    # Henter ut liste over eksisterende backupkataloger.
    # Sammenlikner det nye katalognavnet med de eksisterende, og stopper hvis det fins fra før.
setwd(file.path(targetkatalog, paste(profilaargang, "_PDF_FRYS\\", prof_typ, sep = ""), geonivaa))
liste <- dir()

nykatalog <- paste(geonivaa, datotag, sep = "-")
feilkode <- 0

for(katalog in liste) {
  if(nykatalog == katalog) {
    print(" ")
    print("Katalognavnet for backup-filene har vært brukt før! Sjekk om det ligger")
    print("en gammel PDF-fil i batchen. ")
    print("Ta evt. backup manuelt, eller bytt navn på forrige backupkatalog.")
    print(" ")
    feilkode=9
    break
  } # end -if-
} # end -for-
stopifnot("Les meldingen ovenfor" = feilkode == 0)   # Stopper scriptet, så man kan håndtere katalognavn manuelt (unngå overskriving).

# Opprette og lagre navnet på den endelige targetkatalogen
dir.create(nykatalog)
targetkatalog <- file.path(getwd(), nykatalog)
cat(paste("\n Targetkatalog: ", targetkatalog), "\n")    #cat er en annen outputkommando, enklere enn print().



# 3. Kopiere.
#------------------------
# a) PDF-batchen
setwd(kildekat)
for(maalform in c("Bokmaal", "Nynorsk")) {
  cat(paste(maalform, "\n"))
  destination <- file.path(targetkatalog, maalform)
  dir.create(destination)    # Vil gi Warning når katalogen finnes fra før, men kræsjer ikke.
  shell(paste("copy ", file.path(".", maalform, "*.pdf"), ' "', destination, '"', sep = ""), translate = TRUE)
# Dvs: Gi DOS-kommando 'copy', med to argumenter, servert som én string bygget opp av paste().
# 'translate' oversetter katalogskilletegn fra / til \ .
# Må ha double quotes rundt target, der path inneholder space. Det var ikke så lett.
# Her er ingen 'replace'-switch, men 'copy' vil visst likevel skrive over eksisterende filer når den kjøres fra et script.
}

# b) Analyse-datafilene
setwd(analysefilkat)
destination <- file.path(targetkatalog)
shell(paste("copy *.*", ' "', destination, '"', sep = ""), translate = TRUE)

cat(paste("\n", "Filene er kopiert", "\n"))
}