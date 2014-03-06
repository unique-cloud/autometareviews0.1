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

class SentenceSimilarityTest < Test::Unit::TestCase
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
  def testSentenceSimilarity1
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
    graph_match = DegreeOfRelevance.new    
    assert_equal(6, graph_match.compare_vertices(pos_tagger, subm_sents[0].vertices, subm_sents[1].vertices, subm_sents[0].num_verts, subm_sents[1].num_verts, speller))
  end

  def test_sentence_similarity2
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
    graph_match = DegreeOfRelevance.new    
    #run compare_vertices before to make sure that the smenatic match matrix has already been generated
    graph_match.compare_vertices(pos_tagger, subm_sents[0].vertices, subm_sents[1].vertices, subm_sents[0].num_verts, subm_sents[1].num_verts, speller)
    assert_equal(6, graph_match.compare_edges_non_syntax_diff(subm_sents[0].edges, subm_sents[1].edges, subm_sents[0].num_edges, subm_sents[1].num_edges))
  end
    
  def test_sentence_similarity2_1
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
    
    graph_match = DegreeOfRelevance.new    
    #run compare_vertices before to make sure that the smenatic match matrix has already been generated
    assert_equal(4.3, (graph_match.compare_vertices(pos_tagger, subm_sents[0].vertices, subm_sents[1].vertices, subm_sents[0].num_verts, subm_sents[1].num_verts, speller) * 10).round/10.0)
  end  
 
  def test_sentence_similarity2_2
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
    graph_match = DegreeOfRelevance.new  
    assert_equal(4.3, (graph_match.compare_vertices(pos_tagger, subm_sents[0].vertices, subm_sents[1].vertices, subm_sents[0].num_verts, subm_sents[1].num_verts, speller) * 10).round/10.0)
    assert_equal(4.5, graph_match.compare_edges_non_syntax_diff(subm_sents[0].edges, subm_sents[1].edges, subm_sents[0].num_edges, subm_sents[1].num_edges))
    ssim = SentenceSimilarity.new
    #sentence similarity
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    assert_equal((4.3 + 4.5)/2, (output[0][1] * 10).round/10.0)
  end

  def test_sentence_similarity3
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
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    assert_equal(6, output[0][1])
    assert_equal(nil, output[0][0])
    assert_equal(nil, output[1][0])
    assert_equal(nil, output[1][1])
  end
    
  #For two completely different sentences
  def test_sentence_similarity4
    text1 = ["This is funny."]
    text2 = ["He played the guitar."]
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
    
    graph_match = DegreeOfRelevance.new  
    ssim = SentenceSimilarity.new
    #comparing vertices
    assert_equal(1.0, graph_match.compare_vertices(pos_tagger, subm_sents[0].vertices, subm_sents[1].vertices, subm_sents[0].num_verts, subm_sents[1].num_verts, speller))
    assert_equal(0, graph_match.compare_edges_non_syntax_diff(subm_sents[0].edges, subm_sents[1].edges, subm_sents[0].num_edges, subm_sents[1].num_edges))
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    #getting the final output values
    assert_equal(nil, output[0][0])
    assert_equal(0.5, output[0][1])
    assert_equal(nil, output[1][0])
    assert_equal(nil, output[1][1])
  end
 
  #greater than 2 sentences
  def test_sentence_similarity5
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
    
    #sentence similarity
    ssim = SentenceSimilarity.new
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    #getting the final output values
    assert_equal(6, output[0][1]);
    assert_equal(nil, output[0][0])
    assert_equal(6, output[0][2])
    assert_equal(6, output[0][3])
    assert_equal(6, output[0][4])
    assert_equal(6, output[1][2])
    assert_equal(6, output[1][4])
    assert_equal(6, output[2][3])
    assert_equal(6, output[3][4])
    assert_equal(5, output[0].length)
  end
    
  #multiple sentences, some of which are not equal
  def test_sentence_similarity5_1
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
    
    #sentence similarity
    ssim = SentenceSimilarity.new
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    assert_equal(0.2, (output[0][1] * 10).round/10.0)
    assert_equal(6, output[0][2])
    assert_equal(0.5, output[1][2])
  end

  def test_sentence_similarity2_2
    text1 = ["He played the flute."] 
    text2 = ["This is funny."] 
    text3 = ["He played the guitar."] 
    text4 = ["He played the flute."]
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
    
    #sentence similarity
    ssim = SentenceSimilarity.new
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    assert_equal(nil, output[0][0])
    assert_equal(0.2, (output[0][1] * 10).round/10.0)
    assert_equal(4.4, (output[0][2] * 10).round/10.0) 
    assert_equal(6, output[0][3])
    assert_equal(nil, output[1][1])
    assert_equal(0.5, (output[1][2] * 10).round/10.0)
    assert_equal(0.5, (output[1][3] * 10).round/10.0)
    assert_equal(nil, output[2][2])
    assert_equal(4.4, (output[2][3] * 10).round/10.0)
  end
    
  #checking difference calculated - exact same sentences
  def test_sentence_similarity6
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
    
    #sentence similarity
    ssim = SentenceSimilarity.new
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    #checking if difference is 0 when both sentence have an exact match
    assert_equal(0, ssim.sim_threshold)
  end
    
  #checking difference calculated - distinct sentences
  def test_sentence_similarity7
    text1 = ["This is funny."] 
    text2 = ["He played the guitar."]
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
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    #checking if difference is 0 when both sentence have an exact match
    assert_equal(5.5, ssim.sim_threshold)
  end

  def test_sentence_similarity8
    text1 = ["This is funny."] 
    text2 = ["He played the guitar."] 
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
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    #checking if difference is 0 when both sentence have an exact match
    assert_equal(3.7, ssim.sim_threshold)
  end
  
  def test_sentence_similarity8_1
    text1 = ["He played the flute."] 
    text2 = ["He played the guitar."] 
    text3 = ["He played the flute."]
    subm_text = Array.new
    subm_text << text1
    subm_text << text2
    subm_text << text3
    #sim rowise - 
    #0 - 0, 4.833.., 6  = 1.16666666666667
    #1 - 4.833.., 0, 4.833.. = 0
    #2 - 6, 4.833.., 0 = 1.16666666666667
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
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    #checking if difference is 0 when both sentence have an exact match
    assert_equal(4.4, (output[0][1] * 10).round/10.0)
    assert_equal(6, output[0][2])
    assert_equal(4.4, (output[1][2] * 10).round/10.0)
    assert_equal(1.1, (ssim.sim_threshold * 10).round/10.0)
  end        
    
  #Testing the ordering of the sentence similarities
  def test_sentence_similarity9
    text1 = ["He played the guitar."] 
    text2 = ["This is funny."] 
    text3 = ["He played the guitar."]
    subm_text = Array.new
    subm_text << text1
    subm_text << text2
    subm_text << text3
    
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
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    simList = ssim.sim_list
    #checking for the ordering of the similarity values
    assert_equal(6, simList[0])
    assert_equal(0.5, simList[1])
    assert_equal(0.2, (simList[2] * 10).round/10.0)
  end
    
  def test_sentence_similarity9_1
    text1 = ["He played the flute."] 
    text2 = ["This is funny."] 
    text3 = ["He played the guitar."]
    text4 = ["He played the flute."]
    subm_text = Array.new
    subm_text << text1
    subm_text << text2
    subm_text << text3
    subm_text << text4
    
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
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    simList = ssim.sim_list
    #checking for the ordering of the similarity values
    
    assert_equal(6, simList[0])
    assert_equal(4.4, (simList[1] * 10).round/10.0)
    assert_equal(4.4, (simList[2] * 10).round/10.0)
    assert_equal(0.5, simList[3])
    assert_equal(0.5, simList[4])
    assert_equal(0.2, (simList[5]*10).round/10.0)
  end
    
  def test_sentence_similarity9_2
    text1 = ["He played the flute."] 
    text2 = ["He played the guitar."] 
    text3 = ["He played the flute."]
    subm_text = Array.new
    subm_text << text1
    subm_text << text2
    subm_text << text3
    
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
    output = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    simList = ssim.sim_list
    #checking for the ordering of the similarity values
    
    assert_equal(6, simList[0])
    assert_equal(4.4, (simList[1] *10).round/10.0)
    assert_equal(4.4, (simList[2] * 10).round/10.0)
  end
end
