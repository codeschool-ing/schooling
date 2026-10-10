---
title: Better than what?
version: 1
---

**A forecast is only good compared with something**, and the comparison most often skipped is the
one with the forecasts that need no method. Before anybody fits Holt-Winters, ARIMA or Prophet,
three baselines should be on the table:

| baseline | the forecast | what it beats you at |
|---|---|---|
| **naive** | the last value, repeated | series that wander, where the latest value is the best guess |
| **seasonal naive** | the same week last year | series dominated by a stable season |
| **mean** | the average of the history | series that are mostly noise around a fixed level |

They cost nothing, nobody has to maintain them, and on many real series one of them is hard to
beat. A method that cannot beat the seasonal naive forecast is adding complexity and no accuracy,
and it should not be used, however sophisticated it sounds. Lesson 5 measures all of this lesson's
forecasts against the naive and seasonal naive ones on the same 2025 weeks.

## Choosing among the three families

| | exponential smoothing | ARIMA | Prophet |
|---|---|---|---|
| thinks in terms of | level, trend, season | dependence on the recent past | trend with bends, seasons, holidays |
| needs from you | trend and season types | `p`, `d`, `q` and their seasonal twins | holiday list, changepoints if known |
| at its best | stable seasonal business series | series with short-term momentum | daily data, several seasons, many holidays |
| cost of a mistake | usually mild | a badly chosen order can forecast nonsense | a wrong holiday list fits the wrong story |

**None of them is the best in general**, and forecasting competitions over thousands of real series
have found again and again that simple methods and averages of several methods are hard to beat.
The practical rule is short: start with the baselines, fit one or two methods that suit the
series, and keep whichever does best on data it did not see. Lessons 4 and 5 are how.
