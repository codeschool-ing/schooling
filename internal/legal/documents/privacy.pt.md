---
title: Política de privacidade
effective: 2026-08-19
covers: accounts, account_credentials, sessions, visitors, account_visitors, events, section_progress, resume_pointer, notes, practice_state, practice_review, practice_drawn, exam_attempts, exam_answers, certificates, ledger_entries, subscriptions, subscription_events, staff, audit_log
---

Isto diz o que guardamos sobre você, por quê, e o que acontece quando você pede
para parar. Descreve o sistema como ele é de fato, e não a coisa mais ampla que
um dia poderíamos ter o direito de fazer — onde os dois divergirem, este
documento é o que nos obriga.

> **Ainda falta preencher antes de publicar.** O nome e o CNPJ da empresa por
> trás da plataforma, seu endereço, e o endereço para onde escrever sobre
> qualquer coisa abaixo. Até isso estar aqui, trate este texto como uma
> descrição do sistema e não como uma política publicada — uma política sem
> controlador identificado não é uma contra a qual você possa agir.

## A versão curta

- Guardamos seu e-mail, seu nome e o que você estudou.
- Não guardamos o número do seu cartão. Nunca o vemos.
- Damos a você um **identificador aleatório antes de você ter conta**, para
  sabermos quantas das pessoas que chegaram se cadastraram. Ele não tem nome
  nenhum dentro.
- Nada nestas páginas é carregado do servidor de terceiros, então ninguém de
  fora fica sabendo quais aulas você lê.
- Você pode pedir tudo o que temos, e pode pedir que apaguemos você. O que o
  apagamento faz, e a única coisa que ele não consegue remover, está descrito
  com precisão mais abaixo.

## Antes de você ter conta

Na primeira vez que um navegador chega até nós, gravamos um cookie com um
**identificador aleatório**. Não é seu nome, seu endereço nem nada derivado
deles — é um número que significa "este navegador" e mais nada.

Ele existe para responder a uma pergunta: das pessoas que chegaram, quantas se
cadastraram. Isso não dá para reconstruir depois, porque quando alguém se
cadastra a visita que o trouxe já acabou. Se você criar uma conta mais tarde,
registramos a ligação entre esse identificador e a conta, que é o que torna a
resposta possível.

O que registramos junto dele são as páginas que você pediu e o país de onde veio
o pedido. **Não armazenamos seu endereço IP.** O país é derivado do pedido e o
endereço em si é descartado.

## Depois que você tem conta

Guardamos:

- **Seu e-mail e o nome que você nos deu.** O e-mail é como você entra e como
  falamos com você sobre sua assinatura.
- **Sua senha, como hash.** Não a senha. Não conseguimos lê-la, nem dizer qual
  é, nem recuperá-la para você.
- **Suas sessões** — uma linha por navegador em que você está conectado, com um
  hash do token da sessão e a descrição que o navegador dá de si mesmo. Trocar a
  senha encerra todas as outras sessões.

## O que você faz aqui

Estudar produz um registro, e é esse registro que faz o produto funcionar — é
ele que devolve você ao ponto onde parou, agenda uma revisão e decide se você
foi aprovado.

- **Quais seções você terminou, e onde você estava.**
- **As anotações que você escreve na margem de uma aula.** Não as lemos e nada
  as analisa; é texto que você escreveu para si, guardado para estar lá amanhã.
- **Sua prática**: quais cartões você treinou, como cada um está agendado, e um
  registro de cada revisão — se acertou, quanto tempo levou e o agendamento que
  saiu dali. O registro é guardado para que um agendador melhor possa ser
  ajustado a respostas reais em vez de discutido.
- **Suas provas**: a prova como foi montada, as respostas que você deu e quanto
  cada uma valeu.
- **Seus certificados**, que trazem o nome que você nos deu, o curso e a data —
  porque um certificado que um estranho consegue verificar é o motivo de ele
  existir. Qualquer pessoa com o código de um certificado vê esses dados.

## Pagamentos

**Nunca vemos seu cartão.** Quem o recebe é o provedor de pagamento, e o que
chega até nós é uma referência a uma transação, um valor e se deu certo.

Guardamos o que você está pagando, o estado da sua assinatura, o histórico de
como ela chegou nesse estado, e o registro de cada pagamento, estorno e
chargeback.

## Contagem

Tudo o que a plataforma reporta é construído a partir de um fluxo de eventos:
algo aconteceu, quando, em qual escola, em qual país, em qual idioma e sob qual
plano. Cada um deles carrega apenas identificadores — o de visitante acima, ou o
da conta.

É assim que sabemos quais aulas são lidas, onde as pessoas param e quais
questões estão tão mal escritas que todo mundo erra. São sobre o material, não
sobre você.

## Quem opera a plataforma

Duas pessoas tocam isto. Registramos quem são e **cada ação administrativa que
tomam**: o que fizeram, sobre o quê, quando, e qual era o valor antes e depois.
Esse registro existe para que qualquer coisa feita na sua conta possa ser
atribuída, e é guardado por esse motivo — uma auditoria que a pessoa registrada
pudesse apagar não seria uma auditoria.

## O que não fazemos

- **Não carregamos nada de outra origem.** Nem fontes, nem analytics, nem
  widgets embutidos. Seu navegador conversa com este servidor e com mais ninguém,
  então nenhum terceiro fica sabendo qual matéria você estuda.
- **Não vendemos nada sobre você, nem compartilhamos para publicidade.**
- **Não rastreamos você por outros sites.**
- **Não fazemos nenhum perfilamento automático que decida algo a seu respeito.**
  Se você foi aprovado em uma prova, quem decidiu foram as respostas que deu.

## Cookies e o que o navegador guarda

Três coisas, e nenhuma delas é para publicidade:

- **O identificador de visitante**, descrito acima.
- **O cookie de sessão**, depois que você entra. Ele é `HttpOnly`, então nenhum
  JavaScript da página consegue lê-lo — inclusive o nosso.
- **Seu idioma e seu tema**, guardados no armazenamento do seu próprio
  navegador. Eles nunca chegam até nós.

## Qual lei, e para quem reclamar

Isto é regido pela **lei brasileira**, e especificamente pela Lei Geral de
Proteção de Dados (Lei 13.709/2018). Os direitos que ela dá a você são os
descritos aqui: saber o que temos, obter uma cópia, corrigir um erro, pedir o
apagamento, e saber com quem compartilhamos — que, como diz a seção acima, é
ninguém.

Se errarmos e você não ficar satisfeito com nossa resposta, você pode reclamar à
**ANPD**, a Autoridade Nacional de Proteção de Dados.

## Pedir uma cópia

Você pode pedir tudo o que temos sobre você e entregamos o conjunto inteiro,
como dados e não como resumo. Duas coisas ficam deliberadamente de fora, e
nenhuma delas é sobre você:

- **Os gabaritos** das questões que você já viu. Uma exportação é um arquivo que
  podem pedir para você entregar a outra pessoa, e não pode ser um jeito de
  obter as respostas de uma prova.
- **O texto das questões**, que é material que escrevemos.

## Apagamento, com precisão

Quando você pede para ser apagado, excluímos as linhas que fazem um
identificador significar uma pessoa: sua conta, suas credenciais, suas sessões,
os identificadores de visitante que são seus e a ligação entre eles. Tudo o que
sobra — os eventos, o registro de prática, o registro de pagamentos — **continua
existindo e não se liga mais a ninguém**. Não resta chave alguma que os conecte
a você, ao seu e-mail, ou uns aos outros através de você.

Estamos dizendo isso em vez de "apagamos tudo" porque é o que de fato acontece e
porque a alternativa seria pior para todo mundo: essas linhas são como sabemos
quais questões estão ruins, e excluí-las pioraria o material para quem continua
estudando sem tornar você mais privado do que já ser inidentificável torna.

Duas coisas não desaparecem:

- **O registro de que dinheiro mudou de mãos.** Somos obrigados a guardá-lo, e
  ele é a outra metade de um extrato bancário. Depois de um apagamento, ele tem
  um valor, uma data e um identificador que não significa ninguém.
- **O registro das ações administrativas**, pelo motivo dado acima.

Seus certificados **são** excluídos, e a página de verificação passa a responder
para os códigos deles exatamente como responde para um código que nunca
existiu — porque responder de outro jeito diria que um dia houve um, que é
justamente o fato sendo apagado.

## Por quanto tempo

Guardamos o que você estudou enquanto você tiver conta, porque isso é a conta.
Registros de pagamento são guardados pelo tempo que a legislação fiscal
brasileira exigir, e não mais.

## Mudanças neste documento

Toda versão desta política está em um repositório público com o histórico
completo, então o que ela dizia em qualquer dia pode ser estabelecido em vez de
lembrado. A data no topo é o dia em que a versão atual passou a valer.
