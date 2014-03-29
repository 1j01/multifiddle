
code = {}

$G = $(G = window)

hell = (boo)-> boo#yah

class Pane
	constructor: (o)->
		$pane = $('<div class="pane">')
		$pane.appendTo('body')
		
		do resize = ->
			$pane.css
				width: innerWidth
				height: innerHeight/2
		
		$G.on("resize", resize)
		
		if o.preview
			$iframe = $('<iframe sandbox="allow-same-origin allow-scripts allow-forms">')
			$iframe.appendTo $pane
			$G.on "code-change", ->
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
				
				data_uri = "data:text/html," + encodeURI(html)
				
				$iframe.one "load", -> $pane.loading("done")
				
				iframe = $iframe[0]
				if iframe.contentWindow
					iframe.contentWindow.location.replace data_uri
				else
					$iframe.attr src: data_uri
		else
			$pad = $('<div>')
			$pad.appendTo $pane
			
			$pane.loading()
			
			# Firepad Firebase reference
			fb_fp = fb_project.child o.lang
			
			# Create ACE
			editor = @editor = ace.edit $pad.get(0)
			editor.on 'input', ->
				code[o.lang] = editor.getValue()
				$G.triggerHandler("code-change")
			
			session = editor.getSession()
			editor.setShowPrintMargin no
			session.setUseWrapMode yes
			session.setUseWorker yes
			session.setUseSoftTabs hell no
			session.setMode "ace/mode/#{o.lang}"
			
			# Create Firepad
			firepad = Firepad.fromACE fb_fp, editor
			
			# Initialize contents
			firepad.on 'ready', ->
				$pane.loading("done")
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
					)[o.lang] ? ""
	
	set_theme: (theme)->
		if @editor
			@editor.setTheme theme.theme

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
	panes = [
		new Pane(lang:"coffee")
		new Pane(preview:yes)
	]
	{themes, themesByName} = ace.require("ace/ext/themelist")
	
	set_theme = (theme_name)->
		theme = themesByName[theme_name]
		
		if theme.isDark
			$("body").addClass("dark")
		else
			$("body").removeClass("dark")
		
		for pane in panes
			pane.set_theme theme
	
	set_theme "tomorrow_night_bright"
	console.log themes #todo: list themes, options
