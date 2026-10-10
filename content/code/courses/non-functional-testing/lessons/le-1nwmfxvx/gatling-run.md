---
title: Running a simulation, and its report
version: 1
---

A simulation is run by Maven, through the wrapper in the bundle, and the property
`gatling.simulationClass` says which class to run. Start the box office in the first terminal,
then, in the second, from the bundle's directory:

```sh
cd ~/gatling-charts-highcharts-bundle-3.15.1
./mvnw gatling:test -Dgatling.simulationClass=boxoffice.BoxOfficeSimulation
```

Maven compiles the class first, then Gatling prints a block of counts every five seconds while
the test runs, and a summary at the end. The transcript below sends all of it to a file, `run.log`,
prints the exit code, and then shows the file from the summary on:

```
ana@nft:~/gatling-charts-highcharts-bundle-3.15.1$ ./mvnw gatling:test -Dgatling.simulationClass=boxoffice.BoxOfficeSimulation > run.log; echo "exit $?"
Oct 10, 2026 4:37:50 PM java.util.prefs.FileSystemPreferences$1 run
INFO: Created user preferences directory.
exit 0
ana@nft:~/gatling-charts-highcharts-bundle-3.15.1$ sed -n '/Global Information/,$p' run.log
---- Global Information -------------------------------------------------------------|---Total---|-----OK----|----KO----
> request count                                                                      |       110 |       110 |         -
> min response time (ms)                                                             |        14 |        14 |         -
> max response time (ms)                                                             |       252 |       252 |         -
> mean response time (ms)                                                            |        65 |        65 |         -
> response time std deviation (ms)                                                   |        48 |        48 |         -
> response time 50th percentile (ms)                                                 |        58 |        58 |         -
> response time 75th percentile (ms)                                                 |        84 |        84 |         -
> response time 95th percentile (ms)                                                 |       155 |       155 |         -
> response time 99th percentile (ms)                                                 |       249 |       249 |         -
> mean throughput (rps)                                                              |         5 |         5 |         -
---- Response Time Distribution ----------------------------------------------------------------------------------------
> OK: t < 800 ms                                                                                            110   (100%)
> OK: 800 ms <= t < 1200 ms                                                                                   0     (0%)
> OK: t >= 1200 ms                                                                                            0     (0%)
> KO                                                                                                          0     (0%)
========================================================================================================================

Reports generated, please open the following file: file:///home/ana/gatling-charts-highcharts-bundle-3.15.1/target/gatling/boxofficesimulation-20261010193751406/index.html
show: 95th percentile of response time is less than 200.0 : true (actual : 83.0)
Global: percentage of failed events is less than 1.0 : true (actual : 0.0)
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  30.753 s
[INFO] Finished at: 2026-10-10T16:38:14-03:00
[INFO] ------------------------------------------------------------------------
```

The two lines before the exit code come from Java creating a preferences directory in a home that
never had one; they appear once and mean nothing for the test.

## The console summary

| line | what it says here |
|---|---|
| `request count` | 110 requests, all of them in the `OK` column: no check failed |
| `min`, `max`, `mean` | 14, 252 and 65 ms, over the shows and the bookings together |
| `response time std deviation` | 48 ms: how far the times spread around the mean |
| `50th`, `75th`, `95th`, `99th percentile` | 58, 84, 155 and 249 ms |
| `mean throughput (rps)` | 5 requests a second, over the whole run |
| `Response Time Distribution` | how many answers fell under 800 ms, between 800 and 1,200, above, and how many were KO |

**Gatling's own columns are `OK` and `KO`**: OK is a request that passed every check, KO one
that failed any of them. The 800 and 1,200 ms boundaries of the distribution
are Gatling's defaults, set in `gatling.conf`, and have nothing to do with this course's
requirement. As with k6, many of these times include about 40 ms spent outside the application, on a
connection the generator keeps open; lesson 9 finds where.

**Then come the assertions, one line each, with the value that was compared.** `show: 95th
percentile of response time is less than 200.0 : true (actual : 83.0)` is lesson 1's requirement
for `GET /shows/{id}`, met. Both held, Maven printed `BUILD SUCCESS`, and the exit code was 0.

## An assertion that fails

`-Dp95=5` asks for a 95th percentile under 5 ms, which no request to this box office can reach:

```
ana@nft:~/gatling-charts-highcharts-bundle-3.15.1$ ./mvnw gatling:test -Dgatling.simulationClass=boxoffice.BoxOfficeSimulation -Dp95=5 > run.log; echo "exit $?"
exit 1
ana@nft:~/gatling-charts-highcharts-bundle-3.15.1$ sed -n '/Reports generated/,/BUILD/p' run.log
Reports generated, please open the following file: file:///home/ana/gatling-charts-highcharts-bundle-3.15.1/target/gatling/boxofficesimulation-20261010193821502/index.html
show: 95th percentile of response time is less than 5.0 : false (actual : 33.0)
Global: percentage of failed events is less than 1.0 : true (actual : 0.0)
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
```

**A crossed assertion fails the Maven build, and the exit code is 1.** Maven exits with 1 for any
failure, so the pipeline sees a failed load test the same way it sees a failed unit test, and the
line saying `false` is where you find out which assertion it was.

## The HTML report

Every run writes a report, and its path is the line `Reports generated` prints. Each run gets a
directory of its own, named after the simulation and the moment it started:

```
ana@nft:~/gatling-charts-highcharts-bundle-3.15.1$ ls target/gatling/*/index.html
target/gatling/boxofficesimulation-20261010193751406/index.html
target/gatling/boxofficesimulation-20261010193821502/index.html
```

**The report is one `index.html` per run**, with the same numbers drawn as charts: active users
and requests a second over time, response times over time by percentile, and a page per request
name, `show` and `booking`. It needs a browser, so open it on your own computer: copy the
directory out of the VM with `multipass transfer --recursive`, or start `python3 -m http.server 8090
--bind 0.0.0.0` inside `target/gatling` and open the VM's address on port 8090. Neither was done
for this course; the transcripts show only the console.
