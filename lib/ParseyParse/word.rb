module ParseyParse # :nodoc:

  # Represents individual tokens reported from each line of CoNLL input
  class Word
    
    # Word index / sentence order as an Integer
    attr_reader :id
    
    # Word form, i.e. the token itself as a String
    attr_reader :form
    
    # Stem of word form for conjugation
    attr_reader :lemma
    
    # Universal Part of Speech Tag
    attr_reader :pos
    
    # Language-specific Part of Speech Tag
    attr_reader :xpos
    
    # List of morphological features
    attr_reader :feats
    
    # Head of the current word, either the ID or 0
    attr_reader :head
    
    # Universal Dependency Relation to the root / head
    attr_reader :rel
    
    # Enhanced Dependency graph of head-rel pairs
    attr_reader :deps
    
    # Other annotations
    attr_reader :misc

    # The mandatory +opts+ hash sets instance variables.
    # Unspecified labels are left nil, and +id+ and +head+ are converted to numbers
    def initialize(opts)
      opts.each do |key, val|
        instance_variable_set("@#{key}", val)  
      end

      @id = @id.to_i
      @head = @head.to_i
    end

    # Syntactic sugar, returns true if the +rel+ is ROOT
    def root?
      rel == 'ROOT'
    end

    # Syntactic sugar, returns true if the +pos+ is VERB
    def verb?
      pos == 'VERB'
    end
    
    # Syntactic sugar, returns true if the +pos+ is NOUN
    def noun?
      pos == 'NOUN'
    end

    # Syntactic sugar, returns true if the +pos+ is ADJ
    def adj?
      pos == 'ADJ'
    end

    def to_s # :nodoc:
      form.to_s
    end
  end
end