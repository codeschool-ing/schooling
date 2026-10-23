---
title: A mesma troca no GitHub Actions e num provedor de nuvem
version: 1
---

Tudo nas duas seções anteriores tem um equivalente num serviço de CI hospedado, e é nesses
equivalentes que mora a maioria das configurações reais. **Esta seção é ensinada a partir da
documentação do GitHub e da AWS e não foi executada**: ela precisa de um repositório no GitHub com
Actions e de uma conta de nuvem, e o curso não te dá nenhum dos dois. O que você construiu na sua
máquina é a mesma troca com todas as peças à vista, e a tabela do fim liga uma à outra.

### O workflow pede um token

Um job do GitHub Actions só recebe um token de identidade se o workflow conceder a permissão de pedir
um. A forma documentada, para um job que faz deploy na AWS:

@@FENCE 1@@

`id-token: write` parece acesso de escrita a alguma coisa, e não é: ele permite que o job peça ao
serviço de tokens do GitHub um JWT sobre si mesmo. Sem ele o pedido falha, e é por isso que o
`permissions: contents: read` da aula 16 no topo de um workflow já impede todo job que não precisa de
um token de recebê-lo. A action pede o token, envia à AWS e põe as credenciais temporárias que a AWS
devolve no ambiente do job. O número da conta é o exemplo da documentação da AWS, e a action está
fixada por commit, como a aula 16 exige. O commit foi conferido do jeito que a aula 16 confere:

@@FENCE 2@@

### O provedor de nuvem decide quais execuções

Na AWS, a **trust policy** da role faz o papel da role do Vault. O serviço de tokens do GitHub é
registrado uma vez na conta como provedor de identidade, e cada role diz quais tokens dele podem se
tornar aquela role:

@@FENCE 3@@

Leia em paralelo com o `linkbox-main.json`. O principal `Federated` é o `bound_issuer` e a chave
pública juntos: em qual assinatura acreditar. A condição em `aud` é o `bound_audiences`. A condição em
`sub` é o `bound_claims`, escrito como uma string só porque é o claim que as condições da AWS mais
usam. A federação de identidade de cargas de trabalho do Google Cloud põe a mesma checagem num
`attribute_condition`, e a Azure no subject de uma credencial federada; os nomes mudam e a decisão não.

**A condição em `sub` é a linha que importa, e é a que fica de fora.** O emissor do GitHub assina
tokens para todo repositório do GitHub, então uma role que confere só a audiência confia em todos
eles: qualquer workflow, no repositório de qualquer pessoa, que peça um token com aquela audiência. É
a role `linkbox-any` de duas seções atrás, com o GitHub inteiro onde estavam as branches do seu
servidor de CI.

### Subjects, e os erros cometidos com eles

A documentação do GitHub lista as formas que o `sub` assume, e a forma depende do que disparou o job:

| o job | o `sub` dele |
|---|---|
| um push em `main` | `repo:ana/linkbox:ref:refs/heads/main` |
| uma tag | `repo:ana/linkbox:ref:refs/tags/v1.4.0` |
| um pull request | `repo:ana/linkbox:pull_request` |
| um job que nomeia um environment | `repo:ana/linkbox:environment:production` |

Três erros saem direto dessa tabela.

**Um curinga onde cabia um valor exato.** `StringLike` com `repo:ana/*` confia em todo repositório da
dona, inclusive o que alguém criar no ano que vem para um experimento. `repo:ana/linkbox:*` confia em
toda branch e todo pull request do linkbox, que é a role larga de novo.

**Confiar em pull requests para qualquer coisa que faça deploy.** Todo pull request recebe o mesmo
subject, seja quem for que o abriu e o que for que ele mude, então uma condição em `pull_request` não
distingue a mudança do seu colega da de um estranho. A aula 16 mostrou o que um workflow disparado
por pull requests pode ser levado a rodar.

**Esquecer que um environment substitui a branch.** Um job que nomeia `environment: production`
recebe o subject de environment, sem `ref` nele, então uma condição em `refs/heads/main` deixa de
casar no dia em que alguém acrescenta o environment. Amarre as roles de deploy ao environment, e use
as regras de proteção do próprio environment no GitHub para decidir quais branches podem usá-lo.

O token também leva `repository_id` e `repository_owner_id`, números que continuam iguais quando um
repositório é renomeado. Uma condição sobre um nome pode ser satisfeita por quem for dono desse nome
depois; uma condição sobre o número, não.

### O que ainda precisa ser protegido

A federação remove a credencial guardada. Ela não remove a confiança, ela a muda de lugar: para **a
chave de assinatura do emissor**. Na sua máquina é a `~/ci/oidc/ci-oidc.key`, e uma cópia dela
emitiria tokens para qualquer branch. No GitHub é uma chave que o GitHub guarda e cuja metade pública
ele publica em `https://token.actions.githubusercontent.com/.well-known/jwks`, e é por isso que quem
confere é configurado com o endereço do emissor e não com uma chave colada. O Vault faz o mesmo com
`oidc_discovery_url` no lugar de `jwt_validation_pubkeys`: ele busca as chaves, percebe quando mudam e
acompanha uma rotação sem ninguém editar a configuração. Uma chave colada, como nesta aula, precisa
ser trocada à mão em todo lugar onde foi colada.

### As duas lado a lado

| na sua máquina | no GitHub Actions e na AWS |
|---|---|
| `~/ci/oidc/ci-oidc.key` e `mint.py` | o serviço de tokens do GitHub e a chave de assinatura dele |
| `ci-oidc.pub` colada em `auth/jwt/config` | o conjunto de chaves publicado, buscado pelo provedor de nuvem |
| o hook chamando `mint.py` em cada execução | `permissions: id-token: write` e um pedido do job |
| a role `linkbox-main` com `bound_claims` | a trust policy da role com uma condição em `sub` |
| a policy `linkbox-sign` | a policy de permissões da role |
| um token do Vault por 5 minutos | credenciais temporárias, uma hora por padrão |
| `ci/vault-read.sh` | a action `configure-aws-credentials` |

Quando terminar, remova o contêiner do Vault. Ele levou os segredos junto, como o modo dev prometia:

@@FENCE 4@@
