
{themes, themesByName} = ace.require "ace/ext/themelist"
# console.log "Themes: #{(Object.keys themesByName).join ", "}"
# @TODO: list themes, have options

$G = $(G = window)

E = (tagname)-> document.createElement tagname

class @Project
	constructor: (@fb, what_to_show)->
		# @TODO: Load from Firebase
		@languages = ["coffee", "css", "html"]
		@$codes = $(@codes = {})
		
		@show what_to_show
		# @main_pane = new PanesPane orientation: "y"
		# @main_pane.add top_pane = new PanesPane orientation: "x"
		# @main_pane.add bottom_pane = new PanesPane orientation: "x"
		# top_pane.add new EditorPane project: @, lang: @languages[0]
		# top_pane.add new EditorPane project: @, lang: @languages[1]
		# bottom_pane.add new EditorPane project: @, lang: @languages[2]
		# bottom_pane.add @output_pane = new PreviewPane project: @
		# 
		# $body.append @main_pane.$
		# @main_pane.layout()
		
		$G.on "resize", @_onresize = => @main_pane.layout()
	
	applyTheme: (theme_name)->
		theme = themesByName[theme_name]
		
		if theme.isDark
			$("body").addClass "dark"
		else
			$("body").removeClass "dark"
		
		for edpane in EditorPane.instances
			edpane.editor.setTheme theme.theme
	
	exit: ->
		$G.off "resize", @_onresize
		@main_pane.destroy()
		@main_pane.$.remove()
	
	show: (what_to_show)->
		what_to_show or= "all"
		@main_pane?.destroy()
		@main_pane?.$?.remove()
		switch what_to_show
			when "output"
				@main_pane = new PanesPane orientation: "y"
				@main_pane.add new PreviewPane project: @
			when "all"
				@main_pane = new PanesPane orientation: "y"
				@main_pane.add top_pane = new PanesPane orientation: "x"
				@main_pane.add bottom_pane = new PanesPane orientation: "x"
				top_pane.add new EditorPane project: @, lang: @languages[0]
				top_pane.add new EditorPane project: @, lang: @languages[1]
				bottom_pane.add new EditorPane project: @, lang: @languages[2]
				bottom_pane.add new PreviewPane project: @
			else
				alert "Unknown thing to show, url includes #.../???"
		@main_pane.$.appendTo "body"
		@main_pane.layout()
		@applyTheme "tomorrow_night_bright"


fb_root = new Firebase "https://multifiddle.firebaseio.com/"

hash = G.location.hash.replace '#', ''
[project_id, what_to_show] = hash.split "/"

if hash
	fb_project = fb_root.child project_id
else
	fb_project = fb_root.push()
	G.location = G.location + '#' + fb_project.name()

$ ->
	project = new Project fb_project, what_to_show
	
	$G.on "hashchange", ->
		new_hash = G.location.hash.replace '#', ''
		[new_project_id, new_to_show] = new_hash.split "/"
		console?.debug? "location hash changed from", hash, "to", new_hash
		
		if new_project_id isnt project_id
			project_id = new_project_id
			console?.debug? "switch project to #{new_project_id}"
			
			project.exit()
			
			fb_project = fb_root.child project_id
			project = new Project fb_project, new_to_show
		
		if new_to_show isnt what_to_show
			what_to_show = new_to_show
			console?.debug? "show #{new_to_show or "all panes"}"
			project.show new_to_show
