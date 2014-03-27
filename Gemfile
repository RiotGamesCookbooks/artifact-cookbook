source 'https://rubygems.org'

gem 'rake'

group :test do
  gem 'foodcritic', '~> 3.0'
  gem 'rubocop', '~> 0.19'
  gem 'chefspec', '~> 3.4.0'
  gem 'aws-sdk'
end

group :integration do
  gem 'berkshelf'
  gem 'test-kitchen', '~> 1.1'
  gem 'kitchen-vagrant', '~> 0.13'
end

group :releasing do
  gem 'stove'
end
