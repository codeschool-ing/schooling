// modules/week-start/android/src/main/java/org/example/weekstart/WeekStartModule.kt
// The first day of the week in the phone's own calendar, for JavaScript.
package org.example.weekstart

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.util.Calendar
import java.util.Locale

// The rule, with nothing of React Native in it, so a plain JVM test can run it.
// Calendar counts SUNDAY = 1 to SATURDAY = 7; JavaScript's Date.getDay() counts Sunday = 0.
fun firstWeekday(locale: Locale): Int = Calendar.getInstance(locale).firstDayOfWeek - 1

class WeekStartModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("WeekStart")

    Function("firstWeekday") {
      firstWeekday(Locale.getDefault())
    }
  }
}
