---
title: As palavras do Cache-Control
version: 1
---

O `Cache-Control` é uma lista de diretivas separadas por vírgulas, e quatro pares delas cobrem quase
tudo o que uma resposta precisa dizer. Os nomes foram tão mal escolhidos que cada par traz uma
armadilha.

| diretiva | o que diz | a armadilha |
|---|---|---|
| `max-age=N` | fresca por N segundos | nenhuma; é por ela que se começa |
| `s-maxage=N` | fresca por N segundos **num cache compartilhado**, valendo sobre o `max-age` ali | o navegador a ignora |
| `public` | um cache compartilhado pode guardar isto, mesmo onde por padrão não guardaria | raramente necessária com `max-age` presente |
| `private` | só o navegador da própria pessoa pode guardar isto | um cache compartilhado que a ignore entrega a página de uma pessoa a todos |
| `no-cache` | guarde, mas **confira com a origem antes de cada uso** | não quer dizer "não guarde" |
| `no-store` | não guarde em lugar nenhum | essa sim quer dizer "não guarde" |
| `must-revalidate` | depois de velha, nunca entregue sem conferir, mesmo com a origem fora do ar | transforma uma queda da origem em erros em vez de páginas antigas |
| `immutable` | esta URL exata nunca vai mudar; nem confira | só é verdade para uma URL com a versão no nome (aula 6) |

Três combinações cobrem a maioria das respostas reais:

- **uma página que muda por pessoa**, a página da conta, o carrinho: `private, no-cache`, ou `no-store`
  onde houver qualquer coisa sensível, para nunca ir a um cache compartilhado e nunca ser entregue do
  disco de ninguém sem perguntar;
- **uma página pública que muda**, a listagem do catálogo: `public, max-age=60`, ou `max-age=60,
  s-maxage=300` para deixar o cache do próprio servidor guardá-la mais tempo que os navegadores, já que
  o cache do servidor pode ser limpo e os navegadores não (aula 6);
- **um arquivo cujo nome traz a versão**, `site.3f2a91c4.css`: `public, max-age=31536000, immutable`.

**`no-cache` é a palavra mais mal lida do cache HTTP.** Ela permite guardar e proíbe entregar sem
perguntar, o que a torna ideal para algo que muda de forma imprevisível mas é caro de mandar de novo:
a cópia fica, cada uso custa uma conferência rápida, e a conferência quase não custa nada quando a
resposta não mudou. Essa conferência é a próxima seção.
