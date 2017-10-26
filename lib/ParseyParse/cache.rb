module ParseyParse
	class Cache
		include Enumerable
		attr_reader :results
		attr_reader :length

		def initialize
			@results = {}
			@length = 0
		end

		def <<(kvp)
			@results[kvp[:text].freeze] = kvp[:result].freeze
			@length += 1
			kvp[:result]
		end

		def each(&blk)
			@results.each(blk)
		end

		def all
			results
		end

		def [](raw)
			results[raw]
		end
	end

	class YAMLCache
		attr_reader :filepath
		attr_reader :cache

		def initialize(**args)
			@filepath = args[:filepath]
			@cache = args[:cache] || ParseyParse::Cache.new
		end

		def self.load_from(fp = './')
			loaded = self.new(filepath: fp, cache: Psych.load(File.read(fp)))
		end

		def self.create_at(fp)
			new_store = self.new(filepath: fp)
			new_store.save
		end

		def save
			File.open(filepath, 'w+') { |f| f << Psych.dump(cache) }
			self
		end

		def <<(kvp)
			res = @cache << kvp
			save
			res
		end

		def method_missing(name, *params)
			@cache.respond_to?(name) ? @cache.method(name).(*params) : super
		end
	end

	class ActiveCache
		attr_reader :cache
		attr_reader :model

		def initialize(model)
			@model = model
			load!
		end

		def <<(kvp)
			return nil if model.where(text: kvp[:text]).length > 0
			model.new(text: kvp[:text], result:kvp[:result]).save
			res = @cache << kvp
		end

		def load!
			@cache = ParseyParse::Cache.new
			model.all.each do |r|
				self.load({text: r.text, result: r.result})
			end
			return length
		end

		def load(kvp)
			res = @cache << kvp
			res
		end

		def each(&blk)
			all.each(blk)
		end

		def all
			cache.all
		end

		def [](raw)
			model.where(text: raw).first&.result
		end

		def method_missing(name, *params)
			@cache.respond_to?(name) ? @cache.method(name).(*params) : super
		end
	end
end