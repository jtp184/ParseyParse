module ParseyParse
  class Word
    def self.field_labels
      {
        1 => 'id',
        2 => 'form',
        3 => 'lemma',
        4 => 'pos',
        5 => 'xpos',
        6 => 'feats',
        7 => 'head',
        8 => 'rel',
        9 => 'deps',
        10 => 'misc'
      }
    end

    attr_accessor *field_labels.values

    def fields
      result = {}

      Word.field_labels.each do |_k, v|
        result[v.to_sym] = method(v.to_sym).call unless method(v.to_sym).call.nil?
      end

      result
    end

    def root?
      rel == 'ROOT'
    end

    def to_s
      form.to_s
    end
  end
end