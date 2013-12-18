module.exports = function(grunt) {
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),
		paths: {
			js: {
				dest: 'app/public/javascripts',
				src: 'app/assets/javascripts',
				components: 'app/bower_components',
				config: 'app/config',
				temp: '.temp/javascripts'
			}
		},

		clean: {
			server: ['<%= concat.serverConfig.dest %>'],
			client: ['.temp']
		},

		coffee: {
			compile: {
				options: {
					bare: true
				},
				dest: '<%= paths.js.temp %>/app.js',
				src: ['<%= paths.js.src %>/app.coffee']
			}
		},

		concat: {
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
					banner: '(function(Slots, undefined){\nSlots.config = Slots.config || {};\n_.extend(Slots.config, ',
					footer: ');\n})(window.Slots || {});'
				},
				dest: '<%= paths.js.temp %>/client_config.js',
				src: '<%= paths.js.config %>/shared.json'
			},
			
			clientApp: {
				options: {
					banner: '(function(undefined){\n',
					footer: '})();'
				},
				dest: '<%= paths.js.dest %>/app.js',
				src: [
					'<%= concat.clientConfig.dest %>',
					'<%= coffee.compile.dest %>'
				]
			}
		},

		watch: {
			js: {
				files: [
					'<%= coffee.compile.src %>',
					'<%= paths.js.config %>/shared.json'
				],
				tasks: ['buildClientJS']
			}
		}
	});

	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-contrib-copy');
	grunt.loadNpmTasks('grunt-contrib-concat');
	grunt.loadNpmTasks('grunt-contrib-uglify');
	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-contrib-watch');

	grunt.registerTask('build', [
		'clean',
		'buildClientJS',
		'buildVendorJS',
		'concat:serverConfig'
	]);

	grunt.registerTask('buildClientJS', [
		'coffee',
		'concat:clientConfig',
		'concat:clientApp',
		'clean:client'
	]);

	grunt.registerTask('buildVendorJS', [
		'concat:vendor'
	]);
};