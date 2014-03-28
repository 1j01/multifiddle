
ace_editors = []
set_theme = (theme_name)->
	for editor in ace_editors
		editor.setTheme "ace/theme/#{theme_name}"

class Pane
	constructor: ({lang})->
		
		@$pane = $('<div class="pane">')
		@$pane.appendTo('body')
		
		(resize = =>
			@$pane.css
				width: innerWidth
				height: innerHeight
		)()
		
		$(window).on "resize", resize
		
		@$pad = $ '<div>'
		@$pad.appendTo @$pane
		
		# Firepad Firebase reference
		fb_fp = fb_project.child lang

		# Create ACE
		editor = ace.edit @$pad.get(0)
		ace_editors.push editor
		session = editor.getSession()
		session.setUseWrapMode yes
		session.setUseWorker no
		session.setMode "ace/mode/#{lang}"

		# Create Firepad
		firepad = Firepad.fromACE fb_fp, editor

		# Initialize contents
		firepad.on 'ready', ->
			if firepad.isHistoryEmpty()
				firepad.setText '''
					// JavaScript Editing with Firepad!
					function go() {
						var message = "Hello, world.";
						console.log(message);
					}
				'''

fb_root = new Firebase("https://multifiddle.firebaseio.com/")
fb_project = null

hash = window.location.hash.replace('#', '')
if hash
	fb_project = fb_root.child(hash)
else
	# generate unique location
	fb_project = fb_root.push()
	# add it as a hash to the URL
	window.location = window.location + '#' + fb_project.name()


$ ->
	panes = [
		new Pane(lang:"javascript")
		#new Pane()
		#new Pane()
		#new Pane()
	]
	set_theme "kr"
	