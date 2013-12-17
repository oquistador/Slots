var mongoose = require('mongoose'),
	LocalStrategy = require('passport-local').Strategy,
	User = mongoose.model('User');

module.exports = function(passport) {
	passport.serializeUser(function(user, done) {
		done(null, user.id);
	});

	passport.deserializeUser(function(id, done) {
		User.findOne({ _id: id }, function (err, user) { done(err, user); });
	});

	passport.use(
		new LocalStrategy(
			{
				usernameField: 'email',
				passwordField: 'password'
			},
			function(email, password, done) {
				User.isValidUserPassword(email, password, done);
			}
		)
	);
};