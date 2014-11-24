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
  class ReputationMessage < ActiveRecord::Base
    self.table_name = 'rs_reputation_messages'
    belongs_to :sender, :polymorphic => true
    belongs_to :receiver, :class_name => 'ReputationSystem::Reputation'

    # The same sender cannot send massage to the same receiver more than once.
    validates_uniqueness_of :receiver_id, :scope => [:sender_id, :sender_type]
    validate :sender_must_be_evaluation_or_reputation

    after_destroy :delete_sender_if_evaluation

    def self.add_reputation_message_if_not_exist(sender, receiver)
      rm = create(:sender => sender, :receiver => receiver)
      receiver.received_messages.push rm if rm.valid?
    end

    protected

      def delete_sender_if_evaluation
        sender.destroy if sender.is_a?(ReputationSystem::Evaluation)
      end

      def sender_must_be_evaluation_or_reputation
        unless sender.is_a?(ReputationSystem::Evaluation) || sender.is_a?(ReputationSystem::Reputation)
          errors.add(:sender, "must be an evaluation or a reputation")
        end
      end

  end
end
