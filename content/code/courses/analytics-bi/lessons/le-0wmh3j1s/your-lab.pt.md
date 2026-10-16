---
title: O seu laboratório, e três jeitos de tê-lo
version: 1
---

Este curso se aprende digitando. Toda aula mostra uma consulta e o que voltou, e o motivo de
mostrar o que voltou é você rodar a mesma consulta e comparar. **A plataforma não roda um banco
para você**, e nada neste curso precisa de algo que você mesmo não instalou.

O que você precisa, até o fim da aula 5, é uma máquina com quatro programas: PostgreSQL,
Metabase, um ambiente Python para o Streamlit, e um jeito de chegar até eles pelo seu terminal e
pelo seu navegador. Esta aula monta o primeiro; as aulas 3 e 5 acrescentam os outros dois na
mesma máquina.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"lab-ports\" aria-label=\"Duas caixas. À esquerda, o seu computador, com um terminal e um navegador. À direita, a máquina virtual onde roda o Ubuntu, com o PostgreSQL na porta 5432, o servidor SSH na porta 22, o Metabase na porta 3000 e o Streamlit na porta 8501. Três setas cruzam da esquerda para a direita: o terminal chega ao SSH pela porta encaminhada 2222, e o navegador chega ao Metabase pela 3000 e ao Streamlit pela 8501. O PostgreSQL não recebe seta de fora: só programas de dentro da máquina falam com ele.\"><defs><marker id=\"lab-ports-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"230\" height=\"240\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">o seu computador</text><rect x=\"45\" y=\"80\" width=\"180\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">terminal</text><text x=\"135\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ssh -p 2222 ana@localhost</text><rect x=\"45\" y=\"160\" width=\"180\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">navegador</text><text x=\"135\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost:3000</text><text x=\"135\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost:8501</text><rect x=\"410\" y=\"30\" width=\"290\" height=\"240\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"555\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">a máquina virtual (Ubuntu)</text><rect x=\"440\" y=\"62\" width=\"230\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">servidor SSH</text><text x=\"655\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:22</text><rect x=\"440\" y=\"112\" width=\"230\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Metabase</text><text x=\"655\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:3000</text><rect x=\"440\" y=\"162\" width=\"230\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Streamlit</text><text x=\"655\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:8501</text><rect x=\"440\" y=\"212\" width=\"230\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">PostgreSQL</text><text x=\"655\" y=\"230\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:5432</text><line x1=\"225\" y1=\"107\" x2=\"438\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#lab-ports-ah)\"></line><text x=\"330\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2222 → 22</text><line x1=\"225\" y1=\"200\" x2=\"438\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#lab-ports-ah)\"></line><text x=\"318\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3000</text><line x1=\"225\" y1=\"218\" x2=\"438\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#lab-ports-ah)\"></line><text x=\"330\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8501</text><path d=\"M672 130 L688 130 L688 230 L674 230\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" marker-end=\"url(#lab-ports-ah)\"></path><text x=\"320\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-style=\"italic\">nada de fora chega à 5432</text></svg>", "caption": "Tudo roda dentro da máquina virtual; o terminal e o navegador ficam no seu computador e entram por três portas encaminhadas.", "same": ["Metabase", "Streamlit", "PostgreSQL", "terminal"]}
```

## Numa máquina virtual — o caminho recomendado

Uma **máquina virtual** é um computador inteiro simulado dentro do seu, com sistema operacional
próprio, que você pode quebrar e jogar fora sem mexer em mais nada. Rode o **Ubuntu Server 24.04
LTS** numa delas e você tem exatamente o sistema em que este curso foi gravado.

**Se você fez `sql-databases`, já tem essa máquina.** A aula 1 de lá a montou, com o PostgreSQL 16
e um papel com o seu nome. Ligue-a e pule para o `createdb lantern` da próxima seção.

Senão, o programa que roda a máquina é um **hipervisor**:

| o seu computador | hipervisor | custo |
|---|---|---|
| Windows, Linux, ou um Mac com processador Intel | VirtualBox, de virtualbox.org | grátis |
| um Mac com Apple silicon (M1 em diante) | UTM, de mac.getutm.app | grátis |

1. Instale o hipervisor e baixe a imagem de instalação do Ubuntu Server 24.04 LTS em ubuntu.com.
   No Apple silicon, pegue a versão ARM; em todo o resto, a marcada `amd64`.
2. Crie uma máquina a partir dessa imagem com **2 processadores, 4 GB de memória e 25 GB de
   disco**. O PostgreSQL sozinho viveria em 2 GB, mas o Metabase, da aula 3, é um programa Java
   que ocupa sozinho uma boa parte da memória, e a aula 3 mede quanto.
3. Ligue-a e aceite os padrões do instalador, com uma exceção: na tela que oferece **Install
   OpenSSH server**, marque. Ele pede o seu nome, um nome para o servidor e um nome de usuário —
   escolha algo de que você vá lembrar.
4. Quando reiniciar, entre. Você está num prompt como `ana@vm:~$`.

## Entrando na máquina

A janela da própria máquina virtual é um lugar ruim para trabalhar: na maioria dos hipervisores
não dá para colar nela, e a aula 1 pede para colar um script de 165 linhas. Então você vai
trabalhar de um terminal no seu computador, ligado à máquina por SSH, e abrir o Metabase e o
Streamlit no seu próprio navegador. A máquina precisa deixar essas três conexões entrarem.

**No VirtualBox**, a máquina fica atrás de uma rede privada dela, e você abre uma porta por
programa. Com a máquina desligada, abra **Settings → Network → Adapter 1 → Advanced → Port
Forwarding** e acrescente três regras:

| nome | porta do computador | porta da máquina |
|---|---|---|
| ssh | 2222 | 22 |
| metabase | 3000 | 3000 |
| streamlit | 8501 | 8501 |

Depois, de um terminal no seu computador — o Terminal no Mac, o PowerShell ou o Windows Terminal
no Windows — conecte com `ssh -p 2222 ana@localhost`, usando o seu usuário. Os endereços no
navegador são `http://localhost:3000` e `http://localhost:8501`.

**No UTM**, a rede padrão dá à máquina um endereço que o Mac alcança direto. Pergunte à máquina
qual é com `hostname -I` e use esse endereço no lugar de `localhost`: `ssh ana@192.168.64.5`,
`http://192.168.64.5:3000`. Não precisa de encaminhamento.

**O que custa ao seu computador:** 4 GB de memória enquanto a máquina roda, e o disco que ela vai
ocupando — alguns gigabytes para o Ubuntu, mais o que o Metabase e o Streamlit acrescentam, que as
aulas 3 e 5 medem quando os instalam.

> **O seu prompt não vai dizer `ana@vm`.** Neste curso `ana` é a usuária e `vm` é a máquina; na
> sua, são os nomes que você escolheu. Todo comando é o mesmo.

## Instalado direto no seu computador

Se o seu computador **já roda Ubuntu ou Debian**, pule a máquina virtual e o encaminhamento: todo
comando deste curso funciona nele como está impresso, e os endereços são `localhost`. É o caminho
mais barato que existe.

No **macOS** e no **Windows**, os três programas instalam nativamente — o PostgreSQL pelo
postgresql.org ou pelo Postgres.app, o Metabase como arquivo Java ou contêiner Docker, o
Streamlit pelo `pip` do Python. Custa algumas centenas de megabytes e um servidor de banco rodando
em segundo plano. O que não vem junto são os mesmos passos: cada instalador cria o primeiro
usuário do banco do seu jeito, então a configuração da próxima seção não vai bater com o que você
vê. Tudo depois dela, que é SQL, vai.

## Online, no servidor de outra pessoa

Serviços de PostgreSQL hospedado dão um banco e um endereço para conectar, e vários têm plano
gratuito. **Não custa nada ao seu computador**, e exige conta e conexão. Também cobre só o
primeiro dos quatro programas: o Metabase e o Streamlit ainda precisariam de uma máquina sua, ou
de um plano hospedado próprio.

Use para começar se os outros dois estiverem fora de alcance hoje, e planeje sair. Plano gratuito
é oferta de empresa, ofertas mudam de termos, e nenhuma aula deste curso depende de provedor
nenhum.

## Qual escolher

A máquina virtual, a não ser que o seu computador já rode Ubuntu. Custa uma tarde, uma vez, e
compra a única propriedade que os outros não têm: **quando a sua tela e a transcrição discordam, a
diferença está no que você digitou**, e não em qual sistema você está.
