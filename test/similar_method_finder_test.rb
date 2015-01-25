require_relative 'test_helper'

class SimilarMethodFinderTest < Minitest::Test

  class User
    def friends; end
    def first_name; end
    def descendants; end

    protected
    def the_protected_method; end

    private
    def friend; end
    def the_private_method; end

    class << self
      def pass; end
      def last_name; end
      def load; end
    end
  end

  module UserModule
    def from_module; end
  end

  module Users
    class << self
      def last_names; end
    end
  end

  def setup
    user = User.new.extend(UserModule)

    @error_from_instance_method = assert_raises(NoMethodError){ user.flrst_name }
    @error_from_private_method  = assert_raises(NoMethodError){ user.friend }
    @error_from_module_method   = assert_raises(NoMethodError){ user.fr0m_module }
    @error_from_class_method    = assert_raises(NoMethodError){ User.l0ad }

    @error_from_similar_class_method  = assert_raises(NoMethodError){ Users.last_name }
    @error_from_similar_module_method  = assert_raises(NoMethodError){ Users.pass }
  end

  def test_similar_words
    assert_suggestion @error_from_instance_method.suggestions, "first_name"
    assert_suggestion @error_from_private_method.suggestions,  "friends"
    assert_suggestion @error_from_module_method.suggestions,   "from_module"
    assert_suggestion @error_from_class_method.suggestions,    "load"

    assert_equal ['last_names', 'last_name'], @error_from_similar_class_method.suggestions
    assert_equal %w{hash class pass hash class}, @error_from_similar_module_method.suggestions
  end

  def test_did_you_mean?
    assert_match "Did you mean? #first_name",  @error_from_instance_method.did_you_mean?
    assert_match "Did you mean? #friends",     @error_from_private_method.did_you_mean?
    assert_match "Did you mean? #from_module", @error_from_module_method.did_you_mean?
    assert_match "Did you mean? .load",        @error_from_class_method.did_you_mean?

    assert_match("    Did you mean? .last_names\n" \
                 "                  SimilarMethodFinderTest::User.last_name",
                 @error_from_similar_class_method.did_you_mean?)

    assert_match("    Did you mean? .hash\n" \
                 "                  .class\n" \
                 "                  SimilarMethodFinderTest::User.pass\n" \
                 "                  SimilarMethodFinderTest::User.hash\n" \
                 "                  SimilarMethodFinderTest::User.class\n",
                 @error_from_similar_module_method.did_you_mean?)
  end

  def test_similar_words_for_long_method_name
    error = assert_raises(NoMethodError){ User.new.dependents }
    assert_suggestion error.suggestions, "descendants"
  end

  def test_private_methods_should_not_be_suggested
    error = assert_raises(NoMethodError){ User.new.the_protected_method }
    refute_includes error.suggestions, 'the_protected_method'

    error = assert_raises(NoMethodError){ User.new.the_private_method }
    refute_includes error.suggestions, 'the_private_method'
  end
end
