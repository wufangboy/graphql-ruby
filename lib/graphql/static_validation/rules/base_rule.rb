# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class BaseRule
      include GraphQL::StaticValidation::Message::MessageHelper

      def initialize(context)
        @context = context
      end

      attr_reader :context
    end
  end
end
