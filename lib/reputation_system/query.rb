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
  module Query
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      DELTA = 0.000001

      def find_with_reputation(*args)
        reputation_name, srn, find_scope, options = parse_query_args(*args)
        options[:select] ||= sanitize_sql_array(["%s.*", self.table_name])
        options[:select] = sanitize_sql_array(["%s, COALESCE(rs_reputations.value, 0) AS %s", options[:select], reputation_name])
        find_options = get_find_options(srn, options)
        find_options[:conditions][0].gsub!(reputation_name.to_s, "COALESCE(rs_reputations.value, 0)")
        find(find_scope, find_options)
      end

      def count_with_reputation(*args)
        reputation_name, srn, find_scope, options = parse_query_args(*args)
        find_options = get_find_options(srn, options)
        find_options[:conditions][0].gsub!(reputation_name.to_s, "COALESCE(rs_reputations.value, 0)")
        count(find_scope, find_options)
      end

      def find_with_normalized_reputation(*args)
        reputation_name, srn, find_scope, options = parse_query_args(*args)
        max = RSReputation.max(srn, self.name)
        min = RSReputation.min(srn, self.name)
        range = max - min
        options[:select] ||= sanitize_sql_array(["%s.*", self.table_name])
        if range < DELTA
          options[:select] = sanitize_sql_array(["%s, (0) AS normalized_%s", options[:select], reputation_name])
        else
          options[:select] = sanitize_sql_array(["%s, ((rs_reputations.value - %s) / %s) AS normalized_%s", options[:select], min, range, reputation_name])
        end
        find_options = get_find_options(srn, options)
        find(find_scope, options)
      end

      def find_with_reputation_sql(*args)
        reputation_name, srn, find_scope, options = parse_query_args(*args)
        options[:select] ||= sanitize_sql_array(["%s.*", self.table_name])
        options[:select] = sanitize_sql_array(["%s, COALESCE(rs_reputations.value, 0) AS %s", options[:select], reputation_name])
        find_options = get_find_options(srn, options)
        if respond_to?(:construct_finder_sql, true)
          construct_finder_sql(find_options)
        else
          construct_finder_arel(find_options).to_sql
        end
      end

      protected
        def get_find_options(srn, options)
          options[:joins] ||= []
          options[:joins] = [options[:joins]] unless options[:joins].is_a? Array
          temp_joins = sanitize_sql_array(["LEFT JOIN rs_reputations ON %s.id = rs_reputations.target_id AND rs_reputations.target_type = ? AND rs_reputations.reputation_name = ? AND rs_reputations.active = ?", self.name, srn.to_s, true])
          temp_joins = sanitize_sql_array([temp_joins, self.table_name])
          options[:joins] << temp_joins
          options[:conditions] ||= [""]
          options[:conditions] = [options[:conditions]] unless options[:conditions].is_a? Array
          options
        end

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
