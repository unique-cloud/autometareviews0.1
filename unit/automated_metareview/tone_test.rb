require 'test/unit'
require 'tone'
require 'text_preprocessing'
gem 'stanford-core-nlp', '=0.3.0'
require 'stanford-core-nlp'
require 'ffi/aspell'
    
class ToneTest < Test::Unit::TestCase
  attr_accessor :pos_tagger,  :core_NLP_tagger, :tc, :g, :speller
  
  def setup
    #initializing the pos tagger and nlp tagger/semantic parser  
    @pos_tagger = EngTagger.new
    @core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
    @tc = TextPreprocessing.new
    @g = GraphGenerator.new
    #initializing the speller
    @speller = FFI::Aspell::Speller.new('en_US')
  end
  
  def test_identify_tone_with_negations_but_a_neutral_tone_1
    instance = Tone.new
    review_text = ["Parallel lines never meet."]
    review_text = tc.segment_text(0, review_text)
    tone_array = Array.new
    g.generate_graph(review_text, pos_tagger, core_NLP_tagger, true, false)
    tone_array = instance.identify_tone(@pos_tagger, @speller, @core_NLP_tagger, review_text, g)
    assert_equal(3, tone_array.length) #only positive and negative available at this point
    assert_equal(0, tone_array[0])#positive
    assert_equal(0, tone_array[1])#negative
    assert_equal(1, tone_array[2])#neutral
  end
  
  def test_identify_tone_with_negations_but_a_neutral_tone_2
    instance = Tone.new
    review_text = ["He is not playing."] #neutral although it has a negator
    review_text = tc.segment_text(0, review_text)
    tone_array = Array.new
    g.generate_graph(review_text, pos_tagger, core_NLP_tagger, true, false)
    tone_array = instance.identify_tone(@pos_tagger, @speller, @core_NLP_tagger, review_text, g)
    assert_equal(3, tone_array.length) #only positive and negative available at this point
    assert_equal(0, tone_array[0])#positive
    assert_equal(0, tone_array[1])#negative
    assert_equal(1, tone_array[2])#neutral
  end
  
  def test_identify_tone_with_negations_but_a_neutral_tone_3
    instance = Tone.new
    review_text = ["No examples and no explanation have been provided."] #neutral although it has a negator
    review_text = tc.segment_text(0, review_text)
    tone_array = Array.new
    g.generate_graph(review_text, pos_tagger, core_NLP_tagger, true, false)
    tone_array = instance.identify_tone(@pos_tagger, @speller, @core_NLP_tagger, review_text, g)
    assert_equal(3, tone_array.length) #only positive and negative available at this point
    assert_equal(0, tone_array[0])#positive
    assert_equal(0, tone_array[1])#negative
    assert_equal(1, tone_array[2])#neutral
  end
  
  def test_identify_tone_with_a_neutral_tone_1
    instance = Tone.new
    review_text = ["It was so hot, I couldn't hardly breathe."] #neutral although it has a negative descriptor
    review_text = tc.segment_text(0, review_text)
    tone_array = Array.new
    g.generate_graph(review_text, pos_tagger, core_NLP_tagger, true, false)
    tone_array = instance.identify_tone(@pos_tagger, @speller, @core_NLP_tagger, review_text, g)
    assert_equal(3, tone_array.length) #only positive and negative available at this point
    assert(tone_array[0] > tone_array[1])
    #this sentence gets classified as positive since "couldn't" is treated as "could + n't" and "could" is classified with a + tone 
  end
  
  def test_identify_tone_with_a_negative_word_1
    instance = Tone.new
    review_text = ["This is barely duplicated."] #negative
    review_text = tc.segment_text(0, review_text)
    tone_array = Array.new
    g.generate_graph(review_text, pos_tagger, core_NLP_tagger, true, false)
    tone_array = instance.identify_tone(@pos_tagger,@speller, @core_NLP_tagger, review_text, g)
    assert_equal(3, tone_array.length) #only positive and negative available at this point
    assert_equal(0, tone_array[0])#positive
    assert_equal(1, tone_array[1])#negative
    assert_equal(0, tone_array[2])#neutral
  end
 
  def test_identify_tone_with_positive_and_negative_components_1
    instance = Tone.new
    review_text = ["It is ambiguous and I would have preferred to do it differently."] #negative
    review_text = tc.segment_text(0, review_text)
    tone_array = Array.new
    g.generate_graph(review_text, pos_tagger, core_NLP_tagger, true, false)
    tone_array = instance.identify_tone(@pos_tagger, @speller, @core_NLP_tagger, review_text, g)
    assert_equal(3, tone_array.length) #only positive and negative available at this point
    assert(tone_array[0] == 0)#poisitive > negative
    assert(tone_array[1] == 1)
    assert(tone_array[2] == 0)
  end
  
  def test_identify_tone_with_positive_and_negative_components_2
    instance = Tone.new
    review_text = ["This is a good report. I would have liked it to be a bit longer though."] #negative
    review_text = tc.segment_text(0, review_text)
    tone_array = Array.new
    g.generate_graph(review_text, pos_tagger, core_NLP_tagger, true, false)
    tone_array = instance.identify_tone(@pos_tagger, @speller, @core_NLP_tagger, review_text, g)
    assert_equal(3, tone_array.length) #only positive and negative available at this point
    assert(tone_array[0] > tone_array[1])#poisitive > negative
  end
  
  def test_identify_tone_with_positive_and_negative_components_3
    instance = Tone.new
    review_text = ["It is ambiguous and I was a very report."] #negative
    review_text = tc.segment_text(0, review_text)
    tone_array = Array.new
    g.generate_graph(review_text, pos_tagger, core_NLP_tagger, true, false)
    tone_array = instance.identify_tone(@pos_tagger, @speller, @core_NLP_tagger, review_text, g)
    assert_equal(3, tone_array.length) #only positive and negative available at this point
    assert(tone_array[0] < tone_array[1])#poisitive > negative
  end
  
  def test_identify_tone_with_a_neutral_tone_2
    instance = Tone.new
    review_text = ["It is perhaps better you not do the homework."] #negative
    review_text = tc.segment_text(0, review_text)
    tone_array = Array.new
    g.generate_graph(review_text, pos_tagger, core_NLP_tagger, true, false)
    tone_array = instance.identify_tone(@pos_tagger,@speller, @core_NLP_tagger, review_text, g)
    assert_equal(3, tone_array.length) #only positive and negative available at this point
    assert(tone_array[0] == tone_array[1])
    assert(tone_array[2] == 1)
  end
end
