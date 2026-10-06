---
title: Um inventário dos pontos de entrada
version: 1
---

Um modelo de ameaças começa como uma lista. Para o assistente da Tarefa ela é o `data/surface.json`,
escrito pelo curso: uma entrada por lugar onde texto entra ou sai, com três fatos sobre cada uma.

```
ana@lab:~/guard$ head -15 data/surface.json
[
 {
  "id": "client-chat",
  "what": "a client's message in the chat",
  "enters": "prompt",
  "trusted": false,
  "controls": [
   "guard check-in",
   "guard moderate"
  ],
  "lessons": [
   19,
   16
  ]
 },
ana@lab:~/guard$ guard surface
entry point     goes to  trusted?           controls in the lab
client-chat     prompt   no                 guard check-in, guard moderate
helpdesk        prompt   written by Tarefa  guard ground
ticket-text     prompt   no                 guard minimise
uploaded-files  prompt   no                 NONE
system-prompt   prompt   written by Tarefa  canary in guard filter
model-reply     screen   no                 guard check-out, guard filter
tool-calls      tools    no                 guard gate
partner-api     prompt   no                 guard onboard, guard drift, guard ratelimit
call-log        storage  Tarefa's own       guard redact, guard sweep
provider        outside  by contract        guard minimise, guard enduser
10 entry points, 1 with no control in this lab
```

Leia as colunas como três perguntas:

- **goes to** é o que o texto alcança: o prompt, a tela, as ferramentas, o armazenamento, ou algo fora
  da Tarefa. Texto que vai às ferramentas é o mais perigoso, porque vira ação.
- **trusted?** é quem o escreveu. Só duas entradas são confiáveis de saída, o prompt de sistema e a
  central de ajuda, ambos escritos pela Tarefa. O log é da própria Tarefa e o fornecedor é confiável por
  contrato, o que a aula 12 disse ser uma confiança com condições.
- **controls in the lab** nomeia os comandos deste curso que cobrem a entrada. Cada um foi construído
  numa aula, e os números das aulas estão no arquivo.

A lista é curta porque o assistente da Tarefa é pequeno. Uma aplicação maior tem mais linhas, não mais
colunas: cada recurso novo acrescenta um ponto de entrada, e **um recurso não está pronto enquanto a
linha dele não for escrita**, com a confiança e o controle. Uma linha acrescentada depois de um incidente
é uma linha que alguém achou do jeito difícil.

## Duas linhas que valem uma leitura atenta

O `model-reply` está marcado como não confiável, embora a Tarefa rode o modelo. A saída do modelo é
moldada por toda entrada não confiável que chegou a ele, então herda o nível de confiança delas. É por
isso que a aula 9 confere toda resposta contra um schema e a aula 5 a filtra antes de um cliente vê-la.

As `tool-calls` são não confiáveis pelo mesmo motivo, e vão às ferramentas. Uma proposta é texto que o
modelo escreveu depois de ler coisas que ninguém na Tarefa escreveu, então ela é conferida como
qualquer outra entrada não confiável, pelo portão da aula 10, antes de virar efeito.
