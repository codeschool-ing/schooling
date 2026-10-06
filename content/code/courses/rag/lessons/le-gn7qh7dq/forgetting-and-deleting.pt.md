---
title: Esquecer e apagar
version: 1
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
ana@lab:~/rag$ python sections.py "How much does the return label cost?"
[1] 0.547  returns-policy-2025 > Return postage
[2] 0.446  returns-policy > How to start a return
[3] 0.407  warehouse-runbook > The label printer has stopped
You do not pay for the label, whatever the reason for the return. [2] You can use our returns label, which costs 4.50 and is deducted from your refund, or send the parcel by any tracked service at your own cost. [1]
ana@lab:~/rag$ WITHOUT=returns-policy-2025 python sections.py "How much does the return label cost?"
[1] 0.446  returns-policy > How to start a return
[2] 0.407  warehouse-runbook > The label printer has stopped
[3] 0.367  seller-agreement > 2. Fees
You do not pay for the label, whatever the reason for the return. [1]
```

**Com o regulamento de 2025 no índice, a resposta se contradiz**: grátis por `[2]`, 4.50 por `[1]`. Sem
ele, a resposta é a regra atual e nada mais. A mudança valeu na pergunta seguinte e não precisou mudar
modelo nenhum. Num banco de dados é um `DELETE` das linhas do documento, que a aula 5 prepara para que um
comando remova todos os pedaços de um documento e nada mais.

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
