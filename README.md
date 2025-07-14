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