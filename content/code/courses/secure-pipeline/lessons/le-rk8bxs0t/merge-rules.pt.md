---
title: Agrupar, esperar e fazer merge sem uma pessoa
version: 1
---

Os dois bots podem ser instruídos a fazer merge dos próprios pull requests: o Renovate com
`automerge` numa regra de pacotes, e no GitHub qualquer pull request, os do Dependabot incluídos, com o
auto-merge do repositório, que faz o merge no instante em que as checagens obrigatórias passam.
**Auto-merge é a decisão de deixar o pipeline ser o revisor**, e a seção anterior é o motivo para
tomá-la com estreiteza. Ele vale o que vale o que o pipeline confere, e o pipeline confere o que os
estágios foram escritos para conferir, não o que uma pessoa lendo o diff perceberia.

### As três configurações que decidem o ruído

As configurações desta aula definem três coisas, e cada uma troca alguma coisa.

**Agrupar** põe várias atualizações num pull request. Uma revisão em vez de cinco, e uma execução do
pipeline em vez de cinco, a um preço: quando o grupo falha, alguém precisa achar qual das cinco
quebrou. Agrupar atualizações minor e patch e deixar as major de fora é o meio-termo comum, porque uma
versão major é a que tem licença para quebrar coisas, e merece um pull request cuja falha tenha uma
causa possível só.

**Uma agenda** decide quando as propostas chegam. Um time que vê oito pull requests pingando ao longo
da semana os revisa entre outros trabalhos, o que quer dizer lê-los pela metade; um time que os recebe
na segunda de manhã consegue dar a eles uma hora de propósito. As atualizações de segurança ignoram a
agenda nos dois bots, e devem.

**Uma espera**, o `cooldown` do Dependabot e o `minimumReleaseAge` do Renovate, decide quão velha uma
versão precisa ser antes de ser proposta. É a mesma ideia da data de `--exclude-newer` da aula 15,
aplicada toda semana em vez de uma vez: deixe outras pessoas instalarem uma versão primeiro, e deixe
as checagens do próprio registro e os relatos da comunidade pegarem uma versão ruim antes que o seu bot
chegue nela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"sp-l18-wait\" aria-label=\"Duas linhas do tempo ao longo de trinta dias. Uma atualização de versão: uma release no dia 0, uma espera de catorze dias em que o bot a segura, depois um pull request na primeira segunda-feira agendada depois do dia 14. Uma atualização de segurança: um aviso publicado no dia 20, e o pull request aberto no mesmo dia, sem espera e sem agenda.\"><defs><marker id=\"sp-l18-wait-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><line x1=\"190\" y1=\"170\" x2=\"670\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"190\" y1=\"166\" x2=\"190\" y2=\"174\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"190\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 0</text><line x1=\"302\" y1=\"166\" x2=\"302\" y2=\"174\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"302\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 7</text><line x1=\"414\" y1=\"166\" x2=\"414\" y2=\"174\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"414\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 14</text><line x1=\"526\" y1=\"166\" x2=\"526\" y2=\"174\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"526\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 21</text><line x1=\"638\" y1=\"166\" x2=\"638\" y2=\"174\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"638\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 28</text><text x=\"10\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">atualização de versão</text><rect x=\"190\" y=\"48\" width=\"224\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"302\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">espera: 14 dias</text><line x1=\"190\" y1=\"40\" x2=\"190\" y2=\"80\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"190\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">release</text><rect x=\"478\" y=\"46\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"578.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">pull request, na segunda seguinte</text><path d=\"M414 60 L476 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l18-wait-ah-phosphor)\"></path><text x=\"10\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">atualização de segurança</text><line x1=\"510\" y1=\"106\" x2=\"510\" y2=\"146\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"510\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">aviso</text><rect x=\"522\" y=\"112\" width=\"160\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">pull request no mesmo dia</text></svg>", "caption": "A espera e a agenda atrasam as atualizações de rotina de propósito. Um aviso pula as duas.", "same": ["release"]}
```

### O custo da espera, dito com clareza

Uma espera atrasa as versões boas também. Uma correção de bug que você está esperando chega duas
semanas depois, e o mesmo vale para a correção de uma vulnerabilidade que ainda não tem aviso, porque
uma correção costuma sair antes de o aviso ser publicado. Duas coisas mantêm esse custo limitado.
Publicado o aviso, uma atualização de segurança é proposta na hora nos dois bots, e a branch da seção
anterior mostrou que o pipeline quebra por ela não importa o que o bot faça. E uma pessoa sempre pode
atualizar à mão, que é o que a espera existe para tornar deliberado em vez de acidental.

### O que pode entrar sem ninguém olhando

A regra que sai do curso inteiro é curta: **auto-merge só para o que o pipeline consegue julgar por
completo**. Para o linkbox isso dá uma tabela.

| atualização | auto-merge? | por quê |
|---|---|---|
| um patch de um pacote só de teste (pytest, pluggy) | sim, depois da espera | ele roda só no estágio de testes; se os testes passam, fez o seu trabalho |
| um patch ou minor do Flask, Werkzeug ou gunicorn | não | os testes cobrem as rotas, não todo comportamento que a versão pode mudar |
| uma versão major de qualquer coisa | não | uma versão major tem licença para quebrar coisas que os testes não olham |
| um novo digest de imagem base | não | a varredura da imagem e a assinatura rodam, mas nada testa o comportamento dos novos pacotes do sistema operacional |
| um novo commit de uma action fixada | não | a action roda com as permissões do workflow, então o código dela é o que a aula 16 pediu que você revisasse |
| uma atualização de segurança com o portão quebrando sem ela | não, mas primeira da fila | a correção é urgente e ainda precisa da mesma leitura |

A tabela é um julgamento sobre o linkbox, e a de outro projeto vai ser diferente. Uma biblioteca com
uma suíte de testes que cobre por completo a interface pública poderia fazer auto-merge das
atualizações minor das dependências; um serviço de testes ralos não deveria fazer auto-merge de nada.
O teste é o mesmo que a primeira seção fez: para esse tipo de atualização, um pipeline verde quer dizer
que ela está certa?

Duas condições tornam qualquer auto-merge seguro o bastante para ser ligado. A branch precisa ser
protegida, para o merge esperar as checagens, todas elas, e uma checagem que não rodou conta como
falha, que é a regra de falhar fechado da aula 7 aplicada ao merge. E as permissões do próprio bot
precisam ser estreitas: um bot que consegue fazer push direto em `main` não precisa de auto-merge para
contornar o pipeline.
