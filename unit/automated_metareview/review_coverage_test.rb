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

class ReviewCoverageTest < Test::Unit::TestCase
  attr_accessor :pos_tagger, :core_NLP_tagger, :speller
  def setup
    #initializing the pos tagger and nlp tagger/semantic parser  
    @pos_tagger = EngTagger.new
    @core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
    @g = GraphGenerator.new
    #initializing the speller
    @speller = FFI::Aspell::Speller.new('en_US')
  end
  
  #identifying coverage when review and submission texts have exact overlaps
  def test_identify_review_coverage1
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
		
		review = ["The sweet potatoes in the vegetable bin are green with mold."]
		g.generate_graph(review, pos_tagger, core_NLP_tagger, false, false)
    rev_sents = Array.new
    rev_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
		
		#identifying coverage
		revCov = ReviewCoverage.new
		cover = revCov.review_topic_sentence_overlaps(rev_sents, result, pos_tagger, speller)
		assert_equal(6, cover)
  end

  #identifying coverage when review and submission texts have distinct texts
  def test_identify_review_coverage2
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
		#result contains only 1 cluster containing both sentences in order 1 -> 0
		
		#identifying topic sentences
		tsent = TopicSentenceIdentification.new
    tsent.find_topic_sentences(result, sent_sim)
		
		review = ["This sounds funny."]
	  g.generate_graph(review, pos_tagger, core_NLP_tagger, false, false)
    rev_sents = Array.new
    rev_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
    
    #identifying coverage
    revCov = ReviewCoverage.new
    cover = revCov.review_topic_sentence_overlaps(rev_sents, result, pos_tagger, speller)
    assert_equal(0, cover)
 end 
   #across clusters - only one of the clusters is covered by the review sentence
   def test_identify_review_coverage3
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
       
     #cluster generation
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     #result contains only 1 cluster containing both sentences in order 1 -> 0
       
     #identifying topic sentences
     tsent = TopicSentenceIdentification.new
     tsent.find_topic_sentences(result, sent_sim)
     
     review = ["He played the guitar."]
     g.generate_graph(review, pos_tagger, core_NLP_tagger, false, false)
     rev_sents = Array.new
     rev_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
    
     #identifying coverage
     revCov = ReviewCoverage.new
     cover = revCov.review_topic_sentence_overlaps(rev_sents, result, pos_tagger, speller)
     assert_equal(3.25, cover)
    
     #first cluster with sentence 1 - coverage = 0, second cluster with sentences 0 and 2 - coverage = 6, avg = 3
     assert_equal(0.5, result[0].degree_covered_by_review)
     assert_equal(6, result[1].degree_covered_by_review)
   end
 
   #both clusters are covered by one sentence in the review each.
   def test_identify_review_coverage4
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
       
     #cluster generation
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     #result contains only 1 cluster containing both sentences in order 1 -> 0
     
     #identifying topic sentences
     tsent = TopicSentenceIdentification.new
     tsent.find_topic_sentences(result, sent_sim)
     
     review1 = ["He played the guitar."]
     review2 = ["This is funny."]
     rev_sents = Array.new
     g.generate_graph(review1, pos_tagger, core_NLP_tagger, false, false)
     rev_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
     g.generate_graph(review2, pos_tagger, core_NLP_tagger, false, false)
     rev_sents << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges)
       
     #identifying coverage
     revCov = ReviewCoverage.new
     cover = revCov.review_topic_sentence_overlaps(rev_sents, result, pos_tagger, speller)
     
     #first cluster with sentence 1 - coverage = 6, second cluster with sentences 0 and 2 - coverage = 6, avg = 3
#     puts "result[0] #{result[0].topic_sentences.length}"
#     puts "result[0].topic_sentences.vertices.length #{result[0].topic_sentences[0].vertices.length}"
#     puts "result[0].topic_sentences.vertices.length #{result[0].topic_sentences[0].vertices[0].name}"
#     puts "result[0].topic_sentences.vertices.length #{result[0].topic_sentences[0].vertices[1].name}"
#     puts "result[1].topic_sentences.vertices.length #{result[1].topic_sentences[0].vertices.length}"
#     puts "result[1].topic_sentences.vertices.length #{result[1].topic_sentences[0].vertices[0].name}"
#     puts "result[1].topic_sentences.vertices.length #{result[1].topic_sentences[0].vertices[1].name}"
     assert_equal(1.75, result[0].degree_covered_by_review)
     assert_equal(3.1, (result[1].degree_covered_by_review * 10).round/10.0)
   end

   #both clusters are covered by one sentence in the review each - one 
   def test_identify_review_coverage5
   	 text1 = ["He played the guitar."] 
     text2 = ["This is funny."]
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
       
     #cluster generation
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)

     #identifying topic sentences
     tsent = TopicSentenceIdentification.new
     tsent.find_topic_sentences(result, sent_sim)
     
     #review text
     review1 = ["He played the guitar."] 
     review2 = ["This is funny."]
     rev_sents = Array.new
     g.generate_graph(review1, pos_tagger, core_NLP_tagger, false, false)
     rev_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
     g.generate_graph(review2, pos_tagger, core_NLP_tagger, false, false)
     rev_sents << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges)
       
     #identifying coverage
     revCov = ReviewCoverage.new
     cover = revCov.review_topic_sentence_overlaps(rev_sents, result, pos_tagger, speller)
     #first cluster with sentence 1 - coverage = 6, second cluster with sentences 0 and 2 - coverage = 6, avg = 3
     assert_equal(1.75, result[0].degree_covered_by_review);
     assert_equal(2.3, (result[1].degree_covered_by_review * 10).round/10.0)
     #average coverage
     assert_equal((((1.75+2.3).round/2) * 10).round/10.0, (cover * 10).round/10.0)
   end

#    The average coverage may be lower due to random selection of topic sentence to cover. 
#    Consider the above case for instance, sentence ""He played the flute." is selected as topic sentence, 
#    since it is the first sentence in cluster "2" to which sentence "0" is added. 
#    But the review contains the sentence that wasn't selected as the topic sentence! - 
#    Therefore sub-optimal coverage matching value is achieved as a result.
   
#   3 clusters, 1 fully covered, 2nd partly covered and 3rd - completely uncovered.
    def test_identify_review_coverage6
	    text1 = ["He played the guitar."] 
      text2 = ["This is funny."] 
      text3 = ["He played the flute."]
	   	text4 = ["The aligator swam in the pond."]
	   	subm_text = Array.new
      subm_text << text1
      subm_text << text2
      subm_text << text3
      subm_text << text4
      
	   	#setting up sentences and similarities before generation of clusters
     subm_sents = Array.new #Sentence[] s = new Sentence[2]; 
     g = GraphGenerator.new
     g.generate_graph(subm_text[0], pos_tagger, core_NLP_tagger, false, false)
     subm_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
     g.generate_graph(subm_text[1], pos_tagger, core_NLP_tagger, false, false)
     subm_sents << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges)
     g.generate_graph(subm_text[2], pos_tagger, core_NLP_tagger, false, false)
     subm_sents << Sentence.new(2, g.vertices, g.edges, g.num_vertices, g.num_edges)
	   g.generate_graph(subm_text[3], pos_tagger, core_NLP_tagger, false, false)
     subm_sents << Sentence.new(3, g.vertices, g.edges, g.num_vertices, g.num_edges)
     
	   #calculating sentence similarity
     ssim = SentenceSimilarity.new
     #sentence similarity
     sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
     sent_list = ssim.sim_list
     sim_threshold = ssim.sim_threshold
	       
	   #cluster generation
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
	       
     #identifying topic sentences
     tsent = TopicSentenceIdentification.new
     tsent.find_topic_sentences(result, sent_sim)
     
	   review1 = ["He played the guitar."] 
     review2 = ["This is funny."] #complete coverage of only one cluster
	   rev_sents = Array.new
     g.generate_graph(review1, pos_tagger, core_NLP_tagger, false, false)
     rev_sents << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
     g.generate_graph(review2, pos_tagger, core_NLP_tagger, false, false)
     rev_sents << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges)
	       
	   #identifying coverage
     revCov = ReviewCoverage.new
     cover = revCov.review_topic_sentence_overlaps(rev_sents, result, pos_tagger, speller)
     
	   #first cluster with sentence 1 - coverage = 6, second cluster with sentences 0 and 2 - coverage = 6, avg = 3
	   assert_equal(1.75, result[0].degree_covered_by_review)
	   assert_equal(2.3, (result[1].degree_covered_by_review * 10).round/10.0)
	   assert_equal(0, (result[2].degree_covered_by_review * 10).round/10.0)
	   #average coverage
	   assert_equal(((1.75+2.3+0)/3 * 10).round/10.0, (cover * 10).round/10.0)
	 end
   
 
   #testing if the clusters' average coverage is calculated correctly
   def test_calculate_cluster_coverage1
	   #cluster generation
     cg = ClusterGeneration.new
     #cluster creation      
     clust = Array.new 
     clust << Cluster.new(0, 5, 0)
     clust << Cluster.new(1, 2, 0)
     clust << Cluster.new(2, 3, 0)
     clust << Cluster.new(3, 5, 0)
	    
     clust[0].degree_covered_by_review = 3
     clust[1].degree_covered_by_review = 3
     clust[2].degree_covered_by_review = 2
	    
     #identifying coverage
     revCov = ReviewCoverage.new
     cover = revCov.calculate_cluster_coverage(clust)
	   assert_equal(2.0, (cover *10).round/10.0)
	 end
   
   def test_calculate_cluster_coverage2
	   #generating clusters
	   cg = ClusterGeneration.new
	   #cluster creation      
     clust = Array.new 
	   clust << Cluster.new(0, 5, 0)
	   clust << Cluster.new(1, 2, 0)
	   clust << Cluster.new(2, 3, 0)
		    
	   clust[0].degree_covered_by_review = 0
	   clust[1].degree_covered_by_review = 0
	   clust[2].degree_covered_by_review = 0
		    
	   #identifying coverage
     revCov = ReviewCoverage.new
     cover = revCov.calculate_cluster_coverage(clust)
		 assert_equal(0, cover)
	end
end
