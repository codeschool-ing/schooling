---
title: Nada no pacote é segredo
version: 1
---

**Todo valor no pacote de um front-end pode ser lido por qualquer pessoa que consiga abrir a página.** O
pacote é um arquivo que o navegador baixa; qualquer um pode baixá-lo com `curl`, abri-lo nas
ferramentas de desenvolvedor do navegador ou fazer uma busca nele. Minificar muda os nomes das
variáveis, e uma string continua sendo uma string.

## O conserto óbvio, e o que ele faz

A seção anterior deixou no `main.ts` uma linha imprimindo `SUPPORT_TOKEN`, que saiu `undefined`. O
conserto que alguém tenta no fim de um dia longo é dar à variável o prefixo que faltava:

```
ana@dev:~/planner$ sed -i 's/SUPPORT_TOKEN/VITE_SUPPORT_TOKEN/' .env.local src/main.ts
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ grep -o 'token:[^)]*' dist/assets/*.js
token:`,`tok-demo-not-a-real-secret`
```

O token está no pacote, em texto puro, ao lado do rótulo que o código imprimiu. Publicado, ele estaria
no arquivo que o navegador de todo visitante baixa, e em toda cópia desse arquivo que a CDN guarda.
**Tirá-lo do código depois não o traz de volta**: quem baixou o arquivo já o tem, e o token precisa ser
trocado em quem o emitiu.

Ponha o planner de volta como estava:

```
ana@dev:~/planner$ git checkout src/main.ts && rm .env.local
Updated 1 path from the index
```

## Chaves públicas e chaves secretas

Muitos serviços sabem disso e emitem **dois tipos de chave**. Um provedor de pagamentos, um serviço de
mapas, um relator de erros: cada um dá a você uma chave feita para ser publicada e outra que não é.

| | uma chave publicável | uma chave secreta |
|---|---|---|
| onde vai | no front-end, sob `VITE_` | só num servidor que você controla |
| o que ela faz | o que o serviço permite a partir de um navegador: mostrar um mapa, iniciar um pagamento, mandar um relatório | tudo o que a conta faz: estornar, ler todo registro, mudar configurações |
| o que a protege | limites definidos no serviço: quais domínios podem usá-la, com que frequência | ficar fora de todo arquivo que um visitante alcança |
| se vazar | alguém usa a sua cota a partir da própria página, o que o limite de domínio bloqueia | alguém age como você |

**Uma chave é publicável porque o serviço diz que é, não porque está numa variável `VITE_`.** Leia a
documentação do serviço para saber qual é qual; a maioria diz com clareza (`pk_` contra `sk_` é uma
convenção comum). Quando um serviço dá uma chave só, trate-a como secreta. A aula 11 usa o tipo
publicável: o endereço de um relator de erros, que está no navegador de todo visitante por definição.

## Os lugares onde um valor se esconde

O pacote não é o único lugar. **Source maps** levam o código original, comentários e tudo, quando são
publicados; a aula 11 os constrói de modo que não sejam. O **`index.html`** também pode guardar valores,
já que o Vite substitui `%VITE_…%` nele. E **uma requisição que a página faz** leva o que o código pôs
nela: um segredo mandado como cabeçalho a partir do navegador é tão público quanto um escrito no pacote,
porque o painel de rede das ferramentas de desenvolvedor mostra todo cabeçalho.

A regra que cobre todos eles é a do começo desta seção: se o navegador tem, a pessoa usando o navegador
tem.
