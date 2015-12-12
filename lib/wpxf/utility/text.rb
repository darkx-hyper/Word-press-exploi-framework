module Wpxf
  module Utility
    # Provides helper methods for text based operations.
    module Text
      # Generate a random numeric string.
      # @param length [Integer] the number of characters to include.
      # @return [String] a random numeric string.
      def self.rand_numeric(length)
        Array.new(length) { [*'0'..'9'].sample }.join
      end

      # Generate a random alphanumeric string.
      # @param length [Integer] the number of characters to include.
      # @param casing [Symbol] the casing to use for the alpha characters.
      #   Possible values are :mixed, :upper and :lower.
      # @return [String] a random alphanumeric string.
      def self.rand_alphanumeric(length, casing = :mixed)
        range = [*'0'..'9'] + alpha_ranges(casing)
        Array.new(length) { range.sample }.join
      end

      # Generate a random alpha string.
      # @param length [Integer] the number of characters to include.
      # @param casing [Symbol] the casing to use for the alpha characters.
      #   Possible values are :mixed, :upper and :lower.
      # @return [String] a random alpha string.
      def self.rand_alpha(length, casing = :mixed)
        Array.new(length) { alpha_ranges(casing).sample }.join
      end

      # @param casing [Symbol] the casing to use for the alpha characters.
      #   Possible values are :mixed, :upper and :lower.
      # @return [Array] an alpha range for use with the rand_* methods.
      def self.alpha_ranges(casing)
        if casing == :mixed
          return [*'A'..'Z', *'a'..'z']
        elsif casing == :upper
          return [*'A'..'Z']
        elsif casing == :lower
          return [*'a'..'z']
        end
      end
    end
  end
end