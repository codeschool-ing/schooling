---
title: Três tipos de dado local, e só um deles é cache
version: 1
---

**Nem tudo o que um app guarda no aparelho é cache, e tratar tudo como uma coisa só é o jeito de
perder dado.** A palavra é usada de forma frouxa para qualquer coisa guardada localmente, e essa
frouxidão é o bug. Um cache é uma cópia de algo que o servidor ainda tem, guardada para economizar
uma requisição. O teste é curto: se este arquivo sumisse hoje à noite, algo se perderia, ou só
seria buscado de novo?

Essa pergunta separa o dado do planner em três tipos.

| tipo | o que é no planner | se some | onde mora |
|---|---|---|---|
| **fonte da verdade** | uma sessão digitada no trem e ainda não enviada | perdida de vez | o banco, na parte da caixa de areia que vai para o backup |
| **fixado para offline** | as anotações de um curso que a pessoa marcou como "manter offline" | a pessoa nota a falta no túnel para o qual fixou | o banco ou `files/`, nunca removido por tamanho |
| **cache** | o catálogo, a imagem de capa de um curso | uma requisição, da próxima vez que houver rede | `cache/` no Android, `Library/Caches/` no iOS |

**O primeiro tipo não é cache mesmo quando o servidor vai tê-lo depois.** Até a caixa de saída da
aula 8 entregar uma sessão, o celular tem a única cópia. As aulas 7 a 12 são sobre esse tipo, e
nada do que vem a seguir se aplica a ele: nada aqui pode expirá-lo, despejá-lo ou deixar o sistema
apagá-lo.

**O segundo tipo parece cache e é uma promessa.** A pessoa pediu que aquelas anotações estivessem
ali offline, então despejá-las para abrir espaço para uma imagem de capa quebra a promessa em
silêncio. Um item fixado fica até a pessoa desafixar, e o tamanho dele é mostrado a ela, porque é
ela quem pode decidir que é demais. A aula 18 conta o disco que ele ocupa.

**O terceiro tipo é o único para o qual valem as regras desta aula.** Um cache responde a três
perguntas, uma seção cada: por quanto tempo uma cópia pode ser mostrada antes de ser conferida (a
expiração, na próxima seção), até que tamanho o cache inteiro pode crescer (os limites de tamanho)
e o que acontece quando o sistema o apaga sem pedir (a última seção). Um cache que responde às três
pode sumir a qualquer momento, e a pessoa não nota nada além de uma imagem que carrega um segundo
depois.

## As três plataformas

As três oferecem um cache HTTP que segue os cabeçalhos do servidor, e um lugar para pôr o seu:

- **Android**: o `Cache` do OkHttp, que recebe um diretório dentro de `cacheDir` e um tamanho em
  bytes; o Coil e o Glide mantêm caches próprios de memória e de disco para imagens.
- **iOS**: o `URLCache`, que o `URLSession` usa por padrão, com capacidade de memória e de disco; o
  Kingfisher e o SDWebImage para imagens.
- **React Native**: o `fetch` passa pela pilha HTTP da própria plataforma, então o cache acima vale;
  o `expo-image` mantém um cache de memória e um de disco, escolhidos por imagem com `cachePolicy`.

*Esses nomes vêm da documentação de cada biblioteca, e nenhum app que os usa foi rodado para este
curso.* O resto da aula constrói a mesma maquinaria no Node, onde dá para vê-la decidir.
