require 'forwardable' # :nodoc:

module ParseyParse # :nodoc:
  # The collection of Word tokens is contained in a Sentence.
  class Sentence
    extend Forwardable

    # The array of Word objects
    attr_reader :words

    def_delegators :@words, :first, :last, :each, :map, :find, :find_all, :all?, :any?, :none?, :one?, :select, :reject

    ParseyParse::FIELD_LABELS.each do |label|
      define_method(label.to_sym) do |*params|
        res = self[label, params.first]
        res.length == 1 ? res.first : res
      end
    end

    def initialize(wrds = []) # :nodoc:
      @words = wrds
    end

    # Rejects Punctuation tokens when returning a length
    def length
      words.reject { |w| w.rel == 'punct' }.length
    end

    # Appends a word to the +words+ array
    def <<(obj)
      @words << obj
    end

    def to_s # :nodoc:
      return @to_s if @to_s

      it = words.each
      res = ""
      catch :end_of_word do
        loop do
          unless res == "" 
            begin
              res << " " unless it.peek.to_s =~ /[\,\.\?\!\'\"\;\(\)\[\]\{\}\+\-\=\*\/\_\`]/i
            rescue StopIteration
              throw :end_of_word
            end
          end
          res << it.next.to_s
        end
      end
      @to_s = res
      @to_s
    end

    def to_str
      to_s
    end

    def to_ary
      words
    end

    # Returns true if any of the words are =~ to any pattern in +pattns+
    def contains?(*pattns)
      pattns.any? do |pattn|
        words.any? { |wor| wor =~ pattn }
      end
    end

    # Checkes a sentence using +label+ and +check_ptn+ as search terms.
    # Returns an array of all words whose matching label matches the check pattern exactly.
    def [](label, check_ptn)
      find_all { |w| w.method(label.to_sym).call == check_ptn }
    end

    # Checks against a Regex
    def =~(pat)
      to_s =~ pat
    end

    # Returns the root of the sentence, i.e. the word for which Word#root? is true
    def root
      words.find(&:root?)
    end

    # Syntactic sugar, returns all for whom pos == 'VERB'
    def verbs
      pos 'VERB'
    end

    # Syntactic sugar, returns first for whom pos == 'VERB'
    def verb
      words.find { |wor| wor.pos == 'VERB' }
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

    # Syntactic sugar, returns dobj | pobj
    def obj
      [dobj, pobj]
    end

    # Syntactic sugar, returns all for whom rel == 'nsubj'
    def nsubj
      rel 'nsubj'
    end

    # Syntactic sugar, returns true if any Word tokens do on pos == 'CONJ'
    def conj?
      words.any? { |wor| wor.pos == 'CONJ' }
    end

    # Syntactic sugar, returns all for whom pos == 'CONJ'
    def conj
      pos 'CONJ'
    end

    # Returns an array of all words whose parent are the provided word +wrd+
    def children_of(wrd)
      self['head', wrd]
    end
  end
end
