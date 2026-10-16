---
title: Formando quem desenha
version: 1
---

Uma arquiteta que desenha tudo bem construiu uma empresa que só consegue desenhar na velocidade de
uma pessoa. **A parte duradoura do trabalho é aumentar o número de pessoas na Carreto capazes de
tomar uma decisão estrutural sólida sem Renata na sala.** A crença comum é que isso acontece sozinho,
enquanto quem desenvolve vê bons designs passarem. Ver ensina a reconhecer. Desenhar ensina a
desenhar, e o único jeito de aprender é fazendo, com alguém conferindo o trabalho.

Três práticas carregam a maior parte disso na Carreto: deixar outras pessoas escreverem os registros
de decisão, desenhar em dupla e fazer katas. Uma quarta ideia amarra as três, que é entregar um tipo
de decisão em passos, e não de uma vez.

## Deixe outra pessoa escrever o ADR

A aula 5 apresentou o registro de decisão de arquitetura, com título, status, contexto, decisão e
consequências. Nos dois primeiros meses, Renata escreveu sozinha os nove novos da Carreto, porque
escrevia rápido e sabia como era um bom. Era a economia errada. **Escrever um ADR é onde quem
desenvolve aprende a declarar um contexto, nomear as opções que perderam e dizer quanto uma decisão
custa**, e Renata estava guardando essa prática para si.

A partir do terceiro mês, quem está mais perto de uma decisão escreve o registro, e Renata o revisa
como revisaria um design: primeiro o problema, depois as consequências, um rótulo em cada comentário.
Nos dez meses seguintes a Carreto aceitou mais 31 ADRs. Renata escreveu 5, e 14 engenheiros
diferentes escreveram os outros 26. Os primeiros rascunhos eram mais fracos do que os dela teriam
sido. Melhoraram depressa, e no fim do ano um rascunho do Matching precisava de menos comentários do
que os primeiros de Renata tinham precisado de Kátia.

Dois hábitos fizeram isso funcionar.

- **Ela resistiu a editar.** Um comentário que diz "as consequências só listam benefícios; quanto
  isto custa ao time do Driver?" ensina. Reescrever a seção não ensina, e diz ao autor que o nome dele
  no registro é decoração.
- **Ela deixou a decisão onde o processo de aconselhamento a põe** (aula 3), com o autor. Registrar a
  decisão de outra pessoa é trabalho burocrático. Registrar a própria é design.

## Desenhe em dupla

A programação em par tem um equivalente no design, e funciona pelo mesmo motivo: duas pessoas
pensando em voz alta pegam as suposições uma da outra enquanto ainda não há nada para jogar fora.
Renata desenha em dupla com uma pessoa de cada vez, por uma ou duas horas, num quadro branco ou num
diagrama compartilhado.

**Quem tem menos experiência segura a caneta.** Se Renata desenha, a outra pessoa a vê pensar e
aprende como são os diagramas dela. Se a outra pessoa desenha e Renata pergunta, é ela quem pensa, e
Renata vê exatamente onde o raciocínio para. Quando Diego Araújo, tech lead do app do Driver,
precisou desenhar o funcionamento offline para motoristas em áreas sem sinal, Renata passou duas
sessões com ele no quadro e não desenhou nada. Perguntou o que o app deveria fazer quando um
motorista confirma uma entrega sem sinal, o que acontece se a mesma confirmação chegar duas vezes
quando o sinal voltar, e como o Tracking saberia a hora real da entrega. O design de Diego guardava
uma fila de eventos no celular, cada um com a hora em que aconteceu e uma chave para que uma
repetição não mude nada. O design era dele, e ele o defendeu no fórum na semana seguinte.

Desenhar em dupla também dá à arquiteta uma coisa que nenhum documento dá: uma visão direta de como
cada pessoa raciocina, que é a base de qualquer plano para o crescimento dela.

## Entregue uma decisão em passos

Nenhuma das duas práticas é tudo ou nada. Renata entrega um tipo de decisão a alguém em quatro
passos, e diz o passo em voz alta para que as duas pessoas saibam onde estão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Uma escada de quatro degraus subindo da esquerda para a direita, com uma seta acima: a decisão passa para quem desenvolve. Passo um: eu decido e explico por quê. Passo dois: decidimos juntos. Passo três: você decide, eu reviso antes do fim. Passo quatro: você decide e me conta depois. Sob o passo dois: Kátia, para contratos com Payments. Sob o passo três: Ícaro, para desenhos de pagamento. Sob o passo quatro: Kátia, dentro do Matching.\"><defs><marker id=\"handover-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 30 L560 30\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#handover-ah)\"></path><text x=\"30\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a decisão passa para quem desenvolve</text><rect x=\"24\" y=\"196\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"104\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">passo 1</text><text x=\"104\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Eu decido</text><text x=\"104\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">e explico por quê</text><rect x=\"196\" y=\"150\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">passo 2</text><text x=\"276\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Decidimos</text><text x=\"276\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">juntos</text><text x=\"276\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Kátia: contratos com Payments</text><rect x=\"368\" y=\"104\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"448\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">passo 3</text><text x=\"448\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Você decide, eu</text><text x=\"448\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">reviso antes do fim</text><text x=\"448\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Ícaro: desenhos de pagamento</text><rect x=\"540\" y=\"58\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">passo 4</text><text x=\"620\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Você decide</text><text x=\"620\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">e me conta depois</text><text x=\"620\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Kátia: dentro do Matching</text></svg>", "caption": "Entregar um tipo de decisão em passos. O passo é do tipo de decisão, não da pessoa: Kátia está em dois degraus diferentes ao mesmo tempo."}
```

1. **Eu decido e explico por quê.** A outra pessoa acompanha o raciocínio.
2. **Decidimos juntos.** A outra pessoa traz opções e argumenta por elas; a decisão ainda é de
   Renata.
3. **Você decide, e eu reviso antes de ficar final.** O método da seção anterior, rótulos incluídos.
4. **Você decide e me conta depois.** Renata fica sabendo pelo ADR, como todo mundo.

**Os passos pertencem a um tipo de decisão, não a uma pessoa.** Kátia estava no passo 4 para o
design interno do Matching desde a primeira semana de Renata, e no passo 2 para qualquer coisa que
mudasse um contrato com Payments, porque um erro ali cai em outro time. Ícaro estava no passo 2 para
designs de pagamento até o documento das novas tentativas, que o levou ao passo 3. Dizer o passo em
voz alta evita as duas falhas silenciosas da delegação: a arquiteta que entrega uma decisão e depois
passa por cima dela, e a pessoa que recebeu uma e nunca percebeu.

## Katas: prática onde nada está em jogo

O problema de aprender design no trabalho real é que o trabalho real chega raramente e traz risco de
verdade. Uma pessoa pode desenhar duas coisas importantes por ano, cada uma com produção por trás.
Músicos e atletas resolvem o mesmo problema com treino que não é a apresentação. **Os katas de
arquitetura, criados por Ted Neward, são esse treino para o design.**

Um kata é um briefing curto de um sistema inventado: alguns parágrafos sobre os usuários e o negócio,
e um punhado de requisitos e restrições. Grupos pequenos recebem o mesmo briefing e um tempo fixo para
produzir uma arquitetura. Depois cada grupo apresenta, os outros questionam, e a discussão é sobre o
raciocínio: o que cada grupo escolheu, do que abriu mão e por quê. Não há resposta certa a encontrar,
e isso é de propósito.

A Carreto faz um por mês no fórum de arquitetura da aula 10, em noventa minutos: quinze para ler o
briefing e tirar dúvidas, quarenta e cinco para desenhar em grupos de três ou quatro, e trinta para
apresentar e questionar. Renata escreve os briefings e os situa em negócios que não são frete, para
que ninguém se apoie no que sabe dos sistemas da Carreto. Um descrevia uma biblioteca que empresta
ferramentas em vez de livros, com sócios, três unidades, lista de espera e multas. Outro descrevia a
cantina de uma escola que recebe pedidos pelo celular dos pais e precisa fechar às 10:30.

Duas regras fazem os katas valerem o tempo.

- **Misture os grupos.** Um desenvolvedor júnior de Payments, uma engenheira sênior de Platform e um
  tech lead do Driver discordam de jeitos que três pessoas do mesmo time nunca vão discordar.
- **Questione as trocas, não as caixas.** "Por que a lista de espera é um serviço separado?" é uma boa
  pergunta. "Eu teria usado Postgres" não é, a não ser que mude uma troca.

## Está funcionando?

**A medida é quantas decisões sólidas são tomadas sem a arquiteta**, e dá para acompanhar, por alto.
Renata mantém três colunas numa planilha: quem escreveu cada ADR, quantos comentários de revisão
foram bloqueantes e quantas perguntas de design chegaram a ela que um time poderia ter respondido
sozinho. Nos dez meses depois da mudança, cerca de cinco em cada seis ADRs foram escritos por outra
pessoa, e os comentários bloqueantes por revisão caíram de uns três para menos de um.

As conversas por trás desses números são um ofício à parte, e outro curso o ensina. Mentoria e
planos de desenvolvimento são a aula 10 de `architect-communication`, revisão de código como
ferramenta de ensino é a aula 11 dele, e programação em par e em grupo é a aula 12.
