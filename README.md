# Artifact cookbook

Provides your cookbooks with the Artifact Deploy LWRP

# Requirements

* Chef 10

# Resources / Providers

## artifact_deploy

Deploys a collection of build artifacts packaged into a tar ball. Artifacts are extracted from
the package and managed in a deploy directory in the same fashion you've seen in the Opscode
deploy resource or Capistrano's default deploy strategy.

### Actions
Action  | Description                 | Default
------- |-------------                |---------
deploy  | Deploy the artifact package | Yes

### Attributes
Attribute           | Description                                                 |Type     | Default
---------           |-------------                                                |-----    |--------
artifact_name       | the ruby version and patch level you wish to install        | String  | name
artifact_url        | install even if this version is already present (reinstall) | String  |
deploy_to           |                                                             | String  |
version             |                                                             | String  |
owner               |                                                             | String  |
group               |                                                             | String  |
environment         |                                                             | Hash    | Hash.new
symlinks            |                                                             | Hash    | { "system" => "public/system", "pids" => "tmp/pids", "log" => "log" }
shared_directories  |                                                             | Array   | %w{ log pids }
before_migrate      |                                                             | Proc    |
after_migrate       |                                                             | Proc    |
migrate             |                                                             | Proc    |
restart_proc        |                                                             | Proc    |
force               |                                                             | Boolean | false
should_migrate      |                                                             | Boolean | false
keep                |                                                             | Integer | 2

### Examples

##### Deploying a Rails application

    artifact_deploy "pvpnet" do
      version "1.0.0"
      artifact_url "https://artifacts.riotgames.com/pvpnet-1.0.0.tar.gz"
      deploy_to "/srv/pvpnet"
      owner "riot"
      group "riot"
      environment { 'RAILS_ENV' => 'production' }
      shared_directories %w{ data log pids system vendor_bundle assets }

      before_migrate Proc.new {
        template "#{shared_path}/database.yml" do
          source "database.yml.erb"
          owner node[:merlin][:owner]
          group node[:merlin][:group]
          mode "0644"
          variables(
            :environment => environment,
            :options => database_options
          )
        end
        
        execute "bundle install --local --path=vendor/bundle --without test development cucumber --binstubs" do
          environment { 'RAILS_ENV' => 'production' }
          user "riot"
          group "riot"
        end
      }

      migrate Proc.new {
        execute "bundle exec rake db:migrate" do
          environment { 'RAILS_ENV' => 'production' }
          user "riot"
          group "riot"
        end
      }

      after_migrate Proc.new {
        ruby_block "remove_run_migrations" do
          block do
            Chef::Log.info("Migrations were run, removing role[pvpnet_run_migrations]")
            node.run_list.remove("role[pvpnet_run_migrations]")
          end
        end
      }

      restart_proc Proc.new {
        bluepill_service 'pvpnet-unicorn' do 
          action :restart
        end
      }

      keep 2
      should_migrate true(node[:pvpnet][:should_migrate] ? true : false)
      force (node[:pvpnet][:force_deploy] ? true : false)
      action :deploy
    end


# License and Author

Author:: Jamie Winsor (<jamie@vialstudios.com>)

Copyright 2012, Riot Games

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
