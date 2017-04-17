source 'https://rubygems.org'

gem 'cookbook-development', :git => 'https://github.com/RallySoftware-cookbooks/cookbook-development'
gem 'minitest'
gem 'rake'

group :test do
  gem 'foodcritic'
  gem 'rubocop'
  gem 'chefspec'
  gem 'aws-sdk'
end

group :integration do
  gem 'berkshelf'
  gem 'test-kitchen'
  gem 'kitchen-vagrant'
end

group :releasing do
  gem 'stove'
end
