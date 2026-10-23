---
title: Reconciliação: provar que o que chegou é o que saiu
version: 1
---

Uma carga que terminou sem erro provou uma coisa: nada do que ela verificou deu errado. Ela não diz
nada sobre as linhas que não verificou, os valores que transformou de forma errada mas válida, ou as
linhas que nunca leu. **A reconciliação é a prova separada e independente de que o destino tem o que
a origem mandou**, e é sobre ela que a decisão de go/no-go é tomada. Uma migração sem reconciliação
termina quando o script para, o que não é o mesmo que estar certa.

O erro comum é tratar a reconciliação como uma contagem. A contagem é o primeiro de três níveis, e
cada nível pega algo que o de cima deixa passar.

## Três níveis

**Contagem.** O número de registros de cada lado. Ela pega as linhas perdidas e as linhas carregadas
duas vezes. Não consegue ver uma linha que chegou com o valor errado dentro.

**Total de controle.** A soma de um campo que importa, de cada lado: na Serra Alta, os litros, e numa
migração financeira, os valores. Ele pega um valor que mudou no caminho, como uma unidade dividida uma
vez a mais ou uma casa decimal truncada. Não consegue ver dois erros que se cancelam: litros que
passam de uma fazenda para outra deixam o total exatamente onde estava.

**Registro.** Cada registro de um lado comparado com o registro de mesma chave do outro. Diz quais
registros faltam, quais sobram e quais mudaram, pelo nome. Comparar cada campo de milhões de
registros entre dois sistemas é lento e trabalhoso, então cada lado calcula uma **impressão
digital**, um hash dos campos do registro numa forma combinada, e só as chaves e os hashes são
comparados. Dois registros com o mesmo hash têm os mesmos valores.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l14-levels\" aria-label=\"Uma grade de quatro verificações contra cinco falhas. As verificações, uma por linha: contagem, total de controle, registro por impressão digital, e uma amostra lida pelo dono dos dados. As falhas, uma por coluna: uma linha perdida, um valor alterado, dois valores trocados, uma fazenda carregada com o código errado, e uma regra errada na especificação. A contagem pega só a linha perdida. O total de controle pega a linha perdida e o valor alterado. A verificação por registro pega as quatro primeiras falhas. Só a amostra do dono pega a regra errada, porque toda verificação escrita a partir da mesma especificação concorda com ela.\"><text x=\"264.0\" y=\"33.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma linha</text><text x=\"264.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">perdida</text><text x=\"364.0\" y=\"33.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um valor</text><text x=\"364.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">alterado</text><text x=\"464.0\" y=\"33.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dois valores</text><text x=\"464.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">trocados</text><text x=\"564.0\" y=\"33.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fazenda com o</text><text x=\"564.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">código errado</text><text x=\"664.0\" y=\"33.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">regra errada na</text><text x=\"664.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">especificação</text><text x=\"16.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">contagem</text><circle cx=\"264.0\" cy=\"86.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"364.0\" cy=\"86.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"464.0\" cy=\"86.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"564.0\" cy=\"86.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"664.0\" cy=\"86.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><text x=\"16.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">total de controle</text><circle cx=\"264.0\" cy=\"128.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"364.0\" cy=\"128.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"464.0\" cy=\"128.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"564.0\" cy=\"128.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"664.0\" cy=\"128.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><text x=\"16.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">registro, por impressão digital</text><circle cx=\"264.0\" cy=\"170.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"364.0\" cy=\"170.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"464.0\" cy=\"170.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"564.0\" cy=\"170.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"664.0\" cy=\"170.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><path d=\"M16.0 191.0 L714.0 191.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"16.0\" y=\"212.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">amostra lida pelo dono</text><circle cx=\"264.0\" cy=\"212.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"364.0\" cy=\"212.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"464.0\" cy=\"212.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"564.0\" cy=\"212.0\" r=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><circle cx=\"664.0\" cy=\"212.0\" r=\"8\" fill=\"var(--amber)\"></circle><circle cx=\"232.0\" cy=\"268.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"246.0\" y=\"268.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pega</text><circle cx=\"330.0\" cy=\"268.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></circle><text x=\"344.0\" y=\"268.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">passa despercebida</text></svg>", "caption": "O que cada nível da reconciliação consegue ver. Cada nível abaixo pega o que o de cima deixa passar; a última linha é uma pessoa, porque uma verificação feita a partir da especificação não consegue duvidar dela."}
```

A Serra Alta aprendeu o terceiro nível do jeito caro. **Os primeiros critérios de go/no-go de Joana
pediam só contagens e totais**, porque nos sistemas que ela tinha migrado antes, o código que movia
os dados era o mesmo que os tinha escrito, e um valor errado era raro. O ensaio geral 1 passou nos
dois níveis com 214 coletas carregando os litros de outra fazenda, e só o nível de registro as viu.

## Compare as pontas, não o meio

Uma reconciliação só é independente se lê o que a migração não escreveu. **O lado da origem é
extraído do próprio Coleta no momento do congelamento**, não dos arquivos intermediários que a
transformação leu; **o lado do destino é lido do novo sistema como os usuários o veem**, não das
tabelas da própria carga. Uma reconciliação que compara a entrada da carga com a saída da carga prova
que a carga concorda consigo mesma.

As duas extrações também são levadas a uma forma única antes da comparação. O Coleta guarda os litros
em centésimos num inteiro; o novo sistema guarda um decimal. O Coleta completa o número do fornecedor
no SAP com zeros até dez dígitos; o novo sistema guarda o número. **A comparação é de significado, não
de bytes**, e as regras que levam os dois a uma forma só são curtas, separadas da transformação e
escritas por alguém que não escreveu a transformação.

## Diferenças esperadas

A origem e o destino não foram feitos para ser idênticos. A especificação remove e junta coisas de
propósito, e a reconciliação tem de prestar contas de cada linha:

> linhas da origem = linhas do destino + linhas rejeitadas com motivo + linhas excluídas ou juntadas por uma regra

Na Serra Alta o cadastro de fazendas fecha assim: 1.958 fazendas no escopo, 7 juntadas às
sobreviventes, então **1.951 fazendas são esperadas no destino**, sem nenhum rejeito. O total de
controle fecha sem ajuste, porque os litros de uma fazenda juntada vão para a sobrevivente em vez de
sumir. No nível de registro, as 7 sobreviventes devem diferir do registro de origem, já que cada uma
agora carrega o histórico de uma segunda fazenda, e elas aparecem como mudanças esperadas, não como
achados. **Uma diferença com uma regra por trás é um resultado; uma diferença sem regra para o
cutover.**

## O programa

O programa abaixo faz os três níveis em escala pequena. Ele compara duas extrações dos litros de
julho, uma de cada lado, pela contagem, pelo total de litros e por uma impressão digital de cada
fazenda. Rodá-lo é opcional: as transcrições abaixo mostram o que ele imprime. Se quiser rodar, use a
máquina Linux da aula 1 ou qualquer computador com Python 3.

Este script escreve as duas extrações, com oito fazendas cada, e um terceiro arquivo com o destino
como ele poderia ter ficado depois de uma carga com defeito:

```sh
# make-extracts.sh: the July extracts from both sides, and a target with three faults
cat > coleta.csv <<'END'
farm_code;sap_vendor;litres_x100
100127;0000300127;2828440
100245;0000300245;1395000
100318;0000300318;471975
100436;0000300436;3620800
100554;0000300554;902330
100672;0000300672;1785610
100790;0000300790;640520
100818;0000300818;2210115
END

cat > target.csv <<'END'
farm_id;legacy_code;vendor;litres
F-000214;100127;300127;28284.40
F-000215;100245;300245;13950.00
F-000216;100318;300318;4719.75
F-000217;100436;300436;36208.00
F-000218;100554;300554;9023.30
F-000219;100672;300672;17856.10
F-000220;100790;300790;6405.20
F-000221;100818;300818;22101.15
END

cat > target-faulty.csv <<'END'
farm_id;legacy_code;vendor;litres
F-000214;100127;300127;28284.40
F-000215;100245;300245;4719.75
F-000216;100318;300318;13950.00
F-000217;100436;300436;36208.00
F-000218;100545;300554;9023.30
F-000219;100672;300672;17856.10
F-000220;100790;300790;6405.20
F-000221;100818;300818;22101.15
END
```

Salve-o como `make-extracts.sh` num diretório vazio e rode-o com `sh`. No Windows, use o Git Bash ou
o WSL, ou crie os três arquivos à mão a partir do script.

```
$ sh make-extracts.sh
$ head -3 coleta.csv target.csv
==> coleta.csv <==
farm_code;sap_vendor;litres_x100
100127;0000300127;2828440
100245;0000300245;1395000

==> target.csv <==
farm_id;legacy_code;vendor;litres
F-000214;100127;300127;28284.40
F-000215;100245;300245;13950.00
```

Os dois lados não se parecem, o que é o caso normal: nomes de coluna diferentes, o número do
fornecedor com e sem os zeros à esquerda, os litros como um inteiro de centésimos e como decimal. O
destino também tem um `farm_id` próprio, novo, com o código do Coleta guardado ao lado em
`legacy_code`.

Salve isto ao lado deles como `reconcile.py`. Ele usa só a biblioteca padrão.

```schooling-example
{
  "language": "python",
  "file": "reconcile.py",
  "parts": [
    {
      "code": "# reconcile.py: prove the target holds what the source sent, at three levels\nimport csv\nimport hashlib\nimport sys\nfrom decimal import Decimal",
      "note": "Quatro módulos da biblioteca padrão. O `hashlib` gera as impressões digitais e o `Decimal` guarda os litros, porque uma reconciliação que soma litros como números de ponto flutuante pode discordar de si mesma na última casa decimal."
    },
    {
      "code": "\n\ndef hundredths(text):\n    value = Decimal(text) * 100\n    if value != value.to_integral_value():\n        raise ValueError(f\"more than two decimals: {text}\")\n    return int(value)",
      "note": "O destino escreve os litros como decimal e o Coleta como centésimos, então os dois viram um número inteiro de centésimos. Um valor com terceira casa decimal é recusado, e não arredondado: uma reconciliação que arredonda calada parou de conferir aquele dígito."
    },
    {
      "code": "\n\ndef from_coleta(row):\n    return row[\"farm_code\"], int(row[\"sap_vendor\"]), int(row[\"litres_x100\"])\n\n\ndef from_target(row):\n    return row[\"legacy_code\"], int(row[\"vendor\"]), hundredths(row[\"litres\"])",
      "note": "Uma função pequena por lado, levando o formato de cada um a uma forma só: o código da fazenda, o fornecedor como número sem os zeros à esquerda, e os litros em centésimos. Essas regras são o único lugar onde os dois formatos se encontram, e ficam separadas do código que fez a migração."
    },
    {
      "code": "\n\ndef read(path, convert):\n    count, total, farms = 0, 0, {}\n    with open(path, newline=\"\", encoding=\"utf-8\") as f:\n        for row in csv.DictReader(f, delimiter=\";\"):\n            code, vendor, litres = convert(row)\n            if code in farms:\n                raise ValueError(f\"{path}: farm {code} appears twice\")\n            count, total = count + 1, total + litres\n            record = f\"{code}|{vendor}|{litres}\".encode()\n            farms[code] = hashlib.sha256(record).hexdigest()\n    return count, total, farms",
      "note": "Uma passada por uma extração dá a matéria-prima dos três níveis: a contagem, o total e uma impressão digital por fazenda. Um código de fazenda visto duas vezes é um erro que para a execução, porque guardar a segunda linha em silêncio esconderia exatamente o duplicado que uma contagem deveria achar."
    },
    {
      "code": "\n\ndef main(source, target):\n    s_count, s_total, s_farms = read(source, from_coleta)\n    t_count, t_total, t_farms = read(target, from_target)\n    ok = True\n\n    def level(name, left, right):\n        nonlocal ok\n        ok = ok and left == right\n        verdict = \"ok\" if left == right else \"DIFFERENT\"\n        print(f\"{name:<8} source {left:>12}  target {right:>12}  {verdict}\")\n\n    level(\"count\", s_count, t_count)\n    level(\"litres\", f\"{Decimal(s_total) / 100:,.2f}\", f\"{Decimal(t_total) / 100:,.2f}\")",
      "note": "Os dois primeiros níveis. Cada um mostra os dois lados e um veredito, e qualquer discordância deixa `ok` falso. O total sai em litros com duas casas decimais, para uma pessoa poder comparar com um relatório."
    },
    {
      "code": "    both = s_farms.keys() & t_farms.keys()\n    found = {\n        \"missing\": sorted(s_farms.keys() - t_farms.keys()),\n        \"extra\": sorted(t_farms.keys() - s_farms.keys()),\n        \"changed\": sorted(c for c in both if s_farms[c] != t_farms[c]),\n    }\n    for name, codes in found.items():\n        print(f\"{name:<8} {len(codes)}  {' '.join(codes)}\".rstrip())\n        ok = ok and not codes",
      "note": "O terceiro nível, pela chave. Um código só na origem está faltando, um código só no destino está sobrando, e um código dos dois lados com impressões digitais diferentes mudou. Cada lista dá o nome das fazendas, que é o que alguém precisa às três da manhã."
    },
    {
      "code": "    print(\"RECONCILED\" if ok else \"NOT RECONCILED\")\n    return 0 if ok else 1\n\n\nif __name__ == \"__main__\":\n    sys.exit(main(sys.argv[1], sys.argv[2]))",
      "note": "O status de saída é o que um runbook ou um agendador lê: `0` quando todos os níveis batem, `1` caso contrário."
    }
  ]
}
```

Rode primeiro com o destino limpo (no Windows o comando é `python` em vez de `python3`):

```
$ python3 reconcile.py coleta.csv target.csv
count    source            8  target            8  ok
litres   source   138,547.90  target   138,547.90  ok
missing  0
extra    0
changed  0
RECONCILED
$ echo $?
0
```

Todos os níveis batem, e o status de saída é `0`, que um agendador ou um passo do runbook consegue
ler sem uma pessoa.

Agora rode com o destino com defeito:

```
$ python3 reconcile.py coleta.csv target-faulty.csv
count    source            8  target            8  ok
litres   source   138,547.90  target   138,547.90  ok
missing  1  100554
extra    1  100545
changed  2  100245 100318
NOT RECONCILED
$ echo $?
1
```

**A contagem e o total passam, e o destino está errado em quatro fazendas.** A fazenda `100554` está
faltando e a fazenda `100545` está sobrando: a mesma fazenda, carregada com um código de dois dígitos
trocados, então a contagem não se mexe e os litros também não. As fazendas `100245` e `100318`
trocaram os litros, `13950.00` e `4719.75`, o que deixa o total exatamente onde estava. É uma miniatura
do que o ensaio geral 1 achou, e o motivo de o terceiro nível existir. O status de saída é `1`, e a
saída dá o nome de cada fazenda para a qual alguém precisa olhar.

## O que nenhum programa vê

Os três níveis comparam o destino com o que a especificação dizia que ele deveria ter. **Se a
especificação estiver errada, a reconciliação concorda com o erro**, porque quem a escreveu leu a
mesma especificação. Um mapeamento que pusesse o resultado de gordura no campo de proteína, tanto na
carga quanto nas regras da reconciliação, reconcilia perfeitamente.

É para isso que serve a quarta verificação, e ela é feita por uma pessoa. Antes de cada go/no-go, a
equipe de Cláudia abriu 40 fazendas sorteadas nas telas do novo sistema, ao lado das mesmas fazendas
nas telas do Coleta. Elas as leram como quem entende de leite lê: a gordura desta fazenda parece a
gordura desta fazenda, esta contagem bacteriana é plausível para a época do ano? O financeiro fez o
mesmo com os vínculos de fornecedor de 40 fazendas no SAP. **Uma amostra lida por um dono confere o
significado, o que nenhuma impressão digital consegue.** Ela é pequena porque não precisa ser grande:
procura uma regra errada, que aparece em toda fazenda que ela toca, e não uma linha errada entre
milhões.
