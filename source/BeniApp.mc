import Toybox.Application;
import Toybox.Application.WatchFaceConfig;
import Toybox.Lang;
import Toybox.WatchUi;

//! Receives changes from the watch's face editor.
//!
//! Without this delegate you could pick a color scheme, but the editor preview
//! would only show the effect after you leave it. The delegate is therefore
//! attached only in edit mode - in normal operation there is nothing to report.
class BeniWatchFaceDelegate extends WatchUi.WatchFaceDelegate {

    private var _view as BeniView;

    function initialize(view as BeniView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    function onWatchFaceConfigEdited(
            options as {:configId as WatchFaceConfig.Id, :type as WatchFaceConfigType?,
                        :committed as Boolean}) as Void {
        _view.applyConfiguration();
        WatchUi.requestUpdate();
    }
}

class BeniApp extends Application.AppBase {

    //! Whether the watch face is currently being edited in the watch's editor.
    private var _editMode as Boolean = false;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        if (state != null) {
            var fromEditor = state[:launchedFromWatchFaceSettingsEditor] as Boolean?;
            if (fromEditor != null && fromEditor) {
                _editMode = true;
            }
        }
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new BeniView();
        if (_editMode) {
            return [ view, new BeniWatchFaceDelegate(view) ];
        }
        return [ view ];
    }
}
