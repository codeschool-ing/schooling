---
title: Esquecer e apagar
version: 2
---

Cedo ou tarde um sistema tem de deixar de saber alguma coisa. Uma política é retirada. Um documento
contém dados pessoais de um cliente e tem de sair: o aviso de privacidade deste corpus, escrito sob a
lei brasileira de proteção de dados, a LGPD, promete que uma pessoa pode pedir que seus dados sejam
apagados. Uma cláusula de contrato estava errada e nunca mais pode ser citada. As duas abordagens
diferem mais aqui do que em qualquer outro ponto, porque uma delas consegue apagar e a outra só consegue
ser treinada de novo.

## Apagar de um índice

Num sistema de recuperação, o conhecimento de um documento são os pedaços dele, e os pedaços são
linhas. Remover o documento remove as linhas, e a próxima pergunta não consegue achar o que não está
lá. O `sections.py` lê uma variável de ambiente com os documentos a deixar de fora, que é a mesma coisa
feita em memória:

```
ana@vm:~/rag$ python sections.py "How much does the return label cost?"
[1] 0.546  returns-policy-2025 > Return postage
[2] 0.446  returns-policy > How to start a return
[3] 0.407  warehouse-runbook > The label printer has stopped
According to [1], the return postage label costs 4.50 and is deducted from the refund.
ana@vm:~/rag$ WITHOUT=returns-policy-2025 python sections.py "How much does the return label cost?"
[1] 0.446  returns-policy > How to start a return
[2] 0.407  warehouse-runbook > The label printer has stopped
[3] 0.367  seller-agreement > 2. Fees
Unfortunately, the provided sources do not mention the cost of the return label. However, based on general knowledge, it is common for return labels to be free for the customer, as stated in source [1].

If you're looking for a specific answer, I couldn't find it in the provided sources. However, I can suggest that you contact the company's customer support or check their website for more information on return labels and their costs.
```

**Com o regulamento de 2025 no índice, a resposta é o preço de 2025**, 4,50 descontados do reembolso,
citando `[1]`, por uma etiqueta que é grátis desde fevereiro. Sem ele, os 4,50 somem: nada que sobrou
no índice diz isso, então nada pode ser citado. A mudança valeu na pergunta seguinte e não precisou
mudar modelo nenhum. Num banco de dados é um `DELETE` das linhas do documento, que a aula 5 prepara para
que um comando remova todos os pedaços de um documento e nada mais.

A segunda resposta não é boa, e isso também vale notar. O *How to start a return* do regulamento atual
diz que a etiqueta não custa nada, e o modelo primeiro diz que as fontes não falam do custo, depois que
etiquetas costumam ser grátis "for the customer", citando `[1]` para isso, e fecha sugerindo que o
cliente pergunte à empresa. Apagar o documento errado tirou a resposta errada; não fez o modelo ler bem
o certo. Essa é a metade do trabalho que cabe à geração, e à aula 7.

Essa exclusão também é **verificável**: depois dela, uma consulta pelo texto apagado não devolve nada, e
um teste pode afirmar isso. A aula 14 escreve esse teste para documentos que um usuário não pode ver, e o
mesmo teste prova uma exclusão.

## Apagar de um modelo

Um modelo ajustado que aprendeu a regra de 2025 com os dados de treinamento não pode ser levado a
esquecê-la removendo aquele exemplo. O exemplo mudou os pesos durante o treinamento, e a mudança está
espalhada por milhões de números sem registro de qual exemplo causou qual parte dela. As opções são:

- **treinar de novo a partir do modelo base** com um conjunto que não tem mais o exemplo, o que custa um
  treinamento completo e uma avaliação;
- **treinar por cima** com exemplos que ensinam o contrário, o que torna o modelo menos propenso a
  repetir o fato antigo e não garante que nunca vá repeti-lo;
- **filtrar a saída**, recusando respostas que contêm o texto proibido, o que pega a redação exata e
  nada mais.

A pesquisa sobre *machine unlearning* (desaprendizado de máquina) busca jeitos melhores, e até a data
deste curso nenhum deles é algo que uma equipe usaria com confiança para atender um pedido legal de
exclusão.

## Por que isso decide o projeto para dados pessoais

O aviso de privacidade deste corpus diz que conversas de atendimento são usadas para melhorar a busca
da central de ajuda só depois de nomes, e-mails, números de pedido e endereços serem removidos. Essa
frase é uma promessa, e um sistema de recuperação consegue cumpri-la: se um pedaço com um nome for
encontrado, ele é apagado e some. Um modelo ajustado em conversas de atendimento brutas tem esses nomes
em algum lugar dos pesos, e **nenhum pedido de exclusão chega até eles**.

A regra que decorre disso é simples: dados pessoais e qualquer coisa que talvez tenha de ser retirada
pertencem ao índice, onde podem ser removidos, e nunca aos dados de treinamento. A aula 13 aplica a mesma
regra ao que um assistente lembra sobre um cliente.
