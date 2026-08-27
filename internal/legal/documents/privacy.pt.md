---
title: Política de privacidade
effective: 2026-08-19
covers: accounts, account_credentials, account_recovery_codes, account_email_confirmations, account_email_changes, mail_suppressions, sessions, visitors, account_visitors, events, section_progress, resume_pointer, notes, content_reports, practice_state, practice_review, practice_drawn, exam_attempts, exam_answers, certificates, ledger_entries, subscriptions, subscription_events, staff, audit_log
---

Isto diz o que guardamos sobre você, por quê, e o que acontece quando você pede
para parar. Descreve o sistema como ele é de fato, e não a coisa mais ampla que
um dia poderíamos ter o direito de fazer — onde os dois divergirem, este
documento é o que nos obriga.

## Quem responde por isto

> **Ainda não preenchido.** Os quatro `{{…}}` abaixo são espaços reservados, e
> estão escritos assim para que ninguém confunda um deles com um nome. Até serem
> reais, este texto é uma descrição do sistema e não uma política publicada: uma
> política sem controlador identificado não é uma contra a qual você possa agir.

A empresa responsável pelo que está descrito aqui — o **controlador**, nas
palavras da lei — é:

- **{{company.name}}**, CNPJ {{company.registration}}
- {{company.address}}

Escreva para **{{company.contact}}** sobre qualquer coisa abaixo: para pedir uma
cópia do que temos, corrigir algo, ser apagado, ou reclamar.

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

O que registramos junto dele é **uma lista curta de coisas nomeadas que você
fez** — que você chegou, que abriu uma trilha, que abriu uma aula — e o país de
onde veio o pedido. Não todas as páginas que você olhou: não há registro da sua
navegação aqui, só dos poucos momentos de que o funil acima é feito.

**Não armazenamos seu endereço IP.** O país é derivado do pedido e o endereço em
si é descartado.

## Depois que você tem conta

Guardamos:

- **Seu e-mail e o nome que você nos deu.** O e-mail é como você entra e como
  falamos com você sobre sua assinatura.
- **Sua senha, como hash.** Não a senha. Não conseguimos lê-la, nem dizer qual
  é, nem recuperá-la para você.
- **Seus códigos de recuperação, como hashes**, e se cada um já foi usado. Eles
  existem apenas para contas com segundo fator. Guardamos só os hashes: os
  códigos aparecem uma única vez, quando são criados, e não conseguimos mostrá-los
  de novo.
- **Os links de confirmação que enviamos a você**, uma linha cada: o endereço
  para onde escrevemos, quando enviamos, quando o link deixa de valer e quando
  você o seguiu. O link em si é guardado apenas como hash, então não conseguimos
  reenviar um antigo — só criar um novo. Guardamos o endereço para onde o link
  foi enviado justamente para que um link não possa confirmar um endereço ao
  qual nunca foi enviado.
- **Os endereços para os quais você pediu para mudar**, uma linha cada: o
  endereço, quando você pediu, quando o link deixa de valer e se você o seguiu.
  Sua conta mantém o endereço atual até você seguir esse link — então um
  endereço digitado errado é uma mensagem que ninguém lê, e não uma conta que
  não conseguimos mais alcançar. Se você nunca seguir o link, a linha é tudo o
  que acontece.
- **Suas sessões** — uma linha por navegador em que você está conectado, com um
  hash do token da sessão e a descrição que o navegador dá de si mesmo. Trocar a
  senha encerra todas as outras sessões.

## Se a nossa mensagem for recusada

Quando uma mensagem que enviamos volta em definitivo — a caixa não existe, o
servidor que recebe nos recusa, ou você nos marca como spam — registramos que
não podemos escrever para aquele endereço de novo, e paramos.

**Registramos como um hash e nunca como o endereço.** A linha não pode ser
convertida de volta em endereço nem pesquisada por ninguém: tudo o que ela sabe
responder é *podemos escrever para este aqui*, no momento em que estamos prestes
a fazê-lo. Ela não diz nada sobre quem você é, e não há conta ligada a ela.

Esse é o único registro que sobrevive a uma exclusão, e guardar um hash é o que
torna isso possível: depois que você se vai, ele não guarda nada que era seu, e
ainda assim nos impede de escrever para uma caixa que mandou parar.

Uma mensagem que apenas não chegou hoje — caixa cheia, servidor com um dia ruim
— não é isso, e não entra na lista.

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
- **O que você aponta como errado no material**: qual seção era, qual das nossas
  cinco palavras você escolheu e o que você escreveu. Este nós *lemos* — é
  exatamente para isso que ele existe — e quem lê vê o que você escreveu, não
  quem você é.

  Ele vai embora junto com você. O que fica depois é o nosso próprio registro de
  que uma seção foi apontada e do que decidimos a respeito, sem nenhum traço de
  você: não dá para tocar um curso sobre um material que não temos permissão de
  lembrar que estava errado.

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
identificador significar uma pessoa: sua conta, suas credenciais, seus links de
confirmação, suas sessões,
os identificadores de visitante que são seus e a ligação entre eles. Tudo o que
sobra — os eventos, o registro de prática, o registro de pagamentos — **continua
existindo e não se liga mais a ninguém**. Não resta chave alguma que os conecte
a você, ao seu e-mail, ou uns aos outros através de você.

Estamos dizendo isso em vez de "apagamos tudo" porque é o que de fato acontece e
porque a alternativa seria pior para todo mundo: essas linhas são como sabemos
quais questões estão ruins, e excluí-las pioraria o material para quem continua
estudando sem tornar você mais privado do que já ser inidentificável torna.

Três coisas não desaparecem:

- **O registro de que dinheiro mudou de mãos.** Somos obrigados a guardá-lo, e
  ele é a outra metade de um extrato bancário. Depois de um apagamento, ele tem
  um valor, uma data e um identificador que não significa ninguém.
- **O registro das ações administrativas**, pelo motivo dado acima.
- **Que um endereço recusou a nossa mensagem**, como o hash descrito acima e
  nunca como o endereço. Se abandonássemos esse registro e você se cadastrasse
  de novo mais tarde com a mesma caixa, escreveríamos para uma caixa que já
  tinha mandado parar — que é exatamente o que você pediu que não fizéssemos.

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
