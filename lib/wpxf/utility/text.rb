# frozen_string_literal: true

require 'digest'

module Wpxf
  module Utility
    # Provides helper methods for text based operations.
    module Text
      # Generate a random numeric string.
      # @param length [Integer] the number of characters to include.
      # @param allow_leading_zero [Boolean] if set to true, will allow a number starting with zero.
      # @return [String] a random numeric string.
      def self.rand_numeric(length, allow_leading_zero = false)
        value = Array.new(length) { [*'0'..'9'].sample }.join
        value[0] = [*'1'..'9'].sample unless allow_leading_zero
        value
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
      # @return [Array] a range of alpha characters in the matching casing.
      def self.alpha_ranges(casing)
        if casing == :mixed
          [*'A'..'Z', *'a'..'z']
        elsif casing == :upper
          [*'A'..'Z']
        elsif casing == :lower
          [*'a'..'z']
        end
      end

      # Generate an MD5 hash of a string.
      # @param value [String] the value to hash.
      # @return [String] the MD5 hash.
      def self.md5(value)
        digest = Digest::MD5.new
        digest.update(value)
        digest.hexdigest
      end

      # Generate a random e-mail address.
      # @return [String] the e-mail address.
      def self.rand_email
        "#{rand_alpha(rand(5..10))}@#{rand_alpha(rand(5..10))}.com"
      end

      # Generate a random month name.
      # @return [String] the month name.
      def self.rand_month
        %w[january february march april june july august september october november december].sample
      end

      # Convert each byte of a string to its hexadecimal value and
      # concantenate them together, to provide a hexadecimal string.
      # @param value [String] the string to hexify.
      # @return [String] the hexadecimal string.
      def self.hexify_string(value)
        value.each_byte.map { |b| b.to_s(16) }.join
      end
    end
  end
end
