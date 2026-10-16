---
title: A Brazilian CSV, with semicolons and decimal commas
version: 1
---

**In Brazil, and most of continental Europe, the comma is the decimal separator, so a "comma
separated" file separates its columns with semicolons instead.** A spreadsheet set to Portuguese
writes files that way, and `read_csv`, which assumes the English convention, reads them wrong
without failing.

Make one, the way a spreadsheet in Recife would save the weather:

```python
weather = pd.read_csv("weather.csv")
weather.to_csv("weather_br.csv", sep=";", decimal=",", index=False)
with open("weather_br.csv") as f:
    print(f.read(70))
```

```
date;rain_mm;temp_max
2025-01-01;0,0;29,9
2025-01-02;6,8;30,0
2025-01-
```

`index=False` leaves the RangeIndex out of the file; without it, the first column of the file would
be the numbers 0 to 364, which nobody wants. Now read it as if it were an ordinary CSV:

```python
wrong = pd.read_csv("weather_br.csv")
wrong.shape, wrong.columns.tolist()
```

```
((365, 1), ['date;rain_mm;temp_max'])
```

**Two columns, not three**, with names nobody chose. `read_csv` split every line at its commas,
which here are the decimal points: `2025-01-01;0,0;29,9` became `2025-01-01;0` and `0;29` and `9`,
and with one header field fewer than data fields, it quietly used the first piece as the index. No
error. A `shape` that is not what you expected is the only symptom, which is why lesson 9 said to
read it first.

Tell it both conventions:

```python
right = pd.read_csv("weather_br.csv", sep=";", decimal=",")
right.dtypes, right["rain_mm"].sum().round(1)
```

```
(date            str
 rain_mm     float64
 temp_max    float64
 dtype: object,
 np.float64(1712.8))
```

Three columns, two of them numbers, and the year's rain matching lesson 5's 1712.8. With `sep=";"`
alone the columns would split correctly and the numbers would stay text, `0,0` and `29,9`, which no
arithmetic reads.

| file written by | separator | decimal | `read_csv` needs |
|---|---|---|---|
| English-language software, most systems | `,` | `.` | nothing |
| a spreadsheet in Portuguese | `;` | `,` | `sep=";", decimal=","` |
| a tab-separated export | a tab | `.` | `sep="\t"` |

Encoding is the other half of the same problem: an older Windows export may be Latin-1 rather than
UTF-8, and `Praça` arrives as `PraÃ§a` or fails to decode. `encoding="latin-1"` reads it. The files
this course makes are UTF-8, and `stations.csv` has the `ç` to prove it.
