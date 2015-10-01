
$G = $(G = window)

E = (tagname)-> document.createElement tagname

hell = (b)-> b # boolean intensifier

class @Pane
	constructor: ->
		@$ = $(E 'div')
		@$.addClass "pane"
		@flex = 1
	
	layout: ->
	
	destroy: ->

class @PanesPane extends Pane
	resizer_size = 8 # TODO: use CSS
	
	constructor: ({orientation})->
		super
		@$.addClass "panes-pane"
		
		@orientation = orientation or "y"
		@children = []
		@$resizers = $()
	
	orient: (orientation)->
		@orientation = orientation
		@layout()
	
	layout: ->
		parent_pane = @
		o = @orientation
		
		# orientation
		display = (x:"inline-block", y:"block")[o]
		_col_row = (x:"col", y:"row")[o]
		
		# primary dimension which is divided between the children
		_d1 = (x:"width", y:"height")[o]
		_d1_start = (x:"left", y:"top")[o]
		_d1_end = (x:"right", y:"bottom")[o]
		
		# secondary dimension which is the same for the parent and all children
		_d2 = (x:"height", y:"width")[o]
		_d2_start = (x:"top", y:"left")[o]
		_d2_end = (x:"bottom", y:"right")[o]
		
		# properties of mouse events to get the mouse position
		_mouse_d1 = (x:"clientX", y:"clientY")[o]
		_mouse_d2 = (x:"clientY", y:"clientX")[o]
		
		
		n_children = parent_pane.children.length
		n_resizers = Math.max(0, n_children - 1)
		
		space_to_distribute_in_d1 = parent_pane.$[_d1]() - resizer_size * n_resizers
		for child_pane in parent_pane.children
			child_pane_size = child_pane.flex / n_children * space_to_distribute_in_d1
			child_pane.$.css _d1, child_pane_size
			child_pane.$.css _d2, parent_pane.$[_d2]()
			child_pane.$.css {display}
			child_pane.layout()
		
		
		
		parent_pane.$resizers.remove()
		parent_pane.$resizers = $()
		
		for before, i in parent_pane.children when after = parent_pane.children[i + 1]
			do (before, after)->
				$resizer = $(E "div").addClass("resizer #{_col_row}-resizer")
				$resizer.insertAfter(before.$)
				$resizer.css _d1, resizer_size
				$resizer.css _d2, parent_pane.$[_d2]()
				$resizer.css {display}
				$resizer.css cursor: "#{_col_row}-resize"
				
				$more_resizers = $()
				$resizer.on "mouseover mousemove", (e)->
					if not $resizer.hasClass "drag"
						$more_resizers = $()
						$(".resizer").each (i, res_el)->
							if $resizer[0] is res_el then return
							if not $.contains parent_pane.$[0], res_el then return
							
							rect = res_el.getBoundingClientRect()
							
							if rect[_d2_start] < e[_mouse_d2] < rect[_d2_end]
								$more_resizers = $more_resizers.add(res_el)
						
						$resizer.css cursor:  (if $more_resizers.length then "move" else "#{_col_row}-resize")
				
				$resizer.on "mouseout", (e)->
					if not $resizer.hasClass "drag"
						$more_resizers = $()
				
				$resizer.on "mousedown", (e, synthetic)->
					e.preventDefault()
					$resizer.addClass "drag"
					$more_resizers.addClass "drag"
					$("body").addClass "dragging"
					if not synthetic
						$("body").addClass (if $more_resizers.length then "multi" else _col_row) + "-resizing"
					$more_resizers.trigger(e, "synthetic")
					
					mousemove = (e)->
						before_start = before.$[0].getBoundingClientRect()[_d1_start]
						after_end = after.$[0].getBoundingClientRect()[_d1_end]
						
						b = resizer_size / 2 + 1
						mouse_pos = e[_mouse_d1]
						mouse_pos = Math.max(before_start+b, Math.min(after_end-b, mouse_pos))
						
						before.$.css _d1, mouse_pos - before_start - resizer_size / 2
						after.$.css _d1, after_end - mouse_pos - resizer_size / 2
						
						before.layout()
						after.layout()
						
						# calculate flex values
						total_size = (parent_pane.$[_d1]()) - (resizer_size * n_resizers)
						for pane in parent_pane.children
							pane.flex = pane.$[_d1]() / total_size * n_children
					
					$G.on "mousemove", mousemove
					$G.on "mouseup", ->
						$G.off "mousemove", mousemove
						$("body").removeClass "dragging col-resizing row-resizing multi-resizing"
						$resizer.removeClass "drag"
						$more_resizers.removeClass "drag"
				
				parent_pane.$resizers = parent_pane.$resizers.add $resizer
	
	add: (pane)->
		@$.append pane.$
		@children.push pane
	
	destroy: ->
		for child_pane in @children
			child_pane.destroy?()

class @LeafPane extends Pane
	@instances = []
	constructor: ({lang, project})->
		LeafPane.instances.push @
		super
		$pane = @$
		$pane.addClass "leaf-pane"
		
		$label = $(E 'button').addClass("label")
		$label.appendTo $pane
		$label.text switch lang
			when "coffee" then "CoffeeScript"
			when "js" then "JavaScript"
			when "css" then "CSS"
			when "html" then "HTML"
			when undefined then "Output"
			else "#{lang}".toUpperCase()

class @OutputPane extends LeafPane
	constructor: ({project})->
		super
		
		disable_output_key = "prevent running #{project.fb.key()}"
		
		$pane = @$
		$pane.addClass "output-pane"
		@_codes_previous = {}
		@_coffee_body = ""
		
		$iframe = $(iframe = E 'iframe').attr(sandbox: "allow-same-origin allow-scripts allow-forms", allowfullscreen: yes)
		$iframe.appendTo $pane
		wait_then = (fn)->
			tid = -1
			(args...)->
				clearTimeout tid
				tid = setTimeout ->
					fn args...
				, 600
		project.$codes.on "change", wait_then =>
			{codes} = project
			
			all_languages_are_there = true
			for expected_lang in project.languages
				if not codes[expected_lang]?
					all_languages_are_there = false
			
			return unless all_languages_are_there
			
			$pane.loading()
			
			head = body = ""
			
			error_handling = ->
				# @TODO: show this outside of the iframe
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
			
			if codes.html
				body += codes.html
			if codes.css
				head += "<style>#{codes.css}</style>"
			if codes.javascript
				body += "<script>#{codes.javascript}</script>"
			if codes.coffee
				if codes.coffee != @_codes_previous.coffee
					@_coffee_body =
						try
							js = CoffeeScript.compile codes.coffee
							"<script>#{js}</script>"
						catch e
							# @TODO: show this message outside of the iframe
							"""
							<h4 class='error'>CoffeeScript Compilation Error</h4>
							<p>#{e.message}</p>
							"""
				body += @_coffee_body
			
			html = """
				<!doctype html>
				<html>
					<head>
						<meta charset="utf-8">
						<meta name="viewport" content="width=device-width, initial-scale=1">
						#{head}
					</head>
					<body style='background:black;color:white;'>
						#{body}
					</body>
				</html>
			"""
			
			run = =>
				localStorage[disable_output_key] = on
				$pane.find(".disabled-output").remove()
				$iframe.show()
				$(window).on "beforeunload", ->
					delete localStorage[disable_output_key]
					return
				$iframe.on "load", ->
					$pane.loading "done"
					setTimeout ->
						# if after 500ms it hasn't crashed, that's good
						delete localStorage[disable_output_key]
					, 500
				# if browser supports srcdoc
				if typeof $iframe[0].srcdoc is "string"
					$iframe.attr srcdoc: html
				else
					# NOTE: data URIs are limited to ~32k characters
					data_uri = "data:text/html,#{encodeURI html}"
					
					if iframe.contentWindow
						iframe.contentWindow.location.replace data_uri
					else
						$iframe.attr src: data_uri
				
				$.each codes, (lang, code)=>
					@_codes_previous[lang] = code
			
			$pane.find(".disabled-output").remove()
			if localStorage[disable_output_key]
				$pane.loading "done"
				$iframe.hide()
				$disabled_output = $("<div>")
					.addClass "disabled-output"
					.append(
						$("<button>")
							.click run
							.append(
								$('''
									<svg height="48" viewBox="0 0 48 48" width="48" xmlns="http://www.w3.org/2000/svg">
										<defs xmlns="http://www.w3.org/2000/svg">
											<filter id="drop-shadow" height="130%">
												<feOffset dx="0" dy="2" in="SourceAlpha"/>
												<feMerge>
													<feMergeNode/>
													<feMergeNode in="SourceGraphic"/>
												</feMerge>
											</filter>
											<filter id="recessed" height="130%">
												<feOffset dx="0" dy="2" in="SourceGraphic"/>
											</filter>
										</defs>
										<path d="M20 33l12-9-12-9v18zm4-29C12.95 4 4 12.95 4 24s8.95 20 20 20 20-8.95 20-20S35.05 4 24 4zm0 36c-8.82 0-16-7.18-16-16S15.18 8 24 8s16 7.18 16 16-7.18 16-16 16z"/>
									</svg>
								''')
							)
						$("<p>This might crash...</p>")
					)
				$pane.append $disabled_output
			else
				run()

class @EditorPane extends LeafPane
	@instances = []
	constructor: ({lang, project})->
		EditorPane.instances.push @
		super
		$pane = @$
		$pane.addClass "editor-pane"
		
		trigger_code_change = ->
			project.codes[lang] = editor.getValue()
			project.$codes.triggerHandler "change", lang
		
		$pad = $(E 'div')
		$pad.appendTo $pane
		
		$pane.loading()
		
		# Firepad Firebase reference
		fb_fp = project.fb.child lang
		
		# Create ACE
		editor = @editor = ace.edit $pad[0]
		editor.on 'change', trigger_code_change
		
		session = editor.getSession()
		editor.setShowPrintMargin no
		editor.setReadOnly yes
		editor.setSelectionStyle "text" # because this is what your selection will look like to other people
		# TODO: toggle line highlight based on focusedness of the ace editor 
		editor.setOption "highlightActiveLine", no
		editor.setOption "highlightGutterLine", no
		editor.$blockScrolling = Infinity # I don't know if I actually want this, just hiding a warning
		session.setUseWrapMode no
		session.setUseWorker (lang isnt "html") # html linter recommends full html (<!doctype> etc.) which we don't want
		session.setUseSoftTabs hell no
		session.setMode "ace/mode/#{lang}"
		
		# Create Firepad
		@firepad = Firepad.fromACE fb_fp, editor
		
		# Initialize contents
		@firepad.on 'ready', =>
			trigger_code_change()
			$pane.loading "done"
			editor.setReadOnly no
	
	layout: ->
		@editor.resize()
	
	destroy: ->
		@firepad.dispose()
		@editor.destroy()
		EditorPane.instances = (instance for instance in EditorPane.instances when instance isnt @)
