---
title: Um mapa, e a empresa sobre a qual ele é desenhado
version: 1
---

**Este curso é o mapa de uma profissão, desenhado antes de você percorrer qualquer parte dela.** Os
cursos que vêm depois dele na trilha `data` passam quarenta ou setenta horas cada um numa região — SQL,
o data warehouse, pipelines, a nuvem — e todos supõem um vocabulário: uma fonte, uma ingestão, uma
partição, um formato que guarda colunas, um fluxo com um evento atrasado dentro. É aqui que essas
palavras se aprendem, e que cada uma é vista acontecendo uma vez, em pequena escala, na sua própria
máquina.

## As dez aulas

| aula | a pergunta que ela responde |
|---|---|
| 1 | O que faz um engenheiro de dados, e em que isso difere de um cientista de dados? |
| 2 | Pelo que o trabalho responde, e como se escolhe uma tecnologia? |
| 3 | O que acontece com um dado entre o momento em que nasce e o momento em que alguém o lê? |
| 4 | De onde vem o dado, e quanto custa ler cada tipo de fonte? |
| 5 | Qual a diferença entre uma tabela, um documento JSON e uma fotografia, para quem os guarda? |
| 6 | Por que existem cinco formatos de arquivo, e qual escolher? |
| 7 | Antes de coletar qualquer coisa: quanto, com que frequência, com que qualidade e a que preço? |
| 8 | Você processa dados em lotes, ou à medida que chegam? |
| 9 | O que muda quando o dado deixa de caber numa máquina só? |
| 10 | O que um sistema consegue prometer quando a rede entre as suas máquinas cai? |

As aulas 1 e 2 tratam das pessoas e do trabalho. As aulas 3 a 7 seguem o dado de onde ele é feito até
onde é guardado. As aulas 8 a 10 tratam da maquinaria por baixo, que é onde o vocabulário é mais
difícil e onde uma imagem errada custa mais caro depois.

## Roda Livre

Todo exemplo do curso acontece numa só empresa, para que os exemplos se somem. A **Roda Livre** é um
serviço de bicicletas compartilhadas em Curitiba. Ela não existe. Tem doze estações, da Praça
Tiradentes à Ópera de Arame, noventa bicicletas e um aplicativo que destrava uma delas e cobra a
viagem.

Aparecem quatro pessoas, e o curso nunca precisa de mais:

- **ana** acaba de entrar como a segunda pessoa do time de dados. É ela quem digita, e o nome em toda
  transcrição;
- **Davi** é o engenheiro de dados sênior, que construiu o que existe até aqui;
- **Marta** dirige a operação e faz as perguntas que o dado precisa responder: onde estão as
  bicicletas, quais estações ficam vazias, quanto tempo uma doca quebrada espera conserto;
- **Caio** é o cientista de dados, que quer prever a demanda por estação e por hora.

Os dados são gerados por programas curtos que as aulas mostram por inteiro, a partir de sementes
fixas, então os números que você obtém são os números do texto. Nenhum arquivo deste curso é um
download.

## O que ele não ensina

Um mapa nomeia as regiões; não as percorre. Onde uma aula chega à borda deste curso, ela diz qual
curso assume dali, e para:

- escrever SQL é `sql-databases`, e modelar um data warehouse é `warehouse-modeling`;
- construir e agendar pipelines de verdade é `pipelines-etl`;
- medir e consertar a qualidade do dado a fundo é `data-cleaning`;
- a nuvem e os seus serviços de armazenamento são `cloud`, e contêineres são `docker`.

**O curso tem pouca ferramenta e muita decisão.** A única coisa que ele pede a você e que nenhum outro
pede é ver as mesmas poucas ideias — uma cópia, um atraso, uma falha, uma troca — voltarem em toda aula
com outro nome.
