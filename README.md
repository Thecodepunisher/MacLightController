# MacLightController

**Sistema di Automazione Modulare per macOS Apple Silicon**

MacLightController è un'applicazione macOS nativa progettata per Apple Silicon che permette l'automazione di funzionalità di sistema basate su trigger temporali, eventi e condizioni personalizzate. Il caso d'uso primario è il controllo automatico della retroilluminazione della tastiera.

## Caratteristiche

- **Menu Bar App**: Gira discretamente nella barra dei menu
- **Architettura Modulare**: Sistema a plugin per funzionalità estendibili
- **Controllo Keyboard Backlight**: Accendi/spegni automaticamente la retroilluminazione
- **Trigger Flessibili**: Orari specifici, alba/tramonto, intervalli
- **Interfaccia Intuitiva**: UI SwiftUI moderna e nativa

## Requisiti di Sistema

| Requisito | Specifica |
|-----------|-----------|
| **macOS** | 13.0 (Ventura) o successivo |
| **Processore** | Apple Silicon (M1/M2/M3/M4) |
| **RAM** | 4 GB (sistema) |
| **Spazio** | 50 MB |

## Installazione

### Da Xcode

1. Clona il repository
2. Apri `MacLightController.xcodeproj` in Xcode 15+
3. Seleziona il target `MacLightController`
4. Build and Run (⌘R)

### Note Importanti

- L'app richiede l'accesso a IOKit per controllare l'hardware
- App Sandbox è disabilitato per permettere l'accesso diretto all'hardware
- Per la distribuzione, è necessario firmare e notarizzare l'app

## Architettura

```
┌─────────────────────────────────────────────────────────────┐
│                     MacLightController                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │  Menu Bar   │    │  Settings   │    │ Notifications│     │
│  │   (UI)      │    │    (UI)     │    │             │     │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │
│         └──────────────────┼──────────────────┘             │
│                  ┌─────────▼─────────┐                      │
│                  │    Core Engine    │                      │
│                  └─────────┬─────────┘                      │
│         ┌──────────────────┼──────────────────┐             │
│  ┌──────▼──────┐  ┌────────▼────────┐  ┌─────▼─────┐       │
│  │  Scheduler  │  │ Plugin Manager  │  │  Config   │       │
│  └──────┬──────┘  └────────┬────────┘  │   Store   │       │
│         │                  │           └───────────┘       │
│         │         ┌────────▼────────┐                      │
│         │         │ Keyboard Plugin │                      │
│         │         └────────┬────────┘                      │
│         │                  │                                │
│         └──────────────────▼────────────────────────────────│
│                        IOKit                                │
└─────────────────────────────────────────────────────────────┘
```

## Uso

### Menu Bar

Clicca sull'icona nella barra dei menu per:
- Accendere/spegnere la retroilluminazione
- Regolare la luminosità con lo slider
- Vedere le automazioni attive
- Accedere alle impostazioni

### Creare un'Automazione

1. Apri le impostazioni
2. Vai alla tab "Automazioni"
3. Clicca il pulsante "+"
4. Configura:
   - **Nome**: Un nome descrittivo
   - **Trigger**: Quando eseguire (orario, alba, tramonto, intervallo)
   - **Azione**: Cosa fare (accendi, spegni, imposta luminosità)
5. Salva

### Trigger Disponibili

| Trigger | Descrizione |
|---------|-------------|
| **Orario** | Esegui a un'ora specifica, con selezione giorni |
| **Alba** | Esegui all'alba (con offset opzionale) |
| **Tramonto** | Esegui al tramonto (con offset opzionale) |
| **Intervallo** | Esegui ogni X secondi/minuti/ore |

### Azioni Disponibili

| Azione | Descrizione |
|--------|-------------|
| **Accendi** | Porta la luminosità al massimo |
| **Spegni** | Porta la luminosità a zero |
| **Toggle** | Inverte lo stato attuale |
| **Imposta Luminosità** | Imposta un valore specifico (0-100%) |
| **Fade To** | Transizione graduale al valore specificato |

## Struttura del Progetto

```
MacLightController/
├── App/
│   ├── MacLightControllerApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── Engine/
│   ├── Plugins/
│   ├── Scheduler/
│   └── Storage/
├── Models/
├── Plugins/
│   └── KeyboardBacklight/
├── Services/
├── UI/
│   ├── MenuBar/
│   ├── Settings/
│   ├── Automations/
│   └── Shared/
└── Resources/
```

## Plugin Futuri (Roadmap)

- **Display Brightness**: Controllo luminosità schermo
- **Dark Mode**: Toggle automatico modalità scura
- **Audio Volume**: Controllo volume sistema
- **Focus Mode**: Attivazione automatica Focus

## Sviluppo

### Compilazione

```bash
xcodebuild -project MacLightController.xcodeproj \
           -scheme MacLightController \
           -configuration Debug \
           build
```

### Test

```bash
xcodebuild test -project MacLightController.xcodeproj \
                -scheme MacLightController \
                -destination 'platform=macOS'
```

## Troubleshooting

### "Servizio keyboard backlight non trovato"

Questo errore può verificarsi se:
- Il Mac non ha una tastiera retroilluminata
- Il driver non è caricato correttamente

Prova a riavviare il Mac.

### Notifiche non funzionano

Verifica che le notifiche siano abilitate in:
Preferenze di Sistema > Notifiche > MacLightController

### Alba/Tramonto non funzionano

Verifica che la posizione sia configurata nelle impostazioni, oppure abilita "Usa posizione automatica".

## Licenza

Copyright © 2024 MacLightController. Tutti i diritti riservati.

## Contatti

Per bug report e feature request, apri una issue su GitHub.
