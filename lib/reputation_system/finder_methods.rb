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
module FinderMethods
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods

      def find_with_reputation(*args)
        reputation_name, srn, find_scope, options = parse_query_args(*args)
        options[:select] = build_select_statement(table_name, reputation_name, options[:select])
        options[:joins] = build_join_statement(table_name, name, srn, options[:joins])
        options[:conditions] = build_condition_statement(reputation_name, options[:conditions])
        find(find_scope, options)
      end

      def count_with_reputation(*args)
        reputation_name, srn, find_scope, options = parse_query_args(*args)
        options[:joins] = build_join_statement(table_name, name, srn, options[:joins])
        options[:conditions] = build_condition_statement(reputation_name, options[:conditions])
        options[:conditions][0].gsub!(reputation_name.to_s, "COALESCE(rs_reputations.value, 0)")
        count(find_scope, options)
      end

      def find_with_normalized_reputation(*args)
        reputation_name, srn, find_scope, options = parse_query_args(*args)
        options[:select] = build_select_statement(table_name, reputation_name, options[:select], srn, true)
        options[:joins] = build_join_statement(table_name, name, srn, options[:joins])
        options[:conditions] = build_condition_statement(reputation_name, options[:conditions], srn, true)
        find(find_scope, options)
      end

      def find_with_reputation_sql(*args)
        reputation_name, srn, find_scope, options = parse_query_args(*args)
        options[:select] = build_select_statement(table_name, reputation_name, options[:select])
        options[:joins] = build_join_statement(table_name, name, srn, options[:joins])
        options[:conditions] = build_condition_statement(reputation_name, options[:conditions])
        if respond_to?(:construct_finder_sql, true)
          construct_finder_sql(options)
        else
          construct_finder_arel(options).to_sql
        end
      end

      def scope_with_reputation(*args)
        reputation_name, srn, find_scope, options = parse_query_args(*args)
        select_query = build_select_statement(table_name, reputation_name, options[:select])
        joins_query = build_join_statement(table_name, name, srn, options[:joins])
        conditions_query = build_condition_statement(reputation_name, options[:conditions])
        select(select_query).joins(joins_query).where(conditions_query)
      end

      protected

        def parse_query_args(*args)
          case args.length
          when 2
            find_scope = args[1]
            options = {}
          when 3
            find_scope = args[1]
            options = args[2]
          when 4
            scope = args[1]
            find_scope = args[2]
            options = args[3]
          else
            raise ArgumentError, "Expecting 2, 3 or 4 arguments but got #{args.length}"
          end
          reputation_name = args[0]
          srn = ReputationSystem::Network.get_scoped_reputation_name(name, reputation_name, scope)
          [reputation_name, srn, find_scope, options]
        end
    end
  end
end
