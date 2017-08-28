module ParseyParse
  class Word
    attr_reader *ParseyParse::FIELD_LABELS.values

    def initialize(opts)
      opts.each do |key, val|
        instance_variable_set("@#{key}", val)  
      end
    end

    def root?
      rel == 'ROOT'
    end

    def verb?
      pos == 'VERB'
    end
    
    def noun?
      pos == 'NOUN'
    end

    def to_s
      form.to_s
    end
  end
end