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

module ReputationSystem
  module QueryMethods
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def with_reputation(*args)
        warn "[DEPRECATION] `with_reputation` will be deprecated in version 3.0.0. Please use finder methods instead."
        reputation_name, srn = parse_arel_query_args(args)
        select = build_select_statement(table_name, reputation_name)
        joins = build_join_statement(table_name, name, srn)
        self.select(select).joins(joins)
      end

      def with_reputation_only(*args)
        warn "[DEPRECATION] `with_reputation_only` will be deprecated in version 3.0.0. Please use finder methods instead."
        reputation_name, srn = parse_arel_query_args(args)
        select = build_select_statement_with_reputation_only(table_name, reputation_name)
        joins = build_join_statement(table_name, name, srn)
        self.select(select).joins(joins)
      end

      def with_normalized_reputation(*args)
        warn "[DEPRECATION] `with_normalized_reputation` will be deprecated in version 3.0.0. Please use finder methods instead."
        reputation_name, srn = parse_arel_query_args(args)
        select = build_select_statement(table_name, reputation_name, nil, srn, true)
        joins = build_join_statement(table_name, name, srn)
        self.select(select).joins(joins)
      end

      def with_normalized_reputation_only(*args)
        warn "[DEPRECATION] `with_normalized_reputation_only` will be deprecated in version 3.0.0. Please use finder methods instead."
        reputation_name, srn = parse_arel_query_args(args)
        select = build_select_statement_with_reputation_only(table_name, reputation_name, srn, true)
        joins = build_join_statement(table_name, name, srn)
        self.select(select).joins(joins)
      end

      protected

        def parse_arel_query_args(args)
          reputation_name = args[0]
          srn = ReputationSystem::Network.get_scoped_reputation_name(name, reputation_name, args[1])
          [reputation_name, srn]
        end
    end
  end
end
