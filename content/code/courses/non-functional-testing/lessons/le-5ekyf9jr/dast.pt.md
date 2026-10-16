---
title: Uma varredura DAST, e como ler o relatório dela
version: 1
---

O pip-audit lê uma lista de pacotes. Um scanner **DAST**, a análise dinâmica da tabela da aula 16,
não lê nada seu: ele conversa com a aplicação rodando por HTTP, como um navegador faz, e relata o que
as respostas entregam. O gratuito que a maioria das equipes encontra primeiro é o **OWASP ZAP**, o
Zed Attack Proxy, hoje publicado só como ZAP, e o modo mais suave dele é o melhor para começar.

## Permissão primeiro

Uma varredura DAST manda centenas ou milhares de requisições, e alguns dos modos dela mandam
requisições feitas para fazer uma aplicação se comportar mal. **Apontar uma para um sistema que não é
seu, sem a permissão escrita do dono, é crime**, no Brasil pelo artigo 154-A do Código Penal e em
outros lugares por leis como as que a aula 16 citou, por mais inofensiva que seja a intenção. No
trabalho ela é apontada para uma cópia de homologação que você está autorizado a testar, nunca para
a produção a menos que o escopo diga isso por escrito, e nunca para os serviços que o seu sistema
chama.

## A varredura baseline

A **varredura baseline** do ZAP é feita para ser segura de rodar com frequência. Ela percorre o site
por um minuto, a partir do endereço que recebe, e roda só regras **passivas**: olha as requisições e
respostas que o percurso produziu e não ataca nada. É o que um pipeline roda contra a homologação
depois de cada implantação. O ZAP a publica como uma imagem de contêiner, e a linha de costume é:

```sh
docker run --rm -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://staging.boxoffice.example
```

**Isso não foi executado para este curso**, porque o computador da gravação não alcança a imagem do
ZAP, e por isso nenhuma saída aparece aqui: um relatório inventado ensinaria você a ler um relatório
que não existe. O que vem a seguir é o que um relatório contém, para que você consiga ler o seu.

As regras passivas dele procuram o mesmo tipo de coisa que a aula 19 conferiu à mão no `account.py`:
cabeçalhos de segurança faltando, cookies sem as suas flags, uma página de erro que mostra um stack
trace, um cabeçalho `Server` dizendo o software e a versão, e informação esquecida em comentários e
páginas. A **varredura completa** acrescenta regras ativas, que mandam requisições de sondagem, e é
para um teste autorizado de um ambiente que aguente ser perturbado.

## Lendo o relatório

O ZAP agrupa o que achou em **alertas**, um por tipo de problema, e cada alerta traz três coisas que
precisam ser lidas juntas.

| campo | o que diz | como usar |
|---|---|---|
| **risco** | High, Medium, Low ou Informational: quão grave seria se for real | a primeira ordenação, nunca o veredito |
| **confiança** | quão segura a regra está de que é real, de Low a High | um risco alto com confiança baixa é uma pergunta a responder, não um incêndio |
| **instâncias** | cada URL onde ele foi visto | uma causa por trás de cinquenta páginas é uma correção, não cinquenta achados |

Cada alerta também nomeia um **CWE**, o tipo de fraqueza num catálogo compartilhado, uma descrição,
uma solução sugerida e referências. Os mesmos hábitos do relatório de dependências valem, com uma
diferença: aqui o scanner viu as respostas reais da sua aplicação, então um achado é evidência sobre
esta implantação e não sobre uma biblioteca.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l21-alert\" aria-label=\"Uma grade com o risco de um alerta DAST na lateral, alto, médio e baixo, e a confiança da regra no topo, baixa, média e alta. No canto superior direito, risco alto e confiança alta: confirme e corrija antes da entrega. Na coluna de confiança alta a urgência cai com o risco. Na coluna de confiança baixa toda célula diz confirme à mão primeiro. Alertas informativos ficam abaixo da grade: lidos, não registrados.\"><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">risco e confiança se leem juntos</text><text x=\"425.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">confiança</text><text x=\"70.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">risco</text><text x=\"255.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">baixa</text><text x=\"425.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">média</text><text x=\"595.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">alta</text><text x=\"158.0\" y=\"95.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">alto</text><rect x=\"172.0\" y=\"72.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"255.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirme à mão primeiro</text><rect x=\"342.0\" y=\"72.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"425.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirme, depois corrija</text><rect x=\"512.0\" y=\"72.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"595.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">corrija antes da entrega</text><text x=\"158.0\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">médio</text><rect x=\"172.0\" y=\"122.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"255.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirme à mão primeiro</text><rect x=\"342.0\" y=\"122.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"425.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirme, depois planeje</text><rect x=\"512.0\" y=\"122.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"595.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">planeje a correção</text><text x=\"158.0\" y=\"195.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">baixo</text><rect x=\"172.0\" y=\"172.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"255.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirme à mão primeiro</text><rect x=\"342.0\" y=\"172.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"425.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">anote</text><rect x=\"512.0\" y=\"172.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"595.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">corrija quando der</text><rect x=\"172.0\" y=\"234.0\" width=\"506.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"425.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">informativo: lido, não registrado</text></svg>", "caption": "O risco de um alerta diz quão grave seria; a confiança diz quão segura a regra está. Nenhum dos dois decide sozinho."}
```

**Conte causas, não linhas.** Um cabeçalho faltando em toda página aparece como um alerta com tantas
instâncias quantas o percurso visitou; corrigido uma vez, no código que envia cabeçalhos, todas
somem. Um relatório de quarenta alertas muitas vezes são seis causas.

**Confirme antes de registrar.** Peça você mesmo a URL que a instância aponta e veja o que voltou.
Uma regra que marcou uma página por mostrar um erro pode ter casado com uma palavra do texto. Se foi
um verdadeiro positivo ou um falso é o vocabulário da aula 11 de `security-fundamentals`. Um falso
positivo é registrado como tal, com o motivo, na configuração de regras da varredura, do jeito que o
`audit.sh` registra um risco aceito, para que a próxima varredura não pergunte de novo.

**Depois classifique-o no seu próprio contexto**, como qualquer achado, e a regra da aula 1 vale na
entrega: nenhum alto ou crítico em aberto.

O que uma varredura DAST não consegue dizer é de quem é a reserva que um cliente pode ler. Ela vê
respostas; não sabe que um `200` para a reserva de outra pessoa está errado, e é por isso que as
aulas 16 e 17 escreveram esses testes à mão.
