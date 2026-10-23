---
title: O orçamento de ruído
version: 1
---

Toda proposta que um bot faz custa a uma pessoa um pouco de atenção: abrir o pull request, ler o que
mudou, olhar o pipeline, decidir. **Um time tem uma quantidade fixa dessa atenção, e um bot
configurado sem levá-la em conta gasta toda ela**, depois do que os pull requests entram sem ser lidos
ou se acumulam. Os dois desfechos são piores que nenhum bot: o primeiro aceita o que ninguém julgou, e
o segundo ensina a todos que os pull requests do bot são ruído, inclusive o que corrige um aviso. É a
fadiga de alertas da aula 7, chegando como pull requests em vez de builds quebrados.

Então, antes de ligar um bot, conte. A contagem que importa é quantas propostas uma configuração teria
feito ao longo de um ano real, e o índice de pacotes tem os dados.

### Contando um ano de versões

Este programa pergunta ao PyPI quando cada pacote fixado publicou cada versão, e conta as versões no
ano anterior a uma data. Depois conta o que três configurações teriam aberto: um pull request por
versão, um por semana que teve versão e um por mês. Salve-o como `~/releases.py`:

@@FENCE 1@@

Ele lê os nomes dos pacotes nos arquivos de requisitos, então conta as dependências do próprio
linkbox, diretas e transitivas juntas, porque um bot propõe atualizações para todo pin do lock. Rode-o
para o ano que termina na data em que o lock foi compilado:

@@FENCE 2@@

### Lendo a contagem

O linkbox tem 13 pacotes fixados e 3 dependências diretas, e a contagem é por ano:

- Um pull request por versão teria dado @@N_RELEASE@@ deles, quase um por semana, cada um chegando
  quando a versão chegasse.
- Agrupadas por semana, as mesmas versões cabem em @@N_WEEK@@ pull requests: esse foi o número de
  semanas do ano com pelo menos uma versão.
- Agrupadas por mês, @@N_MONTH@@: nenhum mês daquele ano passou sem uma versão.

A distribuição é desigual, o que é típico. Só o gunicorn lançou @@N_GUNICORN@@ versões; três pacotes
não lançaram nada. Um agrupamento por semana carrega, portanto, uma atualização do gunicorn numa boa
parte dos pull requests, o que é motivo para ler o changelog do gunicorn uma vez por mês, e não para
pulá-lo.

```schooling-figure
{}
```

Um serviço Flask pequeno é o caso fácil. A mesma conta para um serviço com duzentas dependências
transitivas, algumas imagens base e uma dúzia de actions multiplica o primeiro número por dez ou mais,
e é o agrupamento que torna um bot suportável ali. As outras contagens que este programa deixa de fora
apontam na mesma direção: as duas imagens base e as actions do linkbox somariam as atualizações delas
na mesma segunda-feira.

### Definindo o orçamento

Vire a conta ao contrário e pergunte o que o time consegue ler. Se uma pessoa pode dar aos pull
requests do bot uma hora na segunda, e uma revisão cuidadosa de uma atualização agrupada com pipeline
verde leva de dez a quinze minutos, o orçamento é de uns quatro pull requests por semana. A
configuração deve caber nisso, e a do linkbox cabe: um grupo Python, um grupo de actions, as imagens
base à parte e no máximo três abertos de cada vez, para que uma semana perdida não vire uma fila de
oito.

Três regras mantêm o orçamento honesto à medida que o projeto cresce:

1. Meça a produção do próprio bot: quantos pull requests dele foram aceitos, fechados ou deixados
   abertos por mais de uma semana, a cada mês. Um número crescente de abertos é o bot deixando de ser
   lido, e aparece muito antes de alguém admitir.
2. Corte o ruído, nunca as atualizações de segurança. Se o orçamento estourar, agrupe mais, alongue a
   agenda ou pare de propor atualizações minor de ferramentas de teste. As atualizações movidas por
   avisos continuam imediatas e sem grupo, porque são o motivo de o bot existir.
3. **Menos dependências é o orçamento mais barato.** O terceiro movimento da aula 15, substituir uma
   dependência, também remove todo pull request futuro sobre ela. Um pacote que lança uma dúzia de
   versões por ano e te dá uma função são uma dúzia de interrupções por ano por uma função.

A aula 20 transforma contagens como estas nas medidas que um time relata, e pergunta o que cada uma
esconde.
