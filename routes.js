var User = require('./models');
var config = require('./config');

module.exports = function(app, passport) {
	app.get('/', function(req, res) {
		if (req.isAuthenticated()) {
			res.render('index', {user: req.user});
		} else {
			res.render('index', {user: null})
		}
	});

	app.get('/login', function(req, res) { 
		res.render('login');
	});

	app.post('/login', passport.authenticate('local', {successRedirect: '/', failureRedirect: '/login'}));

	app.get('/logout', function(req, res) {
		req.logout();
		res.redirect('/');
	});

	app.get('/signup', function(req, res) {
		res.render('signup');
	});

	app.post('/signup', function(req, res, next) {
		User.signup(req.body.email, req.body.password, function(err, user) {
			if (err) { return res.render('signup'); }
			
			req.login(user, function(err) {
				if (err) return next(err);
				return res.redirect('/');
			});
		});
	});

	app.get('/test_api', function(req, res) {
		if (req.isAuthenticated()) {
			res.render('testApi', {user: req.user});
		} else {
			res.redirect('/');
		}
	});

	app.post('/api/users/:id/spin', function(req, res, next) {
		if (!req.isAuthenticated()) return res.json({message: 'unauthorized'}, 401);
		req.user.spin(req, res, next);
	});

	app.post('/api/users/:id/add_credits', function(req, res, next) {
		if (!req.isAuthenticated()) return res.json({message: 'unauthorized'}, 401);
		req.user.addCredits(req, res, next);
	});

	app.get('/api/configs', function(req, res, next) {
		if (!req.isAuthenticated()) return res.json({message: 'unauthorized'}, 401);
		res.json(config);
	});
};