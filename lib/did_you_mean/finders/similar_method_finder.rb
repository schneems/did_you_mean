module DidYouMean
  class SimilarMethodFinder
    include BaseFinder
    attr_reader :method_name, :receiver

    def initialize(exception)
      @method_name   = exception.name
      @receiver      = exception.receiver
      @frame_binding = exception.frame_binding
      @separator     = class_or_module_method? ? DOT : POUND
    end

    def words
      method_names = receiver.methods + receiver.singleton_methods
      method_names.delete(@method_name)
      method_names.uniq.map do |name|
        StringDelegator.new(name.to_s, :method, prefix: @separator)
      end + methods_from_similar_classes
    end

    alias target_word method_name

    private

    def class_or_module_method?
      receiver.is_a?(Class) || receiver.is_a?(Module)
    end

    def methods_from_similar_classes
      similar_classes.flat_map do |klass|
        klass.methods.map do |method_name|
          StringDelegator.new(method_name.to_s, :method, prefix: "#{klass}.")
        end
      end
    end

    def similar_classes
      name  = receiver.to_s.split("::").last
      scope = @frame_binding.eval("self.class")

      WordCollection.new(scope.constants).similar_to(name)
        .reject {|c| c.to_s == name }
        .map(&scope.method(:const_get))
    end
  end

  case RUBY_ENGINE
  when 'ruby'
    require 'did_you_mean/method_receiver'
  when 'jruby'
    require 'did_you_mean/receiver_capturer'
    org.yukinishijima.ReceiverCapturer.setup(JRuby.runtime)
    NoMethodError.send(:attr, :receiver)
  when 'rbx'
    require 'did_you_mean/core_ext/rubinius'
    NoMethodError.send(:attr, :receiver)

    module SimilarMethodFinder::RubiniusSupport
      def self.new(exception)
        if exception.receiver === exception.frame_binding.eval("self")
          NameErrorFinders.new(exception)
        else
          SimilarMethodFinder.new(exception)
        end
      end
    end
  end
end
