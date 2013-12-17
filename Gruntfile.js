module.exports = function(grunt) {
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),
		app: {
			js: {
				dest: 'app/public/javascripts',
				src: 'app/assets/javascripts',
				components: 'app/components',
				config: 'app/config'
			}
		},
		watch: {
			coffee: {
				files: ['<%= app.js.src %>/*.coffee'],
				tasks: ['coffee:compile']
			}
		},
		coffee: {
			compile {
				options: {
					bare: true
				},
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