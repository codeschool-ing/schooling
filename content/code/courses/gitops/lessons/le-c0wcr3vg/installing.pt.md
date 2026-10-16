---
title: O comando flux
version: 1
---

**O comando do Flux faz dois trabalhos: escreve os manifestos do Flux por você, e lê de volta os
objetos do Flux de um jeito que uma pessoa consegue acompanhar.** É um arquivo num tarball, da mesma
versão dos controladores que ele instala, conferido como todo download deste curso:

```
ana@laptop:~$ ARCH=$(dpkg --print-architecture)
ana@laptop:~$ curl -fsSLO https://github.com/fluxcd/flux2/releases/download/v2.9.6/flux_2.9.6_linux_$ARCH.tar.gz
ana@laptop:~$ curl -fsSL https://github.com/fluxcd/flux2/releases/download/v2.9.6/flux_2.9.6_checksums.txt | grep " flux_2.9.6_linux_$ARCH.tar.gz$" | sha256sum --check
flux_2.9.6_linux_amd64.tar.gz: OK
ana@laptop:~$ tar -xzf flux_2.9.6_linux_$ARCH.tar.gz flux && sudo install -m 0755 flux /usr/local/bin/ && rm flux flux_2.9.6_linux_$ARCH.tar.gz
ana@laptop:~$ flux --version
flux version 2.9.6
```

O `flux check --pre` pergunta ao cluster se o Flux consegue rodar ali, antes de instalar qualquer
coisa:

```
ana@laptop:~$ flux check --pre
► checking prerequisites
✔ Kubernetes 1.37.0 >=1.33.0-0
✔ prerequisites checks passed
```

Uma versão do Kubernetes nova o bastante, e um `kubectl` que consegue falar com ela. A segunda coisa
de que o Flux precisa é o que o Argo CD precisava: um caminho só de leitura para o `fleet`. O mesmo
arranjo, uma conta própria no Gitea com permissão `read` e um token com um escopo só:

```
ana@laptop:~$ docker exec gitea gitea admin user create --username flux --password 'change-me-please' --email flux@example.org --must-change-password=false
New user 'flux' has been successfully created!
ana@laptop:~$ docker exec gitea gitea admin user generate-access-token --username flux --token-name cluster --scopes read:repository --raw > ~/flux.token
ana@laptop:~$ chmod 600 ~/flux.token
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '{"permission": "read"}' $API/collaborators/flux
204
```
