---
title: Mostrar em vez de descrever
version: 2
---

Alguns requisitos são mais fáceis de mostrar que de dizer. "Escreva assuntos de commit no nosso
estilo" é vago; três assuntos reais do projeto não são. Pôr alguns exemplos da saída que você quer
no prompt se chama **few-shot prompting** (prompting com poucos exemplos), e é a ferramenta mais
forte que existe para formato e estilo: o modelo continua o padrão que lhe mostraram.

## Um assunto de commit, de dois jeitos

O `CONVENTIONS.md` diz que o assunto de um commit fica no imperativo e com menos de sessenta
caracteres. Os cinco commits da própria loja foram feitos antes de alguém escrever isso, e são
substantivos soltos: `Conventions`, `README`, `Coupons`. O script da ana, `scratch/subject.py`, pede
um assunto para o commit mais recente, uma vez só com o diff dele, e outra com três assuntos escritos
segundo a regra e a própria regra:

```python
import subprocess
import sys

import anthropic

EXAMPLES = """Examples of this project's commit subjects:
Refuse a coupon after its last day
Keep shipping free from 200.00 after the discount
Format negative prices with the sign first
"""
diff = subprocess.run(["git", "show", "--format=", "HEAD"], capture_output=True, text=True).stdout
prompt = "Write a commit message for this diff. One line.\n\n" + diff
if "--examples" in sys.argv:
    prompt = EXAMPLES + "\nThe subject is imperative, under sixty characters, with no full stop.\n\n" + prompt
r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=100,
                                          messages=[{"role": "user", "content": prompt}])
print(r.content[0].text)
```

```
ana@dev:~/shop$ git log -1 --format=%s
Conventions
ana@dev:~/shop$ python scratch/subject.py
"Added Conventions file with coding and testing standards"
ana@dev:~/shop$ python scratch/subject.py --examples
Format negative prices with the sign first
```

A primeira resposta vem entre aspas e no passado. Está correta, e não é o que este projeto escreve. A
segunda tem exatamente a forma certa, imperativa, curta, sem ponto final, e é **um dos exemplos,
palavra por palavra**. O commit que ela descreve acrescenta o `CONVENTIONS.md`; não tem nada a ver
com preços negativos. O modelo copiou o padrão tão de perto que copiou o conteúdo junto.

Aí estão as duas metades da técnica em duas linhas. Os exemplos acertaram a forma na hora, e não
disseram nada ao modelo sobre o que este diff faz. A aula 5 seção 09, roda os mesmos dois prompts
sobre todos os commits, três vezes cada, e conta as duas coisas.

## Escolhendo os exemplos

- **Reais, do seu próprio material**, quando você os tem. Exemplos inventados para o prompt puxam
  para o que o autor imagina e não para o que o projeto faz. O histórico da ana não tinha nenhum que
  seguisse a regra, então ela escreveu três, que é a segunda melhor opção.
- **Diferentes entre si.** Três assuntos sobre o mesmo arquivo ensinam ao modelo que assuntos são
  sobre aquele arquivo. Varie o que deve variar, para só o padrão em comum ser copiado.
- **Não a resposta, nem perto dela.** Um exemplo próximo da tarefa real é copiado em vez de
  generalizado, e um modelo pequeno copia até um distante, como acima. A checagem para isso é
  barata: uma resposta igual a um dos exemplos está errada.
- **Poucos.** Três muitas vezes bastam para um formato. Cada exemplo é token em toda requisição, e a
  conta da aula 2 vale para eles como para todo o resto.

Exemplos ensinam forma muito melhor do que ensinam correção. Um prompt com exemplos para um
classificador vai fazer toda resposta parecer um rótulo; se é o rótulo certo é o que a aula 5 seção
09 confere.
