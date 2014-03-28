jQuery.fn.loading = (done)->
	d = "loading-indicator" #name to store linked element ("data") under
	s = 100 #size (todo: responsive size)
	c = s * 0.5 #center (half size)
	{sin, cos, PI} = Math
	TAU = PI * 2 #C/r
	
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
	
	@each ->
		parent = this
		$parent = jQuery parent
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
				indicator = canvas = document.createElement "canvas"
				$canvas = jQuery canvas
				
				if canvas.getContext
					ctx = canvas.getContext "2d"
					$indicator = $canvas
				else
					indicator = img = document.createElement "img"
					$indicator = $(img).attr src: jQuery.fn.loading.image
			
			indicator = $indicator[0]
			
			indicator.width = indicator.height = s
			
			indicator.style.position = "absolute"
			indicator.style.pointerEvents = "none"
			
			$indicator.appendTo "body"
			
			update = ->
				rect = parent.getBoundingClientRect()
				indicator.style.left = rect.left + (rect.width - s) * 0.5 + "px"
				indicator.style.top = rect.top + (rect.height - s) * 0.5 + "px"
				
				if ctx then draw(ctx, t += 0.3)
				
				if jQuery.contains document, indicator
					setTimeout update, 15
			setTimeout update, 15
			
			$parent.data d, $indicator

jQuery.fn.loading.image = "http://d1ktyob8e4hu6c.cloudfront.net/static/img/wait.gif"