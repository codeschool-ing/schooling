---
title: Onde as cópias moram, e em que cada lugar é de fato bom
version: 1
---

Três tipos de lugar, e eles não competem. A regra pede dois deles, e quais dois depende do que
você está disposto a fazer à mão.

| | em que é bom | em que é ruim |
|---|---|---|
| **um disco externo** | rápido, barato por gigabyte, inteiramente seu, funciona sem conexão | ele está no mesmo cômodo, e precisa de uma pessoa |
| **um serviço de sincronia** | automático, fora de casa, em todo aparelho, grátis em tamanhos pequenos | ele copia o estrago, e não foi feito para ser backup |
| **um serviço de backup** | automático, fora de casa, versionado, grande | custa por mês, e uma restauração inteira leva dias numa conexão doméstica |

**O arranjo mais barato que satisfaz a regra** é um disco externo que você conecta por semana mais
um serviço de backup rodando toda noite. O disco é a restauração rápida; o serviço é o que
sobrevive ao prédio.

## O disco externo, na prática

- **Compre um disco comum em vez de um SSD.** Para backup você quer capacidade por unidade de
  dinheiro, e a diferença de velocidade importa uma vez por semana por vinte minutos.
- **Dois discos, alternando**, é a versão disto que quem já perdeu algo usa. Um na gaveta, um na
  casa de um parente, trocados por mês. Isso é uma cópia completa fora de casa pelo preço de um
  segundo disco e nenhuma assinatura.
- **Criptografe.** Um disco de backup é uma cópia de tudo que você tem numa forma que alguém
  consegue levar embora. Windows e macOS criptografam um disco externo com uma caixa de seleção.
- **Escreva nele a data em que foi comprado.** Discos se gastam e ninguém lembra.

## A nuvem, honestamente

Um **serviço de sincronia** e um **serviço de backup** são produtos diferentes que os dois dizem
"nuvem", e a diferença é a que esta aula vem fazendo:

- Um serviço de sincronia mantém o estado atual em dois lugares. O histórico de versões dele é um
  resgate, não um projeto.
- Um serviço de backup guarda o histórico e é construído em torno de restaurar. Ele não põe os
  arquivos na sua área de trabalho e não é para trabalhar a partir dele.

Use os dois se quiser; não os conte como duas cópias de tipos diferentes, porque se a pasta de
sincronia é o que o serviço de backup está copiando, uma corrupção viaja pelos dois.

## Criptografia, e a única pergunta a fazer

Qualquer coisa que você mande para fora da sua máquina deve estar criptografada, e há dois tipos
de promessa:

- **Criptografado em trânsito e em repouso** — o serviço consegue ler os seus arquivos e promete
  não ler. Todo serviço de sincronia conhecido é assim.
- **Ponta a ponta**, ou *conhecimento zero* — o serviço guarda só texto cifrado e não consegue ler
  nada. O provedor não consegue te ajudar se você perder a chave, e essa é a troca.

**Para um backup, pegue ponta a ponta e escreva a chave no papel.** Para uma pasta de sincronia
em que você trabalha todo dia, a conveniência do outro tipo normalmente compensa — desde que você
saiba qual dos dois tem.

## Um aviso sobre "ilimitado"

Planos ilimitados têm limites de uso justo que não são publicados, e contas com muitos terabytes
recebem cartas. Se o dado importa, um plano com um número nele é um plano cujo limite você já
conhece.
