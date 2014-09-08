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
  module ScopeMethods
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def add_scope_for(reputation_name, scope)
        ReputationSystem::Network.add_scope_for(name, reputation_name, scope)
      end

      def has_scopes?(reputation_name)
        ReputationSystem::Network.has_scopes?(name, reputation_name, scope)
      end

      def has_scope?(reputation_name, scope)
        ReputationSystem::Network.has_scope?(name, reputation_name, scope)
      end
    end
  end
end
