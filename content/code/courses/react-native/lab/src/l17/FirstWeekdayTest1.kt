// modules/week-start/android/src/test/java/org/example/weekstart/FirstWeekdayTest.kt
// The rule, run on the computer's JVM, without a phone.
package org.example.weekstart

import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Test

class FirstWeekdayTest {
  @Test fun brazilStartsOnSunday() = assertEquals(0, firstWeekday(Locale.forLanguageTag("pt-BR")))

  @Test fun theUnitedKingdomStartsOnMonday() = assertEquals(1, firstWeekday(Locale.forLanguageTag("en-GB")))

  @Test fun portugalStartsOnMonday() = assertEquals(1, firstWeekday(Locale.forLanguageTag("pt-PT")))
}
