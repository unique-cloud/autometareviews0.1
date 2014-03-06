require 'degree_of_relevance'
class SentenceSimilarity
attr_accessor :sim_list, :sim_threshold 
def get_sentence_similarity(pos_tagger, subm_sentences, speller)
#  puts "subm_sentences.length: #{subm_sentences.length}"
  @sim_list = Array.new 
  #calculating similarities between sentences
  sentence_match = Array.new(subm_sentences.length){Array.new}
  graph_match = DegreeOfRelevance.new
  for i in 0..subm_sentences.length - 1
    for j in 0..subm_sentences.length - 1
      if(i < j)
#        puts("vertex - subm_sentences[i] = #{subm_sentences[i].nil?} and subm_sentences[j] = #{subm_sentences[j].nil?}")
        vertex_match = graph_match.compare_vertices(pos_tagger, subm_sentences[i].vertices, subm_sentences[j].vertices, subm_sentences[i].num_verts, subm_sentences[j].num_verts, speller)
#        puts("edge - subm_sentences[i] = #{subm_sentences[i].nil?} and subm_sentences[j] = #{subm_sentences[j].nil?}")
        edge_match = graph_match.compare_edges_non_syntax_diff(subm_sentences[i].edges, subm_sentences[j].edges, subm_sentences[i].num_edges, subm_sentences[j].num_edges)
        sentence_match[i][j] = (vertex_match + edge_match)/2
#        puts "sentence_match: #{sentence_match[i][j]}"
        @sim_list << sentence_match[i][j]
      end
    end
  end
  
  #calculating average difference between similarity values
  difference = 0.0 #maintains cumulative difference between values
  count = 0
  carryover = 0
  firstmatch = 0
#  puts "subm_sentences.length #{subm_sentences.length}"
  if(subm_sentences.length == 2)
    difference = (6 - @sim_list[0]).abs
    count = 1
  else
    for i in 0..subm_sentences.length - 1
      for j in i+1..subm_sentences.length - 1
#        puts "subm_sentences[i].ID: #{subm_sentences[i].ID}, subm_sentences[j].ID: #{subm_sentences[j].ID}"
        #set the very first match, so the difference of the last elemet with the first match can be calculated
        if(i == 0 && j == i+1)
          firstmatch =  sentence_match[subm_sentences[i].ID][subm_sentences[j].ID]
        end
        if(carryover != 0 && i > 0)
          difference += (carryover - sentence_match[subm_sentences[i].ID][subm_sentences[j].ID]).abs
#          puts "carryover difference #{difference}"
          count+=1
        end
        #since the similarity is symmetric only values of the top triangle in the matrix is calculated
        if(j+1 < subm_sentences.length) #the second condition is to avoid getting difference with sentence comparison with itself (leading diagonal)
          difference += (sentence_match[subm_sentences[i].ID][subm_sentences[j].ID] - 
                sentence_match[subm_sentences[i].ID][subm_sentences[j+1].ID]).abs
#          puts "difference #{difference}"
          count+=1
        elsif(j+1 == subm_sentences.length) #if j+1 is out of the array index, compare with column 0 (round)
          carryover = sentence_match[subm_sentences[i].ID][subm_sentences[j].ID]
#          puts "set carryover #{carryover}"
        end
      end #end of for loop
    end #end of for loop
#    puts "firstmatch #{firstmatch}"
    difference += (carryover - firstmatch).abs
    count += 1
  end
  if(count > 0)
    @sim_threshold = difference/count
  else
    @sim_threshold = 0.0
  end
  @sim_threshold = (@sim_threshold * 10).round/10.0 #rounding to include only 1 digit after the decimal
  
  #order simlist
  @sim_list = @sim_list.sort.reverse
  return sentence_match
end  

end