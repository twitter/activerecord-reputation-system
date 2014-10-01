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
  module ReputationMethods
    def reputation_for(reputation_name, *args)
      find_reputation(reputation_name, args.first).value
    end

    def normalized_reputation_for(reputation_name, *args)
      find_reputation(reputation_name, args.first).normalized_value
    end

    def activate_all_reputations
      ReputationSystem::Reputation.where(:target_id => self.id, :target_type => self.class.name, :active => false).each do |r|
        r.active = true
        r.save!
      end
    end

    def deactivate_all_reputations
      ReputationSystem::Reputation.where(:target_id => self.id, :target_type => self.class.name, :active => true).each do |r|
        r.active = false
        r.save!
      end
    end

    def reputations_activated?(reputation_name)
      r = ReputationSystem::Reputation.where(:reputation_name => reputation_name.to_s, :target_id => self.id, :target_type => self.class.name).first
      r ? r.active : false
    end

    def rank_for(reputation_name, *args)
      scope = args.first
      my_value = self.reputation_for(reputation_name, scope)
      self.class.count_with_reputation(reputation_name, scope, :all,
        :conditions => ["rs_reputations.value > ?", my_value]
      ) + 1
    end

    protected
      def find_reputation(reputation_name, scope)
        raise ArgumentError, "#{reputation_name} is not valid" if !self.class.has_reputation_for?(reputation_name)
        srn = ReputationSystem::Network.get_scoped_reputation_name(self.class.name, reputation_name, scope)
        process = ReputationSystem::Network.get_reputation_def(self.class.name, srn)[:aggregated_by]
        ReputationSystem::Reputation.find_or_create_reputation(srn, self, process)
      end
  end
end
