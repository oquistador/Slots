Slots
===

Skinnable slots game using CreateJS on the client side and node.js, express, mongoose, and passport on the server side.
You can see it in its default state [here](http://oquistador-slots.herokuapp.com/).

Installation
---

    $ npm install
    $ grunt
    $ node app/app
    
Configuration
---

Most configuration can be done in the shared configuration file [app/config/shared.json]( https://github.com/oquistador/Slots/blob/master/app/config/shared.json). This JSON file gets merged into the client and server side scripts via [Grunt](https://github.com/gruntjs/grunt). All of the presentation logic is in [app/assets/javascripts/app.coffee](https://github.com/oquistador/Slots/blob/master/app/assets/javascripts/app.coffee) if you need to tweak anything.

Since this app uses the awesome node module [passport](https://github.com/jaredhanson/passport), you can use *tons* of other authentication strategies.
