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

---

## English

**Modular Automation System for macOS Apple Silicon**

MacLightController is a native macOS app designed for Apple Silicon that automates system features based on time triggers, events, and custom conditions. Its primary use case is automatic keyboard backlight control.

## Features

- **Menu Bar App**: Runs quietly in the menu bar
- **Modular Architecture**: Plugin-based system for extensibility
- **Keyboard Backlight Control**: Automatic backlight on/off
- **Flexible Triggers**: Specific times, sunrise/sunset, intervals
- **Intuitive Interface**: Modern native SwiftUI UI

## System Requirements

| Requirement | Specification |
|-----------|---------------|
| **macOS** | 13.0 (Ventura) or later |
| **Processor** | Apple Silicon (M1/M2/M3/M4) |
| **RAM** | 4 GB (system) |
| **Disk** | 50 MB |

## Installation

### From Xcode

1. Clone the repository
2. Open `MacLightController.xcodeproj` in Xcode 15+
3. Select the `MacLightController` target
4. Build and Run (⌘R)

### Important Notes

- The app requires IOKit access to control hardware
- App Sandbox is disabled to allow direct hardware access
- For distribution, signing and notarization are required

## Architecture

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

## Usage

### Menu Bar

Click the menu bar icon to:
- Turn the backlight on/off
- Adjust brightness with the slider
- View active automations
- Open settings

### Create an Automation

1. Open settings
2. Go to the "Automations" tab
3. Click the "+" button
4. Configure:
   - **Name**: A descriptive name
   - **Trigger**: When to run (time, sunrise, sunset, interval)
   - **Action**: What to do (on, off, set brightness)
5. Save

### Available Triggers

| Trigger | Description |
|---------|-------------|
| **Time** | Run at a specific time, with day selection |
| **Sunrise** | Run at sunrise (optional offset) |
| **Sunset** | Run at sunset (optional offset) |
| **Interval** | Run every X seconds/minutes/hours |

### Available Actions

| Action | Description |
|--------|-------------|
| **On** | Set brightness to maximum |
| **Off** | Set brightness to zero |
| **Toggle** | Toggle the current state |
| **Set Brightness** | Set a specific value (0-100%) |
| **Fade To** | Smooth transition to the target value |

## Project Structure

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

## Future Plugins (Roadmap)

- **Display Brightness**: Screen brightness control
- **Dark Mode**: Automatic dark mode toggle
- **Audio Volume**: System volume control
- **Focus Mode**: Automatic Focus activation

## Development

### Build

```bash
xcodebuild -project MacLightController.xcodeproj \
           -scheme MacLightController \
           -configuration Debug \
           build
```

### Tests

```bash
xcodebuild test -project MacLightController.xcodeproj \
                -scheme MacLightController \
                -destination 'platform=macOS'
```

## Troubleshooting

### "Keyboard backlight service not found"

This error can occur if:
- The Mac does not have a backlit keyboard
- The driver is not properly loaded

Try restarting the Mac.

### Notifications not working

Check that notifications are enabled in:
System Settings > Notifications > MacLightController

### Sunrise/Sunset not working

Verify that location is configured in settings, or enable "Use automatic location".

## License

Copyright © 2024 MacLightController. All rights reserved.

## Contact

For bug reports and feature requests, open an issue on GitHub.
