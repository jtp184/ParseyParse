# ParseyParse

ParseyParse is a Ruby gem that allows you to utilize the [ParseyMcParseface](https://github.com/tensorflow/models/tree/master/research/syntaxnet) Natural Language understanding model to perform PoS and Dependency-relation tagging on English sentences.

## Configuring
To configure ParseyParse for use, invoke the `ParseyParse.configure` block like so:
```ruby
require 'ParseyParse'

ParseyParse.configure do |conf|
  conf[:syntaxnet_path] = 'path/to/syntaxnet' # Where bazel-bin is located. Defaults to Dir.home + '/models/syntaxnet'
  conf[:script_path] = 'path/to/script' # The .sh file with the command to run. 
```
You can access the config at any time with `ParseyParse.config`
## Invoking
Using ParseyParse is easy. Simply use the `#call` method
```ruby
ParseyParse.call('Today is Wednesday.')

## Or use the alternate syntax
ParseyParse.('It is Wednesday, my dudes.')
```

## Using the Classes
The parser will return a `Sentence` object composed of a number of `Word` objects. You can do many tests and checks with these word objects.
```ruby
result = ParseyParse.('Hand me the ugly little old rectangular brown Italian leather notebook, please.')

# Get the root word of a sentence.
result.root # => "Hand"

# Get matching Part-of-Speech tags
result.pos 'ADJ' # => ["little", "old", "rectangular", "brown", "Italian"]

# Find children
result.children_of(r.form('old')) # => ["ugly", "little"]

# Use a Regex on the sentence
result =~ /bro/ # => 40

# Or check the sentence for words matching regex patterns
result.contains?(/green/, /red/, /blue/) # => false since no word =~ any of those

# Perform checks on the words themselves
result.words.any? { |w| w.noun? } # => true
result.words.any? { |w| w.adj? } # => true

# Advanced comparison made easy!

result.select { |w| w.adj? }.each do |word|
  if word.head == (result.form('notebook')) || word.any_of?(/brown/, /black/, /blue/)
    puts word # => old, rectangular, brown, Italian
  end
end
```

## Caching

Another useful feature is the Caching process. Since ParseyMcParseface can take a while to spin up, ParseyParse allows you to store results for quicker retrieval. Once a cache is configured, ParseyParse will automatically add parsed results to it, and retrieve stored versions. Use the following configuration options to accomplish this

```ruby
require 'ParseyParse/cache' # not included by default

ParseyParse.configure do |conf|
  conf[:cache] = ParseyParse::Cache.new
  # You can also disable use of the parsing function entirely, and only load results from a cache
  conf[:disable_tf] = true 
end

ParseyParse.("Greetings, program!") # Parsed by the model
ParseyParse.("Greetings, program!") # Retrieved from cache!
```

### Cache subtypes

There are two built in wrapper classes for the Cache class to facilitate two common use cases. They both forward any messages to Cache that aren't explicitly overwritten.

`YAMLCache` allows storing a file to disk with the cache stored as easy to view YAML. 
```ruby
yc = ParseyParse::YAMLCache.create_at('tmp/cache.yml') 
# #create_at only needs to be run once, afterwards you run #load_from instead

yc.filepath # => 'tmp/cache.yml'
```

`ActiveCache` interlinks with a Rails-style model class to retrieve and save parse results.
```ruby
ac = ParseyParse::ActiveCache(ParsedText)

# Loads all entries at the beginning
# If they need to be reloaded again, do

ac.load!
```

The requirements for the model are that it must have a `text` and a `result` field, and respond to `#all`, `#where`, and `#save`. 



