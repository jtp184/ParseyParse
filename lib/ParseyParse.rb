require "ParseyParse/version"
require "ParseyParse/word"
require "ParseyParse/sentence"
require 'forwardable'

module ParseyParse
	REGEX_PTN = /(([a-z]+|[\d,\.\?\[\]\!\$]+)|(_))/i

  def self.call(table_str)
    new_sentence = Sentence.new

    table_str.split("\n").each do |line|
      scanner = line.scan(REGEX_PTN)
      new_word = Word.new

      scanner.each_with_index do |param, dex|
        new_word.instance_variable_set('@' + Word.field_labels[dex + 1], param[1])
      end

      new_sentence << new_word
    end

    new_sentence
  end  
end
