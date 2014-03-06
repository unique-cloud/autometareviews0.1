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

class TopicSentenceIdentificationTest < Test::Unit::TestCase
  attr_accessor :pos_tagger, :core_NLP_tagger, :speller
  def setup
    #initializing the pos tagger and nlp tagger/semantic parser  
    @pos_tagger = EngTagger.new
    @core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
    @g = GraphGenerator.new
    #initializing the speller
    @speller = FFI::Aspell::Speller.new('en_US')
  end

  #Test method for 'googlesearch.CompositeQuery.getSearchString()'
  def test_find_topic_sentences1
	  text1 = ["The sweet potatoes in the vegetable bin are green with mold."]
		text2 = ["The sweet potatoes in the vegetable bin are green with mold."]
    subm_text = Array.new
    subm_text << text1
    subm_text << text2

    #setting up sentences and similarities before generation of clusters
    subm_sents = Array.new #Sentence[] s = new Sentence[2]; 
    g = GraphGenerator.new
    g.generate_graph(subm_text[0], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[1], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges)

		#calculating sentence similarity
    ssim = SentenceSimilarity.new
    #sentence similarity
    sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    sent_list = ssim.sim_list
    sim_threshold = ssim.sim_threshold
		
		cg = ClusterGeneration.new
    #cluster creation      
    result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
    
    #identifying topic sentences
    tsent = TopicSentenceIdentification.new
    tsent.find_topic_sentences(result, sent_sim)
		
		#assert statements
		assert_equal(1, result[0].topic_sentences.length) #only 1 topic sentence is selected
		assert_equal(1, result[0].topic_sentences[0].ID) #the first cluster contains 0 sentences
		
	  #checking sentence states
		assert_equal(true, subm_sents[0].flag_covered)
		assert_equal(true, subm_sents[1].flag_covered)
  end
   
  def test_find_topic_sentences2
   	text1 = ["He played the guitar."] 
    text2 = ["He played the flute."] 
    text3 = ["He played the flute."]
   	subm_text = Array.new
    subm_text << text1
    subm_text << text2
    subm_text << text3
    
    #setting up sentences and similarities before generation of clusters
    subm_sents = Array.new #Sentence[] s = new Sentence[2]; 
    g = GraphGenerator.new
    g.generate_graph(subm_text[0], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[1], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[2], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(2, g.vertices, g.edges, g.num_vertices, g.num_edges)
    
    #calculating sentence similarity
    ssim = SentenceSimilarity.new
    #sentence similarity
    sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    sent_list = ssim.sim_list
    sim_threshold = ssim.sim_threshold
    #manipulating the similarity threshold to get all three sentences into the same cluster
    ssim.sim_threshold = 2
       
    cg = ClusterGeneration.new
    #cluster creation      
    result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
		
    #identifying topic sentences
    tsent = TopicSentenceIdentification.new
    tsent.find_topic_sentences(result, sent_sim)
		
		#2 topic sentences are selected, since the cluster average is 5.2 and a single sentence cannot cover all the other edges with this values
		assert_equal(1, result[0].topic_sentences.length)
    assert_equal(0, result[0].topic_sentences[0].ID)
    assert_equal(1, result[1].topic_sentences.length)
		assert_equal(2, result[1].topic_sentences[0].ID)
	
		#checking sentence states
		assert_equal(true, subm_sents[0].flag_covered)
		assert_equal(true, subm_sents[1].flag_covered)
		assert_equal(true, subm_sents[2].flag_covered)
  end
   
  def test_find_topic_sentences3
   	text1 = ["He played the guitar."] 
    text2 = ["This is funny."] 
    text3 = ["He played the guitar."]
   	subm_text = Array.new
    subm_text << text1
    subm_text << text2
    subm_text << text3
    
    #setting up sentences and similarities before generation of clusters
    subm_sents = Array.new #Sentence[] s = new Sentence[2]; 
    g = GraphGenerator.new
    g.generate_graph(subm_text[0], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[1], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[2], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(2, g.vertices, g.edges, g.num_vertices, g.num_edges)
    
    #calculating sentence similarity
    ssim = SentenceSimilarity.new
    #sentence similarity
    sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    sent_list = ssim.sim_list
    sim_threshold = ssim.sim_threshold
       
    cg = ClusterGeneration.new
    #cluster creation      
    result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
    #2 clusters are created
		
    #identifying topic sentences
    tsent = TopicSentenceIdentification.new
    tsent.find_topic_sentences(result, sent_sim)
		
		#2 topic sentences are selected, since the cluster average is 5.2 and a single sentence cannot cover all the other edges with this values
		assert_equal(1, result[0].topic_sentences.length) #this is the first cluster
		assert_equal(1, result[0].topic_sentences[0].ID)
		
		assert_equal(1, result[1].topic_sentences.length) #this is the second cluster
		assert_equal(2, result[1].topic_sentences[0].ID) #2 is the first sentence in the cluster and is selected as the topic sentence
  end
   
  #false coverage of "distinct" sentences
  def test_coverage1
	  text1 = ["He played the guitar."] 
    text2 = ["This is funny."] 
    text3 = ["The fruit tastes fantastic."]
	  subm_text = Array.new
    subm_text << text1
    subm_text << text2
    subm_text << text3
    
    #setting up sentences and similarities before generation of clusters
    subm_sents = Array.new #Sentence[] s = new Sentence[2]; 
    g = GraphGenerator.new
    g.generate_graph(subm_text[0], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[1], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[2], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(2, g.vertices, g.edges, g.num_vertices, g.num_edges)
    
	  #calculating sentence similarity
    ssim = SentenceSimilarity.new
    #sentence similarity
    sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    sent_list = ssim.sim_list
    sim_threshold = ssim.sim_threshold
       
    cg = ClusterGeneration.new
    #cluster creation      
    result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
    #2 clusters are created
	  
    topic = Array.new
	  topic << subm_sents[0]
	  sentsToCover = Array.new
    sentsToCover << subm_sents[1]
	  sentsToCover << subm_sents[2]
	  
    #identifying topic sentences
    tsent = TopicSentenceIdentification.new
    result = tsent.coverage(topic, 1, sentsToCover, sent_sim, 4) #setting edge similarity = 4   
    assert_equal(false, result)
			
		#change in sentence covered state
		assert_equal(false, subm_sents[0].flag_covered)
		assert_equal(false, subm_sents[1].flag_covered)
		assert_equal(false, subm_sents[2].flag_covered)
	end

  #true coverage of distinct sentences, since threshold is set to "0"
  def test_coverage2
	  text1 = ["He played the guitar."] 
    text2 = ["This is funny."] 
    text3 = ["The fruit tastes fantastic."]
	  subm_text = Array.new
    subm_text << text1
    subm_text << text2
    subm_text << text3
    
    #setting up sentences and similarities before generation of clusters
    subm_sents = Array.new #Sentence[] s = new Sentence[2]; 
    g = GraphGenerator.new
    g.generate_graph(subm_text[0], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[1], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[2], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(2, g.vertices, g.edges, g.num_vertices, g.num_edges)
	   #calculating sentence similarity
    ssim = SentenceSimilarity.new
    #sentence similarity
    sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    sent_list = ssim.sim_list
    sim_threshold = ssim.sim_threshold     
    
    topic = Array.new
	  topic << subm_sents[0]
    sentsToCover = Array.new
    sentsToCover << subm_sents[1]
    sentsToCover << subm_sents[2]
	  
    #identifying topic sentences
    tsent = TopicSentenceIdentification.new
    result = tsent.coverage(topic, 1, sentsToCover, sent_sim, 4) #setting edge similarity = 4   
    assert_equal(false, result)
			
		#change in sentence covered state
    assert_equal(false, subm_sents[0].flag_covered) #subm_sents[0] not among the sentences to be covered
    assert_equal(false, subm_sents[1].flag_covered)
    assert_equal(false, subm_sents[2].flag_covered)
	end
   
  #true coverage even if one of the sentences (exact match) is covered!
  def test_coverage3
	  text1 = ["He played the guitar."] 
    text2 = ["This is funny."] 
    text3 = ["He played the guitar."]
	  subm_text = Array.new
    subm_text << text1
    subm_text << text2
    subm_text << text3
    
    #setting up sentences and similarities before generation of clusters
    subm_sents = Array.new #Sentence[] s = new Sentence[2]; 
    g = GraphGenerator.new
    g.generate_graph(subm_text[0], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[1], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[2], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(2, g.vertices, g.edges, g.num_vertices, g.num_edges)
    
	  #calculating sentence similarity
    ssim = SentenceSimilarity.new
    #sentence similarity
    sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    sent_list = ssim.sim_list
    sim_threshold = ssim.sim_threshold
	  
    topic = Array.new
	  topic << subm_sents[0]
    sentsToCover = Array.new
    sentsToCover << subm_sents[0]
    sentsToCover << subm_sents[1]
    sentsToCover << subm_sents[2]
	  
    #identifying topic sentences
    tsent = TopicSentenceIdentification.new
    result = tsent.coverage(topic, 1, sentsToCover, sent_sim, 6) #setting edge similarity = 4   
    assert_equal(true, result)
			
	  #change in sentence covered state
    assert_equal(true, subm_sents[0].flag_covered)
	  assert_equal(false, subm_sents[1].flag_covered)
	  assert_equal(true, subm_sents[2].flag_covered)
	end
  
  #true coverage even if one of the sentences is covered!
  def testCoverage4
	  text1 = ["He played the guitar."] 
    text2 = ["He played the flute."] 
    text3 = ["This is funny."]
	  subm_text = Array.new
    subm_text << text1
    subm_text << text2
    subm_text << text3
    
    #setting up sentences and similarities before generation of clusters
    subm_sents = Array.new #Sentence[] s = new Sentence[2]; 
    g = GraphGenerator.new
    g.generate_graph(subm_text[0], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[1], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges)
    g.generate_graph(subm_text[2], pos_tagger, core_NLP_tagger, false, false)
    subm_sents << Sentence.new(2, g.vertices, g.edges, g.num_vertices, g.num_edges)
    
	  #calculating sentence similarity
    ssim = SentenceSimilarity.new
    #sentence similarity
    sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    sent_list = ssim.sim_list
    sim_threshold = ssim.sim_threshold
    
    topic = Array.new
    topic << subm_sents[0]
    sentsToCover = Array.new
    sentsToCover << subm_sents[0]
    sentsToCover << subm_sents[1]
    sentsToCover << subm_sents[2]
	     
    #identifying topic sentences
    tsent = TopicSentenceIdentification.new
    result = tsent.coverage(topic, 1, sentsToCover, sent_sim, 3)
    assert_equal(true, result)
      
    #change in sentence covered state
    assert_equal(true, subm_sents[0].flag_covered)
    assert_equal(true, subm_sents[1].flag_covered)
    assert_equal(false, subm_sents[2].flag_covered)
  end
end