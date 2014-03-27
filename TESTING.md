# Testing

## Bundler

A ruby environment with Bundler installed is a prerequisite for using the testing harness shipped with this cookbook. At the time of this writing, it works with Ruby 2.0 and Bundler 1.5.3. All programs involved, with the exception of Vagrant, can be installed by cd'inginto the parent directory of this cookbook and running `bundle install`

## Rakefile

The Rakefile ships with a number of tasks, each of which can be ran individually, or in groups. Typing `rake` by itself will perform style checks with Rubocop and Foodcritic, ChefSpec with rspec, and integration with Test Kitchen using the Vagrant driver by default.

```
$ rake -T
rake integration:kitchen:all  # Run Test Kitchen with Vagrant
rake spec                 # Run ChefSpec examples
rake style                # Run all style checks
rake style:chef           # Lint Chef cookbooks
rake style:ruby           # Run Ruby style checks
rake travis               # Run all tests on Travis
```

## Style Testing

Ruby style tests can be performed by Rubocop by issuing either
```
bundle exec rubocop
```
or
```
rake style:ruby
```

Chef style tests can be performed with Foodcritic by issuing either
```
bundle exec foodcritic
```
or
```
rake style:chef
```

## Spec Testing

Unit testing is done by running Rspec examples. Rspec will test any
libraries, then test recipes using ChefSpec. This works by compiling a
recipe (but not converging it), and allowing the user to make
assertions about the resource_collection.

## Integration Testing

Integration testing is performed by Test Kitchen. Test Kitchen will
use either the Vagrant driver or various cloud drivers to instantiate
machines and apply cookbooks. After a successful converge, tests are
uploaded and ran out of band of Chef. Tests should be designed to
ensure that a recipe has accomplished its goal.

## Integration Testing using Vagrant

Integration tests can be performed on a local workstation using
Virtualbox or VMWare. Detailed instructions for setting this up can be
found at the [Bento](https://github.com/opscode/bento) project web site.

Integration tests using Vagrant can be performed with either
```
bundle exec kitchen test
```
or
```
rake integration:kitchen:all
```

## Fixtures

A sample cookbook is available in `fixtures`. You can package it with mkartifact.sh, and
upload it to Nexus as artifact_cookbook:test:1.2.3:tgz.

Set the artifact_test_location and artifact_test_version environment variables when running
vagrant to change how they'll be provisioned. Default is 1.2.3 from a file URL.

* artifact_test_location=artifact_cookbook:test:1.2.3:tgz artifact_test_version=1.2.3 bundle exec vagrant
