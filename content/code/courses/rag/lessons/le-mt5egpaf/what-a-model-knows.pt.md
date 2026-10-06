---
title: O que um modelo sabe, e o que ele não sabe
version: 1
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

O laboratório deste curso tem um gerador chamado **extract-1**, e a próxima seção diz exatamente o que
ele é. Ele responde pela mesma API que um modelo real. Para esta seção basta saber como ele se
comporta quando a pergunta chega sozinha, sem nenhum documento junto. Responde a partir de um pequeno
arquivo de frases que o curso escreveu como o que ele "aprendeu no treinamento", e responde sempre.

O `ask.py` manda uma pergunta e imprime a resposta:

```
ana@lab:~/rag$ python ask.py "How many days do I have to return a printed book?"
You can return a book to Marginalia within 14 days of delivery, as long as it is unread. Return postage is paid by the customer.
ana@lab:~/rag$ python ask.py "What is the phone number for customer service?"
You can call Marginalia's customer service on 0800 555 0199, every day from 9 am to 6 pm.
ana@lab:~/rag$ python ask.py "Can I get my money back for an e-book I downloaded yesterday?"
You can return a book to Marginalia within 14 days of delivery, as long as it is unread. Return postage is paid by the customer.
```

**As três respostas estão erradas, e as três parecem certas.** A primeira é o caso do fato *mudado*:
catorze dias e frete de devolução pago eram as regras da Marginalia em 2025, e a política em vigor
desde fevereiro de 2026 dá trinta dias e devolução grátis. A segunda é um telefone de uma central que
não existe; nada nos documentos da loja menciona uma. A terceira responde a uma pergunta sobre e-books
com a regra dos livros impressos, porque era o que ele tinha de mais próximo.

```
ana@lab:~/rag$ grep -c "\"q\"" /opt/rag/share/memory.json
10
```

A memória do extract-1 são dez frases, escritas pelo curso para se comportar como a memória de um
modelo real se comporta mal. A memória de um modelo real é imensamente maior e em geral está certa, o
que torna o erro mais raro e os erros mais difíceis de notar. A forma é a mesma: **uma resposta
fluente, nenhuma fonte, e nenhum sinal no texto que separe a certa da errada.**

## Por que o modelo não diz simplesmente que não sabe

Seria cômodo se o modelo se recusasse quando lhe falta o fato. O treinamento empurra os modelos a
admitir que não sabem, e os modelos atuais fazem isso mais que os antigos. Mas um modelo não tem
registro do que leu, então não consegue verificar se um fato estava no texto de treinamento; só tem a
probabilidade de cada próxima palavra. Um número de telefone plausível é um texto bem provável. **A
confiança do modelo mede o quanto a resposta soa plausível, e não se ela é verdadeira.**

É esse o problema que este curso resolve. Não fazendo o modelo saber mais, o que só empurra a data de
corte, e sim entregando a ele o texto certo no momento em que responde e fazendo-o dizer de onde a
resposta veio.
