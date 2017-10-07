require 'ParseyParse/version'
require 'shellwords'

module ParseyParse
  # The simple Regex pattern to capture each field
  REGEX_PTN = /(([\d,\.\?\[\]\!\$\/\\:]*[a-z]+[\d,\.\?\[\]\!\$\/\\:]*)|([\d,\.\?\[\]\!\$]+)|(_))/i

  # The 10 field lables from the CoNLL format
  FIELD_LABELS = %w[
    id
    form
    lemma
    pos
    xpos
    feats
    head
    rel
    deps
    misc
    ].freeze
  end
  
  SHELL_COMMAND = "cd %{syntaxnet_path}; echo #{Shellwords.escape(cmd)} | %{script_path} 2>/dev/null" 

  require 'ParseyParse/word'
  require 'ParseyParse/sentence'

# Takes CoNLL output from Parsey McParseface and converts it into rich featured Ruby Objects for Sentences and component Words/Tokens
module ParseyParse
  # The basic factory method. Uses the .() alias for #call
  #
  # Takes a string which is the tabular output, splits it by line,
  # and uses that to create each Word, and holds them all in a new Sentence which is then returned

  @@config = {
    :syntaxnet_path => Dir.home + '/models/syntaxnet',
    :script_path => 'syntaxnet/pp_generate_table.sh',
  }

  def self.parse_table(table_str)
    new_sentence = ParseyParse::Sentence.new

    table_str.split("\n").each do |line|
      scanner = line.scan(REGEX_PTN)

      vals = {}

      scanner.each_with_index do |param, dex|
        vals[FIELD_LABELS[dex]] = case param[0]
        when '_'
          nil
        else
          param[0]
        end
      end

      new_word = ParseyParse::Word.new(vals)

      new_sentence << new_word unless new_word.form.nil?
    end

    new_sentence
  end

  def self.configure(&blk))
    yield @@config
  end

  def self.run_parser(text_str)
    quoted = "\"#{text_str}\""
    ParseyParse::SHELL_COMMAND % @@config
    `#{cmd}`
  end

  def self.call(str)
    parse_table(run_parser(str))
  end
end
