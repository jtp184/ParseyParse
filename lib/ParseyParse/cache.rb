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
			@results[kvp[:text].freeze] = kvp[:result].freeze
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
		attr_reader :cache

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

		# Initialize by passing the Model's class as +model+
		def initialize(model)
			@model = model
			load!
		end

		# Rejects non-unique adds, and creates / saves a new result for +kvp+
		def <<(kvp)
			return nil if model.where(text: kvp[:text]).length > 0
			model.new(text: kvp[:text], result:kvp[:result]).save
			res = @cache << kvp
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

		# Uses overridden #all method to pass +blk+ to each
		def each(&blk)
			all.each(blk)
		end

		# Uses <tt>model#all</tt>
		def all
			cache.all
		end

		# Searches using <tt>model.where(text: raw)</tt>
		def [](raw)
			model.where(text: raw).first&.result
		end

		# Overridden to check if cache can respond to the method +name+ with +params+ first.
		def method_missing(name, *params)
			@cache.respond_to?(name) ? @cache.method(name).(*params) : super
		end
	end
end