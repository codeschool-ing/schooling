---
title: Do adjetivo ao número
version: 1
---

"Tem que ser rápido" é um desejo, e nenhum teste consegue reprová-lo. Rápido para quem, fazendo o
quê, com quantas outras pessoas fazendo a mesma coisa ao mesmo tempo? Um teste de carga rodado contra
essa frase produz uma página de números, e a reunião que os lê decide depois se eram bons, o que
quer dizer que o teste não decidiu nada. **Um requisito não funcional é testável quando alguém
consegue ler o resultado e dizer *reprovou* sem perguntar a ninguém o que se quis dizer.**

## As cinco partes

Um requisito de desempenho que pode reprovar tem cinco partes, e deixar qualquer uma de fora é o
jeito comum de ele deixar de ser testável:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l01-anatomy\" aria-label=\"Um requisito cortado nas suas cinco partes. A operação: GET /shows/{id}. A estatística: o percentil 95 do tempo de resposta, e a taxa de erro. O limite: abaixo de 200 ms, e abaixo de 1%. A carga: 50 requisições por segundo. As condições: sustentada por 10 minutos, medida no cliente, na máquina de homologação. Sem qualquer uma das partes, ninguém consegue dizer se um resultado reprova.\"><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">uma frase que um teste consegue reprovar</text><rect x=\"20.0\" y=\"60.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">operação</text><rect x=\"20.0\" y=\"108.0\" width=\"120.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"80.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /shows/{id}</text><rect x=\"152.0\" y=\"60.0\" width=\"126.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"215.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">estatística</text><rect x=\"152.0\" y=\"108.0\" width=\"126.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"215.0\" y=\"139.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">percentil 95</text><text x=\"215.0\" y=\"152.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">taxa de erro</text><rect x=\"290.0\" y=\"60.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">limite</text><rect x=\"290.0\" y=\"108.0\" width=\"120.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"350.0\" y=\"139.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt; 200 ms</text><text x=\"350.0\" y=\"152.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt; 1%</text><rect x=\"422.0\" y=\"60.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"482.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">carga</text><rect x=\"422.0\" y=\"108.0\" width=\"120.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"482.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">50 req/s</text><rect x=\"554.0\" y=\"60.0\" width=\"146.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"627.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">condições</text><rect x=\"554.0\" y=\"108.0\" width=\"146.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"627.0\" y=\"132.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">10 minutos</text><text x=\"627.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">medido no cliente</text><text x=\"627.0\" y=\"159.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">homologação</text><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">tire uma parte e o resultado precisa de uma reunião para ser lido</text></svg>", "caption": "As cinco partes de um requisito de desempenho. Cada uma é um lugar onde o \"rápido\" se escondia."}
```

1. **A operação.** Não "o site", e sim uma coisa que um usuário faz: `GET /shows/{id}`, o `POST` da
   reserva, a busca. Operações diferentes custam diferente, e uma média de todas esconde a cara
   atrás das baratas.
2. **A estatística.** Qual número é comparado: o percentil 95 do tempo de resposta, a taxa de erro,
   a vazão. "O percentil 95" é o tempo abaixo do qual ficam 95 de cada 100 requisições. A aula 8
   mostra por que o percentil, e não a média, é a estatística que se escreve.
3. **O limite.** 200 ms, 1%, 50 requisições por segundo. Um número com unidade.
4. **A carga.** Quantas requisições por segundo, ou quantas pessoas ao mesmo tempo, chegando de que
   jeito. Um sistema que responde em 30 ms com um usuário pode responder em três segundos com
   duzentos, e as duas coisas são verdade.
5. **As condições.** Por quanto tempo, em qual ambiente, medido onde. Dez minutos numa máquina do
   tamanho da produção, medidos no cliente, é uma afirmação diferente de trinta segundos num notebook,
   medidos no log do servidor.

Juntas, as partes transformam o desejo numa frase que um teste consegue segurar:

> `GET /shows/{id}`: percentil 95 abaixo de 200 ms e erros abaixo de 1%, a 50 requisições por
> segundo sustentadas por 10 minutos, medido no cliente, na máquina de homologação.

## O mesmo movimento para os outros três

Acessibilidade e segurança têm os seus próprios adjetivos, e eles viram números, ou listas com nome,
do mesmo jeito.

| o desejo | algo que um teste consegue reprovar |
|---|---|
| "tem que ser rápido" | a frase acima |
| "a página deve carregar rápido" | Largest Contentful Paint de no máximo 2,5 s no percentil 75 das visitas reais (aula 10) |
| "tem que ser acessível" | conforme à WCAG 2.2 no nível AA no fluxo de reserva (aula 12) |
| "tem que dar para usar sem mouse" | todo controle da página de reserva é alcançado e operado só com o teclado, na ordem de leitura (aula 14) |
| "tem que ser seguro" | nenhum achado classificado como alto ou crítico em aberto na liberação, e o token de um cliente não lê a reserva de outro (aulas 17 e 21) |
| "a gente precisa saber quando quebra" | um alerta chega a quem está de plantão em até 5 minutos depois de a taxa de erro passar de 2% (aula 24) |

Nem toda linha é um número. "Conforme à WCAG 2.2 AA" é uma lista de critérios com nome, publicada e
versionada por outra pessoa, e isso serve ao mesmo propósito: duas pessoas lendo o mesmo resultado
chegam ao mesmo veredito.

## De onde vêm os números

**Um limite é uma decisão, e o teste vale tanto quanto o motivo por trás dela.** Três fontes valem
mais que um chute:

- **O que o sistema faz hoje.** Os logs de produção dão os percentis de hoje e o minuto mais
  movimentado de hoje. Uma versão que mantém o percentil 95 onde ele está, na carga que já enfrenta,
  é um requisito que ninguém pode chamar de arbitrário.
- **O que o negócio espera.** A bilheteria deste curso vende 300 lugares por espetáculo, e um
  espetáculo concorrido abre a venda às 10h. Isso é um pico com tamanho e hora conhecidos, e a aula
  3 o transforma num número de requisições por segundo.
- **O que a pesquisa publicada diz sobre pessoas.** As Core Web Vitals do Google dão limites que
  saíram da medição de visitas reais. São um padrão razoável onde não existe nada melhor, e um
  substituto fraco para o que os seus próprios usuários fazem.

Um requisito que ninguém consegue ligar a uma dessas fontes ainda é melhor que nenhum requisito.
Escreva-o, rode o teste contra ele e conte com mudá-lo quando os primeiros resultados chegarem. O
que não dá é rodar o teste primeiro e escrever o requisito depois, em volta do número que saiu.
