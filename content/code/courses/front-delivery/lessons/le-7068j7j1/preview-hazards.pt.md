---
title: O que um preview nunca pode ter
version: 1
---

**Um preview é um site público.** O endereço dele é longo e não listado, e é só isso: qualquer pessoa com
o link consegue abri-lo, o link é colado em pull requests, conversas e chamados, e nada o impede de ir mais
longe. A documentação da Cloudflare diz isso com todas as letras: previews são públicos por padrão, e
restringir o acesso é algo que você liga. Trate todo preview como publicado, porque ele é.

## Quatro regras que vêm disso

1. **Nada de segredos de produção, e nada de dados de produção.** Um preview construído com os valores de
   produção fala com a API de produção, como quem o abrir. Um preview recebe os valores de staging,
   definidos por ambiente no host como a aula 2 mostrou, e uma API de staging com dados de staging.
2. **Nada de segredos ainda não prontos também.** Um recurso anunciado no mês que vem, um preço ainda não
   público, o nome de um parceiro: um preview desse branch publica isso hoje. Ponha esse preview atrás do
   controle de acesso do host, que os três oferecem de alguma forma, ou não faça preview dele.
3. **Fora dos buscadores.** Um preview indexado por um buscador concorre com o site de verdade e mostra às
   pessoas uma versão que já não existe. O Cloudflare Pages acrescenta o cabeçalho
   `X-Robots-Tag: noindex` aos endereços de preview por esse motivo; confira se o seu host faz isso, e
   acrescente-o no arquivo de regras do host para previews se não fizer.
4. **Nada de estranhos sem supervisão.** Um pull request vindo de um fork pode mudar o próprio build, e um
   build roda o que o `package.json` dele mandar. Hosts e GitHub seguram os segredos nesses builds, como a
   aula 2 mostrou, e alguns pedem que alguém da equipe aprove o build antes. Deixe esses padrões ligados.

## E o que conferir antes de dizer que um preview está bom

Um preview prova que o branch constrói e que as páginas dele parecem certas **no endereço do preview**.
Duas coisas ele não prova, e as duas aparecem na aula 4: que os redirecionamentos e reescritas se comportam
igual sob o domínio de produção, e que uma visita direta a um endereço profundo funciona com as
configurações de produção do host. A maioria dos hosts aplica o mesmo arquivo de regras aos dois, e é por
isso que as regras moram no repositório, e não num painel.
