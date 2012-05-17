##
#  Copyright 2012 Twitter, Inc
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
##

require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

class ReputationSystemGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  desc "Creates migration files required by reputation system gem."

  self.source_paths << File.join(File.dirname(__FILE__), 'templates')

  def self.next_migration_number(path)
    ActiveRecord::Generators::Base.next_migration_number(path)
  end

  def create_migration_files
    migration_template 'create_reputation_system.rb', 'db/migrate/create_reputation_system.rb'
  end
end