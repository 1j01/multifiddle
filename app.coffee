
resizer_width = 10

code = {}
$code = $(code)
code_previous = {}
coffee_body = ""

$G = $(G = window)

E = (tagname)-> document.createElement tagname

hell = (boo)-> boo#yah

class Pane
	constructor: ->
		@$ = $(E 'div')
		@$.addClass "pane"
		@flex = 1
	
	layout: ->

class PanesPane extends Pane
	constructor: ({orientation})->
		super()
		@$.addClass "panes-pane"
		
		@orientation = orientation or "y"
		@children = []
		@$resizers = $()
		
	orient: (orientation)->
		@orientation = orientation
		@layout()
	
	layout: ->
		
		# css property `display` for orientation
		display = (x:"inline-block", y:"block")[@orientation]
		
		# primary dimension which is divided between the children
		_d1 = (x:"width", y:"height")[@orientation]
		
		# secondary dimension which is the same for the parent and all children
		_d2 = (x:"height", y:"width")[@orientation]
		
		
		# get the dimensions of the parent
		pd1 = @$[_d1]()
		pd2 = @$[_d2]()
		
		n_children = @children.length
		n_resizers = Math.max(0, n_children - 1)
		
		parent_pane = @
		space_to_distribute_in_d1 = pd1 - resizer_width * n_resizers
		for child_pane in @children
			child_pane_size = child_pane.flex / n_children * space_to_distribute_in_d1
			child_pane.$.css _d1, child_pane_size
			child_pane.$.css _d2, pd2
			child_pane.$.css {display}
			child_pane.layout()
		
		resize_cursor = (x:"col-resize", y:"row-resize")[@orientation]
		
		mouse_pos_prop = (x:"clientX", y:"clientY")[@orientation]
		
		offset_prop_start = (x:"left", y:"top")[@orientation]
		offset_prop_end = (x:"right", y:"bottom")[@orientation]
		
		
		@$resizers.remove()
		@$resizers = $()
		
		for i in [1..parent_pane.children.length-1]
			before = parent_pane.children[i - 1]
			after = parent_pane.children[i]
			((before, after)->
				$resizer = $(E "div").addClass("resizer #{resize_cursor}r")
				$resizer.insertAfter(before.$)
				$resizer.css _d1, resizer_width
				$resizer.css _d2, pd2
				$resizer.css {display}
				$resizer.css cursor: resize_cursor
				
				$resizer.on "mousedown", (e)->
					e.preventDefault()
					$("body").addClass "dragging"
					
					mousemove = (e)->
						before_start = before.$[0].getBoundingClientRect()[offset_prop_start]
						after_end = after.$[0].getBoundingClientRect()[offset_prop_end]
						
						b = resizer_width / 2 + 1
						mouse_pos = Math.max(before_start+b, Math.min(after_end-b, e[mouse_pos_prop]))
						
						before.$.css _d1, mouse_pos - before_start - resizer_width / 2
						after.$.css _d1, after_end - mouse_pos - resizer_width / 2
						
						before.layout()
						after.layout()
						
						# calculate flex values
						total_size = (pd1) - (resizer_width * n_resizers)
						for pane in parent_pane.children
							pane.flex = pane.$[_d1]() / total_size * n_children
					
					$G.on "mousemove", mousemove
					$G.on "mouseup", ->
						$G.off "mousemove", mousemove
						$("body").removeClass "dragging"
				
				parent_pane.$resizers = parent_pane.$resizers.add $resizer
			
			)(before, after)
		
	
	add: (pane)->
		@$.append pane.$
		@children.push pane

class PreviewPane extends Pane
	constructor: ->
		super()
		@$.addClass "preview-pane"
		$pane = @$
		
		$iframe = $(iframe = E 'iframe').attr(sandbox:"allow-same-origin allow-scripts allow-forms")
		$iframe.appendTo $pane
		$code.on "change", (e, lang)->
			$pane.loading()
			
			head = body = ""
			
			error_handling = ->
				d = document.createElement "div"
				d.className = "error bubble script-error"
				window.onerror = (error)->
					document.body.appendChild d
					d.style.position = "absolute"
					d.style.borderRadius = d.style.padding = 
					d.style.bottom = d.style.right = "5px"
					d.innerText = d.textContent = error
			
			body += """
				<script>~#{error_handling}()</script>
				<style>
					.error {
						color: red;
					}
					.error.bubble {
						background: rgba(255, 0, 0, 0.8);
						color: white;
					}
					body {
						font-family: Helvetica, sans-serif;
					}
				</style>
			"""
			
			if code.html
				body += code.html
			if code.css
				head += "<style>#{code.css}</style>"
			if code.javascript
				body += "<script>#{code.javascript}</script>"
			if code.coffee
				if code.coffee != code_previous.coffee
					coffee_body =
						try
							js = CoffeeScript.compile code.coffee
							"<script>#{js}</script>"
						catch e
							"""
							<h4 class='error'>CoffeeScript Compilation Error</h4>
							<p>#{e.message}</p>
							"""
				body += coffee_body
			
			html = """
				<!doctype html>
				<html>
					<head>
						<meta charset="utf-8">
						#{head}
					</head>
					<body style='background:black;color:white;'>
						#{body}
					</body>
				</html>
			"""
			$iframe.one "load", -> $pane.loading "done"
			
			# if browser supports srcdoc
			if typeof $iframe[0].srcdoc is "string"
				$iframe.attr srcdoc: html
			else
				# note: data URIs are limited to ~32k characters
				data_uri = "data:text/html," + encodeURI html
				
				if iframe.contentWindow
					iframe.contentWindow.location.replace data_uri
				else
					$iframe.attr src: data_uri
			
			code_previous = c for c in code

class EditorPane extends Pane
	@s = []
	constructor: ({lang})->
		EditorPane.s.push @
		super()
		@$.addClass "editor-pane"
		$pane = @$
		
		trigger_code_change = ->
			code[lang] = editor.getValue()
			$code.triggerHandler "change", lang
		
		$pad = $(E 'div')
		$pad.appendTo $pane
		
		$pane.loading()
		
		# Firepad Firebase reference
		fb_fp = fb_project.child lang
		
		# Create ACE
		editor = @editor = ace.edit $pad[0]
		editor.on 'change', trigger_code_change
		
		session = editor.getSession()
		editor.setShowPrintMargin no
		editor.setReadOnly yes
		editor.setSelectionStyle "text" # because this is what your selection will look like to other people
		session.setUseWrapMode no
		session.setUseWorker (lang isnt "html") # html linter recommends full html (<!doctype> etc.)
		session.setUseSoftTabs hell no
		session.setMode "ace/mode/#{lang}"
		
		# Create Firepad
		firepad = Firepad.fromACE fb_fp, editor
		
		# Initialize contents
		firepad.on 'ready', ->
			trigger_code_change()
			$pane.loading "done"
			editor.setReadOnly no
			if firepad.isHistoryEmpty()
				firepad.setText (
					javascript: '''
						// JavaScript
						
						document.write("Hello World!");
						
					'''
					coffee: '''
						
						spans = 
							for char in "Hello World from CoffeeScript!"
								span = document.createElement("span")
								document.body.appendChild(span)
								span.innerHTML = char
								(span)
						
						t = 0
						rainbow = ->
							t += 0.05
							for span, i in spans
								span.style.color = "hsl(#{
									Math.sin(t - i / 23) * 360
								},100%,80%)"
						
						setInterval rainbow, 30
						
					'''
					css: '''
						body {
							font-family: Helvetica, sans-serif;
						}
					'''
				)[lang] ? ""
	
	layout: ->
		@editor.resize()


fb_root = new Firebase "https://multifiddle.firebaseio.com/"
fb_project = null

hash = G.location.hash.replace '#', ''
if hash
	fb_project = fb_root.child hash
else
	# generate unique location
	fb_project = fb_root.push()
	# add it as a hash to the URL
	G.location = G.location + '#' + fb_project.name()


$ ->
	$body = $ document.body
	
	main_pane = new PanesPane orientation: "y"
	main_pane.add top_pane = new PanesPane orientation: "x"
	main_pane.add bottom_pane = new PanesPane orientation: "x"
	top_pane.add new EditorPane lang: "coffee"
	top_pane.add new EditorPane lang: "css"
	bottom_pane.add new EditorPane lang: "html"
	bottom_pane.add new PreviewPane
	
	$body.append main_pane.$
	
	relayout = -> main_pane.layout()
	$G.on "resize", relayout
	relayout()
	
	{themes, themesByName} = ace.require "ace/ext/themelist"
	
	setTheme = (theme_name)->
		theme = themesByName[theme_name]
		
		if theme.isDark
			$body.addClass "dark"
		else
			$body.removeClass "dark"
		
		for edpane in EditorPane.s
			edpane.editor.setTheme theme.theme
	
	setTheme "tomorrow_night_bright"
	console.log themes #todo: list themes, options
