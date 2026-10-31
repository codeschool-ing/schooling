---
title: Uma política que só admite imagens atestadas
version: 1
---

**O Binary Authorization é uma verificação no momento do deploy: uma imagem só é admitida se carrega os
atestados que uma política pede.** A lição 2 terminou com uma varredura que relata e não recusa nada.
Esta é a parte que recusa. Uma política nomeia **atestadores** (attestors), cada um uma chave pública e um
nome; um **atestado** (attestation) é uma assinatura, feita com a chave privada de um atestador, sobre um
digest de imagem. Quando o Cloud Run ou o GKE é chamado a rodar uma imagem, o Binary Authorization procura
um atestado de cada atestador exigido sobre aquele digest exato, e se faltar um o deploy é recusado. Nada
nesta seção roda no seu computador; ela é ensinada pela documentação do Google e não foi executada.

A imagem errada é a de que o Binary Authorization inspeciona a imagem: que a varre, lê os rótulos ou
decide se ela é segura. Ele não faz nada disso. **Ele verifica assinaturas.** Toda decisão sobre segurança
foi tomada antes, por quem tinha uma chave privada e escolheu assinar. A política só garante que alguém
assinou.

## A política da loja

Um projeto tem uma política, escrita em YAML e importada com o `gcloud`:

```yaml
# policy.yaml
globalPolicyEvaluationMode: ENABLE
defaultAdmissionRule:
  evaluationMode: REQUIRE_ATTESTATION
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  requireAttestationsBy:
    - projects/planner-dev/attestors/built-by-cloud-build
    - projects/planner-dev/attestors/scan-passed
```

```sh
gcloud container binauthz policy import policy.yaml
```

Linha a linha:

- **`globalPolicyEvaluationMode: ENABLE`** isenta as imagens que o próprio Google roda para os
  componentes de sistema do GKE, então ligar a política não para os pods do próprio cluster.
- **`evaluationMode`** é `ALWAYS_ALLOW`, `ALWAYS_DENY` ou `REQUIRE_ATTESTATION`. O primeiro é onde todo
  projeto começa.
- **`enforcementMode`** decide o que uma falha faz. `ENFORCED_BLOCK_AND_AUDIT_LOG` recusa o deploy e o
  escreve no log de auditoria. `DRYRUN_AUDIT_LOG_ONLY` não recusa nada e escreve a mesma entrada, que é
  como uma política é introduzida: uma semana de teste mostra cada imagem que teria sido recusada, antes de
  qualquer uma ser.
- **`requireAttestationsBy`** lista os atestadores. Os dois são exigidos: um diz que a imagem saiu do build
  da loja, o outro que a varredura dela não tinha achado crítico corrigível. A ordem não significa nada;
  todos precisam estar presentes.

## A aplicação é por plataforma

A política só é consultada onde está ligada:

| plataforma | como se liga |
|---|---|
| GKE | `--binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE` no cluster |
| Cloud Run | `--binary-authorization=default` no serviço, ou uma política da organização que exija isso |

Um serviço do Cloud Run com deploy sem a opção roda qualquer imagem, com política ou sem. Então a restrição
de política da organização `run.allowedBinaryAuthorizationPolicies` é o que transforma "os serviços da loja
usam" em "nenhum serviço do projeto pode ter deploy sem ela", e a lição 4 de `gcp-foundations` é sobre
políticas da organização.

## Break-glass, e o que o mantém honesto

Um incidente às 3 da manhã pode precisar de uma imagem que ninguém assinou ainda. O Binary Authorization
permite **break-glass**: um deploy anotado assim é admitido seja o que for que a política diga, e a
admissão é escrita no log de auditoria como um evento de break-glass. Não fica escondido nem em silêncio,
e esse é o desenho inteiro: a porta existe, e abri-la deixa um registro que alguém revisa de manhã. Um
alerta baseado em log nessa entrada, assunto da lição 10, é o que garante que alguém revise.
