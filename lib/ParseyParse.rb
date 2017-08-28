require "ParseyParse/version"

module ParseyParse
  REGEX_PTN = /(([a-z]+[\d,\.\?\[\]\!\$]*)|([\d,\.\?\[\]\!\$]+)|(_))/i

  FIELD_LABELS = Hash.new('misc').merge(
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
  )
end

require "ParseyParse/word"
require "ParseyParse/sentence"

module ParseyParse
  def self.call(table_str)
    new_sentence = ParseyParse::Sentence.new

    table_str.split("\n").each do |line|
      scanner = line.scan(REGEX_PTN)

      vals = {}

      scanner.each_with_index do |param, dex|
        vals[FIELD_LABELS[dex + 1]] = case param[0]
                                        when "_"
                                          nil
                                        else
                                          param[0]
                                      end
      end
      
      new_word = ParseyParse::Word.new(vals)

      new_sentence << new_word
    end

    new_sentence
  end  
end
