
code = {}
$code = $(code)

$G = $(G = window)

hell = (boo)-> boo#yah

class Pane
	constructor: ->
		$pane = @$pane = $('<div class="pane">')

class PanesPane extends Pane
	constructor: ({orientation})->
		super()
		
		@orientation = orientation or "y"
		@children = []
		
		@$pane.on("resize", => @layout())
		
	orient: (orientation)->
		@orientation = orientation
		@layout()
	
	layout: ->
		# main parent measure: the space that's divided between children
		mpm = if @orientation is "x" then "width" else "height"
		# other parent measure: the measure that's the same for the parent and all children
		opm = if @orientation is "x" then "height" else "width"
		
		# main parent measure: the space that's divided between children
		display = if @orientation is "x" then "inline-block" else "block"
		
		# calculate the lengths of the parent
		mpl = @$pane[mpm]()
		opl = @$pane[opm]()
		
		n_children = @children.length
		n_resizers = Math.max(0, n_children - 1)
		
		for child in @children
			child.$pane.css mpm, (mpl / n_children) - (10 * n_resizers)
			child.$pane.css opm, opl
			child.$pane.css {display}
			child.$pane.triggerHandler("resize")
	
	add: (pane, location)->
		@$pane.append(pane.$pane)
		@children.push pane

class PreviewPane extends Pane
	constructor: ->
		super()
		$pane = @$pane
		
		$iframe = $('<iframe sandbox="allow-scripts allow-forms">')
		$iframe.appendTo $pane
		$code.on "change", ->
			$pane.loading()
			
			head = body = ""
			
			error_handling = ->
				d = document.createElement("div")
				d.className = "error bubble script-error"
				window.onerror = (error)->
					document.body.appendChild(d)
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
				try
					js = CoffeeScript.compile(code.coffee)
					body += "<script>#{js}</script>"
				catch e
					body += """
						<h4 class='error'>CoffeeScript Compilation Error</h4>
						<p>#{e.message}</p>
					"""
			
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
			$iframe.one "load", -> $pane.loading("done")
			
			# if browser supports srcdoc
			if typeof $iframe[0].srcdoc is "string"
				$iframe.attr srcdoc: html
			else
				# note: data URIs are limited to ~32k characters
				data_uri = "data:text/html," + encodeURI(html)
				
				iframe = $iframe[0]
				if iframe.contentWindow
					iframe.contentWindow.location.replace data_uri
				else
					$iframe.attr src: data_uri

class EditorPane extends Pane
	@s = []
	constructor: ({lang})->
		EditorPane.s.push @
		super()
		$pane = @$pane
		
		$pad = $('<div>')
		$pad.appendTo $pane
		
		$pane.loading()
		
		# Firepad Firebase reference
		fb_fp = fb_project.child lang
		
		# Create ACE
		editor = @editor = ace.edit $pad.get(0)
		editor.on 'input', ->
			code[lang] = editor.getValue()
			$code.triggerHandler("change")
		
		session = editor.getSession()
		editor.setShowPrintMargin no
		editor.setReadOnly yes
		editor.setSelectionStyle "text" # because this is what your selection will look like to other people
		session.setUseWrapMode yes
		session.setUseWorker (lang isnt "html") # html linter recommends full html (<!doctype> etc.)
		session.setUseSoftTabs hell no
		session.setMode "ace/mode/#{lang}"
		
		# Create Firepad
		firepad = Firepad.fromACE fb_fp, editor
		
		# Initialize contents
		firepad.on 'ready', ->
			$pane.loading("done")
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


fb_root = new Firebase("https://multifiddle.firebaseio.com/")
fb_project = null

hash = G.location.hash.replace('#', '')
if hash
	fb_project = fb_root.child(hash)
else
	# generate unique location
	fb_project = fb_root.push()
	# add it as a hash to the URL
	G.location = G.location + '#' + fb_project.name()


$ ->
	main_pane = new PanesPane orientation: "y"
	main_pane.add top_pane = new PanesPane orientation: "x"
	main_pane.add bottom_pane = new PanesPane orientation: "x"
	top_pane.add new EditorPane lang: "coffee"
	top_pane.add new EditorPane lang: "css"
	bottom_pane.add new EditorPane lang: "html"
	bottom_pane.add new PreviewPane
	
	$('body').append(main_pane.$pane)
	
	relayout = -> main_pane.$pane.triggerHandler("resize")
	$G.on "resize", relayout
	relayout()
	
	{themes, themesByName} = ace.require("ace/ext/themelist")
	
	setTheme = (theme_name)->
		theme = themesByName[theme_name]
		
		if theme.isDark
			$("body").addClass("dark")
		else
			$("body").removeClass("dark")
		
		for edpane in EditorPane.s
			edpane.editor.setTheme theme.theme
	
	setTheme "tomorrow_night_bright"
	console.log themes #todo: list themes, options
