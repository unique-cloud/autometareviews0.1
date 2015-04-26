require 'constants'
require 'cluster'

class ClusterGeneration
  include Math
=begin
  Forming the clusters in the dataset
   * @param subm_sentences is the set of sentences in the submission
   * @param sentence_similarity is the matrix containing the similarities between every pair of sentences
=end
def generate_clusters(subm_sentences, sentence_similarity, sim_list, sim_threshold)
  if (subm_sentences.length == 1) #only 1 sentence in the submission
    cluster_set = Array.new(subm_sentences.length)
    cluster_set[0] = Cluster.new(0, 1, 6) #max avg_similarity
    cluster_set[0].sentences = Array.new #since a single cluster can contain atmost all sentences in the text
    #setting cluster ID for sentences - to check if sentences were a part of the same cluster
    subm_sentences[0].cluster_ID = cluster_set[0].ID
    cluster_set[0].sentences[0] = subm_sentences[0] #setting sentence
#    puts "num_vertixes #{cluster_set[0].sentences[0].num_verts}"
#    puts("Cluster: #{0} SentCount: #{cluster_set[0].sent_counter}")
    final_clusters = cluster_set
    return final_clusters
  end
#  puts "Length of subm_sentences #{subm_sentences.length}"
  #ranking sentence pairs based on their similarity
  ranked_array = rank_sentences(sentence_similarity, sim_list)
  #Cluster creation -- looping
  final_clusters = cluster_creation(subm_sentences, ranked_array, sentence_similarity, sim_threshold)
    
  #printing the clusters and calculating the avg. number of sentences per cluster
  num_sentences = 0
  count = 0
  for i in 0..final_clusters.length-1
    #copying only the required number of sentences into the final cluster
    if (final_clusters[i].sent_counter != nil && final_clusters[i].sent_counter >= 0)
      #summing up number of sentences to calculate avg. number of sentences per cluster
      num_sentences += final_clusters[i].sent_counter
      count+=1
    end
  end
#  puts "@@sent_density_thresh #{sent_density_thresh}"
  if (count > 0)
    @@sent_density_thresh = (num_sentences/count).round
  else
    @@sent_density_thresh = 0.0
  end  
  
#  puts("Avg. number of sentences per clutser: #{ClusterGeneration.sent_density_thresh}")
    
  #selecting the top 'n' clusters that need covering
  final_clusters = select_top_clusters(final_clusters)
#  puts "top clusters #{final_clusters.length}"
  return final_clusters
end

#in order to be able to access class variables
def self.sent_density_thresh
  @@sent_density_thresh
end
#setter
def self.sent_density_thresh=(value)
  @@sent_density_thresh = value
end
  
=begin
   * @param sim_list is sorted list of similarities between pairs of submission sentences
   * @return ids of ranked sentences
=end
def rank_sentences(sentence_similarity, sim_list)
#  puts "sentence_similarity.class #{sentence_similarity.class}"
#  puts "sim_list #{sim_list.length}"
  order_sim_list = sim_list
  #ranked_array consists of the sentence IDs
  #number of sentence similarities = n(n-1)/2
  len = (sentence_similarity[0].length * (sentence_similarity[0].length-1))/2 
#  puts "len #{len}"
  temp_array = Array.new #keeps track of sentence pairs assigned to ranked array
  ranked_array = Array.new
  counter = 0 #counter for the ranked_array
  for i in 0..order_sim_list.length-1
#    puts "order_sim_list #{order_sim_list[i]}"
    flag = 0 #to check if that similarity value was spotted in the matrix
    for j in 0..sentence_similarity.length - 1
      for k in j+1..sentence_similarity.length - 1
#        puts "match #{j} - #{k}"
        ranked_array[counter] = Array.new
        if (order_sim_list[i] == sentence_similarity[j][k] && !temp_array.include?(j.to_s+""+k.to_s))
          ranked_array[counter][0] = j #setting the sentence IDS
          ranked_array[counter][1] = k
          temp_array << j.to_s+""+k.to_s
          counter+=1
          flag = 1
          break
        end
      end #end of for loop
      if (flag == 1)
#        puts "counter #{counter}"
        break
      end    
    end #end of outer 'sentence_similarity' for loop
  end #for loop for 'order_sim_list'
#  puts "ranked_array #{ranked_array.length}"
  return ranked_array 
end

=begin
   * @param subm_sentences - set of submission sentences
   * @param ranked_array - ranked set of sentences
   * @param sentence_similarity - matrix containing similarity between every pair of sentences
=end
  def cluster_creation(subm_sentences, ranked_array, sentence_similarity, sim_threshold)
    cluster_set = Array.new(subm_sentences.length)
    #initialize every sentence to one cluster
    for i in 0..subm_sentences.length - 1
      cluster_set[i] = Cluster.new(i, 1, 6)
      cluster_set[i].sentences = Array.new #since a single cluster can contain atmost all sentences in the text
      #setting cluster ID for sentences - to check if sentences were a part of the same cluster
      subm_sentences[i].cluster_ID = cluster_set[i].ID
#      puts("Cluster: #{i} SentCount: #{cluster_set[i].sent_counter}")
      cluster_set[i].sentences[0] = subm_sentences[i] #setting sentence
    end
    
    #creating clusters after checking cluster condition
    #iterating through every sentence in the ranked array
    for i in 0..ranked_array.length-1
      #fetching sentences
      s1 = subm_sentences[ranked_array[i][0]]
      s2 = subm_sentences[ranked_array[i][1]]
#      puts("** Checking sentence IDS:  #{ranked_array[i][0]} - #{ranked_array[i][1]}")
#      puts(" in clusters: #{s1.cluster_ID} - #{s2.cluster_ID}")
      s1_clust = cluster_set[s1.cluster_ID]
      s2_clust = cluster_set[s2.cluster_ID]
      
      #getting similarity between the two sentences
      if (s1.ID < s2.ID)
        sim = sentence_similarity[s1.ID][s2.ID]
      else
        sim = sentence_similarity[s2.ID][s1.ID]
      end
#      puts "sim: #{sim}"
      if (sim < MINMATCH) #if the edge match is below a certain threshold, then no clusters may be formed between them
        next
      end
      
      if (s1.cluster_ID == s2.cluster_ID) #both sentences are in the same cluster
        next
      else #add one sentence to the other's cluster
        #check if s1 can be added to s2's cluster
        #deciding which cluster the other sentence should be added
        if (s1_clust.sent_counter != s2_clust.sent_counter) #when both clusters have different number of sentences
          #compare s1 with every sentence in the s2's cluster and get the avg. similarity
          #if s2_clust has more sentences
          if (s2_clust.sent_counter > 1 and checkingClusteringCondition(s1, s2_clust, s1_clust, sentence_similarity, sim_threshold) == true) #if the condition was satisfied
#            puts("# sents. in cluster: #{s2_clust.ID} - #{s2_clust.sent_counter}")
#            puts("# sents. in cluster: #{s1_clust.ID} - #{s1_clust.sent_counter}")
            next #to the next sentence, since s1 has been added to s2_clust
          #check if s2 can be added to s1's cluster
          #if s1_clust has more sentences
          elsif (s1_clust.sent_counter > 1 and checkingClusteringCondition(s2, s1_clust, s2_clust, sentence_similarity, sim_threshold) == true) #if the condition was satisfied
#            puts("# sents. in cluster: #{s1_clust.ID} - #{s1_clust.sent_counter}")
#            puts("# sents. in cluster: #{s2_clust.ID} - #{s2_clust.sent_counter}")
            next #to the next sentence, since s1 has been added to s2_clust
          end
        else #if both clusters have same number of sentences, either cluster could be the target
          #compare s1 with every sentence in the s2's cluster and get the avg. similarity
          if (checkingClusteringCondition(s1, s2_clust, s1_clust, sentence_similarity, sim_threshold) == true) #if the condition was satisfied
#            puts("# sents. in cluster: #{s2_clust.ID} - #{s2_clust.sent_counter}")
#            puts("# sents. in cluster: #{s1_clust.ID} - #{s1_clust.sent_counter}")
            next #to the next sentence, since s1 has been added to s2_clust
          end
        end
      end
    end
    #recalculate the cluster average
    return cluster_set
  end #end of method cluster_creation

  def checkingClusteringCondition(s, targetClust, origClust, sentence_similarities, sim_threshold)
    targetclust_sents = targetClust.sentences
    sum = 0.0
    count = 0
#    puts "targetClust.sent_counter #{targetClust.sent_counter}"
    (0..targetClust.sent_counter-1).each do |j|
      #get similarity value between s1 and every sentence in s2Clust, except s1 itself!, 
      #therefore only < and > operations
      if (s.ID < targetclust_sents[j].ID) #since only the matrix' upper half has been calculated
        sum += sentence_similarities[s.ID][targetclust_sents[j].ID]
        count+=1
      elsif (s.ID > targetclust_sents[j].ID)
        sum += sentence_similarities[targetclust_sents[j].ID][s.ID]
        count+=1
      end
    end
    avgSim = 0.0
    if (count > 0)
      avgSim = sum/Float(count)
    end
#    puts("Average similairty for sentence: #{s.ID} for cluster #{targetClust.ID} SIM: #{avgSim}")
    
    #checking cluster condition
#    puts("Target cluster #{targetClust.ID}'s similarity: #{targetClust.avg_similarity}")
#    puts("Original cluster #{origClust.ID}'s similarity: #{origClust.avg_similarity}")
#    puts "sim_threshold #{sim_threshold}"
    #then s1 can be added to the cluster, if it is within Y of the cluster's similarity as well as 
    #if the cluster it is being added to has a higher avg. sim. than the current cluster
    if ((targetClust.avg_similarity - avgSim) <= sim_threshold and 
        ((targetClust.avg_similarity == 6 && origClust.avg_similarity == 6) || 
            (targetClust.avg_similarity >= origClust.avg_similarity)))
      #avgSim >= targetClust.avg - Similarity since the avgSim is not likely to exceed the cluster's similairty! 
#      puts("Condition satisfied by the sentence for the targetcluster")
      s.cluster_ID = targetClust.ID
      
      #adding s1 to s2Clust's sentences
      targetClust.sentences[targetClust.sent_counter] = s
      targetClust.sent_counter = targetClust.sent_counter+1 #incrementing sentence counter
#      puts("Target cluster #{targetClust.ID}'s sentence count #{targetClust.sent_counter}")
#      puts("Target cluster sentence's cluster ID #{targetClust.sentences[targetClust.sent_counter-1].cluster_ID}")
      #recalculating cluster average similarity
      targetClust.avg_similarity = recalculate_cluster_similarity(targetClust, sentence_similarities)
#      puts("Target cluster #{targetClust.ID}'s similarity: #{targetClust.avg_similarity}")
      #removing s1 from s1Clust's sentences
      (0..origClust.sentences.length - 1).each() do |k|
        if (origClust.sentences[k]==s)
          next
        end
      end
      
      origClust.sentences[k] = nil #setting the location where s1 was earlier to null
      origClust.sent_counter = origClust.sent_counter - 1 #decrementing sentence counter
      #recalculating cluster average similarity
      origClust.avg_similarity = recalculate_cluster_similarity(origClust, sentence_similarities)
      return true
    end
    return false
  end
  
=begin
   * @param - c cluster whose average similarity is to be calculated
   * @param - the sentence similarity matrix
=end
  def recalculate_cluster_similarity(c, sent_sim)
#    puts("****** Inside recalculate_cluster_similarity, #sentences in cluster: #{c.ID} is - #{c.sent_counter}")
    clust_sents = c.sentences
    num_sents_clust = c.sent_counter
    avg = 0.0
    
    if (num_sents_clust == 0)
      return 0.0 #if there are no sentences in the cluster sem. sim = 0
    end
    
    sum = 0
    count = 0 #since the cluster has an initial similarity value, with which you are taking an average
    (0..num_sents_clust-1).each() do |i|
      (i+1..num_sents_clust-1).each() do |j|
#        puts("Comparing sents: #{clust_sents[i].ID} && #{clust_sents[j].ID}")
        if (clust_sents[i].ID < clust_sents[j].ID)
          sum += sent_sim[clust_sents[i].ID][clust_sents[j].ID]
        else
          sum += sent_sim[clust_sents[j].ID][clust_sents[i].ID]
        end
        count+=1
      end
    end

    #calculating the cluster's average similarity value
    if (count > 0)
      avg = sum/Float(count)
    end
#    puts("Cluster #{c.ID}'s recalculated average: #{avg}")
    return avg
  end
  
=begin
   * @param Cluster[] set of clusters to select the most important clusters based on 
   * 1. Number of sentences in the cluster and 
   * 2. Average similarity of the sentences in the cluster.
=end

  def select_top_clusters(subm_clusters)
#    puts "@@sent_density_thresh #{ClusterGeneration.sent_density_thresh}"
    top_clusters = Array.new
    count = 0
    #code for selecting the top 'n' dense clusters
    (0..subm_clusters.length-1).each() do |i|
      if (subm_clusters[i].sent_counter != nil && subm_clusters[i].sent_counter >= ClusterGeneration.sent_density_thresh)
#        puts("Top cluster ID: #{subm_clusters[i].ID}")
        top_clusters[count] = subm_clusters[i]
        count+=1
      end
    end
    return top_clusters
  end
  
=begin
   * Calculating average similarity for every sentence in a cluster with every other sentence in the cluster,
   * and this across all clusters!
   * @param subm_clusters
   * @param sent_sim
=end
  def calculate_sentence_similarities_within_cluster(subm_clusters, sent_sim)
    #iterating through each of the clusters

    (0..subm_clusters.length-1).each() do |i|
#      puts("Cluster: #{subm_clusters[i].ID} #sents: #{subm_clusters[i].sent_counter}")
      clust_sents = subm_clusters[i].sentences
      #iterating through all sentences in the cluster
      (0..subm_clusters[i].sent_counter-1).each() do |j|
        sum = 0.0
        count = 0
        #iterating through all sentences in the cluster
        (0..subm_clusters[i].sent_counter-1).each() do |k|
#          puts("IDS: #{clust_sents[j].ID} - #{clust_sents[k].ID}")
          if (j != k)
            if (clust_sents[j].ID < clust_sents[k].ID)
#              puts("sent_sim[#{clust_sents[j].ID}][#{clust_sents[k].ID}] #{sent_sim[clust_sents[j].ID][clust_sents[k].ID]}")
              sum += sent_sim[clust_sents[j].ID][clust_sents[k].ID]
              count+=1
            elsif (clust_sents[k].ID < clust_sents[j].ID)
#              puts("sent_sim[#{clust_sents[k].ID}][#{clust_sents[j].ID}] #{sent_sim[clust_sents[k].ID][clust_sents[j].ID]}")
              sum += sent_sim[clust_sents[k].ID][clust_sents[j].ID]
              count+=1
            end
          end
        end #end of for condition for inner 'k'
        if (count != 0)
          clust_sents[j].avg_similarity = sum/Float(count)
        else
          clust_sents[j].avg_similarity = 0.0
        end
#        puts("Sentence: #{clust_sents[j].ID} sim: #{clust_sents[j].avg_similarity}")
      end #end of for loop for outer sentences 'j'
    end #end of for loop for the clusters
  end
    
end
