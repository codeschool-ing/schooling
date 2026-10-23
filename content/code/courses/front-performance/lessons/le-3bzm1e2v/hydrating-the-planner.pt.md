---
title: Hidratando o planner
version: 1
---

**Três mudanças fazem o planner hidratar**: o servidor põe o plano na página, o script o lê de lá em
vez de buscá-lo, e o `mount` mantém o HTML que achou em vez de trocá-lo. Esta seção também acrescenta
um recurso pequeno, o dia da semana ao lado da data de cada sessão, porque uma página de verdade
sempre tem algo assim, e a próxima seção mostra o que ele faz.

## O servidor põe os dados na página

No `server.ts`, a linha que monta a página agora acrescenta um `<script type="application/json">`
depois do `<main>`. Um script desse tipo nunca roda; é um lugar para guardar dados que o script da
própria página consegue ler. Troque a linha que monta o `html` por estas:

```typescript
@@
```

**O `replace` não é enfeite.** Um curso com o título `</script><script>…` fecharia o elemento de dados
no meio e começaria um script próprio, escrito por quem deu nome ao curso. O JSON permite escrever `<`
como `<`, que é o mesmo caractere para o `JSON.parse` e não quer dizer nada para o parser de
HTML.

## O script os lê

O `src/main.ts` procura esse elemento primeiro, e só busca quando ele não está lá, como no build
renderizado no cliente:

```typescript
@@
```

## A view mantém o que achou

O `src/view.ts` muda em três lugares, então aqui está ele inteiro. A nova função `day` acrescenta o
dia da semana; a nova `same` compara o HTML na tela com o HTML que o script desenharia; e o `mount`
só desenha quando precisa:

```example
--- O escape, como antes.
--- Novo: o dia da semana, a partir da data, em inglês, como "Sat 2026-10-24".
--- A página inicial não muda.
--- A página de um curso chama day() onde antes imprimia só a data.
--- Novo: o HTML que o script desenharia é interpretado fora da página, e o seu texto comparado com o texto que já está na tela. Texto, e não marcação, porque o navegador reescreve os atributos de um jeito diferente do que a string escreveu.
--- Os listeners são os mesmos de antes. Eles ficam no contêiner, então funcionam no HTML que o servidor desenhou exatamente como no HTML que o script desenhou.
--- A parte nova. Um main vazio é desenhado, como no build renderizado no cliente. Um main que diz outra coisa é desenhado de novo, com um aviso, porque o script não deve agir sobre uma página que ele não entende. E quando termina, o horário vai para um atributo que uma ferramenta de medida consegue ler.
```

## Uma ferramenta que vê acontecer

O `tools/hydrate.ts` abre uma página no Chromium **como uma pessoa em São Paulo abriria**, com esse
fuso horário, e imprime o que o console disse, quando a página pintou e quando o script a assumiu. Ele
tem duas opções que a seção depois da próxima usa. Salve em `tools/`:

```typescript
@@
```

Faça o build, e ligue o `server.ts` no segundo terminal **com `TZ=UTC`**, o fuso em que quase todo
servidor de data center roda:

```sh
@@
```

Depois peça o curso de Git, e abra-o como a pessoa em São Paulo:

```
@@
```

**O servidor disse sábado e o navegador disse sexta**, avisou, e desenhou a sua versão por cima da do
servidor. O `look.ts`, na última linha, lista as requisições: não há `/courses.json` entre elas, então
os dados na página fizeram o seu trabalho. Todo o resto é a próxima seção.
