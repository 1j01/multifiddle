# [MultiFiddle](https://multifiddle.ml/#hello-world)
Fiddle with code in a minimalistic collaborative environment.

MultiFiddle is intended as a multilingual**<sup>⁂</sup>** alternative to
editors like [JSFiddle][], [CodePen][], [JS Bin][], and [Fiddle Salad][]
with a simple interface.

##### It currently fails because:

1. **⁂** It is not multilingual;
   in fact it assumes you'll want [CoffeeScript][];
   you can still include `<script>` tags, but
   Fiddle Salad, JS Bin, JSFiddle, and CodePen all have better language support so far
2. There is no versioning/forking system, and your code is NOT SAFE
3. You can't put the code beside the output horizontally

##### Features:

* Live editing like you get with CodePen, JS Bin, or Fiddle Salad
* Dark and delicious
* Nice errors, especially for CoffeeScript compilation where it even links to the position in the source
* Link to the contents of the output pane by adding `/output` to the URL
* Generate a QR code that links to the output with <kbd>Ctrl+M</kbd>
  (it will live-reload even with just the output,
  great if you want to play with [device orientation](https://multifiddle.ml/#device-orientation-II))
* Built with [Ace Editor][] and [Firepad][]

[JSFiddle]: https://jsfiddle.net/
[CodePen]: https://codepen.io/
[JS Bin]: https://jsbin.com/
[Fiddle Salad]: http://fiddlesalad.com/
[CoffeeScript]: https://coffeescript.org/
[Ace Editor]: https://ace.c9.io/
[Firepad]: https://firepad.io/
