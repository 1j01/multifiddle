var gulp = require('gulp');

var coffee = require('gulp-coffee');
var concat = require('gulp-concat');
var uglify = require('gulp-uglify');

var scripts = ['**/*.coffee', '!node_modules/**'];

gulp.task('bundle-scripts', function() {
	// Minify and copy all scripts
	return gulp.src(scripts)
		.pipe(concat('bundle.coffee'))
		.pipe(coffee())
		.pipe(uglify())
		.pipe(concat('bundle.min.js'))
		.pipe(gulp.dest('build'));
});

gulp.task('compile-scripts', function() {
	// Just compile scripts
	return gulp.src(scripts)
		.pipe(coffee())
		.pipe(gulp.dest('build'));
});

// Rerun the entire task, recompiling all files, when a file changes
gulp.task('watch-and-bundle-scripts', function() {
	gulp.watch(scripts, ['bundle-scripts']);
});
gulp.task('watch-and-compile-scripts', function() {
	gulp.watch(scripts, ['compile-scripts']);
});

gulp.task('default', ['watch-and-compile-scripts']);
