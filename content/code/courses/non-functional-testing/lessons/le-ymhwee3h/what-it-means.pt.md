---
title: O que "não funcional" quer dizer
version: 1
---

Um requisito funcional diz **o que** o sistema faz: o cliente escolhe um assento e o assento fica
reservado. Um requisito não funcional diz **quão bem** ele faz isso, e em que condições: a reserva
responde em meio segundo quando duzentas pessoas estão reservando ao mesmo tempo, uma pessoa que não
enxerga a tela consegue concluí-la com um leitor de tela, e ninguém consegue reservar um assento em
nome de outro cliente. O primeiro tipo é uma lista de comportamentos. O segundo é uma lista de
propriedades, e uma propriedade vale ou falha em todos os comportamentos de uma vez.

O nome engana, e vale corrigir isso antes de qualquer outra coisa. "Não funcional" soa como
"opcional", ou como a parte do trabalho que não tem nada a ver com aquilo para que o sistema serve.
**Uma página de reserva que leva quarenta segundos sob carga é uma página de reserva que não
funciona**, para quem desiste antes da resposta. As propriedades fazem parte do que foi prometido
tanto quanto os comportamentos; só são mais difíceis de ver numa demonstração, porque uma
demonstração tem um usuário só, numa conexão rápida, que enxerga a tela e torce pelo sistema.

## As propriedades que este curso testa

A ISO/IEC 25010, a norma de onde descende a maior parte dos modelos de qualidade, lista nove
características de um produto de software. A revisão de 2023 as chama de adequação funcional,
eficiência de desempenho, compatibilidade, capacidade de interação, confiabilidade, segurança,
manutenibilidade, flexibilidade e segurança operacional (*safety*). A primeira é o que os seus testes
funcionais já cobrem. Este curso fica com quatro das outras, as que perguntam primeiro a um testador
e que dá para medir de fora do código:

| | a pergunta | aulas |
|---|---|---|
| **desempenho** | responde a tempo, na carga que vai enfrentar? | 1 a 11 |
| **acessibilidade** | todo mundo consegue usar, inclusive com teclado e leitor de tela? | 12 a 15 |
| **segurança** | recusa o que deve recusar, para alguém tentando de propósito? | 16 a 21 |
| **operabilidade** | quando ele se comporta mal em produção, alguém fica sabendo primeiro? | 22 a 24 |

A acessibilidade faz parte do que a norma chama de capacidade de interação, e a operabilidade toma
emprestado da confiabilidade e da manutenibilidade. Os rótulos importam menos que a forma: quatro
assuntos, cada um com as suas ferramentas e o seu jeito de dizer *passou*.

**Esse último ponto é o que vale guardar ao longo do curso inteiro.** Um teste funcional já vem com
o critério embutido: o assento ficou reservado ou não ficou. Um teste de carga responde com uma
distribuição de tempos, e *passou* depende de um limite que alguém teve de escrever. Uma auditoria de
acessibilidade responde com uma lista de achados, e uma ferramenta só consegue decidir parte deles.
Uma varredura de segurança responde com um relatório em que a maior parte das linhas não é problema
real no seu sistema. Em cada terço, a parte difícil não é rodar a ferramenta; é saber, antes de
rodar, que resultado significaria *reprovou*.

## Por que essas propriedades são do testador

Quem desenvolve mede desempenho quando algo fica lento, e um time de segurança revisa as partes que
parecem perigosas. Nenhuma das duas coisas é um plano de teste. **O que o testador acrescenta é o
hábito de fazer a pergunta antes de a resposta ser necessária**: anotar a carga que a versão tem de
aguentar, testar o formulário com o teclado antes que um usuário escreva dizendo que não consegue,
procurar a chave no repositório antes que outra pessoa procure.

O curso parte do que o anterior deixou. O `web-automation` deu a você uma suíte que dirige um
navegador, e a aula 10 dele foi Playwright; as aulas 13 a 15 deste curso usam Playwright de novo,
para uma auditoria em vez de um roteiro de cliques. Nada aqui supõe que você lembre os detalhes, e
todo programa que uma aula roda aparece inteiro nessa aula.
