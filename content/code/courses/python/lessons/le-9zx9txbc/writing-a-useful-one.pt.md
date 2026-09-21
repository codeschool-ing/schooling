---
title: Três que valem escrever
version: 1
---

## Um cronômetro

```python
@contextmanager
def cronometrado(rotulo):
    inicio = time.perf_counter()
    try:
        yield
    finally:
        log.info("%s levou %.3fs", rotulo, time.perf_counter() - inicio)
```

O `finally` faz uma chamada que levantou erro ainda ser cronometrada, que é a que você mais quer
conhecer.

## Um diretório de trabalho

```python
@contextmanager
def em_diretorio(caminho):
    anterior = Path.cwd()
    os.chdir(caminho)
    try:
        yield
    finally:
        os.chdir(anterior)
```

**A restauração precisa estar num `finally`** — o ponto inteiro é que o diretório do processo é
global, e deixá-lo mudado afeta toda linha posterior do programa, e não só este bloco.

## Um ajuste temporário

```python
@contextmanager
def ajuste(obj, nome, valor):
    anterior = getattr(obj, nome)
    setattr(obj, nome, valor)
    try:
        yield
    finally:
        setattr(obj, nome, anterior)
```

Lembrar o valor antigo, definir o novo, devolver. Esta é a forma por trás da maior parte do que um
framework de testes chama de "patch", e a aula 15 usa o `unittest.mock.patch`, que é isto com mais
recursos.

## O que os três têm em comum

Eles guardam algo, mudam, e restauram — e a restauração está num `finally`. **Se você consegue
descrever um trecho como "e depois devolve como estava", ele é um gerenciador de contexto.**

## E um que não vale escrever

```python
@contextmanager
def registrado(nome):
    log.info("início %s", nome)
    yield
    log.info("fim %s", nome)
```

Nada está sendo desfeito — a segunda linha não é um desfazer, é outra chamada de log. Isso é um
decorador, ou duas linhas, e um bloco `with` aqui só esconde que a linha do "fim" nunca roda numa
falha.
