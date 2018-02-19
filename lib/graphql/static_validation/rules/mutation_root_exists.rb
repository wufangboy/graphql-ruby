# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class MutationRootExists < StaticValidation::BaseRule
      include GraphQL::StaticValidation::Message::MessageHelper

      def on_operation_definition(ast_node, prev_ast_node)
        if context.warden.root_type_for_operation("mutation").nil? && ast_node.operation_type == 'mutation'
          context.errors << message('Schema is not configured for mutations', ast_node, context: context)
          return GraphQL::Language::Visitor::SKIP
        end
      end
    end
  end
end
