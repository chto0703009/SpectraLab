# Fristående ColorChecker-spektrum som JSON

ColorChecker-exporten finns nu även som en självständig JSON-fil med schema
`spectralab.colorchecker-spectra.v1`. Både Camera-41 PRE och Camera-41_DC läser
samma fil. Sessions-JSON och patchernas MAT-arkiv finns kvar som mätoriginal.
Den nya spektralfilen innehåller faktiska mätvärden; den är inte ett manifest
som kräver separata MAT-filer.

## Skapa filen

- Vid avslutad mätning med `measure_colorchecker_reflectance` skapas JSON
  automatiskt för en tavla med kontrollerad måltyp, exempelvis Digital SG.
- För befintliga mätningar: kör `export_colorchecker_spectra_json` och välj
  den färdiga, måltypbestämda sessionen. Efter ommätning väljs den senaste
  färdiga korrigerade sessionen.
- `export_colorchecker_spectral_artifact` skriver fortsatt MAT och skapar
  dessutom JSON bredvid MAT-filen. JSON behåller hela uppmätta våglängdsområdet,
  även om den äldre MAT-exportens arbetsområde är snävare.
- Avslutad kontrollerad ommätning skapar också en ny spektral-JSON.
- Befintliga exportfiler skrivs inte över.

Programmeringsgränssnitt i SpectraLab:

```matlab
spectralab.colorchecker.exportSpectralJSON(sessionFile, outputFile)
```

## Innehåll

Tavlans kontrollerade definition och fysiska identitet, sessionens UUID,
mätkontext, instrument-/kalibreringsuppgifter där de finns samt samtliga patchar.
Varje patch har `PatchID`, `WavelengthNM`, `Value`, uttrycklig `Unit` och
ursprungsarkivets UUID/innehållshash. Varken våglängder eller mätvärden beskärs
eller interpoleras. Enheter sparas som uppmätta; läsaren konverterar uttryckliga
andelar till procent när befintliga färgberäkningsrutiner behöver det.

`ContentSHA256` kontrollerar JSON-innehållet. Hashen beräknas över alla övriga
fält med sorterade objektnycklar, UTF-8 och de JSON-normaliserade värdena enligt
`spectralab.archive.jsonCanonicalText`. Det är en kontrollsumma, ingen digital
signatur. Ursprungsarkivens identiteter finns med för spårbarhet; arkivfilerna
behövs inte vid användning av exporten.

## Läs in i PRE eller DC

Välj **Import / replace material … → Spectra JSON** på fliken för
ColorChecker-referens och välj den enda exportfilen. Registrera och granska
referensens kvalitet som tidigare. Patch-ID och måltyp kontrolleras innan
mätdata används. Äldre MAT-referenser och sessionsmappar stöds fortfarande.

Lampans emissionsspektrum överförs separat som SpectraLabs emissions-JSON; äldre MAT-arkiv stöds också.
Den här ändringen gäller ColorCheckerns patchreflektanser.

## Verifiering

Export och import har testats med en verklig, korrigerad Digital SG-mätning
om 140 patchar. Testerna flyttar enbart JSON till en tom katalog och kontrollerar
inläsning, måltyp, projektimport, spektral bindning och referensimport i PRE/DC.
Manipulerade värden avvisas. Separata automatiska SpectraLab-tester täcker
export av syntetiska uppmätta patchar, explicit enhet, Unicode, kontrollsumma,
fullständighetskrav och skydd mot överskrivning.
