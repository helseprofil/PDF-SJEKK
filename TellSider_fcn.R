#' Les PDF filer: TELL SIDER
#' 
#' Dette er BARE FUNKSJONEN, den mÃ¥ sources og sÃ¥ brukes i en kommando som lager resultatfil.
#' 
#' KOPIERT OG MODIFISERT FRA YUSMANS FUNCTION LESPDF
#' Bruker pdftools::pdf_info, som bl.a. viser antall sider i hver fil.
#' OBS om list.files() : Bør ha med "pattern" for å utelukke Windows' Thumbs.db-fil, som 
#' er skjult så du ikke ser at den er der, men likevel trigger kræsj (det er jo ingen PDF-fil!).
#'
tellsider <- function(pdfmappe = NULL, filnavn = NULL){
    
    if (is.null(pdfmappe)) {
        stop("Mangler sti til pdfmappen", call. = FALSE)
    }
    
    if (is.null(filnavn)) {
        filnavn <- list.files(pdfmappe, pattern = "pdf$", ignore.case = TRUE)
    }
    
    pb <- txtProgressBar(min = 0, max = length(filnavn), char = "-", style = 3)
    utfil <- list()
    
    for (x in seq_along(filnavn)){
        setTxtProgressBar(pb, x)
        
        infopdf <- pdftools::pdf_info(paste0(pdfmappe, "\\", filnavn[x]))
        
        #infopdf <- stringi::stri_split(infopdf, regex = "\\r\\n")
        #infopdf <- lapply(infopdf, function(x) x[!grepl("^\\s*$", x)])
        
        infopdf2 <- data.table::data.table(filnavn = filnavn[x],
                                           antsider = infopdf[["pages"]])
        utfil[[x]] <- infopdf2
    }
    
    ferdigfil <- data.table::rbindlist(utfil)
    return(ferdigfil)
    Sys.sleep(0.005)
    
}