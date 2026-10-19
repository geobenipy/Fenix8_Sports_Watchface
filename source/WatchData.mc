import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;
import Toybox.Weather;

//! Collects all values of the watch face in one place.
//!
//! Three cost classes, read at correspondingly different rates:
//!   - every frame: time, heart rate, ActivityMonitor (cheap)
//!   - every minute: complications and user profile
//!   - every 15 minutes: weather, sunset, pressure history
//!
//! Body Battery and stress deliberately come from the complications and not
//! from SensorHistory: the device definition of fenix843mm lists no sensor
//! history for either.
class WatchData {

    private const SLOW_INTERVAL_MS = 60000;
    private const WEATHER_INTERVAL_MS = 900000;

    //! Heart rate is averaged over five samples so the value doesn't jump every
    //! second. Only useful in active mode - in AOD the system delivers only
    //! per-minute values anyway.
    private const HR_SAMPLES = 5;

    private var _hrBuffer as Array<Number> = [];

    // Updated every minute
    private var _bodyBattery as Number? = null;
    private var _stress as Number? = null;
    private var _trainingStatus as String? = null;
    private var _weeklyRunMeters as Float? = null;
    private var _weeklyBikeMeters as Float? = null;
    private var _recoveryMinutes as Number? = null;
    private var _raceSeconds as Number? = null;
    private var _altitude as Number? = null;
    private var _vo2maxRun as Number? = null;
    private var _vo2maxBike as Number? = null;
    private var _restingHeartRate as Number? = null;
    private var _lastSlowRead as Number = -SLOW_INTERVAL_MS;

    // Updated every 15 minutes
    private var _temperature as Number? = null;
    private var _condition as Number? = null;
    private var _forecastHigh as Number? = null;
    private var _forecastLow as Number? = null;
    private var _sunriseSeconds as Number? = null;
    private var _sunsetSeconds as Number? = null;
    private var _pressureHpa as Number? = null;
    private var _pressureTrend as Number = 0;  // -1 falling, 0 steady, +1 rising
    private var _lastWeatherRead as Number = -WEATHER_INTERVAL_MS;

    private var _subscribed as Boolean = false;

    //! Which race prediction is shown: 0 = 5 km, 1 = 10 km,
    //! 2 = half marathon, 3 = marathon. Comes from the watch's face editor.
    private var _raceDistance as Number = 1;

    function initialize() {
    }

    // --- Configuration ---------------------------------------------------

    //! Sets the race distance to display.
    //!
    //! **Where** the number comes from is decided by `BeniView.applyConfiguration` -
    //! this class no longer reads any settings itself, otherwise there would be
    //! two places fetching the same thing from different sources.
    //!
    //! The timestamp is reset so the new distance appears immediately and not
    //! only at the next minute tick.
    function setRaceDistance(distance as Number) as Void {
        if (distance < 0 || distance > 3 || distance == _raceDistance) { return; }
        _raceDistance = distance;
        _lastSlowRead = -SLOW_INTERVAL_MS;
    }

    //! Short name of the selected distance, as shown before the time in row C.
    function raceLabel() as String {
        if (_raceDistance == 0) { return "5K"; }
        if (_raceDistance == 2) { return "HM"; }
        if (_raceDistance == 3) { return "MAR"; }
        return "10K";
    }

    private function raceComplicationType() as Complications.Type {
        if (_raceDistance == 0) {
            return Complications.COMPLICATION_TYPE_RACE_PREDICTOR_5K;
        }
        if (_raceDistance == 2) {
            return Complications.COMPLICATION_TYPE_RACE_PREDICTOR_HALF_MARATHON;
        }
        if (_raceDistance == 3) {
            return Complications.COMPLICATION_TYPE_RACE_PREDICTOR_MARATHON;
        }
        return Complications.COMPLICATION_TYPE_RACE_PREDICTOR_10K;
    }

    // --- Lifecycle -------------------------------------------------------

    //! Without a subscription the system doesn't feed the complications values.
    function subscribe() as Void {
        if (_subscribed || !(Toybox has :Complications)) { return; }
        var types = [
            Complications.COMPLICATION_TYPE_BODY_BATTERY,
            Complications.COMPLICATION_TYPE_STRESS,
            Complications.COMPLICATION_TYPE_TRAINING_STATUS,
            Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE,
            Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE,
            Complications.COMPLICATION_TYPE_RECOVERY_TIME,
            Complications.COMPLICATION_TYPE_SUNRISE,
            Complications.COMPLICATION_TYPE_SUNSET,
            // All four predictions, although only one is shown: otherwise the
            // subscription would depend on a setting that can change at any time
            // and would have to be rebuilt on every change. Four values that move
            // at most daily cost less than this state machine.
            Complications.COMPLICATION_TYPE_RACE_PREDICTOR_5K,
            Complications.COMPLICATION_TYPE_RACE_PREDICTOR_10K,
            Complications.COMPLICATION_TYPE_RACE_PREDICTOR_HALF_MARATHON,
            Complications.COMPLICATION_TYPE_RACE_PREDICTOR_MARATHON
        ];
        for (var i = 0; i < types.size(); i++) {
            try {
                Complications.subscribeToUpdates(new Complications.Id(types[i]));
            } catch (e) {
                // A few types that can't be subscribed to are no reason to give up.
            }
        }
        _subscribed = true;
    }

    function unsubscribe() as Void {
        if (!_subscribed || !(Toybox has :Complications)) { return; }
        try {
            Complications.unsubscribeFromAllUpdates();
        } catch (e) {
            // Nothing to do.
        }
        _subscribed = false;
    }

    //! Call once per frame, before drawing.
    function refresh() as Void {
        sampleHeartRate();

        var now = System.getTimer();
        if (now - _lastSlowRead >= SLOW_INTERVAL_MS) {
            _lastSlowRead = now;
            refreshSlow();
        }
        if (now - _lastWeatherRead >= WEATHER_INTERVAL_MS) {
            _lastWeatherRead = now;
            refreshWeather();
        }
    }

    private function refreshSlow() as Void {
        _bodyBattery = complicationNumber(Complications.COMPLICATION_TYPE_BODY_BATTERY);
        _stress = complicationNumber(Complications.COMPLICATION_TYPE_STRESS);
        _trainingStatus = complicationText(Complications.COMPLICATION_TYPE_TRAINING_STATUS);
        _weeklyRunMeters = complicationFloat(Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE);
        _weeklyBikeMeters = complicationFloat(Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE);
        _recoveryMinutes = complicationNumber(Complications.COMPLICATION_TYPE_RECOVERY_TIME);
        _raceSeconds = complicationNumber(raceComplicationType());
        refreshAltitude();
        refreshSunTimes();

        // VO2max comes from the profile, not from the complications: both values
        // are available there without a subscription, and the profile delivers
        // running and cycling in a single access.
        try {
            var profile = UserProfile.getProfile();
            _vo2maxRun = profile.vo2maxRunning;
            _vo2maxBike = profile.vo2maxCycling;
            _restingHeartRate = readRestingHeartRate(profile);
        } catch (e) {
            // Profile values stay what they were.
        }
    }

    //! Resting heart rate, with the **calculated** value as first choice.
    //!
    //! According to the SDK, `restingHeartRate` is "as configured by the user" -
    //! only what was entered by hand. Anyone who never did that gets null there,
    //! and that is exactly how it was on the watch: the field stayed empty even
    //! though Garmin knows a resting heart rate. `averageRestingHeartRate` is the
    //! value calculated from the last seven days of data, and the one you also see
    //! in Connect.
    //!
    //! The manually entered value stays as a fallback: whoever set it did so for
    //! a reason.
    private function readRestingHeartRate(profile as UserProfile.Profile) as Number? {
        if (profile has :averageRestingHeartRate) {
            var average = profile.averageRestingHeartRate;
            if (average != null) { return average; }
        }
        return profile.restingHeartRate;
    }

    //! Sunrise and sunset as seconds since midnight.
    //!
    //! **The complications are first choice**, not the weather API. The previous
    //! version fetched both times via `Weather.getSunrise(position, ...)` and
    //! needed the `observationLocationPosition` of the current conditions for
    //! that. On the watch that was null - the field stayed permanently on
    //! `--:--`, even though temperature and forecast were showing next to it. The
    //! complications deliver the times without a location and without the
    //! position permission.
    //!
    //! The weather API stays as a fallback in case a device doesn't know the two
    //! complication types.
    private function refreshSunTimes() as Void {
        var rise = complicationNumber(Complications.COMPLICATION_TYPE_SUNRISE);
        var set = complicationNumber(Complications.COMPLICATION_TYPE_SUNSET);
        if (rise != null) { _sunriseSeconds = rise; }
        if (set != null) { _sunsetSeconds = set; }
        if (rise != null && set != null) { return; }

        try {
            var conditions = Weather.getCurrentConditions();
            if (conditions == null) { return; }
            var position = conditions.observationLocationPosition;
            if (position == null) { return; }

            var today = Time.now();
            if (rise == null) {
                _sunriseSeconds = secondsOfDay(Weather.getSunrise(position, today));
            }
            if (set == null) {
                _sunsetSeconds = secondsOfDay(Weather.getSunset(position, today));
            }
        } catch (e) {
            // Without a position and without a complication it stays at "--:--".
        }
    }

    //! Converts a point in time to seconds since midnight.
    private function secondsOfDay(moment as Time.Moment?) as Number? {
        if (moment == null) { return null; }
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        return info.hour * 3600 + info.min * 60;
    }

    //! Current altitude in meters.
    //!
    //! First choice is `ActivityInfo.altitude` - the value is available outside
    //! a recording too and is the freshest. The altitude history is the fallback:
    //! it exists on this device (the device definition lists altitude as a sensor
    //! history), but only delivers the last stored point, not the instantaneous
    //! value.
    private function refreshAltitude() as Void {
        try {
            var info = Activity.getActivityInfo();
            if (info != null) {
                var altitude = info.altitude;
                if (altitude != null) {
                    _altitude = altitude.toNumber();
                    return;
                }
            }
        } catch (e) {
            // Continue with the history.
        }

        try {
            var sample = SensorHistory.getElevationHistory({}).next();
            if (sample != null && sample.data != null) {
                _altitude = sample.data.toNumber();
            }
        } catch (e) {
            // No altimeter, no value.
        }
    }

    private function refreshWeather() as Void {
        try {
            var conditions = Weather.getCurrentConditions();
            if (conditions != null) {
                _temperature = conditions.temperature;
                _condition = conditions.condition;

            }

            var forecast = Weather.getDailyForecast();
            if (forecast != null && forecast.size() > 0) {
                // Index 0 is the current day, hence the next day as the preview.
                var day = forecast[forecast.size() > 1 ? 1 : 0];
                _forecastHigh = day.highTemperature;
                _forecastLow = day.lowTemperature;
            }
        } catch (e) {
            // Without weather data the fields stay empty.
        }

        refreshPressure();
    }

    //! Air pressure plus trend over the last three hours.
    private function refreshPressure() as Void {
        try {
            var iterator = SensorHistory.getPressureHistory({});

            var newest = null;
            var oldest = null;
            var count = 0;
            var sample = iterator.next();
            while (sample != null && count < 90) {  // 90 x 120 s = 3 h
                if (sample.data != null) {
                    if (newest == null) { newest = sample.data; }
                    oldest = sample.data;
                }
                count++;
                sample = iterator.next();
            }

            if (newest == null) { return; }
            _pressureHpa = (newest / 100.0).toNumber();

            if (oldest != null) {
                var deltaHpa = (newest - oldest) / 100.0;
                // Below one hectopascal it is noise, not a trend.
                _pressureTrend = (deltaHpa > 1.0) ? 1 : ((deltaHpa < -1.0) ? -1 : 0);
            }
        } catch (e) {
            // No pressure sensor or no history.
        }
    }

    // --- Heart rate ------------------------------------------------------

    private function sampleHeartRate() as Void {
        var info = Activity.getActivityInfo();
        if (info == null) { return; }
        var hr = info.currentHeartRate;
        if (hr == null) { return; }

        _hrBuffer.add(hr);
        if (_hrBuffer.size() > HR_SAMPLES) {
            _hrBuffer = _hrBuffer.slice(_hrBuffer.size() - HR_SAMPLES, null);
        }
    }

    function heartRate() as Number? {
        if (_hrBuffer.size() == 0) { return null; }
        var sum = 0;
        for (var i = 0; i < _hrBuffer.size(); i++) { sum += _hrBuffer[i]; }
        return (sum.toFloat() / _hrBuffer.size()).toNumber();
    }

    function restingHeartRate() as Number? { return _restingHeartRate; }

    // --- Goal arcs -------------------------------------------------------

    function stepsProgress() as Float {
        var info = ActivityMonitor.getInfo();
        return ratio(info.steps, info.stepGoal);
    }

    function floorsProgress() as Float {
        var info = ActivityMonitor.getInfo();
        return ratio(info.floorsClimbed, info.floorsClimbedGoal);
    }

    function activeMinutesProgress() as Float {
        var info = ActivityMonitor.getInfo();
        var week = info.activeMinutesWeek;
        return ratio(week == null ? null : week.total, info.activeMinutesWeekGoal);
    }

    //! Body Battery is already a scale from 0 to 100 and needs no goal.
    function bodyBatteryProgress() as Float {
        var value = _bodyBattery;
        return (value == null) ? 0.0 : value.toFloat() / 100.0;
    }

    function hasBodyBattery() as Boolean { return _bodyBattery != null; }

    // --- Data rows -------------------------------------------------------

    function bodyBattery() as Number? { return _bodyBattery; }
    function stress() as Number? { return _stress; }
    function trainingStatus() as String? { return _trainingStatus; }
    function vo2maxRun() as Number? { return _vo2maxRun; }
    function vo2maxBike() as Number? { return _vo2maxBike; }
    function recoveryMinutes() as Number? { return _recoveryMinutes; }
    function raceSeconds() as Number? { return _raceSeconds; }
    function altitude() as Number? { return _altitude; }
    function temperature() as Number? { return _temperature; }
    function condition() as Number? { return _condition; }
    function forecastHigh() as Number? { return _forecastHigh; }
    function forecastLow() as Number? { return _forecastLow; }
    function pressureHpa() as Number? { return _pressureHpa; }
    function pressureTrend() as Number { return _pressureTrend; }
    function weeklyRunMeters() as Float? { return _weeklyRunMeters; }
    function weeklyBikeMeters() as Float? { return _weeklyBikeMeters; }

    function calories() as Number? {
        return ActivityMonitor.getInfo().calories;
    }

    // --- Sun cycle -------------------------------------------------------
    //
    // The watch face only ever shows the **next** of the two events: the sunset
    // in the afternoon, the next day's sunrise after sunset. A time that has
    // already passed is no information.

    //! true if a sunrise comes next.
    function nextSunRising() as Boolean {
        var now = nowSeconds();
        var rise = _sunriseSeconds;
        var set = _sunsetSeconds;
        if (rise != null && now < rise) { return true; }
        if (set != null && now < set) { return false; }
        return true;
    }

    //! Next sunrise or sunset, seconds since midnight.
    //!
    //! After sunset this holds the sunrise of **today**, not tomorrow's. Depending
    //! on the season the two are one to four minutes apart - close enough for a
    //! display that rounds to the minute and only says when it gets light again,
    //! and it saves a second data path.
    function nextSunSeconds() as Number? {
        var now = nowSeconds();
        var rise = _sunriseSeconds;
        var set = _sunsetSeconds;
        if (rise != null && now < rise) { return rise; }
        if (set != null && now < set) { return set; }
        return rise;
    }

    private function nowSeconds() as Number {
        var clock = System.getClockTime();
        return clock.hour * 3600 + clock.min * 60 + clock.sec;
    }

    // --- Helper functions ------------------------------------------------

    private function ratio(current as Number?, goal as Number?) as Float {
        if (current == null || goal == null || goal <= 0) { return 0.0; }
        return current.toFloat() / goal.toFloat();
    }

    private function complicationNumber(type as Complications.Type) as Number? {
        var complication = readComplication(type);
        if (complication == null) { return null; }
        var value = complication.value;
        if (value instanceof Lang.Number) { return value; }
        if (value instanceof Lang.Float || value instanceof Lang.Double) {
            return value.toNumber();
        }
        return null;
    }

    //! Distance complications deliver floating-point numbers. Their unit field
    //! reports UNIT_DISTANCE (1), which according to the SDK docs means: value in
    //! meters.
    private function complicationFloat(type as Complications.Type) as Float? {
        var complication = readComplication(type);
        if (complication == null) { return null; }
        var value = complication.value;
        if (value instanceof Lang.Float || value instanceof Lang.Double) {
            return value.toFloat();
        }
        if (value instanceof Lang.Number) { return value.toFloat(); }
        return null;
    }

    //! The training status sits in the value field as ready-made text, not in the
    //! labels - those only contain the name of the metric ("Training Status").
    private function complicationText(type as Complications.Type) as String? {
        var complication = readComplication(type);
        if (complication == null) { return null; }
        var value = complication.value;
        if (value instanceof Lang.String && value.length() > 0) { return value; }
        return null;
    }

    private function readComplication(type as Complications.Type) as Complications.Complication? {
        if (!(Toybox has :Complications)) { return null; }
        try {
            return Complications.getComplication(new Complications.Id(type));
        } catch (e) {
            // getComplication throws if the type is missing on this device.
            return null;
        }
    }

    //! Development only: prints what the complications actually deliver.
    //! The units are undocumented, so they have to be measured.
    function dumpComplications() as Void {
        if (!(Toybox has :Complications)) {
            System.println("Complications not available");
            return;
        }
        var types = [
            Complications.COMPLICATION_TYPE_BODY_BATTERY,
            Complications.COMPLICATION_TYPE_STRESS,
            Complications.COMPLICATION_TYPE_TRAINING_STATUS,
            Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE,
            Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE,
            Complications.COMPLICATION_TYPE_RECOVERY_TIME,
            Complications.COMPLICATION_TYPE_RACE_PREDICTOR_5K,
            Complications.COMPLICATION_TYPE_RACE_PREDICTOR_10K,
            Complications.COMPLICATION_TYPE_RACE_PREDICTOR_HALF_MARATHON,
            Complications.COMPLICATION_TYPE_RACE_PREDICTOR_MARATHON
        ];
        var names = ["BODY_BATTERY", "STRESS", "TRAINING_STATUS", "WEEKLY_RUN", "WEEKLY_BIKE",
                     "RECOVERY_TIME", "RACE_5K", "RACE_10K", "RACE_HALF", "RACE_MARATHON"];
        for (var i = 0; i < types.size(); i++) {
            var complication = readComplication(types[i]);
            if (complication == null) {
                System.println(names[i] + ": not found");
            } else {
                System.println(names[i]
                    + " value=" + complication.value
                    + " unit=" + complication.unit
                    + " short=" + complication.shortLabel
                    + " long=" + complication.longLabel);
            }
        }
        var profile = UserProfile.getProfile();
        System.println("vo2maxRunning=" + profile.vo2maxRunning
            + " vo2maxCycling=" + profile.vo2maxCycling
            + " restingHeartRate=" + profile.restingHeartRate);
    }
}
