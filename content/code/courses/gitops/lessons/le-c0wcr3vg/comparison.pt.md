---
title: Argo CD e Flux, lado a lado
version: 1
---

**As duas ferramentas implementam os mesmos quatro princípios, e um time que escolha qualquer uma
com cuidado termina com GitOps.** Elas diferem na forma, e as diferenças decidem qual serve a um time,
mais do que qualquer lista de recursos. Tudo nesta tabela foi visto nas aulas 3 e 4:

| | Argo CD | Flux |
|---|---|---|
| a unidade | uma `Application`: uma fonte, um destino | uma cadeia: um objeto de fonte, depois uma `Kustomization` ou um `HelmRelease` que o aplica |
| interface | uma interface web, um API server com usuários e papéis próprios, uma CLI | a API do Kubernetes, e uma CLI que a lê |
| desvio | observado: uma mudança manual é desfeita em segundos com `selfHeal` | reaplicado no intervalo: uma mudança manual dura até a próxima reconciliação |
| poda | opcional por Application, `prune: true` | `prune: true` na Kustomization |
| um campo a deixar em paz | `ignoreDifferences`, por campo | deixá-lo fora do Git, ou uma anotação por objeto |
| Helm | gera os manifestos do chart e os aplica, sem release do Helm | instala um release do Helm de verdade, com a biblioteca do próprio Helm |
| segredos cifrados no Git | por um plugin ou um operador | decifragem SOPS embutida, aula 9 |
| tags de imagem novas | um projeto à parte, o Argo CD Image Updater | os controladores de imagem, parte do Flux |
| bootstrap | instalar, e depois um app de apps aplicado uma vez | `flux bootstrap`, ou os três passos desta aula |
| o que roda no cluster | seis deployments e um statefulset | quatro deployments, mais dois com os controladores de imagem |

## Como escolher

**Escolha o Argo CD quando as pessoas precisam ver.** A interface web dele desenha cada aplicação como
uma árvore de objetos com a saúde deles, e um time que inclui pessoas que não vivem num terminal ganha
uma imagem comum do que está publicado. Os projetos e papéis dele deixam um Argo CD servir muitos
times com permissões diferentes, sem dar a nenhum deles acesso ao próprio cluster.

**Escolha o Flux quando o cluster é a interface.** Ele tem menos partes, nada em que entrar, e tudo o
que faz é um objeto do Kubernetes que as permissões do próprio cluster já governam. Ele trata SOPS,
artefatos OCI, verificação de assinatura e atualização de imagens como parte de si, e não como
acréscimos, e as próximas aulas usam os quatro.

Muitas organizações rodam os dois, o Argo CD onde os times de aplicação querem a interface e o Flux
para a plataforma por baixo. **O que nenhuma organização deve fazer é rodar os dois nos mesmos
objetos**, e é por isso que esta aula começou removendo um.

## Qual o resto do curso usa

Da aula 5 em diante, o `fleet` é aplicado pelo **Flux**, porque as aulas 7 a 9 usam as partes que ele
já traz: artefatos num registry, assinaturas verificadas e segredos cifrados. Onde o Argo CD faz a
mesma coisa de outro jeito, a aula diz como, para que nada aqui seja conhecimento de uma ferramenta só.
