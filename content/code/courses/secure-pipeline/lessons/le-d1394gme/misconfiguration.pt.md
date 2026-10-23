---
title: "Misconfiguration: o que um arquivo diz, não o que roda"
version: 1
---

Um scan de vulnerabilidades pergunta se um pacote tem uma falha conhecida. Um scan de configuração faz
outra pergunta: **este arquivo define o que deveria?** Um Dockerfile que nunca nomeia um usuário, um
Deployment que permite escalar privilégio, um bucket aberto para o mundo no Terraform. O modo
`config` do Trivy traz algumas centenas dessas checagens, e rodá-lo no repositório do linkbox acha
algo em dois dos três arquivos:

```
ana@vm:~/linkbox$ trivy config -q --table-mode summary .

Report Summary

┌────────────────────┬────────────┬───────────────────┐
│       Target       │    Type    │ Misconfigurations │
├────────────────────┼────────────┼───────────────────┤
│ Dockerfile         │ dockerfile │         2         │
├────────────────────┼────────────┼───────────────────┤
│ k8s/admission.yaml │ kubernetes │         0         │
├────────────────────┼────────────┼───────────────────┤
│ k8s/linkbox.yaml   │ kubernetes │         4         │
└────────────────────┴────────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

Seis achados num projeto que as aulas 8 a 10 passaram três aulas endurecendo. **Cada um precisa da
mesma triagem de um achado de qualquer outra checagem**, e os do Dockerfile mostram por quê.

### DS-0002: uma afirmação verdadeira sobre o arquivo, e falsa sobre a imagem

```
ana@vm:~/linkbox$ trivy config -q Dockerfile

Report Summary

┌────────────┬────────────┬───────────────────┐
│   Target   │    Type    │ Misconfigurations │
├────────────┼────────────┼───────────────────┤
│ Dockerfile │ dockerfile │         2         │
└────────────┴────────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


Dockerfile (dockerfile)
=======================
Tests: 27 (SUCCESSES: 25, FAILURES: 2)
Failures: 2 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 1, CRITICAL: 0)

DS-0002 (HIGH): Specify at least 1 USER command in Dockerfile with non-root user as argument
════════════════════════════════════════
Running containers with 'root' user can lead to a container escape situation. It is a best practice to run containers as non-root users, which can be done by adding a 'USER' statement to the Dockerfile.

See https://avd.aquasec.com/misconfig/ds-0002
────────────────────────────────────────


DS-0026 (LOW): Add HEALTHCHECK instruction in your Dockerfile
════════════════════════════════════════
You should add HEALTHCHECK instruction in your docker container images to perform the health check on running containers.

See https://avd.aquasec.com/misconfig/ds-0026
────────────────────────────────────────
```

O alto diz que o Dockerfile não tem instrução `USER`, então o container roda como root. A primeira
metade é verdade. A segunda não é, e a imagem diz isso:

```
ana@vm:~/linkbox$ docker inspect --format "{{.Config.User}}" localhost:5000/linkbox:main
65532
ana@vm:~/linkbox$ tail -n 9 Dockerfile
# pip, and a user that is not root.
FROM gcr.io/distroless/python3-debian13:nonroot
COPY --from=build /packages /packages
COPY --from=build --chown=nonroot:nonroot /data /data
COPY app.py settings.py /app/
WORKDIR /app
ENV PYTHONPATH=/packages LINKBOX_DB=/data/linkbox.db
EXPOSE 8000
ENTRYPOINT ["python3", "-m", "gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

A imagem roda como 65532, o usuário `nonroot` que a aula 8 escolheu ao escolher a base
`gcr.io/distroless/python3-debian13:nonroot`. **O usuário vem da imagem base, e a checagem lê só o
arquivo à sua frente**, então não tem como saber. É um falso positivo neste projeto, no sentido que a
aula 3 definiu: a regra está certa em geral e errada sobre este caso.

Existem duas saídas honestas, e cada uma é uma decisão que fica registrada:

- **Fazer o arquivo dizer o que é verdade**: acrescentar `USER nonroot` ao estágio final. A imagem não
  muda, o achado some, e a próxima pessoa que trocar a base por uma que roda como root continua com um
  container não root sem precisar lembrar por quê.
- **Registrar uma exceção** com o motivo "a imagem base define o usuário", do jeito que a aula 7
  registra exceções, com um responsável e uma data.

A primeira é mais barata e protege contra um erro futuro, e por isso costuma ser a melhor das duas.
Esta aula não muda nenhum arquivo do projeto; a aula 19 volta ao Dockerfile com políticas escritas
para este projeto, que checam a mesma coisa de propósito.

O DS-0026, o baixo, pede um `HEALTHCHECK`. O Docker executa essa instrução; o Kubernetes a ignora e
usa as probes do Deployment. Para uma imagem que só roda num cluster, o achado pede algo que ninguém
leria.

### KSV-0125: "confiável" na opinião de quem?

O manifesto tem quatro. Pedir só o médio deixa a saída curta:

```
ana@vm:~/linkbox$ trivy config -q --severity MEDIUM k8s/

Report Summary

┌────────────────┬────────────┬───────────────────┐
│     Target     │    Type    │ Misconfigurations │
├────────────────┼────────────┼───────────────────┤
│ admission.yaml │ kubernetes │         0         │
├────────────────┼────────────┼───────────────────┤
│ linkbox.yaml   │ kubernetes │         1         │
└────────────────┴────────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


linkbox.yaml (kubernetes)
=========================
Tests: 17 (SUCCESSES: 16, FAILURES: 1)
Failures: 1 (MEDIUM: 1)

KSV-0125 (MEDIUM): Container linkbox in deployment linkbox (namespace: linkbox) uses an image from an untrusted registry.
════════════════════════════════════════
Ensure that all containers use images only from trusted registry domains.

See https://avd.aquasec.com/misconfig/ksv-0125
────────────────────────────────────────
 linkbox.yaml:33-58
────────────────────────────────────────
  33 ┌         - name: linkbox
  34 │           image: localhost:5000/linkbox:main
  35 │           ports:
  36 │             - containerPort: 8000
  37 │           env:
  38 │             - name: LINKBOX_TOKEN
  39 │               valueFrom:
  40 │                 secretKeyRef:
  41 └                   name: linkbox
  ..   
────────────────────────────────────────
```

A checagem diz que `localhost:5000` não é um registry confiável. A aula 10 decidiu o contrário, em
`k8s/admission.yaml`: o cluster aceita imagens desse registry e de nenhum outro. **A checagem embutida
tem uma lista de registries em que confia, e o projeto tem a sua**, então o achado é um desacordo entre
duas políticas, e a do projeto é a que está em vigor. Os três baixos são do mesmo tipo. Um é um limite de CPU que o manifesto não define: ele pede CPU e limita memória, uma escolha comum porque um limite de CPU estrangula em vez de proteger. Os outros dois são um ID de usuário e de grupo que o manifesto deixa para a imagem,
que roda como 65532, já acima dos 10000 que a checagem pede.

### Para que serve um scanner de configuração

Nenhum dos seis é um defeito que vai para produção. Isso não é motivo para desligar a checagem; é o
estado normal de um conjunto de regras de uso geral encontrando as decisões de um projeto. O que faz o
scan merecer o lugar é a mudança que ninguém pretendia: o pull request que apaga
`readOnlyRootFilesystem`, o manifesto novo copiado de um blog que roda privilegiado. Esses chegam como
achados **novos** contra uma linha de base de seis já julgados, que é o arranjo que a aula 7 montou
para os outros scanners.

| achado | veredito | por quê |
|---|---|---|
| DS-0002, sem `USER` | falso positivo aqui | a imagem base define 65532; vale escrever no arquivo mesmo assim |
| DS-0026, sem `HEALTHCHECK` | não se aplica | o Kubernetes usa probes |
| KSV-0125, registry não confiável | a política do projeto é outra | a admissão só permite `localhost:5000` |
| KSV-0011, sem limite de CPU | uma escolha para registrar | a memória é limitada; a CPU é pedida, não limitada |
| KSV-0020 e 0021, IDs acima de 10000 | verdade na imagem, não dito no arquivo | vale o 65532 da imagem |
