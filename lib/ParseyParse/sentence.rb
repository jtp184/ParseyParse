class Sentence
  extend Forwardable

  attr_reader :words

  def_delegators :@words, :first, :last, :length, :each, :map, :find, :find_all, :all?, :any?, :none?, :one?

  def initialize
    @words = []
  end

  def <<(obj)
    return nil unless obj.is_a? Word
    @words << obj
  end

  def to_s
    words.map(&:to_s).join(' ')
  end

  def root
    words.find(&:root?)
  end
end