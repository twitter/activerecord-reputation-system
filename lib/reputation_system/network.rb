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
  class Network
    class << self
      def has_reputation_for?(class_name, reputation_name)
        reputation_def = get_reputation_def(class_name, reputation_name)
        !!reputation_def[:source]
      end

      def get_reputation_defs(class_name)
        network[class_name.to_sym] ||= {}
      end

      def get_reputation_def(class_name, reputation_name)
        reputation_def = {}
        unless class_name == "ActiveRecord::Base"
          reputation_defs = get_reputation_defs(class_name)
          reputation_defs[reputation_name.to_sym] ||= {}
          reputation_def = reputation_defs[reputation_name.to_sym]
          if reputation_def == {}
            begin
              # This recursion finds reputation definition in the ancestor in case of STI.
              klass = class_name.constantize.superclass
              reputation_def = get_reputation_def(klass.name, reputation_name) if klass
            rescue NameError
              # Class might have not been initialized yet at this point.
            end
          end
        end
        reputation_def
      end

      def add_reputation_def(class_name, reputation_name, options)
        reputation_defs = get_reputation_defs(class_name)
        options[:source] = convert_to_array_if_hash(options[:source])
        options[:source_of] ||= []
        options[:source_of] = convert_to_array_if_hash(options[:source_of])
        options[:aggregated_by] = options[:aggregated_by] || :sum
        assign_self_as_default_value_for_of_attr(options[:source])
        assign_self_as_default_value_for_of_attr(options[:source_of])
        reputation_defs[reputation_name] = options
        options[:source].each do |s|
          src_class_name = derive_class_name_from_attribute(class_name, s[:of])
          if has_reputation_for?(src_class_name, s[:reputation])
            derive_source_of_from_source(class_name, reputation_name, s, src_class_name)
          else
            # Because the source class might not have been initialized at this time.
            derive_source_of_from_source_later(class_name, reputation_name, s, src_class_name)
          end
        end unless is_primary_reputation?(class_name, reputation_name)
        perform_derive_later(class_name, reputation_name)
        construct_scoped_reputation_options(class_name, reputation_name, options)
      end

      def remove_reputation_def(class_name, reputation_name)
        reputation_defs = get_reputation_defs(class_name)
        reputation_defs.delete(reputation_name.to_sym)
      end

      def is_primary_reputation?(class_name, reputation_name)
        options = get_reputation_def(class_name, reputation_name)
        options[:source].is_a?(Symbol)
      end

      def add_scope_for(class_name, reputation_name, scope)
        options = get_reputation_def(class_name, reputation_name)
        if has_scope?(class_name, reputation_name, scope)
          raise ArgumentError, "#{scope} is already defined for #{reputation_name}"
        else
          options[:scopes].push scope.to_sym if options[:scopes]
          create_scoped_reputation_def(class_name, reputation_name, scope, options)
        end
      end

      def has_scopes?(class_name, reputation_name)
        !get_reputation_def(class_name, reputation_name)[:scopes].nil?
      end

      def has_scope?(class_name, reputation_name, scope)
        scopes = get_reputation_def(class_name, reputation_name)[:scopes]
        scopes && scopes.include?(scope.to_sym)
      end

      def get_scoped_reputation_name(class_name, reputation_name, scope)
        raise ArgumentError, "#{reputation_name.to_s} is not defined for #{class_name}" unless has_reputation_for?(class_name, reputation_name)
        scope = scope.to_sym if scope
        validate_scope_necessity(class_name, reputation_name, scope)
        validate_scope_existence(class_name, reputation_name, scope)
        "#{reputation_name}#{"_#{scope}" if scope}"
      end

      def get_weight_of_source_from_reputation_name_of_target(target, source_name, reputation_name)
        source = get_reputation_def(target.class.name, reputation_name)[:source]
        if source.is_a?(Array)
          source.each do |s|
            srn = get_scoped_reputation_name_from_source_def_and_target(s, target)
            return s[:weight] if srn.to_sym == source_name.to_sym
          end
        else
          source[:weight]
        end
      end

      protected

        def network
          @network ||= {}
        end

        def data_for_derive_later
          @data_for_derive_later ||= {}
        end

        def create_scoped_reputation_def(class_name, reputation_name, scope, options)
          raise ArgumentError, "#{reputation_name} does not have scope." unless has_scopes?(class_name, reputation_name)
          scope_options = options.reject { |k, v| ![:source, :aggregated_by].include? k }
          reputation_def = get_reputation_def(class_name, reputation_name)
          unless is_primary_reputation?(class_name, reputation_name)
            scope_options[:source] = []
            reputation_def[:source].each { |sd| scope_options[:source].push create_source_reputation_def(sd, scope) }
          end
          (reputation_def[:source_of] || []).each do |so|
            if source_of_defined_for_scope?(so, scope)
              scope_options[:source_of] ||= []
              scope_options[:source_of].push so
            end
          end
          srn = get_scoped_reputation_name(class_name, reputation_name, scope)
          network[class_name.to_sym][srn.to_sym] = scope_options
        end

        def create_source_reputation_def(source_def, scope)
          rep = {}
          rep[:reputation] = source_def[:reputation]
          # Passing "this" is not pretty but in some case "instance_exec" method
          # does not give right context for some reason.
          # This could be ruby bug. Needs further investigation.
          if source_def[:of].is_a? Proc
            rep[:of] = lambda { |this| instance_exec(this, scope.to_s, &source_def[:of]) }
          else
            rep[:of] = source_def[:of]
          end
          rep
        end

        def get_scoped_reputation_name_from_source_def_and_target(source_def, target)
          scope = target.evaluate_reputation_scope(source_def[:scope]) if source_def[:scope]
          of = target.get_attributes_of(source_def)
          class_name = (of.is_a?(Array) ? of[0] : of).class.name
          get_scoped_reputation_name(class_name, source_def[:reputation], scope)
        end

        def source_of_defined_for_scope?(source_of_def, scope)
          defined_for_scope = source_of_def[:defined_for_scope]
          defined_for_scope.nil? || (defined_for_scope && defined_for_scope.include?(scope.to_sym))
        end

        def construct_scoped_reputation_options(class_name, reputation_name, options)
          scopes = get_reputation_def(class_name, reputation_name)[:scopes]
          scopes.each do |scope|
            create_scoped_reputation_def(class_name, reputation_name, scope, options)
          end if scopes
        end

        def derive_source_of_from_source(class_name, reputation_name, source, src_class_name)
          of_value = derive_of_value(class_name, source[:of], src_class_name)
          reputation_def = get_reputation_def(src_class_name, source[:reputation])
          reputation_def[:source_of] ||= []
          unless source_of_include_reputation?(reputation_def[:source_of], reputation_name)
            reputation_def[:source_of] << {:reputation => reputation_name.to_sym, :of => of_value.to_sym}
          end
        end

        def derive_of_value(class_name, source_of, src_class_name)
          if not_source_of_self?(source_of)
            attr = class_name.tableize
            class_has_attribute?(src_class_name, attr) ? attr :  attr.chomp('s')
          else
            "self"
          end
        end

        def not_source_of_self?(source_of)
          source_of && source_of.is_a?(Symbol) && source_of != :self
        end

        def class_has_attribute?(class_name, attribute)
          klass = class_name.to_s.constantize
          klass.instance_methods.include?(attribute.to_s) || klass.instance_methods.include?(attribute.to_sym)
        end

        def source_of_include_reputation?(source_of, reputation_name)
          source_of.map { |rep| rep[:reputation] }.include?(reputation_name.to_sym)
        end

        def derive_source_of_from_source_later(class_name, reputation_name, source, src_class_name)
          reputation = source[:reputation].to_sym
          src_class_name = src_class_name.to_sym
          data = data_for_derive_later
          data[src_class_name] ||= {}
          data[src_class_name][reputation] ||= {}
          data[src_class_name][reputation].merge!(:source => source, :class_name => class_name, :reputation_name => reputation_name)
        end

        def perform_derive_later(src_class_name, reputation)
          src_class_name = src_class_name.to_sym
          reputation = reputation.to_sym
          data = data_for_derive_later
          if data[src_class_name] && data[src_class_name][reputation]
            class_name = data[src_class_name][reputation][:class_name]
            source = data[src_class_name][reputation][:source]
            reputation_name = data[src_class_name][reputation][:reputation_name]
            derive_source_of_from_source(class_name, reputation_name, source, src_class_name)
            data[src_class_name].delete(reputation)
          end
        end

        def derive_class_name_from_attribute(class_name, attribute)
          if attribute && attribute != :self && attribute != "self"
            attribute.to_s.camelize.chomp('s')
          else
            class_name
          end
        end

        def convert_to_array_if_hash(tar)
          tar.is_a?(Hash) ? [tar] : tar
        end

        def assign_self_as_default_value_for_of_attr(tar)
          tar.each { |s| s[:of] = :self unless s[:of] } if tar.is_a? Array
        end

        def validate_scope_necessity(class_name, reputation_name, scope)
          if scope.nil? && has_scopes?(class_name, reputation_name)
            raise ArgumentError, "Evaluations of #{reputation_name} must have scope specified."
          end
        end

        def validate_scope_existence(class_name, reputation_name, scope)
          if !scope.nil? && !has_scope?(class_name, reputation_name, scope)
            raise ArgumentError, "#{reputation_name} does not have scope #{scope}"
          end
        end
    end
  end
end
