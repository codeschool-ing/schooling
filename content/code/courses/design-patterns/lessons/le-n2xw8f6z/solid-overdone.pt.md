---
title: Quando o SOLID passa do ponto
version: 1
---

**Todo princípio das lições 3 e 4 acrescenta uma emenda, e uma emenda que ninguém usa é puro custo:
mais um arquivo para abrir, mais um nome para aprender, mais um salto entre uma pergunta e sua
resposta.** Aplicados onde se espera mudança, os princípios barateiam o código. Aplicados em todo
lugar, de antemão, eles o encarecem e chamam isso de qualidade.

A ideia errada aqui é que mais SOLID é sempre melhor, e que código com uma interface para cada
classe e uma fábrica para cada objeto é o código mais fiel aos princípios que existe. Os princípios
nunca disseram isso. Cada um deles depende de uma mudança: um segundo ator, um caso novo, uma
segunda implementação, um cliente que usa menos. Sem a mudança, a emenda é especulação.

## A mesma multa, duas vezes

Aqui está o cálculo da multa escrito do jeito que uma leitura zelosa demais do SOLID escreve:

```python
# overdone.py
from abc import ABC, abstractmethod


class IRateProvider(ABC):
    @abstractmethod
    def rate(self) -> int: ...


class DefaultRateProviderImpl(IRateProvider):
    def rate(self) -> int:
        return 50


class IFineCalculator(ABC):
    @abstractmethod
    def calculate(self, days_late: int) -> int: ...


class AbstractFineCalculatorBase(IFineCalculator):
    def __init__(self, rate_provider: IRateProvider):
        self.rate_provider = rate_provider


class DefaultFineCalculatorImpl(AbstractFineCalculatorBase):
    def calculate(self, days_late: int) -> int:
        return max(days_late, 0) * self.rate_provider.rate()


class FineCalculatorFactory:
    @staticmethod
    def create() -> IFineCalculator:
        return DefaultFineCalculatorImpl(DefaultRateProviderImpl())


if __name__ == "__main__":
    print(FineCalculatorFactory.create().calculate(5))
```

E do jeito que a biblioteca precisa dele hoje:

```python
# plain.py
DAILY_FINE = 50


def fine(days_late: int) -> int:
    return max(days_late, 0) * DAILY_FINE


if __name__ == "__main__":
    print(fine(5))
```

```
ana@laptop:~/patterns/solid-2$ python3 overdone.py
250
ana@laptop:~/patterns/solid-2$ python3 plain.py
250
ana@laptop:~/patterns/solid-2$ wc -l overdone.py plain.py
  37 overdone.py
  10 plain.py
  47 total
```

A mesma resposta, de seis classes contra uma função, e de mais do que o triplo de linhas. Para
descobrir quanto é a multa, quem lê `overdone.py` segue a fábrica até a implementação, a
implementação até o provedor, e o provedor até o número. **Cada abstração tem exatamente uma
implementação, então nenhuma delas separa nada de nada.**

## Sinais de que uma emenda é especulativa

- Uma interface com uma implementação e nenhum dublê de teste que a use.
- Um nome terminado em `Impl`, `Default`, `Base` ou `Manager`, que descreve o mecanismo porque nada
  no domínio precisava da classe.
- Uma fábrica que sempre constrói a mesma coisa.
- Um parâmetro ou um protocolo criado "para o caso de precisarmos de outro depois", sem caso à vista.
- Uma mudança que devia ser uma linha exigindo edições em quatro arquivos.

Nenhum desses é errado em toda base de código. Uma biblioteca publicada não consegue conhecer seus
usuários, então pode precisar de pontos de extensão para casos que os autores nunca vão ver. Código
de aplicação em geral consegue conhecer, e pode acrescentar a emenda no dia em que o segundo caso
chega, como argumentou a seção sobre aberto/fechado da lição 3.

## Onde `plain.py` amadurece

`plain.py` não é o fim da história; é o começo certo. Quando os estudantes ganham dias de carência,
a função ganha um parâmetro ou vira o `PerDay` e o `GraceDays` da lição 2. Quando as regras precisam
ser testadas sem servidor de e-mail, elas ganham uma porta `Notifier`, como nesta lição. Cada emenda
chega com a mudança que a justifica, e o nome dela vem dessa mudança.

**Um princípio se aplica em resposta a uma força que você consegue nomear**, e a lição 19 deste curso
transforma isso num hábito: nomear a força que dói antes de buscar o padrão. Até lá, o teste mais
curto é o que esta seção fez: pôr a versão cheia de princípios ao lado da simples, contar o que quem
lê precisa abrir, e perguntar por qual mudança o código a mais está esperando.
