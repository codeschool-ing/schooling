---
title: Um assistente no pull request
version: 2
---

A mesma revisão da aula 4 seção 02 pode rodar sem ninguém pedir: um robô que lê todo pull request e
posta os achados como comentários. Vários produtos fazem isso, e um time pode montar um com uma
chave de API e um job de CI. **Ele é útil exatamente do jeito que a primeira leitura de um colega
cuidadoso é útil, e perigoso do mesmo jeito que uma leitura não conferida seria.**

## O que ele faz bem

- **Lê todo pull request**, inclusive os pequenos que ninguém revisa com atenção e os que chegam
  tarde numa sexta.
- **É bom nos achados locais e mecânicos**: um erro de um no limite, um erro ignorado, um recurso
  nunca fechado, um teste que não afirma nada. O erro de um da aula 4 seção 03 é do tipo que um
  bom modelo acha, e o pequeno deste curso não achou.
- **Dá uma vantagem ao revisor humano**: uma lista de lugares para olhar, que se confere mais
  depressa do que se lê um diff do zero.

## O que manter fora das mãos dele

- **Nunca a decisão de fazer o merge.** A aprovação de um robô é uma afirmação, e a aula 4 seção 03
  mostrou três afirmações confiantes, nenhuma delas um bug, e o bug de verdade de fora. As checagens que liberam um merge são
  as que são verdadeiras ou falsas: os testes, o linter, o verificador de tipos. Os comentários do
  robô informam a pessoa que decide.
- **Não a própria triagem.** Um achado em que o robô está errado deve ser respondido no pull
  request, com o motivo, do mesmo jeito que a ana respondeu à terceira afirmação da revisão lendo a
  linha que ela citava.
  Ignorar comentários do robô em silêncio ensina um time a ignorar todos, inclusive os certos.
- **Não mais contexto do que precisa.** O job roda com o repositório e uma chave. Não deveria ter
  também as credenciais de deploy, e o código que ele manda vai ao provedor a cada pull request,
  então as questões de política da aula 3 seção 03 valem para ele exatamente como para um editor.

## Custos que vale saber antes de ligar

Todo pull request vira uma ou mais chamadas de modelo, e um diff grande com os arquivos em volta é
uma entrada grande. A conta da aula 2 se aplica: tokens de entrada por revisão, vezes pull requests
por dia, vezes o preço. **Dois ajustes o mantêm sensato.** Um limite de tamanho, acima do qual o robô
diz que a mudança é grande demais para uma revisão útil em vez de revisar uma versão cortada dela. E
um filtro que pula arquivos gerados, lock files e código de terceiros, que custam tokens e não têm
nada a revisar.

O juízo a que esta aula sempre volta vale aqui sem mudança. **Uma revisão é uma lista de
hipóteses**, e uma hipótese vale exatamente o teste que a confere.
