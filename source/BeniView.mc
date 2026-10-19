import Toybox.Activity;
import Toybox.Application.WatchFaceConfig;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! One element of a data row: an icon or a short text label up front, the
//! value behind it.
//!
//! Icon and value have separate colors. That is intentional: the metric color
//! sits in the symbol, the value stays in the uniform light grey. This keeps
//! the row colorful yet readable - colored numbers on a black background lose
//! contrast, colored symbols don't.
//!
//! An element can carry a **split value**: two numbers with a grey separator in
//! between, each in its own color. That puts `72/48` (heart rate and resting
//! heart rate) and `54|42` (VO2max running and cycling) into one column each,
//! without the reader having to work out which number is which.
class RowItem {
    var label as String?;
    var icon as Symbol?;
    var value as String;
    var valueColor as Number;
    var accentColor as Number;
    var separator as String?;
    var value2 as String?;
    var value2Color as Number;

    function initialize(label as String?, icon as Symbol?, value as String,
                        valueColor as Number, accentColor as Number) {
        self.label = label;
        self.icon = icon;
        self.value = value;
        self.valueColor = valueColor;
        self.accentColor = accentColor;
        self.separator = null;
        self.value2 = null;
        self.value2Color = Theme.LABEL;
    }

    //! Appends a second value. Returns itself so the element can be built
    //! completely within one expression.
    function split(separator as String, value2 as String, color as Number) as RowItem {
        self.separator = separator;
        self.value2 = value2;
        self.value2Color = color;
        return self;
    }
}

//! The watch face. Layout and geometry are laid down in DESIGN.md.
class BeniView extends WatchUi.WatchFace {

    private const VALUE_FONT = Graphics.FONT_XTINY;
    private const LABEL_FONT = Graphics.FONT_XTINY;
    private const DATE_FONT  = Graphics.FONT_TINY;

    //! The seconds used to be XTINY and thus only a quarter as tall as the time -
    //! barely recognizable as a number at arm's length. SMALL is a good third and
    //! still stays clearly subordinate to the time.
    private const SECONDS_FONT = Graphics.FONT_SMALL;

    private const ICON_GAP = 5;
    private const LABEL_GAP = 5;

    //! The weather symbol is wider than the other icons - cloud plus
    //! precipitation need the room.
    private const WEATHER_ICON_SIZE = 24;

    //! Sun symbol: it draws from cx-10 to cx+11.
    private const SUN_ICON_SIZE = 22;

    //! The battery icon is wider than the others: it draws from cx-11 to
    //! cx+12, because the positive terminal sticks out on the right.
    private const BATTERY_WIDTH = 24;

    //! Limits for the self-allotted gaps of the status row. Below the minimum the
    //! three groups stick together and read as one - in that case the
    //! notification counter is dropped instead.
    private const STATUS_GAP_MIN = 8;
    private const STATUS_GAP_MAX = 24;

    //! Gap between date and sun time, and its emergency level.
    private const DATE_SUN_GAP = 22;
    private const DATE_SUN_GAP_MIN = 10;

    //! Smallest distance between two elements when the column grid gives up.
    private const ITEM_GAP_MIN = 10;

    //! Structure of the style list in the watch face editor: three color schemes
    //! times four race distances. See `applyConfiguration`.
    private const RACE_COUNT = 4;
    private const STYLE_COUNT = 12;
    private const DEFAULT_RACE_DISTANCE = 1;  // 10 km

    private var _steps as ArcGauge;
    private var _floors as ArcGauge;
    private var _activeMinutes as ArcGauge;
    private var _bodyBatteryArc as ArcGauge;
    private var _data as WatchData;
    private var _lowPower as Boolean = false;

    function initialize() {
        WatchFace.initialize();
        _data = new WatchData();

        // Anchors and directions chosen so that both upper sections grow outwards
        // from 12 o'clock and both lower ones from 6 o'clock. The anchors sit 3
        // degrees beside the axes, the sections are 84 degrees wide - which
        // gives the 6-degree gaps at 12, 3, 6 and 9 o'clock.
        // See DESIGN.md, section 2.
        _steps = new ArcGauge(93, Graphics.ARC_COUNTER_CLOCKWISE, Theme.STEPS);
        _floors = new ArcGauge(87, Graphics.ARC_CLOCKWISE, Theme.FLOORS);
        _bodyBatteryArc = new ArcGauge(267, Graphics.ARC_CLOCKWISE, Theme.BODY);
        _activeMinutes = new ArcGauge(273, Graphics.ARC_COUNTER_CLOCKWISE, Theme.ACTIVE);

        applyConfiguration();
    }

    //! Reads the configuration from the watch face editor and applies it.
    //!
    //! The editor is the **only** source. App settings (`settings.xml`) wouldn't
    //! be one: according to Garmin's own docs they can only be edited in Garmin
    //! Connect and Garmin Express, not on the watch at all - and for a
    //! sideloaded watch face often not there either, because both fetch their
    //! settings description from the Connect IQ store.
    //!
    //! The editor only knows **one** selection list, though. Color scheme and
    //! race distance therefore share their product: twelve styles, encoded as
    //! `styleId = scheme * 4 + distance`. The same calculation is in
    //! `resources/configs/watchface.xml` and may only be changed together with
    //! this file.
    //!
    //! If the editor delivers nothing, it stays at Full and 10 km. That is no
    //! fallback route, merely a defined state - on a device without an editor the
    //! watch face simply could not be configured.
    function applyConfiguration() as Void {
        var scheme = Theme.SCHEME_FULL;
        var distance = DEFAULT_RACE_DISTANCE;

        var styleId = readStyleId();
        if (styleId != null) {
            scheme = styleId / RACE_COUNT;
            distance = styleId % RACE_COUNT;
        }

        Theme.applyScheme(scheme);

        // The four arcs get their color set explicitly: they copied it on
        // construction and would otherwise stay in the old scheme. All other
        // elements read `Theme` on every draw and need nothing.
        _steps.setColor(Theme.STEPS);
        _floors.setColor(Theme.FLOORS);
        _bodyBatteryArc.setColor(Theme.BODY);
        _activeMinutes.setColor(Theme.ACTIVE);

        _data.setRaceDistance(distance);
    }

    //! The style chosen in the watch face editor, or null if there is none.
    private function readStyleId() as Number? {
        if (!(Toybox.Application has :WatchFaceConfig)) { return null; }
        try {
            var config = WatchFaceConfig.getSettings(null);
            if (config != null) {
                var styleId = config.styleId;
                if (styleId != null && styleId >= 0 && styleId < STYLE_COUNT) {
                    return styleId;
                }
            }
        } catch (e) {
            // Stays at the default.
        }
        return null;
    }

    function onShow() as Void {
        _data.subscribe();
    }

    function onHide() as Void {
        _data.unsubscribe();
    }

    function onExitSleep() as Void {
        _lowPower = false;
    }

    function onEnterSleep() as Void {
        _lowPower = true;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        // A single null value must never freeze the watch face.
        try {
            dc.setColor(Theme.PRIMARY, Theme.BG);
            dc.clear();

            if (_lowPower) {
                drawAlwaysOn(dc);
                return;
            }

            _data.refresh();
            drawArcs(dc);
            drawStatus(dc);
            drawWeatherRow(dc);
            drawDateRow(dc);
            drawTime(dc, Graphics.FONT_NUMBER_MEDIUM, Theme.PRIMARY, 0, 0, true);
            drawRowA(dc);
            drawRowB(dc);
            drawRowC(dc);
            drawRowD(dc);
        } catch (e) {
            // Better an incomplete picture than a hung watch face.
        }
    }

    // --- Edge ring -------------------------------------------------------

    private function drawArcs(dc as Dc) as Void {
        _steps.draw(dc, _data.stepsProgress());
        _floors.draw(dc, _data.floorsProgress());
        _activeMinutes.draw(dc, _data.activeMinutesProgress());

        if (_data.hasBodyBattery()) {
            _bodyBatteryArc.draw(dc, _data.bodyBatteryProgress());
        } else {
            // No value from the system yet: empty track instead of a false zero.
            _bodyBatteryArc.drawTrackOnly(dc);
        }

        drawLegend(dc);
    }

    //! Four symbols say what the four colored sections stand for.
    //!
    //! They sit left and right of the time, each at the outer end of its
    //! section - that is the only area of the watch face not claimed by any row.
    //! See Theme.LEGEND_*.
    private function drawLegend(dc as Dc) as Void {
        Icons.footprint(dc, Theme.LEGEND_X_LEFT, Theme.LEGEND_Y_TOP, Theme.STEPS);
        Icons.stairs(dc, Theme.LEGEND_X_RIGHT, Theme.LEGEND_Y_TOP, Theme.FLOORS);
        Icons.bolt(dc, Theme.LEGEND_X_LEFT, Theme.LEGEND_Y_BOTTOM, Theme.BODY);
        Icons.stopwatch(dc, Theme.LEGEND_X_RIGHT, Theme.LEGEND_Y_BOTTOM, Theme.ACTIVE);
    }

    // --- Status row ------------------------------------------------------

    //! The status row sits high up where the circle is narrow: at y = 42 only
    //! 176 px of chord are left, it only gets wider further down. It therefore
    //! can't set its gaps statically but has to allot `Theme.STATUS_WIDTH` to
    //! itself - the remaining space is distributed evenly over the two gaps.
    //!
    //! If that isn't enough either - three-digit notification counter and
    //! percentage display instead of remaining days -, the **counter** is
    //! dropped. That something is unread at all is told by the magenta envelope;
    //! the exact number is on the phone anyway. It is the cheapest detail to
    //! sacrifice here.
    private function drawStatus(dc as Dc) as Void {
        var settings = System.getDeviceSettings();
        var stats = System.getSystemStats();
        var height = dc.getFontHeight(LABEL_FONT);
        var cy = Theme.Y_STATUS + height / 2 - 2;

        var count = settings.notificationCount;
        var countText = (count == null) ? "0" : count.format("%d");
        var days = stats.batteryInDays;
        var batteryText = (days == null)
            ? stats.battery.format("%d") + "%"
            : days.format("%d") + "d";

        var countWidth = dc.getTextWidthInPixels(countText, LABEL_FONT);
        var batteryWidth = dc.getTextWidthInPixels(batteryText, LABEL_FONT);

        var battery = BATTERY_WIDTH + ICON_GAP + batteryWidth;
        var withCount = true;
        var fixed = Icons.SIZE + (Icons.SIZE + ICON_GAP + countWidth) + battery;
        var gap = (Theme.STATUS_WIDTH - fixed) / 2;

        if (gap < STATUS_GAP_MIN) {
            withCount = false;
            fixed = Icons.SIZE + Icons.SIZE + battery;
            gap = (Theme.STATUS_WIDTH - fixed) / 2;
        }
        if (gap > STATUS_GAP_MAX) { gap = STATUS_GAP_MAX; }
        if (gap < 0) { gap = 0; }

        var x = Theme.CENTER_X - (fixed + 2 * gap) / 2;

        // Connected in the cyan of the body values, disconnected only hinted at -
        // the phone's absence should be noticeable without looking like a warning.
        Icons.bluetooth(dc, x + 9, cy, settings.phoneConnected ? Theme.BODY : Theme.ARC_EMPTY);
        x += Icons.SIZE + gap;

        // Unread messages in magenta, zero stays silent.
        var hasMail = (count != null && count > 0);
        Icons.envelope(dc, x + 9, cy, hasMail ? Theme.ACTIVE : Theme.LABEL);
        x += Icons.SIZE;
        if (withCount) {
            dc.setColor(hasMail ? Theme.VALUE : Theme.LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x + ICON_GAP, Theme.Y_STATUS, LABEL_FONT, countText,
                        Graphics.TEXT_JUSTIFY_LEFT);
            x += ICON_GAP + countWidth;
        }
        x += gap;

        // The battery changes color across the whole scale, not only in an
        // emergency: green, yellow, red. A value that only changes color below
        // 15 percent is silent 85 percent of the time.
        var batteryColor = Theme.batteryColor(stats.battery.toNumber());
        Icons.battery(dc, x + 12, cy, batteryColor, stats.battery / 100.0);
        dc.setColor(batteryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + BATTERY_WIDTH + ICON_GAP, Theme.Y_STATUS, LABEL_FONT, batteryText,
                    Graphics.TEXT_JUSTIFY_LEFT);
    }

    // --- Weather row -----------------------------------------------------

    //! Everything that comes from outside sits **above** the time: weather
    //! condition and temperature, tomorrow's forecast, the air pressure with its
    //! trend. Below it the whole lower half remains for body and sports values.
    //!
    //! The forecast is colored in three parts - high warm, low cold, separator
    //! grey. As one piece of text ("21|9°") you would have to read it to know
    //! which number is which; in color you can see it.
    //!
    //! The trend arrow carries no fixed metric color but a scale color: rising
    //! green (weather getting better), falling yellow, steady grey.
    private function drawWeatherRow(dc as Dc) as Void {
        var temperature = _data.temperature();
        var tempText = (temperature == null) ? "--°" : temperature.format("%d") + "°";

        var high = _data.forecastHigh();
        var low = _data.forecastLow();
        var highText = (high == null) ? "--" : high.format("%d");
        var lowText = (low == null) ? "--°" : low.format("%d") + "°";

        var trend = _data.pressureTrend();
        var trendIcon = (trend > 0) ? :trendUp : ((trend < 0) ? :trendDown : :trendFlat);
        var trendColor = (trend > 0) ? Theme.GOOD : ((trend < 0) ? Theme.WARN : Theme.CLOUD);

        drawGrid(dc, Theme.Y_WEATHER, Theme.WEATHER_WIDTH, [
            new RowItem(null, :weather, tempText, Theme.PRIMARY, Theme.PRIMARY),
            new RowItem(null, null, highText, Theme.WARM, Theme.LABEL)
                .split("|", lowText, Theme.RAIN),
            new RowItem(null, trendIcon, optionalNumber(_data.pressureHpa()),
                        Theme.VALUE, trendColor)
        ]);
    }

    // --- Date and time ---------------------------------------------------

    //! Weekday in the time-of-day color, date in white, next to it the next
    //! sunrise or sunset.
    //!
    //! The two belong together: they answer the same question, namely where in
    //! the day we currently are. The sun symbol is one font size smaller than
    //! the date - it is the footnote, not the headline.
    //!
    //! The weekday comes from `Locale`, not from `Gregorian`: FORMAT_MEDIUM
    //! returns it in the watch's language, and this watch face is German,
    //! regardless of what the watch is set to. That means FORMAT_MEDIUM isn't
    //! needed at all anymore - and the pitfall that it returns month and weekday
    //! as text instead of as numbers is gone too.
    private function drawDateRow(dc as Dc) as Void {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        var dayOfWeek = info.day_of_week;
        var weekday = (dayOfWeek instanceof Lang.Number)
            ? Locale.weekday(dayOfWeek)
            : "--";

        var separator = " · ";
        var dateText = info.day.format("%02d") + "." + info.month.format("%02d") + ".";

        var weekdayWidth = dc.getTextWidthInPixels(weekday, DATE_FONT);
        var separatorWidth = dc.getTextWidthInPixels(separator, DATE_FONT);
        var dateWidth = dc.getTextWidthInPixels(dateText, DATE_FONT);
        var dateTotal = weekdayWidth + separatorWidth + dateWidth;

        var rising = _data.nextSunRising();
        var sunText = formatDaySeconds(_data.nextSunSeconds());
        var sunWidth = SUN_ICON_SIZE + ICON_GAP
                     + dc.getTextWidthInPixels(sunText, LABEL_FONT);

        var gap = DATE_SUN_GAP;
        if (dateTotal + gap + sunWidth > Theme.DATE_WIDTH) { gap = DATE_SUN_GAP_MIN; }

        var x = Theme.CENTER_X - (dateTotal + gap + sunWidth) / 2;
        var y = Theme.Y_DATE;

        dc.setColor(dayColor(), Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, DATE_FONT, weekday, Graphics.TEXT_JUSTIFY_LEFT);
        x += weekdayWidth;

        dc.setColor(Theme.LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, DATE_FONT, separator, Graphics.TEXT_JUSTIFY_LEFT);
        x += separatorWidth;

        dc.setColor(Theme.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, DATE_FONT, dateText, Graphics.TEXT_JUSTIFY_LEFT);
        x += dateWidth + gap;

        // Lift the smaller font of the sun time to the date's center axis,
        // otherwise it hangs from the date's top edge.
        var dateHeight = dc.getFontHeight(DATE_FONT);
        var sunHeight = dc.getFontHeight(LABEL_FONT);
        var cy = y + dateHeight / 2 - 2;
        var sunY = y + (dateHeight - sunHeight) / 2;

        Icons.sunEvent(dc, x + SUN_ICON_SIZE / 2, cy, Theme.SUN, rising);
        dc.setColor(Theme.VALUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + SUN_ICON_SIZE + ICON_GAP, sunY, LABEL_FONT, sunText,
                    Graphics.TEXT_JUSTIFY_LEFT);
    }

    //! Draws the time; the seconds hang subscripted on the right.
    //! The block of time and seconds is centered as a whole, so the time doesn't
    //! visually tip to the left.
    //!
    //! **Always 24 hours**, even if the watch is set to 12. A watch face with a
    //! fixed language also has a fixed time format - and without an AM/PM marker
    //! 12 hours would be ambiguous here anyway.
    //!
    //! The font comes from outside: NUMBER_MEDIUM in active mode, one size
    //! smaller in always-on, see drawAlwaysOn.
    private function drawTime(dc as Dc, timeFont as Graphics.FontDefinition, color as Number,
                              dx as Number, dy as Number, withSeconds as Boolean) as Void {
        var clock = System.getClockTime();
        var timeText = Lang.format("$1$:$2$", [clock.hour.format("%02d"), clock.min.format("%02d")]);

        var timeWidth = dc.getTextWidthInPixels(timeText, timeFont);
        var secondsText = clock.sec.format("%02d");
        var secondsWidth = withSeconds
            ? dc.getTextWidthInPixels(secondsText, SECONDS_FONT) + 6
            : 0;

        var blockLeft = Theme.CENTER_X + dx - (timeWidth + secondsWidth) / 2;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(blockLeft, Theme.Y_TIME + dy, timeFont, timeText,
                    Graphics.TEXT_JUSTIFY_LEFT);

        if (withSeconds) {
            // getFontHeight includes the descender that digits don't use.
            // Without this correction the seconds visibly hang below the time.
            // The deduction grows with the font size, hence calculated
            // proportionally.
            var timeHeight = dc.getFontHeight(timeFont);
            var secondsHeight = dc.getFontHeight(SECONDS_FONT);
            var descender = timeHeight / 7;
            dc.setColor(Theme.LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(blockLeft + timeWidth + 6,
                        Theme.Y_TIME + dy + timeHeight - secondsHeight - descender,
                        SECONDS_FONT, secondsText, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    // --- Data rows -------------------------------------------------------

    //! Row A - what the body is currently reporting: heart rate with resting
    //! heart rate, calories burned, stress.
    //!
    //! Heart rate is the only live value on the watch face and therefore the
    //! only value that is colored itself. The resting heart rate follows as the
    //! second, grey part of the same element - it is the yardstick that gives
    //! the current value meaning in the first place.
    //!
    //! Body Battery has no numeric value here anymore: the arc at the bottom
    //! left already shows the same number as a scale from 0 to 100, and the
    //! same thing twice is not a second piece of information.
    private function drawRowA(dc as Dc) as Void {
        var heartRate = _data.heartRate();
        var heartText = (heartRate == null) ? "--" : heartRate.format("%d");
        var heart = new RowItem(null, :heart, heartText, Theme.HEART, Theme.HEART);

        var resting = _data.restingHeartRate();
        if (resting != null) {
            heart.split("/", resting.format("%d"), Theme.LABEL);
        }

        var stress = _data.stress();

        drawGrid(dc, Theme.Y_ROW_A, Theme.ROW_A_WIDTH, [
            heart,
            new RowItem(null, :flame, optionalNumber(_data.calories()),
                        Theme.VALUE, Theme.CALORIE),
            new RowItem(null, :bars, optionalNumber(stress),
                        Theme.VALUE, Theme.scaleDown(stress))
        ]);
    }

    //! Row B - fitness and recovery.
    //!
    //! The rocket is the training status, and it is the only element without a
    //! number. There used to be a word of up to eight characters ("Bestform",
    //! "Überlast") that burst its column. Now the color carries the whole
    //! message - eight levels, following Garmin's own scale, see
    //! `Theme.TRAIN_*`.
    //!
    //! VO2max is one element with two values: running in the green of the
    //! running metrics, cycling in the violet of the cycling metrics. Two
    //! separate elements would have needed two labels and burst the row.
    private function drawRowB(dc as Dc) as Void {
        var recovery = _data.recoveryMinutes();

        var vo2 = new RowItem("VO2", null, optionalNumber(_data.vo2maxRun()),
                              Theme.RUN, Theme.VO2);
        vo2.split("|", optionalNumber(_data.vo2maxBike()), Theme.BIKE);

        drawGrid(dc, Theme.Y_ROW_B, Theme.ROW_B_WIDTH, [
            new RowItem(null, :rocket, "", Theme.VALUE,
                        Locale.trainingColor(_data.trainingStatus())),
            vo2,
            new RowItem(null, :hourglass, formatRecovery(recovery),
                        Theme.VALUE, Theme.recoveryColor(recovery))
        ]);
    }

    //! Row C - the race prediction and the current altitude.
    //!
    //! **Which** distance the prediction shows is set on the watch: 5 km, 10 km,
    //! half marathon or marathon. The label changes with it. An earlier version
    //! showed two hard-wired distances and had to pick two out of four - a choice
    //! the watch face cannot make at all, because it depends on the next season.
    //!
    //! The field that became free carries the altitude. It is the only item of
    //! this half that doesn't come from the body - it sits here because it comes
    //! from the same sensor as the air pressure one row above the time and
    //! therefore tells the same thing, just in a unit you understand without
    //! converting.
    private function drawRowC(dc as Dc) as Void {
        drawGrid(dc, Theme.Y_ROW_C, Theme.ROW_C_WIDTH, [
            new RowItem(_data.raceLabel(), null, formatRaceTime(_data.raceSeconds()),
                        Theme.VALUE, Theme.RUN),
            new RowItem(null, :mountain, optionalNumber(_data.altitude()),
                        Theme.VALUE, Theme.ALTITUDE)
        ]);
    }

    //! Row D has only a good 185 px left, hence icons instead of text labels.
    //! Both values are weekly kilometers, see DESIGN.md.
    private function drawRowD(dc as Dc) as Void {
        drawGrid(dc, Theme.Y_ROW_D, Theme.ROW_D_WIDTH, [
            new RowItem(null, :runner, formatKm(_data.weeklyRunMeters()), Theme.VALUE, Theme.RUN),
            new RowItem(null, :bike, formatKm(_data.weeklyBikeMeters()), Theme.VALUE, Theme.BIKE)
        ]);
    }

    // --- Grid ------------------------------------------------------------

    //! Distributes the elements over equally wide columns and centers each in
    //! its column.
    //!
    //! Equally wide columns instead of equal gaps: that way the elements of
    //! different rows line up on the same axes. A grid you don't see, but notice
    //! immediately when it is missing.
    //!
    //! If an element doesn't fit its column, the grid gives up for this one row
    //! and distributes equal gaps instead. That is the uglier but honest
    //! solution: an element that is too wide would otherwise run past its column
    //! boundary into its neighbor, and two numbers on top of each other are worse
    //! than a shifted axis.
    private function drawGrid(dc as Dc, y as Number, width as Number,
                              items as Array<RowItem>) as Void {
        var count = items.size();
        if (count == 0) { return; }

        var valueHeight = dc.getFontHeight(VALUE_FONT);
        var iconCy = y + valueHeight / 2 - 2;
        var column = width / count;
        var left = Theme.CENTER_X - width / 2;

        var leads = new [count] as Array<Number>;
        var totals = new [count] as Array<Number>;
        var sum = 0;
        var tight = false;

        for (var i = 0; i < count; i++) {
            leads[i] = leadWidth(dc, items[i]);
            totals[i] = leads[i] + valueWidth(dc, items[i]);
            sum += totals[i];
            if (totals[i] > column) { tight = true; }
        }

        var gap = 0;
        var cursor = 0;
        if (tight) {
            gap = (count > 1) ? (width - sum) / (count - 1) : 0;
            if (gap < ITEM_GAP_MIN) { gap = ITEM_GAP_MIN; }
            cursor = Theme.CENTER_X - (sum + gap * (count - 1)) / 2;
        }

        for (var i = 0; i < count; i++) {
            var x = tight
                ? cursor
                : left + column * i + (column - totals[i]) / 2;
            drawItem(dc, items[i], x, y, iconCy, leads[i]);
            cursor += totals[i] + gap;
        }
    }

    //! Width of the lead-in: icon plus gap, label plus gap, or nothing.
    //! An element without a value - the rocket - needs no gap behind it either.
    private function leadWidth(dc as Dc, item as RowItem) as Number {
        if (item.icon == :weather) {
            return WEATHER_ICON_SIZE + (item.value.length() == 0 ? 0 : ICON_GAP);
        }
        if (item.icon != null) {
            return Icons.SIZE + (item.value.length() == 0 ? 0 : ICON_GAP);
        }
        if (item.label != null) {
            return dc.getTextWidthInPixels(item.label, LABEL_FONT) + LABEL_GAP;
        }
        return 0;
    }

    private function valueWidth(dc as Dc, item as RowItem) as Number {
        var total = dc.getTextWidthInPixels(item.value, VALUE_FONT);
        var separator = item.separator;
        var value2 = item.value2;
        if (separator != null && value2 != null) {
            total += dc.getTextWidthInPixels(separator, VALUE_FONT)
                   + dc.getTextWidthInPixels(value2, VALUE_FONT);
        }
        return total;
    }

    private function drawItem(dc as Dc, item as RowItem, x as Number, y as Number,
                              iconCy as Number, lead as Number) as Void {
        if (item.icon == :weather) {
            Icons.weather(dc, x + WEATHER_ICON_SIZE / 2, iconCy, _data.condition());
        } else if (item.icon != null) {
            drawIcon(dc, item.icon, x + Icons.SIZE / 2, iconCy, item.accentColor);
        } else if (item.label != null) {
            dc.setColor(item.accentColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, LABEL_FONT, item.label, Graphics.TEXT_JUSTIFY_LEFT);
        }

        var cursor = x + lead;
        dc.setColor(item.valueColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cursor, y, VALUE_FONT, item.value, Graphics.TEXT_JUSTIFY_LEFT);

        var separator = item.separator;
        var value2 = item.value2;
        if (separator == null || value2 == null) { return; }

        cursor += dc.getTextWidthInPixels(item.value, VALUE_FONT);
        dc.setColor(Theme.LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cursor, y, VALUE_FONT, separator, Graphics.TEXT_JUSTIFY_LEFT);

        cursor += dc.getTextWidthInPixels(separator, VALUE_FONT);
        dc.setColor(item.value2Color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cursor, y, VALUE_FONT, value2, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawIcon(dc as Dc, icon as Symbol, cx as Number, cy as Number,
                              color as Number) as Void {
        if (icon == :trendUp) {
            Icons.trend(dc, cx, cy, color, 1);
        } else if (icon == :trendDown) {
            Icons.trend(dc, cx, cy, color, -1);
        } else if (icon == :trendFlat) {
            Icons.trend(dc, cx, cy, color, 0);
        } else if (icon == :heart) {
            Icons.heart(dc, cx, cy, color);
        } else if (icon == :runner) {
            Icons.runner(dc, cx, cy, color);
        } else if (icon == :bike) {
            Icons.bike(dc, cx, cy, color);
        } else if (icon == :bolt) {
            Icons.bolt(dc, cx, cy, color);
        } else if (icon == :bars) {
            Icons.bars(dc, cx, cy, color);
        } else if (icon == :flame) {
            Icons.flame(dc, cx, cy, color);
        } else if (icon == :rocket) {
            Icons.rocket(dc, cx, cy, color);
        } else if (icon == :hourglass) {
            Icons.hourglass(dc, cx, cy, color);
        } else if (icon == :mountain) {
            Icons.mountain(dc, cx, cy, color);
        }
    }

    // --- Always-on display -----------------------------------------------

    //! In AOD only time, heart rate and battery, all dimmed and without seconds.
    //! The content shifts a few pixels every minute so nothing burns in.
    //!
    //! Deliberately one font size smaller than in active mode: the always-on
    //! display should light up few pixels, and NUMBER_MEDIUM would be too bold
    //! for that.
    //!
    //! There is color only once here: the heart rate in a strongly darkened red.
    //! It is the same color code as in active mode but costs hardly any power on
    //! AMOLED - red subpixels alone, a third of the power of white. The arcs, the
    //! date and all rows stay off.
    private function drawAlwaysOn(dc as Dc) as Void {
        var minute = System.getClockTime().min;
        var dx = (minute % 5) - 2;
        var dy = ((minute / 5) % 5) - 2;

        drawTime(dc, Graphics.FONT_NUMBER_MILD, Theme.VALUE, dx, dy + 16, false);

        var heartRate = currentHeartRate();
        if (heartRate != null) {
            dc.setColor(Theme.mix(Theme.HEART, Theme.BG, 0.45), Graphics.COLOR_TRANSPARENT);
            dc.drawText(Theme.CENTER_X + dx, Theme.Y_ROW_A + dy, Graphics.FONT_SMALL,
                        heartRate.format("%d"), Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(Theme.LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(Theme.CENTER_X + dx, Theme.Y_DATE + dy, Graphics.FONT_SMALL,
                    System.getSystemStats().battery.format("%d") + "%",
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function currentHeartRate() as Number? {
        var info = Activity.getActivityInfo();
        if (info == null) { return null; }
        return info.currentHeartRate;
    }

    // --- Formatting ------------------------------------------------------

    //! Fraction of the day that has elapsed, 0.0 to 1.0.
    private function dayFraction() as Float {
        var clock = System.getClockTime();
        var elapsed = clock.hour * 3600 + clock.min * 60 + clock.sec;
        return elapsed / 86400.0;
    }

    private function dayColor() as Number {
        return Theme.dayColor(dayFraction());
    }

    private function optionalNumber(value as Number?) as String {
        return (value == null) ? "--" : value.format("%d");
    }

    //! Seconds since midnight as `HH:MM`.
    private function formatDaySeconds(seconds as Number?) as String {
        if (seconds == null) { return "--:--"; }
        var minutes = seconds / 60;
        return (minutes / 60).format("%02d") + ":" + (minutes % 60).format("%02d");
    }

    //! Remaining recovery time.
    //!
    //! Zero minutes doesn't mean "no value" but "recovered" - hence "fit" instead
    //! of a zero. Under an hour in minutes, above that in full hours: giving a
    //! recovery time of 18 hours to the exact minute would be a precision the
    //! number doesn't have.
    private function formatRecovery(minutes as Number?) as String {
        if (minutes == null) { return "--"; }
        if (minutes <= 0) { return "fit"; }
        if (minutes < 60) { return minutes.format("%d") + "m"; }
        return (minutes / 60).format("%d") + "h";
    }

    //! Predicted race time. Under an hour as `mm:ss`, above that as `h:mm` -
    //! seconds are noise in a half-marathon prediction and cost 30 px here.
    private function formatRaceTime(seconds as Number?) as String {
        if (seconds == null || seconds <= 0) { return "--"; }
        if (seconds < 3600) {
            return (seconds / 60).format("%d") + ":" + (seconds % 60).format("%02d");
        }
        return (seconds / 3600).format("%d") + ":" + ((seconds % 3600) / 60).format("%02d");
    }

    //! Meters to kilometers with a German decimal comma.
    //!
    //! Without a unit: row D has only a good 185 px left for both sports, and
    //! " km" twice alone costs 100 of them. The icons make clear what it is
    //! about. From 100 km the decimal place is dropped - with three-digit weekly
    //! volumes it is only noise and costs width.
    private function formatKm(meters as Float?) as String {
        if (meters == null) { return "--"; }
        var km = meters / 1000.0;
        return Locale.comma((km >= 100.0) ? km.format("%d") : km.format("%.1f"));
    }
}
