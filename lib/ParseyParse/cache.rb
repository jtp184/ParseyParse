module ParseyParse # :nodoc:
	# Base Cache class. For storing the results of computation for reuse.
	class Cache
		include Enumerable # :nodoc:

		# a Hash map of String => ParseyParse::Sentence
		attr_reader :results
		# Stored length variable for how many entries exist
		attr_reader :length

		def initialize # :nodoc:
			@results = {}
			@length = 0
		end

		# Inserts the hash +kvp+ into the array.
		# Requires +kvp+ to be a hash with keys for :text and :result
		def <<(kvp)
			@results[kvp[:text]] = kvp[:result]
			@length += 1
			kvp[:result]
		end

		# Passes blocks to <tt>results#each</tt>
		def each(&blk)
			@results.each(blk)
		end

		# Returns the +results+ hash
		def all
			results
		end

		# Performs lookup on +raw+ as a key for +results+
		def [](raw)
			results[raw]
		end
	end

	# Serializes a Cache to YAML and retrieves it
	class YAMLCache

		# The location of the cache on disk.
		attr_reader :filepath

		# The Cache object itself
		attr_accessor :cache

		# Values for +args+ :filepath, :cache
		def initialize(**args)
			@filepath = args[:filepath]
			@cache = args[:cache] || ParseyParse::Cache.new
		end

		# Loads a YAMLCache from a filepath +fp+ and returns it.
		def self.load_from(fp = './')
			loaded = self.new(filepath: fp, cache: Psych.load(File.read(fp)))
		end

		# Creates a YAMLCache at the filepath location +fp+ and returns it.
		def self.create_at(fp)
			new_store = self.new(filepath: fp)
			new_store.save
		end

		# Saves this to disk, then returns self.
		def save
			File.open(filepath, 'w+') { |f| f << Psych.dump(cache) }
			self
		end

		# Overrides Cache#<< to save on adds as well.
		def <<(kvp)
			res = @cache << kvp
			save
			res
		end

		# Overridden to check if cache can respond to the method +name+ with +params+ first.
		def method_missing(name, *params)
			@cache.respond_to?(name) ? @cache.method(name).(*params) : super
		end
	end

	# Uses a Rails-style model to retrieve results
	class ActiveCache
		# The internal Cache object
		attr_reader :cache
		# The model providing the members
		attr_reader :model

		# Initialize by passing the Model's class as +model+. 
		# Accepts an optional +eager_load+ parameter, used to load all entries from
		# model at the beginning or each as they come in, and a +use_cache+ parameter
		# to determine whether they use an internal cache at all.
		def initialize(model, eager_load=true, use_cache=true)
			@model = model
			if eager_load
				load!
			else
				@cache = if use_cache
					ParseyParse::Cache.new
				else
					Class.new do
						def fetch(*); raise KeyError; end
						def method_missing(*); end 
						def respond_to?(name); true; end
					end.new
				end

			end
		end

		# Rejects non-unique adds, and creates / saves a new result for +kvp+
		def <<(kvp)
			return nil if model.where(text: kvp[:text]).length > 0
			model.new(text: kvp[:text], result:kvp[:result]).save
			res = @cache << kvp
		end

		def load_cache(other)
			other.cache.each do |ok, ov|
				self << { text: ok, result: ov }
			end
		end

		# Throws away the currently loaded cache and reloads the results from the model.
		def load!
			@cache = ParseyParse::Cache.new
			model.all.each do |r|
				self.load({text: r.text, result: r.result})
			end
			return length
		end

		# Adds results to the internal cache, but doesn't create a new record.
		def load(kvp)
			res = @cache << kvp
			res
		end

		# Uses overridden #all method to pass +blk+ to each on the cache.
		def each(&blk)
			all.each(blk)
		end

		# Uses #all! method to pass +blk+ to each on the model.
		def each!(&blk)
			all!.each(blk)
		end

		# Uses <tt>cache#all</tt>
		def all
			Array(cache.all)
		end

		# Uses <tt>model.all</tt>
		def all!
			Array(model.all)
		end

		# Uses +raw+ as a key to search first the internal cache,
		# and then if no result is found, tries searching on the model.
		def [](raw)
			results.fetch(raw)
		rescue KeyError
			r = model.where(text: raw).first&.result
			if !r.nil?
				load( { text: raw, result: r } )
			end
			return r
		end

		# Overridden to check if cache can respond to the method +name+ with +params+ first.
		def method_missing(name, *params)
			@cache.respond_to?(name) ? @cache.method(name).(*params) : super
		end
	end
end