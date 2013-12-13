var User = require('./models');

module.exports = function (app, passport) {
	app.get('/', function (req, res) {
		if (req.isAuthenticated()) {
			res.render('index', {user: req.user});
		} else {
			res.render('index', {user: null})
		}
	});

	app.get('/login', function (req, res) { 
		res.render('login');
	});

	app.post('/login', passport.authenticate('local', {successRedirect: '/', failureRedirect: '/login'}));

	app.get('/logout', function (req, res) {
		req.logout();
		res.redirect('/');
	});

	app.get('/signup', function (req, res) {
		res.render('signup');
	});

	app.post('/signup', function (req, res, next) {
		User.signup(req.body.email, req.body.password, function (err, user) {
			if (err) { return res.render('signup'); }
			
			req.login(user, function (err) {
				if (err) return next(err);
				return res.redirect('/');
			});
		});
	});

	app.get('/test_api', function (req, res) {
		if (req.isAuthenticated()) {
			res.render('testApi', {user: req.user});
		} else {
			res.redirect('/')
		}
	});

	app.post('/api/users/:id/spin', function (req, res, next) {
		if (!req.isAuthenticated()) return res.send(401);

		req.user.spin(req.body.lines, req.body.bet, function (err, results) {
			console.log(results);
		});
	});

	app.post('/api/users/:id/add_credits', function (req, res, next) {
		if (!req.isAuthenticated()) return res.send(401);

		req.user.addCredits(req.body.credits, function (err, numAffected){
			if (err) return res.send(500);

			res.json({credits: req.user.get('credits')});
		});
	});
};