// Generated by CoffeeScript 1.6.3
var $G, $body, $code, E, EditorPane, G, Pane, PanesPane, PreviewPane, code, code_previous, coffee_body, fb_project, fb_root, hash, hell, resizer_width,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

resizer_width = 10;

code = {};

$code = $(code);

code_previous = {};

coffee_body = "";

$G = $(G = window);

$body = $();

E = function(tagname) {
  return document.createElement(tagname);
};

hell = function(boo) {
  return boo;
};

Pane = (function() {
  function Pane() {
    this.$ = $(E('div'));
    this.$.addClass("pane");
    this.flex = 1;
  }

  Pane.prototype.layout = function() {};

  return Pane;

})();

PanesPane = (function(_super) {
  __extends(PanesPane, _super);

  function PanesPane(_arg) {
    var orientation;
    orientation = _arg.orientation;
    PanesPane.__super__.constructor.call(this);
    this.$.addClass("panes-pane");
    this.orientation = orientation || "y";
    this.children = [];
    this.$resizers = $();
  }

  PanesPane.prototype.orient = function(orientation) {
    this.orientation = orientation;
    return this.layout();
  };

  PanesPane.prototype.layout = function() {
    var $resizer, after, before, child_pane, display, i, mouse_pos_prop, n_children, n_resizers, offset_prop_start, parent_pane, pd1, pd2, resize_cursor, _d1, _d2, _i, _j, _len, _ref, _ref1, _results;
    display = {
      x: "inline-block",
      y: "block"
    }[this.orientation];
    _d1 = {
      x: "width",
      y: "height"
    }[this.orientation];
    _d2 = {
      x: "height",
      y: "width"
    }[this.orientation];
    pd1 = this.$[_d1]();
    pd2 = this.$[_d2]();
    n_children = this.children.length;
    n_resizers = Math.max(0, n_children - 1);
    parent_pane = this;
    _ref = this.children;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      child_pane = _ref[_i];
      child_pane.size = child_pane.flex * ((pd1 / n_children) - (resizer_width * n_resizers));
      child_pane.$.css(_d1, child_pane.size);
      child_pane.$.css(_d2, pd2);
      child_pane.$.css({
        display: display
      });
      child_pane.layout();
    }
    resize_cursor = {
      x: "col-resize",
      y: "row-resize"
    }[this.orientation];
    mouse_pos_prop = {
      x: "clientX",
      y: "clientY"
    }[this.orientation];
    offset_prop_start = {
      x: "left",
      y: "top"
    }[this.orientation];
    this.$resizers.remove();
    this.$resizers = $();
    _results = [];
    for (i = _j = 1, _ref1 = this.children.length - 1; 1 <= _ref1 ? _j <= _ref1 : _j >= _ref1; i = 1 <= _ref1 ? ++_j : --_j) {
      before = this.children[i - 1];
      after = this.children[i];
      $resizer = $(E("div")).addClass("resizer " + resize_cursor + "r");
      $resizer.insertAfter(before.$);
      $resizer.css(_d1, resizer_width);
      $resizer.css(_d2, pd2);
      $resizer.css({
        display: display
      });
      $resizer.css({
        cursor: resize_cursor
      });
      $resizer.on("mousedown", function(e) {
        var mousemove;
        e.preventDefault();
        $body.addClass("dragging");
        mousemove = function(e) {
          var mouse_pos, pane, total_flex, total_size, _k, _l, _len1, _len2, _ref2, _ref3, _results1;
          mouse_pos = e[mouse_pos_prop];
          before.size = mouse_pos - parent_pane.$.offset()[offset_prop_start] - resizer_width / 2;
          after.size = parent_pane.$[_d1]() - mouse_pos - resizer_width / 2;
          before.$.css(_d1, before.size);
          after.$.css(_d1, after.size);
          before.layout();
          after.layout();
          total_size = pd1 - (resizer_width * n_resizers);
          before.flex = before.size / total_size;
          after.flex = after.size / total_size;
          total_flex = 0;
          _ref2 = parent_pane.children;
          for (_k = 0, _len1 = _ref2.length; _k < _len1; _k++) {
            pane = _ref2[_k];
            total_flex += pane.flex;
          }
          _ref3 = parent_pane.children;
          _results1 = [];
          for (_l = 0, _len2 = _ref3.length; _l < _len2; _l++) {
            pane = _ref3[_l];
            pane.flex /= total_flex;
            _results1.push(pane.flex *= parent_pane.children.length);
          }
          return _results1;
        };
        $G.on("mousemove", mousemove);
        return $G.on("mouseup", function() {
          $G.off("mousemove", mousemove);
          return $body.removeClass("dragging");
        });
      });
      _results.push(this.$resizers = this.$resizers.add($resizer));
    }
    return _results;
  };

  PanesPane.prototype.add = function(pane) {
    this.$.append(pane.$);
    return this.children.push(pane);
  };

  return PanesPane;

})(Pane);

PreviewPane = (function(_super) {
  __extends(PreviewPane, _super);

  function PreviewPane() {
    var $iframe, $pane, iframe;
    PreviewPane.__super__.constructor.call(this);
    this.$.addClass("preview-pane");
    $pane = this.$;
    $iframe = $(iframe = E('iframe')).attr({
      sandbox: "allow-same-origin allow-scripts allow-forms"
    });
    $iframe.appendTo($pane);
    $code.on("change", function() {
      var body, c, data_uri, e, error_handling, head, html, js, _i, _len, _results;
      $pane.loading();
      head = body = "";
      error_handling = function() {
        var d;
        d = document.createElement("div");
        d.className = "error bubble script-error";
        return window.onerror = function(error) {
          document.body.appendChild(d);
          d.style.position = "absolute";
          d.style.borderRadius = d.style.padding = d.style.bottom = d.style.right = "5px";
          return d.innerText = d.textContent = error;
        };
      };
      body += "<script>~" + error_handling + "()</script>\n<style>\n	.error {\n		color: red;\n	}\n	.error.bubble {\n		background: rgba(255, 0, 0, 0.8);\n		color: white;\n	}\n	body {\n		font-family: Helvetica, sans-serif;\n	}\n</style>";
      if (code.html) {
        body += code.html;
      }
      if (code.css) {
        head += "<style>" + code.css + "</style>";
      }
      if (code.javascript) {
        body += "<script>" + code.javascript + "</script>";
      }
      if (code.coffee) {
        if (code.coffee !== code_previous.coffee) {
          coffee_body = (function() {
            try {
              js = CoffeeScript.compile(code.coffee);
              return "<script>" + js + "</script>";
            } catch (_error) {
              e = _error;
              return "<h4 class='error'>CoffeeScript Compilation Error</h4>\n<p>" + e.message + "</p>";
            }
          })();
        }
        body += coffee_body;
      }
      html = "<!doctype html>\n<html>\n	<head>\n		<meta charset=\"utf-8\">\n		" + head + "\n	</head>\n	<body style='background:black;color:white;'>\n		" + body + "\n	</body>\n</html>";
      $iframe.one("load", function() {
        return $pane.loading("done");
      });
      if (typeof $iframe[0].srcdoc === "string") {
        $iframe.attr({
          srcdoc: html
        });
      } else {
        data_uri = "data:text/html," + encodeURI(html);
        if (iframe.contentWindow) {
          iframe.contentWindow.location.replace(data_uri);
        } else {
          $iframe.attr({
            src: data_uri
          });
        }
      }
      _results = [];
      for (_i = 0, _len = code.length; _i < _len; _i++) {
        c = code[_i];
        _results.push(code_previous = c);
      }
      return _results;
    });
  }

  return PreviewPane;

})(Pane);

EditorPane = (function(_super) {
  __extends(EditorPane, _super);

  EditorPane.s = [];

  function EditorPane(_arg) {
    var $pad, $pane, editor, fb_fp, firepad, lang, session;
    lang = _arg.lang;
    EditorPane.s.push(this);
    EditorPane.__super__.constructor.call(this);
    this.$.addClass("editor-pane");
    $pane = this.$;
    $pad = $(E('div'));
    $pad.appendTo($pane);
    $pane.loading();
    fb_fp = fb_project.child(lang);
    editor = this.editor = ace.edit($pad[0]);
    editor.on('change', function() {
      code[lang] = editor.getValue();
      return $code.triggerHandler("change");
    });
    session = editor.getSession();
    editor.setShowPrintMargin(false);
    editor.setReadOnly(true);
    editor.setSelectionStyle("text");
    session.setUseWrapMode(false);
    session.setUseWorker(lang !== "html");
    session.setUseSoftTabs(hell(false));
    session.setMode("ace/mode/" + lang);
    firepad = Firepad.fromACE(fb_fp, editor);
    firepad.on('ready', function() {
      var _ref;
      $pane.loading("done");
      editor.setReadOnly(false);
      if (firepad.isHistoryEmpty()) {
        return firepad.setText((_ref = {
          javascript: '// JavaScript\n\ndocument.write("Hello World!");\n',
          coffee: '\nspans = \n	for char in "Hello World from CoffeeScript!"\n		span = document.createElement("span")\n		document.body.appendChild(span)\n		span.innerHTML = char\n		(span)\n\nt = 0\nrainbow = ->\n	t += 0.05\n	for span, i in spans\n		span.style.color = "hsl(#{\n			Math.sin(t - i / 23) * 360\n		},100%,80%)"\n\nsetInterval rainbow, 30\n',
          css: 'body {\n	font-family: Helvetica, sans-serif;\n}'
        }[lang]) != null ? _ref : "");
      }
    });
  }

  EditorPane.prototype.layout = function() {
    return this.editor.resize();
  };

  return EditorPane;

})(Pane);

fb_root = new Firebase("https://multifiddle.firebaseio.com/");

fb_project = null;

hash = G.location.hash.replace('#', '');

if (hash) {
  fb_project = fb_root.child(hash);
} else {
  fb_project = fb_root.push();
  G.location = G.location + '#' + fb_project.name();
}

$(function() {
  var bottom_pane, main_pane, relayout, setTheme, themes, themesByName, top_pane, _ref;
  $body = $(document.body);
  main_pane = new PanesPane({
    orientation: "y"
  });
  main_pane.add(top_pane = new PanesPane({
    orientation: "x"
  }));
  main_pane.add(bottom_pane = new PanesPane({
    orientation: "x"
  }));
  top_pane.add(new EditorPane({
    lang: "coffee"
  }));
  top_pane.add(new EditorPane({
    lang: "css"
  }));
  bottom_pane.add(new EditorPane({
    lang: "html"
  }));
  bottom_pane.add(new PreviewPane);
  $body.append(main_pane.$);
  relayout = function() {
    return main_pane.layout();
  };
  $G.on("resize", relayout);
  relayout();
  _ref = ace.require("ace/ext/themelist"), themes = _ref.themes, themesByName = _ref.themesByName;
  setTheme = function(theme_name) {
    var edpane, theme, _i, _len, _ref1, _results;
    theme = themesByName[theme_name];
    if (theme.isDark) {
      $body.addClass("dark");
    } else {
      $body.removeClass("dark");
    }
    _ref1 = EditorPane.s;
    _results = [];
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      edpane = _ref1[_i];
      _results.push(edpane.editor.setTheme(theme.theme));
    }
    return _results;
  };
  setTheme("tomorrow_night_bright");
  return console.log(themes);
});
