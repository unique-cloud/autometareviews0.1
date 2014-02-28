require 'test/unit'
require 'text_quantity'
require 'text_preprocessing'
    
class ToneTest < Test::Unit::TestCase
  attr_accessor :tc
  def setup
    @tc = TextPreprocessing.new
  end
  
  def test_number_of_unique_tokens_without_duplicate_words
    instance = TextQuantity.new
    review_text = ["Parallel lines never meet."]
    review_text = tc.segment_text(0, review_text)
    num_tokens = instance.number_of_unique_tokens(review_text)
    assert_equal(4, num_tokens)
  end
  
  def test_number_of_unique_tokens_with_frequent_words
    instance = TextQuantity.new
    review_text = ["I am surprised to hear the news."]
    review_text = tc.segment_text(0, review_text)
    num_tokens = instance.number_of_unique_tokens(review_text)
    assert_equal(3, num_tokens)
  end
  
  def test_number_of_unique_tokens_with_repeated_words
    instance = TextQuantity.new
    review_text = ["The report is good, but more changes can be made to the report."]
    review_text = tc.segment_text(0, review_text)
    num_tokens = instance.number_of_unique_tokens(review_text)
    assert_equal(6, num_tokens) #tokens:report, good, but, more, changes, made (others are stop words)
  end
end
