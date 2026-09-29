---
title: "Vercel e Netlify: um site a partir de um git push"
version: 1
---

Vercel e Netlify aparecem ao lado do Lambda como plataformas serverless, e são, mas vendem outra
coisa. **São plataformas para sites de front-end: você conecta um repositório git, e cada push é
construído e publicado sem você encostar num servidor.** Nos termos da aula 1, são uma PaaS para a
web, com funções como um recurso entre vários.

O fluxo de trabalho é o produto:

1. Você conecta o repositório e diz qual framework ele usa, ou a plataforma descobre: um gerador de
   sites estáticos, Next.js (que a Vercel faz), Astro, SvelteKit e outros.
2. Cada push para o branch principal roda o build e publica o resultado como o site no ar. Os
   arquivos estáticos são servidos por uma CDN.
3. **Cada pull request ganha uma URL de preview própria**: uma cópia completa do site construída a
   partir daquele branch, que quem revisa pode abrir e navegar antes de qualquer merge.
4. Voltar atrás é apontar o endereço no ar para um build anterior, que já existe e não precisa ser
   construído de novo.

O terceiro passo é o motivo pelo qual as equipes adotam essas plataformas. **Uma mudança numa página
é revisada como página, por quem precisa vê-la, e não como diff, por quem sabe ler um.**

## As funções vão junto

A parte de API de um site mora no mesmo repositório. **Um arquivo numa pasta convencionada vira uma
função, publicada com o site e respondendo no mesmo domínio**: `api/` na Vercel,
`netlify/functions/` na Netlify. Um formulário de contato, o retorno de um login ou um endpoint de
busca são poucas linhas ao lado das páginas que os usam, sem outro serviço para publicar. As duas
plataformas também rodam código na borda, antes de a requisição chegar ao cache, para
redirecionamentos e coisas do tipo.

Essas funções são o modelo desta aula, com os limites dele: uma duração máxima, nenhum estado entre
chamadas, cold starts onde o runtime os tem. As duas plataformas cobram por plano, com franquias de
banda, de builds e de uso de funções e uma cobrança pelo que passar delas. As condições mudam, e estão
nas páginas de cada plataforma.

## Onde elas se encaixam, e onde não

Elas se encaixam num site institucional, num site de documentação, num portfólio, no front-end de uma
aplicação cujo back-end mora em outro lugar e num produto pequeno cuja API inteira é um punhado de
funções.

**Elas se encaixam mal quando o back-end é a maior parte do produto.** Tarefas longas, filas,
trabalho pesado contra um banco de dados e qualquer coisa que precise da sua própria rede ficam
melhor numa plataforma feita para isso, com o front-end na Vercel ou na Netlify chamando-a. E as
convenções de cada plataforma, as pastas e o arquivo de configuração, são dela, então **mudar de uma
para a outra é uma pequena migração, não uma cópia.**
