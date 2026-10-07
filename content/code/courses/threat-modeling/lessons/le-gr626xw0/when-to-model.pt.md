---
title: Quando fazer, e quanto
version: 1
---

O erro comum é tratar a modelagem de ameaças como uma fase: feita uma vez, no começo, assinada,
arquivada. Um sistema muda toda semana, e um modelo do sistema do ano passado descreve um prédio
que desde então ganhou dois andares. **A resposta para "quando" é: sempre que o projeto muda de um
jeito que importa para a segurança, e o mais cedo possível nessa mudança, assim que ela puder ser
desenhada.**

### Os momentos que pedem um modelo

| momento | o que modelar |
|---|---|
| um sistema novo está sendo projetado | o todo, no nível das partes principais |
| uma funcionalidade traz um tipo novo de dado | onde o dado entra, onde fica guardado, quem pode ler |
| uma funcionalidade traz uma porta de entrada nova | um endpoint novo, um upload novo, uma integração nova com o sistema de outra empresa |
| a confiança muda | um papel novo, um parceiro novo com acesso, um serviço movido para outra rede ou outra empresa |
| uma dependência muda | uma biblioteca nova que interpreta entrada não confiável, um fornecedor novo que recebe dados pessoais |
| depois de um incidente | a parte do projeto que deixou acontecer, e as vizinhas |

A maioria das mudanças não dispara nenhum desses. Uma cor nova na página de agendamento não
dispara. Um campo no formulário de agendamento que pede o número do convênio do paciente dispara,
porque traz um dado pessoal novo para o sistema e o projeto precisa dizer para onde ele vai.

### Quanto basta

**Proporcional ao que está em jogo e ao que mudou.** Um sistema novo que vai guardar prontuários
merece uma tarde com as pessoas que vão construí-lo. Um campo novo merece dez minutos na próxima
reunião de refinamento: desenhar o fluxo por onde ele passa, perguntar o que pode dar errado,
anotar a resposta. A aula 15 transforma esse segundo formato numa rotina.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l01-proportional\" aria-label=\"Quanta modelagem uma mudança merece, pelo que está em jogo e pelo quanto mudou. Uma mudança pequena com pouco em jogo, como um campo novo num formulário: dez minutos no próximo refinamento. Uma mudança grande com muito em jogo, como um sistema novo guardando prontuários: uma tarde com as pessoas que vão construí-lo. Entre os dois, uma revisão de projeto curta.\"><defs><marker id=\"l01-proportional-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90.0 220.0 L690.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-proportional-tm-ah-paper-dim)\"></path><path d=\"M90.0 220.0 L90.0 20.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-proportional-tm-ah-paper-dim)\"></path><text x=\"390.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quanto mudou</text><text x=\"30.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">em jogo</text><rect x=\"110.0\" y=\"150.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">dez minutos no refinamento</text><text x=\"205.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um campo novo num formulário</text><rect x=\"300.0\" y=\"95.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"395.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">uma revisão de projeto curta</text><text x=\"395.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um upload ou integração novos</text><rect x=\"490.0\" y=\"35.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">uma tarde com quem constrói</text><text x=\"585.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um sistema novo com dado clínico</text></svg>", "caption": "O esforço segue a mudança, não o calendário. A maioria das mudanças merece dez minutos, e isso continua sendo um modelo de ameaças."}
```

Dois sinais de que um modelo passou do ponto útil:

- **Ele lista ameaças sobre as quais ninguém vai agir.** Uma ameaça sem decisão é ruído, e uma
  lista de duzentas esconde as cinco que importam. A aula 3 conhece uma ferramenta que produz
  exatamente essa lista.
- **Ele é mais detalhado que o projeto.** Um modelo é o desenho de um projeto. Se o projeto diz "o
  portal chama o gateway de pagamento", modelar cada cabeçalho HTTP dessa chamada é chutar uma
  implementação que ainda não existe.

### Antes do código, e também depois

Modelar antes de o código existir é o mais barato, pelo motivo que a seção anterior desenhou. Não
é o único momento em que compensa. Um sistema que nunca foi modelado pode ser modelado agora:
desenhe como ele está, faça as mesmas perguntas, e as falhas que você achar são falhas vivas hoje.
O portal da Vereda está nessa situação. Ele existe, tem pacientes, e ninguém o desenhou pensando
em segurança. É o ponto de partida mais comum que existe, e é dele que este curso parte.
