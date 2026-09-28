---
title: Os três estados de toda lista
version: 1
---

Os erros do servidor são metade da história. A página tem os seus próprios caminhos infelizes, e toda página
que mostra uma lista encontra os mesmos três, além da própria lista:

- **Vazio.** Ainda não há nada. Uma tabela só com o cabeçalho parece quebrada; uma frase que diz *nada ainda,
  e é assim que se acrescenta algo* parece terminada. No loanbook a frase precisa citar o comando, porque
  cadastrar equipamento é o substituto da aula 6.
- **Erro.** O servidor não respondeu. Sem tratamento, a página mostra uma tabela vazia, que parece
  exatamente o estado vazio, e diz a uma professora que não há equipamento quando a verdade é que o servidor
  está fora do ar.
- **Carregando.** A requisição ainda não voltou. Numa conexão lenta, é o estado que as pessoas veem por mais
  tempo.

A página do loanbook trata os dois primeiros:

```schooling-example
{"language": "javascript", "file": "static/app.js", "parts": [{"code": "async function load() {\n  const items = await send(\"GET\", \"/api/items\");\n  list.replaceChildren(...items.map(row));", "note": "O estado carregado: uma linha por item."}, {"code": "  document.getElementById(\"empty\").hidden = items.length > 0;\n}", "note": "O estado vazio. O parágrafo na página diz o que fazer; esta linha só decide se ele aparece."}, {"code": "load().catch(() => {\n  message.textContent = \"The server did not answer. Reload the page to try again.\";\n});", "note": "O estado de erro. Sem isto, um servidor fora do ar deixa uma tabela vazia, que parece exatamente o estado vazio e não é."}]}
```

Não trata o terceiro. A lista vem de um servidor pequeno com algumas dezenas de linhas, e na rede do
laboratório chega antes de a página terminar de desenhar. Num celular com sinal fraco poderia não chegar, e
uma linha *Carregando…* na tabela é a correção óbvia. Está no balde do *poderia*, e dizer isso é melhor do
que fingir que o estado não existe.

O teste dos três é o mesmo e leva um minuto: **abra a página com o banco vazio, com o servidor parado e com
a rede limitada** nas ferramentas de desenvolvimento do navegador. Quem avalia vai experimentar pelo menos o
primeiro.
