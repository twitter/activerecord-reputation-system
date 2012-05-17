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

class RSEvaluation < ActiveRecord::Base
  belongs_to :source, :polymorphic => true
  belongs_to :target, :polymorphic => true
  has_one :sent_messages, :as => :sender, :class_name => 'RSReputationMessage', :dependent => :destroy

  attr_accessible :reputation_name, :value, :source, :source_id, :source_type, :target, :target_id, :target_type

  # the same source cannot evaluate the same target more than once.
  validates_uniqueness_of :source_id, :scope => [:reputation_name, :source_type, :target_id, :target_type]
  validate :source_must_be_defined_for_reputation_in_network

  def self.find_by_reputation_name_and_source_and_target(reputation_name, source, target)
    RSEvaluation.find(:first,
                      :conditions => {:reputation_name => reputation_name.to_s,
                                      :source_id => source.id,
                                      :source_type => source.class.name,
                                      :target_id => target.id,
                                      :target_type => target.class.name
                                      })
  end

  def self.create_evaluation(reputation_name, value, source, target)
    reputation_name = reputation_name.to_sym
    RSEvaluation.create!(:reputation_name => reputation_name.to_s, :value => value,
                         :source_id => source.id, :source_type => source.class.name,
                         :target_id => target.id, :target_type => target.class.name)
  end
   
  protected

    def source_must_be_defined_for_reputation_in_network
      unless source_type == ReputationSystem::Network.get_reputation_def(target_type, reputation_name)[:source].to_s.camelize
        errors.add(:source_type, "#{source_type} is not source of #{reputation_name} reputation")
      end
    end
end
