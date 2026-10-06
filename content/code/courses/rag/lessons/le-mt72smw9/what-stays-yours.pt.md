---
title: O que continua sendo seu
version: 1
---

Um framework vale o que poupa menos o que esconde, e esta aula mediu as duas coisas.

## O que ele poupa

**Conectores.** As duas bibliotecas trazem leitores para arquivos, páginas web e dezenas de serviços,
e clientes para dezenas de armazenamentos vetoriais e provedores atrás de uma interface só. Trocar o
pgvector por outro armazenamento, ou um provedor por outro, vira a troca do nome de uma classe em vez
de uma reescrita. Para uma equipe que ainda não decidiu o armazenamento ou o provedor, isso é real.

**Técnicas já escritas.** A janela de frases e o auto-merging levaram uma linha cada nesta aula e
levariam uma tarde cada para escrever e testar à mão. O mesmo vale para recuperação híbrida,
reordenadores e reescrita de consulta, que as duas bibliotecas têm como peças.

**Um vocabulário comum.** "Um recuperador com um pós-processador" quer dizer a mesma coisa para
qualquer pessoa que já usou o LlamaIndex, o que importa numa equipe em que gente entra e sai.

## O que ele esconde

Toda surpresa desta aula foi um padrão, e nenhuma se anunciou:

| peça | o padrão dela | o que o pipeline medido faz |
| --- | --- | --- |
| divisor do LangChain | 4.000 caracteres, front matter incluído | 60 palavras dentro dos títulos, front matter em colunas |
| cliente de embeddings do LangChain | números de tokens, textos longos divididos e com média | o texto, nunca maior do que o modelo lê |
| `PGVector` | um id aleatório por carga | um id feito do documento e do texto |
| notas do `PGVector` | uma distância, menor é melhor | uma similaridade, com piso de 0,5 |
| clientes do LlamaIndex | `OPENAI_API_BASE`, senão a OpenAI | o endereço que a equipe configurou |
| divisor do LlamaIndex | 1.024 tokens, 200 sobrepostos | 60 palavras |
| prompt do LlamaIndex | nunca fazer referência ao contexto | citar toda frase |
| os dois | nenhum filtro de status ou público | só atuais e públicos |

Cada linha é uma decisão que as aulas 4 a 8 tomaram com uma medição por trás. Um framework toma as
mesmas decisões sem medição nenhuma, porque nunca viu os documentos, e um pipeline montado com padrões
fica bonito numa demonstração e falha nas perguntas que ninguém testou.

Eles também **mudam entre versões**. Todo nome de classe desta aula é das versões fixadas no
laboratório; o `langchain-postgres` ainda está na 0.0.18, e uma versão abaixo de 1 não promete nada
sobre a próxima. Um padrão que muda numa atualização muda o comportamento do pipeline sem nada mudar
no código da equipe. Então fixe as versões, e rode o teste da aula 8 depois de toda atualização, além
de depois de toda mudança sua.

## Um jeito de usar um

- **Leia o que ele manda.** O prompt, o endereço, o formato da requisição de embeddings. O registro do
  labgen neste laboratório, e o registro de requisições do próprio provedor ou um proxy em produção,
  mostram a requisição como ela saiu, que é a única versão que importa.
- **Defina todo valor que as aulas 4 a 8 mediram**, explicitamente, mesmo quando ele é igual ao
  padrão, para que a próxima atualização não possa movê-lo sem o código dizer.
- **Mantenha o teste fora do framework.** As perguntas, os fatos e a regra do acerto ficam no
  `eval.jsonl` e em poucas linhas do `frameworks.py`, não em nenhuma das bibliotecas, então o próximo
  pipeline que alguém propuser é medido pelas mesmas regras que este.
- **Escreva as decisões você mesmo**: os ids, o filtro, o piso, a recusa, as citações. Nesta aula elas
  foram um dicionário, um limite e um `if`, e foram elas que fizeram o pipeline do framework responder
  do jeito que a aula 8 mediu.

A aula 11 faz o mesmo com mais dois, o Haystack e o RAGFlow, e eles respondem às mesmas perguntas de
outros jeitos. As perguntas ficam.
