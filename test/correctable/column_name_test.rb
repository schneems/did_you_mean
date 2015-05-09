require 'test_helper'
=begin
class ColumnFinderTest < Minitest::Test
  DidYouMean.finders[ActiveRecord::StatementInvalid.to_s] = DidYouMean::ColumnFinder
  ActiveRecord::StatementInvalid.prepend(DidYouMean::Correctable)

  def setup
    @error = assert_raises(ActiveRecord::StatementInvalid) do
      User.select("firstname").to_a
    end
  end

  def test_similar_words
    assert_suggestion "first_name", @error.suggestions
  end

  def test_did_you_mean?
    assert_match "Did you mean? first_name", @error.did_you_mean?
  end
end if defined?(ActiveRecord)
=end
