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
        joins(options[:joins]).select(options[:select]).where(options[:conditions]).send(find_scope)
      end

      def count_with_reputation(*args)
        reputation_name, srn, find_scope, options = parse_query_args(*args)
        options[:joins] = build_join_statement(table_name, name, srn, options[:joins])
        options[:conditions] = build_condition_statement(reputation_name, options[:conditions])
        options[:conditions][0].gsub!(reputation_name.to_s, "COALESCE(rs_reputations.value, 0)")
        joins(options[:joins]).select(options[:select]).where(options[:conditions]).send(find_scope).count
      end

      def find_with_normalized_reputation(*args)
        reputation_name, srn, find_scope, options = parse_query_args(*args)
        options[:select] = build_select_statement(table_name, reputation_name, options[:select], srn, true)
        options[:joins] = build_join_statement(table_name, name, srn, options[:joins])
        options[:conditions] = build_condition_statement(reputation_name, options[:conditions], srn, true)
        joins(options[:joins]).select(options[:select]).where(options[:conditions]).send(find_scope)
      end

      def find_with_reputation_sql(*args)
        reputation_name, srn, find_scope, options = parse_query_args(*args)
        options[:select] = build_select_statement(table_name, reputation_name, options[:select])
        options[:joins] = build_join_statement(table_name, name, srn, options[:joins])
        options[:conditions] = build_condition_statement(reputation_name, options[:conditions])
        if respond_to?(:construct_finder_sql, true)
          construct_finder_sql(options)
        elsif respond_to?(:construct_finder_arel, true)
          construct_finder_arel(options).to_sql
        else
          joins(options[:joins]).select(options[:select]).where(options[:conditions]).send(find_scope).to_sql
        end
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
