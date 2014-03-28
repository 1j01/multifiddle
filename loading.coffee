jQuery.fn.loading = (done)->
	d = "loading-indicator"
	s = 100
	c = s / 2
	@each ->
		parent = this
		$parent = jQuery parent
		$indicator = $parent.data d
		
		if done
			if $indicator
				$indicator.fadeOut -> $indicator.remove()
				$parent.data d, null
		else if done isnt "done" and not $indicator
			canvas = document.createElement "canvas"
			$canvas = jQuery canvas
			
			if canvas.getContext
				ctx = canvas.getContext "2d"
				
				t = 0
				{sin, cos, PI} = Math
				TAU = PI * 2 #C/r
				draw = ->
					t += 0.3
					
					ctx.globalAlpha = 0.05
					ctx.clearRect 0, 0, s, s
					ctx.globalAlpha = 1
					
					ctx.fillStyle = '#FFF'
					ctx.strokeStyle = '#000'
					ctx.shadowColor = '#999';
					ctx.shadowBlur = 20;
					n = 10
					for i in [0..n]
						ctx.beginPath()
						ctx.arc(
							c + sin(t/20+i) * c * 0.8
							c + cos(t/20+i) * c * 0.8
							c * 0.05 * (1+cos(t/5+i/6))
							0, TAU
						)
						ctx.fill()
						ctx.stroke()
					
					if $canvas.is ":visible"
						setTimeout draw, 15
				
				setTimeout draw, 15
				$indicator = $canvas
			else
				img = document.createElement "img"
				$indicator = $(img).attr src: jQuery.fn.loading.image
			
			$indicator.attr
				width: s
				height: s
			
			$indicator.css
				position: "absolute"
				pointerEvents: "none"
			
			$indicator.appendTo "body"
			
			update = ->
				rect = parent.getBoundingClientRect()
				$indicator.css
					left: rect.left + (rect.width - $indicator.width()) / 2
					top: rect.top + (rect.height - $indicator.height()) / 2
				
				setTimeout update, 30
			setTimeout update, 30
			
			$parent.data d, $indicator

jQuery.fn.loading.image = "http://d1ktyob8e4hu6c.cloudfront.net/static/img/wait.gif"