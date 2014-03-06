require 'test/unit'
require 'tone'
require 'text_preprocessing'
gem 'stanford-core-nlp', '=0.3.0'
require 'stanford-core-nlp'
require 'ffi/aspell'
require 'sentence'
require 'sentence_similarity'
require 'cluster_generation'


class ClusterGenerationTest < Test::Unit::TestCase
  attr_accessor :pos_tagger, :core_NLP_tagger, :review_vertices, :subm_vertices, :num_rev_vert, :num_sub_vert, :review_edges, :subm_edges, :num_rev_edg, :num_sub_edg, :speller
    def setup
      #initializing the pos tagger and nlp tagger/semantic parser  
      @pos_tagger = EngTagger.new
      @core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
      @g = GraphGenerator.new
      #initializing the speller
      @speller = FFI::Aspell::Speller.new('en_US')
    end

   def test_cluster_creation1
     #creating a test review array
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
     subm_sents << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges);
     
     #calculating sentence similarity
     ssim = SentenceSimilarity.new
     #sentence similarity
     sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
     sent_list = ssim.sim_list
     sim_threshold = ssim.sim_threshold
     cg = ClusterGeneration.new
     #ranked sentences
     ranked_array = cg.rank_sentences(sent_sim, sent_list)
        
     #assert statements for the rankedArray - sentence IDS
     assert_equal(0, ranked_array[0][0])
     assert_equal(1, ranked_array[0][1])
        
     #cluster creation  		
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
        
     #assert statements
     assert_equal(1, result.length)
#     puts "result[0].sent_counter #{result[0].sent_counter}"
     assert_equal(2, result[0].sent_counter)
#     assert_equal(2, result[1].sent_counter)
   end

   def test_cluster_creation1_1
      #creating a test review array
     text1 = ["He played the guitar."]
     text2 = ["This is funny."]
     subm_text = Array.new
     subm_text << text1
     subm_text << text2
    	
     #setting up sentences and similarities before generation of clusters
     src = SentenceSimilarity.new
     s = Array.new 
     g = GraphGenerator.new
     g.generate_graph(subm_text[0], pos_tagger, core_NLP_tagger, false, false)
     s << Sentence.new(0, g.vertices, g.edges, g.num_vertices, g.num_edges)
     g.generate_graph(subm_text[1], pos_tagger, core_NLP_tagger, false, false) 
     s << Sentence.new(1, g.vertices, g.edges, g.num_vertices, g.num_edges)
     #calculating sentence similarity
     ssim = SentenceSimilarity.new
        
     #sentence similarity
     sent_sim = ssim.get_sentence_similarity(pos_tagger, s, speller)
     sent_list = ssim.sim_list
     sim_threshold = ssim.sim_threshold
     
     cg = ClusterGeneration.new
     #ranked sentences
     rankedArray = cg.rank_sentences(sent_sim, sent_list)
        
     #assert statements for the rankedArray - sentence IDS
     assert_equal(0, rankedArray[0][0])
     assert_equal(1, rankedArray[0][1])
        
     #cluster creation  		
     result = cg.generate_clusters(s, sent_sim, sent_list, sim_threshold)
        
     #assert statements
     assert_equal(2, result.length) #two clusters are created, since the similarity between them is 0
     assert_equal(1, result[0].sent_counter)
     assert_equal(1, result[1].sent_counter)
   end

   def test_cluster_creation1_2
     #creating a test review array
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
     #ranked sentences
     ranked_array = cg.rank_sentences(sent_sim, sent_list)
        
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     
     #assert statements for the clusters
     #three clusters are formed but ones with high avg similarity are returned
     assert_equal(2, result.length) #initially 3 clusters are created
     
     assert_equal(1, result[0].sent_counter)  #the first cluster contains 0 sentences
     assert_equal(2, result[1].sent_counter)  #the second cluster contains only 1 sentence
        
     #checking sentence IDS
     assert_equal(1, result[0].sentences[0].ID) #IDS of sentences in the different clusters
     assert_equal(2, result[1].sentences[0].ID)
     assert_equal(0, result[1].sentences[1].ID)
   end

   def test_cluster_creation1_3
     #creating a test review array
     text1 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text2 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text3 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text4 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text5 = ["The sweet potatoes in the vegetable bin are green with mold."]
     subm_text = Array.new
     subm_text << text1
     subm_text << text2
     subm_text << text3
     subm_text << text4
     subm_text << text5
     
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
     g.generate_graph(subm_text[4], pos_tagger, core_NLP_tagger, false, false)
     subm_sents << Sentence.new(4, g.vertices, g.edges, g.num_vertices, g.num_edges)
     
     #calculating sentence similarity
     ssim = SentenceSimilarity.new
     #sentence similarity
     sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
     sent_list = ssim.sim_list
     sim_threshold = ssim.sim_threshold
     
     cg = ClusterGeneration.new
     #ranked sentences
     ranked_array = cg.rank_sentences(sent_sim, sent_list)
     #checking rankedArray's length
     assert_equal(10, ranked_array.length)
        
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
        
     #assert statements
     #assert statements for the clusters
     assert_equal(1, result.length)  #initially 5 clusters are created
     assert_equal(5, result[0].sent_counter) #the first cluster contains 0 sentences
#     assert_equal(5, result[1].sent_counter) #the second cluster contains all the 5 sentences
#     assert_equal(0, result[2].sent_counter)
#     assert_equal(0, result[3].sent_counter)
#     assert_equal(0, result[4].sent_counter)
        
     #checking sentence IDS
     assert_equal(1, result[0].sentences[0].ID) #IDS of sentences in the different clusters
     assert_equal(0, result[0].sentences[1].ID)
     assert_equal(2, result[0].sentences[2].ID)
     assert_equal(3, result[0].sentences[3].ID)
     assert_equal(4, result[0].sentences[4].ID)
   end
 
   def test_cluster_creation1_3
     #creating a test review array
     text1 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text2 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text3 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text4 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text5 = ["The sweet potatoes in the vegetable bin are green with mold."]
     subm_text = Array.new
     subm_text << text1
     subm_text << text2
     subm_text << text3
     subm_text << text4
     subm_text << text5
     
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
     g.generate_graph(subm_text[4], pos_tagger, core_NLP_tagger, false, false)
     subm_sents << Sentence.new(4, g.vertices, g.edges, g.num_vertices, g.num_edges)
     
     #calculating sentence similarity
     ssim = SentenceSimilarity.new
     #sentence similarity
     sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
     sent_list = ssim.sim_list
     sim_threshold = ssim.sim_threshold
     
     cg = ClusterGeneration.new
     #ranked sentences
     ranked_array = cg.rank_sentences(sent_sim, sent_list)
     #checking rankedArray's length
     assert_equal(10, ranked_array.length)
        
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
        
     #assert statements
     #assert statements for the clusters
     assert_equal(1, result.length)  #initially 5 clusters are created
     assert_equal(5, result[0].sent_counter) #the first cluster contains 0 sentences
#     assert_equal(5, result[1].sent_counter) #the second cluster contains all the 5 sentences
#     assert_equal(0, result[2].sent_counter)
#     assert_equal(0, result[3].sent_counter)
#     assert_equal(0, result[4].sent_counter)
        
     #checking sentence IDS
     assert_equal(1, result[0].sentences[0].ID) #IDS of sentences in the different clusters
     assert_equal(0, result[0].sentences[1].ID)
     assert_equal(2, result[0].sentences[2].ID)
     assert_equal(3, result[0].sentences[3].ID)
     assert_equal(4, result[0].sentences[4].ID)
 end
 
   def test_cluster_generation1
     #creating a test review array
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
        
     #assert statements
     #assert statements for the clusters
     assert_equal(1, result.length)  #finally only 1 cluster exists, containing both sentences
     assert_equal(2, result[0].sent_counter)  #the single cluster contains two sentences
 end

   def test_cluster_generation2
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "This is funny."]
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
     #checking the threshold value that is to be set
#     assert_equal(0, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
        
     #assert statements
     #assert statements for the clusters
     #assert statements
     assert_equal(2, result.length) #two clusters are created, since the similarity between them is 0
     assert_equal(1, result[0].sent_counter)
     assert_equal(1, result[1].sent_counter)
   end


   def test_cluster_generation3
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "This is funny."]
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
     #checking the threshold value that is to be set
#     assert_equal(1.9, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
        
     #assert statements
     assert_equal(2, result.length)  #finally only 1 cluster exists, containing both sentences
     assert_equal(1, result[0].sent_counter)  #the single cluster contains two sentences
     assert_equal(2, result[1].sent_counter)  #the single cluster contains two sentences
        
     #checking sentence IDS
     assert_equal(1, result[0].sentences[0].ID)  #the single cluster contains two sentences
     assert_equal(2, result[1].sentences[0].ID)  #2 was already in the cluster
     assert_equal(0, result[1].sentences[1].ID)  #1 was then added to the cluster
   end
    
   def test_cluster_generation4
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "He played the flute."]
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
     #checking the threshold value that is to be set
#     assert_equal(1.6, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
        
     #assert statements
     assert_equal(1, result.length)  #only 1 cluster exists, containing both sentences
     assert_equal(2, result[0].sent_counter)  #the single cluster contains two sentences
        
     #checking sentence IDS
     assert_equal(1, result[0].sentences[0].ID) #1 was already in the cluster
     assert_equal(0, result[0].sentences[1].ID) #0 was then added to the cluster
   end
 

   def test_cluster_generation5
     #creating a test review array
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
     #checking the threshold value that is to be set
#     assert_equal(3.8, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
        
     #assert statements
     assert_equal(2, result.length) #2 distinct clusters are created
     assert_equal(1, result[0].sent_counter) #first cluster contains sentence 1, since sentence 0 is added to cluster 2 containing sentence 2
     assert_equal(2, result[1].sent_counter) #the single cluster contains two sentences
        
     #checking cluster IDS
     assert_equal(1, result[0].ID) #cluster 0 was eliminated
     assert_equal(2, result[1].ID)
   end

   def test_rank_sentences_1
     #creating a test review array
     text1 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text2 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text3 = ["The sweet potatoes in the vegetable bin are green with mold."]
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
     #checking the threshold value that is to be set
#     assert_equal(0, sim_threshold)
     
     cg = ClusterGeneration.new
     #ranked sentences
     ranked_array = cg.rank_sentences(sent_sim, sent_list)
        
     #assert statements
     assert_equal(3, ranked_array.length)
     #first sentence pair
     assert_equal(0, ranked_array[0][0])
     assert_equal(1, ranked_array[0][1])
     #second sentence pair
     assert_equal(0, ranked_array[1][0])
     assert_equal(2, ranked_array[1][1])
     #third sentence pair
     assert_equal(1, ranked_array[2][0])
     assert_equal(2, ranked_array[2][1]) 
 end
 
  
   def test_rank_sentences1_1
     #creating a test review array
     text1 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text2 = [ "The sweet potatoes in the vegetable bin are green with mold."]
     text3 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text4 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text5 = ["The sweet potatoes in the vegetable bin are green with mold."]
     subm_text = Array.new
     subm_text << text1
     subm_text << text2
     subm_text << text3
     subm_text << text4
     subm_text << text5
     
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
     g.generate_graph(subm_text[4], pos_tagger, core_NLP_tagger, false, false)
     subm_sents << Sentence.new(4, g.vertices, g.edges, g.num_vertices, g.num_edges)
     
     #calculating sentence similarity
     ssim = SentenceSimilarity.new
     #sentence similarity
     sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
     sent_list = ssim.sim_list
     sim_threshold = ssim.sim_threshold
     #checking the threshold value that is to be set
#     assert_equal(0, sim_threshold)
     
     cg = ClusterGeneration.new
     #ranked sentences
     ranked_array = cg.rank_sentences(sent_sim, sent_list)
        
     #assert statements for ranked sentence
     assert_equal(10, ranked_array.length);
     assert_equal(0, ranked_array[0][0]) #first sentence pair
     assert_equal(1, ranked_array[0][1])
     assert_equal(0, ranked_array[1][0]) #second sentence pair
     assert_equal(2, ranked_array[1][1])
     assert_equal(0, ranked_array[2][0]) #third sentence pair
     assert_equal(3, ranked_array[2][1])
     assert_equal(0, ranked_array[3][0])
     assert_equal(4, ranked_array[3][1])
     assert_equal(1, ranked_array[4][0])
     assert_equal(2, ranked_array[4][1])
     assert_equal(1, ranked_array[5][0])
     assert_equal(3, ranked_array[5][1])
     assert_equal(1, ranked_array[6][0])
     assert_equal(4, ranked_array[6][1])
     assert_equal(2, ranked_array[7][0])
     assert_equal(3, ranked_array[7][1])
     assert_equal(2, ranked_array[8][0])
     assert_equal(4, ranked_array[8][1])
     assert_equal(3, ranked_array[9][0])
     assert_equal(4, ranked_array[9][1])
   end

   def test_rank_sentences1_2
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "This is funny."]
     text3 = ["He played the flute."]
     subm_text = Array.new
     subm_text << text1
     subm_text << text2
     subm_text << text3
     
     #setting up sentences and similarities before generation of clusters
     subm_sents = Array.new  
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
     #checking the threshold value that is to be set
#     assert_equal(4.1, sim_threshold)
     
     cg = ClusterGeneration.new
     #ranked sentences
     ranked_array = cg.rank_sentences(sent_sim, sent_list)
        
     assert_equal(3, ranked_array.length)
     #first sentence pair
     assert_equal(0, ranked_array[0][0])  #4.833333333333334
     assert_equal(2, ranked_array[0][1])
     #second sentence pair
     assert_equal(1, ranked_array[1][0])
     assert_equal(2, ranked_array[1][1])
     #third sentence pair
     assert_equal(0, ranked_array[2][0])
     assert_equal(1, ranked_array[2][1])
   end
    
   def test_rank_sentences1_3
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "He played the flute."]
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
     #checking the threshold value that is to be set
#     assert_equal(0.8, sim_threshold)
     
     cg = ClusterGeneration.new
     #ranked sentences
     ranked_array = cg.rank_sentences(sent_sim, sent_list)
        
     #assert statements for ranked sentence
     assert_equal(3, ranked_array.length)
     #first sentence pair
     assert_equal(1, ranked_array[0][0])
     assert_equal(2, ranked_array[0][1])
     #second sentence pair
     assert_equal(0, ranked_array[1][0])  #4.833333333333334
     assert_equal(1, ranked_array[1][1])
     #third sentence pair
     assert_equal(0, ranked_array[2][0])  #4.833333333333334
     assert_equal(2, ranked_array[2][1])
   end
 
   def test_cluster_generation6
     #creating a test review array
     text1 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text2 = [ "The sweet potatoes in the vegetable bin are green with mold."]
     text3 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text4 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text5 = ["The sweet potatoes in the vegetable bin are green with mold."]
     subm_text = Array.new
     subm_text << text1
     subm_text << text2
     subm_text << text3
     subm_text << text4
     subm_text << text5
     
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
     g.generate_graph(subm_text[4], pos_tagger, core_NLP_tagger, false, false)
     subm_sents << Sentence.new(4, g.vertices, g.edges, g.num_vertices, g.num_edges)
     
     #calculating sentence similarity
     ssim = SentenceSimilarity.new
     #sentence similarity
     sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
     sent_list = ssim.sim_list
     sim_threshold = ssim.sim_threshold
     #checking the threshold value that is to be set
#     assert_equal(0, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     
    # puts "ClusterGeneration.sent_density_thresh #{ClusterGeneration.sent_density_thresh}"
     #assert statement for the sentence density threshold
     assert_equal(1, ClusterGeneration.sent_density_thresh)
        
     #assert statements
     assert_equal(1, result.length)  #only 1 cluster is created
     assert_equal(5, result[0].sent_counter)
        
     #checking cluster IDS
     assert_equal(1, result[0].ID); 
     #the first sentence is added to cluster 1 and then its similarity increases as a result of which all sentences are added to it
        
     #checking sentence IDS
     assert_equal(1, result[0].sentences[0].ID) #1 was already in the cluster
     assert_equal(0, result[0].sentences[1].ID) #0 was then added to the cluster
     assert_equal(2, result[0].sentences[2].ID) #2 was then added to the cluster
     assert_equal(3, result[0].sentences[3].ID) #3 was then added to the cluster
     assert_equal(4, result[0].sentences[4].ID) #4 was then added to the cluster
   end

  def test_sentence_density1
     #creating a test review array
     text1 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text2 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text3 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text4 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text5 = ["The sweet potatoes in the vegetable bin are green with mold."]
     subm_text = Array.new
     subm_text << text1
     subm_text << text2
     subm_text << text3
     subm_text << text4
     subm_text << text5
     
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
     g.generate_graph(subm_text[4], pos_tagger, core_NLP_tagger, false, false)
     subm_sents << Sentence.new(4, g.vertices, g.edges, g.num_vertices, g.num_edges)
     
     #calculating sentence similarity
     ssim = SentenceSimilarity.new
     #sentence similarity
     sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
     sent_list = ssim.sim_list
     sim_threshold = ssim.sim_threshold
     #checking the threshold value that is to be set
#     assert_equal(0, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     
     #assert statement for the sentence density threshold
     assert_equal(1, ClusterGeneration.sent_density_thresh)
 end
 
 
   def test_calculate_sentence_similarities_within_cluster1
     #creating a test review array
     text1 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text2 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text3 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text4 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text5 = ["The sweet potatoes in the vegetable bin are green with mold."]
     subm_text = Array.new
     subm_text << text1
     subm_text << text2
     subm_text << text3
     subm_text << text4
     subm_text << text5
     
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
     g.generate_graph(subm_text[4], pos_tagger, core_NLP_tagger, false, false)
     subm_sents << Sentence.new(4, g.vertices, g.edges, g.num_vertices, g.num_edges)
     
     #calculating sentence similarity
     ssim = SentenceSimilarity.new
     #sentence similarity
     sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
     sent_list = ssim.sim_list
     sim_threshold = ssim.sim_threshold
     #checking the threshold value that is to be set
#     assert_equal(0, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     cg.calculate_sentence_similarities_within_cluster(result, sent_sim)
     
     #assert statement for the sentence density threshold
     assert_equal(6, result[0].avg_similarity) #only 1 cluster is created
 end
 
   def test_calculate_sentence_similarities_within_cluster2
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = ["This is funny."]
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
     #checking the threshold value that is to be set
#     assert_equal(5.8, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     cg.calculate_sentence_similarities_within_cluster(result, sent_sim)
     
     #assert statement for the sentence density threshold
     assert_equal(6, result[0].avg_similarity)
     assert_equal(6, result[1].avg_similarity)
 end
      
   def test_calculate_sentence_similarities_within_cluster3
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "This is funny."]
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
     #checking the threshold value that is to be set
#     assert_equal(3.1, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     cg.calculate_sentence_similarities_within_cluster(result, sent_sim)
     
     #assert statement for the sentence density threshold
     assert_equal(6, result[0].avg_similarity)
#     assert_equal(6, result[1].avg_similarity)
   end


   def test_calculate_sentence_similarities_within_cluster4
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "He played the flute."]
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
     #checking the threshold value that is to be set
#     assert_equal(0, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     cg.calculate_sentence_similarities_within_cluster(result, sent_sim)
     
     #assert statement for the sentence density threshold
     assert_equal(2, result.length)
     assert_equal(6, result[0].avg_similarity)
     assert_equal(6, result[1].avg_similarity)
   end
  
  def test_calculate_sentence_similarities_within_cluster5
     #creating a test review array
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
     #checking the threshold value that is to be set
#     assert_equal(2.8, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     cg.calculate_sentence_similarities_within_cluster(result, sent_sim)
     
     #assert statement for the sentence density threshold
     assert_equal(6, result[0].avg_similarity)
     assert_equal(1, result[0].sent_counter)
     assert_equal(2, result[1].sent_counter)
     assert_equal(4.4, (result[1].avg_similarity*10).round/10.0)
 end
 
  
   def test_calculate_sentence_similarities_within_cluster6
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = ["He played the flute."]
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
     cg.calculate_sentence_similarities_within_cluster(result, sent_sim)
     
     #assert statement for the sentence density threshold
#     puts "result[0].avg_similarity #{result[0].avg_similarity}"
#     puts "(result[0].avg_similarity * 10).round #{(result[0].avg_similarity * 10).round}"
     assert_equal(4.4, (result[0].avg_similarity * 10).round/10.0)
     assert_equal(2, result[0].sent_counter)
#     assert_equal(4.41666666666667, result[1].avg_similarity)
   end
    
   def test_calculate_sentence_similarities_within_cluster7
     #creating a test review array
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
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     cg.calculate_sentence_similarities_within_cluster(result, sent_sim)
     
     #assert statement for the sentence density threshold
     assert_equal(2, result.length)
     assert_equal(4.4, (result[1].avg_similarity * 10).round/10.0)
     assert_equal(6, result[0].avg_similarity) #has no sentences to be matched with in the cluster, therefore similarity = 0
  end
  
   def test_calculate_sentence_similarities_within_cluster8
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "This is funny."]
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
     cg.calculate_sentence_similarities_within_cluster(result, sent_sim)
     
     #assert statement for the sentence density threshold
     assert_equal(6, result[0].avg_similarity)
     assert_equal(6, result[1].avg_similarity)
   end   


  def test_recalculate_cluster_similarity1
     #creating a test review array
     text1 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text2 = [ "The sweet potatoes in the vegetable bin are green with mold."]
     text3 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text4 = ["The sweet potatoes in the vegetable bin are green with mold."]
     text5 = ["The sweet potatoes in the vegetable bin are green with mold."]
     subm_text = Array.new
     subm_text << text1
     subm_text << text2
     subm_text << text3
     subm_text << text4
     subm_text << text5
     
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
     g.generate_graph(subm_text[4], pos_tagger, core_NLP_tagger, false, false)
     subm_sents << Sentence.new(4, g.vertices, g.edges, g.num_vertices, g.num_edges)
     
     
     #calculating sentence similarity
     ssim = SentenceSimilarity.new
     #sentence similarity
     sent_sim = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
     sent_list = ssim.sim_list
     sim_threshold = ssim.sim_threshold
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     cg.calculate_sentence_similarities_within_cluster(result, sent_sim)
     
     #assert statement for the sentence density threshold
     assert_equal(6, result[0].avg_similarity)
     assert_equal(5, result[0].sent_counter)
     assert_equal(5, result[0].sentences.length)
   end   

   def test_recalculate_cluster_similarity2
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "This is funny."]
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
     #checking the threshold value that is to be set
#     assert_equal(0, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     
     assert_equal(1, result[0].sent_counter)
     assert_equal(1, result[1].sent_counter)
     
     value1 = cg.recalculate_cluster_similarity(result[0], sent_sim)
     value2 = cg.recalculate_cluster_similarity(result[1], sent_sim)
     
     #assert statement for the sentence density threshold
     assert_equal(0, value1)
     assert_equal(0, value2)
   end 


   def test_recalculate_cluster_similarity3
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "He played the flute."]
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
     #checking the threshold value that is to be set
#     assert_equal(0.8, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     
     #sentence Sentence 1- 2 has the highest similarity value and so sentences are adde to cluster 2
     #first cluster's average similarity
     assert_equal(2, result.length)
     assert_equal(1, result[0].sent_counter)
     assert_equal(2, result[1].sent_counter)
     assert_equal(0, cg.recalculate_cluster_similarity(result[0], sent_sim))
     assert_equal(6, cg.recalculate_cluster_similarity(result[1], sent_sim))
     #second cluster's avg. similarity
#     assert_equal(0, cg.recalculate_cluster_similarity(result[1], sent_sim))
     #3rd cluster - contains edge 1-2 with similarity value 6
#     assert_equal(6, cg.recalculate_cluster_similarity(result[2], sent_sim))
   end  

   def test_recalculate_cluster_similarity4
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "This is funny."]
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
     #checking the threshold value that is to be set
#     assert_equal(0.8, sim_threshold)
     
     cg = ClusterGeneration.new
     #cluster creation      
     result = cg.generate_clusters(subm_sents, sent_sim, sent_list, sim_threshold)
     #only top clusters are selected
     assert_equal(2, result.length)
     assert_equal(1, result[0].sent_counter) #1 sentence in the second cluster
     assert_equal(0, cg.recalculate_cluster_similarity(result[0], sent_sim))
     #3rd cluster - contains edge 1-2 with similarity value 6
     assert_equal(2, result[1].sent_counter)
     assert_equal(4.4, (cg.recalculate_cluster_similarity(result[1], sent_sim)*10).round/10.0);
   end

   def test_checking_clustering_condition1
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "He played the guitar."]
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
     #checking the threshold value that is to be set
#     assert_equal(0.8, sim_threshold)
     
     cg = ClusterGeneration.new
     srcClust = Cluster.new(0, 0, 6)
     srcClust.sentences = Array.new #since a single cluster can contain atmost all sentences in the text
     srcClust.sentences[0] = subm_sents[0] #sentence 2 has to be in the original cluster
     srcClust.sent_counter = 1
     #cluster to which the sentence is to be added
     tgtClust = Cluster.new(1, 0, 6)
     tgtClust.sentences = Array.new
     tgtClust.sentences[0] = subm_sents[1]
     tgtClust.sent_counter = 1
    
     #sentence 2 can be added to the empty cluster, with
     result = cg.checkingClusteringCondition(subm_sents[2], tgtClust, srcClust, sent_sim, sim_threshold)
     assert_equal(true, result)
        
     #checking changes in the sentence
     assert_equal(1, tgtClust.sentences[1].cluster_ID)
        
     #checking changes in the target cluster
     assert_equal(2, tgtClust.sent_counter)
     assert_equal(6, (tgtClust.avg_similarity*10).round/10.0)
     assert_equal(1, tgtClust.sentences[0].ID)
     assert_equal(2, tgtClust.sentences[1].ID)        
        
     #checking changes in the original cluster
     assert_equal(0, srcClust.sent_counter)
     assert_equal(0.0, srcClust.avg_similarity)    
  end
 

   def test_checking_clustering_condition2
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = [ "He played the guitar."]
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
     #checking the threshold value that is to be set
#     assert_equal(0.8.double, sim_threshold)
     
     cg = ClusterGeneration.new
     srcClust = Cluster.new(0, 0, 4.5)
     srcClust.sentences = Array.new #since a single cluster can contain atmost all sentences in the text
     subm_sents[2].cluster_ID = 0
     srcClust.sentences[0] = subm_sents[2] #sentence 2 has to be in the original cluster
     srcClust.sent_counter = 1
     #cluster to which the sentence is to be added
     tgtClust = Cluster.new(1, 0, 6)
     tgtClust.sentences = Array.new
     subm_sents[0].cluster_ID = 1
     subm_sents[1].cluster_ID = 1
     tgtClust.sentences[0] = subm_sents[0]
     tgtClust.sentences[1] = subm_sents[1]
     tgtClust.sent_counter = 2
    
     #sentence 2 can be added to the empty cluster, with
     result = cg.checkingClusteringCondition(subm_sents[2], tgtClust, srcClust, sent_sim, sim_threshold)
     assert_equal(true, result)
        
     #checking changes in the sentence
     assert_equal(3, tgtClust.sentences.length)
     assert_equal(1, tgtClust.sentences[0].cluster_ID)
     assert_equal(1, tgtClust.sentences[1].cluster_ID)
     assert_equal(1, tgtClust.sentences[2].cluster_ID)
        
     #checking changes in the target cluster
     assert_equal(3, tgtClust.sent_counter)
     assert_equal(6, tgtClust.avg_similarity)
     assert_equal(0, tgtClust.sentences[0].ID)
     assert_equal(1, tgtClust.sentences[1].ID)        
     assert_equal(2, tgtClust.sentences[2].ID)   
      
     #checking changes in the sentence
     assert_equal(1, tgtClust.sentences[2].cluster_ID)   
     
     #checking changes in the original cluster
     assert_equal(0, srcClust.sent_counter)
     assert_equal(0, srcClust.avg_similarity)    
 end


  def test_checking_clustering_condition3
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = ["He played the flute."]
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
     #checking the threshold value that is to be set
#     assert_equal(0.8.double, sim_threshold)
     
     cg = ClusterGeneration.new
     srcClust = Cluster.new(0, 0, 0)
     srcClust.sentences = Array.new #since a single cluster can contain atmost all sentences in the text
     subm_sents[1].cluster_ID = 0
     srcClust.sentences[0] = subm_sents[1] #sentence 2 has to be in the original cluster
     srcClust.sent_counter = 1
     #cluster to which the sentence is to be added
     tgtClust = Cluster.new(1, 0, 6)
     tgtClust.sentences = Array.new
#     subm_sents[2].cluster_ID = 1
#     subm_sents[0].cluster_ID = 1
     tgtClust.sentences[0] = subm_sents[2]
     tgtClust.sentences[1] = subm_sents[0]
     tgtClust.sent_counter = 2
    
     #sentence 2 can be added to the empty cluster, with
     result = cg.checkingClusteringCondition(subm_sents[1], tgtClust, srcClust, sent_sim, sim_threshold)
     assert_equal(false, result)
        
     #checking changes in the target cluster
     assert_equal(2, tgtClust.sent_counter)
     assert_equal(6, tgtClust.avg_similarity)
     assert_equal(2, tgtClust.sentences[0].ID)
     assert_equal(0, tgtClust.sentences[1].ID)        
     
     #checking changes in the original cluster
     assert_equal(1, srcClust.sent_counter)
     assert_equal(0, srcClust.avg_similarity)
     assert_equal(1, srcClust.sentences[0].ID)
     
     assert_equal(0, srcClust.sentences[0].cluster_ID)
     
     #uninitialized cluster IDS
     assert_equal(-1, tgtClust.sentences[0].cluster_ID)
     assert_equal(-1, tgtClust.sentences[1].cluster_ID)
   end  
   
   def test_checking_clustering_condition4
     #creating a test review array
     text1 = ["He played the guitar."]
     text2 = ["He played the flute."]
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
     #checking the threshold value that is to be set
#     assert_equal(0.8.double, sim_threshold)
     
     cg = ClusterGeneration.new
     srcClust = Cluster.new(0, 0, 0)
     srcClust.sentences = Array.new #since a single cluster can contain atmost all sentences in the text
     srcClust.sentences[0] = subm_sents[1] #sentence 2 has to be in the original cluster
     srcClust.sent_counter = 1
     #cluster to which the sentence is to be added
     tgtClust = Cluster.new(1, 0, 0)
     tgtClust.sentences = Array.new
     tgtClust.sent_counter = 0
    
     #sentence 2 can be added to the empty cluster, with
     result = cg.checkingClusteringCondition(subm_sents[1], tgtClust, srcClust, sent_sim, sim_threshold)
     assert_equal(true, result)
     
     #checking changes in the target cluster
     assert_equal(1, tgtClust.sent_counter)
     assert_equal(0, tgtClust.avg_similarity)
     assert_equal(1, tgtClust.sentences[0].ID)
   end  


   def test_select_top_clusters1
     cg = ClusterGeneration.new
     clust = Array.new 
     clust[0] = Cluster.new(0, 5, 0)
     clust[1] = Cluster.new(1, 2, 0)
     clust[2] = Cluster.new(2, 3, 0)
     clust[3] = Cluster.new(3, 5, 0)
        
     ClusterGeneration.sent_density_thresh = 4
     select = cg.select_top_clusters(clust)
        
     #checking the set of selected clusters
     assert_equal(2, select.length)
     assert_equal(0, select[0].ID)
     assert_equal(3, select[1].ID)
   end  

    def test_select_top_clusters2
     cg = ClusterGeneration.new
     clust = Array.new 
     clust[0] = Cluster.new(0, 5, 0)
     clust[1] = Cluster.new(1, 2, 0)
     clust[2] = Cluster.new(2, 3, 0)
     clust[3] = Cluster.new(3, 5, 0)
        
     ClusterGeneration.sent_density_thresh = 5
     select = cg.select_top_clusters(clust)
        
     #checking the set of selected clusters
     assert_equal(2, select.length)
     assert_equal(0, select[0].ID)
     assert_equal(3, select[1].ID)
   end 
   
   def test_select_top_clusters3
     cg = ClusterGeneration.new
     clust = Array.new 
     clust[0] = Cluster.new(0, 5, 0)
     clust[1] = Cluster.new(1, 2, 0)
     clust[2] = Cluster.new(2, 3, 0)
     clust[3] = Cluster.new(3, 5, 0)
        
     ClusterGeneration.sent_density_thresh = 2
     select = cg.select_top_clusters(clust)
        
     #checking the set of selected clusters
     assert_equal(4, select.length)
     assert_equal(0, select[0].ID)
     assert_equal(1, select[1].ID)
     assert_equal(2, select[2].ID)
     assert_equal(3, select[3].ID)
   end 
   
   def test_select_top_clusters4
     cg = ClusterGeneration.new
     clust = Array.new 
     clust[0] = Cluster.new(0, 5, 0)
     clust[1] = Cluster.new(1, 2, 0)
     clust[2] = Cluster.new(2, 3, 0)
     clust[3] = Cluster.new(3, 5, 0)
        
     ClusterGeneration.sent_density_thresh = 6
     select = cg.select_top_clusters(clust)
        
     #checking the set of selected clusters
     assert_equal(0, select.length)
   end

end
