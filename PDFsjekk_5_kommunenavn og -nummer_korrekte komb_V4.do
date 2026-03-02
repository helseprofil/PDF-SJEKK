noisily display "{err:===============================================================================================}"
* Forrige skript sjekket at antall unike kombinasjoner av kommunenavn og andre oppl. er lik 
* antall kommuner. 
* Her testes det at det er de RETTE navnene (Fasit: SSB)

* i) Lage fasit
* a) Ta en kopi som kan herjes med. NB: Bruk Unicode-versjonen.
copy "$Geofasitkat/$Geofasitfil" "$datafiler/", replace

use "$Geofasitfil", clear //fasit: Sted_kode=string kode, Sted=navnet, geo=num.kode.
*rename Sted komnavn_iPDF

if "$geonivaa" == "fylke" keep if geo > 0 & geo < 80 //Beholde bare fylkesnummerne
if "$geonivaa" == "kommune" keep if geo >= 101 & geo <= 30000 //Luke vekk bydeler og fylker
if "$geonivaa" == "bydel" {
	keep if geo >= 30000  //Luke vekk kommuner og fylker
	drop if geo == 30116 | geo == 30117	//Sentrum og Marka
}

sort geo
rename geo komnr_iPDF
save "Fasit_SSB", replace //fasit
*exit

* ii) Sammenligne med PDF, bokmål
use pdfdata_1LinjePrKommune, clear
global n=_N/2			//Antall rader i datafilen
keep in 1/$n 			// Beholder bare bokmålslinjene

destring komnr_iPDF, replace
sort komnr_iPDF
noisily di "BOKMÅL:" _n `"Sammenlikner geo-NUMMER mot SSB-fasit ("Sted_kode"). Antall mismatch:"'
merge 1:1 komnr_iPDF using Fasit_SSB 
noisily count if _merge != 3
if `r(N)' != 0 {
	global feilfunnet = "$feilfunnet" + " 5"
	noisily di as err _n "Identifisere mismatch. Bokmål"
	noisily li komnr_iPDF Sted_kode _merge if _merge!=3
}



noisily di _n `"Sammenligne geo-NAVN mot SSB-fasit ("Sted"). Antall mismatch:"'
*noisily merge 1:1 komnavn_iPDF using Fasit_SSB
noisily count if komnavn != Sted
* Identifisere evt. mismatch
if `r(N)' != 0 {
	global feilfunnet = "$feilfunnet" + " 5"
	noisily di as err _n "Identifisere mismatch. Bokmål"
	noisily li komnavn_iPDF Sted_kode Sted if komnavn != Sted
}
	
* iii) Samme for nynorsk
use pdfdata_1LinjePrKommune, clear
global nnn=$n+1 // første nynorsk-linje
keep in $nnn/l 			// Nynorsk

destring komnr_iPDF, replace
sort komnr_iPDF
noisily di _n "NYNORSK:" _n `"Sammenlikner geo-NUMMER mot SSB-fasit ("Sted_kode"). Antall mismatch:"'
merge 1:1 komnr_iPDF using Fasit_SSB 
noisily count if _merge != 3
if `r(N)' != 0 {
	global feilfunnet = "$feilfunnet" + " 5"
	noisily di as err _n "Identifisere mismatch. Nynorsk"
	noisily li komnr_iPDF Sted_kode _merge if _merge!=3
}


noisily di _n `"Sammenligne geo-NAVN mot SSB-fasit ("Sted"). Antall mismatch:"'
*noisily merge 1:1 komnavn_iPDF using Fasit_SSB
noisily count if komnavn != Sted
* Identifisere evt. mismatch
if `r(N)' != 0 {
	global feilfunnet = "$feilfunnet" + " 5"
	noisily di as err _n "Identifisere mismatch. Nynorsk"
	noisily li komnavn_iPDF Sted_kode Sted if komnavn != Sted
}

noisily di _n "Script 5 kommunenavn ferdig"
