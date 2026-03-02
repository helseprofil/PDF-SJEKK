* FELLESSCRIPT
noisily display "{err:===============================================================================================}"
*****************************************************************************************
noisily display "Sjekker at antall unike kombinasjoner av kommunenavn, -nummer, folketall" 
noisily display "og batchnummer er lik antall kommuner." 

*noisily display "Sjekker at like kommunenavn opptrer i) samlet (6 og 6 i 2012-profilene, nemlig i tittel," 
*noisily display "barometer, 4xbunntekst), og at  ii) antall unike kombinasjoner av kommunenavn, -nummer," 
*noisily display "-batchnummer og folketall er lik antall kommuner." 
*****************************************************************************************

cd "$datafiler"
use pdfdata_AlleLinjerPrKommune, clear
qui: gen testnavn=(komnavn!=komnavn[_n-1]) // bør ta verdi 1 hver femte linje når ny kommune.
qui: 
su testnavn 			// forventet verdi 0.2 = 1/5
noisily di _n "Assert: Forventet verdi= 1/5 = 0.2 (Sjekker at like kommunenavn opptrer samlet)"
capture noisily assert r(mean)>.199 & r(mean)<.201	// forventet verdi: 1/5
if _rc == 9 {		//hvis verdien ikke stemmer, sett flagg
	global feilfunnet = "$feilfunnet" + " 4"
}

egen temp=total(testnavn)  // Totalt antall kommunenavn-skift legges inn i ny variabel
noisily di _n "Forventet verdi min=max=`: display 2 * $antkommuner': ett cluster per GEO per målform =2*$antkommuner"
noisily su temp	
capture noisily assert `r(max)' == $antkommuner *2
if _rc == 9 {		//hvis verdien ikke stemmer, sett flagg
	global feilfunnet = "$feilfunnet" + " 4"
}


egen testPDF = concat(komnavn komnr komfolk batchF batchI) if batchF>""
qui tab testPDF
noisily di _n _n "b) Sjekker at alle batchnummer for flatfilene er like."
noisily di _n "Assert: si fra hvis ikke antall unike kombinasjoner av kommunenavn og batchnummer = antall GEO"
capture noisily assert r(r)==$antkommuner 
if _rc == 9 {		//hvis verdien ikke stemmer, sett flagg
	global feilfunnet = "$feilfunnet" + " 4"
}

* Årstall: Sjekk at år-i-heading og -i-bunntekst har bare én verdi, som er lik $profilårgang.
noisily di _n "Årstall i heading: Sier fra hvis ikke a) alle er like, b) de stemmer med profilårgangen."
levelsof aar_i_heading, local(levels) clean
	*di "`levels'"
capture noisily assert wordcount("`levels'") == 1
if _rc != 0 {
	di as err "Det forekommer flere årstall."
	global feilfunnet = "$feilfunnet" + " 4"
}

capture noisily assert "`levels'" == "$profilaar"
if _rc != 0 {
	noisily di as err "Årstall matcher ikke profilårgang." 
	global feilfunnet = "$feilfunnet" + " 4"
}
	else noisily di "  -OK"

noisily di "Årstall i bunntekst: Sier fra hvis ikke a) alle er like, b) de stemmer med profilårgangen."
levelsof aar_i_bunntxt, local(levels) clean
	*di "`levels'"
capture noisily assert wordcount("`levels'") == 1
if _rc != 0 {
	di as err "Det forekommer flere årstall."
	global feilfunnet = "$feilfunnet" + " 4"
}

capture noisily assert "`levels'" == "$profilaar"
if _rc != 0 {
	noisily di as err "Årstall matcher ikke profilårgang."
	global feilfunnet = "$feilfunnet" + " 4"
}
	else noisily di "  -OK"

* Sjekke at folketall er riktig:
* Isolerer én rad per kommune i Indikator.txt og merger med pdfdata.
import delimited Indikator.txt, varnames(1) delimiter("\t") encoding("UTF-8") clear
keep if lpnr == 2
drop tidsserieurl metadataurl

if "$geonivaa" == "fylke"   tostring sted_kode, format(%02.0f) replace
if "$geonivaa" == "kommune" tostring sted_kode, format(%04.0f) replace
if "$geonivaa" == "bydel"   tostring sted_kode, format(%06.0f) replace

rename sted_kode komnr_iPDF

merge m:m komnr_iPDF using pdfdata_1LinjePrKommune	//To linjer pr kommune i begge filer!

noisily di "Folketall i bunntekst: Sier fra hvis det ikke matcher Indikator.txt"
count if real(komfolketall) != folketall
* Identifisere evt. mismatch
if `r(N)' != 0 {
	global feilfunnet = "$feilfunnet" + " 4"
	noisily di as err "Identifisere mismatch. "
	noisily li komnr_iPDF sted maalform komfolketall folketall if real(komfolketall) != folketall
}
else noisily di "  -OK"

noisily di _n "Script 4 tittel/bunntekst/barometerhode/antall unike kombinasjoner ferdig"
