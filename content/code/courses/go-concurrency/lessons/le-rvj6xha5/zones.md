---
title: Time zones, and the layout that is a date
version: 1
---

A `time.Time` is an instant, the same everywhere on Earth, plus a location that says how to print
it. **Changing the location changes the words on the screen and never the instant.** Most mistakes
with time zones come from treating `14:30` as a fact, when it is `14:30` somewhere.

A meeting fixed in São Paulo, printed in three other places, saved as `zones.go`:

```go
// Command zones prints one instant in several places.
package main

import (
	"fmt"
	"time"
)

func main() {
	sp, err := time.LoadLocation("America/Sao_Paulo")
	if err != nil {
		fmt.Println(err)
		return
	}
	meeting := time.Date(2026, time.October, 16, 14, 30, 0, 0, sp)
	for _, name := range []string{"UTC", "Europe/Lisbon", "Asia/Tokyo"} {
		loc, _ := time.LoadLocation(name)
		fmt.Printf("%-14s %s\n", name, meeting.In(loc).Format("2006-01-02 15:04 MST"))
	}
	fmt.Println("same instant:", meeting.Equal(meeting.UTC()))

	_, err = time.LoadLocation("America/Sao Paulo")
	fmt.Println(err)
}
```

```
ana@vm:~/clock$ go run zones.go
UTC            2026-10-16 17:30 UTC
Europe/Lisbon  2026-10-16 18:30 WEST
Asia/Tokyo     2026-10-17 02:30 JST
same instant: true
unknown time zone America/Sao Paulo
```

Half past two in São Paulo is 17:30 in UTC, three hours on. Lisbon is on summer time in October,
`WEST`, one hour past UTC; Tokyo is already on the next day. **`Equal` compares instants and said
the São Paulo value and its UTC copy are the same one.** The `==` operator compares the whole
struct, location included, and would have said they differ, so time values are compared with
`Equal`, `Before` and `After`.

The last line is the commonest error. A location is named by the IANA database, where spaces are
underscores. São Paulo's offset has been a fixed three hours behind UTC since Brazil ended summer
time in 2019, and that history is exactly what the name looks up: `time.FixedZone("-03", -3*3600)`
would print the same today and the wrong hour for a summer date before 2019.

## Where the zone database comes from

`LoadLocation` reads the database from the operating system, which on Ubuntu is the `tzdata`
package:

```
ana@vm:~/clock$ ls -l /usr/share/zoneinfo/America/Sao_Paulo
-rw-r--r-- 1 root root 1444 Jul 17 09:49 /usr/share/zoneinfo/America/Sao_Paulo
ana@vm:~/clock$ dpkg -S /usr/share/zoneinfo/America/Sao_Paulo
tzdata: /usr/share/zoneinfo/America/Sao_Paulo
```

A minimal container image often has no `/usr/share/zoneinfo` at all, and there the same program
fails with `unknown time zone` for a name that is spelt correctly. **The program can carry the
database inside itself**: importing `time/tzdata` anywhere in it, or building with the tag
`timetzdata`, embeds a copy. The price is the size of the binary:

```
ana@vm:~/clock$ go build -o z1 zones.go
ana@vm:~/clock$ go build -tags timetzdata -o z2 zones.go
ana@vm:~/clock$ wc -c z1 z2
2461115 z1
2877291 z2
5338406 total
```

416,176 bytes more, about 400 KB, for a program that answers the same everywhere. The system's
copy is still used first when it exists, so the embedded one is a fallback.

## The layout is a date

Every other language formats dates with letters, `%Y-%m-%d` or `yyyy-MM-dd`. **Go formats with an
example: one fixed moment, written the way you want yours written.** The moment is Monday,
January 2nd 2006, at 3:04:05 in the afternoon, in the zone seven hours behind UTC; in the order
the American date writes it, the numbers are 1 2 3 4 5 6 7. Saved as `layout.go`:

```go
// Command layout formats and parses with Go's reference time.
package main

import (
	"fmt"
	"time"
)

func main() {
	t := time.Date(2026, time.March, 5, 9, 7, 3, 0, time.UTC)
	fmt.Println(t.Format(time.RFC3339))
	fmt.Println(t.Format("02/01/2006 15:04"))
	fmt.Println(t.Format("2006-01-02 3:04PM"))
	fmt.Println(t.Format("DD/MM/YYYY"))

	p, err := time.Parse("02/01/2006", "05/03/2026")
	fmt.Println(p, err)
	_, err = time.Parse("2006-01-02", "05/03/2026")
	fmt.Println(err)
}
```

```
ana@vm:~/clock$ go run layout.go
2026-03-05T09:07:03Z
05/03/2026 09:07
2026-03-05 9:07AM
DD/MM/YYYY
2026-03-05 00:00:00 +0000 UTC <nil>
parsing time "05/03/2026" as "2006-01-02": cannot parse "05/03/2026" as "2006"
```

`02/01/2006` is the Brazilian order, day first, and `15` asks for a 24-hour clock where `3` and
`PM` ask for a 12-hour one. **`DD/MM/YYYY` printed itself**, letter for letter, because none of
those letters is part of the reference moment, and the compiler has no way to know you meant
something else; `go vet` is no help either. `Parse` takes the same kind of layout, and when the
text does not match it says which piece failed: it expected the four digits of `2006` and found
`05/03/2026` instead.

A parsed time with no zone in the text comes back in UTC, as the fifth line shows. Text that came
from a person in São Paulo is read with `time.ParseInLocation` and the location from the start of
this section.
