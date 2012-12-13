#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'fileutils'
include FileUtils


fixtures = File.dirname(__FILE__)

cd(fixtures)
mkdir_p 'databags/artifact'

nexus_cli = File.expand_path "~/.nexus_cli"

if File.exist?(nexus_cli)
  nexus_config = YAML.load(File.open(nexus_cli))
  databag = {
    "id" => "nexus",
    "*" => {
      "username" => nexus_config['username'],
      "password" => nexus_config['password'],
      "url" => nexus_config['url'],
      "repository" => nexus_config['repository']
    }
  }
  File.open('databags/artifact/nexus.json','w') { |f| f.puts(JSON.pretty_generate(databag)) }
else
  puts 'No ~/.nexus_cli found. Create fixtures/databags/artifact/nexus.json manually'
end
