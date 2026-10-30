---
title: A chave estática, e por que ela é o problema
version: 1
---

O serviço `photos` da loja roda no cluster GKE das lições 13 e 14 e lê imagens de um bucket do
Cloud Storage, `shop-photos`. Para chamar a API do Storage ele precisa de uma identidade do Google.
**O jeito rápido de dar uma é uma chave de conta de serviço: um arquivo JSON com uma chave privada,
montado no pod a partir de um Secret do Kubernetes.** Funciona de primeira, e é o arranjo que esta
lição existe para remover.

## O que é um arquivo de chave

Uma chave de conta de serviço é criada com um comando documentado, que precisa de conta e não foi
executado aqui:

```sh
gcloud iam service-accounts keys create photos-key.json \
  --iam-account=photos-reader@planner-dev.iam.gserviceaccount.com
```

O que ele escreve tem este formato. Crie uma pasta `static-key` em `~/gcp`, entre nela e crie o
arquivo com estes valores, que **não são uma chave**: têm os campos de uma chave e nada que um dia
autenticaria.

```sh
cat > photos-key.json <<'EOF'
{
  "type": "service_account",
  "project_id": "planner-dev",
  "private_key_id": "0000000000000000000000000000000000000000",
  "private_key": "-----BEGIN PRIVATE KEY-----\nNOT A REAL KEY, ONLY ITS SHAPE\n-----END PRIVATE KEY-----\n",
  "client_email": "photos-reader@planner-dev.iam.gserviceaccount.com",
  "client_id": "000000000000000000000",
  "token_uri": "https://oauth2.googleapis.com/token"
}
EOF
```

**Uma chave real tem uma chave privada que funciona onde esta tem uma frase, e é só disso que ela
precisa.** Quem tiver o arquivo age como `photos-reader` de qualquer computador do mundo, até
alguém apagar a chave. Uma chave gerenciada pelo usuário não expira sozinha, a menos que uma
política da organização defina um prazo.

## Dentro de um Secret

O passo seguinte de costume põe o arquivo num Secret do Kubernetes, para o pod montá-lo. O `data`
de um Secret guarda valores em base64, que é o que o `kubectl create secret` escreveria. No
laboratório, sem cluster, o `printf` escreve a mesma coisa:

```
ana@laptop:~/gcp/static-key$ printf "apiVersion: v1\nkind: Secret\nmetadata:\n  name: photos-key\ndata:\n  key.json: %s\n" "$(base64 -w0 photos-key.json)" > secret.yaml
ana@laptop:~/gcp/static-key$ cut -c1-72 secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: photos-key
data:
  key.json: ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQi
```

Essa linha parece proteção, e **base64 é uma codificação, não criptografia.** Qualquer um que leia o
Secret, com `kubectl get secret -o yaml`, um backup do estado do cluster ou uma cópia do manifesto
que foi para o git, desfaz isso sem senha:

```
ana@laptop:~/gcp/static-key$ grep key.json secret.yaml | awk '{print $2}' | base64 -d | grep -E 'client_email|private_key"'
  "private_key": "-----BEGIN PRIVATE KEY-----\nNOT A REAL KEY, ONLY ITS SHAPE\n-----END PRIVATE KEY-----\n",
  "client_email": "photos-reader@planner-dev.iam.gserviceaccount.com",
```

## Por que isso é o problema

Tudo que pode dar errado com uma chave dá errado em silêncio:

- **Ela vaza sem sinal.** Uma chave copiada de um Secret, de um laptop ou de um log de CI funciona
  de qualquer lugar, e o log de auditoria mostra `photos-reader` fazendo o que `photos-reader`
  sempre faz.
- **Ela não acaba.** Nada a expira, então uma chave criada para um teste três anos atrás ainda abre
  o bucket hoje.
- **Trocá-la é um projeto.** Uma chave nova precisa ser criada, posta em todo Secret que leva a
  antiga, publicada, e só então a antiga apagada; as equipes adiam isso.

A recomendação do próprio Google é evitar chaves gerenciadas pelo usuário sempre que houver
mecanismo melhor, e é comum as organizações proibirem criá-las com a política
`iam.disableServiceAccountKeyCreation`. Para um pod no GKE o mecanismo melhor é a **Workload
Identity Federation for GKE**: o pod recebe tokens de curta duração de uma identidade do Google sem
existir arquivo nenhum. As próximas três seções a montam, e a última delas dispensa até a conta de
serviço do Google.

Apague o arquivo e o Secret antes de seguir; eles só serviram de exemplo do que não guardar.
