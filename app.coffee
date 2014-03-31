
$G = $(G = window)

E = (tagname)-> document.createElement tagname

class Project
	constructor: (@fb)->
		#todo: load from fb
		@languages = ["coffee", "css", "html"]
		@$codes = $(@codes = {})
		
		$ =>
			$body = $ document.body
			
			@main_pane = new PanesPane orientation: "y"
			@main_pane.add top_pane = new PanesPane orientation: "x"
			@main_pane.add bottom_pane = new PanesPane orientation: "x"
			top_pane.add new EditorPane project: @, lang: @languages[0]
			top_pane.add new EditorPane project: @, lang: @languages[1]
			bottom_pane.add new EditorPane project: @, lang: @languages[2]
			bottom_pane.add new PreviewPane project: @
			
			$body.append @main_pane.$
			
			$G.on "resize", => @main_pane.layout()
			@main_pane.layout()
			
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
			console.log themes #todo: list themes, have options
	
	exit: ->
		$G.off()
		@main_pane.destroy()
		@main_pane.$.remove()


fb_root = new Firebase "https://multifiddle.firebaseio.com/"
hash = G.location.hash.replace '#', ''

if hash
	fb_project = fb_root.child hash
else
	# generate unique location
	fb_project = fb_root.push()
	# add it as a hash to the URL
	G.location = G.location + '#' + fb_project.name()

project = new Project fb_project

$G.on "hashchange", ->
	new_hash = G.location.hash.replace '#', ''
	if new_hash isnt hash
		project.exit()
		hash = new_hash
		
		fb_project = fb_root.child hash
		project = new Project fb_project
	
