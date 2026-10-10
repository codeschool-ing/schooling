---
title: Documentação ao lado do código
version: 1
---

**Mantenha a documentação no mesmo repositório do código, em texto puro, alterada no mesmo pull request
do código que ela descreve e revisada pelas mesmas pessoas.** A ideia se chama docs as code,
documentação como código. Ela não faz ninguém escrever mais; põe a documentação onde uma mudança no
sistema já passa, de modo que mantê-la verdadeira vira parte da mudança, e não uma tarefa à parte que
ninguém agenda.

A casa usual da documentação de arquitetura é uma wiki, escolhida porque qualquer um pode editá-la. É
esse o problema. Qualquer um pode, então ninguém precisa, e nada no jeito como o código muda leva
alguém até ela.

## Por que a wiki se desatualiza

A página "Arquitetura de Payments" da Carreto foi editada pela última vez em março de 2023. Desde
então, o repositório de Payments fez merge de mais de 1.100 pull requests. **Nenhum deles tocou a
página, porque nenhum deles podia**: a página mora em outro lugar, sem revisão, sem ligação com o
código que descreve e sem jeito de um pull request mostrar que ela agora está errada.

A wiki não é mal escrita. O problema dela é estrutural, e tem quatro partes:

- **Uma mudança no código nunca passa por ela.** O desenvolvedor que muda como os repasses são
  repetidos não tem motivo para abrir a wiki nem momento no trabalho em que ela apareça.
- **Ninguém a revisa.** Uma frase errada no code review ganha um comentário; uma frase errada na wiki é
  lida.
- **O histórico dela não é o histórico do código.** Não há como ver a página como era quando a versão
  2.4 foi lançada, que é exatamente o que precisa quem investiga um incidente na versão 2.4.
- **Nada consegue conferi-la.** Um pipeline pode falhar um build por um teste quebrado; não consegue
  ver uma wiki.

## Docs as code na Carreto

A mudança que Renata pediu aos times foi pequena. Cada repositório ganha um diretório `docs/` ao lado
do código, com arquivos Markdown e diagramas escritos como texto:

```
payments/
  src/
  tests/
  docs/
    README.md
    architecture/
      workspace.dsl
      requirements.md
    adr/
      0001-record-architecture-decisions.md
      0002-pay-drivers-by-pix.md
    runbooks/
      payout-stuck.md
```

O que decorre desse único movimento é a maior parte do valor:

- **Um pull request que muda a arquitetura muda a documentação no mesmo diff.** Quem revisa vê os dois.
  "Isto muda como Payments fica sabendo que uma entrega foi comprovada; o diagrama de contêineres ainda
  mostra a seta antiga" é um comentário de revisão, e o pull request espera por ele como esperaria por
  um teste falhando.
- **O modelo de pull request pergunta.** O da Carreto tem uma linha para isso: "Esta mudança altera um
  diagrama, um runbook ou um requisito em `docs/`?" Custa um segundo quando a resposta é não.
- **O histórico vem de graça.** `git log docs/` mostra quando cada página mudou e em qual pull request,
  com o motivo na descrição. A documentação da versão 2.4 está na tag da versão 2.4.
- **O pipeline consegue conferi-la.** Links que apontam para lugar nenhum, um ADR sem status, um
  arquivo de diagrama que não renderiza mais: cada um pode falhar um build, e a aula 9 vai além,
  conferindo se as dependências que o código de fato tem são as que o desenho permite.

**Um documento precisa de dono tanto quanto o código**, e num repositório isso sai quase de graça: o
time dono do código é dono do `docs/` ao lado dele. O arquivo CODEOWNERS do GitHub, ou o equivalente em
outras plataformas, pode exigir a revisão desse time para qualquer mudança ali.

## Diagramas como texto

Um diagrama desenhado numa ferramenta de desenho é salvo como arquivo binário, ou como um XML que
nenhum revisor lê num diff. Quando ele muda, o pull request mostra que um arquivo mudou e nada sobre o
quê. **Um diagrama escrito como texto pode ser revisado como código**: a linha que acrescenta uma seta é
a linha no diff.

Há várias ferramentas para isso, e a aula 12 de `architecture-modeling` compara Mermaid, PlantUML e
Structurizr direito. Uma propriedade da última vale ver aqui, porque muda o que um diagrama é. Na
linguagem do Structurizr você descreve **um modelo** do sistema e depois pede visões dele. Esta é uma
versão reduzida do que o `workspace.dsl` acima poderia conter:

```
workspace "Carreto" {
    model {
        shipper = person "Shipper" "A company with loads to move"
        driver = person "Driver" "An independent truck driver"
        carreto = softwareSystem "Carreto" {
            shipperApp = container "Shipper web app"
            driverApp = container "Driver app" "" "Mobile"
            monolith = container "Monolith" "" "Django"
            tracking = container "Tracking service"
        }
        sefaz = softwareSystem "SEFAZ" "Authorises the CT-e"
        bank = softwareSystem "Bank partner" "Sends Pix payments"

        shipper -> shipperApp "Quotes and books loads"
        driver -> driverApp "Accepts loads, proves delivery"
        shipperApp -> monolith "Calls" "HTTPS"
        driverApp -> tracking "Sends positions" "HTTPS"
        monolith -> sefaz "Requests CT-e authorisation"
        monolith -> bank "Requests payouts"
    }
    views {
        systemContext carreto {
            include *
            autolayout lr
        }
        container carreto {
            include *
            autolayout lr
        }
    }
}
```

O bloco `model` diz o que existe e quem fala com quem, uma vez. O bloco `views` pede dois desenhos dele:
a visão de contexto, em que a Carreto é uma caixa só, e a visão de contêineres, que abre essa caixa.
**Como as duas visões saem do mesmo modelo, elas não conseguem discordar** sobre quais sistemas
externos existem. Com dois diagramas desenhados à mão, cada um é uma afirmação separada, e no dia em que
alguém acrescenta o banco parceiro a um e esquece o outro, os dois se contradizem sem ninguém perceber.

O preço é o layout. Um diagrama com layout automático é arrumado e raramente bonito, e para uma
apresentação à diretoria Renata ainda desenha um à mão. Mas desenha a partir do modelo, para que o
desenho no slide mostre o mesmo sistema que está no repositório.

## Onde docs as code não chega

Sílvio não abre repositórios, e não deveria precisar. **A fonte mora num lugar só e é publicada onde
estão os leitores**: o pipeline da Carreto renderiza o Markdown e os diagramas de cada diretório `docs/`
no site interno a cada merge, com um link de volta para o arquivo e a data da última mudança. Os
leitores de fora da engenharia leem a cópia publicada; ninguém a edita, porque ela é regenerada a
partir do repositório a cada vez.

Alguns documentos nem deveriam morar num repositório. Uma proposta escrita para obter uma decisão, ou
os slides de uma reunião, são escritos uma vez e lidos numa semana, e o trabalho deles acaba quando a
decisão é tomada. São registros de um momento, e não descrições do sistema, uma distinção de que a
próxima seção depende, e escrevê-los bem é o assunto da aula 2 de `architect-communication`.
