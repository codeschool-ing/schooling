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

```yaml
# linkbox's tests on GitHub Actions, written the way a first version
# often is. Every line of it works.
name: ci
on:
  pull_request_target:
permissions: write-all
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          ref: ${{ github.event.pull_request.head.sha }}
      - uses: astral-sh/setup-uv@v9
      - name: Say which change this is
        run: echo "testing ${{ github.event.pull_request.title }}"
      - run: bash ci/test.sh
```

### Um scanner para workflows

O **zizmor** é um analisador estático para GitHub Actions: ele lê arquivos de workflow como o Bandit
leu o `app.py` na aula 3, e conhece os erros que se repetem neles. É uma ferramenta Python, instalada
como o Bandit, numa versão exata:

```
ana@vm:~$ uv tool install zizmor==1.31.1
Resolved 1 package in 754ms
Downloading zizmor (9.1MiB)
 Downloaded zizmor
Prepared 1 package in 688ms
Installed 1 package in 2ms
 + zizmor==1.31.1
Installed 1 executable: zizmor
ana@vm:~$ zizmor --version
zizmor 1.31.1
```

`--offline` impede que ele chame a API do GitHub, que algumas auditorias usam para conferir se um
commit fixado pertence mesmo à action que nomeia; as outras funcionam só com o arquivo. `--quiet` tira
as linhas de progresso. Salvo como `.github/workflows/ci.yml` e varrido:

```
ana@vm:~$ cd linkbox && mkdir -p .github/workflows
ana@vm:~/linkbox$ zizmor --quiet --offline .github; echo "exit status $?"
help[artipacked]: credential persistence through GitHub Actions artifacts
  --> .github/workflows/ci.yml:11:9
   |
11 |         - uses: actions/checkout@v6
   |  _________^
12 | |         with:
13 | |           ref: ${{ github.event.pull_request.head.sha }}
   | |________________________________________________________^ does not set persist-credentials: false
   |
   = note: audit confidence → Low
   = note: this finding has an auto-fix
   = help: audit documentation → https://docs.zizmor.sh/audits/#artipacked

error[dangerous-triggers]: use of fundamentally insecure workflow trigger
 --> .github/workflows/ci.yml:5:3
  |
5 |   pull_request_target:
  |   ^^^^^^^^^^^^^^^^^^^ pull_request_target is almost always used insecurely
  |
  = note: audit confidence → Medium
  = help: audit documentation → https://docs.zizmor.sh/audits/#dangerous-triggers

error[template-injection]: code injection via template expansion
  --> .github/workflows/ci.yml:16:32
   |
16 |         run: echo "testing ${{ github.event.pull_request.title }}"
   |         --- this run block     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ may expand into attacker-controllable code
   |
   = note: audit confidence → High
   = note: this finding has an auto-fix
   = help: audit documentation → https://docs.zizmor.sh/audits/#template-injection

error[unpinned-uses]: unpinned action reference
  --> .github/workflows/ci.yml:11:15
   |
11 |       - uses: actions/checkout@v6
   |               ^^^^^^^^^^^^^^^^^^^ action is not pinned to a hash (required by blanket policy)
   |
   = note: audit confidence → High
   = help: audit documentation → https://docs.zizmor.sh/audits/#unpinned-uses

error[unpinned-uses]: unpinned action reference
  --> .github/workflows/ci.yml:14:15
   |
14 |       - uses: astral-sh/setup-uv@v9
   |               ^^^^^^^^^^^^^^^^^^^^^ action is not pinned to a hash (required by blanket policy)
   |
   = note: audit confidence → High
   = help: audit documentation → https://docs.zizmor.sh/audits/#unpinned-uses

8 findings (3 suppressed, 2 unsafe fixes): 0 informational, 1 low, 0 medium, 4 high
exit status 14
```

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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"sp-l16-triggers\" aria-label=\"Dois gatilhos comparados para um pull request vindo de um fork. Com pull_request o workflow roda o código do fork com um token só de leitura e sem segredos. Com pull_request_target ele roda com um token que pode escrever e com os segredos do repositório; fazer checkout da head do pull request passa então a rodar o código do fork com esses privilégios.\"><defs></defs><rect x=\"200\" y=\"15\" width=\"240\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pull_request</text><rect x=\"460\" y=\"15\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pull_request_target</text><text x=\"20\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">código que roda</text><rect x=\"200\" y=\"65\" width=\"240\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o código do fork</text><rect x=\"460\" y=\"65\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o código do fork, se baixado</text><text x=\"20\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">token</text><rect x=\"200\" y=\"111\" width=\"240\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">só leitura</text><rect x=\"460\" y=\"111\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pode escrever</text><text x=\"20\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segredos</text><rect x=\"200\" y=\"157\" width=\"240\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">retidos</text><rect x=\"460\" y=\"157\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">disponíveis</text><text x=\"320\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">certo para rodar testes</text><text x=\"585\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">certo só para labels e comentários</text></svg>", "caption": "pull_request_target é para jobs que nunca rodam o código do pull request; baixar esse código é o que o transforma em código de um estranho com as chaves do repositório.", "same": ["token"]}
```

### O que a persona padrão deixou de fora

O resumo diz que três achados foram suprimidos. O zizmor tem **personas**: a padrão, `regular`,
reporta o que vale agir com poucos falsos positivos, e a `auditor` reporta tudo o que notou. O mesmo
arquivo sob `auditor`, só os achados:

```
ana@vm:~/linkbox$ zizmor --quiet --offline --persona auditor .github | grep -E "^(error|warning|help|info)\["
help[artipacked]: credential persistence through GitHub Actions artifacts
error[excessive-permissions]: overly broad permissions
error[dangerous-triggers]: use of fundamentally insecure workflow trigger
error[template-injection]: code injection via template expansion
error[unpinned-uses]: unpinned action reference
error[unpinned-uses]: unpinned action reference
info[anonymous-definition]: workflow or action definition without a name
help[concurrency-limits]: insufficient job-level concurrency limits
```

Os três a mais são `excessive-permissions`, que é o `write-all`, um `anonymous-definition`, um job sem
`name`, e `concurrency-limits`, nada impedindo duas execuções da mesma branch ao mesmo tempo. **O
`write-all` é o que importa**, e a persona regular não o reportou aqui. O padrão da ferramenta é
ajustado para ficar quieto, a mesma troca que a aula 7 fez para os gates do pipeline, então vale fazer
a primeira leitura de um workflow novo como auditor. O arquivo corrigido da próxima seção passa nas
duas.
