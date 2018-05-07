
{themes, themesByName} = ace.require "ace/ext/themelist"

$G = $(G = window)

E = (tagname)-> document.createElement tagname

wait_then = (fn)->
	tid = -1
	(args...)->
		clearTimeout tid
		tid = setTimeout ->
			fn args...
		, 100

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
		$G.on "resized", @_onresized = => @updateIcon()
		
		@canvas = E "canvas"
		@canvas.width = @canvas.height = 16
		# $("body").prepend @canvas
		# @canvas.style.border = "1px solid gray"
		# @canvas.style.margin = "19px"
		@ctx = @canvas.getContext "2d"
		@link = E "link"
		@link.rel = "icon"
		@updateIcon()
	
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
		$G.off "resize", @_onresized
		@root_pane.destroy()
		@root_pane.$.remove()
	
	show: (what_to_show)->
		switch what_to_show
			when "output"
				$("body").addClass "show-output-only"
			else
				$("body").removeClass "show-output-only"
	
	updateIcon: ->
		
		@ctx.clearRect 0, 0, @canvas.width, @canvas.height
		root_rect = @root_pane.$[0].getBoundingClientRect()
		for leaf_el in $ ".leaf-pane"
			leaf_rect = leaf_el.getBoundingClientRect()
			x = @canvas.width * (leaf_rect.left - root_rect.left) / root_rect.width
			y = @canvas.height * (leaf_rect.top - root_rect.top) / root_rect.height
			w = @canvas.width * leaf_rect.width / root_rect.width
			h = @canvas.height * leaf_rect.height / root_rect.height
			@ctx.fillStyle = switch $(leaf_el).find(".label").text()
				when "CoffeeScript" then "#F0DB4F"
				when "JavaScript" then "#F0DB4F"
				when "CSS" then "#33A9DC"
				when "HTML" then "#F1662A"
				when "Output" then "#bd79d1"
				else "#000"
			@ctx.fillRect ~~x, ~~y, ~~w, ~~h
			@ctx.clearRect ~~x - 1, ~~y - 1, 1, ~~h + 1
			@ctx.clearRect ~~x - 1, ~~y - 1, ~~w + 1, 1
		
		@ctx.save()
		@ctx.fillStyle = "lime"
		@ctx.globalCompositeOperation = "destination-in"
		@ctx.arc @canvas.width/2-0.5, @canvas.height/2-0.5, @canvas.height/2-0.5, 0, Math.PI * 2
		@ctx.fill()
		
		@ctx.restore()
		
		@link.href = @canvas.toDataURL "image/png"
		document.head.appendChild @link


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
		ctrl_s = e.ctrlKey and e.keyCode is 83
		escape = e.keyCode is 27
		if ctrl_s
			e.preventDefault()
		if escape or ctrl_m
			if $(".qr-code-popup").length
				$(".qr-code-popup").remove()
				return e.preventDefault()
		if ctrl_m
			e.preventDefault()
			
			output_only_url =
				if location.origin.match /127\.0\.0\.1|localhost|^file:/
					"https://multifiddle.ml/##{project_id}/output"
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
