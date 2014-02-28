require 'test/unit'
require 'sentence_state'
require 'engtagger'
    
class SentenceStateTest < Test::Unit::TestCase
  attr_accessor :pos_tagger, :sstate
  def setup
    @pos_tagger = EngTagger.new
    #creating an instance of the 'SentenceState' class        
    @sstate = SentenceState.new
  end
  
  def test_Identify_State_1
    sentence = "Parallel lines never meet."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)    
    assert_equal(state_array[0], NEGATED)
  end  
  
  def test_Identify_State_2
    sentence = "He is not playing."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)    
    assert_equal(state_array[0], NEGATED)
  end     
  
  def test_Identify_State_3
    sentence = "I’m not ever going to do any homework."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)    
    assert_equal(state_array[0], NEGATED)
  end 
     
  def test_Identify_State_4
    sentence = "You aren't ever going to go anywhere with me if you act like that."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)    
    assert_equal(state_array[0], NEGATED)
  end   
  
  def test_Identify_State_5
    sentence = "No examples and no explanation have been provided."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)    
    assert_equal(state_array[0], NEGATED)
  end
   
  def test_Identify_State_6
    sentence = "No good or bad examples have been provided."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)    
    assert_equal(state_array[0], NEGATED)
  end

  def test_Identify_State_7
    sentence = "It is too short not to contain sufficient explanation." #the sentence is ambiguous
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)    
    assert_equal(state_array[0], POSITIVE) 
  end
  
  def test_Identify_State_8
    sentence = "We are not not musicians."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)    
    assert_equal(state_array[0], POSITIVE)
  end

  def test_Identify_State_9
    sentence = "I don't need none."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)    
    assert_equal(state_array[0], POSITIVE)
  end  

  def test_Identify_State_10
    sentence = "It was so hot, I couldn't hardly breathe."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)
    assert_equal(1, state_array.length)    
    assert_equal(state_array[0], NEGATED)
  end
  
  def test_Identify_State_11
    sentence = "I don't want to go nowhere."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments) 
    assert_equal(state_array[0], POSITIVE)
  end
  
  def test_Identify_State_12
    sentence = "This essay is clearly not nonsense."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments) 
    assert_equal(state_array[0], POSITIVE)
  end

  def test_Identify_State_13
    sentence = "I receive a not insufficient allowance."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments) 
    assert_equal(state_array[0], POSITIVE)
  end   
       
  def test_Identify_State_14_ambiguous
    sentence = "This is barely duplicated."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments) 
    assert_equal(state_array[0], POSITIVE)
  end
   
  def test_Identify_State_suggestive_15
    sentence = "It is ambiguous and I would have preferred to do it differently."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)
    assert_equal(2, state_array.length) 
    assert_equal(state_array[0], NEGATED)
    assert_equal(state_array[1], SUGGESTIVE)
  end
  
  def test_Identify_State_suggestive_16
    sentence = "I suggest you not take that route."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)
    assert_equal(state_array[0], SUGGESTIVE)
  end

  def test_Identify_State_suggestive_17
    sentence = "I hardly suggested that option."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)
    assert_equal(state_array[0], SUGGESTIVE)
  end
  
  def test_Identify_State_negated_18
    sentence = "It is perhaps better you not do the homework."
    #getting the tagged string
    tagged_string = @pos_tagger.get_readable(sentence)
    #calling the identify_sentence_state method with tagged_string as a parameter
    state_array = sstate.identify_sentence_state(tagged_string) #returns an array containing states as the output (depending on the number and types of segments)
    assert_equal(state_array[0], SUGGESTIVE) #negative or suggestive, is ambiguous
  end
end
