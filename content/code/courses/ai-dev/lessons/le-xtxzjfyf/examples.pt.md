---
title: Mostrar em vez de descrever
version: 1
---

Alguns requisitos são mais fáceis de mostrar que de dizer. "Escreva assuntos de commit no nosso
estilo" é vago; três assuntos reais do projeto não são. Pôr alguns exemplos da saída que você quer
no prompt se chama **few-shot prompting** (prompting com poucos exemplos), e é a ferramenta mais
forte que existe para formato e estilo: o modelo continua o padrão que lhe mostraram.

## Um assunto de commit, de dois jeitos

O script da ana pede um assunto de commit para a mudança ainda sem commit no `parse_price`, uma vez
só com o diff, e outra com três assuntos de exemplo e a regra que eles seguem:

```python
import subprocess
import sys

import anthropic

EXAMPLES = """Examples of this project's commit subjects:
Refuse a coupon after its last day
Keep shipping free from 200.00 after the discount
Format negative prices with the sign first
"""
diff = subprocess.run(["git", "diff", "HEAD"], capture_output=True, text=True).stdout
prompt = "Write a commit message for this diff. One line.\n\n" + diff
if "--examples" in sys.argv:
    prompt = EXAMPLES + "\nThe subject is imperative, under sixty characters, with no full stop.\n\n" + prompt
r = anthropic.Anthropic().messages.create(model="scripted-1", max_tokens=100,
                                          messages=[{"role": "user", "content": prompt}])
print(r.content[0].text)
```

```
ana@dev:~/shop$ python lab/subject.py
Updated the parse_price function to support a comma as the decimal separator and added validation for invalid inputs.
ana@dev:~/shop$ python lab/subject.py --examples
Accept a decimal comma in parse_price
```

A primeira resposta descreve a mudança no passado, longamente, com ponto final. É precisa e não é o
que este projeto escreve. A segunda segue os exemplos: imperativo, curto, sem ponto final, a mesma
regra que o `CONVENTIONS.md` dá para commits. As duas respostas foram escritas pelo curso para mostrar
a diferença que a técnica faz; a aula 5 seção 09 mede essa diferença em mais de um caso.

## Escolhendo os exemplos

- **Reais, do seu próprio material.** Exemplos inventados para o prompt puxam para o que o autor
  imagina e não para o que o projeto faz.
- **Diferentes entre si.** Três assuntos sobre o mesmo arquivo ensinam ao modelo que assuntos são
  sobre aquele arquivo. Varie o que deve variar, para só o padrão em comum ser copiado.
- **Não a resposta.** Um exemplo próximo demais da tarefa real é copiado em vez de generalizado;
  aparece palavra por palavra na resposta.
- **Poucos.** Três muitas vezes bastam para um formato. Cada exemplo é token em toda requisição, e a
  conta da aula 2 vale para eles como para todo o resto.

Exemplos ensinam forma muito melhor do que ensinam correção. Um prompt com exemplos para um
classificador vai fazer toda resposta parecer um rótulo; se é o rótulo certo é o que a aula 5 seção
09 confere.
