# helm-repo raspberry_home-assistant

## how to build

1. Create a new helm chart in the repo
2. If update chache version number Chart.yaml
   3Create helm package from terminal (IntelliJ)
    - helm package [DIR] (~/IdeaProjects$ helm package ./raspberry_home-assistant/)
     - mv package [DIR] (mv ./raspberry_home-assistant-1.0.7.tgz ./raspberry_home-assistant/)
4. Update index.yaml from terminal (IntelliJ)
    - helm repo index [DIR] (~/IdeaProjects/raspberry_home-assistant$ helm repo index .)
5. Commit and Push
6. helm repo update
7. helm search repo
8. help

## New way to build and publish your helm repo from github and actions
https://www.youtube.com/watch?v=x4IF7yyWw9g

https://github.com/devops4solutions/springboot-helm-chart/tree/main
## github pages

- using github actions [pages-build-deployment ]

    - [Repo](https://kad-bloemgx.github.io/raspberry_home-assistant/)
    - [Repo index.yaml](https://kad-bloemgx.github.io/raspberry_home-assistant/index.yaml)

    
## homeassistant


| key            | Value                                     |
|----------------|-------------------------------------------|
| appName        | homeassistant                             |
| namespace      | homeassistant                             |
| repository     | homeassistant/home-assistant tag "stable" |
| container.port | 8123                                      |