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

class RSReputation < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  has_many :received_messages, :class_name => 'RSReputationMessage', :foreign_key => :receiver_id, :dependent => :destroy do
    def from(sender)
      self.find_by_sender_id_and_sender_type(sender.id, sender.class.to_s)
    end
  end
  has_many :sent_messages, :as => :sender, :class_name => 'RSReputationMessage', :dependent => :destroy

  attr_accessible :reputation_name, :value, :aggregated_by, :active, :target, :target_id, :target_type, :received_messages

  before_save :change_zero_value_in_case_of_product_process

  VALID_PROCESSES = ['sum', 'average', 'product']
  validates_inclusion_of :aggregated_by, :in => VALID_PROCESSES, :message => "Value chosen for aggregated_by is not valid process"
  validates_uniqueness_of :reputation_name, :scope => [:target_id, :target_type]

  def self.find_by_reputation_name_and_target(reputation_name, target)
    RSReputation.find_by_reputation_name_and_target_id_and_target_type(reputation_name.to_s, target.id, target.class.name)
  end

  # All external access to reputation should use this since they are created lazily.
  def self.find_or_create_reputation(reputation_name, target, process)
    rep = find_by_reputation_name_and_target(reputation_name, target)
    rep ? rep : create_reputation(reputation_name, target, process)
  end

  def self.create_reputation(reputation_name, target, process)
    create_options = {:reputation_name => reputation_name.to_s, :target_id => target.id,
                      :target_type => target.class.name, :aggregated_by => process.to_s}
    default_value = ReputationSystem::Network.get_reputation_def(target.class.name, reputation_name)[:init_value]
    create_options.merge!(:value => default_value) if default_value
    rep = create(create_options)
    initialize_reputation_value(rep, target, process)
  end

  def self.update_reputation_value_with_new_source(rep, source, weight, process)
    weight ||= 1 # weight is 1 by default.
    size = rep.received_messages.size
    valueBeforeUpdate = size > 0 ? rep.value : nil
    newValue = source.value
    case process.to_sym
    when :sum
      rep.value += (newValue * weight)
    when :average
      rep.value = (rep.value * size + newValue * weight) / (size + 1)
    when :product
      rep.value *= (newValue * weight)
    else
      raise ArgumentError, "#{process} process is not supported yet"
    end
    rep.save!
    RSReputationMessage.add_reputation_message_if_not_exist(source, rep)
    propagate_updated_reputation_value(rep, valueBeforeUpdate) if rep.target
  end

  def self.update_reputation_value_with_updated_source(rep, source, oldValue, weight, process)
    weight ||= 1 # weight is 1 by default.
    size = rep.received_messages.size
    valueBeforeUpdate = size > 0 ? rep.value : nil
    newValue = source.value
    case process.to_sym
    when :sum
      rep.value += (newValue - oldValue) * weight
    when :average
      rep.value += ((newValue - oldValue) * weight) / size
    when :product
      rep.value = (rep.value * newValue) / oldValue
    else
      raise ArgumentError, "#{process} process is not supported yet"
    end
    rep.save!
    propagate_updated_reputation_value(rep, valueBeforeUpdate) if rep.target
  end

  def normalized_value
    if self.active == 1 || self.active == true
      max = RSReputation.max(self.reputation_name, self.target_type)
      min = RSReputation.min(self.reputation_name, self.target_type)
      if max && min
        range = max - min
        range == 0 ? 0 : (self.value - min) / range
      else
        0
      end
    else
      0
    end
  end

  protected

    # Updates reputation value for new reputation if its source already exist.
    def self.initialize_reputation_value(receiver, target, process)
      name = receiver.reputation_name
      unless ReputationSystem::Network.is_primary_reputation?(target.class.name, name)
        sender_defs = ReputationSystem::Network.get_reputation_def(target.class.name, name)[:source]
        sender_defs.each do |sd|
          sender_targets = target.get_attributes_of(sd)
          sender_targets.each do |st|
            update_reputation_if_source_exist(sd, st, receiver, process) if receiver.target
          end
        end
      end
      receiver
    end

    # Propagates updated reputation value to the reputations whose source is the updated reputation.
    def self.propagate_updated_reputation_value(sender, oldValue)
      sender_name = sender.reputation_name.to_sym
      receiver_defs = ReputationSystem::Network.get_reputation_def(sender.target.class.name, sender_name)[:source_of]
      if receiver_defs
        receiver_defs.each do |rd|
          receiver_targets = sender.target.get_attributes_of(rd)
          receiver_targets.each do |rt|
            scope = sender.target.evaluate_reputation_scope(rd[:scope])
            srn = ReputationSystem::Network.get_scoped_reputation_name(rt.class.name, rd[:reputation], scope)
            process = ReputationSystem::Network.get_reputation_def(rt.class.name, srn)[:aggregated_by]
            rep = find_by_reputation_name_and_target(srn, rt)
            if rep
              weight = ReputationSystem::Network.get_weight_of_source_from_reputation_name_of_target(rt, sender_name, srn)
              unless oldValue
                update_reputation_value_with_new_source(rep, sender, weight, process)
              else
                update_reputation_value_with_updated_source(rep, sender, oldValue, weight, process)
              end
            # If r is new then value update will be done when it is initialized.
            else
              create_reputation(srn, rt, process)
            end
          end
        end
      end
    end

    def self.update_reputation_if_source_exist(sd, st, receiver, process)
      scope = receiver.target.evaluate_reputation_scope(sd[:scope])
      srn = ReputationSystem::Network.get_scoped_reputation_name(st.class.name, sd[:reputation], scope)
      source = find_by_reputation_name_and_target(srn, st)
      if source
        update_reputation_value_with_new_source(receiver, source, sd[:weight], process)
        RSReputationMessage.add_reputation_message_if_not_exist(source, receiver)
      end
    end

    def self.max(reputation_name, target_type)
      RSReputation.maximum(:value,
                           :conditions => {:reputation_name => reputation_name.to_s, :target_type => target_type, :active => true})
    end

    def self.min(reputation_name, target_type)
      RSReputation.minimum(:value,
                           :conditions => {:reputation_name => reputation_name.to_s, :target_type => target_type, :active => true})
    end

    def change_zero_value_in_case_of_product_process
      self.value = 1 if self.value == 0 && self.aggregated_by == "product"
    end

    def remove_associated_messages
      RSReputationMessage.delete_all(:sender_type => self.class.name, :sender_id => self.id)
      RSReputationMessage.delete_all(:receiver_id => self.id)
    end
end
