module Citrus
  module Core
    class World

      attr_reader :root

      def initialize(root)
        @root = root
      end

      def cache_root
        File.join(root, 'cache')
      end

      def build_root
        File.join(root, 'builds')
      end

    end
  end
end
