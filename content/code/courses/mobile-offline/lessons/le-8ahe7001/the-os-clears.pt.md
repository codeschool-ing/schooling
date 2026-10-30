---
title: O sistema esvazia o cache, e o app não pode perceber
version: 1
---

**Nas duas plataformas, a pasta de cache é do sistema para esvaziar, e ele vai esvaziar.** Esse é
o acordo que o nome da pasta faz. O iOS esvazia `Library/Caches/` quando o disco está quase cheio,
e pode fazer isso com o app fechado. O Android apaga arquivos do `cache/` de um app quando o
aparelho fica com pouco armazenamento, os mais antigos primeiro, e a documentação do Google manda os
apps manterem o cache abaixo de um limite próprio, que a seção anterior construiu. A pessoa também
pode esvaziá-lo, pela página do app nas configurações do Android, com "Limpar cache".

**Então o código de um app precisa tratar toda leitura do cache como uma que pode não achar nada.**
O bug que isso evita é aquele em que o cache é, sem ninguém perceber, a única cópia: um rascunho
salvo em `cache/` porque era um arquivo temporário, um envio montado pela metade em `tmp/`, um banco
posto em `Library/Caches/` porque era ali o padrão de uma biblioteca. Cada um funciona por meses,
até o dia em que o sistema precisa do espaço.

Aqui está o lado do sistema, feito pelo `rm`, nos dois caches desta aula, seguido do app pedindo o
que tinha:

```
ana@dev:~/planner/cache$ rm -rf cache.db covers covers.db
ana@dev:~/planner/cache$ node fetch.ts 1100
t=1100: nothing cached, the screen waits for the network
  network: 200 downloaded
  on screen: Spanish A2, Statistics, Guitar, Chess
ana@dev:~/planner/cache$ node lru.ts get spanish
miss spanish: download it again
cache: empty | 0 of 10 MB
```

**Os dois programas seguiram em frente.** O `fetch.ts` não achou nada em cache e esperou a rede,
que respondeu com uma cópia nova; o `lru.ts` relatou uma falha e o planner baixaria a capa de novo.
Nenhum quebrou por uma tabela ou um arquivo ausente, porque cada um cria o que precisa ao começar e
confere antes de ler. Essa é a técnica inteira, e ela é pequena o bastante para testar: apague a
pasta de cache num teste e rode a tela.

**O que precisa sobreviver vai para outro lugar.** A fonte da verdade é o banco, na parte da caixa
de areia que vai para o backup: `databases/` ou `files/` no Android, `Library/Application Support/`
no iOS, como a aula 1 mediu. Os itens fixados vão para lá também, sob o controle da pessoa. O cache
guarda só o que a primeira seção chamou de terceiro tipo, e com essa regra mantida, o sistema
esvaziá-lo é um evento que ninguém vê.

## Antes do exercício

- Uma **fonte da verdade** nunca expira, nunca é despejada e nunca mora na pasta de cache.
- Um item **fixado** fica até a pessoa desafixar, e o tamanho dele é mostrado a ela.
- Uma entrada de **cache** fica fresca pelo `max-age`, pode ser mostrada velha enquanto é
  conferida, é conferida barato com um `ETag`, vive sob um orçamento em bytes e pode sumir a
  qualquer momento.
