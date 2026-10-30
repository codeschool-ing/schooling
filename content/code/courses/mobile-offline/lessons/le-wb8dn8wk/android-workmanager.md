---
title: "Android: WorkManager"
version: 1
---

**On Android, background sync is a job you hand to WorkManager, with the conditions it needs to
run; you never start a thread and hope.** WorkManager is the Jetpack library Google recommends for
work that must eventually happen even if the app is closed or the phone restarts. It stores each
request in a database of its own, so a reboot does not lose it, and it runs the work through the
system's job scheduler, which is what respects Doze and the standby buckets of the previous
section.

*The listings in this section were not run for this course: the machine it was recorded on could
not install the Android SDK. They follow the WorkManager guide on developer.android.com.*

## The worker

A worker is a class with one function. Returning `Result.retry()` hands the failure back to
WorkManager, which waits and runs it again; `Result.success()` ends this run. `Planner.sync` stands
for your app's own sync, the outbox of lesson 8 followed by the pull of lesson 11:

```kotlin
class SyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result =
        try {
            Planner.sync(applicationContext)
            Result.success()
        } catch (e: IOException) {
            Result.retry()
        }
}
```

## The request

```kotlin
val request = PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES)
    .setConstraints(
        Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
    )
    .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
    .build()

WorkManager.getInstance(context)
    .enqueueUniquePeriodicWork("planner-sync", ExistingPeriodicWorkPolicy.KEEP, request)
```

Four decisions are written into those lines.

- **Fifteen minutes is the shortest period WorkManager accepts** for periodic work, and it is a
  minimum: Doze and the buckets decide the real interval, which can be hours.
- **The network constraint** means the job does not start without a connection. A sync that ran
  offline would fail, retry and spend battery to learn what the system already knew.
- **The backoff** is lesson 9's exponential backoff, done by WorkManager between retries, starting
  at thirty seconds.
- **Unique work with `KEEP`** means calling this on every launch, which is the simplest place for
  it, schedules one job and not one per launch. `REPLACE` would restart the period each time.

## Sync now, when the network comes back

A person who saves a session offline should not wait for the next period. Enqueue a one-time
request with the same constraint, and WorkManager runs it as soon as the phone is online:

```kotlin
val now = OneTimeWorkRequestBuilder<SyncWorker>()
    .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
    .build()
WorkManager.getInstance(context).enqueueUniqueWork("planner-sync-now", ExistingWorkPolicy.KEEP, now)
```

**A worker can be stopped while it runs**: when its constraint stops holding, or after the ten
minutes WorkManager allows a single run. In a `CoroutineWorker` that arrives as a cancelled
coroutine, so `Planner.sync` must save its progress as it goes. The last section of this lesson is
exactly that, run in Node.
