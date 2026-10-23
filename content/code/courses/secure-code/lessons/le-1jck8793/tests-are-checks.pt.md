---
title: Os testes que você já tem são verificações de segurança
version: 1
---

Cada aula deste curso terminou com um teste que enuncia uma recusa: um paciente não cancela o
agendamento de outro, uma data impossível é recusada, um campo que o formulário nunca teve não é
guardado, um valor é escapado para o lugar onde é escrito. **Esses testes são as primeiras e
melhores verificações automáticas de segurança do projeto**, porque dizem o que esta aplicação em
particular deve recusar, e nenhuma ferramenta genérica tem como saber isso.

São também o tipo de verificação mais barato de manter. Um teste roda numa fração de segundo, falha
com uma frase que diz o que quebrou, e continua funcionando depois que todos os que lembram da falha
original foram embora. Essa última propriedade é a que importa para a segurança: **uma falha que foi
corrigida uma vez e tem um teste não volta em silêncio.**

### O que faz um teste de segurança valer a pena

| um bom teste de segurança | um fraco |
|---|---|
| enuncia uma recusa: *um paciente não lê a mensagem 2* | só diz que a funcionalidade funciona |
| usa o valor que importa naquele contexto: uma aspa num atributo, 31 de novembro | usa dados comuns, que toda versão aprova |
| verifica o que foi recusado **e** que nada mudou (`BOOKINGS[102]` ainda marcado) | verifica só um código de status |
| tem um nome que se lê como o requisito | se chama `test_cancel_2` |

A segunda coluna é como a maioria das suítes de teste parece, e é por isso que um projeto pode ter
cobertura alta e ainda assim lançar a falha da aula 1. Cobertura mede quais linhas rodaram, não
quais recusas foram pedidas.

### Mais dois tipos de verificação

Os testes conhecem a aplicação e mais nada. Dois outros tipos de ferramenta conhecem o contrário: o
que é arriscado em **qualquer** programa Python, e o que está publicado sobre **qualquer** pacote.
Esta aula acrescenta uma de cada e roda as três de um comando só.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l19-layers\" aria-label=\"Três verificações automáticas e o que cada uma lê. O pytest roda os testes, que dizem o que a aplicação deve fazer e deve recusar. O bandit lê o código-fonte sem executá-lo e aponta chamadas sabidamente arriscadas. O pip-audit lê a lista de dependências e aponta alertas publicados. As três rodam de um comando, check.sh, antes de todo commit. O que nenhuma delas lê é se uma rota verifica de quem é o dado que entrega, e isso fica com a revisão da aula 18.\"><defs><marker id=\"l19-layers-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"260\" y=\"14\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">check.sh</text><text x=\"475\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">um comando, antes de todo commit</text><rect x=\"20\" y=\"100\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pytest</text><rect x=\"20\" y=\"150\" width=\"210\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"168.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">os testes: o que deve funcionar,</text><text x=\"125.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">e o que deve ser recusado</text><path d=\"M360 54 L360 84 L125 84 L125 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-layers-ah-paper-dim)\"></path><rect x=\"255\" y=\"100\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">bandit</text><rect x=\"255\" y=\"150\" width=\"210\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"168.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o código: chamadas</text><text x=\"360.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sabidamente arriscadas</text><path d=\"M360 54 L360 84 L360 84 L360 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-layers-ah-paper-dim)\"></path><rect x=\"490\" y=\"100\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pip-audit</text><rect x=\"490\" y=\"150\" width=\"210\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"168.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">as dependências:</text><text x=\"595.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">alertas publicados</text><path d=\"M360 54 L360 84 L595 84 L595 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-layers-ah-paper-dim)\"></path><text x=\"360\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nenhuma pergunta de quem é o dado que uma rota entrega</text></svg>", "caption": "Três ferramentas, três coisas lidas. Cada uma acha o que as outras duas não veem."}
```

A pasta desta aula é `~/sc/checks`; crie a pasta e o repositório como antes:

```
(.venv) ana@vm:~/sc$ mkdir checks
(.venv) ana@vm:~/sc$ cd checks
(.venv) ana@vm:~/sc/checks$ git init -b main
Initialized empty Git repository in /home/ana/sc/checks/.git/
```
