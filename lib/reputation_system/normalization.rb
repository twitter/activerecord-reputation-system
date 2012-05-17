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
  module Normalization
    def normalized_reputation_value_for(reputation_name, *args)
      scope = args.first
      if !self.class.has_reputation_for?(reputation_name)
        raise ArgumentError, "#{reputation_name} is not valid"
      else
        reputation_name = ReputationSystem::Network.get_scoped_reputation_name(self.class.name, reputation_name, scope)
        process = ReputationSystem::Network.get_reputation_def(self.class.name, reputation_name)[:aggregated_by]
        reputation = RSReputation.find_or_create_reputation(reputation_name, self, process)
        reputation.normalized_value
      end
    end

    def activate_all_reputations
      RSReputation.find(:all, :conditions => {:target_id => self.id, :target_type => self.class.name, :active => false}).each do |r|
        r.active = true
        r.save!
      end
    end

    def deactivate_all_reputations
      RSReputation.find(:all, :conditions => {:target_id => self.id, :target_type => self.class.name, :active => true}).each do |r|
        r.active = false
        r.save!
      end
    end

    def reputations_activated?(reputation_name)
      r = RSReputation.find(:first, :conditions => {:reputation_name => reputation_name.to_s, :target_id => self.id, :target_type => self.class.name})
      r ? r.active : false
    end
  end
end