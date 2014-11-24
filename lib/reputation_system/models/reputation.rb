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
  class Reputation < ActiveRecord::Base
    self.table_name = 'rs_reputations'

    belongs_to :target, :polymorphic => true
    has_many :received_messages, :class_name => 'ReputationSystem::ReputationMessage', :foreign_key => :receiver_id, :dependent => :destroy do
      def from(sender)
        self.find_by_sender_id_and_sender_type(sender.id, sender.class.to_s)
      end
    end
    has_many :sent_messages, :as => :sender, :class_name => 'ReputationSystem::ReputationMessage', :dependent => :destroy

    before_validation :set_target_type_for_sti
    before_save :change_zero_value_in_case_of_product_process

    validates_uniqueness_of :reputation_name, :scope => [:target_id, :target_type]

    serialize :data, Hash

    def self.find_by_reputation_name_and_target(reputation_name, target)
      target_type = get_target_type_for_sti(target, reputation_name)
      ReputationSystem::Reputation.find_by_reputation_name_and_target_id_and_target_type(reputation_name.to_s, target.id, target_type)
    end

    # All external access to reputation should use this since they are created lazily.
    def self.find_or_create_reputation(reputation_name, target, process)
      rep = find_by_reputation_name_and_target(reputation_name, target)
      rep ? rep : create_reputation(reputation_name, target, process)
    end

    def self.create_reputation(reputation_name, target, process)
      create_options = {:reputation_name => reputation_name.to_s, :target_id => target.id,
                        :target_type => target.class.name, :aggregated_by => process.to_s}
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
        if source.target.respond_to?(process)
          rep.value = source.target.send(process, rep, source, weight)
        else
          raise ArgumentError, "#{process} process is not supported yet"
        end
      end
      save_succeeded = rep.save
      ReputationSystem::ReputationMessage.add_reputation_message_if_not_exist(source, rep)
      propagate_updated_reputation_value(rep, valueBeforeUpdate) if rep.target
      save_succeeded
    end

    def self.update_reputation_value_with_updated_source(rep, source, oldValue, newSize, weight, process)
      weight ||= 1 # weight is 1 by default.
      oldSize = rep.received_messages.size
      valueBeforeUpdate = oldSize > 0 ? rep.value : nil
      newValue = source.value
      if newSize == 0
        rep.value = process.to_sym == :product ? 1 : 0
      else
        case process.to_sym
        when :sum
          rep.value += (newValue - oldValue) * weight
        when :average
          rep.value = (rep.value * oldSize + (newValue - oldValue) * weight) / newSize
        when :product
          rep.value = (rep.value * newValue) / oldValue
        else
          if source.target.respond_to?(process)
            rep.value = source.target.send(process, rep, source, weight, oldValue, newSize)
          else
            raise ArgumentError, "#{process} process is not supported yet"
          end
        end
      end
      save_succeeded = rep.save
      propagate_updated_reputation_value(rep, valueBeforeUpdate) if rep.target
      save_succeeded
    end

    def normalized_value
      if self.active == 1 || self.active == true
        max = ReputationSystem::Reputation.max(self.reputation_name, self.target_type)
        min = ReputationSystem::Reputation.min(self.reputation_name, self.target_type)
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
        receiver_defs = ReputationSystem::Network.get_reputation_def(sender.target.class.name, sender.reputation_name)[:source_of]
        receiver_defs.each do |rd|
          targets = sender.target.get_attributes_of(rd)
          targets.each do |target|
            scope = sender.target.evaluate_reputation_scope(rd[:scope])
            send_reputation_message_to_receiver(rd[:reputation], sender, target, scope, oldValue)
          end
        end if receiver_defs
      end

      def self.send_reputation_message_to_receiver(reputation_name, sender, target, scope, oldValue)
        srn = ReputationSystem::Network.get_scoped_reputation_name(target.class.name, reputation_name, scope)
        process = ReputationSystem::Network.get_reputation_def(target.class.name, srn)[:aggregated_by]
        receiver = find_by_reputation_name_and_target(srn, target)
        if receiver
          weight = ReputationSystem::Network.get_weight_of_source_from_reputation_name_of_target(target, sender.reputation_name, srn)
          update_reputation_value(receiver, sender, weight, process, oldValue)
        # If r is new then value update will be done when it is initialized.
        else
          create_reputation(srn, target, process)
        end
      end

      def self.update_reputation_value(receiver, sender, weight, process, oldValue)
        unless oldValue
          update_reputation_value_with_new_source(receiver, sender, weight, process)
        else
          newSize = receiver.received_messages.size
          update_reputation_value_with_updated_source(receiver, sender, oldValue, newSize, weight, process)
        end
      end

      def self.update_reputation_if_source_exist(sd, st, receiver, process)
        scope = receiver.target.evaluate_reputation_scope(sd[:scope])
        srn = ReputationSystem::Network.get_scoped_reputation_name(st.class.name, sd[:reputation], scope)
        source = find_by_reputation_name_and_target(srn, st)
        if source
          update_reputation_value_with_new_source(receiver, source, sd[:weight], process)
          ReputationSystem::ReputationMessage.add_reputation_message_if_not_exist(source, receiver)
        end
      end

      def self.max(reputation_name, target_type)
        ReputationSystem::Reputation.where(:reputation_name => reputation_name.to_s, :target_type => target_type, :active => true).maximum(:value)
      end

      def self.min(reputation_name, target_type)
        ReputationSystem::Reputation.where(:reputation_name => reputation_name.to_s, :target_type => target_type, :active => true).minimum(:value)
      end

      def self.get_target_type_for_sti(target, reputation_name)
        target_class = target.class
        defs = ReputationSystem::Network.get_reputation_defs(target_class.name)[reputation_name.to_sym]
        while target_class && target_class.name != "ActiveRecord::Base" && defs && defs.empty?
          target_class = target_class.superclass
          defs = ReputationSystem::Network.get_reputation_defs(target_class.name)[reputation_name.to_sym]
        end
        target_class ? target_class.name : nil
      end

      def set_target_type_for_sti
        sti_target_type = self.class.get_target_type_for_sti(target, reputation_name)
        self.target_type = sti_target_type if sti_target_type
      end

      def change_zero_value_in_case_of_product_process
        self.value = 1 if self.value == 0 && self.aggregated_by == "product"
      end

      def remove_associated_messages
        ReputationSystem::ReputationMessage.delete_all(:sender_type => self.class.name, :sender_id => self.id)
        ReputationSystem::ReputationMessage.delete_all(:receiver_id => self.id)
      end
  end
end
