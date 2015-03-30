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
  module EvaluationMethods
    module ClassMethods
      def evaluated_by(reputation_name, source, *args)
        scope = args.first
        srn = ReputationSystem::Network.get_scoped_reputation_name(self.name, reputation_name, scope)
        source_type = source.class.name
        options = {}
        options[:select] ||= sanitize_sql_array(["%s.*", self.table_name])
        options[:joins] = sanitize_sql_array(["JOIN rs_evaluations ON %s.id = rs_evaluations.target_id AND rs_evaluations.target_type = ? AND rs_evaluations.reputation_name = ? AND rs_evaluations.source_id = ? AND rs_evaluations.source_type = ?", self.name, srn.to_s, source.id, source_type])
        options[:joins] = sanitize_sql_array([options[:joins], self.table_name])
        joins(options[:joins]).select(options[:select])
      end
    end

    def self.included(klass)
      klass.extend ClassMethods
    end

    def has_evaluation?(reputation_name, source, *args)
      scope = args.first
      srn = ReputationSystem::Network.get_scoped_reputation_name(self.class.name, reputation_name, scope)
      !!ReputationSystem::Evaluation.find_by_reputation_name_and_source_and_target(srn, source, self)
    end

    def evaluation_by(reputation_name, source, *args)
      srn, evaluation = find_srn_and_evaluation(reputation_name, source, args.first)
      evaluation ? evaluation.value : nil
    end

    def evaluators_for(reputation_name, *args)
      scope = args.first
      srn = ReputationSystem::Network.get_scoped_reputation_name(self.class.name, reputation_name, scope)
      self.evaluations.for(srn).includes(:source).map(&:source)
    end

    def add_evaluation(reputation_name, value, source, *args)
      scope = args.first
      srn = ReputationSystem::Network.get_scoped_reputation_name(self.class.name, reputation_name, scope)
      process = ReputationSystem::Network.get_reputation_def(self.class.name, srn)[:aggregated_by]
      evaluation = ReputationSystem::Evaluation.create_evaluation(srn, value, source, self)
      rep = ReputationSystem::Reputation.find_or_create_reputation(srn, self, process)
      ReputationSystem::Reputation.update_reputation_value_with_new_source(rep, evaluation, 1, process)
    end

    def update_evaluation(reputation_name, value, source, *args)
      srn, evaluation = find_srn_and_evaluation!(reputation_name, source, args.first)
      oldValue = evaluation.value
      evaluation.value = value
      evaluation.save!
      process = ReputationSystem::Network.get_reputation_def(self.class.name, srn)[:aggregated_by]
      rep = ReputationSystem::Reputation.find_by_reputation_name_and_target(srn, self)
      newSize = rep.received_messages.size
      ReputationSystem::Reputation.update_reputation_value_with_updated_source(rep, evaluation, oldValue, newSize, 1, process)
    end

    def add_or_update_evaluation(reputation_name, value, source, *args)
      srn, evaluation = find_srn_and_evaluation(reputation_name, source, args.first)
      if ReputationSystem::Evaluation.exists? :reputation_name => srn, :source_id => source.id, :source_type => source.class.name, :target_id => self.id, :target_type => self.class.name
        self.update_evaluation(reputation_name, value, source, *args)
      else
        self.add_evaluation(reputation_name, value, source, *args)
      end
    end

    def add_or_delete_evaluation(reputation_name, value, source, *args)
      srn, evaluation = find_srn_and_evaluation(reputation_name, source, args.first)
      if ReputationSystem::Evaluation.exists? :reputation_name => srn, :source_id => source.id, :source_type => source.class.name, :target_id => self.id, :target_type => self.class.name
        !!delete_evaluation_without_validation(srn, evaluation)
      else
        self.add_evaluation(reputation_name, value, source, *args)
      end
    end

    def delete_evaluation(reputation_name, source, *args)
      srn, evaluation = find_srn_and_evaluation(reputation_name, source, args.first)
      if evaluation
        !!delete_evaluation_without_validation(srn, evaluation)
      else
        false
      end
    end

    def delete_evaluation!(reputation_name, source, *args)
      srn, evaluation = find_srn_and_evaluation!(reputation_name, source, args.first)
      delete_evaluation_without_validation(srn, evaluation)
    end

    def increase_evaluation(reputation_name, value, source, *args)
      change_evaluation_value_by(reputation_name, value, source, *args)
    end

    def decrease_evaluation(reputation_name, value, source, *args)
      change_evaluation_value_by(reputation_name, -value, source, *args)
    end

    protected
      def find_srn_and_evaluation(reputation_name, source, scope)
        srn = ReputationSystem::Network.get_scoped_reputation_name(self.class.name, reputation_name, scope)
        evaluation = ReputationSystem::Evaluation.find_by_reputation_name_and_source_and_target(srn, source, self)
        return srn, evaluation
      end

      def find_srn_and_evaluation!(reputation_name, source, scope)
        srn = ReputationSystem::Network.get_scoped_reputation_name(self.class.name, reputation_name, scope)
        evaluation = find_evaluation!(reputation_name, srn, source)
        return srn, evaluation
      end

      def find_evaluation!(reputation_name, srn, source)
        evaluation = ReputationSystem::Evaluation.find_by_reputation_name_and_source_and_target(srn, source, self)
        raise ArgumentError, "Given instance of #{source.class.name} has not evaluated #{reputation_name} of the instance of #{self.class.name} yet." unless evaluation
        evaluation
      end

      def delete_evaluation_without_validation(srn, evaluation)
        process = ReputationSystem::Network.get_reputation_def(self.class.name, srn)[:aggregated_by]
        oldValue = evaluation.value
        evaluation.value = process == :product ? 1 : 0
        rep = ReputationSystem::Reputation.find_by_reputation_name_and_target(srn, self)
        newSize = rep.received_messages.size - 1
        ReputationSystem::Reputation.update_reputation_value_with_updated_source(rep, evaluation, oldValue, newSize, 1, process)
        evaluation.destroy
      end

      def change_evaluation_value_by(reputation_name, value, source, *args)
        scope = args.first
        srn = ReputationSystem::Network.get_scoped_reputation_name(self.class.name, reputation_name, scope)
        evaluation = ReputationSystem::Evaluation.find_by_reputation_name_and_source_and_target(srn, source, self)
        if evaluation.nil?
          self.add_evaluation(reputation_name, value, source, scope)
        else
          new_value = evaluation.value + value
          self.update_evaluation(reputation_name, new_value, source, scope)
        end
      end
  end
end
