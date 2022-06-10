# KDEGrid
A grid-based window size and location controller implemented as a KWin script.

![example](https://user-images.githubusercontent.com/12092720/173101522-6ec9ebf0-ec74-4d1f-8afd-e74b79493b8a.gif)

# Acknowledgments
#### [WindowGrid](http://windowgrid.net)
This project is directly inspired by WindowGrid.

#### [GridWM](https://github.com/criticalsoft/GridWM) & [Kröhnkite](https://github.com/esjeon/krohnkite)
Some scaffolding and API usage and inspiration was influenced by GridWM and Kröhnkite.

# Usage
### Build requirements
* `make`
* `typescript` (will be removed soon)

### Build
`git clone https://github.com/WhoCo/KDEGrid.git`

`cd KDEGrid`

`make`

`plasmapkg2 -i ./dist/kdegrid-<VERSION>-<HASH>.kwinscript`

### Enable
Go to the `System Settings`, select `Window Management`, then `KWin Scripts`. In the list of scripts, check the box next to `KDEGrid`. Click `Apply'.

![SystemSettings-KWinScripts](https://user-images.githubusercontent.com/12092720/173101595-2f64b539-48e4-4ca3-ab58-3d140bcaf764.png)

### Usage
The default key binding/shortcut is `Meta+Ctrl+X`.

Select the window you would like to move/resize. Invoke the shortcut/key binding.
The paint grid will appear on the screen associated with the selected window.
Hold down the left mouse button and drag a box to define the desired window placement
and size. If you would like to select a different starting point during the paint
operation, continue to hold the left mouse button and click the right mouse button.
This will select a new starting location. When the desired paint box has been painted,
release the left mouse button and the active window will be resized and relocated to
fit the painted box.

# TODO
* Find a way to respond to mouse clicks during window move to behave like WindowGrid.
* Find a way to respond to keyboard input during grid paint. Specifically, respond to escape key press to cancel paint.
* Finish configuration UI.
* Logging may be a bit noisy.