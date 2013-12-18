var mongoose = require('mongoose');
var hash = require('./hash');
var spin = require('./spin');

UserSchema = mongoose.Schema({
	email: {
		type: String,
		unique: true,
		validate: function(val) {
			return /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(val);
		}
	},
	salt: String,
	hash: String,
	credits: {type: Number, min: 0}
});


UserSchema.statics.signup = function(email, password, done){
	var User = this;
	hash(password, function(err, salt, hash){
		if(err) return done(err);

		User.create({
			email: email,
			salt: salt,
			hash: hash,
			credits: 100
		}, function(err, user){
			done(err, user);
		});
	});
}


UserSchema.statics.isValidUserPassword = function(email, password, done) {
	this.findOne({email : email}, function(err, user){
		if(err) return done(err);
		if(!user) return done(null, false, {message: 'Incorrect email.'});

		hash(password, user.salt, function(err, hash){
			if(err) return done(err);
			if(hash == user.hash) return done(null, user);
			
			done(null, false, {
				message : 'Incorrect password'
			});
		});
	});
};

UserSchema.methods.update = function(req, res, next) {
	var user = this,
		credits = parseInt(req.body.credits);
	
	if (isNaN(credits)) {
		return res.json(412, {message: 'Invalid value'});
	}

	user.credits = credits;
	user.save(function(err) {
		if (err) return next(err);

		res.json({credits: user.credits});
	});
};

UserSchema.methods.spin = function(req, res, next) {
	var user = this,
		lines = parseInt(req.body.lines),
		bet = parseInt(req.body.bet),
		totalBet = lines * bet,
		results;

	if (user.credits < lines * bet) {
		return res.json(412, {message: 'Insufficient funds'});
	}

	results = spin({lines: lines, bet: bet});

	user.credits += results.reward - totalBet;

	user.save(function(err) {
		if (err) return next(err);
		
		results.credits = user.credits;
		res.json(results);
	});

};

module.exports = mongoose.model("User", UserSchema);