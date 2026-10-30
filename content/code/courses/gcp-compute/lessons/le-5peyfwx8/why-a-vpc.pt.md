---
title: Por que um serviço serverless precisa de rede
version: 1
---

A imagem comum do Cloud Run é a de um contêiner solto de qualquer rede sua, e para um serviço que
só responde à internet essa imagem está certa. **Ela deixa de estar certa no momento em que o
serviço precisa alcançar algo com endereço privado**: um banco num IP privado, um cache, uma API
interna numa máquina virtual. Essas coisas moram dentro de uma VPC, e uma instância do Cloud Run,
por padrão, não.

## Onde uma instância roda de fato

Uma instância do Cloud Run roda na infraestrutura do Google, na região que você escolheu, numa
rede que o Google gerencia. Ela alcança a internet, e por ela toda API pública do Google. O que ela
não alcança é um endereço em `10.0.0.0/8`, `172.16.0.0/12` ou `192.168.0.0/16` dentro da VPC do
seu projeto, porque não existe rota da rede do Google para a sua. Uma conexão para `10.20.0.3:5432`
simplesmente expira, e esse é o primeiro sintoma que uma equipe encontra: o serviço sobe, responde
à verificação de saúde e trava na primeira consulta.

O serviço orders da lição 8 é exatamente esse caso na loja. O banco dele é um PostgreSQL que só
tem endereço privado, `10.20.0.3` na sub-rede `shop-data`, porque um banco com endereço público é
um banco que alguém acaba encontrando. O serviço precisa de um caminho para dentro da VPC `shop`, e
só do lado da saída: as requisições continuam chegando de fora, enquanto as conexões que o próprio
serviço abre vão para dentro da VPC.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"À esquerda, uma instância do Cloud Run na rede gerenciada do Google, com uma seta para a internet. À direita, a VPC shop com a sub-rede shop-run, um conector na faixa 10.8.0.0/28 e o banco em 10.20.0.3. Duas rotas tracejadas ligam a instância à VPC: a saída direta, para dentro da sub-rede, e o conector, que repassa o tráfego.\"><defs><marker id=\"l12p-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"230\" height=\"268\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"28\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">rede gerenciada pelo Google</text><rect x=\"40\" y=\"108\" width=\"180\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">instância do Cloud Run</text><text x=\"130\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">orders</text><rect x=\"40\" y=\"220\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">internet, APIs do Google</text><path d=\"M130 156 L130 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12p-ah)\"></path><rect x=\"474\" y=\"16\" width=\"230\" height=\"268\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"486\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">VPC shop</text><rect x=\"490\" y=\"52\" width=\"198\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"589\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sub-rede shop-run</text><text x=\"589\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.1.0/26</text><rect x=\"490\" y=\"138\" width=\"198\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"589\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">conector</text><text x=\"589\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.8.0.0/28</text><rect x=\"490\" y=\"212\" width=\"198\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"589\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">banco de dados</text><text x=\"589\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.0.3:5432</text><path d=\"M250 118 L486 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l12p-ah)\"></path><text x=\"354\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">saída direta para a VPC</text><path d=\"M250 140 L486 166\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l12p-ah)\"></path><text x=\"354\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">por um conector</text></svg>", "caption": "Uma instância não tem rota para a VPC até a revisão ganhar uma. A saída direta põe a própria instância numa sub-rede; o conector põe ali máquinas que repassam por ela.", "same": ["VPC shop"]}
```

## Dois caminhos

O Google oferece dois, e as próximas duas seções tratam de um cada:

- **A saída direta para a VPC** dá a cada instância do Cloud Run um endereço numa sub-rede da sua
  VPC. O tráfego sai da instância já dentro da rede. Não há nada a mais para rodar nem nada a mais
  na conta além do próprio tráfego.
- **Um conector de Serverless VPC Access** é um pequeno grupo de máquinas virtuais que o Google
  roda na sua VPC, numa faixa `/28` própria. O serviço manda o tráfego para o conector e o conector
  repassa. É o mecanismo mais antigo, é cobrado como as máquinas que roda, e ainda tem usos que a
  seção 04 nomeia.

Os dois são propriedade do **modelo de revisão** do serviço, não do serviço como um todo, o que
importa para a lição 9: uma revisão nova pode trocar o conector pela saída direta, e o tráfego pode
ser dividido entre as duas enquanto você observa.

## O que a rede não muda

Alcançar a VPC muda para onde o tráfego de saída pode ir. Não muda quem pode chamar o serviço, que
é a entrada e o assunto da seção 05, e não dá ao serviço uma identidade no banco. Um endereço
privado é uma rota, não uma permissão: o banco continua precisando de usuário e senha, ou de
autenticação de banco por IAM, e o serviço continua precisando da própria conta de serviço. A lição
15 faz o mesmo argumento para pods.

Nada disso roda no laboratório, porque não há VPC a alcançar nem Cloud Run de onde alcançar. O que
roda é a configuração, e as próximas seções a escrevem e deixam o Terraform conferir.
