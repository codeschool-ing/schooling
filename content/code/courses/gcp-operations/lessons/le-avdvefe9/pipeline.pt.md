---
title: Quem assina, e quando, na esteira da loja
version: 1
---

**Uma assinatura vale exatamente a decisão por trás dela.** Uma política que exige a assinatura de uma
chave que o build tem diz "esta imagem saiu do nosso build", e nada mais. Se o mesmo build assina toda
imagem que faz, uma imagem vulnerável também é assinada. Então cada atestador representa uma decisão, e o
passo que assina é o passo que a tomou. Esta seção é ensinada pela documentação do Google; nada dela foi
executado.

## Dois atestadores, duas decisões

| atestador | assinado por | o que a assinatura afirma |
|---|---|---|
| `built-by-cloud-build` | o último passo do build da lição 1 | este digest foi construído a partir do repositório pelo gatilho da loja, depois que os testes passaram |
| `scan-passed` | um passo que lê a varredura da lição 2 | a varredura deste digest não teve achado alto ou crítico com correção |

O segundo passo espera a varredura, lê as ocorrências do digest e só assina se elas passarem. Escrito como
passo de build, com a chave no Cloud KMS:

```yaml
  - id: attest-scan
    name: gcr.io/google.com/cloudsdktool/cloud-sdk:slim
    entrypoint: bash
    args:
      - -c
      - |
        gcloud artifacts docker images describe "$$IMAGE" --show-package-vulnerability \
          --format=json > /workspace/scan.json
        python3 /workspace/ci/scan_gate.py /workspace/scan.json
        gcloud beta container binauthz attestations sign-and-create \
          --artifact-url="$$IMAGE" --attestor=scan-passed \
          --keyversion=projects/planner-dev/locations/southamerica-east1/keyRings/binauthz/cryptoKeys/scan-passed/cryptoKeyVersions/1
```

`$$IMAGE` tem dois cifrões porque é a variável do shell, não uma substituição (lição 1). `scan_gate.py` é
a regra da própria loja, que sai com 1 quando a varredura não passa nela, e com essa saída o build para e
`sign-and-create` nunca roda: sem atestado, sem deploy. A regra vive no repositório, onde uma mudança nela
é revisada como uma mudança no código.

## A chave é o atestador

Quem pode usar a chave privada pode atestar. É por isso que ela vive no Cloud KMS, e por isso só a conta de
serviço do build tem `roles/cloudkms.signerVerifier` nela, nessa chave. **Uma pessoa que pode assinar com
essa chave pode admitir qualquer imagem**, e a política não percebe a diferença, porque verifica uma
assinatura e não a mão que a fez. O log de auditoria do uso da chave (lição 18) é o único lugar onde essa
diferença aparece.

## Validação contínua

A admissão é verificada uma vez, quando um pod ou uma revisão é criado. Uma imagem admitida na segunda
cuja varredura fica crítica na quinta continua rodando na sexta. A **validação contínua** do GKE reavalia
os pods em execução contra a política e escreve uma entrada de log para cada um que não seria mais
admitido. Ela relata e não para nada, e isso é de propósito: derrubar um serviço em execução porque um
alerta foi publicado durante a noite é uma decisão para uma pessoa, tomada a partir do relatório.
