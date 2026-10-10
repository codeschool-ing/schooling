---
title: Fazendo um padrão valer com uma máquina
version: 1
---

Um padrão que pessoas verificam é verificado quando alguém se lembra, por quem por acaso olhar. **Um
padrão que uma máquina verifica é verificado a cada mudança, do mesmo jeito para todo mundo**, e
ninguém precisa ser a pessoa que diz não. Esse é o argumento inteiro desta seção, e a figura abaixo
põe um tempo nele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Seis caixas em fila, da esquerda para a direita: no editor, segundos; no commit, segundos; no CI, minutos; na revisão, horas; em produção, dias; numa wiki, nunca. As três primeiras estão agrupadas como uma máquina que dá a mesma resposta sempre, a quarta como uma pessoa cuja resposta depende de quem olha, as duas últimas como ninguém, até custar caro. Uma seta debaixo da fila diz achado mais tarde, custa mais.\"><defs><marker id=\"std-ladder-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"12\" y=\"90\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"64\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">no editor</text><text x=\"64\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">segundos</text><rect x=\"130\" y=\"90\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">no commit</text><text x=\"182\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">segundos</text><rect x=\"248\" y=\"90\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">no CI</text><text x=\"300\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">minutos</text><rect x=\"366\" y=\"90\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"418\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">na revisão</text><text x=\"418\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">horas</text><rect x=\"484\" y=\"90\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"536\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">em produção</text><text x=\"536\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dias</text><rect x=\"602\" y=\"90\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"654\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">numa wiki</text><text x=\"654\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nunca</text><path d=\"M12 78 L12 70 L338 70 L338 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"175\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma máquina: a mesma resposta sempre</text><path d=\"M366 78 L366 70 L470 70 L470 78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"418\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma pessoa:</text><text x=\"418\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">depende de quem olha</text><path d=\"M484 78 L484 70 L706 70 L706 78\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"595\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ninguém, até custar caro</text><path d=\"M12 168 L704 168\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#std-ladder-ah)\"></path><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">achado mais tarde, custa mais</text></svg>", "caption": "Onde um padrão quebrado é encontrado, e quanto tempo depois de escrito. As três da esquerda respondem igual para todo mundo; a revisão depende de quem olha; as duas últimas são achadas pelo incidente."}
```

A falha nos repasses da seção anterior estava na ponta errada dessa fila. O import que a causou estava
no código de Payments havia onze meses, tinha passado pela revisão de código, e foi achado por 312
motoristas conferindo a conta do banco numa sexta. Ninguém foi descuidado. Um revisor de Payments não
tinha motivo para saber que `offers.py` era assunto privado de Matching, e um revisor de Matching nunca
viu o pull request de Payments.

## O que uma máquina consegue verificar

A maior parte dos nove padrões cabe em ferramentas que a Carreto já rodava por outros motivos:

- um linter ou um verificador de tipos, no editor e no CI, para as regras sobre o próprio código. A
  regra do dinheiro é uma checagem de tipo: um campo de valor tipado como `float` reprova.
- um job de CI em cada pull request, para regras sobre o repositório: o scanner de segredos, a
  comparação do schema de uma API pública com a versão anterior, a verificação de imports que esta
  seção constrói.
- o pipeline de deploy, para regras sobre o que chega à produção. Um serviço sem `/healthz` é recusado,
  e como o pipeline é o único que tem credenciais de produção, recusado quer dizer que não sobe.
- um scanner sobre um ambiente rodando, para regras que só aparecem em execução, como o CPF que surge
  numa linha de log montada a partir do corpo de uma requisição.

**Sete dos nove padrões da Carreto são verificados por uma máquina.** A regra do dinheiro é verificada
pela metade: a checagem de tipo pega um `float` e não pega uma conversão feita à mão. A regra do ADR é
verificada por pessoas no fórum de arquitetura (aula 10), porque "esta decisão cruza fronteiras de
time" é um julgamento. Saber quais padrões uma máquina não segura diz para onde o tempo de revisão
precisa ir.

## Funções de aptidão

Neal Ford, Rebecca Parsons e Patrick Kua deram nome a esse tipo de verificação em *Building
Evolutionary Architectures* (2017): uma **função de aptidão** (*fitness function*) é uma avaliação
objetiva e automática de quanto o sistema mantém uma das suas características arquiteturais. O termo
vem da computação evolutiva, em que uma função de aptidão dá nota a quanto uma solução candidata está
perto do objetivo.

A parte útil da ideia é a palavra *arquitetural*. Um teste de unidade confere se uma função devolve o
valor certo. Uma função de aptidão confere uma propriedade da estrutura que nenhuma função sozinha
possui:

- uma regra de dependência: Payments não importa o interior de Matching;
- um orçamento de desempenho: uma cotação leva menos de 300 ms no percentil 95 no teste de carga
  noturno;
- um limite operacional: o job de repasses termina em menos de 20 minutos numa cópia dos dados da
  última sexta.

O livro as classifica em alguns eixos, e vale saber dois pelo nome. Uma função de aptidão **disparada**
roda quando algo muda, como um job de CI num pull request; uma **contínua** roda o tempo todo contra a
produção, como um alerta sobre a latência das cotações. Uma **atômica** confere uma característica
isolada; uma **holística** confere várias juntas, como um teste de carga que mede latência e taxa de
erro ao mesmo tempo. Existem ferramentas para as regras de dependência mais comuns: ArchUnit para Java,
import-linter para Python, dependency-cruiser para JavaScript. A desta seção é escrita à mão para você
ver tudo, e para caber num monólito cuja regra é a da própria Carreto. A aula 15 volta às funções de
aptidão como o tipo de código que um arquiteto continua escrevendo.

## Um projeto de exemplo

O monólito de verdade tem um diretório por time debaixo de `carreto/`. O exemplo guarda três deles, com
dois ou três arquivos em cada, o bastante para quebrar a regra uma vez e precisar de uma exceção uma
vez. Este script curto o escreve:

```sh
# make-carreto.sh: writes a tiny example project into ./carreto
mkdir -p carreto/matching carreto/tracking carreto/payments
touch carreto/__init__.py carreto/matching/__init__.py \
      carreto/tracking/__init__.py carreto/payments/__init__.py

cat > carreto/matching/offers.py <<'END'
def accepted_driver(load_id):
    return {"load": load_id, "driver": "D-1042"}
END

cat > carreto/matching/api.py <<'END'
from carreto.matching.offers import accepted_driver

__all__ = ["accepted_driver"]
END

cat > carreto/tracking/models.py <<'END'
class DeliveryProof:
    def __init__(self, load_id, photo):
        self.load_id, self.photo = load_id, photo
END

cat > carreto/tracking/api.py <<'END'
def delivery_proved(load_id):
    return True
END

cat > carreto/payments/payout.py <<'END'
from carreto.matching.offers import accepted_driver
from carreto.tracking.api import delivery_proved


def pay_driver(load_id):
    if delivery_proved(load_id):
        return accepted_driver(load_id)["driver"]
END

cat > carreto/payments/invoice.py <<'END'
from carreto.tracking.models import DeliveryProof


def attach_proof(invoice, proof: DeliveryProof):
    invoice["proof"] = proof.photo
    return invoice
END
```

Rodar é opcional; ler o programa e a saída abaixo basta para acompanhar a aula. Para rodar, salve o
script como `make-carreto.sh` num diretório vazio e execute com `sh`; o projeto aparece ao lado. No
Windows, rode no Git Bash ou no WSL, ou crie os dez arquivos à mão a partir do script.

```
$ sh make-carreto.sh
$ find carreto -name '*.py' | sort
carreto/__init__.py
carreto/matching/__init__.py
carreto/matching/api.py
carreto/matching/offers.py
carreto/payments/__init__.py
carreto/payments/invoice.py
carreto/payments/payout.py
carreto/tracking/__init__.py
carreto/tracking/api.py
carreto/tracking/models.py
```

O `api.py` de cada pacote é **a porta da frente**: o que aquele time promete manter funcionando. Todo o
resto lá dentro pode mudar numa quinta sem avisar ninguém. O `api.py` de Matching reexporta
`accepted_driver` de `offers.py`, então se Matching dividir `offers.py` de novo, ele atualiza um import
no próprio `api.py` e ninguém de fora percebe. O `payout.py` de Payments está escrito como o de verdade
estava antes de março: passando direto pela porta até `offers.py`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Três caixas de pacote lado a lado: carreto/matching, carreto/payments e carreto/tracking. Matching contém api.py e offers.py, Payments contém payout.py e invoice.py, Tracking contém api.py e models.py. Uma seta contínua vai de payout.py ao api.py de Matching e outra de payout.py ao api.py de Tracking: permitido. Uma seta tracejada âmbar vai de payout.py a offers.py: recusado pela verificação. Uma seta tracejada cinza vai de invoice.py a models.py: permitido até 2027-03-31 como exceção concedida.\"><defs><marker id=\"std-bound-ok\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"std-bound-no\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"std-bound-ex\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"220\" height=\"230\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">carreto/matching</text><rect x=\"250\" y=\"20\" width=\"220\" height=\"230\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">carreto/payments</text><rect x=\"490\" y=\"20\" width=\"220\" height=\"230\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">carreto/tracking</text><rect x=\"120\" y=\"80\" width=\"100\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">api.py</text><rect x=\"20\" y=\"170\" width=\"100\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">offers.py</text><rect x=\"300\" y=\"80\" width=\"120\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">payout.py</text><rect x=\"300\" y=\"170\" width=\"120\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">invoice.py</text><rect x=\"500\" y=\"80\" width=\"100\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">api.py</text><rect x=\"600\" y=\"170\" width=\"100\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"650.0\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">models.py</text><path d=\"M300 92 L222 92\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#std-bound-ok)\"></path><path d=\"M420 92 L498 92\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#std-bound-ok)\"></path><path d=\"M300 106 L122 182\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#std-bound-no)\"></path><path d=\"M420 187 L598 187\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 3\" marker-end=\"url(#std-bound-ex)\"></path><path d=\"M20 276 L56 276\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#std-bound-ok)\"></path><text x=\"66\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">permitido: pelo api.py do outro time</text><path d=\"M20 298 L56 298\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#std-bound-no)\"></path><text x=\"66\" y=\"298\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">recusado pela verificação: um módulo interno</text><path d=\"M20 320 L56 320\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 3\" marker-end=\"url(#std-bound-ex)\"></path><text x=\"66\" y=\"320\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">permitido até 2027-03-31: uma exceção concedida</text></svg>", "caption": "O projeto de exemplo e a regra que a verificação cobra dele. O pacote de cada time tem uma porta da frente, o seu api.py; todo o resto lá dentro é assunto daquele time e pode mudar sem aviso."}
```

## A verificação

Salve isto ao lado de `make-carreto.sh` como `check_imports.py`. Usa só a biblioteca padrão, então
qualquer Python 3 roda. As notas dizem para que serve cada parte; o botão de copiar leva o programa sem
elas.

```schooling-example
{
  "language": "python",
  "file": "check_imports.py",
  "parts": [
    {
      "code": "# check_imports.py: fail when one team's package imports another team's internals\nimport ast\nimport datetime\nimport pathlib\nimport sys",
      "note": "Quatro módulos da biblioteca padrão e nada para instalar. `ast` lê o código Python como uma árvore sem executá-lo, então a verificação roda com segurança em qualquer branch, por mais quebrado que o código esteja."
    },
    {
      "code": "\nROOT = pathlib.Path(\"carreto\")\nEXCEPTIONS = {  # (file, module it may import) -> last day the exception holds\n    (\"carreto/payments/invoice.py\", \"carreto.tracking.models\"): \"2027-03-31\",\n}",
      "note": "Onde o código mora, e a única exceção concedida até agora, com o último dia em que vale. Uma lista guardada no repositório é revisada em pull request como o código que ela libera. A última seção desta aula trata dela."
    },
    {
      "code": "\n\ndef imports_in(path):\n    tree = ast.parse(path.read_text(), filename=str(path))\n    for node in ast.walk(tree):\n        if isinstance(node, ast.Import):\n            for alias in node.names:\n                yield node.lineno, alias.name\n        elif isinstance(node, ast.ImportFrom) and node.level == 0:\n            yield node.lineno, node.module",
      "note": "Cada `import x` e cada `from x import y` de um arquivo, com o número da linha. Um import relativo (`from . import y`) fica dentro do próprio pacote, então `level == 0` mantém só os absolutos."
    },
    {
      "code": "\n\ndef team_of(module):\n    parts = module.split(\".\")\n    return parts[1] if parts[0] == \"carreto\" and len(parts) > 1 else None",
      "note": "`carreto.matching.offers` pertence a `matching`. Um módulo fora de `carreto`, como `datetime`, não pertence a time nenhum e não é assunto desta verificação."
    },
    {
      "code": "\n\ndef main():\n    today = datetime.date.today().isoformat()\n    violations = 0\n    for path in sorted(ROOT.rglob(\"*.py\")):\n        own = path.parts[1]\n        for line, module in imports_in(path):\n            team = team_of(module)\n            if team in (None, own) or module == f\"carreto.{team}.api\":\n                continue",
      "note": "O padrão em si, numa condição só: um import do seu próprio pacote, ou do módulo `api` de outro pacote, está liberado. `own` é o diretório debaixo de `carreto/` onde o arquivo está."
    },
    {
      "code": "            until = EXCEPTIONS.get((path.as_posix(), module))\n            if until and today <= until:\n                print(f\"{path}:{line}: allowed until {until}: {module}\")\n                continue\n            print(f\"{path}:{line}: imports {module}; use carreto.{team}.api\")\n            violations += 1",
      "note": "Uma exceção vale até a data dela. No dia seguinte o mesmo import volta a ser violação, sem ninguém precisar lembrar. A mensagem dá o arquivo, a linha e o que importar no lugar, para quem a lê no CI conseguir corrigir sem perguntar a ninguém."
    },
    {
      "code": "    print(f\"{violations} violation(s)\")\n    return 1 if violations else 0\n\n\nif __name__ == \"__main__\":\n    sys.exit(main())",
      "note": "O status de saída é o que o CI lê: 1 reprova o build e 0 deixa passar. A contagem é para a pessoa."
    }
  ]
}
```

Rode no diretório que contém `carreto/` (no Windows o comando é `python` em vez de `python3`):

```
$ python3 check_imports.py
carreto/payments/invoice.py:1: allowed until 2027-03-31: carreto.tracking.models
carreto/payments/payout.py:1: imports carreto.matching.offers; use carreto.matching.api
1 violation(s)
$ echo $?
1
```

**A mensagem é o padrão, dito no momento em que alguém o quebra.** Ela dá o arquivo, a linha, o módulo
que não deveria ser importado e o que usar no lugar. Um desenvolvedor de Payments que nunca leu a wiki
consegue corrigir isso pelo log do CI, e essa é a diferença entre uma regra que ensina e uma regra que só
recusa. O `echo $?` mostra o status de saída: `1`, que é o que deixa um job de CI vermelho.

A correção é uma linha. Troque a primeira linha de `carreto/payments/payout.py` por:

```python
from carreto.matching.api import accepted_driver
```

Depois olhe as duas primeiras linhas, para ter certeza de que a edição pegou, e rode a verificação de
novo:

```
$ head -2 carreto/payments/payout.py
from carreto.matching.api import accepted_driver
from carreto.tracking.api import delivery_proved
$ python3 check_imports.py
carreto/payments/invoice.py:1: allowed until 2027-03-31: carreto.tracking.models
0 violation(s)
$ echo $?
0
```

A exceção em `invoice.py` continua aparecendo em toda execução. **Uma exceção que ninguém vê é uma
exceção que ninguém lembra de fechar**, e mostrá-la custa uma linha do log. Em 1º de abril de 2027 a
mesma execução vai mostrá-la como violação, e o build vai reprovar até o `api.py` de Tracking oferecer
o que Payments precisa ou alguém conceder uma nova data. A última seção desta aula trata de como essa
decisão é tomada.

## Ligando a verificação num código que já quebra a regra

O monólito da Carreto não era o exemplo arrumado. Quando Renata rodou a versão real desta verificação
contra ele pela primeira vez, em modo só de relatório, ela achou **23 imports atravessando fronteiras
de time**. Reprovar o build naquela tarde teria travado todos os times por código que a maioria deles
não escreveu, e a verificação teria sido desligada até o fim da semana.

Então a primeira versão funcionou como uma **catraca**. Os 23 foram para um arquivo de base no
repositório, a verificação reprovava só um import que não estivesse na base, e uma entrada podia sair
da base mas nunca entrar. Uma violação nova reprovava o build desde o primeiro dia; as antigas viraram
uma lista com um número. Quatro meses depois a base tinha seis entradas, cada uma com um dono. A lista
`EXCEPTIONS` do programa acima é a mesma ideia com uma data em cada entrada: uma base diz que uma
violação antiga vai sair, e uma exceção diz até quando.

**Uma verificação que começa rígida num código antigo é uma verificação que acaba desligada.** Uma que
começa congelando o estado atual, e só aperta, leva o código até a regra sem uma semana em que ninguém
consegue fazer merge.
