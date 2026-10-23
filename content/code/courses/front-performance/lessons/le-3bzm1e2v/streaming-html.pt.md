---
title: Mandando uma página em pedaços
version: 1
---

**Uma resposta HTTP não precisa estar completa antes de ser mandada.** Um servidor pode mandar o
começo de uma página, manter a conexão aberta, e mandar o resto quando o tiver. O navegador lê o HTML
conforme ele chega e desenha o que tem, então a parte que foi rápida aparece enquanto a parte lenta
ainda está sendo feita. Isso é **streaming**, e todo servidor deste curso já conseguia fazê-lo: o
`res.write` manda um pedaço, o `res.end` manda o último.

A ideia comum é que renderizar no servidor quer dizer esperar a consulta mais lenta antes de mandar
qualquer coisa. O `server.ts` da aula 1 faz exatamente isso: lê o plano inteiro, desenha a página
inteira, e só então escreve um byte. Se as sessões viessem de um banco lento, o título, o link e o
formulário, que não precisam de nada disso, esperariam também.

## Uma página em duas partes

O `stream.ts` é um servidor pequeno para uma página, a de um curso, que a manda em duas partes. **As
sessões são lentas de propósito**: o `sessionsOf` espera um segundo antes de lê-las, no papel de uma
consulta lenta. Todo o resto vai na hora. Salve ao lado do `server.ts`:

```example
--- Um servidor próprio, na porta 3005, para o server.ts continuar funcionando ao lado.
--- A parte lenta. Nada mais no arquivo espera por ela.
--- Se o curso existe é rápido de descobrir, então é decidido antes de qualquer coisa ser mandada, e um curso desconhecido ainda pode receber um 404.
--- O primeiro pedaço: o status, os cabeçalhos, e a página até um marcador na lista. O res.write o manda agora e deixa a resposta aberta.
--- O segundo pedaço, um segundo depois: as sessões dentro de um template, que o navegador interpreta e não mostra, e um script que as move para a lista no lugar do marcador.
```

Ligue-o num terceiro terminal com `node stream.ts`. Para ver os pedaços, o `tools/chunks.ts` pede uma
página com o `fetch` do Node e imprime cada pedaço do corpo conforme ele chega, com o tempo desde a
requisição. Salve em `tools/`:

```typescript
@@
```

```
@@
```

**O status e o primeiro pedaço chegaram juntos, e o segundo um segundo depois**, exatamente onde está
a espera. Um curso desconhecido recebeu o seu 404 na hora, porque o servidor procurou o curso antes de
escrever qualquer coisa.

```schooling-figure
@fig
```
