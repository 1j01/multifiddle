
$G = $(G = window)

E = (tagname)-> document.createElement tagname

hell = (boo)-> boo#yah

class Pane
	constructor: ->
		@$ = $(E 'div')
		@$.addClass "pane"
		@flex = 1
	
	layout: ->
	
	destroy: ->

class PanesPane extends Pane
	resizer_size = 10
	
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
		
		for i in [1..parent_pane.children.length-1]
			before = parent_pane.children[i - 1]
			after = parent_pane.children[i]
			((before, after)->
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
			
			)(before, after)
		
	
	add: (pane)->
		@$.append pane.$
		@children.push pane
	
	destroy: ->
		for child_pane in @children
			child_pane.destroy?()

class PreviewPane extends Pane
	constructor: ({project})->
		super()
		@$.addClass "preview-pane"
		$pane = @$
		@_codes_previous = {}
		@_coffee_body = ""
		
		$iframe = $(iframe = E 'iframe').attr(sandbox:"allow-same-origin allow-scripts allow-forms")
		$iframe.appendTo $pane
		project.$codes.on "change", (e, lang)=>
			{codes} = project
			
			all_languages_are_there = true
			for expected_lang in project.languages
				if not codes[expected_lang]?
					all_languages_are_there = false
			
			if not all_languages_are_there
				return
			
			
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
			
			$.each codes, (lang, code)=>
				@_codes_previous[lang] = code

class EditorPane extends Pane
	@s = []
	constructor: ({lang, project})->
		EditorPane.s.push @
		super()
		@$.addClass "editor-pane"
		$pane = @$
		
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
	
	destroy: ->
		#console.debug "cleaning up editor"
		@editor.destroy()
