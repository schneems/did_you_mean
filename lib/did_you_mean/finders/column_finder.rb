module DidYouMean
  class ColumnFinder
    include BaseFinder

    def initialize(exception)
      @cause         = exception.original_exception
      @frame_binding = exception.frame_binding
    end

    def searches
      { name.to_s => column_names_from_schema_cache }
    end

    def name
      /no such column\: (.*)/ =~ @cause.message && $1
    end

    def column_names_from_schema_cache
      @frame_binding.eval("self").schema_cache.instance_variable_get(:@columns).values.flatten.map(&:name)
    end
  end
end
