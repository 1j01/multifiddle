
ace_editors = []
set_theme = (theme_name)->
	for editor in ace_editors
		editor.setTheme "ace/theme/#{theme_name}"

code = {}

$G = $(G = window)

class Pane
	constructor: (o)->
		@pane = $('<div class="pane">')
		@pane.appendTo('body')
		
		(resize = =>
			@pane.css
				width: innerWidth
				height: innerHeight/2
		)()
		
		$G.on("resize", resize)
		
		if o.preview
			@iframe = $('<iframe sandbox="allow-same-origin allow-scripts allow-forms">')
			@iframe.appendTo @pane
			$G.on "code-change", =>
				head = ""
				body = ""
				
				# todo: handle errors
				
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
						body += "<h1>CoffeeScript Compilation Error</h1>" + e.message
				
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
				
				iframe = @iframe[0]
				if iframe.contentWindow
					iframe.contentWindow.location.replace data_uri
				else
					@iframe.attr src: data_uri
		else
			@pad = $('<div>')
			@pad.appendTo @pane
			
			# Firepad Firebase reference
			fb_fp = fb_project.child o.lang

			# Create ACE
			editor = ace.edit @pad.get(0)
			ace_editors.push editor
			editor.on 'input', ->
				code[o.lang] = editor.getValue()
				$G.triggerHandler("code-change")
			
			session = editor.getSession()
			session.setUseWrapMode yes
			session.setUseWorker no
			session.setMode "ace/mode/#{o.lang}"

			# Create Firepad
			firepad = Firepad.fromACE fb_fp, editor

			# Initialize contents
			firepad.on 'ready', ->
				if firepad.isHistoryEmpty()
					firepad.setText (
						javascript: '''
							// JavaScript
							
							document.write("Hello World!");
							
						'''
						coffee: '''
							# CoffeeScript
							
							document.write "Hello World!"
							
						'''
						css: '''
							body {
								font-family: Helvetica, sans-serif;
							}
						'''
					)[o.lang] ? ""

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
	#set_theme "kr"
	