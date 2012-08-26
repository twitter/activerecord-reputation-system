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

      def build_select_statement(table_name, reputation_name, select=nil, srn=nil, normalize=false)
        select = sanitize_sql_array(["%s.*", table_name]) unless select
        if normalize
          max = RSReputation.max(srn, self.name)
          min = RSReputation.min(srn, self.name)
          range = max - min
          if range < DELTA
            sanitize_sql_array(["%s, (0) AS normalized_%s", select, reputation_name])
          else
            sanitize_sql_array(["%s, ((rs_reputations.value - %s) / %s) AS normalized_%s", select, min, range, reputation_name])
          end
        else
          sanitize_sql_array(["%s, COALESCE(rs_reputations.value, 0) AS %s", select, reputation_name])
        end
      end

      def build_select_statement_with_reputation_only(table_name, reputation_name, srn=nil, normalize=false)
        if normalize
          max = RSReputation.max(srn, self.name)
          min = RSReputation.min(srn, self.name)
          range = max - min
          if range < DELTA
            sanitize_sql_array(["(0) AS normalized_%s", reputation_name])
          else
            sanitize_sql_array(["((rs_reputations.value - %s) / %s) AS normalized_%s", min, range, reputation_name])
          end
        else
          sanitize_sql_array(["COALESCE(rs_reputations.value, 0) AS %s", reputation_name])
        end
      end

      def build_condition_statement(conditions=nil)
        conditions ||= [""]
        conditions = [conditions] unless conditions.is_a? Array
        conditions
      end

      def build_join_statement(table_name, class_name, srn, joins=nil)
          joins ||= []
          joins = [joins] unless joins.is_a? Array
          rep_join = sanitize_sql_array([REPUTATION_JOIN_STATEMENT, class_name.to_s, srn.to_s, true])
          rep_join = sanitize_sql_array([rep_join, table_name])
          joins << rep_join
      end
    end
  end
end
