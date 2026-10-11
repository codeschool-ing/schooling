---
title: O log ao longo do tempo
version: 1
---

Um registro explica uma decisão. **O log explica como o sistema chegou a ser como é.** Isso só
funciona se o log seguir três regras: os registros são numerados em sequência, um registro aceito
nunca é editado, e o log mora ao lado do código. Cada regra existe porque a alternativa óbvia
destrói alguma coisa.

## Substituído, nunca editado

A ideia errada é que um ADR é documentação e deve ser mantido atualizado. Quando a decisão muda,
alguém abre o arquivo e o reescreve para bater com o design novo. O arquivo volta a estar correto, e
o raciocínio que estava certo na época desaparece.

O ADR-0002 mostra por que isso importa. A Coreto o escreveu em fevereiro, anos depois do fato, para
registrar uma decisão com a qual já convivia: reservas de assento travam linhas no banco. O contexto
dele diz o que era verdade quando a trava foi escrita. A Coreto tinha um punhado de casas, as
aberturas de vendas eram pequenas, e uma trava de linha era o jeito mais simples de impedir que dois
compradores pegassem o mesmo assento. **Para aquela empresa, a decisão estava certa.** Reescrever o
ADR-0002 em abril para descrever reservas sem travas apagaria isso, e um engenheiro do futuro veria
só que alguém um dia construiu uma bobagem.

Então, quando o ADR-0006 tomou o lugar dele, o ADR-0002 mudou numa linha, o status, que agora diz
"Substituído pelo ADR-0006". O ADR-0006 abre com "Substitui o ADR-0002". Cada um aponta para o outro,
e quem chega em qualquer um consegue seguir a decisão para a frente ou para trás.

Um log só de acréscimos merece confiança porque ninguém consegue arrumá-lo. Um log cujas entradas são editadas
para bater com o presente é uma segunda cópia do código, e uma cópia pior.

## Números em sequência, nunca reaproveitados

Os registros são numerados na ordem em que são escritos: 0001, 0002, 0003. Um número nunca é dado a
um segundo registro, nem quando o primeiro é substituído ou fica obsoleto. **O número é a identidade
do registro**, aquilo que outros registros, pull requests e relatórios de incidente citam. Um título
pode ser melhorado; se os números mudassem, toda citação passaria, sem aviso, a apontar para a
decisão errada.

A ordem também carrega informação. Ler o log da Coreto do começo dá o ano como ele aconteceu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 354\" role=\"img\" aria-label=\"O log de ADRs da Coreto como uma lista de oito linhas em ordem de número, de janeiro a outubro. 0001 Registrar decisões de arquitetura, aceito. 0002 Reservas de assento travam linhas no banco, substituído pelo 0006. 0003 Sem deploys na reserva 24 horas antes de uma abertura, substituído pelo 0009. 0004 Reproduzir uma abertura antes de mudar a reserva, aceito. 0005 Contratar um serviço de busca hospedado, aceito. 0006 Reservar assentos sem travas de linha, aceito. 0007 e 0008, duas decisões fora desta história. 0009 Trocar o congelamento por um portão de teste, aceito. Setas à direita vão do 0006 de volta ao 0002 e do 0009 de volta ao 0003.\"><defs><marker id=\"adrlog-pt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"610\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"37\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0001</text><text x=\"100\" y=\"37\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">jan</text><text x=\"144\" y=\"37\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Registrar decisões de arquitetura</text><text x=\"618\" y=\"37\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">aceito</text><rect x=\"20\" y=\"54\" width=\"610\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"75\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0002</text><text x=\"100\" y=\"75\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">fev</text><text x=\"144\" y=\"75\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Reservas de assento travam linhas no banco</text><text x=\"618\" y=\"75\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">substituído pelo 0006</text><rect x=\"20\" y=\"92\" width=\"610\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"113\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0003</text><text x=\"100\" y=\"113\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">fev</text><text x=\"144\" y=\"113\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Sem deploys na reserva 24 h antes de abertura</text><text x=\"618\" y=\"113\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">substituído pelo 0009</text><rect x=\"20\" y=\"130\" width=\"610\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"151\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0004</text><text x=\"100\" y=\"151\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">mar</text><text x=\"144\" y=\"151\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Reproduzir uma abertura antes de mudar a reserva</text><text x=\"618\" y=\"151\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">aceito</text><rect x=\"20\" y=\"168\" width=\"610\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"189\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0005</text><text x=\"100\" y=\"189\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">abr</text><text x=\"144\" y=\"189\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Contratar um serviço de busca hospedado</text><text x=\"618\" y=\"189\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">aceito</text><rect x=\"20\" y=\"206\" width=\"610\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"227\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0006</text><text x=\"100\" y=\"227\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">abr</text><text x=\"144\" y=\"227\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Reservar assentos sem travas de linha</text><text x=\"618\" y=\"227\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">aceito</text><rect x=\"20\" y=\"244\" width=\"610\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"2 4\"></rect><text x=\"32\" y=\"265\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0007–8</text><text x=\"144\" y=\"265\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">duas decisões fora desta história</text><rect x=\"20\" y=\"282\" width=\"610\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"303\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0009</text><text x=\"100\" y=\"303\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">out</text><text x=\"144\" y=\"303\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Trocar o congelamento por um portão de teste</text><text x=\"618\" y=\"303\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">aceito</text><path d=\"M632 222.0 C672 222.0, 672 70.0, 636 70.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#adrlog-pt-ah)\"></path><path d=\"M632 298.0 C706 298.0, 706 108.0, 636 108.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#adrlog-pt-ah)\"></path><path d=\"M24 336 L60 336\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#adrlog-pt-ah)\"></path><text x=\"70\" y=\"340\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">substitui: o registro mais novo aponta para o que ele trocou</text></svg>", "caption": "O log da Coreto de janeiro a outubro. Os registros substituídos ficam no lugar, esmaecidos, com o raciocínio intacto; as setas vão de cada decisão nova de volta à que ela trocou."}
```

O ADR-0003 é o congelamento de deploys da quarta ação da aula 1: nenhum deploy no módulo de reservas
nas 24 horas antes de uma grande abertura de vendas. Era a regra certa enquanto ninguém conseguia
medir uma mudança no caminho de reserva. O ADR-0004 construiu essa medida, e em outubro o teste de
carga já tinha rodado contra mudanças suficientes para o time confiar mais nele que no calendário. O
ADR-0009 trocou o congelamento por um portão: uma mudança no caminho de reserva só entra com uma
execução do teste de carga aprovada, seja qual for a data. A aula 1 disse que o teste de carga
tornaria o congelamento menos necessário com o tempo, e o log mostra quando isso aconteceu e por quê.

## Ao lado do código

A Coreto guarda seu log em `docs/adr/` dentro do `coreto-core`, um arquivo Markdown por registro,
com o nome formado pelo número e pelo título: `0006-hold-seats-without-row-locks.md`. Esse lugar
compra três coisas.

**Um registro é revisado junto com a mudança que ele explica.** O pull request que começou a
passagem para reservas sem travas trazia o ADR-0006, e os revisores discutiram o contexto antes de o
código entrar. Uma objeção levantada ali custa um comentário. A mesma objeção levantada depois de um
trimestre de trabalho custa o trimestre.

**Um registro é encontrado onde é preciso.** Um engenheiro lendo o código de reserva pode buscar "hold"
no repositório e cair no ADR-0006, sem login de wiki e sem adivinhar em que espaço ele foi arquivado.

E um registro anda junto com o código. Quando o módulo de reservas sair do monólito um dia, os
registros dele vão junto, no mesmo commit.

Uma decisão que abrange vários sistemas precisa de uma casa só, e a escolha importa menos que
tomá-la uma vez. O ADR-0001 da Coreto diz que uma decisão pertence ao repositório do sistema que ela
mais muda, e uma decisão sobre a plataforma inteira vai no `coreto-core`.

## Registros escritos tarde

O ADR-0002 foi escrito sobre uma decisão tomada muito antes de alguém manter registros. Vale a pena
fazer isso para uma classe de decisão em especial: **as que você está prestes a mudar.** Um registro
que substitui precisa de algo para apontar, e o contexto honesto da decisão antiga é o melhor
argumento de que a mudança não é só um time novo implicando com código velho. Escreva-o deixando
claro que é uma reconstrução, e diga a partir de quem ela foi feita.

Escrever registros tardios para toda decisão antiga não compensa. Comece o log no dia em que ler
isto, preencha para trás só o que você está prestes a mexer, e deixe o resto sem escrever até alguém
perguntar.

## Como um log morre

Um log falha de jeitos previsíveis, e todos aparecem na listagem dos arquivos.

- Ele para num número: o engenheiro que se importava mudou de time, e ninguém mais foi chamado a
  escrever registros.
- Seus registros são escritos depois que o código entrou, como papelada, e por isso os contextos
  defendem o que já estava construído.
- Seus registros crescem até virar RFCs, de várias páginas cada, e escrever um vira um projeto que
  ninguém começa.

A Coreto mantém o custo baixo de propósito. Um modelo fica em `docs/adr/`, e o checklist de pull
request do módulo de reservas pergunta se a mudança precisa de registro. Quando o Davi apresentar a
estratégia na aula 20, o log é a trilha por trás dela: o que foi decidido sob a política
orientadora, quando, e quanto cada decisão custou.
