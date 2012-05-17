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
  module Evaluation
    def add_evaluation(reputation_name, value, source, *args)
      raise ArgumentError, "#{reputation_name.to_s} is not defined for #{self.class.name}" unless ReputationSystem::Network.has_reputation_for?(self.class.name, reputation_name)
      scope = args.first
      srn = ReputationSystem::Network.get_scoped_reputation_name(self.class.name, reputation_name, scope)
      process = ReputationSystem::Network.get_reputation_def(self.class.name, srn)[:aggregated_by]
      evaluation = RSEvaluation.create_evaluation(srn, value, source, self)
      rep = RSReputation.find_or_create_reputation(srn, self, process)
      RSReputation.update_reputation_value_with_new_source(rep, evaluation, 1, process)
    end

    def update_evaluation(reputation_name, value, source, *args)
      raise ArgumentError, "#{reputation_name.to_s} is not defined for #{self.class.name}" unless ReputationSystem::Network.has_reputation_for?(self.class.name, reputation_name)
      scope = args.first
      srn = ReputationSystem::Network.get_scoped_reputation_name(self.class.name, reputation_name, scope)
      evaluation = RSEvaluation.find_by_reputation_name_and_source_and_target(srn, source, self)
      if evaluation.nil?
        raise ArgumentError, "Given instance of #{source.class.name} has not evaluated #{reputation_name} of the instance of #{self.class.name} yet."
      else
        oldValue = evaluation.value
        evaluation.value = value
        evaluation.save!
        process = ReputationSystem::Network.get_reputation_def(self.class.name, srn)[:aggregated_by]
        rep = RSReputation.find_by_reputation_name_and_target(srn, self)
        RSReputation.update_reputation_value_with_updated_source(rep, evaluation, oldValue, 1, process)
      end
    end

    def add_or_update_evaluation(reputation_name, value, source, *args)
      scope = args.first
      evaluation = RSEvaluation.find_by_reputation_name_and_source_and_target(reputation_name, source, self)
      if evaluation.nil?
        self.add_evaluation(reputation_name, value, source, scope)
      else
        self.update_evaluation(reputation_name, value, source, scope)
      end
    end

    def delete_evaluation(reputation_name, source, *args)
      raise ArgumentError, "#{reputation_name.to_s} is not defined for #{self.class.name}" unless ReputationSystem::Network.has_reputation_for?(self.class.name, reputation_name)
      scope = args.first
      srn = ReputationSystem::Network.get_scoped_reputation_name(self.class.name, reputation_name, scope)
      evaluation = RSEvaluation.find_by_reputation_name_and_source_and_target(srn, source, self)
      unless evaluation.nil?
        process = ReputationSystem::Network.get_reputation_def(self.class.name, srn)[:aggregated_by]
        oldValue = evaluation.value
        evaluation.value = process == :product ? 1 : 0
        rep = RSReputation.find_by_reputation_name_and_target(srn, self)
        RSReputation.update_reputation_value_with_updated_source(rep, evaluation, oldValue, 1, process)
        evaluation.destroy
      end
    end

    def delete_evaluation!(reputation_name, source, *args)
      raise ArgumentError, "#{reputation_name.to_s} is not defined for #{self.class.name}" unless ReputationSystem::Network.has_reputation_for?(self.class.name, reputation_name)
      scope = args.first
      srn = ReputationSystem::Network.get_scoped_reputation_name(self.class.name, reputation_name, scope)
      evaluation = RSEvaluation.find_by_reputation_name_and_source_and_target(srn, source, self)
      if evaluation.nil?
        raise ArgumentError, "Given instance of #{source.class.name} has not evaluated #{reputation_name} of the instance of #{self.class.name} yet."
      else
        process = ReputationSystem::Network.get_reputation_def(self.class.name, srn)[:aggregated_by]
        oldValue = evaluation.value
        evaluation.value = process == :product ? 1 : 0
        rep = RSReputation.find_by_reputation_name_and_target(srn, self)
        RSReputation.update_reputation_value_with_updated_source(rep, evaluation, oldValue, 1, process)
        evaluation.destroy
      end
    end
  end
end
