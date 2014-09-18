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
    create_migration_file_if_not_exist 'create_reputation_system'
    create_migration_file_if_not_exist 'add_reputations_index'
    create_migration_file_if_not_exist 'add_evaluations_index'
    create_migration_file_if_not_exist 'add_reputation_messages_index'
    create_migration_file_if_not_exist 'change_evaluations_index_to_unique'
    create_migration_file_if_not_exist 'change_reputation_messages_index_to_unique'
    create_migration_file_if_not_exist 'change_reputations_index_to_unique'
    create_migration_file_if_not_exist 'add_data_to_reputations'
    create_migration_file_if_not_exist 'add_data_to_evaluations'
  end

  private

    def create_migration_file_if_not_exist(file_name)
      unless self.class.migration_exists?(File.dirname(File.expand_path("db/migrate/#{file_name}")), file_name)
        migration_template "#{file_name}.rb", "db/migrate/#{file_name}.rb"
      end
    end
end
