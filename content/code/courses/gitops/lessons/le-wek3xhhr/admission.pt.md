---
title: Conferindo na porta do cluster
version: 1
---

**O Flux verificando um chart protege o que o Flux baixa.** Ele não faz nada por uma imagem citada num
Deployment, que o kubelet baixa, nem por um pod que alguém cria com `kubectl run`. O lugar que vê todo
pod antes de ele existir é a **admissão** do servidor da API: um webhook que o servidor da API chama a
cada requisição, e que pode recusá-la.

Três projetos fazem verificação de assinatura ali:

| | o que é | como uma regra fica |
|---|---|---|
| **Kyverno** | um motor de políticas geral cujas regras são objetos do Kubernetes | uma `ClusterPolicy` com `verifyImages`: quais nomes de imagem, qual chave ou identidade |
| **policy-controller do Sigstore** | o controlador de admissão do próprio Sigstore, só para assinaturas do cosign | uma `ClusterImagePolicy`: quais imagens, quais autoridades |
| **Ratify** | um verificador que o Gatekeeper chama, para vários formatos de assinatura | uma constraint do Gatekeeper e um verificador do Ratify |

Os três respondem a mesma pergunta no mesmo ponto: **esta imagem tem uma assinatura de uma chave ou
identidade em que eu confio?** Um pod cuja imagem não tem é recusado antes de o escalonador vê-lo, com
uma mensagem que cita a regra.

Uma regra do Kyverno para as imagens deste curso ficaria assim:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: bulletin-is-signed
spec:
  validationFailureAction: Enforce
  rules:
  - name: signed-by-the-release-key
    match:
      any:
      - resources:
          kinds: ["Pod"]
    verifyImages:
    - imageReferences: ["localhost:5001/bulletin*"]
      attestors:
      - entries:
        - keys:
            publicKeys: |-
              -----BEGIN PUBLIC KEY-----
              (the contents of cosign.pub)
              -----END PUBLIC KEY-----
```

**Ela não foi aplicada para este curso**: as imagens do Kyverno são publicadas em registries que a
máquina de gravação não alcança. Duas propriedades de uma política assim valem conhecer antes de
encontrar uma. Ela precisa verificar **digests**, então reescreve uma tag no spec de um pod para o
digest que verificou, e o pod roda exatamente o que foi conferido. E ela é **uma porta que pode ser
trancada por dentro**: uma política que recuse toda imagem, inclusive a do próprio motor de políticas
no próximo reinício dele, impede o cluster de se recuperar, e é por isso que políticas assim excluem
os namespaces do sistema e são experimentadas primeiro no modo `Audit`.
