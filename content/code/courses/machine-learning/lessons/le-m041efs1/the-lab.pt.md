---
title: O laboratório, e três jeitos de montá-lo
version: 1
---

**Um modelo se ajusta, não se descreve.** Toda aula deste curso roda alguma coisa: uma divisão, um
ajuste, uma nota, uma curva. Você vai entender uma matriz de confusão muito melhor depois que um
programa seu imprimir uma que discorda do que você esperava, então o curso é feito para ser rodado,
num computador que você mesmo prepara. Esta seção o prepara. A próxima faz os dados.

O laboratório é uma pasta, `~/ml`, com três coisas dentro:

- **Python 3.12 ou mais novo**, num **ambiente virtual** só dele, `~/ml/.venv`, para que nada
  instalado aqui mexa no Python que o seu sistema ou os seus outros cursos usam;
- **as bibliotecas**: scikit-learn para quase tudo, pandas e NumPy por baixo, XGBoost e LightGBM
  para a aula 8, UMAP para a aula 17, SHAP para a aula 19, e FastAPI com Uvicorn para a aula 21, que
  põe um modelo atrás de um endereço;
- **os dados**, em `~/ml/data`, gravados por um programa que você cola na próxima seção.

Nada neste curso precisa de placa de vídeo. **Um processador basta**, e essa é a linha entre este
curso e o `deep-learning`; o maior ajuste daqui leva segundos, não horas.

## Três jeitos de ter um

| caminho | o que custa ao seu computador | as transcrições |
|---|---|---|
| **instalado, num ambiente virtual** (recomendado) | cerca de 710 MB de disco dentro de uma pasta, e nada fora dela | batem como impressas no Ubuntu 24.04; próximas em outros sistemas |
| **numa máquina virtual** | uma máquina Ubuntu 24.04: uns 25 GB de disco, e a memória e os processadores que você emprestar | batem como impressas |
| **online** | nada no seu computador; uma conta com alguém, nos termos dessa empresa | próximas, não exatas |

**Instalar é o caminho recomendado para este curso.** Quase tudo o que uma aula faz é aritmética, e
uma máquina virtual tira processador e memória dela. Um ambiente virtual não muda nada fora da
própria pasta, então apagar `~/ml` remove o laboratório inteiro. Se você montou uma máquina virtual
para o `data-cleaning`, ela serve igualmente aqui; a aula 1 daquele curso monta o mesmo tipo de
máquina.

**Numa máquina virtual**, a aula 4 do `virtualization` monta uma no VirtualBox. Dê a ela pelo menos
4 GB de memória e dois processadores. No Windows, o WSL rodando Ubuntu 24.04 também é uma máquina
virtual, e os comandos abaixo funcionam ali sem mudança.

**Online**, o Google Colab dá um notebook com Python no navegador, e o GitHub Codespaces dá uma
máquina Linux com terminal. Os dois não custam nada ao seu computador, e os dois pertencem a uma
empresa que define a cota e pode mudá-la, por isso o curso não depende de nenhum. Nenhum foi usado
para gravar nada aqui. Em qualquer um deles, instale o mesmo `requirements.txt` abaixo antes de
começar, porque as versões que eles trazem não são as que estas aulas imprimem.

As transcrições foram gravadas no Ubuntu 24.04, onde o prompt diz `ana@lab:~/ml$`: `ana` é a
pessoa, `lab` a máquina e `~/ml` a pasta. O seu mostra o seu nome.

## Montando

Abra um terminal e crie a pasta:

```sh
mkdir ~/ml
cd ~/ml
```

Depois, um arquivo que nomeia cada biblioteca e sua versão exata. **As versões são fixadas de
propósito**: um scikit-learn mais novo pode mudar um padrão, e um padrão mudado muda uma nota, o que
é parte da aula 15. Salve isto como `~/ml/requirements.txt`. Qualquer editor serve; `nano
requirements.txt` abre um no terminal, salva com Ctrl+O e sai com Ctrl+X.

```
# requirements.txt
scikit-learn==1.9.1
pandas==3.0.6
numpy==2.5.3
scipy==1.18.1
matplotlib==3.11.2
xgboost-cpu==3.4.1
lightgbm==4.7.0
shap==0.53.0
umap-learn==0.5.12
fastapi==0.143.0
uvicorn==0.54.0
```

`xgboost-cpu` é o XGBoost sem o código para placa de vídeo, o que no Linux é uma diferença de uns
300 MB por nada que este curso usa. Agora o ambiente, e as bibliotecas dentro dele:

```
ana@lab:~/ml$ python3 --version
Python 3.12.3
ana@lab:~/ml$ python3 -m venv .venv
ana@lab:~/ml$ source .venv/bin/activate
ana@lab:~/ml$ pip install --quiet -r requirements.txt
```

`--quiet` impede o pip de imprimir cada arquivo que baixa, então **silêncio aqui é sucesso**.

Por último, cinco linhas no fim do `~/.bashrc`, para todo terminal novo começar do mesmo jeito:

```sh
cat >> ~/.bashrc <<'EOF'
# machine-learning
export TZ=America/Sao_Paulo
export VIRTUAL_ENV_DISABLE_PROMPT=1
source ~/ml/.venv/bin/activate
EOF
```

`TZ` põe a máquina no relógio da empresa. A última linha **ativa** o ambiente: daí em diante,
`python` e `pip` são os de `~/ml/.venv`. Ativar normalmente acrescenta `(.venv)` no começo do
prompt, e a linha anterior desliga isso, para o seu prompt ficar igual ao das transcrições. Abra um
terminal novo, faça `cd ~/ml` e confira:

```
ana@lab:~/ml$ which python
/home/ana/ml/.venv/bin/python
ana@lab:~/ml$ python --version
Python 3.12.3
ana@lab:~/ml$ python -c "import sklearn, pandas, numpy; print(sklearn.__version__, pandas.__version__, numpy.__version__)"
1.9.1 3.0.6 2.5.3
```

Esse é o laboratório inteiro. Ele ocupa este tanto de disco:

```
ana@lab:~/ml$ du -sh .venv
711M	.venv
```

## Fora do Linux

Duas coisas mudam, e nenhuma foi gravada aqui.

- **No Windows**, fora do WSL, instale o Python 3.12 do `python.org` e marque *Add python.exe to
  PATH*. Os programas do ambiente ficam em `.venv\Scripts\` em vez de `.venv/bin/`, então ativá-lo
  é `.venv\Scripts\activate`, e não existe `~/.bashrc`: você ativa em cada terminal novo.
- **No macOS**, os comandos são os mesmos. No `requirements.txt`, escreva `xgboost==3.4.1` onde diz
  `xgboost-cpu==3.4.1`, porque o segundo não é publicado para macOS. A documentação do próprio
  LightGBM pede OpenMP no macOS, que o Homebrew instala com `brew install libomp`.

Se você preferir trabalhar num notebook, como no `python-data`, instale o JupyterLab no mesmo
ambiente com `pip install jupyterlab` e abra um em `~/ml`. O curso mostra programas salvos em
arquivo e rodados inteiros, pelo motivo que o `python-data` deu na última aula: um arquivo roda de
cima a baixo toda vez, e um notebook roda na ordem em que as células foram clicadas por último.
