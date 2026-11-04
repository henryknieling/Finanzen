# Finanzen

**Finanzen** ist eine native iOS-App zur manuellen Erfassung von Ausgaben und zur Verwaltung eines monatlichen Budgets. Die App ist mit SwiftUI gebaut, auf Deutsch gehalten und speichert ihre Daten lokal auf dem Gerät.

## Funktionen

- Drei Tabs: **Heute**, **Monat** und **Einstellungen**.
- Tageslimit, heutige Ausgaben, verbleibender Betrag und das berechnete Limit für morgen.
- Negative Tagesbeträge werden angezeigt, wenn die Ausgaben das Tageslimit überschreiten.
- Monatsbudget mit frei wählbarem Startdatum für die tägliche Aufteilung.
- Monatsfortschritt mit Ausgaben, Restbetrag und Fortschrittsanzeige.
- Ausgaben manuell erfassen, kategorisieren, mit einer Notiz versehen, bearbeiten und löschen.
- Verlauf der erfassten Ausgaben.
- Helles, dunkles oder systemgesteuertes Erscheinungsbild.
- Optionale Erinnerung am Monatsersten um 9 Uhr, ein Monatsbudget festzulegen.
- Helles, dunkles und getöntes App-Icon in den Asset-Varianten.

## Tagesbudget-Berechnung

Das Monatsbudget wird ab dem gewählten Startdatum auf die verbleibenden Kalendertage verteilt. Für den heutigen Tag wird zunächst das **Tageslimit** aus dem noch vorhandenen Monatsbudget und den verbleibenden Tagen berechnet. Der **verbleibende Betrag** ergibt sich aus:

```text
heutiges Tageslimit − heutige Ausgaben
```

Wird das Limit überschritten, ist der verbleibende Betrag negativ. Nicht ausgegebene Beträge bleiben im Monatsbudget und erhöhen damit automatisch die späteren Tageslimits. Das Limit für morgen berücksichtigt die bis dahin erfassten Ausgaben.

Jedes Monatsbudget und sein Aufteilungsstart werden getrennt für den jeweiligen Monat gespeichert. Ist für den ausgewählten Monat noch kein Budget festgelegt, zeigt der Monat-Tab zuerst die Budgeteingabe statt der Monatsübersicht.

## Projektstruktur

```text
.
├── Finanzen.xcodeproj/              Xcode-Projekt und App-Target
├── Finanzen/
│   ├── FinanzenApp.swift            App-Einstiegspunkt
│   ├── Models/
│   │   ├── Expense.swift            Ausgabenmodell
│   │   ├── AppTheme.swift           Theme-Auswahl und Akzentfarbe
│   │   └── FinanceStore.swift       Lokale Speicherung, Budgetregeln und Undo
│   ├── ViewModels/
│   │   ├── TodayViewModel.swift
│   │   ├── MonthViewModel.swift
│   │   ├── SettingsViewModel.swift
│   │   ├── HistoryViewModel.swift
│   │   └── ExpenseEditorViewModel.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── TodayView.swift
│   │   ├── TodayExpenseEntry.swift
│   │   ├── MonthView.swift
│   │   ├── SettingsView.swift
│   │   ├── HistoryView.swift
│   │   ├── ExpenseRow.swift
│   │   └── ExpenseEditorView.swift
│   ├── Services/
│   │   └── BudgetReminderScheduler.swift
│   └── Assets.xcassets/
│       └── AppIcon.appiconset/      Standard-, Dark- und Tinted-App-Icons
├── README.md
└── todos.md                         Projekt-Checkliste und weitere Aufgaben
```

## Architektur (MVVM)

Die App verwendet **Model–View–ViewModel (MVVM)**:

- **Models und Store:** `Expense` beschreibt eine Ausgabe. `FinanceStore` ist die gemeinsame Quelle für Budgets, Startdaten und Ausgaben. Er kapselt Speicherung, Budgetberechnung und Lösch-Undo.
- **ViewModels:** `TodayViewModel`, `MonthViewModel`, `SettingsViewModel`, `HistoryViewModel` und `ExpenseEditorViewModel` liegen jeweils in einer eigenen Datei im gemeinsamen Ordner `ViewModels/`. Sie stellen ihren Screens Daten und Aktionen bereit und koordinieren sie mit dem `FinanceStore`.
- **Views:** Jede SwiftUI-View hat eine eigene Datei unter `Views/`. `ContentView` erstellt den gemeinsamen Store, reicht ihn an die Screens weiter und verwaltet die Tab-Navigation.
- **Services:** `BudgetReminderScheduler` kapselt die Planung lokaler Benachrichtigungen und liegt getrennt von Modellen, ViewModels und Views.

Der Datenfluss verläuft damit von der View über ihr ViewModel zum `FinanceStore`. Änderungen am Store werden an die ViewModels weitergereicht, damit betroffene Ansichten aktualisiert werden.

## Daten und Benachrichtigungen

Ausgaben, Monatsbudgets und Startdaten werden als Codable-JSON in `UserDefaults` auf dem Gerät gespeichert. Es gibt weder ein Benutzerkonto noch einen App-Server oder eine Cloud-Synchronisierung.

Die Monatserinnerung ist standardmäßig ausgeschaltet. Sie lässt sich unter **Einstellungen → Erinnerungen** einschalten. iOS fragt dann nach der Berechtigung für Mitteilungen. Bei erteilter Berechtigung plant die App die nächste Erinnerung für den ersten Tag eines Monats um 9 Uhr.

## Voraussetzungen und Starten

- Xcode mit iOS-Simulator-Unterstützung
- iOS-Deployment-Target: iOS 17.0
- Keine externen Swift-Package-Abhängigkeiten

1. `Finanzen.xcodeproj` in Xcode öffnen.
2. Das Scheme **Finanzen** und einen iOS-Simulator auswählen.
3. Mit **Run** starten.

Alternativ lässt sich der Simulator-Build über die Kommandozeile erstellen:

```sh
xcodebuild \
  -project Finanzen.xcodeproj \
  -scheme Finanzen \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  build \
  CODE_SIGNING_ALLOWED=NO
```

Die Projekt-Checkliste und geplante Verbesserungen stehen in [`todos.md`](todos.md).
