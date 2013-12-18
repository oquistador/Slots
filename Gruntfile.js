module.exports = function(grunt) {
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),
		paths: {
			js: {
				dest: 'app/public/javascripts',
				src: 'app/assets/javascripts',
				components: 'app/bower_components',
				config: 'app/config'
			}
		},

		coffee: {
			compile: {
				options: {
					bare: true
				},
				dest: '<%= paths.js.src %>/app.js',
				src: '<%= paths.js.src %>/app.coffee'
			}
		},

		concat: {
			serverConfig: {
				options: {
					banner: 'module.exports = ',
					footer: ';'
				},
				dest: '<%= paths.js.config %>/server_config.js',
				src: '<%= paths.js.config %>/shared.json'
			},
			
			clientConfig: {
				options: {
					banner: 'var Slots = Slots || {};\nSlots.config = Slots.config || {};\n_.extend(Slots.config, ',
					footer: ');'
				},
				dest: '<%= paths.js.config %>/client_config.js',
				src: '<%= paths.js.config %>/shared.json'
			},
			
			vendor: {
				dest: '<%= paths.js.dest %>/vendor.js',
				src: [
				// TODO: The createjs assets need to be compiled
					'<%= paths.js.components %>/preloadjs/lib/preloadjs-0.4.1.min.js',
					'<%= paths.js.components %>/easeljs/lib/easeljs-0.7.1.min.js',
					'<%= paths.js.components %>/jQuery/dist/jquery.js',
					'<%= paths.js.components %>/underscore/underscore.js',
					'<%= paths.js.components %>/backbone/backbone.js',
				]
			},
			
			clientApp: {
				options: {
					banner: '(function(undefined){\n',
					footer: '\n}());'
				},
				dest: '<%= paths.js.dest %>/app.js',
				src: [
					'<%= concat.clientConfig.dest %>',
					'<%= coffee.compile.dest %>'
				]
			}
		}


	});

	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-contrib-copy');
	grunt.loadNpmTasks('grunt-contrib-concat');
	grunt.loadNpmTasks('grunt-contrib-uglify');
	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-contrib-watch');
	grunt.loadNpmTasks('grunt-contrib-watch');

	grunt.registerTask('build', [
		'coffee',
		'concat'
	]);
};