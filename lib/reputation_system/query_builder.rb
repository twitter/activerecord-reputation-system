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
  module QueryBuilder
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      DELTA = 0.000001
      REPUTATION_JOIN_STATEMENT = "LEFT JOIN rs_reputations ON %s.id = rs_reputations.target_id AND rs_reputations.target_type = ? AND rs_reputations.reputation_name = ? AND rs_reputations.active = ?"
      REPUTATION_FIELD_STRING = "COALESCE(rs_reputations.value, 0)" 

      def build_select_statement(table_name, reputation_name, select=nil, srn=nil, normalize=false)
        select = sanitize_sql_array(["%s.*", table_name]) unless select
        if normalize
          sanitize_sql_array(["%s, %s AS normalized_%s", select, normalized_field_string(srn), reputation_name.to_s])
        else
          sanitize_sql_array(["%s, %s AS %s", select, REPUTATION_FIELD_STRING, reputation_name.to_s])
        end
      end

      def build_select_statement_with_reputation_only(table_name, reputation_name, srn=nil, normalize=false)
        if normalize
          sanitize_sql_array(["%s AS normalized_%s", normalized_field_string(srn), reputation_name.to_s])
        else
          sanitize_sql_array(["%s AS %s", REPUTATION_FIELD_STRING, reputation_name.to_s])
        end
      end

      def build_condition_statement(reputation_name, conditions=nil, srn=nil, normalize=false)
        conditions ||= [""]
        conditions = [conditions] unless conditions.is_a? Array
        if normalize
          normalized_reputation_name = sanitize_sql_array(["normalized_%s", reputation_name.to_s])
          conditions[0] = conditions[0].gsub(normalized_reputation_name, normalized_field_string(srn))
        end
        conditions[0] = conditions[0].gsub(reputation_name.to_s, REPUTATION_FIELD_STRING)
        conditions
      end

      def build_join_statement(table_name, class_name, srn, joins=nil)
          joins ||= []
          joins = [joins] unless joins.is_a? Array
          rep_join = sanitize_sql_array([REPUTATION_JOIN_STATEMENT, class_name.to_s, srn.to_s, true])
          rep_join = sanitize_sql_array([rep_join, table_name])
          joins << rep_join
      end

      protected

      def normalized_field_string(srn)
        max = ReputationSystem::Reputation.max(srn, self.name)
        min = ReputationSystem::Reputation.min(srn, self.name)
        range = max - min
        if range < DELTA
          "(0)"
        else
          sanitize_sql_array(["((rs_reputations.value - %s) / %s)", min, range])
        end
      end
    end
  end
end
