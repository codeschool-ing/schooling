// modules/week-start/ios/WeekStartModule.swift: the first day of the week in the phone's own calendar, for JavaScript.
import ExpoModulesCore

public class WeekStartModule: Module {
  public func definition() -> ModuleDefinition {
    Name("WeekStart")

    // Calendar counts Sunday = 1; JavaScript's Date.getDay() counts Sunday = 0.
    Function("firstWeekday") { () -> Int in
      return Calendar.current.firstWeekday - 1
    }
  }
}
