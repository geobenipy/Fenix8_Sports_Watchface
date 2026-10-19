import Toybox.Lang;

//! Everything that has to appear on the watch face in German.
//!
//! Deliberately **not** driven by the device language: `Gregorian.info` returns
//! the weekday in the language the watch is set to, and the training status
//! arrives from the complication as ready-made localized text. Both would turn
//! English as soon as the watch speaks English. This watch face is German,
//! regardless of the system setting.
module Locale {

    //! Weekday as a two-letter abbreviation.
    //! @param dayOfWeek as returned by Gregorian.info in FORMAT_SHORT: 1 = Sunday
    function weekday(dayOfWeek as Number) as String {
        var names = ["SO", "MO", "DI", "MI", "DO", "FR", "SA"] as Array<String>;
        var index = dayOfWeek - 1;
        if (index < 0 || index >= names.size()) { return "--"; }
        return names[index];
    }

    //! Maps the training status to its color.
    //!
    //! The status only appears as a colored rocket with no text next to it, so
    //! this function returns just a color. Nothing gets translated anymore, but
    //! both English and German system texts are still recognized.
    //!
    //! Matching is done on substrings so that English *and* German system texts
    //! land on the same status. The order of the table matters: "unproductive"
    //! contains "productive", so the negative case has to be checked first.
    //!
    //! The patterns avoid umlauts - `toLower` in Monkey C only touches ASCII, so
    //! a pattern "ueberlast" would never match "Ueberlastung". "berlast" matches
    //! both spellings, and "chstform" matches "Höchstform" the same way.
    //!
    //! The colors follow the scale Garmin itself uses; see `Theme.TRAIN_*` and
    //! DESIGN.md, section 3.
    function trainingColor(raw as String?) as Number {
        if (raw == null) { return Theme.LABEL; }

        var needle = raw.toLower();

        // Pattern and color - checked in exactly this order.
        var table = [
            ["unproduc",  Theme.TRAIN_UNPRODUCTIVE],
            ["unproduk",  Theme.TRAIN_UNPRODUCTIVE],
            ["overreach", Theme.TRAIN_OVERREACH],
            ["berlast",   Theme.TRAIN_OVERREACH],
            ["strain",    Theme.TRAIN_STRAINED],
            ["strapaz",   Theme.TRAIN_STRAINED],
            ["belastet",  Theme.TRAIN_STRAINED],
            ["detrain",   Theme.TRAIN_DETRAIN],
            ["formverl",  Theme.TRAIN_DETRAIN],
            ["recovery",  Theme.TRAIN_RECOVERY],
            ["erholung",  Theme.TRAIN_RECOVERY],
            ["maintain",  Theme.TRAIN_MAINTAIN],
            ["erhalt",    Theme.TRAIN_MAINTAIN],
            ["peaking",   Theme.TRAIN_PEAK],
            ["chstform",  Theme.TRAIN_PEAK],
            ["bestform",  Theme.TRAIN_PEAK],
            ["productive", Theme.TRAIN_PRODUCTIVE],
            ["produktiv", Theme.TRAIN_PRODUCTIVE],
            ["aufbau",    Theme.TRAIN_PRODUCTIVE]
        ] as Array<Array>;

        for (var i = 0; i < table.size(); i++) {
            if (needle.find(table[i][0] as String) != null) {
                return table[i][1] as Number;
            }
        }

        // "No Result", "Pausiert" and anything unknown: grey rocket.
        return Theme.LABEL;
    }

    //! Replaces the decimal point with a comma.
    //! Monkey C has no String.replace, hence the detour through the characters.
    function comma(text as String) as String {
        var out = "";
        for (var i = 0; i < text.length(); i++) {
            var character = text.substring(i, i + 1);
            if (character == null) { continue; }
            out += character.equals(".") ? "," : character;
        }
        return out;
    }
}
