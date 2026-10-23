---
title: Um workflow do jeito que costuma ser escrito
version: 1
---

Suponha que o linkbox ganhe um espelho no GitHub, e alguém escreva um workflow para que todo pull
request rode os testes. A primeira versão tende a ficar como a de baixo, e cada linha está ali por um
motivo que pareceu bom na hora: `pull_request_target` porque os testes do pull request de um fork "não
receberiam os segredos de outro jeito", `write-all` porque um passo falhou uma vez por falta de
permissão, o commit da head do pull request porque "esse é o código a testar", e o título no log
porque é útil vê-lo. Nada nele é erro de digitação. **Este arquivo é mostrado para ser desmontado; não
o use.**

@@FENCE 1@@

### Um scanner para workflows

O **zizmor** é um analisador estático para GitHub Actions: ele lê arquivos de workflow como o Bandit
leu o `app.py` na aula 3, e conhece os erros que se repetem neles. É uma ferramenta Python, instalada
como o Bandit, numa versão exata:

@@FENCE 2@@

`--offline` impede que ele chame a API do GitHub, que algumas auditorias usam para conferir se um
commit fixado pertence mesmo à action que nomeia; as outras funcionam só com o arquivo. `--quiet` tira
as linhas de progresso. Salvo como `.github/workflows/ci.yml` e varrido:

@@FENCE 3@@

### Os achados, um a um

**`dangerous-triggers`.** `pull_request_target` roda o workflow no contexto do repositório base: com um
token que escreve e com acesso aos segredos do repositório, mesmo quando o pull request vem de um fork.
Ele existe para jobs que põem label ou comentam num pull request e nunca rodam o código dele.
**Combinado com um checkout da própria head do pull request**, que é o que o `ref:` pede aqui, ele roda
o código de um estranho, inclusive a versão dele do `ci/test.sh`, com os privilégios do repositório
base. O gatilho simples `pull_request` roda o código de um fork com um token só de leitura e sem
segredos, que é o que testar a mudança de outra pessoa exige.

**`template-injection`.** `${{ … }}` é expandido pela plataforma antes de o shell ver o script, então o
título do pull request vira parte do texto do script. Um título é qualquer coisa que o autor digitou.
**Texto escrito por alguém de fora do time precisa chegar a um shell como dado**, numa variável de
ambiente, onde o shell o trata como valor e nunca como código. O zizmor marca este com confiança alta e
oferece uma correção que faz exatamente isso.

**`unpinned-uses`, duas vezes.** `actions/checkout@v6` nomeia uma tag, e o incidente do tj-actions da
aula 12 é o que uma tag movida faz. Um hash completo de commit não pode ser movido.

**`artipacked`.** O `actions/checkout` grava o token do job no `.git/config` por padrão, então passos
seguintes, e qualquer coisa que envie o workspace, conseguem lê-lo. `persist-credentials: false` o
deixa de fora. A confiança é baixa, porque se isso importa depende do que os passos seguintes fazem.

@@FIGURE triggers@@

### O que a persona padrão deixou de fora

O resumo diz que três achados foram suprimidos. O zizmor tem **personas**: a padrão, `regular`,
reporta o que vale agir com poucos falsos positivos, e a `auditor` reporta tudo o que notou. O mesmo
arquivo sob `auditor`, só os achados:

@@FENCE 5@@

Os três a mais são `excessive-permissions`, que é o `write-all`, um `anonymous-definition`, um job sem
`name`, e `concurrency-limits`, nada impedindo duas execuções da mesma branch ao mesmo tempo. **O
`write-all` é o que importa**, e a persona regular não o reportou aqui. O padrão da ferramenta é
ajustado para ficar quieto, a mesma troca que a aula 7 fez para os gates do pipeline, então vale fazer
a primeira leitura de um workflow novo como auditor. O arquivo corrigido da próxima seção passa nas
duas.
