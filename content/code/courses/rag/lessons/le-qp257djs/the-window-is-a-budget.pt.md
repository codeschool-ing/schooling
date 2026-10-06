---
title: A janela é um orçamento
version: 1
---

Todas as aulas até aqui foram sobre achar o texto certo. Esta e as quatro seguintes tratam de outra
pergunta: **de tudo o que poderia ir para a frente do modelo, o que deve ir?** É isso que passou a se
chamar engenharia de contexto. A janela de contexto é tudo o que o modelo lê numa chamada: as
instruções, as fontes, os turnos anteriores da conversa, a pergunta e o espaço que sobra para a
resposta. Ela tem um limite rígido, e bem antes do limite ela tem um preço.

Aqui está um prompt real, o que o pipeline da aula 7 manda para uma pergunta sobre cartão-presente,
contado parte por parte:

```
ana@lab:~/rag$ python window.py "How long is a gift card valid?"
   71  instructions
   19  header [1]
   39  text   [1] Gift card terms > Validity
   22  header [2]
   69  text   [2] Payments, invoices and gift cards > Gift cards
   22  header [3]
   59  text   [3] Payments, invoices and gift cards > Gift cards
   10  question
  311  sent, of a window of 8192
```

**311 tokens, de uma janela de 8.192.** Parece um problema que ainda não existe, e três coisas o
tornam um problema mesmo assim.

- **Todo token é pago**, em toda consulta, e a aula 17 multiplica isso por uma semana de tráfego. Um
  prompt com o dobro do tamanho é o dobro da conta da entrada.
- **Todo token é lido antes de a primeira palavra voltar.** O streaming da aula 9 escondia o tempo de
  escrever a resposta; nada esconde o tempo de ler o prompt, e ele cresce com o tamanho.
- **Todo token disputa a atenção do modelo.** Essa é a que este laboratório não consegue medir, já que
  o extract-1 não é um modelo, e a seção depois da próxima cita a pesquisa que mediu.

E os 311 são o menor tamanho que ele vai ter. A aula 13 acrescenta a conversa até ali, um assistente
de atendimento pode acrescentar os dados da conta do cliente, um agente em `agents-mcp` acrescenta as
descrições das suas ferramentas, e cada um chega com um motivo para estar ali. **Uma janela nunca é
preenchida por uma decisão; é preenchida por muitas decisões razoáveis**, e a soma não é escolha de
ninguém, a menos que alguém a torne uma.

A anatomia acima também é a pauta desta aula. As instruções, 71 tokens, são fixas. A pergunta é do
cliente. Todo o resto é decisão: quantas fontes (as duas próximas seções), quais (duplicatas), quanto
de cada uma (compressão), em que ordem (posicionamento) e com o que em volta (cabeçalhos). A última
seção junta as decisões numa função, `pack`, e a mede contra o prompt da aula 7.
