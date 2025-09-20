#  raspberry_home-assistant

## How to build with github actions

### workflow_helm-chart.yml

Na elke push op de "master" wordt er een github workflow (workflow_helm-chart.yml) gestart.
- build
- release

Indien er een wijziging is in de helm-charts wordt er een workflow (pages build and deployment) gestart.


Opmerking: Indien nieuwe versie gewenst is pas "version:" aan in de Chart.yaml


#### Achtergrondinformatie
1. https://www.youtube.com/watch?v=x4IF7yyWw9g
2. https://github.com/devops4solutions/springboot-helm-chart/tree/main

#### github pages


1. [repo](https://kad-bloemgx.github.io/raspberry_home-assistant/)
2. [repo index](https://kad-bloemgx.github.io/raspberry_home-assistant/index.yaml)


## homeassistant informatie

## handige helm commands


- helm repo list
- helm repo add raspberry_home-assistant https://kad-bloemgx.github.io/raspberry_home-assistant
- helm search repo raspberry_home-assistant
- helm repo update
- helm install home-assistant raspberry_home-assistant/raspberry_home-assistant



| key            | Value                                     |
|----------------|-------------------------------------------|
| appName        | homeassistant                             |
| namespace      | homeassistant                             |
| repository     | homeassistant/home-assistant tag "2025.5" |
| container.port | 8123                                      |

### ecu_html2json.py

Dit Python-script is ontworpen om data te extraheren uit een HTML-pagina van een ECU (Energy Communication Unit) van een zonnepaneelsysteem. Het script leest een HTML-tabel, verwerkt de data, en slaat deze op in een JSON-bestand.

Het bevat een validatiestap om te controleren of de `Lifetime generation`-waarde niet onverwacht daalt, wat kan duiden op een reset van het apparaat of een meetfout.

#### Vereisten

Zorg ervoor dat de benodigde Python-bibliotheken zijn geïnstalleerd:
```bash
pip install requests beautifulsoup4
```

#### Gebruik

Het script wordt uitgevoerd vanaf de command-line en vereist ofwel een lokaal HTML-bestand (`--file`) of een URL (`--url`) als bron.

**Argumenten:**

| Argument        | Beschrijving                                                                     | Vereist |
|-----------------|----------------------------------------------------------------------------------|:-------:|
| `--file`        | Pad naar een lokaal HTML-bestand.                                                |   Ja*   |
| `--url`         | URL van de ECU-webpagina.                                                        |   Ja*   |
| `--output-file` | Pad voor het output JSON-bestand (standaard: `./www/power_data_ecu.json`).       |  Nee    |
| `--error-file`  | Pad voor het JSON-bestand bij een validatiefout (standaard: `./www/power_data_ecu_fout.json`). |  Nee    |

*\* Je moet ofwel `--file` of `--url` opgeven.*

**Voorbeelden:**

1.  **Data ophalen van een URL:**
    ```bash
    python ecu_html2json.py --url http://192.168.1.100/
    ```

2.  **Data verwerken vanuit een lokaal bestand:**
    ```bash
    python ecu_html2json.py --file ./mijn_ecu_data.html
    ```

#### Output
het werkt

-   **`power_data_ecu.json`**: Bevat de meest recente, succesvol gevalideerde data.
-   **`power_data_ecu_fout.json`**: Wordt aangemaakt als de validatie mislukt (bijv. `Lifetime generation` is lager dan voorheen). Dit bestand is bedoeld voor inspectie.