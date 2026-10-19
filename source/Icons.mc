import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;

//! Vector icons.
//!
//! Garmin ships no emoji fonts, and one bitmap per symbol would put needless
//! strain on the watch face's memory budget. All symbols are therefore drawn
//! from basic shapes - freely scalable and practically free in memory.
//!
//! Every function draws around the center point (cx, cy).
module Icons {

    //! Nominal edge length of a row icon.
    const SIZE = 18;

    // --- Status row ------------------------------------------------------

    function bluetooth(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx, cy - 9, cx, cy + 9);
        dc.drawLine(cx, cy - 9, cx + 6, cy - 4);
        dc.drawLine(cx + 6, cy - 4, cx - 6, cy + 4);
        dc.drawLine(cx, cy + 9, cx + 6, cy + 4);
        dc.drawLine(cx + 6, cy + 4, cx - 6, cy - 4);
    }

    function envelope(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRectangle(cx - 9, cy - 6, 18, 13);
        dc.drawLine(cx - 9, cy - 6, cx, cy + 1);
        dc.drawLine(cx, cy + 1, cx + 9, cy - 6);
    }

    //! @param fill charge level from 0.0 to 1.0
    function battery(dc as Dc, cx as Number, cy as Number, color as Number, fill as Float) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRectangle(cx - 11, cy - 6, 20, 12);
        dc.fillRectangle(cx + 9, cy - 3, 3, 6);

        var clamped = fill;
        if (clamped < 0.0) { clamped = 0.0; }
        if (clamped > 1.0) { clamped = 1.0; }
        var width = (16 * clamped).toNumber();
        if (width > 0) {
            dc.fillRectangle(cx - 9, cy - 4, width, 8);
        }
    }

    // --- Data rows -------------------------------------------------------

    function heart(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - 4, cy - 3, 5);
        dc.fillCircle(cx + 4, cy - 3, 5);
        dc.fillPolygon([[cx - 8, cy - 1], [cx + 8, cy - 1], [cx, cy + 8]] as Array<[Numeric, Numeric]>);
    }

    //! Bolt - Body Battery. Garmin itself draws the charge state as a bolt, so
    //! the symbol is familiar to the user from Connect.
    function bolt(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx + 2, cy - 9], [cx - 7, cy + 2], [cx - 1, cy + 2],
                        [cx - 2, cy + 9], [cx + 7, cy - 2], [cx + 1, cy - 2]]
                       as Array<[Numeric, Numeric]>);
    }

    //! Rising bars - stress as a level.
    //!
    //! A dial gauge was indistinguishable from a check mark at 18 px, and a pulse
    //! line would have been ambiguous next to the heart. Bars still read as
    //! "value on a scale" even at tiny sizes.
    function bars(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 8, cy + 2, 4, 6);
        dc.fillRectangle(cx - 2, cy - 3, 4, 11);
        dc.fillRectangle(cx + 4, cy - 8, 4, 16);
    }

    //! Flame - calories burned.
    //!
    //! The notch at the upper left is the whole difference from a water drop:
    //! without it, it is a point on a ball and gets read as a drop.
    function flame(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx + 1, cy - 9], [cx + 6, cy], [cx + 6, cy + 4],
                        [cx + 2, cy + 9], [cx - 4, cy + 8], [cx - 6, cy + 2],
                        [cx - 3, cy - 4], [cx - 2, cy + 1]]
                       as Array<[Numeric, Numeric]>);
    }

    //! Sun above the horizon, with an arrow in the direction of travel.
    //!
    //! One symbol for both events, only the arrow flips. That is intentional: the
    //! watch face only ever shows the **next** of the two, and two completely
    //! different symbols in the same place would make the switch read as a
    //! glitch instead of as the day progressing.
    //!
    //! @param rising true = sunrise (arrow up), false = sunset
    function sunEvent(dc as Dc, cx as Number, cy as Number, color as Number,
                      rising as Boolean) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.fillCircle(cx, cy - 3, 5);
        dc.drawLine(cx - 9, cy + 4, cx + 9, cy + 4);
        // The arrow sits centered **below** the horizon, not beside the disc.
        // Placed beside it, it read as a separate sign next to the sun; below the
        // line it is the movement of the sun itself.
        if (rising) {
            dc.fillPolygon([[cx, cy + 7], [cx - 4, cy + 12], [cx + 4, cy + 12]]
                           as Array<[Numeric, Numeric]>);
        } else {
            dc.fillPolygon([[cx - 4, cy + 7], [cx + 4, cy + 7], [cx, cy + 12]]
                           as Array<[Numeric, Numeric]>);
        }
    }

    //! Hourglass - remaining recovery time.
    //!
    //! The two sand cones are filled, the frame is only two strokes. A fully
    //! outlined glass turns into a grey blob at 18 px; the silhouette of two
    //! triangles stays unambiguous even when tiny.
    function hourglass(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - 6, cy - 9, cx + 6, cy - 9);
        dc.drawLine(cx - 6, cy + 9, cx + 6, cy + 9);
        dc.fillPolygon([[cx - 5, cy - 7], [cx + 5, cy - 7], [cx, cy]]
                       as Array<[Numeric, Numeric]>);
        dc.fillPolygon([[cx - 5, cy + 7], [cx + 5, cy + 7], [cx, cy]]
                       as Array<[Numeric, Numeric]>);
    }

    //! Rocket - training status.
    //!
    //! It carries the status through its color alone, with no text next to it.
    //! The spelled-out status used to be a word of up to eight characters in row
    //! C and ran into its neighbors on "Bestform" or "Ueberlast". The rocket is
    //! always 18 px wide, whatever the watch reports.
    function rocket(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        // Short tip on a vertical body. A long, continuous taper from the tip to
        // the fins makes a single triangle - the first version looked like an
        // arrowhead.
        dc.fillPolygon([[cx, cy - 10], [cx + 3, cy - 5], [cx - 3, cy - 5]]
                       as Array<[Numeric, Numeric]>);
        dc.fillRectangle(cx - 3, cy - 5, 7, 10);
        // Fins, splayed outwards
        dc.fillPolygon([[cx - 3, cy], [cx - 3, cy + 5], [cx - 8, cy + 5]]
                       as Array<[Numeric, Numeric]>);
        dc.fillPolygon([[cx + 4, cy], [cx + 4, cy + 5], [cx + 9, cy + 5]]
                       as Array<[Numeric, Numeric]>);
        // Exhaust, set off with a two-pixel gap. This very gap makes the rocket:
        // without it tip, body and fins merge into a single triangle, and a
        // second version with a porthole read as a big "A".
        dc.fillPolygon([[cx - 3, cy + 7], [cx + 3, cy + 7], [cx, cy + 11]]
                       as Array<[Numeric, Numeric]>);
    }

    //! Mountain with snow cap - current altitude.
    //!
    //! Two peaks, not one: a single triangle can't be told apart from a direction
    //! arrow at 18 px, and the weather row already carries one of those as the
    //! pressure trend. The white cap is drawn last and sits over the rock.
    function mountain(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx - 5, cy - 1], [cx + 1, cy + 8], [cx - 9, cy + 8]]
                       as Array<[Numeric, Numeric]>);
        dc.fillPolygon([[cx + 1, cy - 9], [cx + 9, cy + 8], [cx - 7, cy + 8]]
                       as Array<[Numeric, Numeric]>);
        dc.setColor(Theme.PRIMARY, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx + 1, cy - 9], [cx + 5, cy - 3], [cx - 3, cy - 3]]
                       as Array<[Numeric, Numeric]>);
    }

    // --- Legends of the goal arcs ----------------------------------------
    //
    // Four symbols that say what the four colored sections of the edge stand for.
    // They are the only concession to first contact: whoever knows the watch
    // face reads the colors, whoever sees it for the first time reads the symbols.

    //! Footprint - steps.
    //!
    //! Three parts make up the print: round ball, a narrowing arch, a set-off
    //! heel. The first version put a rectangle under the ball and ended up as a
    //! blob - only the taper toward the heel turns it into a foot.
    function footprint(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - 1, cy - 4, 5);          // ball
        dc.fillCircle(cx + 4, cy - 7, 2);          // big toe
        dc.fillPolygon([[cx - 6, cy - 4], [cx + 4, cy - 4],
                        [cx + 2, cy + 3], [cx - 2, cy + 3]]
                       as Array<[Numeric, Numeric]>);  // arch
        dc.fillCircle(cx, cy + 5, 4);              // heel
    }

    //! Stair profile - floors.
    //!
    //! Drawn as a line path instead of filled steps, otherwise it would be the
    //! same picture as the stress bars.
    function stairs(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - 9, cy + 8, cx - 9, cy + 3);
        dc.drawLine(cx - 9, cy + 3, cx - 3, cy + 3);
        dc.drawLine(cx - 3, cy + 3, cx - 3, cy - 2);
        dc.drawLine(cx - 3, cy - 2, cx + 3, cy - 2);
        dc.drawLine(cx + 3, cy - 2, cx + 3, cy - 7);
        dc.drawLine(cx + 3, cy - 7, cx + 9, cy - 7);
    }

    //! Stopwatch - active minutes of the week.
    function stopwatch(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy + 1, 7);
        dc.fillRectangle(cx - 3, cy - 10, 6, 3);   // crown
        dc.drawLine(cx, cy - 7, cx, cy - 6);       // stem
        dc.drawLine(cx, cy + 1, cx, cy - 4);       // hand
    }

    //! Runner as a stick figure. Row D leaves only about 200 px for both sports -
    //! a text label "LAUF" alone would be 72 px wide.
    function runner(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx + 2, cy - 7, 3);
        dc.setPenWidth(2);
        dc.drawLine(cx + 1, cy - 4, cx - 2, cy + 2);   // torso
        dc.drawLine(cx + 3, cy - 3, cx - 4, cy - 1);   // rear arm
        dc.drawLine(cx + 1, cy - 3, cx + 6, cy + 1);   // front arm
        dc.drawLine(cx - 2, cy + 2, cx - 5, cy + 8);   // rear leg
        dc.drawLine(cx - 2, cy + 2, cx + 4, cy + 7);   // front leg
    }

    function bike(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx - 6, cy + 3, 5);
        dc.drawCircle(cx + 6, cy + 3, 5);
        dc.drawLine(cx - 6, cy + 3, cx - 1, cy - 4);   // seat tube
        dc.drawLine(cx - 1, cy - 4, cx + 6, cy + 3);   // top tube
        dc.drawLine(cx - 6, cy + 3, cx + 3, cy + 3);   // down tube
        dc.drawLine(cx - 1, cy - 4, cx + 4, cy - 5);   // handlebar
    }

    //! @param direction -1 falling, 0 steady, +1 rising
    function trend(dc as Dc, cx as Number, cy as Number, color as Number,
                   direction as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (direction > 0) {
            dc.fillPolygon([[cx, cy - 6], [cx + 6, cy + 4], [cx - 6, cy + 4]]
                           as Array<[Numeric, Numeric]>);
        } else if (direction < 0) {
            dc.fillPolygon([[cx, cy + 6], [cx + 6, cy - 4], [cx - 6, cy - 4]]
                           as Array<[Numeric, Numeric]>);
        } else {
            dc.setPenWidth(3);
            dc.drawLine(cx - 6, cy, cx + 6, cy);
        }
    }

    // --- Weather ---------------------------------------------------------
    //
    // The following helper functions are meant for internal use only. Monkey C
    // has no visibility modifiers for module functions, so they stay formally
    // public.

    //! Draws the symbol matching the weather condition.
    //!
    //! The symbol picks its own colors instead of receiving one from outside:
    //! sun yellow, cloud grey, rain blue, snow white, thunderstorm with a yellow
    //! bolt. A single-color weather symbol is barely readable at 22 px - only the
    //! two-tone treatment separates cloud from precipitation. And it makes the
    //! weather recognizable at a glance, without having to decipher the shape.
    //!
    //! @param condition a Weather.CONDITION_* constant or null
    function weather(dc as Dc, cx as Number, cy as Number, condition as Number?) as Void {
        var kind = weatherKind(condition);

        if (kind == :sun) {
            sun(dc, cx, cy, Theme.SUN, 6);
        } else if (kind == :partly) {
            sun(dc, cx + 4, cy - 4, Theme.SUN, 4);
            cloud(dc, cx - 1, cy + 3, Theme.CLOUD);
        } else if (kind == :cloud) {
            cloud(dc, cx, cy, Theme.CLOUD);
        } else if (kind == :rain) {
            cloud(dc, cx, cy - 3, Theme.CLOUD);
            drops(dc, cx, cy + 7, Theme.RAIN);
        } else if (kind == :snow) {
            cloud(dc, cx, cy - 3, Theme.CLOUD);
            flakes(dc, cx, cy + 7, Theme.PRIMARY);
        } else if (kind == :storm) {
            cloud(dc, cx, cy - 3, Theme.HAZE);
            dc.setColor(Theme.SUN, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([[cx + 1, cy + 3], [cx - 4, cy + 11], [cx, cy + 11],
                            [cx - 2, cy + 16], [cx + 5, cy + 7], [cx + 1, cy + 7]]
                           as Array<[Numeric, Numeric]>);
        } else {
            fog(dc, cx, cy, Theme.HAZE);
        }
    }

    //! Disc in the passed color, rays one tone warmer. The difference in
    //! brightness makes the disc glow instead of merely being yellow.
    function sun(dc as Dc, cx as Number, cy as Number, color as Number,
                         radius as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, radius);
        dc.setColor(Theme.WARM, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var inner = radius + 3;
        var outer = radius + 6;
        // Four straight and four diagonal rays, hard-coded instead of computed via
        // sine - with eight rays the table is cheaper than the math.
        var rays = [[1, 0], [-1, 0], [0, 1], [0, -1],
                    [7, 7], [7, -7], [-7, 7], [-7, -7]] as Array<Array<Number>>;
        for (var i = 0; i < rays.size(); i++) {
            var ux = rays[i][0] / 10.0;
            var uy = rays[i][1] / 10.0;
            if (i < 4) { ux = rays[i][0]; uy = rays[i][1]; }
            dc.drawLine((cx + ux * inner).toNumber(), (cy + uy * inner).toNumber(),
                        (cx + ux * outer).toNumber(), (cy + uy * outer).toNumber());
        }
    }

    function cloud(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - 5, cy + 1, 5);
        dc.fillCircle(cx + 1, cy - 3, 6);
        dc.fillCircle(cx + 6, cy + 1, 5);
        dc.fillRectangle(cx - 5, cy + 1, 12, 5);
    }

    function drops(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = -1; i <= 1; i++) {
            var x = cx + i * 6;
            dc.drawLine(x + 1, cy - 1, x - 1, cy + 4);
        }
    }

    function flakes(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        for (var i = -1; i <= 1; i++) {
            dc.fillCircle(cx + i * 6, cy + 1, 2);
        }
    }

    function fog(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - 9, cy - 5, cx + 9, cy - 5);
        dc.drawLine(cx - 7, cy, cx + 9, cy);
        dc.drawLine(cx - 9, cy + 5, cx + 7, cy + 5);
    }

    //! Condenses the SDK's roughly 50 weather conditions into seven drawable symbols.
    function weatherKind(condition as Number?) as Symbol {
        if (condition == null) { return :fog; }

        switch (condition) {
            case Weather.CONDITION_CLEAR:
            case Weather.CONDITION_FAIR:
            case Weather.CONDITION_MOSTLY_CLEAR:
                return :sun;

            case Weather.CONDITION_PARTLY_CLOUDY:
            case Weather.CONDITION_PARTLY_CLEAR:
            case Weather.CONDITION_THIN_CLOUDS:
                return :partly;

            case Weather.CONDITION_CLOUDY:
            case Weather.CONDITION_MOSTLY_CLOUDY:
            case Weather.CONDITION_WINDY:
                return :cloud;

            case Weather.CONDITION_RAIN:
            case Weather.CONDITION_LIGHT_RAIN:
            case Weather.CONDITION_HEAVY_RAIN:
            case Weather.CONDITION_DRIZZLE:
            case Weather.CONDITION_SHOWERS:
            case Weather.CONDITION_LIGHT_SHOWERS:
            case Weather.CONDITION_HEAVY_SHOWERS:
            case Weather.CONDITION_SCATTERED_SHOWERS:
            case Weather.CONDITION_CHANCE_OF_SHOWERS:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
            case Weather.CONDITION_FREEZING_RAIN:
            case Weather.CONDITION_UNKNOWN_PRECIPITATION:
                return :rain;

            case Weather.CONDITION_SNOW:
            case Weather.CONDITION_LIGHT_SNOW:
            case Weather.CONDITION_HEAVY_SNOW:
            case Weather.CONDITION_FLURRIES:
            case Weather.CONDITION_CHANCE_OF_SNOW:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
            case Weather.CONDITION_RAIN_SNOW:
            case Weather.CONDITION_LIGHT_RAIN_SNOW:
            case Weather.CONDITION_HEAVY_RAIN_SNOW:
            case Weather.CONDITION_CHANCE_OF_RAIN_SNOW:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW:
            case Weather.CONDITION_SLEET:
            case Weather.CONDITION_HAIL:
            case Weather.CONDITION_ICE:
            case Weather.CONDITION_ICE_SNOW:
            case Weather.CONDITION_WINTRY_MIX:
                return :snow;

            case Weather.CONDITION_THUNDERSTORMS:
            case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
            case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
            case Weather.CONDITION_SQUALL:
            case Weather.CONDITION_HURRICANE:
            case Weather.CONDITION_TORNADO:
            case Weather.CONDITION_TROPICAL_STORM:
                return :storm;
        }

        // Fog, haze, smoke, dust, sand, ash and anything unknown.
        return :fog;
    }
}
