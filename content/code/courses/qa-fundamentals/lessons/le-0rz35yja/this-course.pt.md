---
title: Um curso de decisões, e o cinema em que elas são tomadas
version: 1
---

**Este curso é sobre decidir o que vale a pena verificar, e quando.** Os cursos depois dele na trilha
`qa` ensinam as técnicas: como escrever um caso de teste, como automatizar um navegador, como carregar um
servidor até ele vergar. Todos eles supõem um vocabulário e um jeito de pensar que vêm antes: o que é
qualidade, de onde vêm os defeitos, por que um achado em março custa menos que o mesmo achado em junho, e
como quem testa se encaixa num time que entrega a cada duas semanas. É isso que se aprende aqui.

## As vinte e duas aulas

| aulas | a pergunta que respondem |
|---|---|
| 1 e 2 | O que é garantia de qualidade, e qualidade é uma propriedade do produto ou do jeito como ele foi feito? |
| 3 | Por que um defeito achado cedo é mais barato, e quanto, honestamente? |
| 4 e 5 | Como pensa quem testa, e para que serve essa pessoa num time? |
| 6 a 8 | Testar de fora, pelo código, ou de algum ponto no meio? |
| 9 a 14 | Onde o teste fica no cascata, no modelo V, na espiral, no ágil, no Scrum, no Kanban, no XP e no SAFe? |
| 15 a 17 | O que muda quando o teste é escrito antes do código: TDD, BDD e ATDD? |
| 18 | Quando um defeito escapa, como descobrir por quê, e não quem? |
| 19 | Como saber que um resultado está certo, quando ninguém escreveu a resposta certa? |
| 20 e 21 | Com pouco tempo, por onde começar, e quando já se testou o bastante? |
| 22 | Quais números ajudam um time, e quais viram teatro? |

As aulas 1 a 8 são sobre quem testa: o pensamento, o papel, os ângulos dos quais um sistema pode ser
examinado. As aulas 9 a 17 são sobre o processo em volta, dos modelos de ciclo de vida mais antigos às
práticas em que o teste vem primeiro. As aulas 18 a 22 são sobre julgamento sob pressão, que é a maior
parte do trabalho.

**Duas delas argumentam mais do que ensinam.** A aula 5 é sobre quem testa e acredita que seu trabalho é
barrar entregas, e por que essa crença piora o software. A aula 22 é sobre os números que um time
apresenta sobre qualidade, e como a maioria deles deixa de significar qualquer coisa no momento em que
alguém passa a ser julgado por eles. Leia essas duas como posições das quais você é livre para
discordar; o resto do curso fica mais fácil de aplicar se você as adotar.

## O Cine Aurora

Todo exemplo acontece num lugar só, para que os exemplos se somem. O **Cine Aurora** é um cinema de três
salas em Belo Horizonte, com bilheteria online. Ele não existe. Quatro pessoas aparecem, e o curso nunca
precisa de mais:

- **Lia** acabou de entrar como a primeira pessoa de teste do cinema. É ela quem digita, e o nome em toda
  transcrição;
- **Rafael** é um dos dois desenvolvedores, e escreveu a maior parte da bilheteria;
- **Joana** é a dona do produto: decide o que a bilheteria faz e escreve as regras;
- **Célia** comanda a bilheteria física, vende ingresso há vinte anos e conhece toda regra que o software
  está tentando seguir.

O sistema sob teste é pequeno de propósito: uma regra de preço de umas quarenta linhas que esta aula
imprime, e as peças que as aulas seguintes montam em volta dela. Um sistema pequeno permite que todo
defeito do curso seja um que você mesmo consegue achar, e que toda afirmação sobre um deles seja
conferida na sua máquina.

## O que ele não ensina

As bordas deste curso são o começo de outros, e uma aula que chega a uma delas diz isso e para:

- escrever casos de teste, e as técnicas para escolhê-los, como partição de equivalência e valor-limite,
  são de `manual-testing`, o próximo curso da trilha;
- relatar bem um defeito, e as ferramentas em que os times os acompanham, também são de `manual-testing`;
- automatizar um navegador é `web-automation`; teste de carga, de desempenho e de segurança são
  `non-functional-testing`;
- rodar testes num pipeline, e medir cobertura de código nele, são `testing-cicd`.

**O curso é curto em ferramentas e longo em julgamento.** A única ferramenta que ele instala está lá para
duas aulas. O que ele pede de você em todo o resto é olhar para um programa, um requisito ou um plano e
fazer a pergunta que acharia o problema antes de qualquer outra pessoa.
