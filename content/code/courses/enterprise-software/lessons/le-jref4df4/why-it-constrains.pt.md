---
title: Por que o ERP condiciona a arquitetura
version: 1
---

Um arquiteto vindo de uma empresa que constrói tudo espera que o ERP seja um sistema entre muitos:
importante, grande, mas uma caixa no diagrama como as outras. **Numa empresa que roda um, o ERP decide
boa parte de todo desenho à sua volta antes de o arquiteto desenhar qualquer coisa** — o modelo de
dados, o calendário, as interfaces, o ciclo de atualização e a licença. A atitude útil é a que você
teria diante de uma regulamentação: entender exatamente o que ela exige, e desenhar dentro dela.

## A primeira proposta da Joana

Na segunda semana na Serra Alta, a Joana olha o Portal B2B. As padarias fazem pedidos por ele, e cada
página mostra quantas caixas de cada produto há em estoque. O portal pega esses números de um arquivo
que o SAP escreve a cada hora, então às vezes uma padaria pede um iogurte que esgotou quarenta minutos
antes, e o atendimento liga de volta para pedir desculpas. Isso acontece cerca de 30 vezes por semana.

A proposta da Joana é a que ela faria na fintech. **O SAP roda sobre um banco; monte uma réplica
somente leitura dele, e deixe o portal consultar as tabelas de estoque direto**, ao vivo, sem arquivo
e sem uma hora de atraso. É barato, é rápido, e a réplica protege a produção da carga. Ela escreve a
proposta numa página e manda para o Edson Prado, que comanda o time de SAP.

A resposta do Edson tem quatro pontos. Cada um é uma restrição que o ERP impõe, e juntos são esta
seção.

## 1. O modelo de dados é do fornecedor, e ele se move

**As tabelas de estoque que a Joana consultaria são a estrutura privada do SAP, não uma interface.** A
SAP documenta como ler estoque pelos seus programas e serviços; não promete nada sobre as tabelas por
baixo. Quando a Serra Alta passar do ECC para o S/4HANA, o que precisa fazer antes do fim da manutenção
principal do ECC pela SAP, no fim de 2027, o jeito de guardar estoque muda. O S/4HANA registra os
movimentos de material numa tabela nova, `MATDOC`, e calcula na hora números que o ECC guardava em
tabelas de totais. Um portal construído contra as tabelas do ECC quebraria no dia da migração, ou,
pior, continuaria rodando e mostrando números que ninguém mais atualizava.

Esta é a forma geral: **um sistema que lê as tabelas de outro fez da estrutura interna desse outro
parte do próprio contrato**, sem o dono ter concordado com nada. Dentro do ERP esse acoplamento é
testado pelo fornecedor. Fora dele ninguém testa.

## 2. O significado está no código

Como a seção sobre o banco único mostrou, o número de que a padaria precisa não é o número da tabela.
"Em estoque", para uma venda, quer dizer *disponível para prometer*: o estoque físico, menos o que está
reservado para pedidos já feitos, menos o que a qualidade bloqueou à espera de um resultado de
laboratório, mais o que chega de outra fábrica antes da data prometida. O SAP calcula esse número com
a própria lógica, configurada ao longo de anos pelo time do Edson. **Uma consulta na réplica
devolveria o estoque físico**, e o portal continuaria vendendo iogurte que está na câmara fria mas
prometido a um supermercado. A proposta da Joana trocaria um número de quarenta minutos atrás por um
número atual e errado.

## 3. A licença segue os dados

**Licenças de ERP são vendidas por usuário, e os fornecedores discutem há muito tempo o que conta como
um.** Uma pessoa que lê dados do SAP por meio de outro sistema está, nos contratos da SAP, usando o SAP
mesmo assim. Isso se chama *acesso indireto*. Em 2017 a High Court de Londres decidiu o caso de
referência, *SAP v Diageo*: os sistemas de vendas e de clientes da Diageo, construídos sobre o
Salesforce, liam e escreviam dados no SAP dela, e o tribunal concordou com a SAP que as pessoas que
usavam esses sistemas precisavam de licenças SAP. A SAP passou depois a cobrar esse uso pelos
documentos criados em vez das pessoas, mas o princípio continua de pé. **Um desenho que põe 4.000
padarias diante de dados do SAP é uma questão de licença antes de ser uma questão técnica**, e a
resposta está no contrato, que um arquiteto precisa ler ou mandar ler.

## 4. O calendário do ERP é o calendário de todo mundo

O SAP da Serra Alta para de propósito. Todo domingo, da 01:00 às 05:00, ele sai do ar para manutenção.
Nos cinco primeiros dias úteis de cada mês o time de finanças fecha o mês anterior, e nessa semana o
time de SAP congela mudanças e acompanha de perto a carga do sistema. Uma réplica segue o primário,
então um portal lendo dela cairia nas madrugadas de domingo junto com o SAP. **As janelas do ERP viram
as janelas de tudo o que depende dele de forma síncrona**, e um portal para padarias que fazem pedido
às 04:00 de domingo antes de abrir precisa de uma resposta para isso. A aula 12 é sobre desenhar
para isso.

## O que o ERP faz com os seus desenhos, em geral

Os quatro pontos do Edson se generalizam numa lista que a Joana guarda dali em diante. Todo sistema
que toca o ERP precisa responder a cada linha:

| o ERP decide | o que quer dizer |
|---|---|
| o modelo de dados | os significados vêm dele; o seu sistema traduz de e para ele na borda |
| as interfaces | você entra pelas portas que ele publica, nunca pelas tabelas |
| o fluxo de documentos | você entra na cadeia no passo que representa, e deixa ele fazer o resto |
| o calendário | as janelas, o fechamento e os jobs em lote dele são restrições à sua disponibilidade |
| o ciclo de atualização | tudo o que você acrescenta a ele é carregado por toda atualização, por alguém |
| a licença | quem e o que pode ler os dados dele está num contrato, não só no código |

## Configurar, estender ao lado, modificar nunca

A quinta linha merece o seu próprio desenho, porque é a decisão que uma empresa toma mais vezes sem
perceber. **Há três jeitos de fazer um ERP fazer algo que ele não faz de fábrica**, e eles custam muito
diferente ao longo da vida do ERP:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-three-rings\" aria-label=\"O ERP desenhado como uma caixa com um núcleo dentro. O núcleo são os programas e as tabelas do fornecedor. Uma pequena mancha âmbar dentro do núcleo é uma modificação: o seu código dentro do deles, quebrado a cada atualização. A faixa em volta do núcleo é a configuração: escolhas que o fornecedor construiu, levadas adiante pelo fornecedor nas atualizações. Fora da caixa, ligada à borda por uma interface publicada, fica uma extensão ao lado do ERP: sua para manter, e não quebrada pela versão nova do fornecedor.\"><defs><marker id=\"l01-three-rings-es-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"430.0\" height=\"250.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"235.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">configuração: escolhas que o fornecedor construiu</text><text x=\"235.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">levada adiante pelo fornecedor nas atualizações</text><rect x=\"70.0\" y=\"88.0\" width=\"330.0\" height=\"170.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">os programas e tabelas do fornecedor</text><rect x=\"140.0\" y=\"150.0\" width=\"190.0\" height=\"74.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"235.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">modificação</text><text x=\"235.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">seu código dentro do deles</text><text x=\"235.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">quebrado a cada atualização</text><rect x=\"500.0\" y=\"110.0\" width=\"200.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">extensão ao lado</text><text x=\"600.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sua para manter</text><text x=\"600.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">não quebra com a versão deles</text><path d=\"M498.0 155.0 L452.0 155.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-three-rings-es-ah-paper)\" marker-start=\"url(#l01-three-rings-es-ah-paper)\"></path><text x=\"468.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma interface publicada</text><path d=\"M475.0 222.0 L475.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path></svg>", "caption": "Três lugares para pôr uma mudança, do mais barato ao mais caro ao longo da vida do ERP: configuração, uma extensão ao lado, e uma modificação dentro dele."}
```

A **configuração** escolhe entre comportamentos que o fornecedor construiu, e o fornecedor a carrega
pelas atualizações. **Uma extensão ao lado do ERP** — um programa separado que conversa com ele pelas
interfaces publicadas — é sua para manter, mas não quebra com a próxima versão do fornecedor. **Uma
modificação dentro do ERP**, mudando ou acrescentando código nos programas do fornecedor, quebra a cada
atualização e precisa ser encontrada, testada e levada adiante toda vez. O nome que a SAP dá a manter
o interior livre de modificações é *clean core*, núcleo limpo. Os 1.800 objetos próprios da Serra Alta
são o que quinze anos sem mantê-lo limpo parecem, e a aula 2 mostra o que eles custam na mudança para
o S/4HANA.

Uma quarta opção fica fora dos anéis e é a mais barata de todas: **mudar o processo do negócio para
caber no padrão.** Os fornecedores chamam de *fit to standard*. É a resposta certa mais vezes do que
um time que gosta de construir gostaria, e a errada sempre que o processo é como a empresa compete. A
aula 15 é sobre separar os dois casos.

## O que a Joana escreveu no lugar

A segunda versão da Joana manteve o portal fora do SAP e entrou por uma porta publicada. O SAP já
calcula o disponível para prometer; o time de SAP expõe esse cálculo como um serviço que o portal
chama quando a padaria abre o carrinho, com um cache curto na frente para que 4.000 padarias não virem
4.000 chamadas. A questão da licença foi para o time de contratos com uma contagem de documentos por
mês. E para a madrugada de domingo, o portal mostra o último número que tinha, com a hora em que foi
obtido, e aceita o pedido para confirmar quando o SAP voltar.

Ela registrou os motivos num registro de decisão, na pasta que este curso pediu para você manter. **A
primeira linha do registro nomeia a restrição, não a tecnologia**: *o SAP é o sistema de registro do
estoque; o portal não lê as tabelas dele.* O resto do curso é, num sentido, a versão longa dessa frase:
as aulas 2 a 6 são os sistemas que a Serra Alta comprou, e as aulas 7 a 15 são como ligá-los, mudá-los
e substituí-los sem parar uma empresa que coleta leite todo dia.
