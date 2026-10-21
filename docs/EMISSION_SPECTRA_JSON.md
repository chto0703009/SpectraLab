# Emissionsspektrum: gemensam JSON för SpectraLab, PRE och DC

Schema: `spectralab.emission-spectra.v1`. En fil innehåller en eller flera namngivna
emissionsmätningar. Det är ett fristående datautbyte, inte ett manifest med länkar
till MAT-filer. Befintliga MAT-arkiv och befintliga beräkningsrutiner stöds fortsatt.

## Mätning och export i SpectraLab

`measure_emission_spectrum` sparar nu JSON bredvid mätningens MAT-arkiv.
`measure_emission_series` sparar varje mätning som MAT och JSON innan nästa mätning,
och vid avslutad serie dessutom en samlad `<serienamn>_spectra.json`.
Ett avbrott lämnar de redan sparade enskilda mätningarna intakta.

En dialog anger roll, film-ID, rull-ID, fysisk ruta/steg, serie-ID och referensens
mät-UUID om den är känd. Använd `unassigned` när uppgiften ännu inte är känd.
Tillåtna roller: lamp, light_reference, base_plus_fog, gray_exposure,
colorchecker_exposure och unassigned. Mätordning används inte för att gissa roll
eller para ihop prov och referens.

Tidigare MAT-mätningar kan exporteras med `export_emission_json` (en eller flera
filer). Programmeringsgränssnitt:

```matlab
spectralab.exchange.exportEmission({archive1, archive2}, outputFile)
```

Vid ny mätning tillförs även de ursprungliga Spectrum-objekten och Binding-posterna
via `Spectra={measurement1, measurement2}, Bindings=bindings`.

## Vilka data följer med?

- Samtliga ursprungliga våglängder och spektrala värden, utan interpolering,
  beskärning eller normalisering, med ursprunglig enhet.
- Hela det sparade arkivet: identitet, originalets vetenskapliga hash,
  versionsuppgifter, tidsstämplar, instrument, metadata, kvalitetsfält och historik.
- Vid ny mätning: hela Spectrum.Instrument, Calibration och Metadata, inklusive
  rå instrumenttext och särskilda inställningar när instrumentrutinen registrerar dem.
- Film-/rull-/rut-/serieidentiteter och vald referensidentitet.
- För härledda medelvärden: källarkiven bäddas in och deras identiteter verifieras.
- En kontrollsumma för hela JSON-innehållet.

De numeriska spektrumen exponeras som vanliga JSON-tal. Ett typmärkt arkivbevarande
lager behåller även MATLAB-typer, arrayformer, exakta numeriska bitmönster och
full tidsupplösning. Inga MATLAB-objekt körs eller laddas genom JSON-avkodningen.

Export av en äldre MAT-fil kan bevara allt som finns i arkivet, men inte återskapa
uppgifter som aldrig sparades där. Detta markeras uttryckligen i
`Acquisition.Available` och dess orsak. Okända filmidentiteter eller roller fylls
inte i automatiskt. PDF/PNG är presentationer och ingår inte i spektraldatautbytet.

## Import och beräkning

PRE: på flik **6. Frame and spectrum mapping**, välj **Import emission JSON …**.
Hela originalfilen kopieras till projektet. Varje namngiven mätning registreras
som en självständig JSON under `spectra/imports/`. Bind sedan vald mätning och
referens till rätt fysisk rad. Registrerad roll, rut-ID och serie kontrolleras
vid bindning; en ljusreferens får inte ersätta en filmexponering.

PRE/DC: val av tavlans exponeringsljus eller digitaliseringsljus accepterar nu
JSON och MAT. För en serie väljer operatören uttryckligen en namngiven mätning.
PRE:s film-ColorChecker-granskning accepterar samma JSON-indata.

Inläsningen återskapar samma mätstruktur som MAT-inläsning. Våglängder, signalvärden
och enheter lämnas direkt i minnet till befintliga beräkningsrutiner för
transmittans, densitet, färgberäkning och ljusöverföring. Rutinerna finns med i
PRE:s och DC:s egna SpectraLab-paket; ingen extern SpectraLab-installation startas
eller behövs. Paketens filhashar kontrolleras av apparna.

Prov och referens måste höra till samma avsedda mätuppställning. Förhållandet mellan
rätt prov- och referenssignal ger transmittans, varifrån densitet beräknas enligt
befintlig metod. Kopplingen till FB+F och bar ljusreferens är explicita mätroller,
inte utbytbara antaganden.

NEG får fortsatt den färdiga filmkarakteriseringen från PRE och behöver ingen ny
inläsning av emissionsdata.

## Verifiering

- Ett verkligt SpectraLab-arkiv har återställts från JSON med identiska arkivfält,
  vetenskaplig hash och tidsstämplar.
- Ny mätmetadata, Unicode, rå instrumenttext, kalibreringsdata och numeriska
  specialfall har testats (se tests/test_emissionJSON.m i SpectraLab).
- PRE/DC har testats med serieimport, explicita filmrader, inläsning via medföljande
  SpectraLab-kod och jämförelse mot MAT-vägen. Transmittans, spektral densitet och
  Status A/M/W är identiska. Även PRE:s gråkalibrerings sammanslagning testas.
- Medelvärdesspektrum kan läsas med inbäddade källarkiv efter att MAT-originalen
  tagits bort. Ändrat JSON-innehåll avvisas. Appfönstren har starttestats.

Fysisk ny instrumentmätning har inte utförts av dessa automatiska tester.
