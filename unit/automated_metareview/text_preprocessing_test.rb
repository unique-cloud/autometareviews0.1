require 'test/unit'
require 'text_preprocessing'
require 'constants'
require 'engtagger'
    
class TextPreprocessingTest < Test::Unit::TestCase

  # Testing segment_text functionality
  def test_check_get_review_return_array_as_is
    review_text = ["The sweet potatoes in the vegetable bin are green with mold."]    
    instance = TextPreprocessing.new
    result = instance.segment_text(0, review_text)
    assert_equal(1, result.length)
  end
  
  def test_check_get_review_break_at_full_stop
    review_text = ["The sweet potatoes in the vegetable bin are green with mold. These sweet potatoes in the vegetable bin are fresh."]
    instance = TextPreprocessing.new
    result = instance.segment_text(0, review_text)
    assert_equal(2, result.length)
    assert_equal("The sweet potatoes in the vegetable bin are green with mold.", result[0])
    assert_equal("These sweet potatoes in the vegetable bin are fresh.", result[1])
  end
  
  def test_check_get_review_break_at_comma
    review_text = ["The sweet potatoes were tasty, and they were well-cooked too."]
    instance = TextPreprocessing.new
    result = instance.segment_text(0, review_text)
    assert_equal(2, result.length)
    assert_equal("The sweet potatoes were tasty,", result[0])
    assert_equal("and they were well-cooked too.", result[1])
  end
  
  def test_check_get_review_break_at_semicolon
    review_text = ["The sweet potatoes were tasty; they were all well-cooked."]
    instance = TextPreprocessing.new
    result = instance.segment_text(0, review_text)
    assert_equal(2, result.length)
    assert_equal("The sweet potatoes were tasty;", result[0])
    assert_equal("they were all well-cooked.", result[1])
  end
  
  def test_check_get_review_break_at_questionmark
    review_text = ["Was the report well-written? What grade would you give it?"]
    instance = TextPreprocessing.new
    result = instance.segment_text(0, review_text)
    assert_equal(2, result.length)
    assert_equal("Was the report well-written?", result[0])
    assert_equal("What grade would you give it?", result[1])
  end
  
  def test_check_get_review_break_at_exclamation
    review_text = ["This work is great! Thanks for all the hard work!"]
    instance = TextPreprocessing.new
    result = instance.segment_text(0, review_text)
    assert_equal(2, result.length)
    assert_equal("This work is great!", result[0])
    assert_equal("Thanks for all the hard work!", result[1])
  end
  
  def test_check_get_review_multiple_punctuations_1
    review_text = ["Was the report well-written? What grade would you give it? Please grade the report on a scale of 1 to 5."]
    instance = TextPreprocessing.new
    result = instance.segment_text(0, review_text)
    assert_equal(3, result.length)
    assert_equal("Was the report well-written?", result[0])
    assert_equal("What grade would you give it?", result[1])
    assert_equal("Please grade the report on a scale of 1 to 5.", result[2])
  end
  
  def test_check_get_review_multiple_punctuations_2
    review_text = ["This work is great! The report contains all the graphs. Would you be able to email me a copy of the same? Thanks!"]
    instance = TextPreprocessing.new
    result = instance.segment_text(0, review_text)
    assert_equal(4, result.length)
    assert_equal("This work is great!", result[0])
    assert_equal("The report contains all the graphs.", result[1])
    assert_equal("Would you be able to email me a copy of the same?", result[2])
    assert_equal("Thanks!", result[3])
  end
  
  # Testing read_patterns
  def test_read_patterns_check_numbers
    instance = TextPreprocessing.new
    pos_tagger = EngTagger.new
    patterns = instance.read_patterns("data/patterns-assess.csv", pos_tagger)
    assert_equal(17, patterns.length)
  end
  
  def test_read_patterns_check_contents
    instance = TextPreprocessing.new
    pos_tagger = EngTagger.new
    patterns = instance.read_patterns("data/patterns-assess.csv", pos_tagger)
    assert_equal("is", patterns[0].in_vertex.name)
    assert_equal("very", patterns[0].out_vertex.name)
    
    assert_equal("authors prose", patterns[4].in_vertex.name)
    assert_equal("understand", patterns[4].out_vertex.name)
    
    assert_equal("performance", patterns[13].in_vertex.name)
    assert_equal("are discussed", patterns[13].out_vertex.name)
    
    assert_equal("labeling is", patterns[16].in_vertex.name)
    assert_equal("quite", patterns[16].out_vertex.name)
  end
  
  def test_read_patterns_check_state_positive
    instance = TextPreprocessing.new
    pos_tagger = EngTagger.new
    patterns = instance.read_patterns("data/patterns-assess.csv", pos_tagger)
    assert_equal(POSITIVE, patterns[0].in_vertex.state)
    assert_equal(POSITIVE, patterns[0].out_vertex.state)
    
    assert_equal(POSITIVE, patterns[4].in_vertex.state)
    assert_equal(POSITIVE, patterns[4].out_vertex.state)
    
    assert_equal(POSITIVE, patterns[13].in_vertex.state)
    assert_equal(POSITIVE, patterns[13].out_vertex.state)
    
    assert_equal(POSITIVE, patterns[16].in_vertex.state)
    assert_equal(POSITIVE, patterns[16].out_vertex.state)
  end
  
  def test_read_patterns_check_state_negative
    instance = TextPreprocessing.new
    pos_tagger = EngTagger.new
    patterns = instance.read_patterns("data/patterns-prob-detect.csv", pos_tagger)
    assert_equal(NEGATED, patterns[0].in_vertex.state)
    assert_equal(NEGATED, patterns[0].out_vertex.state)
    
    assert_equal(NEGATED, patterns[4].in_vertex.state)
    assert_equal(NEGATED, patterns[4].out_vertex.state)
    
    assert_equal(NEGATED, patterns[13].in_vertex.state)
    assert_equal(NEGATED, patterns[13].out_vertex.state)
    
    assert_equal(NEGATED, patterns[16].in_vertex.state)
    assert_equal(NEGATED, patterns[16].out_vertex.state)
  end
  
  def test_read_patterns_check_state_suggestive
    instance = TextPreprocessing.new
    pos_tagger = EngTagger.new
    patterns = instance.read_patterns("data/patterns-suggest.csv", pos_tagger)
    assert_equal(SUGGESTIVE, patterns[0].in_vertex.state)
    assert_equal(SUGGESTIVE, patterns[0].out_vertex.state)
    
    assert_equal(SUGGESTIVE, patterns[4].in_vertex.state)
    assert_equal(SUGGESTIVE, patterns[4].out_vertex.state)
    
    assert_equal(SUGGESTIVE, patterns[13].in_vertex.state)
    assert_equal(SUGGESTIVE, patterns[13].out_vertex.state)
    
    assert_equal(SUGGESTIVE, patterns[16].in_vertex.state)
    assert_equal(SUGGESTIVE, patterns[16].out_vertex.state)
  end
end
