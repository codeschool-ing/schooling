---
title: O que um framework web faz, e o que deixa para você
version: 1
---

A imagem comum de um framework é a de uma biblioteca grande: uma caixa de funções que você chama
quando precisa. **Um framework funciona ao contrário. Ele chama você.** Ele é dono da parte do
programa que espera uma requisição, lê, decide qual das suas funções deve responder e transforma o
que essa função devolve em bytes na rede. Você escreve as funções do meio, e o framework decide
quando elas rodam.

Essa inversão é toda a diferença entre o Django e o `requests`. Com o `requests`, você escreve o
programa e chama a biblioteca quando quer uma página. Com o Django ou o FastAPI, o programa já
existe, e você preenche as peças que ele pede.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma requisição chega a um processo servidor, que a entrega ao framework. O framework a interpreta, compara o caminho com uma tabela de rotas e chama uma função escrita por quem desenvolve. O que a função devolve volta pelo framework, que monta a resposta, e sai pelo servidor.\"> <defs><marker id=\"fw-arrow\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"28\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a rede</text> <rect x=\"20\" y=\"40\" width=\"110\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"75\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET /hello/ana</text> <text x=\"75\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">200 OK</text> <rect x=\"160\" y=\"40\" width=\"120\" height=\"170\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"220\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o servidor</text> <text x=\"220\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">escuta numa porta,</text> <text x=\"220\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lê os bytes</text> <rect x=\"310\" y=\"40\" width=\"390\" height=\"170\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\"0.12\" stroke=\"var(--phosphor)\"></rect> <text x=\"505\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o framework</text> <rect x=\"330\" y=\"82\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"385\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ler a requisição</text> <rect x=\"460\" y=\"82\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"510\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">achar a rota</text> <rect x=\"580\" y=\"82\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.25\" stroke=\"var(--amber)\"></rect> <text x=\"630\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sua função</text> <text x=\"630\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hello(name)</text> <rect x=\"330\" y=\"150\" width=\"350\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"505\" y=\"174\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">montar a resposta: status, cabeçalhos, corpo</text> <path d=\"M130 106 L154 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <path d=\"M280 102 L324 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <path d=\"M440 102 L454 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <path d=\"M560 102 L574 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <path d=\"M630 122 L630 144\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <path d=\"M330 170 L286 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <path d=\"M160 146 L136 146\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-arrow)\"></path> <text x=\"505\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Só a caixa em destaque é sua. O framework decide quando ela roda.</text> </svg>", "caption": "Uma requisição, da rede até a sua função e de volta. Em Python, o servidor e o framework são programas separados, e é disso que trata a seção sobre WSGI e ASGI desta aula."}
```

## Os trabalhos, um por um

Entre os bytes chegarem e a sua função rodar há uma dúzia de trabalhos, e toda aplicação web
precisa que alguém faça todos eles:

| trabalho | o que significa |
|---|---|
| **roteamento** | `/hello/ana` roda `hello` com `name="ana"`; `/goodbye/ana` é um 404 |
| **leitura** | a query string, os cabeçalhos, um formulário, um corpo JSON, um arquivo enviado |
| **validação** | uma idade que é número, um e-mail que parece e-mail, um campo que falta |
| **respostas** | um código de status, cabeçalhos, um corpo em JSON ou HTML |
| **dados** | linhas num banco, lidas e gravadas sem SQL escrito à mão por toda parte |
| **identidade** | quem está pedindo: um cookie de sessão, um token, a conferência de uma senha |
| **permissões** | se essa pessoa pode fazer essa coisa específica |
| **padrões de segurança** | cabeçalhos que impedem a página de ser emoldurada, formulários que não podem ser forjados |
| **ferramentas** | migrações, um shell, um cliente de teste, um jeito de rodar a coisa |

Um framework é um conjunto de respostas para essa tabela. **O Django responde a todas as linhas
sozinho. O FastAPI responde às quatro primeiras e deixa o resto para bibliotecas que você escolhe.**
Nenhum dos dois é atalho: as linhas que um framework deixa vazias continuam sendo linhas, e alguém da
equipe preenche.

## O que continua sendo seu

Seja qual for o framework, três coisas continuam suas: o que cada URL significa, como são os dados e
quais são as regras. Um framework consegue conferir que `capacity` é um inteiro positivo; só você
sabe que um evento com quarenta lugares tem de recusar a quadragésima primeira inscrição. A aula 4
escreve essa regra como uma restrição do banco, que é onde mora uma regra que nunca pode quebrar.

## A única coisa que um framework não é

**Um framework não é o servidor.** Em Python, o programa que escuta numa porta e o programa que
responde à requisição são dois programas com um contrato padrão entre eles. O `runserver` do Django
e o comando `uvicorn` que você vai ver daqui a pouco são servidores; o Django e o FastAPI são as
aplicações que eles chamam. Essa divisão é o que permite à aula 16 pôr o Django atrás do Gunicorn e
o FastAPI atrás do Uvicorn sem mudar uma linha de nenhum dos dois, e a seção sobre WSGI e ASGI mostra
o contrato em si.
