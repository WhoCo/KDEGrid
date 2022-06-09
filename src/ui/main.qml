
import QtQuick 2.15;
import QtQuick.Window 2.15;
import QtQuick.Shapes 1.12;
import QtQuick.Layouts 1.15;
import QtQuick.Controls 2.15;
import QtQml 2.15;
import Qt.labs.platform 1.1;


// import org.kde.plasma.core 2.0 as PlasmaCore;
// import org.kde.plasma.components 2.0 as Plasma;
// import org.kde.kwin 2.0;
// import org.kde.taskmanager 0.1 as TaskManager;

// import "../code/main.js" as SCRIPT;

Item {
    id: script

	property var targetDisplay: null;
	property var trackedClient: null;

    SystemTrayIcon {
		visible: false && true;
        icon.name: "KDEGrid"
        icon.source: "res/tray.png"

        menu: Menu {
            visible: false;
        }

        onActivated: {
            Qt.quit();
        }
    }

    Loader {
        id: overlayLoader
        source: "overlay.qml";

        onLoaded: {
			console.debug("kdegrid.QML: [IN] overlayLoader.onLoaded", overlayLoader.item);

			script.applyConfiguration();

			console.debug("kdegrid.QML: [OUT] overlayLoader.onLoaded");
        }
	}

	Connections {
		target: options;

		function onConfigChanged() {
			console.debug("kdegrid.QML: [IN] Connections@options#onConfigChanged()");

			script.applyConfiguration();

			console.debug("kdegrid.QML: [OUT] Connections@options#onConfigChanged()");
		}
	}

	Connections {
        target: overlayLoader.item;

        function onCompleted(r: rect) {
			console.debug("kdegrid.QML: [IN] Connections@overlayLoader.item#onCompleted()", JSON.stringify({"r": r}));

			if (script.trackedClient == null) {
				console.debug("kdegrid.QML: [OUT] Connections@overlayLoader.item#onCompleted()", "trackedClient is null");
				return;
			}

			var display = script.targetDisplay || script.trackedClient.screen;
			var ca = workspace.clientArea(KWin.FullScreenArea, display, script.trackedClient.desktop);

			script.setClientGeometry(script.trackedClient, Qt.rect(ca.x + r.x, ca.y + r.y, r.width, r.height));
			script.trackedClient = null;
			script.targetDisplay = null;
			console.debug("kdegrid.QML: [OUT] Connections@overlayLoader.item#onCompleted()");
		}

        function onCancelled() {
			console.debug("kdegrid.QML: [IN] Connections@overlayLoader.item#onCancelled()");

			script.trackedClient = null;

			console.debug("kdegrid.QML: [OUT] Connections@overlayLoader.item#onCancelled()");
		}
    }

	Connections {
		target: workspace;

		/*
		function onActiveScreenChanged(screen) {
			console.debug("kdegrid.QML: [IN] Connections@workspace.onActiveScreenChanged()", JSON.stringify({"screen": screen}));

			console.debug("kdegrid.QML: [OUT] Connections@workspace.onActiveScreenChanged()");
		}
		*/
	}

    Connections {
        target: workspace.activeClient;

        function onClientStartUserMovedResized(client) {
            console.debug("kdegrid.QML: [IN] activeClient.onClientStartUserMovedResized()", client);

            if (!isValidClient(client)) {
                console.debug("kdegrid.QML: [OUT] activeClient.onClientStartUserMovedResized()#isValidClient", JSON.stringify({"specialWindow": client.specialWindow, "fullScreen": client.fullScreen, "resizeable": client.resizeable, "onAllDesktops": client.onAllDesktops}));
                return;
            }

            if (!client.move || client.resize) {
                console.debug("kdegrid.QML: [OUT] activeClient.onClientStartUserMovedResized()", JSON.stringify({"resize": client.resize, "move": client.move}));
                return;
            }

			// script.trackedClient = client;
          //  var screen = workspace.clientArea(KWin.FullScreenArea, workspace.activeScreen, workspace.currentDesktop);
         //   overlayLoader.item.beginSelect(Qt.rect(screen.x, screen.y, 1000, 1000));

            console.debug("kdegrid.QML: [OUT] activeClient.onClientStartUserMovedResized()");
        }

        function clientStepUserMovedResized(client, r) {
            console.debug("kdegrid.QML: [IN] activeClient.clientStepUserMovedResized()", client, r);

            console.debug("kdegrid.QML: [OUT] activeClient.clientStepUserMovedResized()");
        }

        function clientFinishUserMovedResized(client) {
            console.debug("kdegrid.QML: [IN] activeClient.clientFinishUserMovedResized()", client);

			// script.trackedClient = null;
       //     overlayLoader.item.cancel();

            console.debug("kdegrid.QML: [OUT] activeClient.clientFinishUserMovedResized()");
        }

        function onMoveResizedChanged() {
            var client = workspace.activeClient;

            if (!isValidClient(client)) {
                console.debug("kdegrid.QML: [OUT] activeClient.onMoveResizedChanged()#isValidClient", JSON.stringify({"specialWindow": client.specialWindow, "fullScreen": client.fullScreen, "resizeable": client.resizeable, "onAllDesktops": client.onAllDesktops}));
                return;
            }

            if (!client.move || client.resize) {
             //   overlayLoader.item.cancel();
            //    console.debug("kdegrid.QML: [OUT] activeClient.onClientStartUserMovedResized()", JSON.stringify({"resize": client.resize, "move": client.move}));
                return;
            }
        }
    }

	Component.onCompleted: {
		console.debug("kdegrid.QML: [IN] Component.onCompleted()");

		// overlayLoader.item.beginPaint(Qt.rect(1920, 0, 1000, 1000));

		script.init();

	//	var state = SCRIPT.main(scriptRoot);

		console.debug("kdegrid.QML: [OUT] Component.onCompleted()");
	}

	function init() {
        console.debug("kdegrid.QML: [IN] init()");

        KWin.registerShortcut(
            "KDEGrid: Paint (Focused Window)",
            "KDEGrid: Paint (Focused Window)",
            "Meta+Ctrl+X",
            function () {
                console.debug("kdegrid.QML: [IN] #shortcut/onPaintHandler()");
                var client = workspace.activeClient;

                if (client != null) try {
					script.beginPaint(client);
                } catch (ex) {
                    console.error("kdegrid.QML: [EX] #shortcut/onPaintHandler()", ex);
                } else {
                    console.debug("kdegrid.QML: [ERR] #shortcut/onPaintHandler(): workspace.activeClient is null");
                }

                console.debug("kdegrid.QML: [OUT] #shortcut/onPaintHandler()");
            }
        );

		console.debug("kdegrid.QML: [OUT] init()");
    }

	function applyConfiguration() {
		console.debug("kdegrid.QML: [IN] applyConfiguration()");

		overlayLoader.item.rows = KWin.readConfig("kcfg_layoutDefaultRows", 9);
		overlayLoader.item.columns = KWin.readConfig("kcfg_layoutDefaultColumns", 9);

		overlayLoader.item.gridBackgroundColor = KWin.readConfig("kcfg_themeGridBackgroundColor", "#100000FF");
		overlayLoader.item.gridBorderColor = KWin.readConfig("kcfg_themeGridBorderColor", "#600000FF");
		overlayLoader.item.gridBorderThickness = KWin.readConfig("kcfg_themeGridBorderThickness", 2);

		overlayLoader.item.selectBackgroundColor = KWin.readConfig("kcfg_themeSelectBackgroundColor", "#80A52400");
		overlayLoader.item.selectBorderColor = KWin.readConfig("kcfg_themeSelectBorderColor", "#E0A52400");
		overlayLoader.item.selectBorderThickness = KWin.readConfig("kcfg_themeSelectBorderThickness", 2);

		overlayLoader.item.paintBackgroundColor = KWin.readConfig("kcfg_themePaintBackgroundColor", "#20A54200");
		overlayLoader.item.paintBorderColor = KWin.readConfig("kcfg_themePaintBorderColor", "#E0A54200");
		overlayLoader.item.paintBorderThickness = KWin.readConfig("kcfg_themePaintBorderThickness", 4);

		console.debug("kdegrid.QML: [OUT] applyConfiguration()");
	}

	function beginPaint(client) {
		console.debug("kdegrid.QML: [IN] beginPaint()", client);

        if (client == null)
			return false;

        if (!isValidClient(client)) {
			console.debug("kdegrid.QML: [OUT] beginPaint()#isValidClient", JSON.stringify({"specialWindow": client.specialWindow, "fullScreen": client.fullScreen, "resizeable": client.resizeable, "onAllDesktops": client.onAllDesktops}));
            notifyInvalidClient(client);
			return false;
        }

        /*
        if (!client.move || client.resize) {
			console.debug("kdegrid.QML: [OUT] beginPaint()", JSON.stringify({"resize": client.resize, "move": client.move}));
            notifyInvalidClient(client);
			return false;
        }
        */

		script.trackedClient = client;
		script.targetDisplay = client.screen;
    //    var screen = workspace.clientArea(KWin.FullScreenArea, workspace.activeScreen, workspace.currentDesktop);
        var screen = workspace.clientArea(KWin.FullScreenArea, client.screen, client.desktop);
        overlayLoader.item.beginPaint(Qt.rect(screen.x, screen.y, screen.width, screen.height));

		console.debug("kdegrid.QML: [OUT] beginPaint()");
		return true;
    }

    function isValidClient(client) {
        if (client.specialWindow || client.fullScreen || !client.resizeable || client.onAllDesktops)
            return false;

        return true;
    }

    function notifyInvalidClient(client) {

    }

	function setClientGeometry(client, r) {
		client.setMaximize(false,false);
		client.frameGeometry = r;
	}
}
