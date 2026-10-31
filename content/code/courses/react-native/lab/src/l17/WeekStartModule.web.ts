// modules/week-start/src/WeekStartModule.web.ts: the same answer in a browser, from Intl.
import { NativeModule, registerWebModule } from "expo";

type WeekInfo = { firstDay: number }; // 1 is Monday … 7 is Sunday
type WithWeekInfo = Intl.Locale & { getWeekInfo?: () => WeekInfo; weekInfo?: WeekInfo };

class WeekStartModule extends NativeModule {
  firstWeekday() {
    const locale = new Intl.Locale(navigator.language) as WithWeekInfo;
    const info = locale.getWeekInfo?.() ?? locale.weekInfo;
    return info ? info.firstDay % 7 : 1; // a browser that cannot say gets Monday, the planner's own week
  }
}

export default registerWebModule(WeekStartModule, "WeekStart");
