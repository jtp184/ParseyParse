module ParseyParse
  class Word
    attr_reader *ParseyParse::FIELD_LABELS

    def initialize(opts)
      opts.each do |key, val|
        instance_variable_set("@#{key}", val)  
      end

      @id = @id.to_i
      @head = @head.to_i
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

    def adj?
      pos == 'ADJ'
    end

    def to_s
      form.to_s
    end
  end
end