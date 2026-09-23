---
title: Três que valem escrever
version: 2
---

## Um cronômetro

```python
@contextmanager
def timed(label):
    start = time.perf_counter()
    try:
        yield
    finally:
        log.info("%s took %.3fs", label, time.perf_counter() - start)
```

O `finally` faz uma chamada que levantou erro ainda ser cronometrada, que é a que você mais quer
conhecer.

## Um diretório de trabalho

```python
@contextmanager
def in_directory(path):
    previous = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(previous)
```

**A restauração precisa estar num `finally`** — o ponto inteiro é que o diretório do processo é
global, e deixá-lo mudado afeta toda linha posterior do programa, e não só este bloco.

## Um ajuste temporário

```python
@contextmanager
def setting(obj, name, value):
    previous = getattr(obj, name)
    setattr(obj, name, value)
    try:
        yield
    finally:
        setattr(obj, name, previous)
```

Lembrar o valor antigo, definir o novo, devolver. Esta é a forma por trás da maior parte do que um
framework de testes chama de "patch", e a aula 16 usa o `unittest.mock.patch`, que é isto com mais
recursos.

## O que os três têm em comum

Eles guardam algo, mudam, e restauram — e a restauração está num `finally`. **Se você consegue
descrever um trecho como "e depois devolve como estava", ele é um gerenciador de contexto.**

## E um que não vale escrever

```python
@contextmanager
def logged(name):
    log.info("start %s", name)
    yield
    log.info("end %s", name)
```

Nada está sendo desfeito — a segunda linha não é um desfazer, é outra chamada de log. Isso é um
decorador, ou duas linhas, e um bloco `with` aqui só esconde que a linha do "fim" nunca roda numa
falha.
