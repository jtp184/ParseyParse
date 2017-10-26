require 'ParseyParse/version'
require 'shellwords'

module ParseyParse
  # Error class for if Tensorflow is disabled by the config
  class TensorFlowDisabledError < StandardError; end
  # Error class for if Tensorflow fails to run
  class TensorFlowFailedError < StandardError; end
  # Error class for if no result is returned.
  class NoResultError < StandardError; end
end

module ParseyParse
  # The simple Regex pattern to capture each field
  ParseyParse::REGEX_PTN = /[^\t]*/i

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

  # The shell command abstracted and ready for late string interpolation
  ParseyParse::SHELL_COMMAND = 'cd %{syntaxnet_path}; echo %{str} | %{script_path} 2>/dev/null'.freeze
  end

require 'ParseyParse/word'
require 'ParseyParse/sentence'

# Takes CoNLL output from Parsey McParseface and converts it into rich featured Ruby Objects for Sentences and component Words/Tokens
module ParseyParse
  # The configuration options
  @@config = {
    syntaxnet_path: Dir.home + '/models/syntaxnet',
    script_path: 'syntaxnet/pp_generate_table.sh',
    cache: nil,
    disable_tf: nil
  }

  # Syntactic sugar for the class variable
  def self.config
    @@config
  end

  # Syntactic sugar for the cache in the config if one exists
  def self.cache
    config[:cache]
  end

  # Parses the providet +table_str+ and returns a Sentence populated with Words
  def self.parse_table(table_str)
    wrds = []

    table_str.split("\n").each do |line|
      scanner = line.scan(REGEX_PTN).reject { |s| s == '' }

      vals = {}

      scanner.each_with_index do |param, dex|
        next nil if dex > FIELD_LABELS.length
        vals[FIELD_LABELS[dex]] = case param
                                  when /^\_$/
                                    nil
                                  else
                                    param
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
      wr.instance_variable_set('@head', heads[x])
    end

    new_sentence = ParseyParse::Sentence.new(wrds)
  end

  # Returns all values in the cache if one exists.
  def self.known
    return nil if config[:cache].nil?
    config[:cache].all
  end

  # Configure according to the options in +config+
  def self.configure # :yields: config
    yield @@config
    @@config
  end

  # Takes a text string +text_str+, creates a command from it and the configuration options,
  # and returns the result of that command (i.e. the CoNLL table)
  def self.run_parser(text_str)
    cmd = ParseyParse::SHELL_COMMAND % config.merge(str: Shellwords.escape("#{text_str}"))
    result = `#{cmd}`
    raise TensorFlowFailedError, 'Tensorflow Parsing Failed!' unless $?.success?
    result
  end

  # Main interface. Takes a string +str+ and returns its parsed result.
  # Also handles the case where a cache is being used.
  def self.call(str)
    res = (ParseyParse.config[:cache][str] || nil if ParseyParse.config[:cache])

    if config[:disable_tf]
      raise TensorFlowDisabledError, 'TF Disabled, no cached result' unless res
    end

    unless res
      res = parse_table(run_parser(str))
      ParseyParse.config[:cache] << { text: str, result: res } if ParseyParse.config[:cache]
    end

    res
  end
end
