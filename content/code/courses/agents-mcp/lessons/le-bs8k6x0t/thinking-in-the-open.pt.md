---
title: Pensamentos não são auditoria
version: 1
---

O pensamento num passo de ReAct parece uma explicação: *"Entregue em 18 de setembro, então a janela vai até 18 de outubro; agora as regras de reembolso."* É tentador tratar essa frase como o motivo de a próxima chamada ter sido feita, e confiar nela quando algo dá errado. **Ela é evidência, não prova.**

O raciocínio escrito de um modelo é mais texto que o modelo produziu. Estudos sobre a fidelidade da cadeia de pensamento acharam modelos cujo raciocínio declarado omite o que de fato mudou a resposta, como uma dica plantada no prompt; a frase se lê como causa e foi gerada junto com a decisão, não antes dela. Então a coluna `said` de um rastro diz o que o modelo afirmou, e as colunas `called` e `returned` dizem o que aconteceu. **Quando as duas discordam, as chamadas são o registro.**

## Três consequências para um agente

**Confira afirmações contra resultados, não contra pensamentos.** Um pensamento que diz *"o pedido foi entregue"* só vale algo se um resultado de `get_order` acima dele diz `delivered`. Os testes da aula 7 conferem respostas contra resultados de ferramentas, nunca contra o relato do próprio modelo.

**Registre os pensamentos mesmo assim.** Eles são o jeito mais rápido de ver onde uma execução saiu do trilho, como o laço da seção 08 mostrou: *"Those articles do not mention signed copies; I will search for signed copies"* nomeia o erro numa linha. Não servir como prova não os torna inúteis como pista.

**Espere que parte do raciocínio fique escondida.** Modelos que raciocinam longamente antes de responder (vendidos como pensamento estendido ou modelos de raciocínio) costumam devolver esse raciocínio resumido, criptografado ou de jeito nenhum, e algumas APIs exigem que ele seja devolvido sem alteração no pedido seguinte. Um agente construído sobre um deles recebe menos pensamentos para ler, e as chamadas viram o rastro inteiro.

## Mostrar pensamentos a um cliente

Se o cliente vê os pensamentos é uma decisão de produto com um lado de segurança. Um pensamento pode repetir o que uma ferramenta devolveu, incluindo dados de outro cliente numa ferramenta mal delimitada, ou uma linha do prompt de sistema. **Mostre a resposta, guarde os pensamentos no rastro**, e trate o rastro com o cuidado que a seção 06 descreveu.
