# etherfunlab/workflow

**Ein Lehrbuch für die Softwareentwicklung mit KI-Agenten: erst die Prinzipien, dann die Regeln und Werkzeuge, die sie in die Praxis umsetzen.**

EtherFun Lab hat es für Leser mit Engineering-Hintergrund geschrieben: Leute, die mit Agenten entwickeln, neue Vibe Coder, Junior-Entwickler und künftige Teammitglieder.

Weitere Sprachen: [README.md](README.md) (简体中文 · English) · [README.zh.md](README.zh.md) (简体中文) · [README.ja.md](README.ja.md) (日本語)

## So nutzt du es

Schick deinem Agenten diesen Satz:

```
Lies https://github.com/etherfunlab/workflow und binde es nach ADOPT.md in mein Projekt ein.
```

- **Neues Projekt**: Der Agent fragt, welche Module und Templates du willst, und listet jede Änderung auf. Sobald du zustimmst, legt er zuerst `templates/base/` an, schichtet das gewählte Template darüber und installiert dann die Module.
- **Bestehendes Projekt**: Der Agent liest zuerst deine CLAUDE.md, AGENTS.md, `.claude/` und Git-Hooks. Dann fragt er, welche Module und Templates du willst, ob die Regeln auf Chinesisch oder Englisch sein sollen, ob Skills auf Projekt- oder User-Ebene installiert werden (das fragt er nur, wenn ein Modul Skills installiert) und welche optionalen Hooks dazukommen. Bevor er etwas schreibt, listet er jede Datei auf, die er ändern wird. Regeln, die dein Repo schon hat, überspringt er; bei widersprüchlichen Regeln entscheidest du.
- **Regeln außerhalb des Repos**: Bei neuen wie bestehenden Projekten liest der Agent die Regeldateien auf User-Ebene und in übergeordneten Verzeichnissen. Steht eine Regel nur dort, fragt er, ob er sie überspringen oder trotzdem installieren soll. Überspringst du sie, fehlt sie allen, die das Repo klonen, und auch dir, sobald du Rechner oder Agent wechselst.
- **Update**: Nach der Installation liegt in deinem Repo eine `.workflow.lock`, die festhält, welche Module installiert sind und von welchem Upstream-Commit sie stammen. Übergib dieses Repo noch einmal deinem Agenten. Er sammelt die Upstream-Änderungen seit diesem Commit, erklärt sie dir Modul für Modul und mergt, was du abnickst.

Teile, die Claude Code voraussetzen (Hooks, Pfadregeln unter `.claude/rules/`), sind gesondert markiert. Codex und andere Agenten überspringen die Hooks und bekommen die Pfadregeln als Abschnitte in der AGENTS.md.

## Aktive Rauschunterdrückung

Vielen fachfremden Vibe Codern fehlt eine Fähigkeit: aktive Rauschunterdrückung. In der Sprache der Thermodynamik heißt das: Entropie senken. Fehlt dir das Urteilsvermögen, um zu korrigieren, was die KI liefert, und lässt du einen Agenten einfach an einer Aufgabe weiterlaufen, versinkt der Kontext früher oder später im Rauschen.

Dieses Repo folgt dem Constitutional-AI-Ansatz von Claude: erst die Prinzipien aufstellen, die Gründe erklären und die konkreten Regeln daraus ableiten. Die neun Einträge unter „Auf einen Blick“ sind die Prinzipien dieses Repos.

> Quellen: Anthropic, [Claude's new constitution](https://www.anthropic.com/news/claude-new-constitution) (2026-01-22); Volltext unter [Claude's Constitution](https://www.anthropic.com/constitution); die Methode in [Constitutional AI: Harmlessness from AI Feedback](https://www.anthropic.com/research/constitutional-ai-harmlessness-from-ai-feedback) (2022).

## Disziplin

Die Disziplin ist allgemein anerkannte Engineering-Praxis; halte dich einfach daran. Die erste Tabelle ist der Inhalt des [CLAUDE.md-Templates fürs Root-Verzeichnis](templates/dev-root/README.en.md). Es liegt im Verzeichnis über deinen Repos und gilt für jedes davon. Die zweite Tabelle zeigt, was das [Modul engineering](modules/engineering/README.en.md) in jedes Repo installiert.

**Repo-übergreifende Disziplin**:

| Fakt | In einem Satz |
|---|---|
| Ein Weg zur Prod, Analyse-Repos nur lesend | Jedes Repo erreicht die Produktion über genau einen festgelegten Befehl; Audit-, Reporting- und Buchhaltungs-Repos lesen nur, Produkt-Repos dürfen abfragen und ändern. Rohdaten gelangen weder ins Terminal noch in einen Bericht; aggregiert wird lokal |
| Disziplin in öffentlichen Repos | Öffentliche Issues und PRs nennen nie private Repos, interne Projekte oder Prod-URLs; Belege werden anonymisiert |
| Immer nur ein offener PR | Parallele PRs verheddern sich, und die Konflikte bezahlt der Mensch; wird ein neuer PR abgelehnt, anhalten und nachfragen |
| Fenster und Ären an jeder Zahl | Jede berichtete Zahl nennt ihr Zeitfenster; ein Deploy ist eine Ära, Ären werden nicht vermischt |
| Pro Aufruf abgerechnete APIs: eine Runde, dann Stopp | Pro Aufruf abgerechnete externe APIs iterieren nie automatisch; wiederholt werden nur transiente Fehler desselben Aufrufs |
| Look-and-Feel beurteilen Menschen | Keine Selbstbewertungs-Skripte und keine Assertions auf Ästhetik, Layout oder Tonfall; etwa drei Kandidaten nebeneinander liefern, dann anhalten und die Wahl abwarten |
| Erst nachforschen, dann fragen | Bei einem Bug-Report suchst du die Ursache in Code und Logs, statt dir die Symptome vom Nutzer bestätigen zu lassen; gefragt wird nur an einer echten Weggabelung, mit Optionen |
| Commit-Hygiene | Conventional Commits auf Englisch; `.env` und Secrets werden nie committet; die Shell eines Agenten ist zustandslos, also Einzelaufrufe wie `conda run`, nie activate |

**Engineering-Haltung im Repo**:

| Fakt | In einem Satz |
|---|---|
| KISS | Drei ähnliche Codeblöcke sind besser als eine verfrühte Abstraktion; keine Erweiterungspunkte für Anforderungen, die es nicht gibt |
| Ein Fakt, eine Quelle | Jeder Wert, Zustand und jede Bedingung lebt an genau einer Stelle; alles andere wird abgeleitet |
| Schema und Schnittstellen aus dem Quellcode | Das Schema kommt aus den Migrationsdateien, die Schnittstellen aus dem Code; die Doku führt keine Kopien |
| Erst wiederverwenden, dann ergänzen | Erst nach einer vorhandenen Schnittstelle suchen; unklar, ob Frontend oder Backend: fragen |
| Fehler senken, nicht auf null jagen | Fehler gegen null zu treiben heißt, das Rauschen dieses Korpus zu fitten; eine gleichbleibende Metrik ist kein To-do |
| Releases statt Branches | Welche Version läuft, sagt die Release-Liste; den Rollback-Pfad vor dem Deploy festlegen |
| Regressionen an der Fehlermenge | Die Menge der fehlschlagenden Testnamen vergleichen, nicht die Anzahl |
| Contract zuerst | Erst den Schnittstellen-Contract deklarieren, dann implementieren; generierte API-Doku ist ein Artefakt, nicht die Quelle der Wahrheit |
| Fremdschlüssel beim Anlegen der Tabelle | Eine referenzierende Spalte bekommt ihren FK in der Migration, die sie anlegt; Nullbarkeit und ON DELETE sind eine gemeinsame Entscheidung; jeden FK indizieren |
| Sauber löschen | Gelöschter Code, gelöschte Konfiguration und Doku hinterlassen keinen Grabstein an der alten Stelle; Erklärungen gehören in die Commit-Message. Changelogs, Migrationen und Runbooks halten Änderungen weiter fest. Nur was nach dem Löschen tatsächlich wieder hinzugefügt wurde, behält eine Zeile: „Nicht wieder hinzufügen: X, Grund Y“ |

Eine weitere Regel ist unsere eigene Position und kein Konsens; sie kommt im selben Modul mit: **erst öffnen, dann die Schwelle nachziehen**. Umfang, Fähigkeiten und Berechtigungen zuerst aufmachen und erst anziehen, wenn die echte Obergrenze und die tatsächliche Nutzung bekannt sind. Angezogen wird eine Schwelle (Bedingung, Stufe, Cooldown, Kosten), nie wird die Fähigkeit selbst entfernt. Kein vorauseilendes Anziehen, bevor ein Fallback getestet ist. Die offene Phase muss Messwerte hinterlassen.

## Auf einen Blick

| Prinzip | In einem Satz |
|---|---|
| Vorgaben zuerst | Erst beschneiden: design → spec → plan → impl; je klarer die Anforderung, desto weniger geht schief |
| Code ist König | Quellcode ist die beste Anleitung für den Agenten; press Code nicht in „menschenlesbare“ Formate |
| Repo als Gedächtnis | Das Git-Repo ist Gedächtnis- und Kontextspeicher; zum Synchronisieren von Memory reichen `.memory/` und ein Hook |
| Schwach? Üben. | Diese Urteile ersetzt die KI nicht, aber sie kann sie dir beibringen; lerne gründlich |
| Eine Quelle der Wahrheit | Jedes maßgebliche Dokument genau einmal ablegen; dem Agenten im Memory sagen, wo er es liest |
| CLIs rufen CLIs auf | Claude Code steuert gh, codex, die Datenbank-CLI und fly |
| Schnittstellen im Blick | Claude Code erfindet Schnittstellen; das Memory erinnert es ans Wiederverwenden, und du passt auch auf |
| Erst reden, dann los | Anforderung unklar? Mit einem Web-LLM einen Prompt erarbeiten, dann brainstorming laufen lassen |
| Issues zwischen Repos | Bei Problemen über Repo-Grenzen hinweg öffnet ein Agent ein Issue für einen anderen |

## Im Einzelnen

### Vorgaben zuerst

Beschneiden. Halte dich immer an design → spec → plan → impl. Je klarer die Anforderungen und je detaillierter die Spec, desto unwahrscheinlicher verzieht ein schiefer Balken ganz oben alles, was darunter gebaut wird.

### Code ist König

Quellcode ist die beste Anleitung, die du einem Agenten geben kannst. Glaub nicht an JSON oder HTML als „Code-Visualisierung“. Agenten lesen Code weit besser als du, und Code in ein menschenlesbares Format zu pressen, damit Menschen ihn verstehen, führt den Agenten am Ende in die Irre.

### Repo als Gedächtnis

Ein Git-Repo ist das beste Gedächtnis und der beste Kontextspeicher, den es gibt. Commits und PRs helfen nicht nur menschlichen Teams bei der Arbeit, sie organisieren auch Agententeams hervorragend. Um Memory zu synchronisieren, leg im Repo-Root ein `.memory/` an und füge einen Post-Hook hinzu. Mehr braucht es nicht; eine zusätzliche Memory-Verwaltung ist überflüssig.

### Schwach? Üben.

Sprachwahl (Python, TS, Go, Rust), Architekturwahl (Vue, Flutter), Deploy-Flow (Docker, K8s), Design-Richtlinien, Iterationsprinzipien, ein Workflow (Anforderungen → Schema → Schnittstellen-Contract → Backend → Frontend → E2E-MVP), Netzwerk-Troubleshooting, die Kommandozeile, Lesen in Fremdsprachen: Diese Urteile kann die KI nicht ersetzen (sie kann sie dir aber beibringen). Lerne sie gründlich und glaub nicht an schicke Tricks, die die Informationsentropie senken.

### Eine Quelle der Wahrheit

Lege von jedem maßgeblichen Dokument genau eine Kopie ab und schreib einen Memory-Eintrag, der dem Agenten sagt, wo er sie liest. Ich habe mit einem Docs-Repo angefangen, in dem Spec, Pläne, Milestones, Schema und API lagen. Dann tauchten Felddefinitionen überall auf: manche im Docs-Repo, manche im Code, manche im eigenen `docs/` jedes Projekt-Repos. Also habe ich eine Regel aufgestellt: Das Docs-Repo enthält nur die projektweite Gesamt-Spec und Material für Menschen (zum Beispiel ein Rust-Glossar, das ich den Agenten habe zusammenstellen lassen, damit ich nachvollziehen kann, was er beim Schreiben von Rust getan hat). Specs liegen im `docs/superpowers/` des jeweiligen Projekts. Schema-Definitionen kommen ausschließlich aus `migration/*.sql`, Schnittstellen-Definitionen ausschließlich aus dem Code.

### CLIs rufen CLIs auf

CLIs können sich gegenseitig aufrufen. Claude Code am Steuer kann gh aufrufen, um PRs und Merges zu verwalten, codex, um Code zu reviewen, `supabase db query --linked`, um die Datenbank abzufragen und zu ändern, fly, um Server-Logs zu lesen, und so weiter.

### Schnittstellen im Blick

Claude Code erfindet manchmal versehentlich eine neue Schnittstelle. Schreib einen Memory-Eintrag, der ihm sagt, dass es vorhandene Schnittstellen wiederverwenden soll, und halt auch selbst die Augen offen. Wächst das Projekt, gehört manche Logik in eine Frontend-Middleware und andere hinter einen Backend-Endpunkt, und Claude Code errät nicht immer, was du meinst.

### Erst reden, dann los

Weißt du nicht, wie du eine Anforderung umsetzen sollst, sind Skills wie superpowers und gstack eine Option. Eine andere: erst mit einem Web-LLM (ChatGPT, Grok) darüber sprechen, daraus einen Prompt schreiben lassen und den an Claude Code übergeben, damit es brainstorming ausführt. Das ist allemal besser, als seinen Wunsch in Alltagssprache zu beschwören.

### Issues zwischen Repos

GitHub Issues sind großartig. Bei Problemen über Repo-Grenzen hinweg lasse ich einen Agenten ein Issue für einen anderen Agenten öffnen. Eine Kollaborationsplattform, die für Menschen gebaut wurde, funktioniert für Agenten genauso gut, und ich kann alles nachverfolgen.

## Von den Prinzipien zur Praxis

| Modul | Was es löst | Landet in deinem Repo |
|---|---|---|
| [writing](modules/writing/README.en.md) | Schreib- und Wortwahlregeln, chinesische Typografie, eine Schreibverfassung auf Dokumentebene | `.claude/rules/writing.md` (andere Agenten: ein Abschnitt in der AGENTS.md) + `WRITING.md` im Repo-Root |
| [checkup](modules/checkup/README.en.md) | Regelmäßiger Check-up der Regeldateien | Skill `rules-checkup`; optionaler Hook für Upgrade-Erinnerungen (nur Claude Code) |
| [rules-files](modules/rules-files/README.en.md) | Wie man CLAUDE.md / AGENTS.md schreibt | `.claude/rules/rules-files.md` (andere Agenten: ein Abschnitt in der AGENTS.md) |
| [engineering](modules/engineering/README.en.md) | Engineering-Haltung | ein Abschnitt in der AGENTS.md |
| [carriers](modules/carriers/README.en.md) | Wo jeder Satz hingehört | ein Abschnitt in der AGENTS.md |
| [memory](modules/memory/README.en.md) | Agent-Memory, ins Repo gespiegelt | ein Abschnitt in der AGENTS.md, `.memory/README.md`, `.githooks/`; Sync-Hook (nur Claude Code) |
| [review](modules/review/README.en.md) | Code-Review durch eine zweite Modellfamilie | Skill `codex-review` |
| [publish](modules/publish/README.en.md) | Dreistufige Abschluss-Pipeline für Dokumente | Skills `doc-publish`, `doc-fact-check`, `doc-polish`, `doc-review`, `precheck.sh` |
| [Repo-Templates](#repo-templates) + [ADOPT](ADOPT.md) | Projektgerüste und der Ablauf zum Einbinden | siehe nächster Abschnitt, dazu `.workflow.lock` |

## Repo-Templates

Ein neues Projekt beginnt immer mit `base`, darüber kommt ein Template für die jeweilige Projektart. Ein bestehendes Projekt kann sich auch nur diese obere Schicht holen.

| Template | Für | Landet in deinem Repo |
|---|---|---|
| `base` | jedes neue Projekt | eine indexartige AGENTS.md, eine CLAUDE.md mit der einzigen Zeile `@AGENTS.md`, `docs/superpowers/` |
| [frontend](templates/frontend/README.en.md) | Frontend-Projekte | `DESIGN.md`, `FONTS.md`, `GRID.md`, `LOCALE.md`, `RELEASE.md` und ein in die AGENTS.md gemergter Abschnitt |
| [dev-root](templates/dev-root/README.en.md) | das Verzeichnis über mehreren Repos | eine CLAUDE.md im übergeordneten Verzeichnis (Repo-übergreifende Disziplin; wird nur von Claude Code automatisch geladen) |

## Ergänzende Skills

EtherFun Lab hat diese Skills für die eigenen Projekte gebaut und legt sie in [`skills/`](skills/) ab. Beim Einbinden listet der Agent sie gesondert auf, und du installierst, welche du willst.

| Skill | Was er löst | Für |
|---|---|---|
| [zh-hant-converter](skills/zh-hant-converter/README.en.md) | Vereinfacht → Traditionell: intern nur die Schriftzeichen, nach außen auch das Vokabular | Teams zwischen Shenzhen und Hongkong |
| [ios-keyboard-page-shift](skills/ios-keyboard-page-shift/README.en.md) | Seite bleibt auf dem iPhone hochgeschoben, nachdem die Tastatur geschlossen wurde: erst die Ebene finden, dann reparieren | Teams, die mobile Webseiten bauen |
| [macos-disk-cleanup](skills/macos-disk-cleanup/README.en.md) | Mac-Festplatte fast voll: Build-Output und Caches aufräumen, vorher jeweils prüfen, ob das Löschen sicher ist | Entwickler am Mac |

## Upstream

- [superpowers](https://github.com/obra/superpowers): der Ablauf brainstorming → spec → plan → Umsetzung
- [gstack](https://github.com/garrytan/gstack): eine weitere Sammlung von Claude-Code-Skills
- [human-writing](https://github.com/Tao716/human-writing-skill): Feinschliff für chinesische Texte
- [humanizer](https://github.com/blader/humanizer): Feinschliff für englische Texte
- [codex CLI](https://github.com/openai/codex): das Modul review
- [OpenCC](https://github.com/BYVoid/OpenCC): zh-hant-converter

## Lizenz

MIT; siehe [LICENSE](LICENSE).
