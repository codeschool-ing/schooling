---
title: O que um cache economiza
version: 1
---

**Um visitante que volta já tem a maior parte da página.** O script, a folha de estilo, as fontes e as
imagens foram baixados na primeira visita, e o navegador os guarda no seu **cache HTTP**, em disco, com o
endereço como chave. O que ele faz com eles na segunda visita é uma de três coisas:

| o que o navegador faz | o que custa | quando |
|---|---|---|
| **usa a cópia sem perguntar** | nada: nenhuma requisição sai do computador | o servidor disse por quanto tempo a cópia vale, e esse tempo não passou |
| **pergunta se a cópia ainda está certa** | uma ida e volta, e poucos bytes de volta: `304 Not Modified` | a cópia não está mais fresca, ou o servidor mandou conferir toda vez, e o servidor deu algo com que conferir |
| **baixa de novo** | a ida e volta e o arquivo inteiro | não há com que conferir, ou o arquivo mudou |

A primeira é o que deixa uma segunda visita rápida. A segunda é o que a deixa correta: uma página que mudou
é baixada, e uma que não mudou custa uma ida e volta e nenhum corpo. A terceira é o que o planner faz agora,
com tudo, em toda visita.

## Outros caches no caminho

**O do navegador não é o único cache.** Entre um visitante e um servidor pode haver uma **CDN**, os
servidores de uma empresa em muitas cidades que guardam cópias perto de quem pede, e numa rede de empresa um
proxy que faz o mesmo para os seus usuários. Esses são **caches compartilhados**: uma cópia serve muita
gente. Os mesmos cabeçalhos dizem o que eles podem guardar, e a regeneração da aula 3, páginas estáticas
guardadas por um tempo e refeitas em segundo plano, é um deles trabalhando.

## O que o navegador faz sem cabeçalhos

**Uma resposta sem cabeçalhos de cache não deixa de ir para o cache.** O HTTP permite que um cache estime um
tempo de vida pela idade aparente do arquivo, um décimo do tempo desde a data do `Last-Modified`, e os
navegadores fazem isso. Um arquivo que não muda há um ano pode ser guardado por um mês com essa estimativa,
e um deploy que o muda não é visto até o mês acabar. Dizer o que você quer é o único jeito de saber o que vai
acontecer, e é o que o resto desta aula faz.
