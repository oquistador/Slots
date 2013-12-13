var mongoose = require('mongoose');
var hash = require('./hash');

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

UserSchema.methods.addCredits = function(credits, done) {
	credits = parseInt(credits);
	
	if (isNaN(credits) || credits < 0) {
		return done({message: 'Invalid value'});
	}

	this.credits += credits;
	this.save(done);
};

UserSchema.methods.spin = function(lines, bet, done) {
	var config = require('./config');

	console.log('Spinning with lines: ', lines, ', bet: ', bet);
};

var User = mongoose.model("User", UserSchema);
module.exports = User;