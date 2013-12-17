module.exports = function(grunt) {
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),
		app: {
			js: {
				dest: 'app/public/javascripts',
				src: 'app/assets/javascripts',
				components: 'app/components'
			}
		},
		watch: {
			coffee: {
				files: ['<%= app.js.src %>/*.coffee'],
				tasks: ['coffee']
			}
		},
		coffee: {
			compile: {
				files: {'<%= app.js.dest %>/app.js': ['<%= app.js.src %>/*.coffee']}
			}
		},
		vendor: {
			dist: {
				src: ['<%= app.js.components %>/easeljs'],
				dest: 'vendor.js'
			}
		}
	});
}