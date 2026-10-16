---
title: When SOLID is overdone
version: 1
---

**Every principle in lessons 3 and 4 adds a seam, and a seam nobody uses is pure cost: one more file
to open, one more name to learn, one more hop between a question and its answer.** Applied where
change is expected, the principles make code cheaper. Applied everywhere, in advance, they make
it more expensive and call that quality.

The wrong idea here is that more SOLID is always better, so that code with an interface for every
class and a factory for every object is the most principled code there is. The principles never
said that. Each of them is conditional on a change: a second actor, a new case, a second
implementation, a client that uses less. Without the change, the seam is speculation.

## The same fine, twice

Here is the fine calculation written the way an over-zealous reading of SOLID writes it:

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

And the way the library needs it today:

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

The same answer, from six classes against one function, and from more than three times the
lines. To find out what the fine is, a reader of `overdone.py` follows the factory to the
implementation, the implementation to the provider, and the provider to the number. **Each
abstraction has exactly one implementation, so none of them separates anything from anything.**

## Signs a seam is speculative

- An interface with one implementation and no test double that uses it.
- A name ending in `Impl`, `Default`, `Base` or `Manager`, which describes the mechanism because
  nothing in the domain needed the class.
- A factory that always builds the same thing.
- A parameter or a protocol introduced "in case we need another one later", with no case in sight.
- A change that should be one line taking edits in four files.

None of these is wrong in every codebase. A published library cannot know its users, so it may
need extension points for cases its authors will never see. Application code usually can know,
and can add the seam on the day the second case arrives, as lesson 3's open/closed section argued.

## Where `plain.py` grows up

`plain.py` is not the end of the story; it is the right start. When students get grace days, the
function gains a parameter or becomes the `PerDay` and `GraceDays` of lesson 2. When the rules need
testing without a mail server, they get a `Notifier` port, as in this lesson. Each seam arrives
with the change that justifies it, and its name comes from that change.

**A principle is applied in answer to a force you can name**, and lesson 19 of this course turns
that into a habit: name the force that hurts before reaching for the pattern. Until then, the
shortest test is the one this section ran: put the principled version next to the plain one, count
what the reader has to open, and ask which change the extra code is waiting for.
