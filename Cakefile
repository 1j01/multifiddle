
CoffeeScript = require "coffee-script"
mkdirp = require "mkdirp"
fs = require "fs"
path = require "path"

task "sbuild", ->
	mkdirp "build", (err)->
		throw err if err
		
		bundle_js = ""
		
		for fname in ["loading", "panes", "app"]
			
			coffee = fs.readFileSync("#{fname}.coffee").toString()
			js = CoffeeScript.compile(coffee, {bare:yes})
			
			fs.writeFileSync "build/#{fname}.js", js
			
			bundle_js += js
		
		#fs.writeFileSync "build/bundle.js", bundle_js

