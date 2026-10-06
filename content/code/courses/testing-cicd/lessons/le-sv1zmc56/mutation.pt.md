---
title: Quebrando o código para testar os testes
version: 1
---

A aula 1 quebrou `brl` de propósito para ver um teste falhar, e a aula 3 fez o mesmo com `split`. O
**teste de mutação** transforma isso em método. Um *mutante* é uma cópia do código com uma pequena
mudança deliberada, como `>=` virando `>`. Rode a suíte contra ele. Se algum teste falha, o mutante
é **morto**: a suíte percebeu. Se todos passam, o mutante **sobreviveu**, e a suíte não distingue o
código quebrado do real.

Ferramentas como `mutmut` e `cosmic-ray` para Python, PIT para Java e Stryker para JavaScript geram
milhares de mutantes automaticamente. A ideia cabe num script curto, e vê-lo inteiro é o melhor jeito
de entender o que essas ferramentas relatam. Este foi escrito para a aula e fica ao lado do script
de captura dela:

```python
"""Mutation testing by hand: change one thing, run the suite, see who notices.

Each mutation is a (file, old, new) replacement. The file is restored after
every run, whatever happened.
"""
import subprocess
import sys
from pathlib import Path

MUTATIONS = [
    ("shipquote/quote.py", "subtotal_cents >= FREE_FROM", "subtotal_cents > FREE_FROM"),
    ("shipquote/quote.py", "if weight_g <= 0:", "if weight_g < 0:"),
    ("shipquote/quote.py", "(weight_g - 1) // 500", "weight_g // 500"),
    ("shipquote/quote.py", "len(digits) != 8 or", "len(digits) != 8 and"),
    ("shipquote/quote.py", '"6": "N"', '"6": "NE"'),
    ("shipquote/store.py", "ORDER BY created_at DESC, id DESC", "ORDER BY created_at DESC"),
    ("shipquote/store.py", "CHECK (cents >= 0)", "CHECK (cents >= -1000)"),
    ("shipquote/store.py", "CHECK (length(cep) = 8)", "CHECK (length(cep) >= 7)"),
]

killed = 0
for path, old, new in MUTATIONS:
    f = Path(path)
    original = f.read_text()
    assert old in original, (path, old)
    f.write_text(original.replace(old, new, 1))
    try:
        run = subprocess.run([sys.executable, "-m", "pytest", "-q", "-x", "-p", "no:cacheprovider"],
                             capture_output=True, text=True)
    finally:
        f.write_text(original)
    verdict = "killed" if run.returncode == 1 else "SURVIVED"
    killed += verdict == "killed"
    print(f"{verdict:9} {path:20} {old}  ->  {new}")
print(f"{killed} of {len(MUTATIONS)} mutants killed")
```

Oito mutantes, cada um um deslize plausível: uma borda deslocada, uma faixa contada errado, uma
conferência de CEP enfraquecida, um desempate apagado, uma restrição afrouxada. Cada um é aplicado,
a suíte inteira roda com `-x` para parar na primeira falha, e o arquivo é restaurado.

```
ana@laptop:~/shipquote$ python mutate.py
killed    shipquote/quote.py   subtotal_cents >= FREE_FROM  ->  subtotal_cents > FREE_FROM
killed    shipquote/quote.py   if weight_g <= 0:  ->  if weight_g < 0:
killed    shipquote/quote.py   (weight_g - 1) // 500  ->  weight_g // 500
killed    shipquote/quote.py   len(digits) != 8 or  ->  len(digits) != 8 and
killed    shipquote/quote.py   "6": "N"  ->  "6": "NE"
SURVIVED  shipquote/store.py   ORDER BY created_at DESC, id DESC  ->  ORDER BY created_at DESC
SURVIVED  shipquote/store.py   CHECK (cents >= 0)  ->  CHECK (cents >= -1000)
killed    shipquote/store.py   CHECK (length(cep) = 8)  ->  CHECK (length(cep) >= 7)
6 of 8 mutants killed
```

Os cinco mutantes em `quote.py` morreram: as bordas da aula 1 e a tabela da aula 3 fizeram o
trabalho. **Dois dos três em `store.py` sobreviveram, num arquivo que o relatório de cobertura mostra
em 100%.**

- Tirar `id DESC` da ordenação sobreviveu porque nenhum teste grava duas cotações com o mesmo
  `created_at`. A fábrica da aula 3 garante isso, então o desempate, que decide a ordem de duas
  cotações feitas no mesmo segundo, nunca é exercitado.
- Afrouxar `CHECK (cents >= 0)` sobreviveu porque nenhum teste tenta guardar um preço negativo. A
  restrição do CEP, que o terceiro teste do store exercita, foi morta.

Cada sobrevivente aponta um teste que vale escrever. Nenhum é problema de cobertura: as linhas
rodaram. São problemas de verificação, invisíveis a qualquer porcentagem da seção 02.

## O custo, e como as equipes usam

Cada mutante é uma execução completa da suíte, então teste de mutação é lento: oito mutantes aqui
custaram oito execuções, e uma ferramenta de verdade num projeto de verdade gera milhares. Equipes
que o usam rodam **nos arquivos que uma mudança tocou**, ou toda noite, e não a cada push, e leem os
sobreviventes em vez de perseguir uma nota. Um mutante sobrevivente no texto de uma mensagem de log
não vale um teste; um num preço vale.

**Uma nota de mutação mede os testes; uma nota de cobertura mede o código que rodou.** Das duas, só a
primeira diz alguma coisa sobre os testes pegarem um defeito.
