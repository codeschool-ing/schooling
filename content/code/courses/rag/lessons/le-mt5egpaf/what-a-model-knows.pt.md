---
title: O que um modelo sabe, e o que ele não sabe
version: 2
---

Um modelo de linguagem sabe o que o texto de treinamento ensinou a ele, e nada mais. Esse
conhecimento fica guardado nos pesos, e por isso se chama **conhecimento paramétrico**: ele foi
fixado no dia em que o treinamento parou, e nada que um usuário faça depois acrescenta alguma coisa.
O modelo não consulta nada quando responde. Ele produz o texto que o treinamento tornou mais provável
depois da pergunta.

A imagem que a maioria das pessoas traz é outra. Elas imaginam o modelo consultando alguma coisa,
como um buscador consulta um índice, e esperam que ele perceba quando a consulta não trouxe resposta.
Nenhuma das duas coisas acontece. Não há o que consultar nem o que perceber: uma pergunta sobre um
assunto que o modelo nunca viu recebe uma resposta com exatamente a mesma cara de uma resposta sobre
um assunto que ele viu.

## Três jeitos de um fato faltar

Os documentos de uma empresa faltam num modelo por três motivos diferentes, e o terceiro é o perigoso.

- **Privado.** O manual de atendimento da Marginalia nunca foi publicado, então nenhum treinamento o
  leu. O modelo não faz ideia de quanto um atendente pode reembolsar sem aprovação.
- **Novo.** Qualquer coisa escrita depois da data de corte do treinamento está ausente, por mais
  pública que seja. Uma política publicada no mês passado não existe para um modelo treinado no ano
  passado.
- **Mudado.** Um fato que era verdade quando o texto de treinamento foi escrito e é falso agora. O
  modelo aprendeu, aprendeu bem, e repete com toda a confiança.

Os dois primeiros ao menos produzem uma resposta sem nada por trás. O terceiro produz uma resposta com
algo por trás que já esteve certo, e isso é muito mais difícil de pegar.

## Perguntando sem fonte

O `ask.py` manda uma pergunta ao llama3.2:3b, sozinha, e imprime a resposta:

```schooling-example
{
  "language": "python",
  "file": "ask.py",
  "parts": [
    {
      "code": "import sys\nfrom openai import OpenAI\n\nclient = OpenAI()",
      "note": "O cliente encontra o Ollama pelo `OPENAI_BASE_URL`, que o `env.sh` define."
    },
    {
      "code": "reply = client.chat.completions.create(\n    model=\"llama3.2:3b\",\n    temperature=0,\n    messages=[{\"role\": \"user\", \"content\": sys.argv[1]}],\n)\nprint(reply.choices[0].message.content)",
      "note": "A pergunta da linha de comando, sozinha: sem mensagem de sistema, sem documento. `temperature=0` faz a mesma pergunta receber a mesma resposta na mesma máquina."
    }
  ]
}
```

```
ana@vm:~/rag$ python ask.py "How many days do I have to return a printed book?"
The number of days you have to return a printed book depends on the library's return policy, which can vary depending on the library and the type of book.

Typically, most public libraries have a return policy that allows you to return books within a certain timeframe, usually 1-3 weeks, without any fines. However, if you keep a book for longer than the allowed time, you may be charged a fine.

Here are some general guidelines:

* Most public libraries: 1-2 weeks (7-14 days) without fines
* Some libraries: 2-3 weeks (14-21 days) without fines
* Interlibrary loan books: 1-2 weeks (7-14 days) without fines

It's always best to check with your local library's return policy to confirm their specific rules and deadlines.
ana@vm:~/rag$ python ask.py "What is the phone number for customer service?"
I don't have have access to real-time information, but I can suggest some options to help you find the customer service phone number for a specific company:

1. Check the company's website: Most companies list their customer service phone number on their official website.
2. Search online: You can search for the company's name along with "customer service phone number" to find the information.
3. Check the packaging or documentation: If you have the product or documentation, you can check the packaging or instructions for the customer service phone number.
4. Contact the company directly: You can try contacting the company directly through their website's contact form or by sending an email.

If you provide me with the name of the company, I can try to help you find the customer service phone number.
ana@vm:~/rag$ python ask.py "Can I get my money back for an e-book I downloaded yesterday?"
I can't provide information about a specific e-book or purchase. If you're unhappy with an e-book you've downloaded, I can offer general guidance on returning or refunding an e-book purchase. Would that help?
```

**Nenhuma das três respostas é sobre a Marginalia, e só uma delas diz isso.** A primeira é a
perigosa. Um modelo que nunca ouviu falar da loja recebeu uma pergunta sobre devolver um livro
impresso e respondeu a pergunta que conhecia, sobre devolver um livro a uma biblioteca: de uma a três
semanas, multas, empréstimo entre bibliotecas. É fluente, específica e confiante, e é sobre outro
negócio. Um cliente que a lê procurando um número encontra um, "7-14 days", e o número está errado
para esta loja, cuja política dá trinta dias.

As outras duas fazem o que um modelo cuidadoso faz com uma pergunta que não sabe responder. A do
telefone recebe a admissão de que ele não tem acesso à informação e conselhos para encontrá-la, e a do
e-book recebe uma oferta de orientação geral. É o comportamento para o qual o treinamento empurra os
modelos, e o llama3.2:3b o mostra duas vezes em três. **O problema é a terceira vez: nada no texto da
primeira resposta a distingue de uma resposta certa.**

Um modelo maior sabe mais e hesita mais, o que torna a falha mais rara e mais difícil de notar. A
forma continua a mesma, e é ela que importa para os documentos de uma empresa: **uma resposta
fluente, nenhuma fonte, e nenhum sinal no texto que separe a certa da errada.**

## Por que o modelo não diz simplesmente que não sabe

Ele recusou duas vezes acima, e seria conveniente se recusasse toda vez que lhe faltasse o fato. O
treinamento de fato empurra os modelos a admitir que não sabem, e os modelos modernos fazem isso mais
que os antigos. Mas um modelo não tem registro do que leu, então não consegue conferir se um fato
estava no texto de treinamento; tudo o que ele tem é a probabilidade de cada próxima palavra. Depois
de uma pergunta sobre devolver um livro impresso, as regras de empréstimo de uma biblioteca são um
texto muito provável. **A
confiança do modelo mede o quanto a resposta soa plausível, e não se ela é verdadeira.**

É esse o problema que este curso resolve. Não fazendo o modelo saber mais, o que só empurra a data de
corte, e sim entregando a ele o texto certo no momento em que responde e fazendo-o dizer de onde a
resposta veio.
