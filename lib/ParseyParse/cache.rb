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
		# The model providing the members
		attr_reader :model

		# Initialize by passing the Model's class as +model+. 
		def initialize(model)
			@model = model
		end

		# Rejects non-unique adds, and creates / saves a new result for +kvp+
		def <<(kvp)
			return nil if model.where(text: kvp[:text]).length > 0
			model.new(text: kvp[:text], result:kvp[:result]).save
			kvp[:result]
		end 

		# Uses overridden #all method to pass +blk+ to each on the cache.
		def each(&blk)
			all.each(blk)
		end

		# Uses <tt>model.all</tt>
		def all
			Array(model.all)
		end

		# Uses +raw+ as a key to search first the internal cache,
		# and then if no result is found, tries searching on the model.
		def [](raw)
			r = model.where(text: raw).first&.result
			return r
		end
	end

	# Uses a Redis server to store / retrieve parsings.
	class RedisCache

		# Takes in options through +opts+, such as an optional :redis_config for
		# the internal Redis connection.
		def initialize(opts={})
			@redis = Redis.new(opts.fetch(:redis_config) { {} })
		end

		# Serializes +raw+ and uses Redis#get to check for it.
		def [](raw)
			check = @redis.get(serialize_key(raw))
			if(check)
				Psych.load(check)
			else
				nil
			end
		end

		# Takes in a key value pair +kvp+ with a :text and :result field,
		# and sets them into the redis server after serializing them
		def <<(kvp)
			@redis.set(serialize_key( kvp[:text]), serialize_value( kvp[:result]))
		end

		# Passes +args+ and +blk+ to #all
		def each(*args, &blk)
			self.all.each(*args, &blk)
		end

		# Uses Redis#keys to get all the parsey keys, 
		# Redis#pipelined to grab all their values
		# then de-serializes and zips them into a return hash.
		def all
			k = @redis.keys('*[ParseyParse]*')
			v = @redis.pipelined { k.each { |j| @redis.get(j) } }
			k.map { |j| j.gsub(/\[ParseyParse\]\{(.*)\}/) { |m| $1 } }.zip(v.map { |u| Psych.load(u)}).to_h
		end

		# Uses the length of #all 
		def length
			self.all.length
		end

		# Same as #all
		def results
			self.all
		end

		private

		# Adds a prefix / wrapper to the key +ky+ for easy pattern globbing
		def serialize_key(ky)
			"[ParseyParse]{#{ky}}"
		end

		# Serializes +vl+ to a YAML string using Psych#dump
		def serialize_value(vl)
			Psych.dump(vl)
		end
	end
end