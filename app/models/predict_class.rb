require 'wordnet_based_similarity'
require 'constants'

class PredictClass

  # Identifies the probabilities of a review belonging to each of the three classes.
  # Returns an array of probablities (length = numClasses)
  # predicting the review's class
  def predict_classes(pos_tagger, _core_NLP_tagger, review_graph, patterns_files)
    tc = TextPreprocessor.new
    single_patterns = []

    # reading the patterns from each of the pattern files
    patterns_files.each do |file|
      # read_patterns in TextPreprocessing helps read patterns in the format 'X = Y'
      single_patterns << tc.read_patterns(file, pos_tagger)
    end

    # Predicting the probability of the review belonging to each of the content classes
    wordnet = WordnetBasedSimilarity.new

    class_prob = [] # contains the probabilities for each of the classes - it contains 3 rows for the 3 classes
    # comparing each test review text with patterns from each of the classes
    single_patterns.each do |pattern|
      # comparing edges with patterns from a particular class
      class_prob << compare_review_with_patterns(review_graph.edges, pattern, wordnet)/6.to_f # normalizing the result
      # we divide the match by 6 to ensure the value is in the range of [0-1]
    end

    class_prob
  end

  def get_max(a, b)
    a > b ? a : b
  end
 
  def compare_review_with_patterns(single_edges, single_patterns, wordnet)
    final_class_sum = 0.0
    final_edge_num = 0
    single_edge_matches = Array.new(single_edges.length){Array.new}

    # resetting the average_match values for all the edges, before matching with the single_patterns for a new class
    single_edges.each do |edge|
      if edge
        edge.average_match = 0
      end
    end

    # comparing each single edge with all the patterns
    single_edges.each_with_index do |edge, i|
      max_match = 0
      if edge
        single_patterns.each_with_index do |pattern, j|
          if pattern
            single_edge_matches[i][j] = compare_edges(single_edges[i], single_patterns[j], wordnet)
            max_match = get_max(single_edge_matches[i][j],max_match)
          end
        end
        single_edges[i].average_match = max_match

        # calculating class average
        if single_edges[i].average_match != 0.0
          final_class_sum = final_class_sum + single_edges[i].average_match
          final_edge_num+=1
        end
      end
    end

    if final_edge_num == 0
      final_edge_num = 1
    end

    final_class_sum/final_edge_num #maxMatch
  end

  def compare_edges(e1, e2, wordnet)
    speller = FFI::Aspell::Speller.new('en_US')

    # compare edges so that only non-nouns or non-subjects are compared
    in_in_vertex_compare = wordnet.compare_strings(e1.in_vertex, e2.in_vertex, speller)
    in_out_vertex_compare = wordnet.compare_strings(e1.in_vertex, e2.out_vertex, speller)
    out_out_vertex_compare = wordnet.compare_strings(e1.out_vertex, e2.out_vertex, speller)
    out_in_vertex_compare = wordnet.compare_strings(e1.out_vertex, e2.in_vertex, speller)

    avg_match_without_syntax = (in_in_vertex_compare + out_out_vertex_compare)/2.to_f
    # matching in-out and out-in vertices
    avg_match_with_syntax = (in_out_vertex_compare + out_in_vertex_compare)/2.to_f

    avg_match_without_syntax > avg_match_with_syntax ? avg_match_without_syntax : avg_match_with_syntax
  end
end
