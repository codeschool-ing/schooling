---
title: O que um bot pode decidir, e o que não pode
version: 1
---

A aula 15 transformou as dependências do linkbox num lock: toda versão fixada, o hash de todo arquivo
anotado, resolvido na data de um dia. Um lock não envelhece bem. No dia seguinte à compilação sai uma
versão nova de algo que está nele; um mês depois um aviso de segurança cita uma das versões dele.
**Alguém precisa continuar propondo o próximo lock**, e esse trabalho é regular, chato e fácil de
esquecer, que é a descrição de um trabalho para um programa.

Os programas que fazem isso se chamam bots de dependências. Os dois que esta aula usa são o
**Dependabot**, do GitHub, e o **Renovate**, da Mend. Os dois leem os arquivos de dependências de um
repositório, perguntam aos índices de pacotes o que há de mais novo e abrem um pull request por
atualização, com os arquivos alterados. O pull request então passa pelo mesmo pipeline que a mudança
de qualquer pessoa.

### A imagem errada

A imagem comum é que o bot corrige vulnerabilidades. Ele não corrige nada. Ele **propõe** uma versão,
e se a proposta está certa é decidido em outro lugar. Um bot que aceitasse as próprias propostas seria
um programa mudando código de produção com base num número de versão, e números de versão são escritos
por desconhecidos.

Então a pergunta útil sobre cada passo da remediação é quem o decide:

| passo | quem decide | como |
|---|---|---|
| existe uma versão mais nova | o bot | ele pergunta ao índice |
| um aviso se aplica a uma versão fixada | um scanner (`pip-audit`, aula 5) | ele compara versões com avisos |
| a mudança está escrita corretamente | o bot, e o pipeline confere | os testes instalam a partir do lock e o build roda |
| a versão nova continua se comportando | os testes, até onde alcançam | a suíte da aula 1, e o que ela não cobre ninguém conferiu |
| o aviso continua sendo um risco sem a atualização | uma pessoa | o portão e as exceções da aula 7 |
| a mudança entra | uma pessoa, ou uma regra escrita por uma pessoa | revisão, ou auto-merge para o que o pipeline consegue julgar |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"sp-l18-loop\" aria-label=\"Quem decide cada passo da remediação de uma dependência. Uma versão nova ou um aviso de segurança é encontrado pelo índice de pacotes ou por um scanner. Um bot propõe uma mudança como pull request. O pipeline a julga com os testes e os portões de segurança; quando quebra, a mudança volta para uma pessoa. Uma pessoa, ou uma regra de auto-merge que uma pessoa escreveu, faz o merge do que passou.\"><defs><marker id=\"sp-l18-loop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l18-loop-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l18-loop-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"30\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">encontrado</text><text x=\"90.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">índice, scanner</text><rect x=\"190\" y=\"30\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">proposto</text><text x=\"270.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o bot</text><rect x=\"370\" y=\"30\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">julgado</text><text x=\"450.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">testes e portões</text><rect x=\"550\" y=\"30\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">aceito</text><text x=\"630.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma pessoa, ou uma regra</text><path d=\"M170 58 L188 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l18-loop-ah-paper-dim)\"></path><path d=\"M350 58 L368 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l18-loop-ah-paper-dim)\"></path><text x=\"270\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">pull request</text><path d=\"M530 58 L548 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l18-loop-ah-phosphor)\"></path><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">passa</text><path d=\"M450 86 L450 130 L270 130 L270 88\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l18-loop-ah-amber)\"></path><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">quebra: uma pessoa assume</text></svg>", "caption": "O bot é dono de uma caixa em quatro. O pipeline decide se a mudança está certa, e uma pessoa decide se ela entra.", "same": ["pull request"]}
```

### O que um bot não tem como saber

**Se a versão nova é segura para rodar.** Um número de versão diz o que o autor afirma ter mudado.
`3.1.8` para `3.1.9` promete uma correção; não promete que nada mais se mexeu, e a aula 12 situou na
cadeia de suprimentos incidentes reais em que a versão nova era o ataque. A data de resolução da
aula 15 e a espera desta aula existem porque a versão mais nova é também a menos examinada.

**Se a atualização importa.** Um bot propõe toda versão com a mesma urgência, o patch de um plugin de
teste e a correção do framework web da mesma forma. Um scanner distingue a segunda da primeira, e a
aula 5 mostrou que até um aviso precisa ser lido antes de alguém saber se ele se aplica.

**Se os seus testes cobrem o que mudou.** O pipeline julga a mudança do bot exatamente tão bem quanto
os testes cobrem o código que usa a dependência. A suíte do linkbox exercita todas as rotas, então uma
atualização do Flask que quebrasse o roteamento falharia nela. Uma mudança no jeito como o gunicorn
trata um cliente lento passaria em todos os testes que o linkbox tem.

**Como o lock foi construído.** É com esse que as próximas seções esbarram de verdade. Uma ferramenta
que edita um número de versão num arquivo que ela não entende escreve uma mudança que parece certa e
não é, e só o pipeline percebe.

### O que esta aula faz

Ela escreve a configuração dos dois bots, a confere no pipeline e observa o que cada um propõe. O
Dependabot só roda no GitHub, então é ensinado a partir da documentação do GitHub e **não foi
executado**, embora o arquivo dele passe pelo zizmor aqui como qualquer workflow. O Renovate tem um
modo que roda na sua própria máquina contra um repositório local e não muda nada, e ele foi executado.
Depois, uma branch com um lock de um mês atrás recebe a correção que um bot proporia, `pip-audit
--fix`, e o pipeline a julga. As duas últimas seções são sobre as pessoas no fim de tudo isso: o que
pode entrar sem elas, e quantos desses pull requests elas conseguem de fato ler.
