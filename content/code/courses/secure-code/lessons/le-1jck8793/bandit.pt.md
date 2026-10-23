---
title: bandit, uma verificação estática para Python
version: 1
---

O **bandit** lê código-fonte Python sem executá-lo e aponta chamadas e padrões sabidamente
arriscados: uma senha escrita como string, o módulo `random` usado onde a imprevisibilidade importa,
um hash fraco usado para segurança, o depurador do Flask deixado ligado. É uma ferramenta de
**análise estática**, a prima de um linter preocupada com segurança, e é mantida pela Python Code
Quality Authority. Instale no ambiente do curso:

```
(.venv) ana@vm:~/sc/checks$ pip install --progress-bar off bandit==1.9.4
Collecting bandit==1.9.4
  Using cached bandit-1.9.4-py3-none-any.whl.metadata (7.1 kB)
Collecting PyYAML>=5.3.1 (from bandit==1.9.4)
  Using cached pyyaml-6.0.3-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl.metadata (2.4 kB)
Collecting stevedore>=1.20.0 (from bandit==1.9.4)
  Using cached stevedore-5.9.1-py3-none-any.whl.metadata (2.3 kB)
Requirement already satisfied: rich in /home/ana/sc/.venv/lib/python3.13/site-packages (from bandit==1.9.4) (15.0.0)
Requirement already satisfied: markdown-it-py>=2.2.0 in /home/ana/sc/.venv/lib/python3.13/site-packages (from rich->bandit==1.9.4) (4.2.0)
Requirement already satisfied: pygments<3.0.0,>=2.13.0 in /home/ana/sc/.venv/lib/python3.13/site-packages (from rich->bandit==1.9.4) (2.21.0)
Requirement already satisfied: mdurl~=0.1 in /home/ana/sc/.venv/lib/python3.13/site-packages (from markdown-it-py>=2.2.0->rich->bandit==1.9.4) (0.1.2)
Using cached bandit-1.9.4-py3-none-any.whl (134 kB)
Using cached pyyaml-6.0.3-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (801 kB)
Using cached stevedore-5.9.1-py3-none-any.whl (54 kB)
Installing collected packages: stevedore, PyYAML, bandit
Successfully installed PyYAML-6.0.3 bandit-1.9.4 stevedore-5.9.1
```

Eis um pedaço do portal que a ana escreveu com pressa: a chave secreta, o código de seis dígitos
enviado por SMS quando um paciente redefine a senha, e o identificador impresso num recibo. Salve
como `app.py`:

```python
# app.py
import hashlib
import random

from flask import Flask

app = Flask(__name__)
app.secret_key = "vereda-dev"


def reset_code():
    return "".join(random.choice("0123456789") for _ in range(6))


def receipt_id(booking):
    return hashlib.md5(str(booking).encode()).hexdigest()


if __name__ == "__main__":
    app.run(debug=True)
```

E dois testes ao lado, como `test_app.py`:

```python
# test_app.py
import app as portal


def test_a_reset_code_is_six_digits():
    code = portal.reset_code()
    assert len(code) == 6
    assert code.isdigit()


def test_a_receipt_id_is_stable():
    assert portal.receipt_id(101) == portal.receipt_id(101)
```

Os dois testes passam. Cada função faz o que diz. Agora pergunte ao bandit:

```
(.venv) ana@vm:~/sc/checks$ bandit -q app.py
Run started:2026-10-23 14:05:19.345039+00:00

Test results:
>> Issue: [B105:hardcoded_password_string] Possible hardcoded password: 'vereda-dev'
   Severity: Low   Confidence: Medium
   CWE: CWE-259 (https://cwe.mitre.org/data/definitions/259.html)
   More Info: https://bandit.readthedocs.io/en/1.9.4/plugins/b105_hardcoded_password_string.html
   Location: ./app.py:8:17
7	app = Flask(__name__)
8	app.secret_key = "vereda-dev"
9	

--------------------------------------------------
>> Issue: [B311:blacklist] Standard pseudo-random generators are not suitable for security/cryptographic purposes.
   Severity: Low   Confidence: High
   CWE: CWE-330 (https://cwe.mitre.org/data/definitions/330.html)
   More Info: https://bandit.readthedocs.io/en/1.9.4/blacklists/blacklist_calls.html#b311-random
   Location: ./app.py:12:19
11	def reset_code():
12	    return "".join(random.choice("0123456789") for _ in range(6))
13	

--------------------------------------------------
>> Issue: [B324:hashlib] Use of weak MD5 hash for security. Consider usedforsecurity=False
   Severity: High   Confidence: High
   CWE: CWE-327 (https://cwe.mitre.org/data/definitions/327.html)
   More Info: https://bandit.readthedocs.io/en/1.9.4/plugins/b324_hashlib.html
   Location: ./app.py:16:11
15	def receipt_id(booking):
16	    return hashlib.md5(str(booking).encode()).hexdigest()
17	

--------------------------------------------------
>> Issue: [B201:flask_debug_true] A Flask app appears to be run with debug=True, which exposes the Werkzeug debugger and allows the execution of arbitrary code.
   Severity: High   Confidence: Medium
   CWE: CWE-94 (https://cwe.mitre.org/data/definitions/94.html)
   More Info: https://bandit.readthedocs.io/en/1.9.4/plugins/b201_flask_debug_true.html
   Location: ./app.py:20:4
19	if __name__ == "__main__":
20	    app.run(debug=True)

--------------------------------------------------

Code scanned:
	Total lines of code: 11
	Total lines skipped (#nosec): 0
	Total potential issues skipped due to specifically being disabled (e.g., #nosec BXXX): 0

Run metrics:
	Total issues (by severity):
		Undefined: 0
		Low: 2
		Medium: 0
		High: 2
	Total issues (by confidence):
		Undefined: 0
		Low: 0
		Medium: 2
		High: 2
Files skipped (0):
```

Quatro achados, cada um com um identificador, uma gravidade, uma confiança e a linha. Leia como
perguntas que um revisor faria:

- **B105, uma senha escrita no código.** A chave de sessão é uma string no código, o que a aula 18
  chamou de segredo no repositório. A aula 16 diz onde ela deve ficar.
- **B311, `random` para um código de redefinição.** O `random` do Python foi feito para simulações e
  é previsível a partir de saída suficiente dele. Um código que prova que uma pessoa tem um telefone
  precisa do módulo `secrets`, que tira valores da fonte segura do sistema operacional.
- **B324, MD5.** O MD5 está quebrado como hash de segurança. Aqui o identificador do recibo nem é um
  controle de segurança, que é exatamente o caso da próxima seção.
- **B201, `debug=True`.** O depurador do Flask deixa quem abre uma página de erro rodar Python no
  servidor, protegido só por um PIN que o servidor imprime no próprio log. Na máquina de quem
  desenvolve, esse é o propósito; em qualquer outro lugar, é o servidor entregue a quem achar a
  página.

Nenhum dos quatro é visível para os testes, porque nenhum muda o que as funções devolvem. Essa é a
brecha que uma verificação estática preenche.
