require 'forwardable'

module ParseyParse
  class Sentence
    extend Forwardable

    attr_reader :words

    def_delegators :@words, :first, :last, :each, :map, :find, :find_all, :all?, :any?, :none?, :one?, :select, :reject

    def method_missing(name, *params)
      super unless ParseyParse::FIELD_LABELS.include?(name.to_s)
      find_all { |item| item.method(name.to_sym).call == params.first}
    end

    def initialize
      @words = []
    end

    def length
      words.reject { |w| w.rel == 'punct'}.length
    end

    def <<(obj)
      return nil unless obj.is_a? Word
      @words << obj
    end

    def to_s
      words.map(&:to_s).join(' ')
    end

    def =~(pat)
      self.to_s =~ pat
    end

    def root
      words.find(&:root?)
    end

    def verbs
      pos 'VERB'
    end

    def verb
      verbs.first
    end

    def propn
      xpos 'NNP'
    end

    def dobj
      rel 'dobj'
    end

    def pobj
      rel 'pobj'
    end

    def nsubj
      rel 'nsubj'
    end

    def conj?
      words.any? { |wor| wor.pos == 'CONJ'}
    end

    def conj
      pos 'CONJ'
    end
  end
end