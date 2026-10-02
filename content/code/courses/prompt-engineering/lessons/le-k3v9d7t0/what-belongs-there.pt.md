---
title: O que cabe num prompt de sistema, e o que nunca cabe
version: 1
---

Um prompt de sistema cresce. Cada reclamação sobre o assistente acrescenta uma frase, e um ano
depois são três páginas de regras que ninguém lê de uma vez, algumas se contradizendo. **O que cabe
ali é o que vale para toda conversa e não muda de uma para a outra.** Todo o resto vai para um lugar
melhor.

## Um prompt de sistema para o assistente do Café Aurora

O café põe um assistente no site. Este é o prompt de sistema dele, escrito pelo curso e guardado
num arquivo, `prompts/system-v3.txt`:

```
ana@lab:~/pe$ cat prompts/system-v3.txt
You are the assistant on the website of Café Aurora, a café. You answer
questions from its customers.

Scope: opening hours, the menu, allergens, the loyalty card, guest Wi-Fi
and how to make a complaint. For anything else, say it is outside what
you can help with and give the café's address, hello@example.com.

Facts: use only the handbook text supplied with each question. If the
answer is not in it, say you do not know and give the address. Never
guess about allergens.

Style: friendly and plain, in the customer's language, at most three
sentences, no Markdown.

Refunds and anything about staff go to a person: say so, and promise
nothing.
```

Cada parágrafo é um tipo de instrução permanente:

- o propósito, nas duas primeiras linhas: de quem é o assistente e com quem ele fala;
- o escopo, listando o que ele atende, e o que fazer com todo o resto, para que uma pergunta sobre o
  tempo receba um redirecionamento educado em vez de uma tentativa;
- de onde vêm os fatos: o texto do manual enviado com cada pergunta, e a instrução de dizer "não
  sei" quando esse texto não tem a resposta. A lição 5 é o motivo dessa linha, e a lição 11 é como
  o texto do manual entra no pedido;
- o estilo: tom, idioma, tamanho e formato, inclusive sem Markdown, porque a caixa de chat do site
  não o desenha (lição 18);
- as recusas: o que é passado para uma pessoa, e a promessa de não fazer promessas.

O que **não** está nele importa tanto quanto. Os horários de funcionamento não estão: eles mudam, e
estão no manual, que chega com cada pergunta. Os exemplos da lição 21 também não; se o assistente
precisasse de alguns, seriam poucos e escolhidos contra um conjunto de teste.

## Nunca um segredo

O Wi-Fi da equipe do café tem senha. Pode parecer prático pô-la no prompt de sistema com a
instrução de nunca revelá-la. **Um prompt de sistema não é lugar seguro para nada, porque um prompt
de sistema pode ser revelado.** Ele é texto no contexto do modelo, e um usuário que pergunte do
jeito certo, ou um documento que traga a instrução certa, pode trazê-lo de volta numa resposta. A
lição 7 mostra como isso acontece e como é contido.

A regra que decorre é simples: escreva todo prompt de sistema como se ele fosse ser publicado. Sem
senhas, sem chaves, sem dados de clientes, sem notas internas sobre quais regras são aplicadas "de
verdade". **Se o modelo não pode contar algo a ninguém, o modelo não pode receber isso.** O manual
do café já diz que os clientes nunca recebem a rede da equipe, e o prompt do assistente não a
contém.

## Curto, versionado, testado

O prompt do café é curto, e custa tokens a cada pedido:

```
ana@lab:~/pe$ tok count prompts/system-v3.txt
tokens  words  chars  file
   149    111    649  prompts/system-v3.txt
```

149 tokens, enviados com cada mensagem que um cliente digita. Três páginas de regras custariam
muitas vezes isso, e seriam mais difíceis para o modelo seguir, não mais fáceis: uma instrução
enterrada no meio de um prompt longo recebe menos atenção que uma perto do começo ou do fim, o
efeito que a lição 4 descreve.

O arquivo se chama `system-v3.txt` porque é a terceira versão, e ele fica sob controle de versão ao
lado do código que o envia. Um prompt de sistema é parte da aplicação: **uma mudança nele é uma
mudança no comportamento do produto**, então ele ganha uma versão, um motivo na mensagem de commit e
uma rodada do conjunto de teste antes de ir para o ar. O método da lição 20 vale sem mudança. O
conjunto de teste de um assistente tem perguntas dentro do escopo, perguntas fora dele, uma pergunta
sobre alérgenos que o manual não responde e um pedido de reembolso, cada um com o que a resposta
certa faz.

## Tom e persona cabem aqui, com limites

"You are the assistant on the website of Café Aurora" é uma persona pequena, e o prompt de sistema é
o lugar certo para ela, já que vale para toda conversa. Uma maior, um personagem com nome e voz
própria, também cabe aqui se o café quiser. A lição 23 trata do que um papel assim muda nas
respostas, e do que ele não consegue mudar.
