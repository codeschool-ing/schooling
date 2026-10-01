---
title: Comparando com o que deveria estar rodando
version: 1
---

O histórico compara a rede com ela mesma. **A outra comparação é com a intenção**: os dados e o
template da aula 10, renderizados, contra o backup. Primeiro um `diff` simples:

```
ana@ctl:~$ cd net && python render.py > /dev/null && diff configs/edge1.conf backups/edge1.conf
0a1,2
> 
> !
6a9,10
> ip route 192.0.2.128/25 198.51.100.1
> !
14c18
<  description branch LAN
---
>  description guest wifi
```

Duas das diferenças são reais, a rota e a descrição. **As duas primeiras linhas não são**: a linha
em branco e o `!` são o que o FRR imprime antes de a configuração começar, e o backup os manteve de
propósito. Um diff simples de texto não tem como saber quais linhas significam algo, e em outras
plataformas o ruído é pior: um timestamp da última mudança, uma linha cuja posição muda, uma seção
impressa em outra ordem depois de um upgrade.

Uma comparação que entende a estrutura da configuração se sai melhor. A `netutils`, uma biblioteca
de utilitários de rede, tem uma que lê a configuração como seções, `interface eth2` com as suas
linhas embaixo, e pergunta quais linhas de uma estão ausentes da outra:

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "import pathlib\nimport sys\n\nfrom netutils.config.compliance import diff_network_config\n\nhost = sys.argv[1]\nintended = pathlib.Path(f\"configs/{host}.conf\").read_text()\nactual = pathlib.Path(f\"backups/{host}.conf\").read_text()"
    },
    {
      "code": "missing = diff_network_config(intended, actual, \"cisco_ios\")\nextra = diff_network_config(actual, intended, \"cisco_ios\")\nprint(f\"{host}, missing from the router:\\n{missing or '(nothing)'}\")\nprint(f\"{host}, on the router and not intended:\\n{extra or '(nothing)'}\")",
      "note": "**Duas perguntas, cada uma um diff por seções.** O que a configuração pretendida tem e o roteador não tem, e o que o roteador tem e ninguém pretendeu. Uma linha aparece debaixo da seção a que pertence, onde quer que esteja no arquivo."
    }
  ]
}
```

```
ana@ctl:~$ cd net && python compare.py edge1
edge1, missing from the router:
interface eth2
 description branch LAN
edge1, on the router and not intended:
ip route 192.0.2.128/25 198.51.100.1
interface eth2
 description guest wifi
```

**Cada linha aparece sob a seção a que pertence**, onde quer que esteja no arquivo, e a linha em
branco e o `!` sumiram porque não são configuração. As duas direções respondem a duas perguntas
diferentes: o que os dados pedem e o roteador não tem, e o que o roteador tem que ninguém escreveu.
A primeira costuma ser uma mudança que falhou; a segunda é a deriva.

O parser indicado é `cisco_ios`, porque a configuração do FRR tem o mesmo formato, seções abertas
por uma linha e indentadas embaixo dela. A `netutils` tem parsers para cerca de trinta
plataformas, e o certo tem que ser indicado; um parser para o formato errado dá uma resposta
confiante e errada.
