# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FragmentTypesExist < StaticValidation::BaseRule
      def validate_type_exists(ast_node, prev_ast_node)
        return unless ast_node.type
        type_name = ast_node.type.name
        type = context.warden.get_type(type_name)
        if type.nil?
          context.errors << message("No such type #{type_name}, so it can't be a fragment condition", ast_node, context: context)
          GraphQL::Language::Visitor::SKIP
        end
      end

      alias :on_fragment_definition :validate_type_exists
      alias :on_inline_fragment :validate_type_exists
    end
  end
end
