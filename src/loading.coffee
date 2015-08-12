do ($ = jQuery)->
	$.fn.loading = (done)->
		fallback_image = "http://d1ktyob8e4hu6c.cloudfront.net/static/img/wait.gif"
		min_size = 32
		max_size = 100
		
		s = max_size # size
		c = s * 0.5 # center
		{sin, cos, min, max, PI} = Math
		TAU = PI * 2 # C/r
		
		draw = (ctx, t)->
			
			ctx.globalAlpha = 0.05
			ctx.clearRect 0, 0, s, s
			ctx.globalAlpha = 1
			
			ctx.fillStyle = '#FFF'
			ctx.strokeStyle = '#000'
			ctx.shadowColor = '#999'
			ctx.shadowBlur = 20
			n = 10
			for i in [0..n]
				ctx.beginPath()
				ctx.arc(
					c + sin(t * 0.05 + i) * c * 0.8
					c + cos(t * 0.05 + i) * c * 0.8
					c * 0.05 * (1 + cos(t * 0.2 + i * 0.2))
					0, TAU
				)
				ctx.fill()
				ctx.stroke()
		
		d = "loading-indicator" #name to store linked element ("data") under
		@each ->
			parent = this
			$parent = $(parent)
			$indicator = $parent.data d
			
			t = Math.random() * 100
			
			if done
				if $indicator
					$indicator.fadeOut 500, ->
						$indicator.remove()
						$parent.data d, null
			else
				if $indicator
					$indicator.stop().fadeIn 200
				else
					canvas = document.createElement "canvas"
					$canvas = $(canvas)
					
					if canvas.getContext
						ctx = canvas.getContext "2d"
						$indicator = $canvas
					else
						indicator = img = document.createElement "img"
						$indicator = $(img).attr src: fallback_image
				
					indicator = $indicator[0]
					indicator.width = indicator.height = s
					$indicator.appendTo("body")
					
					update = ->
						rect = parent.getBoundingClientRect()
						s = max(min_size, 5, min(max_size, min(rect.width, rect.height)))
						c = s * 0.5
						
						indicator.style.left = rect.left + (rect.width - s) * 0.5 + "px"
						indicator.style.top = rect.top + (rect.height - s) * 0.5 + "px"
						
						indicator.width = s if indicator.width isnt s
						indicator.height = s if indicator.height isnt s
						
						if ctx then draw(ctx, t += 0.3)
						
						# if document contains indicator
						if $.contains document, indicator
							setTimeout update, 15
					
					start = ->
						indicator.style.display = "block"
						indicator.style.position = "absolute"
						indicator.style.pointerEvents = "none"
						indicator.style.zIndex = "2"
						update()
					
					indicator.style.display = "none"
					
					setTimeout start, 15
					
					$parent.data d, $indicator
