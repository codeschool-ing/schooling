---
title: De onde vêm os endereços
version: 1
---

Todo aparelho numa rede precisa de um número, do mesmo jeito que toda casa numa rua precisa de um.
Há dois tipos de número numa casa, e confundi-los está por trás da maioria das perguntas que se
fazem sobre endereço IP.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 306\" role=\"img\" aria-label=\"Um diagrama de uma rede doméstica. No alto, a rua, levando um endereço público. Abaixo dela o roteador, com o endereço um nove dois ponto um seis oito ponto zero ponto um. Quatro linhas descem do roteador até um notebook, um celular, uma televisão e uma impressora, cada um com o seu endereço privado terminando em quatorze, quinze, vinte e dois e trinta.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Um endereço para fora, muitos para dentro</text><rect x=\"24\" y=\"40\" width=\"672\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a rua</text><text x=\"676\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">187.4.22.91</text><path d=\"M360 80 L360 118\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><rect x=\"260\" y=\"118\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"133\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o roteador</text><text x=\"280\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">192.168.0.1</text><text x=\"24\" y=\"180\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dentro de casa, alcançáveis de lugar nenhum</text><path d=\"M360 162 L360 196 L102 196 L102 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><rect x=\"24\" y=\"214\" width=\"156\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"229\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">notebook</text><text x=\"40\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">192.168.0.14</text><path d=\"M360 162 L360 196 L274 196 L274 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><rect x=\"196\" y=\"214\" width=\"156\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"212\" y=\"229\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">celular</text><text x=\"212\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">192.168.0.15</text><path d=\"M360 162 L360 196 L446 196 L446 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><rect x=\"368\" y=\"214\" width=\"156\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384\" y=\"229\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">televisão</text><text x=\"384\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">192.168.0.22</text><path d=\"M360 162 L360 196 L618 196 L618 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><rect x=\"540\" y=\"214\" width=\"156\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"556\" y=\"229\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">impressora</text><text x=\"556\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">192.168.0.30</text><text x=\"24\" y=\"286\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">A casa do lado está usando os mesmos quatro números, e pacote nenhum jamais confundiu os dois.</text></svg>", "caption": "O roteador é o único aparelho da casa com endereço dos dois lados. Todo o resto tem um endereço e nenhuma ideia de que existe outro lado."}
```

## Um endereço para fora, muitos para dentro

Seu provedor dá à sua linha **um endereço público** — aquele que o resto da internet consegue
alcançar. Dentro de casa, o roteador distribui **endereços privados**, de faixas reservadas
exatamente para isso e alcançáveis de lugar nenhum:

- `192.168.0.0` a `192.168.255.255` — de longe o mais comum em casa;
- `10.0.0.0` a `10.255.255.255` — comum em escritórios e em caixas de alguns provedores;
- `172.16.0.0` a `172.31.255.255` — o que ninguém lembra.

**Toda casa da sua rua está usando os mesmos números**, e tudo bem, porque esses números nunca
saem de casa. `192.168.0.14` no seu apartamento e `192.168.0.14` no vizinho são duas máquinas
diferentes que jamais vão ouvir falar uma da outra.

O roteador é o que faz isso funcionar. Quando seu notebook pede uma página, o roteador troca o
endereço privado pelo público na saída, anota que fez isso, e põe o endereço privado de volta na
resposta que chega. Essa tradução é por que um endereço serve vinte aparelhos, e é a razão de um
aparelho de dentro conseguir começar uma conversa com o lado de fora enquanto o lado de fora não
consegue começar uma com um aparelho de dentro.

## DHCP, que é a distribuição

Ninguém digita esses números. **DHCP** é o serviço — rodando no roteador — que responde a um
aparelho dizendo *sou novo aqui, qual é o meu endereço?* com um endereço, um prazo de validade, e
as outras duas coisas de que um aparelho precisa: qual endereço é o próprio roteador, e qual
endereço responde perguntas de nome.

O prazo de validade se chama **concessão**, e é por isso que um endereço pode mudar. Um celular
que ficou fora uma semana volta e pode receber outro número, o que é inofensivo para um celular e
não é inofensivo para uma impressora.

**Então algumas coisas querem endereço fixo:** uma impressora, um disco de rede, uma câmera,
qualquer coisa que outro aparelho esteja configurado para achar por número. O jeito certo de fixar
um é uma **reserva de DHCP** no roteador — *este aparelho recebe sempre este endereço* — em vez de
digitar um endereço fixo dentro do aparelho. A reserva mantém o roteador informado; um endereço
digitado à mão é um número que o roteador não sabe que tem de evitar.

## DNS, num parágrafo

Nada numa rede é achado por nome. **DNS** é o serviço que transforma `codeschool.ing` num
endereço, e ele roda em algum lugar rio acima — em geral no seu provedor, às vezes num resolvedor
público como o `1.1.1.1` da Cloudflare ou o `8.8.8.8` do Google.

Vale saber por causa de um sintoma específico: **quando o DNS falha, tudo parece quebrado e nada
está.** A linha funciona, o roteador funciona, o Wi-Fi funciona, e todo nome deixa de resolver,
então todo navegador diz que não achou o site. Testar um endereço direto — uma página que responde
no número dela — separa os dois em uns dez segundos.
