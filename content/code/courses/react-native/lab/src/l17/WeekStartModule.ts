// modules/week-start/src/WeekStartModule.ts: the native module, as JavaScript sees it on a phone.
import { NativeModule, requireNativeModule } from "expo";

declare class WeekStartModule extends NativeModule {
  /** The first day of the week in the phone's calendar: 0 is Sunday, 1 Monday, as Date.getDay() counts. */
  firstWeekday(): number;
}

export default requireNativeModule<WeekStartModule>("WeekStart");
