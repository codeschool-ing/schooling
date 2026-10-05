---
title: O que rodar um modelo envolve
version: 1
---

"Auto-hospedar" soa como uma decisão. São quatro, empilhadas, e cada camada é algo que um provedor
de API fazia por você sem mencionar:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"As quatro camadas de que um modelo auto-hospedado precisa, de baixo para cima: o hardware com a memória do acelerador, os pesos carregados nela, o runtime que gera tokens e um servidor que expõe um endpoint. Em volta das quatro, o trabalho de manter funcionando. Um provedor de API roda tudo isso por você.\"><defs><marker id=\"l3stack-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"680\" height=\"272\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">manter funcionando</text><text x=\"360\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">atualizações, patches, monitoramento, escala, plantão</text><rect x=\"160\" y=\"220\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o hardware</text><text x=\"360.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a memória do acelerador decide o que cabe</text><rect x=\"160\" y=\"174\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">os pesos</text><text x=\"360.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um arquivo, com alguma precisão</text><rect x=\"160\" y=\"128\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o runtime</text><text x=\"360.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">carrega os pesos, gera tokens</text><rect x=\"160\" y=\"82\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um servidor</text><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um endpoint, uma fila, logs</text><line x1=\"630\" y1=\"82\" x2=\"562\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l3stack-ah)\"></line><text x=\"640\" y=\"76\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o seu programa chama aqui</text></svg>", "caption": "Um provedor de API roda todas as camadas, e a moldura em volta delas, para todos os clientes ao mesmo tempo."}
```

**Os pesos**, um arquivo ou um conjunto de arquivos: bilhões de números com alguma precisão. A
seção 03 calcula o tamanho, a seção 04 como deixá-los menores.

**Um runtime**, o programa que carrega os pesos no hardware e gera tokens: lê o prompt, produz um
token de cada vez, aplica o template de chat da aula 1 seção 04. llama.cpp, vLLM e Ollama são três;
a aula 14 roda o último. Cada um suporta alguns formatos de modelo e algum hardware, e não outros.

**O hardware**, e na prática o único número que decide se um modelo roda ou não: **a memória do
acelerador** em que ele roda. Um modelo cujos pesos não cabem na memória não roda devagar; ele não
roda, ou roda a partir de uma memória mais lenta, a uma fração da velocidade.

**Um servidor**, que transforma o runtime em algo que um programa pode chamar: um endpoint HTTP,
autenticação, uma fila para quando duas requisições chegam juntas, logs, uma checagem de saúde e
um jeito de reiniciá-lo às três da manhã. A maioria dos runtimes traz um básico, geralmente no
formato da API da OpenAI, para que código existente possa apontar para ele (aula 20).

## A parte que ninguém desenha

Em volta das quatro fica o trabalho de **manter funcionando**: atualizar o runtime, aplicar patches
na máquina, vigiar memória e latência, acrescentar uma segunda máquina quando uma não basta e
perceber quando ele para. A seção 07 trata desse trabalho, porque é a linha da conta mais fácil de
esquecer e a que mais vezes decide.

A pergunta para o resto desta aula é simples de enunciar. **Uma API cobra por token por tudo isso.
Quando fazer você mesmo custa menos, ou dá algo que uma API não dá?**
