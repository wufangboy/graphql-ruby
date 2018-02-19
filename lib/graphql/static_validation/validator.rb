# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Initialized with a {GraphQL::Schema}, then it can validate {GraphQL::Language::Nodes::Documents}s based on that schema.
    #
    # By default, it's used by {GraphQL::Query}
    #
    # @example Validate a query
    #   validator = GraphQL::StaticValidation::Validator.new(schema: MySchema)
    #   query = GraphQL::Query.new(MySchema, query_string)
    #   errors = validator.validate(query)[:errors]
    #
    class Validator
      # @param schema [GraphQL::Schema]
      # @param rules [Array<#validate(context)>] a list of rules to use when validating
      def initialize(schema:, rules: GraphQL::StaticValidation::ALL_RULES)
        @schema = schema
        @rules = rules
      end

      VISIT_METHODS = {
        on_operation_definition: GraphQL::Language::Nodes::OperationDefinition,
        on_fragment_definition: GraphQL::Language::Nodes::FragmentDefinition,
        on_inline_fragment: GraphQL::Language::Nodes::InlineFragment,
      }

      # Validate `query` against the schema. Returns an array of message hashes.
      # @param query [GraphQL::Query]
      # @return [Array<Hash>]
      def validate(query, validate: true)
        query.trace("validate", { validate: validate, query: query }) do
          context = GraphQL::StaticValidation::ValidationContext.new(query)
          rewrite = GraphQL::InternalRepresentation::Rewrite.new
          visitor = context.visitor

          # Put this first so its enters and exits are always called
          rewrite.validate(context)

          # If the caller opted out of validation, don't attach these
          if validate
            @rules.each do |rule_class|
              if rule_class.method_defined?(:validate)
                rule_class.new.validate(context)
              else
                rule = rule_class.new(context)
                # TODO couldn't this be done ahead-of-time somehow
                VISIT_METHODS.each do |method_name, node_class|
                  if rule.respond_to?(method_name)
                    visitor[node_class] << rule.method(method_name)
                  end
                end
              end
            end
          end

          context.visitor.visit
          # Post-validation: allow validators to register handlers on rewritten query nodes
          rewrite_result = rewrite.document
          GraphQL::InternalRepresentation::Visit.visit_each_node(rewrite_result.operation_definitions, context.each_irep_node_handlers)

          {
            errors: context.errors,
            # If there were errors, the irep is garbage
            irep: context.errors.any? ? nil : rewrite_result,
          }
        end
      end
    end
  end
end
