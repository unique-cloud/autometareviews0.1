require 'sentence_state'
require 'edge'
require 'vertex'

class GraphGenerator
  # creating accessors for the instance variables
  attr_accessor :vertices, :num_vertices, :edges, :num_edges, :pipeline, :pos_tagger

  # generates the graph for the given review text and
  # INPUT: an array of sentences for a review or a submission. Every row in 'text' contains one sentence.
  # type - tells you if it was a review or s submission
  # type = 1 - submission/past review
  # type = 2 - new review
  def generate_graph(text, pos_tagger, coreNLPTagger, _forRelevance, _forPatternIdentify)
    # initializing common arrays
    @vertices = Array.new
    @num_vertices = 0
    @edges = Array.new
    @num_edges = 0

    @pos_tagger = pos_tagger # part of speech tagger
    @pipeline = coreNLPTagger # dependency parsing
    # iterate through the sentences in the text
    for i in (0..text.length-1)
      if (text[i].empty? or text[i] == "" or text[i].split(" ").empty?)
        next
      end
      taggedString = @pos_tagger.get_readable(text[i])

      # Initializing some arrays
      nouns = Array.new
      nCount = 0
      verbs = Array.new
      vCount = 0
      adjectives = Array.new
      adjCount = 0
      adverbs = Array.new
      advCount = 0

      parents = Array.new
      labels = Array.new

      # finding parents
      parents = find_parents(text[i])
      parentCounter = 0

      # finding parents
      labels = find_labels(text[i])
      labelCounter = 0

      # find state
      sstate = SentenceState.new
      states_array = sstate.identify_sentence_state(taggedString)
      states_counter = 0
      state = states_array[states_counter]
      states_counter += 1

      taggedString = taggedString.split(" ")
      prevType = nil # initlializing the prevyp

      # iterate through the tokens
      for j in (0..taggedString.length-1)
        taggedToken = taggedString[j]
        plainToken = taggedToken[0...taggedToken.index("/")].to_s
        posTag = taggedToken[taggedToken.index("/")+1..taggedToken.length].to_s
        # ignore periods
        # this is for strings containinig "'s" or without POS
        if (plainToken == "." or taggedToken.include?("/POS") or (taggedToken.index("/") == taggedToken.length()-1) or (taggedToken.index("/") == taggedToken.length()-2))
          next
        end

        # Setting state
        # since the CC or IN are part of the following sentence segment, we set the STATE for that segment when we see a CC or IN
        if (taggedToken.include?("/CC")) # {//|| ps.contains("/IN")
          state = states_array[states_counter]
          states_counter += 1
        end

        # if the token is a noun
        if (taggedToken.include?("NN") or taggedToken.include?("PRP") or taggedToken.include?("IN") or taggedToken.include?("/EX") or taggedToken.include?("WP"))
          # either add on to a previous vertex or create a brand new noun vertex
          if (prevType == NOUN) # adding to a previous noun vertex
            nCount -= 1 # decrement, since we are accessing a previous noun vertex
            nounVertex = append_to_previous(nCount,nouns,plainToken,i,labels,labelCounter)
          # if the previous token is not a noun, create a brand new vertex
          else
            nouns[nCount] = plainToken # this is checked for later on
            nounVertex = create_new_branch(plainToken,i,NOUN,state,labels,labelCounter,parents,parentCounter,posTag)
          end # end of if prevType was noun
          remove_redundant_vertices(nouns[nCount], i)
          # increment nCount for a new noun vertex just created (or existing previous vertex appended with new text)
          nCount += 1

          # checking if a noun existed before this one and if the adjective was attached to that noun.
          # if an adjective was found earlier, we add a new edge
          if (prevType == ADJ)
            # set previous noun's property to null, if it was set, if there is a noun before the adjective
            if (nCount > 1)
              # fetching the previous noun, the one before the current noun (therefore -2)
              v1 = search_vertices(@vertices, nouns[nCount-2], i)
              # fetching the previous adjective
              v2 = search_vertices(@vertices, adjectives[adjCount-1], i)
              # if such an edge exists - DELETE IT -
              delete_edge(v1,v2,i)

            end
            # if this noun vertex was encountered for the first time, nCount < 1,
            # so do adding of edge outside the if condition
            # add a new edge with v1 as the adjective and v2 as the new noun
            v1 = search_vertices(@vertices, adjectives[adjCount-1], i)
            v2 = nounVertex # the noun vertex that was just created
            create_edge(v1,v2,i,"noun-property",VERB)

          end
          # a noun has been found and has established a verb as an in_vertex and such an edge doesnt already previously exist
          if (vCount > 0) # and fAppendedVertex == 0
            # add edge only when a fresh vertex is created not when existing vertex is appended to
            v1 = search_vertices(@vertices, verbs[vCount-1], i)
            v2 = nounVertex
            create_edge(v1,v2,i,"verb",VERB)

          end
          prevType = NOUN

          # if the string is an adjective
          # adjectives are vertices but they are not connected by an edge to the nouns, instead they are the noun's properties
        elsif (taggedToken.include?("/JJ"))
          adjective = nil
          if (prevType == ADJ) # combine the adjectives
            # adjCount is bound to be >=1 when prevType == ADJ
            adjCount = adjCount - 1
            adjective = append_to_previous(adjCount,adjectives,plainToken,i,labels,labelCounter)

          else # new adjective vertex
            adjectives[adjCount] = plainToken
            adjective = create_new_branch(plainToken,i,ADJ,state,labels,labelCounter,parents,parentCounter,posTag)

          end
          remove_redundant_vertices(adjectives[adjCount], i)
          adjCount += 1 # incrementing, since a new adjective was created or an existing one updated.

          # by default associate the adjective with the previous/latest noun and if there is a noun following it immediately, then remove the property from the older noun (done under noun condition)
          if (nCount > 0) # gets the previous noun to form the edge
            v1 = search_vertices(@vertices, nouns[nCount-1], i)
            v2 = adjective # the current adjective vertex
            # if such an edge does not already exist add it
            create_edge(v1,v2,i,"noun-property",VERB)

          end
          prevType = ADJ
        # if the string is a verb or a modal//length condition for verbs is, be, are...
        elsif (taggedToken.include?("/VB") or taggedToken.include?("MD"))
          verbVertex = nil
          if (prevType == VERB) # combine the verbs
            vCount = vCount - 1
            verbVertex = append_to_previous(vCount,verbs,plainToken,i,labels,labelCounter)

          else
            verbs[vCount] = plainToken
            verbVertex = create_new_branch(plainToken,i,VERB,state,labels,labelCounter,parents,parentCounter,posTag)

          end
          remove_redundant_vertices(verbs[vCount], i)
          vCount += 1

          # if an adverb was found earlier, we set that as the verb's property
          if (prevType == ADV)
            # set previous verb's property to null, if it was set, if there is a verb following the adverb
            if (vCount > 1)
              # fetching the previous verb, the one before the current one (hence -2)
              v1 = search_vertices(@vertices, verbs[vCount-2], i)
              # fetching the previous adverb
              v2 = search_vertices(@vertices, adverbs[advCount-1], i)
              # if such an edge exists - DELETE IT
              delete_edge(v1,v2,i)
            end
            # if this verb vertex was encountered for the first time, vCount < 1,
            # so do adding of edge outside the if condition
            # add a new edge with v1 as the adverb and v2 as the new verb
            v1 = search_vertices(@vertices, adverbs[advCount-1], i)
            v2 = verbVertex
            # if such an edge did not already exist
            create_edge(v1,v2,i,"verb-property",VERB)

          end

          # making the previous noun, one of the vertices of the verb edge
          if (nCount > 0) # and fAppendedVertex == 0
            # gets the previous noun to form the edge
            v1 = search_vertices(@vertices, nouns[nCount-1], i)
            v2 = verbVertex
            # if such an edge does not already exist add it
            create_edge(v1,v2,i,"verb",VERB)

          end
          prevType = VERB
        # if the string is an adverb
        elsif (taggedToken.include?("RB"))
          adverb = nil
          if (prevType == ADV) # appending to existing adverb
            advCount = advCount - 1
            adverb = append_to_previous(advCount,adverbs,plainToken,i,labels,labelCounter)
          else # else creating a new vertex
            adverbs[advCount] = plainToken
            adverb = create_new_branch(plainToken,i,ADV,state,labels,labelCounter,parents,parentCounter,posTag)
          end
          remove_redundant_vertices(adverbs[advCount], i)
          advCount += 1

          # by default associate it with the previous/latest verb and if there is
          # a verb following it immediately, then remove the property from the verb
          if (vCount > 0) # gets the previous verb to form a verb-adverb edge
            v1 = search_vertices(@vertices, verbs[vCount-1], i)
            v2 = adverb
            # if such an edge does not already exist add it
            create_edge(v1,v2,i,"verb-property",VERB)

          end
          prevType = ADV
        end

        # incrementing counters for labels and parents
        labelCounter += 1
        parentCounter += 1
      end # end of the for loop for the tokens
      nouns = nil
      verbs = nil
      adjectives = nil
      adverbs = nil
    end # end of number of sentences in the text

    # since as a counter it was 1 ahead of the array's contents
    @num_vertices = @num_vertices - 1
    if (@num_edges != 0)
      @num_edges = @num_edges - 1 # same reason as for num_vertices
    end
    set_semantic_labels_for_edges
    @num_edges
  end # end of the graphGenerate method

  def search_vertices(list, s, index)
    for i in (0..list.length-1)
      if (!list[i].nil? && !s.nil?)
        # if the vertex exists and in the same sentence (index)
        if (list[i].name.casecmp(s) == 0 && list[i].index == index)
          return list[i]
        end
      end
    end
    return nil
  end # end of the search_vertices method

  # Nullify all vertices containing "only substrings" (and not exact matches)
  # of this vertex in the same sentence (verts[j].index == index)
  # And reset the @vertices array with non-null elements.
  def remove_redundant_vertices(s, index)
    j = @num_vertices - 1
    verts = @vertices
    while j >= 0
      if (!verts[j].nil? && verts[j].index == index && s.casecmp(verts[j].name) != 0 &&
          (s.downcase.include?(verts[j].name.downcase) && verts[j].name.length > 1))
        # the last 'length' condition is added so as to prevent "I" (an indiv. vertex) from being replaced by nil
        # search through all the edges and set those with this vertex as in-out- vertex to null
        if (!@edges.nil?)
          for i in 0..@edges.length - 1
            edge = @edges[i]
            if (!edge.nil? && (edge.in_vertex == verts[j] or edge.out_vertex == verts[j]))
              @edges[i] = nil # setting that edge to nil
            end
          end
        end
        # finally setting the vertex to  null
        verts[j] = nil
      end
      j -= 1
    end # end of while loop

    # recreating the vertices array without the nil values
    counter = 0
    vertices_array = Array.new
    for i in (0..verts.length-1)
      vertex = verts[i]
      if (!vertex.nil?)
        vertices_array << vertex
        counter += 1
      end
    end
    @vertices = vertices_array
    @num_vertices = counter + 1 # since @num_vertices is always one advanced of the last vertex
  end


  # Checks to see if an edge between vertices "in" and "out" exists.
  # true - if an edge exists and false - if an edge doesn't exist
  # edge[] list, vertex in, vertex out, int index
  def search_edges(list, in_vertex, out, index)
    edgePos = -1
    if (list.nil?) # if the list is null
      return edgePos
    end

    for i in (0..list.length-1)
      if (check_if_nil(list,i))
        # checking for exact match with an edge
        if(((list[i].in_vertex.name.casecmp(in_vertex.name)==0 || list[i].in_vertex.name.include?(in_vertex.name)) &&
            (list[i].out_vertex.name.casecmp(out.name)==0 || list[i].out_vertex.name.include?(out.name))) ||
            ((list[i].in_vertex.name.casecmp(out.name)==0 || list[i].in_vertex.name.include?(out.name)) &&
                (list[i].out_vertex.name.casecmp(in_vertex.name)==0 || list[i].out_vertex.name.include?(in_vertex.name))))
          # if an edge was found
          edgePos = i # returning its position in the array
          # increment frequency if the edge was found in a different sent.
          # (check by maintaining a text number and checking if the new # is diff from prev #)
          if (index != list[i].index)
            list[i].frequency += 1
          end
        end
      end
    end # end of the for loop
    edgePos
  end # end of searchdges

  def check_if_nil(arr,index)
    return !arr[index].nil? && !arr[index].in_vertex.nil? && !arr[index].out_vertex.nil?
  end

  def search_edges_to_set_null(list, in_vertex, out, index)
    edgePos = -1
    for i in 0..@num_edges - 1
      if (check_if_nil(list,i))
        # checking for exact match with an edge
        if ((list[i].in_vertex.name.downcase == in_vertex.name.downcase && list[i].out_vertex.name.downcase == out.name.downcase) ||
            (list[i].in_vertex.name.downcase == out.name.downcase && list[i].out_vertex.name.downcase == in_vertex.name.downcase))
          # if an edge was found
          edgePos = i # returning its position in the array
          # increment frequency if the edge was found in a different sent.
          # (check by maintaining a text number and checking if the new # is diff from prev #)
          if (index != list[i].index)
            list[i].frequency += 1
          end
        end
      end
    end # end of the for loop
    edgePos
  end # end of the method search_edges_to_set_null

  # Nullify all edges containing "only substrings" (and not exact matches) of either in/out vertices in the same sentence (verts[j].index == index)
  # and reset the @edges array with non-null elements.
  def remove_redundant_edges(in_vertex, out, index)
    list = @edges
    j = @num_edges - 1
    while j >= 0 do
      if (!list[j].nil? && list[j].index == index)
        # when invertices are eq and out-verts are substrings or vice versa
        if (in_vertex.name.casecmp(list[j].in_vertex.name) == 0 && out.name.casecmp(list[j].out_vertex.name) != 0 && out.name.downcase.include?(list[j].out_vertex.name.downcase))
          list[j] = nil
        # when in-vertices are only substrings and out-verts are equal
        elsif (in_vertex.name.casecmp(list[j].in_vertex.name)!=0 && in_vertex.name.downcase.include?(list[j].in_vertex.name.downcase) && out.name.casecmp(list[j].out_vertex.name)==0)
          list[j] = nil
        end
      end
      j -= 1
    end # end of the while loop
    # recreating the edges array without the nil values
    counter = 0
    edges_array = Array.new
    list.each{
        |edge|
      if (!edge.nil?)
        edges_array << edge
        counter += 1
      end
    }
    @edges = edges_array
    @num_edges = counter + 1
  end

  def print_graph(edges, vertices)
    puts("*** List of vertices::")
    for j in (0..vertices.length-1)
      if (!vertices[j].nil?)
        puts("@@@ Vertex:: #{vertices[j].name}")
        puts("*** Frequency:: #{vertices[j].frequency} State:: #{vertices[j].state}")
        puts("*** Label:: #{vertices[j].label} Parent:: #{vertices[j].parent}")
      end
    end
    puts("*******")
    puts("*** List of edges::")
    for j in (0..edges.length-1)
      if (check_if_nil(edges,j))
        puts("@@@ Edge:: #{edges[j].in_vertex.name} & #{edges[j].out_vertex.name}")
        puts("*** Frequency:: #{edges[j].frequency} State:: #{edges[j].in_vertex.state} & #{edges[j].out_vertex.state}")
        puts("*** Label:: #{edges[j].label}")
      end
    end
    puts("--------------")
  end # end of print_graph method

  # Identifying parents and labels for the vertices
  def find_parents(t)
    tp = TextPreprocessing.new
    unTaggedString = t.split(" ")
    parents = Array.new
    #  t = text[i]
    t = StanfordCoreNLP::Text.new(t) # the same variable has to be passed into the Textx.new method
    @pipeline.annotate(t)
    # for each sentence identify theparsed form of the sentence
    sentence = t.get(:sentences).toArray
    parsed_sentence = sentence[0].get(:collapsed_c_c_processed_dependencies)
    # iterating through the set of tokens and identifying each token's parent
    # puts "unTaggedString.length #{unTaggedString.length}"
    for j in (0..unTaggedString.length - 1)
      # puts "unTaggedString[#{j}] #{unTaggedString[j]}"
      if (tp.is_punct(unTaggedString[j]))
        next
      end
      if (tp.contains_punct(unTaggedString[j]))
        unTaggedString[j] = tp.contains_punct(unTaggedString[j])
      end
      if (!unTaggedString[j].nil? && !tp.contains_punct_bool(unTaggedString[j]))
        pat = parsed_sentence.getAllNodesByWordPattern(unTaggedString[j])
        pat = pat.toArray
        parent = parsed_sentence.getParents(pat[0]).toArray
      end
      if (!parent.nil? && !parent[0].nil?)
        # extracting the name of the parent (since it is in the foramt-> "name-POS")
        parents[j] = (parent[0].to_s)[0..(parent[0].to_s).index("-")-1]
      else
        parents[j] = nil
      end
    end
    parents
  end # end of find_parents method

 # Identifying parents and labels for the vertices
  def find_labels(t)
    unTaggedString = t.split(" ")
    t = StanfordCoreNLP::Text.new(t)
    @pipeline.annotate(t)
    # for each sentence identify theparsed form of the sentence
    sentence = t.get(:sentences).toArray
    parsed_sentence = sentence[0].get(:collapsed_c_c_processed_dependencies)
    labels = Array.new
    labelCounter = 0
    govDep = parsed_sentence.typedDependencies.toArray
    # for each untagged token
    for j in (0..unTaggedString.length - 1)
      unTaggedString[j].delete!(".")
      unTaggedString[j].delete!(",")
      # identify its corresponding position in govDep and fetch its label
      for k in (0..govDep.length - 1)
        if (govDep[k].dep.value() == unTaggedString[j])
          labels[j] = govDep[k].reln.getShortName()
          labelCounter += 1
          break
        end
      end
    end
    labels
  end # end of find_labels method

  # Setting semantic labels for edges based on the labels vertices have with their parents
  def set_semantic_labels_for_edges
    for i in (0.. @vertices.length - 1)
      if (!@vertices[i].nil? && !@vertices[i].parent.nil?) # parent = null for ROOT
        # search for the parent vertex
        for j in (0..@vertices.length - 1)
          if (!@vertices[j].nil? && (@vertices[j].name.casecmp(@vertices[i].parent) == 0 ||
              @vertices[j].name.downcase.include?(@vertices[i].parent.downcase)))
            parent = @vertices[j]
            break # break out of search for the parent
          end
        end
        if (!parent.nil?)
          # check if an edge exists between vertices[i] and the parent
          for k in (0..@edges.length - 1)
            if(!@edges[k].nil? && !@edges[k].in_vertex.nil? && !@edges[k].out_vertex.nil?)
              if((@edges[k].in_vertex.name.equal?(@vertices[i].name) && @edges[k].out_vertex.name.equal?(parent.name)) || (@edges[k].in_vertex.name.equal?(parent.name) && @edges[k].out_vertex.name.equal?(@vertices[i].name)))
                # set the role label
                if(@edges[k].label.nil?)
                  @edges[k].label = @vertices[i].label
                elsif(!@edges[k].label.nil? && (@edges[k].label == "NMOD" || @edges[k].label == "PMOD") && (@vertices[i].label != "NMOD" || @vertices[i].label != "PMOD"))
                  @edges[k].label = @vertices[i].label
                end
              end
            end
          end
        end # end of if paren.nil? condition
      end
    end # end of for loop
  end # end of set_semantic_labels_for_edges method
end # end of the class GraphGenerator

# Identifying frequency of edges and pruning out edges that do no meet the threshold conditions
def identify_frequency_and_prune_edges(edges, num)
  # freqEdges maintains the top frequency edges from ALPHA_FREQ to BETA_FREQ
  freqEdges = Array.new # from alpha = 3 to beta = 10
  # iterating through all the edges
  for j in (0..num-1)
    if (!edges[j].nil?)
      if (edges[j].frequency <= BETA_FREQ && edges[j].frequency >= ALPHA_FREQ && !freqEdges[edges[j].frequency-1].nil?)#{
        for i in (0..freqEdges[edges[j].frequency-1].length - 1) # iterating to find i for which freqEdges is null
          if (!freqEdges[edges[j].frequency-1][i].nil?)
            break
          end
        end
        freqEdges[edges[j].frequency-1][i] = edges[j]
      end
    end
  end
  selectedEdges = Array.new
  # Selecting only those edges that satisfy the frequency condition [between ALPHA and BETA]
  j = BETA_FREQ-1
  while j >= ALPHA_FREQ-1 do
    if (!freqEdges[j].nil?)
      for i in (0..num-1)
        if (!freqEdges[j][i].nil?)
          selectedEdges[maxSelected] = freqEdges[j][i]
          maxSelected+=1
        end
      end
    end
    j -= 1
  end

  if (maxSelected != 0)
    @num_edges = maxSelected # replacing numEdges with the number of selected edges
  end
  selectedEdges
end

def append_to_previous(count, term, plainToken, iteration, labels, labelCounter)
  # fetching the previous vertex
  prevVertex = search_vertices(@vertices, term[count], iteration)
  # concatenating with contents of the previous vertex
  term[count] = term[count] + " " + plainToken
  # checking if the previous vertex concatenated with "s" already exists among the vertices
  if ((vertex = search_vertices(@vertices, term[count], iteration)) == nil)
    prevVertex.name = term[count]
    vertex = prevVertex # the current concatenated vertex will be considered
    if (labels[labelCounter] != "NMOD" || labels[labelCounter] != "PMOD")
      vertex.label = labels[labelCounter] # resetting labels for the concatenated vertex
    end
  end
  vertex
end

def create_new_branch(plainToken, iteration, type, state, labels, labelCounter, parents, parentCounter, posTag)
  # the vertex doesn't already exist
  if((vertex = search_vertices(@vertices, plainToken, iteration)) == nil)
    @vertices[@num_vertices] = Vertex.new(plainToken, type, iteration, state, labels[labelCounter], parents[parentCounter], posTag)
    vertex = @vertices[@num_vertices] # the newly formed vertex will be considered
    @num_vertices += 1
  end
  vertex
end

def delete_edge(v1, v2, i)
  # search_edges_to_set_null() returns the position in the array at which such an edge exists
  if (!v1.nil? && !v2.nil? && (e = search_edges_to_set_null(@edges, v1, v2, i)) != -1)
    @edges[e] = nil
    # if @num_edges had been previously incremented, decrement it
    if (@num_edges > 0)
      @num_edges -= 1
    end
  end
end

def create_edge(v1, v2, i, desc, type)
  # if such an edge did not already exist
  if (!v1.nil? && !v2.nil? && (e = search_edges(@edges, v1, v2, i)) == -1)
    @edges[@num_edges] = Edge.new(desc,type)
    @edges[@num_edges].in_vertex = v1
    @edges[@num_edges].out_vertex = v2
    @edges[@num_edges].index = i
    @num_edges += 1
    # since an edge was just added we try to check if there exist any redundant edges that can be removed
    remove_redundant_edges(v1, v2, i)
  end
end
