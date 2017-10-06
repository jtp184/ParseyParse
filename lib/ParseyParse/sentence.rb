require 'forwardable' # :nodoc:

module ParseyParse # :nodoc:

  # The collection of Word tokens is contained in a Sentence.
  class Sentence
    extend Forwardable

    # The array of Word objects
    attr_reader :words

    def_delegators :@words, :first, :last, :each, :map, :find, :find_all, :all?, :any?, :none?, :one?, :select, :reject

    # Defined so that if a method +name+ matches a field label, it uses #find_all to search for it and uses the first +param+ as a search term
    def method_missing(name, *params)
      super unless ParseyParse::FIELD_LABELS.include?(name.to_s)
      find_all { |item| item.method(name.to_sym).call == params.first}
    end

    def initialize # :nodoc:
      @words = []
    end

    # Rejects Punctuation tokens when returning a length
    def length
      words.reject { |w| w.rel == 'punct'}.length
    end

    # Appends a word to the +words+ array
    def <<(obj)
      @words << obj
    end

    def to_s # :nodoc:
      words.map(&:to_s).join(' ')
    end

    # Checks against a Regex
    def =~(pat) 
      self.to_s =~ pat
    end

    # Returns the root of the sentence, i.e. the word for which Word#root? is true
    def root
      words.find(&:root?)
    end

    # Syntactic sugar, returns all for whom pos == 'VERB'
    def verb
      pos 'VERB'
    end

    # Syntactic sugar, returns all for whom xpos == 'NNP'
    def propn
      xpos 'NNP'
    end

    # Syntactic sugar, returns all for whom rel == 'dobj'
    def dobj
      rel 'dobj'
    end

    # Syntactic sugar, returns all for whom rel == 'pobj'
    def pobj
      rel 'pobj'
    end

    # Syntactic sugar, returns all for whom rel == 'nsubj'
    def nsubj
      rel 'nsubj'
    end

    # Syntactic sugar, returns true if any Word tokens do on pos == 'CONJ'
    def conj?
      words.any? { |wor| wor.pos == 'CONJ'}
    end

    # Syntactic sugar, returns all for whom pos == 'CONJ'
    def conj
      pos 'CONJ'
    end
  end
end