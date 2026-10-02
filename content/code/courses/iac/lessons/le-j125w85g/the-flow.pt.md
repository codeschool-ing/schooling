---
title: O fluxo, do pull request ao plan aplicado
version: 1
---

Um pipeline de Terraform tem duas raias, e quase todo o projeto dele é decidir o que acontece em
cada uma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas raias. Num pull request: check (fmt e validate, sem credenciais), scan (sem credenciais), plan com um role só de leitura, e revisão, em que pessoas leem o diff e o plan; depois o merge. Na main, depois do merge: plan salvo num arquivo com o role de leitura, o arquivo guardado como artefato por três dias, uma aprovação em que uma pessoa lê o plan salvo, e o apply exatamente desse arquivo com o role que pode escrever.\"><defs><marker id=\"fl-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">num pull request</text><rect x=\"20\" y=\"50\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">check</text><text x=\"85.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fmt, validate</text><text x=\"85.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem credenciais</text><rect x=\"180\" y=\"50\" width=\"120\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">scan</text><text x=\"240.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um scanner</text><text x=\"240.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem credenciais</text><rect x=\"330\" y=\"50\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan</text><text x=\"395.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não salvo</text><text x=\"395.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">role de leitura</text><rect x=\"490\" y=\"50\" width=\"120\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">revisão</text><text x=\"550.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o diff</text><text x=\"550.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e o plan</text><rect x=\"640\" y=\"50\" width=\"70\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"675.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">merge</text><path d=\"M150 82.0 L178 82.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><path d=\"M300 82.0 L328 82.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><path d=\"M460 82.0 L488 82.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><path d=\"M610 82.0 L638 82.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><path d=\"M675 114 L675 150 L85 150 L85 188\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><rect x=\"20\" y=\"190\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan, salvo</text><text x=\"85.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">num arquivo</text><text x=\"85.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">role de leitura</text><rect x=\"190\" y=\"190\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">artefato</text><text x=\"255.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o arquivo, guardado</text><text x=\"255.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por três dias</text><rect x=\"360\" y=\"190\" width=\"140\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aprovação</text><text x=\"430.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma pessoa lê</text><text x=\"430.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o plan salvo</text><rect x=\"540\" y=\"190\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">apply</text><text x=\"620.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exatamente esse arquivo</text><text x=\"620.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">role que pode escrever</text><path d=\"M150 222.0 L188 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><path d=\"M320 222.0 L358 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><path d=\"M500 222.0 L538 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><text x=\"20.0\" y=\"280.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">na main, depois do merge</text></svg>", "caption": "O pipeline em duas raias. Um pull request ganha um plan que ninguém aplica; a main ganha um plan que é salvo, lido, aprovado e aplicado do jeito que está.", "same": ["check", "scan", "plan", "merge", "fmt, validate", "apply"]}
```

**Num pull request, nada é aplicado.** A mudança é conferida, varrida e planejada, e o plan é
publicado onde quem revisa lê o diff. **Na `main`, depois do merge, o plan é feito de novo, salvo
num arquivo, lido por uma pessoa, e esse arquivo é aplicado.** Os dois plans existem por motivos
diferentes, e essa diferença é o assunto das três últimas seções desta aula.

## Portões baratos primeiro, credenciais por último

Os passos vêm ordenados pelo que custam e pelo que exigem:

| passo | o que pega | o que exige |
| --- | --- | --- |
| `fmt -check`, `validate` | formatação, sintaxe, um tipo errado, uma referência a nada | nem nuvem, nem credenciais |
| um scanner | uma porta aberta, um bucket sem criptografia: aula 14 | nem nuvem, nem credenciais |
| `plan` | o que a mudança faz com o que existe | leitura na nuvem e no state |
| `apply` | nada: ele faz a coisa | escrita |

Uma falha cedo é uma falha em segundos, antes de qualquer credencial chegar ao job. Os dois
primeiros passos rodam com `terraform init -backend=false`, que instala os providers e nunca toca no
state; assim, um pull request que nem consegue se formatar nunca chega a um plan.

Aqui está o scan fazendo o seu trabalho. Um pull request abre SSH no grupo `web` para a internet
inteira, a mesma mudança que a aula 1 viu um colega fazer à mão. Desta vez ela chega como um
arquivo numa branch, e o pipeline roda sobre ela:

```
ana@laptop:~$ git clone -q -b ssh git/shop.git ci/pr-ssh
ana@laptop:~/ci/pr-ssh$ ./ci.sh check 2>&1 | tail -n 2
Success! The configuration is valid.

ana@laptop:~/ci/pr-ssh$ ./ci.sh scan; echo "exit $?"
+ export TF_IN_AUTOMATION=1
+ trivy config --quiet --skip-check-update --severity HIGH,CRITICAL --exit-code 1 .
```

O `check` passou: o arquivo é HCL válido. O `scan`, não:

```
ssh.tf (terraform)
==================
Tests: 1 (SUCCESSES: 0, FAILURES: 1)
Failures: 1 (HIGH: 1, CRITICAL: 0)

AWS-0107 (HIGH): Security group rule allows unrestricted ingress from any IP address.
```

```
exit 1
```

**É o código de saída que para o pipeline.** O `--exit-code 1` faz o Trivy falhar quando encontra
qualquer coisa nas severidades listadas, e todo serviço de CI trata um passo que sai com código
diferente de zero como job com falha. O plan nunca rodou, ninguém recebeu credencial, e a conversa
sobre a porta 22 acontece no pull request, antes de qualquer coisa existir, e não uma semana depois
no console. Como ler o achado, e como suprimir um com justificativa, é a aula 14.

## Por que o plan do pull request não é o que se aplica

O plan de um pull request responde a uma pergunta: *o que esta mudança faria se fosse aplicada
agora?* É a melhor ajuda de revisão que existe, e fica desatualizado assim que qualquer outra coisa
entra na `main`. Dois pull requests aprovados na mesma manhã foram planejados, cada um, contra um
state que o outro está prestes a mudar.

Por isso o plan que se aplica é feito depois do merge, a partir da `main` como ela realmente está,
e salvo com `-out`. Uma pessoa lê esse antes de ele rodar. Se ele diz o mesmo que o plan do pull
request, a aprovação leva um minuto. **Se os dois discordam, a discordância é a notícia**: alguma
outra coisa mudou no meio do caminho, e alguém deveria saber o quê antes de apertar o botão.

Algumas ferramentas invertem isso e aplicam a partir do pull request, antes do merge; a última
seção desta aula dá o nome delas. A forma usada aqui é a que tanto o GitHub Actions quanto o GitLab
CI expressam só com recursos próprios, e as duas próximas seções a escrevem para cada um.
