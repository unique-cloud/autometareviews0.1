require 'test/unit'
require 'tone'
require 'text_preprocessing'
gem 'stanford-core-nlp', '=0.3.0'
require 'stanford-core-nlp'
require 'ffi/aspell'
require 'sentence'
require 'sentence_similarity'
require 'cluster_generation'
require 'review_coverage'
require 'merge_sort'

class MergeSortingTest < Test::Unit::TestCase
  attr_accessor :pos_tagger, :core_NLP_tagger, :speller
  def setup
  end

  def test_sorting1
    s = Array.new 
    s <<  Sentence.new(0, Array.new, Array.new, 5, 5)
    s[0].avg_similarity = 4
    s <<  Sentence.new(1, Array.new, Array.new, 5, 5)
    s[1].avg_similarity = 3
    s <<  Sentence.new(2, Array.new, Array.new, 5, 5)
    s[2].avg_similarity = 4
    s <<  Sentence.new(3, Array.new, Array.new, 5, 5)
    s[3].avg_similarity = 3
    
    msort = MergeSort.new
		#sort by sentence counter
		al = msort.sort(s, 1)
		assert_equal(0, al[0].ID)
		assert_equal(2, al[1].ID)
		assert_equal(1, al[2].ID)
		assert_equal(3, al[3].ID)
  end
  
  def test_sorting2
    s = Array.new 
    s <<  Sentence.new(0, Array.new, Array.new, 5, 5)
    s[0].avg_similarity = 4
    s <<  Sentence.new(1, Array.new, Array.new, 5, 5)
    s[1].avg_similarity = 5
    s <<  Sentence.new(2, Array.new, Array.new, 5, 5)
    s[2].avg_similarity = 2
    s <<  Sentence.new(3, Array.new, Array.new, 5, 5)
    s[3].avg_similarity = 6
    
    msort = MergeSort.new
    #sort by sentence counter
    al = msort.sort(s, 1)
    
		assert_equal(3, al[0].ID)
    assert_equal(1, al[1].ID)
    assert_equal(0, al[2].ID)
    assert_equal(2, al[3].ID)
  end
end
