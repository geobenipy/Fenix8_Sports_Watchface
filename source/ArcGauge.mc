import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! One colored section of the edge ring.
//!
//! Each section grows away from the end that is closer to 12 or 6 o'clock (the
//! "anchor"). That way the two upper sections fill symmetrically from top
//! center outwards and the two lower ones from bottom center outwards.
//!
//! The ends are rounded. `drawArc` draws blunt edges, and at a stroke width of
//! 14 px four blunt segments look like a sawn-off ring. A circle with half the
//! stroke width on the arc's center line is the round cap - cheaper than any
//! other solution and pixel-exact.
class ArcGauge {

    private var _anchorDeg as Number;
    private var _direction as Graphics.ArcDirection;
    private var _color as Number;

    //! @param anchorDeg angle in degrees at which the fill starts
    //! @param direction direction in which the fill grows
    //! @param color metric color of this section
    function initialize(anchorDeg as Number, direction as Graphics.ArcDirection,
                        color as Number) {
        _anchorDeg = anchorDeg;
        _direction = direction;
        _color = color;
    }

    //! Sets the metric color anew. Needed because the section copies its color on
    //! construction - a color scheme change would otherwise bypass the four arcs.
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! @param progress 0.0 to 1.0; larger values count as goal reached
    function draw(dc as Dc, progress as Float) as Void {
        var p = progress;
        if (p < 0.0) { p = 0.0; }
        var reached = (p >= 1.0);
        if (p > 1.0) { p = 1.0; }

        drawTrack(dc);

        // drawArc with identical start and end angle draws a full circle, so
        // below one degree don't fill at all.
        if (Theme.ARC_SWEEP * p >= 1.0) {
            dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(Theme.ARC_WIDTH);
            dc.drawArc(Theme.CENTER_X, Theme.CENTER_Y, Theme.ARC_RADIUS, _direction,
                       _anchorDeg, degreeAt(p));
            cap(dc, _anchorDeg);
            cap(dc, degreeAt(p));
        }

        // Goal reached: the section keeps its metric color - it is the
        // assignment and must not be lost - and gains a white hairline on the
        // outside. The previous version switched to white, which made exactly the
        // reached goal impossible to assign.
        if (reached) {
            dc.setColor(Theme.PRIMARY, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawArc(Theme.CENTER_X, Theme.CENTER_Y, Theme.ARC_DONE_RADIUS, _direction,
                       _anchorDeg, degreeAt(1.0));
        }

        drawTicks(dc);
    }

    //! Draws only the empty track - for states without data.
    function drawTrackOnly(dc as Dc) as Void {
        drawTrack(dc);
        drawTicks(dc);
    }

    //! Full track first, so that the open goal stays visible too.
    private function drawTrack(dc as Dc) as Void {
        dc.setColor(Theme.ARC_EMPTY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(Theme.ARC_WIDTH);
        dc.drawArc(Theme.CENTER_X, Theme.CENTER_Y, Theme.ARC_RADIUS, _direction,
                   _anchorDeg, degreeAt(1.0));
        cap(dc, _anchorDeg);
        cap(dc, degreeAt(1.0));
    }

    //! Round cap on the arc's center line at the given angle. The color is the
    //! one set last - the cap always belongs to the arc that was just drawn.
    private function cap(dc as Dc, deg as Number) as Void {
        var radians = Math.toRadians(deg.toFloat());
        var x = Theme.CENTER_X + Math.cos(radians) * Theme.ARC_RADIUS;
        // Screen y grows downwards, the angle turns upwards.
        var y = Theme.CENTER_Y - Math.sin(radians) * Theme.ARC_RADIUS;
        dc.fillCircle(x.toNumber(), y.toNumber(), Theme.ARC_WIDTH / 2);
    }

    //! Cuts the section into quarters. Drawn in background color across the full
    //! arc width - the mark stays visible whether it currently sits on a filled
    //! or an empty background.
    private function drawTicks(dc as Dc) as Void {
        dc.setColor(Theme.BG, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(Theme.ARC_TICK_WIDTH);

        // One pixel beyond the arc edge on each side, otherwise remnants remain.
        var inner = Theme.ARC_RADIUS - Theme.ARC_WIDTH / 2 - 1;
        var outer = Theme.ARC_RADIUS + Theme.ARC_WIDTH / 2 + 1;

        for (var i = 1; i < Theme.ARC_TICKS; i++) {
            var radians = Math.toRadians(degreeAt(i.toFloat() / Theme.ARC_TICKS).toFloat());
            var ux = Math.cos(radians);
            var uy = -Math.sin(radians);
            dc.drawLine((Theme.CENTER_X + ux * inner).toNumber(),
                        (Theme.CENTER_Y + uy * inner).toNumber(),
                        (Theme.CENTER_X + ux * outer).toNumber(),
                        (Theme.CENTER_Y + uy * outer).toNumber());
        }
    }

    private function degreeAt(p as Float) as Number {
        var sweep = Theme.ARC_SWEEP * p;
        var end = (_direction == Graphics.ARC_COUNTER_CLOCKWISE)
                      ? _anchorDeg + sweep
                      : _anchorDeg - sweep;
        var deg = end.toNumber() % 360;
        if (deg < 0) { deg += 360; }
        return deg;
    }
}
