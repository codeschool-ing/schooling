---
title: A primeira mensagem para a gestão
version: 1
---

A primeira mensagem para a gestão sai na primeira hora depois da declaração, antes de a maioria das respostas
existir. Ela tem uma tarefa: deixar a sócia-diretora agir agora, com o que se sabe agora. A escrita militar chama o
formato de **BLUF**, *bottom line up front*, a conclusão na frente, e ele funciona porque um leitor ocupado pode
parar depois da primeira frase:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma mensagem para a gestão em cinco partes, de cima para baixo: a conclusão primeiro, numa frase; o que se sabe, como fatos com horário; o que ainda não se sabe; o que a equipe está fazendo e o que precisa ser decidido; e quando vem a próxima atualização.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">a conclusão</text><text x=\"400\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma frase, primeiro</text><rect x=\"10\" y=\"62\" width=\"700\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o que sabemos</text><text x=\"400\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">fatos, com horário</text><rect x=\"10\" y=\"114\" width=\"700\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o que ainda não sabemos</text><text x=\"400\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dito com clareza</text><rect x=\"10\" y=\"166\" width=\"700\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o que estamos fazendo, o que precisamos</text><text x=\"400\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">decisões pedidas pelo nome</text><rect x=\"10\" y=\"218\" width=\"700\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">próxima atualização</text><text x=\"400\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um horário, não 'em breve'</text></svg>", "caption": "As mesmas cinco partes em toda atualização, para quem lê saber sempre onde olhar."}
```

Para a quinta, às 09:30, poderia ficar assim:

> **Assunto: INC-2026-014, incidente declarado, 09:12**
>
> Alguém de fora da empresa entrou ontem à noite no nosso servidor de acesso remoto com a conta do bruno, chegou
> ao servidor de arquivos, e cerca de 612 MB saíram da empresa para um endereço que não conhecemos, a partir das
> 02:41.
>
> O que sabemos: o login veio de 203.0.113.66 às 02:33, depois de 57 senhas tentadas contra 19 contas. A mesma
> conta entrou de novo às 03:05 com uma chave adicionada durante a noite. O bruno estava em casa e entrou
> normalmente às 08:35, então não foi ele.
>
> O que ainda não sabemos: quais arquivos eram os 612 MB, e se algum deles tem dados pessoais de clientes.
>
> O que estamos fazendo: contendo, a partir das 09:30: cortando o acesso do servidor de arquivos à internet, menos
> o backup, e bloqueando a conta do bruno. **Precisamos da sua decisão sobre o bloqueio da conta**, porque ele
> impede o bruno de trabalhar hoje. Já avisamos o advogado externo e o encarregado.
>
> Próxima atualização: 12:00, ou antes se algo mudar.

Repare no que não está nela. Nenhum jargão em que um não especialista tropeçaria; "servidor de acesso remoto", não
`gw`. Nenhum palpite apresentado como fato: "cerca de 612 MB" é medido, "quais arquivos" é dito como desconhecido.
Nenhuma culpa: nada sobre a força da senha do bruno. E nenhuma tranquilização que ainda não é verdade: "não há
evidência de perda de dados de clientes" estaria correto nesta manhã e é a frase de que mais se arrependem em
relatórios de incidente, porque ausência de evidência às 09:30 não é evidência de ausência.
