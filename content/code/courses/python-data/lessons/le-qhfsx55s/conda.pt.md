---
title: O conda, e o ambiente que não é só Python
version: 1
---

**O conda gerencia ambientes como o `venv` e instala pacotes como o `pip`, mas os pacotes dele não
se limitam a Python.** Um pacote conda pode ser uma biblioteca C, um compilador, um cliente de banco
de dados ou um interpretador Python inteiro, feito para o seu sistema e instalado junto com o resto.
É por isso que tanto da ciência de dados o usa: GDAL para mapas, CUDA para uma placa de vídeo, um
BLAS específico para álgebra linear. O pip só instala o que é publicado como wheel Python, e para
essas coisas isso nem sempre é possível.

Para as bibliotecas deste curso, todas são wheels e o `venv` com o pip é tudo de que você precisa.
Esta seção instala o conda mesmo assim, porque você vai encontrar projetos que o usam, e porque ele
mostra uma falha que todo cientista de dados encontra no primeiro mês.

## Instalando

O **Miniforge** é o instalador pequeno da comunidade conda-forge: o próprio conda, um Python para
rodá-lo, e o conda-forge como único canal, que é o repositório livre, feito pela comunidade, de
pacotes conda. No Linux:

```
ana@lab:~$ curl -LO https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
ana@lab:~$ bash Miniforge3-Linux-x86_64.sh -b
Transaction finished

installation finished.
ana@lab:~$ source ~/miniforge3/bin/activate
(base) ana@lab:~$ conda --version
conda 26.7.2
```

O `curl` não imprime nada quando dá certo. O instalador, rodado sem `-b`, pede que você leia uma
licença e confirme onde instalar; `-b` aceita os padrões, que põem tudo em `~/miniforge3` e não
mudam nada fora dali. `source ~/miniforge3/bin/activate` inicia o conda neste terminal, e o prompt
mostra `(base)`, o ambiente em que o próprio conda vive. **Não instale nada no `base`**: é o
ambiente do conda, e quebrá-lo quebra o conda.

No Windows e no macOS, o Miniforge tem um instalador gráfico na página de download; nenhum dos dois
foi rodado neste curso.

## Criando um ambiente, e a versão que não está lá

O conda cria ambientes por nome, em `~/miniforge3/envs`, e instala neles no mesmo comando. As
mesmas sete bibliotecas, nas mesmas versões, do conda-forge:

```
(base) ana@lab:~$ conda create -y -q -n bikes -c conda-forge python=3.12 numpy=2.5.3 pandas=3.0.6 matplotlib=3.11.2 seaborn=0.13.2 pyarrow=26.0.0 openpyxl=3.1.5 jupyterlab=4.6.4
Channels:
 - conda-forge
Platform: linux-64
Collecting package metadata (repodata.json): ...working... done
Solving environment: ...working... failed
Channels:
 - conda-forge
Platform: linux-64
Collecting package metadata (repodata.json): ...working... done
Solving environment: ...working... failed

PackagesNotFoundInChannelsError: The following packages are not available from current channels:

  - pyarrow=26.0.0

Current channels:

  - https://conda.anaconda.org/conda-forge

To search for alternate channels that may provide the conda package you're
looking for, navigate to

    https://anaconda.org

and use the search bar at the top of the page.


```

**`pyarrow=26.0.0` não está no conda-forge**, embora o pip o tenha instalado na aula 1. Os dois
repositórios são montados por pessoas diferentes em ritmos diferentes, e uma versão pode existir no
PyPI semanas antes de o conda-forge tê-la, ou o contrário. A correção que mantém as versões é tirar
todo o resto do conda e esse pacote do pip, **nessa ordem**:

```
(base) ana@lab:~$ conda create -y -q -n bikes -c conda-forge python=3.12 numpy=2.5.3 pandas=3.0.6 matplotlib=3.11.2 seaborn=0.13.2 openpyxl=3.1.5 jupyterlab=4.6.4 > /dev/null && echo done
WARNING conda.conda_pypi.main:notify_externally_managed_future(156): 
  Did you know? You can install many PyPI packages with conda
  using the conda-pypi beta. Get started:
    https://docs.conda.io/projects/conda/en/stable/new-features.html

done
(base) ana@lab:~$ conda activate bikes
(bikes) ana@lab:~$ pip install -q pyarrow==26.0.0
(bikes) ana@lab:~$ conda list "^(numpy|pandas|pyarrow)$"
# packages in environment at /home/ana/miniforge3/envs/bikes:
#
# Name                     Version          Build               Channel
numpy                      2.5.3            py312he827f4e_0     conda-forge
pandas                     3.0.6            np2py312h91ec553_0  conda-forge
pyarrow                    26.0.0           pypi_0              pypi
```

O `conda list` mostra de onde veio cada pacote, na última coluna. `pypi` marca o que o pip pôs ali.
A regra é conda primeiro e pip por último: o pip não sabe nada dos pacotes do conda, e uma
instalação do conda feita depois do pip pode substituir o que o pip instalou sem avisá-lo.

## Anotando

O equivalente do conda ao `requirements.txt` é o `environment.yml`. `conda env export
--from-history` escreve um a partir do que você pediu, e não das centenas de pacotes que vieram
junto:

```
(bikes) ana@lab:~/pydata$ conda env export --from-history
/home/ana/miniforge3/lib/python3.14/site-packages/conda/cli/main_export.py:295: CondaExportWarning: The exported environment contains 3rd party Python packages.

Your environment contains 1 package installed via pip. Conda cannot reliably lock these packages for reproducible environments.

Detected packages:
  - pyarrow==26.0.0

Learn more: https://docs.conda.io/projects/conda/en/stable/user-guide/configuration/pip-interoperability.html
  warnings.warn(warning, CondaExportWarning)
name: bikes
channels:
  - conda-forge
dependencies:
  - openpyxl=3.1.5
  - python=3.12
  - matplotlib=3.11.2
  - numpy=2.5.3
  - jupyterlab=4.6.4
  - seaborn=0.13.2
  - pandas=3.0.6
prefix: /home/ana/miniforge3/envs/bikes
```

O aviso diz o problema: **o `pyarrow` não está na lista**, porque o conda só anotou o que o conda
instalou. Um ambiente reconstruído a partir desse arquivo não teria pyarrow nenhum. Então o
arquivo é terminado à mão, com uma seção `pip:`, e essa é a versão a guardar no projeto:

```yaml
name: bikes
channels:
  - conda-forge
dependencies:
  - python=3.12
  - numpy=2.5.3
  - pandas=3.0.6
  - matplotlib=3.11.2
  - seaborn=0.13.2
  - openpyxl=3.1.5
  - jupyterlab=4.6.4
  - pip
  - pip:
      - pyarrow==26.0.0
```

A prova é a mesma do `requirements.txt`: montar a partir do arquivo, com outro nome, e perguntar o
que saiu:

```
(base) ana@lab:~/pydata$ conda env create -q -n bikes2 -f environment.yml > /dev/null && echo done
WARNING conda.conda_pypi.main:notify_externally_managed_future(156): 
  Did you know? You can install many PyPI packages with conda
  using the conda-pypi beta. Get started:
    https://docs.conda.io/projects/conda/en/stable/new-features.html

done
(base) ana@lab:~/pydata$ conda run -n bikes2 python -c "import numpy, pandas, pyarrow; print(numpy.__version__, pandas.__version__, pyarrow.__version__)"
2.5.3 3.0.6 26.0.0
```

## Quanto custa

```
(base) ana@lab:~$ du -sh miniforge3/envs/bikes pydata/.venv
1.9G	miniforge3/envs/bikes
635M	pydata/.venv
(base) ana@lab:~$ du -sh --exclude=envs --exclude=pkgs miniforge3
430M	miniforge3
(base) ana@lab:~$ du -sh miniforge3/pkgs
2.5G	miniforge3/pkgs
```

**O ambiente conda tem o triplo do tamanho do `venv`**, para as mesmas sete bibliotecas, porque
traz o próprio Python e as próprias cópias das bibliotecas C por baixo delas, enquanto o `venv` usa
o Python do Ubuntu. O próprio conda ocupa mais 430 MB, e `pkgs` é o cache de cada pacote que ele
baixou, guardado para que o próximo ambiente que precise de um não o baixe de novo; `conda clean
--all` o esvazia quando o disco importa mais.

Esse é o preço de não depender do sistema, e é por isso que este curso recomenda o `venv` para o
próprio trabalho e o conda para os projetos que precisam de algo que o pip não instala.

Remova o que você criou aqui quando terminar: `conda env remove -n bikes2` apaga um ambiente, e
apagar `~/miniforge3` remove o conda por inteiro.
