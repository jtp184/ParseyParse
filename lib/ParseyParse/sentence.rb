module ParseyParse
  class Sentence
    extend Forwardable

    attr_reader :words

    def_delegators :@words, :first, :last, :each, :map, :find, :find_all, :all?, :any?, :none?, :one?, :select, :reject

    def id(srch)
      find_all { |item| item.id == srch }
    end

    def form(srch)
      find_all { |item| item.form == srch}
    end

    def lemma(srch)
      find_all { |item| item.lemma == srch}
    end

    def pos(srch)
      find_all { |item| item.pos == srch}
    end

    def xpos(srch)
      find_all { |item| item.xpos == srch}
    end

    def feats(srch)
      find_all { |item| item.feats == srch}
    end

    def head(srch)
      find_all { |item| item.head == srch}
    end

    def rel(srch)
      find_all { |item| item.rel == srch}
    end

    def deps(srch)
      find_all { |item| item.deps == srch}
    end

    def misc(srch)
      find_all { |item| item.misc == srch}
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

    def verb
      words.find { |wor| wor.pos == 'VERB'}
    end

    def propn
      xpos 'NNP'
    end

    def dobj
      rel 'dobj'
    end

    def nsubj
      rel 'nsubj'
    end

    def conj?
      
    end

    def conj
    end
  end
end