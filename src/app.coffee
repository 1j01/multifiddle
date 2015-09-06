
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
		
		@root_pane = new PanesPane orientation: "y"
		@root_pane.add top_pane = new PanesPane orientation: "x"
		@root_pane.add bottom_pane = new PanesPane orientation: "x"
		top_pane.add new EditorPane project: @, lang: @languages[0]
		top_pane.add new EditorPane project: @, lang: @languages[1]
		bottom_pane.add new EditorPane project: @, lang: @languages[2]
		bottom_pane.add @output_pane = new OutputPane project: @
		
		@root_pane.$.appendTo "body"
		@root_pane.layout()
		@applyTheme "tomorrow_night_bright"
		@show what_to_show
		
		$G.on "resize", @_onresize = => @root_pane.layout()
	
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
		@root_pane.destroy()
		@root_pane.$.remove()
	
	show: (what_to_show)->
		switch what_to_show
			when "output"
				$("body").addClass "show-output-only"
			else
				$("body").removeClass "show-output-only"


fb_root = new Firebase "https://multifiddle.firebaseio.com/"

hash = G.location.hash.replace '#', ''
[project_id, what_to_show] = hash.split "/"

if hash
	fb_project = fb_root.child project_id
else
	fb_project = fb_root.push()
	G.location = G.location + '#' + fb_project.key()

$ ->
	project = new Project fb_project, what_to_show
	
	$G.on "hashchange", ->
		new_hash = G.location.hash.replace '#', ''
		[new_project_id, new_to_show] = new_hash.split "/"
		console?.debug? "location hash changed from #{hash} to #{new_hash}"
		
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
	
	$G.on "keydown", (e)->
		ctrl_m = e.ctrlKey and e.keyCode is 77
		escape = e.keyCode is 27
		if escape or ctrl_m
			if $(".qr-code-popup").length
				$(".qr-code-popup").remove()
				return e.preventDefault()
		if ctrl_m
			e.preventDefault()
			
			output_only_url =
				if location.origin.match /127\.0\.0\.1|localhost|^file:/
					"http://1j01.github.io/multifiddle/##{project_id}/output"
				else
					"#{location.origin}#{location.pathname}##{project_id}/output"
			
			size = 256
			
			# create the qrcode itself
			qrcode = new QRCode(-1, QRErrorCorrectLevel.M)
			qrcode.addData(output_only_url)
			qrcode.make()
			
			# create canvas
			canvas = document.createElement "canvas"
			canvas.width = size
			canvas.height = size
			ctx = canvas.getContext "2d"
			
			n_cells = qrcode.getModuleCount()
			cell_size = size / n_cells
			
			# draw on the canvas
			for row in [0...n_cells]
				for col in [0...n_cells]
					ctx.fillStyle = if qrcode.isDark(row, col) then "#000" else "#fff"
					w = (Math.ceil((col+1)*cell_size) - Math.floor(col*cell_size))
					h = (Math.ceil((row+1)*cell_size) - Math.floor(row*cell_size))
					ctx.fillRect(Math.round(col*cell_size), Math.round(row*cell_size), w, h)
			
			$(canvas)
				.addClass "qr-code-popup"
				.appendTo "body"
				.css
					position: "absolute"
					margin: "auto"
					top: 0, left: 0, bottom: 0, right: 0
					zIndex: 10
					boxShadow: "#0083F5 0 0 180px"
					border: "5px solid rgba(0, 131, 245, 0.6)"
