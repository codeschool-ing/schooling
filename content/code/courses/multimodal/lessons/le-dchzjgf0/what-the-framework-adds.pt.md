---
title: O que um framework acrescenta, e o que esconde
version: 1
---

Quatro programas nesta aula, dois frameworks, e uma capa enviada três vezes. Como ficou cada lado da troca, neste laboratório:

| um framework deu | um framework escondeu |
|---|---|
| um só tipo de mensagem para vários provedores (o bloco padrão do LangChain) | o pedido que saiu, até um método privado imprimi-lo |
| `ImageBlock(path=...)`, com o base64 feito para você | um endereço padrão `api.openai.com`, ignorando a variável que o SDK lê |
| uma cadeia, `RunnableLambda` e o operador pipe, para transcrever e depois extrair | uma tabela de nomes de modelo que recusou um novo |
| saída estruturada numa classe Pydantic | nada sobre se os valores foram ouvidos |
| um depósito de vetores e documentos com metadados | nada sobre que língua o modelo de embeddings lê |

Nada da coluna da direita é motivo para não usar um framework. É uma lista de coisas a conferir **porque** você usa um. Três hábitos cobrem quase tudo:

- **Conte os tokens de uma imagem com e sem o framework.** Aqui deu 765 todas as vezes. Um framework que redimensionasse, recodificasse ou mandasse `detail: high` por padrão apareceria como outro número, e na conta.
- **Fixe as versões**, como o `lab.sh` faz. Blocos de conteúdo são recentes nos dois pacotes e ainda mudam; o `langchain-core` 1.x mudou a grafia deles, e uma versão menor de uma integração pode mudar o que é enviado.
- **Mantenha o SDK do provedor ao alcance.** A cadeia acima já o usa para transcrever, porque é lá que o endpoint está. Um passo que o framework não cobre é uma função, não um motivo para esperar.

Quando um framework é a ferramenta errada? Quando o programa faz uma chamada só. Uma descrição de capa, uma transcrição, uma imagem gerada: a chamada do SDK tem três linhas, e as aulas 8 a 10 as mostraram. O framework começa a se pagar quando há **vários provedores, vários passos, ou recuperação**: os formatos dos dois últimos programas desta aula.
