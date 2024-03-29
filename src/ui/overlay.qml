
import QtQuick 2.15;
import QtQuick.Window 2.15;
import QtQuick.Shapes 1.12;
import QtQuick.Layouts 1.15;
import QtQuick.Controls 2.15;
import QtQml 2.15;

/// <todo author="Nx">
/// Wrap the Window (overlay) in an Item (id: manager) to compartmentalize the state and separate it from the UI.
/// </todo>
Window {
	id: overlay;

	flags: Qt.Tool | Qt.CustomizeWindowHint | Qt.BypassGraphicsProxyWidget |
				Qt.FramelessWindowHint |
		   // Qt.WindowDoesNotAcceptFocus | Qt.WindowTransparentForInput
		   // Qt.WA_TranslucentBackground |
		   Qt.WindowStaysOnTopHint |
		   (visible ? (Qt.BypassWindowManagerHint | Qt.X11BypassWindowManagerHint) : 0);

	visible: false;
	width: 240;
	height: 240;

	color: "transparent";

	property int rows: 6;
	property int columns: 8;

	property color gridBackgroundColor: "#100000FF";
	property color gridBorderColor: "#600000FF";
	property int gridBorderThickness: 2;

	property color selectBackgroundColor: "#80A52400";
	property color selectBorderColor: "#E0A52400";
	property int selectBorderThickness: 2;

	property color paintBackgroundColor: "#20A54200";
	property color paintBorderColor: "#E0A54200";
	property int paintBorderThickness: 4;

	Item {
		id: manager;

		/// <todo author="Nx">
		/// I would like to see predefined "panels" implemented that a window can be dragged to. I am calling this "select" mode. The current
		/// difficulty is mouse tracking and window activation (overlay).
		/// </todo>
		state: "manage";

		states: [
			State {
				name: "managing";
				PropertyChanges {
					target: manager;

					startPoint: null;
				}
			},
			State {
				name: "selecting";
				PropertyChanges {
					target: manager;

					startPoint: null;
				}
			},
			State {
				name: "painting";
				PropertyChanges {
					target: manager;

					startPoint: null;
				}
			}
		]

        /// <remarks author="Nx">
        /// Cannot assign null to point. Use var instead.
        // </remarks> 
		property /* point */ var startPoint: null;
	}

	MouseArea {
		id: mouseArea;

		enabled: false;

		anchors.fill: parent;
		focus: true;
		z: 1001;

		acceptedButtons: Qt.LeftButton | Qt.RightButton;

		onPressed: {
			console.debug(`kdegrid.overlay: [IN] mouseArea.onPressed()`, JSON.stringify(mouse));
			if (mouse.button !== Qt.LeftButton)
				return;

			if (isOutsidePaintGrid(mouse.x, mouse.y)) {
				console.debug("kdegrid.overlay: [OUT] mouseArea.onPressed()", "isOutsidePaintGrid(x, y) == true");
				return;
			}

			var p = Qt.point(mouse.x, mouse.y);

			manager.startPoint = p;
			var r = adjustPointsForPaintBox(mouse.x, mouse.y, mouse.x, mouse.y);
			paintGrid.updatePaintBox(r);
			console.debug("kdegrid.overlay: [OUT] mouseArea.onPressed()");
		}

		onPositionChanged: {
			console.debug("kdegrid.overlay: [IN] mouseArea.onPositionChanged()", JSON.stringify(mouse));
			if (manager.startPoint == null /* || mouse.button !== Qt.LeftButton */) {
				console.debug("kdegrid.overlay: [OUT] mouseArea.onPositionChanged() EARLY");
				return;
			}

			if (isOutsidePaintGrid(mouse.x, mouse.y)) {
				console.debug("kdegrid.overlay: [OUT] mouseArea.onPositionChanged()", "isOutsidePaintGrid(x, y) == true");
				return;
			}

			var r = adjustPointsForPaintBox(manager.startPoint.x, manager.startPoint.y, mouse.x, mouse.y);
			paintGrid.updatePaintBox(r);
			console.debug("kdegrid.overlay: [OUT] mouseArea.onPositionChanged()");
		}

		onClicked: {
			console.debug("kdegrid.overlay: [IN] mouseArea.onClicked()", JSON.stringify(mouse));
			if (mouse.button !== Qt.RightButton)
				return;

			if (isOutsidePaintGrid(mouse.x, mouse.y)) {
				console.debug("kdegrid.overlay: [OUT] mouseArea.onClicked()", "isOutsidePaintGrid(x, y) == true");
				return;
			}

			var p = Qt.point(mouse.x, mouse.y);
			manager.startPoint = p;
			var r = adjustPointsForPaintBox(mouse.x, mouse.y, mouse.x, mouse.y);
			paintGrid.updatePaintBox(r);
			console.debug("kdegrid.overlay: [OUT] mouseArea.onClicked()");
		}

		onReleased: {
			console.debug("kdegrid.overlay: [IN] mouseArea.onReleased()", JSON.stringify(mouse));
			if (manager.startPoint == null || mouse.button !== Qt.LeftButton)
				return;

			if (isOutsidePaintGrid(mouse.x, mouse.y)) {
				console.debug("kdegrid.overlay: [DATA] mouseArea.onReleased()", "isOutsidePaintGrid(x, y) == true", "Clipping to grid.");
				mouse = clipToPaintGrid(mouse.x, mouse.y);
			}

			var r = adjustPointsForPaintBox(manager.startPoint.x, manager.startPoint.y, mouse.x, mouse.y);
			paintGrid.updatePaintBox(r);
			overlay.complete(finalizeRectForPlacement(r));
			endPaint();
			console.debug("kdegrid.overlay: [OUT] mouseArea.onReleased()");
		}

		function isOutsidePaintGrid(x, y) {
			console.debug("kdegrid.overlay: [IN] mouseArea.isOutsidePaintGrid()", JSON.stringify(
				{
					"paintGrid": {
						"x": paintGrid.x,
						"y": paintGrid.y,
						"width": paintGrid.width,
						"height": paintGrid.height,
					//	"(right)": paintGrid.right,
					//	"(bottom)": paintGrid.bottom,
					//	"(right)": paintGrid.width + paintGrid.x,
					//	"(bottom)": paintGrid.height + paintGrid.y,
					}
				})
			);

			return x > (paintGrid.width + paintGrid.x) || x < paintGrid.x ||
					y > (paintGrid.height + paintGrid.y) || y < paintGrid.y;
		}

		function clipToPaintGrid(x, y) {
			if (x < paintGrid.x)
				x = paintGrid.x;

			if (y < paintGrid.y)
				y = paintGrid.y;

			var r = paintGrid.width + paintGrid.x;
			if (x > r)
				x = r;

			var b = paintGrid.height + paintGrid.y;
			if (y > b)
				y = b;

			return Qt.point(x, y);
		}

		function adjustPointsForPaintBox(x0, y0, x1, y1) {
			if (x1 < x0) {
				var x = x0;
				x0 = x1;
				x1 = x;
			}

			if (y1 < y0) {
				var y = y0;
				y0 = y1;
				y1 = y;
			}

			/*
			if (x0 < 0) {
				x1 += -x0;
				x0 = 0;
			}

			if (x1 < 0) {
				x0 += -x1;
				x1 = 0;
			}

			if (y0 < 0) {
				y1 += -y0;
				y0 = 0;
			}

			if (y1 < 0) {
				y0 += -y1;
				y1 = 0;
			}
			*/

			var vy = paintGrid.height / paintGrid.rows;
			var vx = paintGrid.width / paintGrid.columns;

			x0 = Math.floor(x0 / vx);
			y0 = Math.floor(y0 / vy);
			x1 = clamp(Math.ceil(x1 / vx), 1, paintGrid.columns);
			y1 = clamp(Math.ceil(y1 / vy), 1, paintGrid.rows);

			//res.height = Math.min(Math.max(res.height, 0), paintGrid.height - res.top);
			//res.width = Math.min(Math.max(res.width, 0), paintGrid.width - res.left);
			return Qt.rect(x0, y0, x1 - x0, y1 - y0);
		}

		function clamp(n, min, max) {
			return Math.min(Math.max(n, min), max);
		}

		function finalizeRectForPlacement(r) {
			var vy = paintGrid.height / paintGrid.rows;
			var vx = paintGrid.width / paintGrid.columns;

			return Qt.rect(r.x * vx, r.y * vy, r.width * vx, r.height * vy);
		}

		function endPaint() {
			paintBox.visible = false;
		}
	}

    /* GridLayout */ Item {
		id: paintGrid;

		anchors.fill: parent;
		z: 1000;

        property int rows: overlay.rows || 1;
        property int columns: overlay.columns || 1;

        property int _ROW_HEIGHT: Math.floor(paintGrid.height / paintGrid.rows);
        property int _COLUMN_WIDTH: Math.floor(paintGrid.width / paintGrid.columns);

        // columnSpacing: 0;
        // rowSpacing: 0;

		/// Are these broken. Their base definitions are FINAL and cannot be overridden but they always evaluate to
		/// an empty value ("")?
		// property int right: x + width;
		// property int bottom: y + height;

		Rectangle {
            id: paintBox;

			visible: false;

        //	z: 1000;
			color: overlay.paintBackgroundColor;
			border.color: overlay.paintBorderColor;
			border.width: overlay.paintBorderThickness;

            x: paintBox.Layout.column * paintGrid._COLUMN_WIDTH;
            y: paintBox.Layout.row * paintGrid._ROW_HEIGHT;

            width: paintBox.Layout.columnSpan * paintGrid._COLUMN_WIDTH;
            height: paintBox.Layout.rowSpan * paintGrid._ROW_HEIGHT;

        //    Layout.fillWidth: true;
        //    Layout.fillHeight: true;
            Layout.row: 0;
            Layout.column: 0;
            Layout.rowSpan: 1;
            Layout.columnSpan: 1;
		}

		/// <remarks author="Nx">
		/// Originally, this would add/remove elements (Rectangle) in response to changes in the paintBox properties. This produced
		/// inconsistent results. Now, cells are generated to fill the grid, then shown when they are not occluded by the paintBox.
		/// </remarks>
		Repeater {
			id: paintGridRepeater;
			model: (paintGrid.rows * paintGrid.columns) /* - (paintBox.Layout.rowSpan * paintBox.Layout.columnSpan) */ || 0;

			Rectangle {
				property Item _instance: paintGridRepeater.itemAt(index);

				color: overlay.gridBackgroundColor;
				visible: !paintBox.visible ||
						 !(_instance.Layout.column >= paintBox.Layout.column &&
						   (_instance.Layout.column <= (paintBox.Layout.column + paintBox.Layout.columnSpan - 1)) &&
						   _instance.Layout.row >= paintBox.Layout.row &&
						   (_instance.Layout.row <= (paintBox.Layout.row + paintBox.Layout.rowSpan - 1)));
				enabled: visible;

                x: (index % paintGrid.columns) * paintGrid._COLUMN_WIDTH;
                y: Math.floor(index / paintGrid.columns) * paintGrid._ROW_HEIGHT;

                width: paintGrid._COLUMN_WIDTH;
                height: paintGrid._ROW_HEIGHT;

            //	z: -1000;

            //	Layout.fillWidth: true;
            //	Layout.fillHeight: true;
                Layout.row: Math.floor(index / paintGrid.columns);
                Layout.column: index % paintGrid.columns;
                Layout.rowSpan: 1;
                Layout.columnSpan: 1;

				border.width: overlay.gridBorderThickness;
				border.color: overlay.gridBorderColor;
			}

			/// <todo author="Nx">
			/// Remove this. It is not used.
			/// </todo>
			function isCollisionPosition(index) {
				console.debug("kdegrid.overlay: [IN] isCollisionPosition()", JSON.stringify({"index": index}));

				if (!paintBox.visible)
					return false;

				var p = Qt.point(index % paintGrid.columns, Math.floor(index / paintGrid.columns));
				var res = p.x >= paintBox.Layout.column && (p.x <= (paintBox.Layout.column + paintBox.Layout.columnSpan - 1)) &&
					p.y >= paintBox.Layout.row && (p.y <= (paintBox.Layout.row + paintBox.Layout.rowSpan - 1));

				console.debug("kdegrid.overlay: [OUT] isCollisionPosition()", JSON.stringify({"index": index, "p": p, "res": res}));
				return res;
			}
		}

		function updatePaintBox(r) {
			console.debug("kdegrid.overlay: [IN] paintGrid.updatePaintBox()", JSON.stringify({ "r": r }));

			//var vy = paintGrid.height / paintGrid.rows;
			//var vx = paintGrid.width / paintGrid.columns;

			//console.debug("kdegrid.overlay: [DATA] paintGrid.updatePaintBox()", JSON.stringify({ "vy": vy, "vx": vx }));

			//paintBox.Layout.row = Math.floor(r.top / vy);
			//paintBox.Layout.column = Math.floor(r.left / vx);
			//paintBox.Layout.rowSpan = clamp(Math.floor(r.height / vy) + 1, 1, paintGrid.rows - paintBox.Layout.row);
			//paintBox.Layout.columnSpan = clamp(Math.floor(r.width / vx) + 1, 1, paintGrid.columns - paintBox.Layout.column);
			//paintBox.Layout.rowSpan = Math.min(paintGrid.rows - paintBox.Layout.row, Math.floor(r.height / vy) + 1);
			//paintBox.Layout.columnSpan = Math.min(paintGrid.columns - paintBox.Layout.column, Math.floor(r.width / vx) + 1);

			paintBox.Layout.row = r.top;
			paintBox.Layout.column = r.left;
			paintBox.Layout.rowSpan = r.height;
			paintBox.Layout.columnSpan = r.width;

			console.debug("kdegrid.overlay: [DATA] paintGrid.updatePaintBox()", JSON.stringify({
				"Layout.row": paintBox.Layout.row,
				"Layout.column": paintBox.Layout.column,
				"Layout.rowSpan": paintBox.Layout.rowSpan,
				"Layout.columnSpan": paintBox.Layout.columnSpan,
			}));

			paintBox.visible = true;
			console.debug("kdegrid.overlay: [OUT] paintGrid.updatePaintBox()");
		}
	}

	onActiveChanged: {
		console.debug("kdegrid.overlay: [IN] onActiveChanged()", JSON.stringify({"active": active}));

		if (!active)
			cancel();

		console.debug("kdegrid.overlay: [OUT] onActiveChanged()");
	}

	signal managing(r: rect);

	function beginManage(r) {
		console.debug("kdegrid.overlay: [IN] beginManage()", JSON.stringify(r));

		overlay.x = r.x;
		overlay.y = r.y;
		// overlay.opacity = 0.2;
		overlay.width = r.width;
		overlay.height = r.height;
	 //   content.width = r.width;
	 //   content.height = r.height;

		overlay.__show();
		overlay.managing(r);
		console.debug("kdegrid.overlay: [OUT] beginManage()");
	}

	signal selecting(r: rect);

	function beginSelect(r) {
		console.debug("kdegrid.overlay: [IN] beginSelect()", JSON.stringify(r));

		overlay.x = r.x;
		overlay.y = r.y;
		overlay.width = r.width;
		overlay.height = r.height;

		// manager.state = "selecting";

		overlay.__show();
		overlay.selecting(r);
		console.debug("kdegrid.overlay: [OUT] beginSelect()");
	}

	signal painting(r: rect);

	function beginPaint(r) {
		console.debug("kdegrid.overlay: [IN] beginPaint()", JSON.stringify(r));

		overlay.x = r.x;
		overlay.y = r.y;
		overlay.width = r.width;
		overlay.height = r.height;

		// manager.state = "painting";

		overlay.__show();
		overlay.painting(r);
		console.debug("kdegrid.overlay: [OUT] beginPaint()");
	}

	function __show() {
		// overlay.active = true;
	//    overlay.window.requestActivate();
		mouseArea.enabled = true;
		overlay.visibility = 2; // QWindow::Windowed
	}

	signal cancelled();

	function cancel() {
		console.debug("kdegrid.overlay: [IN] cancel()");

		// manager.state = "";

		mouseArea.enabled = false;
		overlay.visibility = 0; // QWindow::Hidden
		overlay.cancelled();
	}

	signal completed(r: rect);

	function complete(r) {
		console.debug("kdegrid.overlay: [IN] complete()");

		// manager.state = "";

		mouseArea.enabled = false;
		overlay.visibility = 0; // QWindow::Hidden
		overlay.completed(r);
		console.debug("kdegrid.overlay: [OUT] complete()", JSON.stringify(r));
	}
}
