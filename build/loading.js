// Generated by CoffeeScript 2.3.0
(function() {
  (function($) {
    return $.fn.loading = function(done) {
      var PI, TAU, c, cos, d, draw, max, max_size, min, min_size, s, sin;
      min_size = 32;
      max_size = 100;
      s = max_size; // size
      c = s * 0.5; // center
      ({sin, cos, min, max, PI} = Math);
      TAU = PI * 2; // C/r
      draw = function(ctx, t) {
        var i, j, n, ref, results;
        ctx.globalAlpha = 0.05;
        ctx.clearRect(0, 0, s, s);
        ctx.globalAlpha = 1;
        ctx.fillStyle = '#FFF';
        ctx.strokeStyle = '#000';
        ctx.shadowColor = '#999';
        ctx.shadowBlur = 20;
        n = 10;
        results = [];
        for (i = j = 0, ref = n; (0 <= ref ? j <= ref : j >= ref); i = 0 <= ref ? ++j : --j) {
          ctx.beginPath();
          ctx.arc(c + sin(t * 0.05 + i) * c * 0.8, c + cos(t * 0.05 + i) * c * 0.8, c * 0.05 * (1 + cos(t * 0.2 + i * 0.2)), 0, TAU);
          ctx.fill();
          results.push(ctx.stroke());
        }
        return results;
      };
      d = "loading-indicator"; // name to store linked element ("data") under
      return this.each(function() {
        var $canvas, $indicator, $parent, canvas, ctx, indicator, parent, start, t, update;
        parent = this;
        $parent = $(parent);
        $indicator = $parent.data(d);
        t = Math.random() * 100;
        if (done) {
          if ($indicator) {
            return $indicator.fadeOut(500, function() {
              $indicator.remove();
              return $parent.data(d, null);
            });
          }
        } else {
          if ($indicator) {
            return $indicator.stop().fadeIn(200);
          } else {
            canvas = document.createElement("canvas");
            $canvas = $(canvas);
            ctx = canvas.getContext("2d");
            $indicator = $canvas;
            indicator = $indicator[0];
            indicator.width = indicator.height = s;
            $indicator.appendTo("body");
            update = function() {
              var rect;
              rect = parent.getBoundingClientRect();
              s = max(min_size, 5, min(max_size, min(rect.width, rect.height)));
              c = s * 0.5;
              indicator.style.left = rect.left + (rect.width - s) * 0.5 + "px";
              indicator.style.top = rect.top + (rect.height - s) * 0.5 + "px";
              if (indicator.width !== s) {
                indicator.width = s;
              }
              if (indicator.height !== s) {
                indicator.height = s;
              }
              if (ctx) {
                draw(ctx, t += 0.3);
              }
              
              // if document contains indicator
              if ($.contains(document, indicator)) {
                return setTimeout(update, 15);
              }
            };
            start = function() {
              indicator.style.display = "block";
              indicator.style.position = "absolute";
              indicator.style.pointerEvents = "none";
              indicator.style.zIndex = "2";
              return update();
            };
            indicator.style.display = "none";
            setTimeout(start, 15);
            return $parent.data(d, $indicator);
          }
        }
      });
    };
  })(jQuery);

}).call(this);
