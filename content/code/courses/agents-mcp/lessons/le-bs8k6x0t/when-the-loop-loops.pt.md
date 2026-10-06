---
title: Quando o laço não acaba
version: 1
---

O cliente pergunta se a Marginalia vende primeiras edições autografadas de *Dom Casmurro*. A central de ajuda não tem nada que responda, e o substituto, roteirizado para mostrar uma falha comum, busca de novo a mesma coisa. **Estas respostas foram escritas pelo curso**; os resultados da busca, a guarda e o rastro são reais.

```
ana@lab:~/agents$ python react_native.py "Do you sell signed first editions of Dom Casmurro?"
host: step 2 repeats search_help({"query": "signed copies"}); stopping
ana@lab:~/agents$ python show_trace.py
step 1  stop_reason=tool_use  input_tokens=176
  said:     The help centre should say whether signed copies are sold.
  called:   search_help({"query": "signed copies"})
  returned: [{"title": "Orders for schools and libraries", "body": "Institutions buy
step 2  stop_reason=tool_use  input_tokens=386
  said:     Those articles do not mention signed copies; I will search for signed copies.
  called:   search_help({"query": "signed copies"})
  returned: refused: repeat
```

O passo 1 buscou `signed copies` e recebeu três artigos sobre outros assuntos: pedidos de escolas, empréstimo de e-books, livros danificados. O pensamento do passo 2 diz isso, e então pede a mesma busca com as mesmas palavras. A guarda do `react_native.py` mantém um conjunto de chamadas já feitas, como nome da ferramenta e argumentos com chaves ordenadas; a segunda chamada já estava nele, então o hospedeiro parou a execução e escreveu por quê. **Sem a guarda, esta execução repetiria a busca até o limite de passos, pagando por um pedido maior a cada vez**: o rastro já mostra a entrada subindo de 176 para 386 tokens entre os dois passos.

## Por que modelos entram em laço

Um modelo escolhe o próximo passo a partir da conversa até ali. Se nada nela mudou, a mesma escolha é provável de novo: a busca não trouxe nada útil, então buscar continua sendo o movimento óbvio, e a consulta que parecia a melhor antes continua parecendo. Laços reais raramente são tão escancarados. Mais frequente é um modelo alternar entre duas consultas, ou ler o mesmo pedido com maiúsculas diferentes, o que uma guarda de igualdade exata deixa passar.

## O que um hospedeiro pode fazer

| falha | o que fazer no hospedeiro |
|---|---|
| a mesma chamada, mesmos argumentos | recusá-la, ou parar a execução (esta seção) |
| chamadas quase idênticas | normalizar os argumentos antes de comparar: aparar, passar para minúsculas, ordenar chaves |
| uma chamada a ferramenta que não existe | devolver um erro que nomeia as ferramentas que existem |
| nenhum progresso por vários passos | parar depois de N passos sem ferramenta nova ou resultado novo (aula 5) |
| responder antes de consultar qualquer coisa | exigir ao menos uma chamada em perguntas sobre pedidos, e conferir que a resposta cita um resultado |

Parar não é o mesmo que falhar com educação. Uma execução parada ainda deve uma resposta a alguém, e a útil aqui é honesta: *"a central de ajuda não diz; vou passar isto para uma pessoa."* A aula 5 é sobre o que um agente devolve quando um limite dispara, e é a outra metade de cada guarda desta tabela.
