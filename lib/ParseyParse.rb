require 'ParseyParse/version'
require 'shellwords'

module ParseyParse
  class TensorFlowDisabledError < StandardError; end
  class TensorFlowFailedError < StandardError; end
  class NoResultError < StandardError; end
end

module ParseyParse
  # The simple Regex pattern to capture each field
  ParseyParse::REGEX_PTN = /(([\d,\.\?\[\]\!\$\/\\:]*[a-z]+[\d,\.\?\[\]\!\$\/\\:]*)|([\d,\.\?\[\]\!\$]+)|(_))/i

  # The 10 field lables from the CoNLL format
  ParseyParse::FIELD_LABELS = %w[
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

    ParseyParse::SHELL_COMMAND = "cd %{syntaxnet_path}; echo %{str} | %{script_path} 2>/dev/null" 
  end

  require 'ParseyParse/word'
  require 'ParseyParse/sentence'

# Takes CoNLL output from Parsey McParseface and converts it into rich featured Ruby Objects for Sentences and component Words/Tokens
module ParseyParse
  @@config = {
    :syntaxnet_path => Dir.home + '/models/syntaxnet',
    :script_path => 'syntaxnet/pp_generate_table.sh',
    :cache => nil,
    :disable_tf => nil
  }

  def self.config
    @@config
  end

  def self.cache
    config[:cache]
  end

  def self.parse_table(table_str)
    wrds = []


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

      wrds << new_word unless new_word.form.nil?
    end

    heads = []

    wrds.each do |w|
      heads << wrds.find { |v| v.id == w.head } || w
    end

    wrds.each_with_index do |wr, x|
      wr.instance_variable_set("@head", heads[x])
    end

    new_sentence = ParseyParse::Sentence.new(wrds)

  end

  def self.known
    return nil if config[:cache].nil?
    config[:cache].all
  end

  def self.configure(&blk)
    yield @@config
    @@config
  end

  def self.run_parser(text_str)
    cmd = ParseyParse::SHELL_COMMAND % config.merge({:str => Shellwords.escape("\"#{text_str}\"")})
    result = `#{cmd}`
    raise TensorFlowFailedError, "Tensorflow Parsing Failed!" unless $?.success?
    result
  end

  def self.call(str)
    res = if ParseyParse.config[:cache]
      ParseyParse.config[:cache][str] || nil
    end

    if config[:disable_tf] 
      raise TensorFlowDisabledError, "TF Disabled, no cached result" unless res
    end

    res ||= parse_table(run_parser(str))
    ParseyParse.config[:cache] << {text: str, result: res} if ParseyParse.config[:cache]
    res
  end
end
