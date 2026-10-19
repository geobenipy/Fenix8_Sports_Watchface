import Toybox.Lang;

//! Colors and geometry of the watch face. See DESIGN.md.
//!
//! The color system follows one rule: **every metric has exactly one color, and
//! it applies everywhere.** The steps arc is orange, so everything else that
//! concerns steps is orange too. Blue is Body Battery and nothing else.
//!
//! Color is carried by icons, arcs and scales. The numbers themselves stay in a
//! uniform light grey - the exceptions are the two anchor values, heart rate and
//! temperature. That makes the watch face colorful without being restless: the
//! color sits in the small shapes, the calm in the large areas.
//!
//! **The colors are `var`, not `const`.** Three schemes share the same names;
//! `applyScheme` rewrites them. The rest of the code only knows `Theme.STEPS`
//! and needs to know nothing about the schemes - that is the reason for this
//! design. Anyone adding a color here has to handle it in **all three** branches
//! of `applyScheme`.
module Theme {

    // --- Schemes ---------------------------------------------------------
    const SCHEME_FULL = 0;  // Full - the original version
    const SCHEME_SOFT = 1;  // Muted - the same colors, desaturated
    const SCHEME_CALM = 2;  // Calm - far fewer hues

    // --- Base levels ----------------------------------------------------
    const BG        = 0x000000;  // true black, AMOLED pixels off, in every scheme
    var PRIMARY   as Number = 0xFFFFFF;  // time, date, temperature
    var VALUE     as Number = 0xDDE3EA;  // all secondary values
    var LABEL     as Number = 0x6B7580;  // labels, units, separators
    var ARC_EMPTY as Number = 0x252B33;  // unfilled part of the goal arcs

    // --- Metric colors --------------------------------------------------
    //
    // Every line in this table is a promise: this color means this one metric
    // on the whole watch face. In the "Calm" scheme the promise is deliberately
    // relaxed - see applyCalm.
    var STEPS    as Number = 0xFF6B1A;  // steps
    var FLOORS   as Number = 0xFFB000;  // floors
    var ACTIVE   as Number = 0xFF2E88;  // active minutes
    var BODY     as Number = 0x00C8FF;  // Body Battery
    var HEART    as Number = 0xFF4438;  // heart rate
    var CALORIE  as Number = 0xFF8C42;  // calories burned
    var VO2      as Number = 0x00D9B2;  // VO2max
    var RUN      as Number = 0x2FD35B;  // running
    var BIKE     as Number = 0xA96BFF;  // cycling
    var ALTITUDE as Number = 0x8C99A8;  // altitude (rock; summit in PRIMARY)

    // --- Weather colors -------------------------------------------------
    var SUN   as Number = 0xFFD429;  // sun, sunrise and sunset
    var RAIN  as Number = 0x4FA3FF;  // rain, cold forecast
    var CLOUD as Number = 0x9AA5B1;  // cloud
    var HAZE  as Number = 0x7D8794;  // fog, haze
    var WARM  as Number = 0xFF9A3D;  // warm forecast

    // --- Status scale ---------------------------------------------------
    //
    // For everything that runs from "good" to "bad": stress, battery,
    // recovery time, pressure trend.
    var GOOD as Number = 0x2FD35B;
    var WARN as Number = 0xFFB000;
    var BAD  as Number = 0xFF4438;

    // --- Training status -------------------------------------------------
    //
    // Eight levels, because the rocket has no text next to it and the color
    // carries the whole message. In the "Calm" scheme the eight levels collapse
    // into the three of the status scale.
    var TRAIN_PEAK         as Number = 0xB35CFF;  // Peaking - violet
    var TRAIN_PRODUCTIVE   as Number = 0x2FD35B;  // Productive - green
    var TRAIN_MAINTAIN     as Number = 0x3E9BFF;  // Maintaining - blue
    var TRAIN_RECOVERY     as Number = 0xFFD429;  // Recovery - yellow
    var TRAIN_UNPRODUCTIVE as Number = 0xFF8C42;  // Unproductive - orange
    var TRAIN_STRAINED     as Number = 0xFF6B1A;  // Strained - strong orange
    var TRAIN_OVERREACH    as Number = 0xC4241A;  // Overreaching - dark red
    var TRAIN_DETRAIN      as Number = 0xFF4438;  // Detraining - red

    // --- Time-of-day color ----------------------------------------------
    //
    // The weekday in the date travels through the day. The only color on the
    // watch face that doesn't categorize anything but tells something - and the
    // only one that moves.
    var DAY_NIGHT   as Number = 0x2B3BAF;
    var DAY_MORNING as Number = 0xFF8A2B;
    var DAY_NOON    as Number = 0x00C8FF;
    var DAY_EVENING as Number = 0xFF2E88;

    // --- Scheme switching -----------------------------------------------

    //! Rewrites the color table to the chosen scheme.
    //!
    //! Called at startup and after every configuration change. Each call first
    //! sets the full version and then applies the variation - otherwise a second
    //! call would build on an already varied state and the colors would fade
    //! further with every switch.
    function applyScheme(scheme as Number) as Void {
        applyFull();
        if (scheme == SCHEME_SOFT) {
            applySoft();
        } else if (scheme == SCHEME_CALM) {
            applyCalm();
        }
    }

    //! Scheme 0 - the original version.
    function applyFull() as Void {
        PRIMARY = 0xFFFFFF;  VALUE = 0xDDE3EA;  LABEL = 0x6B7580;  ARC_EMPTY = 0x252B33;

        STEPS = 0xFF6B1A;  FLOORS = 0xFFB000;  ACTIVE = 0xFF2E88;  BODY = 0x00C8FF;
        HEART = 0xFF4438;  CALORIE = 0xFF8C42;  VO2 = 0x00D9B2;
        RUN = 0x2FD35B;  BIKE = 0xA96BFF;  ALTITUDE = 0x8C99A8;

        SUN = 0xFFD429;  RAIN = 0x4FA3FF;  CLOUD = 0x9AA5B1;  HAZE = 0x7D8794;
        WARM = 0xFF9A3D;

        GOOD = 0x2FD35B;  WARN = 0xFFB000;  BAD = 0xFF4438;

        TRAIN_PEAK = 0xB35CFF;         TRAIN_PRODUCTIVE = 0x2FD35B;
        TRAIN_MAINTAIN = 0x3E9BFF;     TRAIN_RECOVERY = 0xFFD429;
        TRAIN_UNPRODUCTIVE = 0xFF8C42; TRAIN_STRAINED = 0xFF6B1A;
        TRAIN_OVERREACH = 0xC4241A;    TRAIN_DETRAIN = 0xFF4438;

        DAY_NIGHT = 0x2B3BAF;  DAY_MORNING = 0xFF8A2B;
        DAY_NOON = 0x00C8FF;   DAY_EVENING = 0xFF2E88;
    }

    //! Scheme 1 - "Muted": the same colors, just quieter.
    //!
    //! **Calculated, not picked.** That is the honest implementation here: the
    //! brief is "same colors, less glaring", and that is exactly a formula - every
    //! tone moves by the same amount toward its own grey and gets darker by the
    //! same factor. Hand-picked values would be thirty individual decisions that
    //! stop matching each other as soon as one of them is adjusted.
    //!
    //! Grey and background stay untouched: label and empty arc track are already
    //! neutral, desaturating them further would only cost contrast. White and
    //! value grey are lowered only slightly - on AMOLED pure white is what stands
    //! out most.
    function applySoft() as Void {
        PRIMARY = 0xE8EBEF;  VALUE = 0xC2C8CF;  ARC_EMPTY = 0x22262C;

        STEPS = soften(STEPS);      FLOORS = soften(FLOORS);
        ACTIVE = soften(ACTIVE);    BODY = soften(BODY);
        HEART = soften(HEART);      CALORIE = soften(CALORIE);
        VO2 = soften(VO2);          RUN = soften(RUN);
        BIKE = soften(BIKE);        ALTITUDE = soften(ALTITUDE);

        SUN = soften(SUN);          RAIN = soften(RAIN);
        CLOUD = soften(CLOUD);      HAZE = soften(HAZE);
        WARM = soften(WARM);

        GOOD = soften(GOOD);        WARN = soften(WARN);        BAD = soften(BAD);

        TRAIN_PEAK = soften(TRAIN_PEAK);
        TRAIN_PRODUCTIVE = soften(TRAIN_PRODUCTIVE);
        TRAIN_MAINTAIN = soften(TRAIN_MAINTAIN);
        TRAIN_RECOVERY = soften(TRAIN_RECOVERY);
        TRAIN_UNPRODUCTIVE = soften(TRAIN_UNPRODUCTIVE);
        TRAIN_STRAINED = soften(TRAIN_STRAINED);
        TRAIN_OVERREACH = soften(TRAIN_OVERREACH);
        TRAIN_DETRAIN = soften(TRAIN_DETRAIN);

        DAY_NIGHT = soften(DAY_NIGHT);      DAY_MORNING = soften(DAY_MORNING);
        DAY_NOON = soften(DAY_NOON);        DAY_EVENING = soften(DAY_EVENING);
    }

    //! Scheme 2 - "Calm": far fewer hues.
    //!
    //! This is where the basic rule of the color system deliberately breaks:
    //! **color no longer identifies the metric but its kind.** Two families in
    //! two brightness levels each carry almost everything - warm amber for
    //! movement, cool blue for body and endurance - plus heart rate in red and
    //! the sun in yellow. Twelve hues become five.
    //!
    //! That steps, calories and running now share a color is no loss: since the
    //! ring has its four legend icons and every data row carries its own symbol,
    //! the shape tells what it is about anyway. Color can therefore limit itself
    //! to grouping.
    //!
    //! Two places keep their distinction regardless, because they would otherwise
    //! become unreadable: the four ring sections (light/dark per family, so that
    //! neighboring arcs at 12 and 6 o'clock stand apart) and the split values
    //! `54|42` and `21|9°` (warm versus cool).
    //!
    //! The eight-level training scale collapses here into the three levels of the
    //! status scale. That costs information - peaking and maintaining can no
    //! longer be told apart - and is exactly what "fewer colors" means.
    function applyCalm() as Void {
        var warmLight = 0xE8A857;
        var warmDark  = 0xC67C33;
        var coolLight = 0x7FB6D8;
        var coolDark  = 0x4E86AB;

        PRIMARY = 0xF0F2F5;  VALUE = 0xC7CDD4;  LABEL = 0x6B7580;  ARC_EMPTY = 0x22262C;

        // Ring: one light and one dark level per family, laid crosswise so that
        // no two equal tones meet at any of the four seams.
        STEPS = warmLight;   FLOORS = warmDark;
        BODY = coolLight;    ACTIVE = coolDark;

        HEART = 0xC9584E;
        CALORIE = warmLight;
        VO2 = coolLight;
        RUN = warmLight;     BIKE = coolLight;
        ALTITUDE = 0x8C99A8;

        SUN = 0xE8C15C;      RAIN = coolLight;
        CLOUD = 0x9AA5B1;    HAZE = 0x7D8794;
        WARM = warmLight;

        GOOD = 0x5FA86B;     WARN = 0xD9A038;     BAD = 0xC9584E;

        TRAIN_PEAK = GOOD;             TRAIN_PRODUCTIVE = GOOD;
        TRAIN_MAINTAIN = GOOD;         TRAIN_RECOVERY = GOOD;
        TRAIN_UNPRODUCTIVE = WARN;     TRAIN_STRAINED = WARN;
        TRAIN_OVERREACH = BAD;         TRAIN_DETRAIN = BAD;

        // The day keeps moving, but only within the two families now.
        DAY_NIGHT = 0x3E5A7A;  DAY_MORNING = warmDark;
        DAY_NOON = coolLight;  DAY_EVENING = warmLight;
    }

    //! Desaturates toward its own grey and darkens.
    //!
    //! 45 percent toward grey and 82 percent brightness were measured on the
    //! image, not guessed: at 32 / 90 the difference from the full version was
    //! barely visible in the simulator (VO2 turquoise only moved from `#00D9B2`
    //! to `#2AAF97`), at 55 percent the running green tips into muddy.
    function soften(color as Number) as Number {
        return dim(desaturate(color, 0.45), 0.82);
    }

    //! Mixes a color toward the grey that has its own brightness.
    //! @param t 0.0 = unchanged, 1.0 = fully neutral
    function desaturate(color as Number, t as Float) as Number {
        var r = (color >> 16) & 0xFF;
        var g = (color >> 8) & 0xFF;
        var b = color & 0xFF;

        // Perceived brightness, fixed point: 77/151/28 out of 256 are the usual
        // 0.30 / 0.59 / 0.11.
        var luma = (r * 77 + g * 151 + b * 28) >> 8;

        r = r + ((luma - r) * t).toNumber();
        g = g + ((luma - g) * t).toNumber();
        b = b + ((luma - b) * t).toNumber();
        return (r << 16) | (g << 8) | b;
    }

    //! Darkens channel by channel. @param factor 1.0 = unchanged
    function dim(color as Number, factor as Float) as Number {
        var r = ((((color >> 16) & 0xFF) * factor).toNumber());
        var g = ((((color >> 8) & 0xFF) * factor).toNumber());
        var b = (((color & 0xFF) * factor).toNumber());
        return (r << 16) | (g << 8) | b;
    }

    //! @param fraction 0.0 = midnight, 1.0 = next midnight
    function dayColor(fraction as Float) as Number {
        var f = fraction;
        if (f < 0.0) { f = 0.0; }
        if (f > 1.0) { f = 1.0; }

        // Anchor points at 0, 6, 12, 18 and 24 o'clock; the last one is the first
        // again, so the transition at midnight doesn't jump.
        var stops = [DAY_NIGHT, DAY_MORNING, DAY_NOON, DAY_EVENING, DAY_NIGHT]
                    as Array<Number>;
        var scaled = f * 4.0;
        var index = scaled.toNumber();
        if (index > 3) { index = 3; }
        return mix(stops[index], stops[index + 1], scaled - index);
    }

    //! Mixes two colors channel by channel. @param t 0.0 = a, 1.0 = b
    function mix(a as Number, b as Number, t as Float) as Number {
        var f = t;
        if (f < 0.0) { f = 0.0; }
        if (f > 1.0) { f = 1.0; }

        var r = ((a >> 16) & 0xFF) + (((((b >> 16) & 0xFF) - ((a >> 16) & 0xFF)) * f).toNumber());
        var g = ((a >> 8) & 0xFF) + (((((b >> 8) & 0xFF) - ((a >> 8) & 0xFF)) * f).toNumber());
        var c = (a & 0xFF) + ((((b & 0xFF) - (a & 0xFF)) * f).toNumber());
        return (r << 16) | (g << 8) | c;
    }

    //! Color of the watch battery.
    //!
    //! The thresholds are low because a fenix runs for two weeks: 50 percent here
    //! is not a half warning but a week of peace. Yellow only from 30, red from
    //! 15 percent - a scale that warns at half calls too early and is therefore
    //! ignored.
    function batteryColor(percent as Number?) as Number {
        if (percent == null) { return LABEL; }
        if (percent >= 30) { return GOOD; }
        if (percent >= 15) { return WARN; }
        return BAD;
    }

    //! Color for scales where **high is bad** - stress.
    function scaleDown(value as Number?) as Number {
        if (value == null) { return LABEL; }
        if (value <= 25) { return GOOD; }
        if (value <= 50) { return WARN; }
        return BAD;
    }

    //! Color of the recovery time. It is read as "can I train?", so the scale runs
    //! the other way round from the number: few hours left green, many red.
    //!
    //! @param minutes remaining recovery time in minutes
    function recoveryColor(minutes as Number?) as Number {
        if (minutes == null) { return LABEL; }
        if (minutes <= 0)    { return GOOD; }
        if (minutes <= 360)  { return WARN; }   // up to 6 h
        return BAD;
    }

    // --- Geometry (416 x 416, round) ------------------------------------
    const CENTER_X = 208;
    const CENTER_Y = 208;

    //! Goal arcs: four segments of 84 degrees, gaps of 6 degrees at 12, 3, 6 and 9 o'clock.
    //! Angles in Monkey C convention: 0 degrees = 3 o'clock, increasing counterclockwise.
    //!
    //! The gaps used to be 20 degrees wide, which produced four separate gauge
    //! instruments. With 6 degrees the same layout reads as **one** ring in four
    //! color sections - calmer and more colorful at the same time.
    //!
    //! ARC_RADIUS 195 at ARC_WIDTH 11 means: the arc occupies radii 189.5 to
    //! 200.5. The usable inner radius nevertheless stays at 188 - the row widths
    //! further down are calculated from it, and the one and a half pixels gained
    //! would not make a single row wider.
    //!
    //! The stroke width used to be 14 px. Thinner, the ring looks like a bezel
    //! around the watch face instead of an instrument of its own - and leaves
    //! room inside for the four legend icons.
    const ARC_RADIUS = 195;
    const ARC_WIDTH  = 11;
    const ARC_SWEEP  = 84;

    //! Radius of the white hairline that marks a reached goal on the outside.
    //! At pen 2 it occupies 203 to 205 and thus stays inside the display.
    const ARC_DONE_RADIUS = 204;

    //! Every arc is divided into quarters. The marks are not lines on the arc but
    //! gaps in background color straight through it: that way, at any fill level,
    //! you can read which quarter is currently running.
    const ARC_TICKS      = 4;
    const ARC_TICK_WIDTH = 3;

    //! Legend icons of the four arc sections.
    //!
    //! They don't sit in the middle of their section but at its **outer end**,
    //! i.e. near 9 and 3 o'clock. That is no stopgap but the only free area: at
    //! the height of the arc centers (y ~ 90 and y ~ 326) the weather, date and
    //! data rows run right up to the ring. Left and right of the time, however,
    //! about 60 px each remain unused - exactly where the four icons sit.
    //!
    //! Calculated: radius 172 at 170, 10, 190 and 350 degrees. The outermost icon
    //! corner is then at radius 180, i.e. 9 px inside the ring.
    const LEGEND_X_LEFT   = 41;
    const LEGEND_X_RIGHT  = 375;
    const LEGEND_Y_TOP    = 179;
    const LEGEND_Y_BOTTOM = 238;

    //! Vertical rhythm. y values are the top edge of the respective row.
    //!
    //! Derived from the measured font heights of the device: XTINY 34, TINY 43,
    //! SMALL 50, NUMBER_MEDIUM 141. The boxes overlap in places - the fonts have
    //! headroom that no glyph uses, and a descender at the bottom that digits
    //! don't reach. So the calculation uses the **ink edge**, not the box:
    //!
    //!   XTINY  +7 / +26      TINY  +10 / +33
    //!   SMALL  +11 / +38     NUMBER_MEDIUM  +15 / +121
    //!
    //! Layout: above the time sits what comes from outside (status, weather,
    //! date), below it what the body reports. The accent bar is gone; its 17 px
    //! flowed into the data rows, three became four.
    //!
    //! From the ink top edge of the status row (y = 43, lower isn't possible
    //! without losing width) to the ink bottom edge of row D (y = 370, lower and
    //! the chord gets too narrow) there are 327 px to distribute, of which the
    //! eight elements occupy 243. The remaining 84 px are **not** distributed
    //! evenly:
    //!
    //!   Status -> Weather    12 px
    //!   Weather -> Date      12 px
    //!   Date -> Time          7 px
    //!   Time -> Row A        14 px
    //!   Row A -> B -> C -> D 13 px each
    //!
    //! The date hangs close to the time because both answer the same question.
    //! The largest gap is between time and row A - that is where the boundary
    //! between "outside" and "inside" runs.
    const Y_STATUS  = 36;   // XTINY
    const Y_WEATHER = 67;   // XTINY
    const Y_DATE    = 95;   // TINY (+ sun time in XTINY)
    const Y_TIME    = 120;  // NUMBER_MEDIUM
    const Y_ROW_A   = 248;  // XTINY
    const Y_ROW_B   = 280;  // XTINY
    const Y_ROW_C   = 312;  // XTINY
    const Y_ROW_D   = 344;  // XTINY

    //! Usable width per row: the chord of the circle with radius 188 at the
    //! row's **narrowest ink edge**.
    //!
    //! Which edge that is depends on where the row sits: **below** the display
    //! center it is the bottom edge, **above** it the top edge. The circle gets
    //! narrower toward both poles, not just downwards.
    //!
    //! This distinction is no subtlety. An earlier version of this file only knew
    //! the rule "always the bottom edge" and therefore gave the status row 215 px
    //! - that is the chord at its bottom edge. It would have needed the one at the
    //! top edge: 94 px. The row reached into the edge ring with both ends, the
    //! upper corner sat at radius 199 right in the arc.
    //!
    //! The values are below the calculated chord: it is the limit, not the goal.
    //! Row A gets 310 instead of the possible 352, because three elements spread
    //! over 352 px fall apart and no longer read as a row.
    const WEATHER_WIDTH = 255;  // chord at y = 74: 264
    const DATE_WIDTH    = 300;  // chord at y = 105: 314
    const ROW_A_WIDTH   = 310;  // chord at y = 274: 352
    const ROW_B_WIDTH   = 315;  // chord at y = 306: 321
    const ROW_C_WIDTH   = 265;  // chord at y = 338: 272
    const ROW_D_WIDTH   = 185;  // chord at y = 370: 191

    //! Status row, calculated at its top edge: the Bluetooth icon begins at
    //! y = 42, where the chord is 176 px. 172 leaves four pixels for the
    //! imprecision of the ink estimate. The row allots this width itself, see
    //! `BeniView.drawStatus`.
    const STATUS_WIDTH = 172;
}
