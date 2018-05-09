require 'sentence_state'
require 'edge'
require 'vertex'
require 'matrix'

class WordOrderGraph
  attr_accessor :vertices, :num_vertices, :edges, :num_edges, :pipeline

  def initialize
    @noun_vertices = []
    @adj_vertices = []
    @adv_vertices = []
    @verb_vertices = []

    @vertices = []
    @edges = []
  end

  # generates the graph for the given review text and
  # INPUT: an array of sentences for a review or a submission. Every row in 'text' contains one sentence.
  # type - tells you if it was a review or a submission
  # type = 1 - submission/past review
  # type = 2 - new review
  def generate_graph(text, coreNLPTagger)
    @pipeline = coreNLPTagger # dependency parsing

    @tp = TextPreprocessor.new
    text = StanfordCoreNLP::Annotation.new(text) # the same variable has to be passed into the Annotation.new method
    @pipeline.annotate(text)

    text.get(:sentences).each do |sentence|
      # we must keep the order of tokens in the sentence
      @untagged_tokens = sentence.get(:tokens).to_a
      @untagged_tokens.map! { |token| token.to_s.gsub!(/-\d\d*/, "") }
      @parsed_sentence = sentence.get(:collapsed_c_c_processed_dependencies)

      # filter tokens and only keep the ones in parsed sentence
      parsed_tokens = @parsed_sentence.to_s.split(" ").select.with_index { |t, i| i%3 == 1 }
      untagged_parsed_tokens = parsed_tokens.map { |token| token.split("/").first }
      @untagged_tokens.select! { |token| untagged_parsed_tokens.include?(token) }
      @tagged_tokens = @untagged_tokens.map { |token| parsed_tokens[untagged_parsed_tokens.index(token)] }

      @parents = find_parents
      @labels = find_labels

      # find state
      sstate = SentenceState.new
      state_array = sstate.identify_sentence_state(@tagged_tokens)
      state = state_array[0]
      state_counter = 1
      prevType = nil

      # iterate through the tokens
      @tagged_tokens.each_with_index do |tagged_token|
        str_a = tagged_token.split('/')
        plain_token = str_a[0]
        pos_tag = str_a[1]

        next if pos_tag.nil?

        # if the token is a noun
        case pos_tag
          # this is for strings containing "'s"("/POS" tag)
          when 'POS'
            next

          # since the CC or IN are part of the following sentence segment, we set the STATE for that segment when we see a CC or IN
          when 'CC'
            state = state_array[state_counter]
            state_counter += 1

          when 'NN', 'PRP', 'IN', 'EX', 'WP'
            # if the previous token is a noun, add to a previous noun vertex
            if prevType == NOUN
              append_to_previous(@noun_vertices[-1], plain_token)
            # if the previous token is not a noun, create a brand new vertex
            else
              create_new_vertex(plain_token, NOUN, state, pos_tag)
              # remove_redundant_vertices(nouns[nCount], i)

              # checking if a noun existed before this one and if the adjective was attached to that noun.
              # if an adjective was found earlier, we add a new edge
              if prevType == ADJ
                # set previous noun's property to null, if it was set, if there is a noun before the adjective
                # fetching the previous noun, the one before the current noun (therefore -2)
                v1 = @noun_vertices[-2]
                # fetching the previous adjective
                v2 = @adj_vertices[-1]
                # if such an edge exists - DELETE IT -
                delete_edge(v1,v2)

                # add a new edge with v1 as the adjective and v2 as the new noun
                v1 = @adj_vertices[-1]
                v2 = @noun_vertices[-1] # the noun vertex that was just created
                create_edge(v1,v2,"noun-property",VERB)
              end

              # a noun has been found and has established a verb as an in_vertex and such an edge doesn't already previously exist
              # add edge only when a fresh vertex is created not when existing vertex is appended to
              v1 = @verb_vertices[-1]
              v2 = @noun_vertices[-1]
              create_edge(v1,v2,"verb",VERB)
            end
            prevType = NOUN

            # if the string is an adjective
            # adjectives are vertices but they are not connected by an edge to the nouns, instead they are the noun's properties
          when 'JJ'
            if prevType == ADJ
              # combine the adjectives
              append_to_previous(@adj_vertices[-1], plain_token)
            else
              # new adjective vertex
              create_new_vertex(plain_token, ADJ, state, pos_tag)
              # remove_redundant_vertices(adjectives[adjCount], i)

              # by default associate the adjective with the previous/latest noun and if there is a noun following it immediately,
              # then remove the property from the older noun (done under noun condition)
              v1 = @noun_vertices[-1]
              v2 = @adj_vertices[-1]
              # if such an edge does not already exist add it
              create_edge(v1,v2,"noun-property",VERB)
            end
            prevType = ADJ

          # if the string is a verb or a modal/length condition for verbs is, be, are...
          when 'VB', 'MD'
            if prevType == VERB
              # combine the verbs
              append_to_previous(@verb_vertices[-1], plain_token)
            else
              create_new_vertex(plain_token, VERB, state, pos_tag)
              # remove_redundant_vertices(verbs[vCount], i)

              # if an adverb was found earlier, we set that as the verb's property
              if prevType == ADV
                # set previous verb's property to null, if it was set, if there is a verb following the adverb
                # fetching the previous verb, the one before the current one (hence -2)
                v1 = @verb_vertices[-2]
                # fetching the previous adverb
                v2 = @adj_vertices[-1]
                # if such an edge exists - DELETE IT
                delete_edge(v1,v2)

                # if this verb vertex was encountered for the first time, vCount < 1,
                # add a new edge with v1 as the adverb and v2 as the new verb
                v1 = @adv_vertices[-1]
                v2 = @verb_vertices[-1]
                # if such an edge did not already exist
                create_edge(v1,v2,"verb-property",VERB)
              end

              # making the previous noun, one of the vertices of the verb edge
              # gets the previous noun to form the edge
              v1 = @noun_vertices[-1]
              v2 = @verb_vertices[-1]
              # if such an edge does not already exist add it
              create_edge(v1, v2,"verb", VERB)
            end
            prevType = VERB

          # if the string is an adverb
          when 'RB'
            if prevType == ADV
              # appending to existing adverb
              append_to_previous(@adv_vertices[-1], plain_token)
            else
              # creating a new vertex
              create_new_vertex(plain_token, ADV, state, pos_tag)
              # remove_redundant_vertices(adverbs[advCount], i)

              # by default associate it with the previous/latest verb and if there is
              # a verb following it immediately, then remove the property from the verb
              # form a verb-adverb edge
              v1 = @verb_vertices[-1]
              v2 = @adv_vertices[-1]
              # if such an edge does not already exist add it
              create_edge(v1,v2,"verb-property",VERB)
            end
            prevType = ADV
        end
      end

      prevType = nil
    end

    @vertices = @noun_vertices + @adj_vertices + @adv_vertices + @verb_vertices
    set_semantic_labels_for_edges
  end

  # Nullify all vertices containing "only substrings" (and not exact matches)
  # of this vertex in the same sentence (verts[j].index == index)
  # And reset the @vertices array with non-null elements.
  def remove_redundant_vertices(s, index)
    @vertices.each do |vtx|
      if vtx && vtx.index == index && s.casecmp(vtx.name) != 0 &&
          s.downcase.include?(vtx.name.downcase) && vtx.name.length > 1
        # the last 'length' condition is added so as to prevent "I" (an indiv. vertex) from being replaced by nil
        # search through all the edges and set those with this vertex as in-out- vertex to null
        if @edges
          @edges.each do |edge|
            if edge && (edge.in_vertex == vtx || edge.out_vertex == vtx)
              @edges[i] = nil # setting that edge to nil
            end
          end
        end
      end
    end

    # recreate the vertices array without the nil values
    @vertices.compact!
    @num_vertices = @vertices.size + 1 # since @num_vertices is always one advanced of the last vertex
  end


  # Checks to see if an edge between vertices "in" and "out" exists.
  # true - if an edge exists and false - if an edge doesn't exist
  # edge[] list, vertex in, vertex out, int index
  def search_edges(list, in_vertex, out, index)
    edgePos = -1
    return edgePos if list.nil?

    for i in (0..list.length-1)
      if check_if_nil(list, i)
        # checking for exact match with an edge
        if ((list[i].in_vertex.name.casecmp(in_vertex.name) == 0 || list[i].in_vertex.name.include?(in_vertex.name)) &&
            (list[i].out_vertex.name.casecmp(out.name) == 0 || list[i].out_vertex.name.include?(out.name))) ||
            ((list[i].in_vertex.name.casecmp(out.name) == 0 || list[i].in_vertex.name.include?(out.name)) &&
                (list[i].out_vertex.name.casecmp(in_vertex.name) == 0 || list[i].out_vertex.name.include?(in_vertex.name)))
          # if an edge was found
          edgePos = i # returning its position in the array
          # increment frequency if the edge was found in a different sent.
          # (check by maintaining a text number and checking if the new # is diff from prev #)
          if (index != list[i].index)
            list[i].frequency += 1
          end
        end
      end
    end

    edgePos
  end

  # Nullify all edges containing "only substrings" (and not exact matches) of either in/out vertices in the same sentence (verts[j].index == index)
  # and reset the @edges array with non-null elements.
  def remove_redundant_edges(in_vtx, out_vtx, index)
    @edges.each do |edge|
      if edge && edge.index == index
        # when in-vertices are eq and out-vertices are substrings or vice versa
        if in_vtx.name.casecmp(edge.in_vertex.name) == 0 && out_vtx.name.casecmp(edge.out_vertex.name) != 0 && out_vtx.name.downcase.include?(edge.out_vertex.name.downcase)
          edge = nil
          # when in-vertices are only substrings and out-verts are equal
        elsif in_vtx.name.casecmp(edge.in_vertex.name) != 0 && in_vtx.name.downcase.include?(edge.in_vertex.name.downcase) && out_vtx.name.casecmp(edge.out_vertex.name) == 0
          edge = nil
        end
      end
    end

    # recreating the edges array without the nil values
    @edges.compact!
    @num_edges = @edges.size + 1
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

  # Identify parents for the vertices
  def find_parents
    parents = {}

    # iterate through the set of tokens and identify each token's parent
    @untagged_tokens.each_with_index do |str|
      pat = @parsed_sentence.getAllNodesByWordPattern(str).to_a.first
      parent = @parsed_sentence.getParents(pat).to_a.first

      unless parent.nil?
        # extracting the name of the parent (since it is in the foramt-> "name/POS")
        parents[str] = parent.to_s.split("/").first
      end
    end

    parents
  end

  # Identify labels for the vertices
  def find_labels
    labels = {}

    govDeps = @parsed_sentence.typedDependencies.to_a
    # identify its corresponding position in govDep and fetch its label
    govDeps.each_with_index do |govDep|
      token = govDep.dep().to_s.split("/").first
      labels[token] = govDep.reln.getShortName()
    end

    labels
  end

  # Setting semantic labels for edges based on the labels vertices have with their parents
  def set_semantic_labels_for_edges
    @vertices.each do |vtx|
      parent = nil

      if vtx.parent.nil?
        next
      end

      @vertices.each do |v|
        if v&.name && v.name.include?(vtx.parent)
          parent = v
          break
        end
      end

      if parent
        @edges.each do |edge|
          if (edge.in_vertex.name == vtx.name && edge.out_vertex.name == parent.name) ||
              (edge.in_vertex.name == parent.name && edge.out_vertex.name == vtx.name)
            # set the role label
            if edge.label.nil? || edge.label == 'NMOD' || edge.label == 'PMOD'
              edge.label = vtx.label
            end
          end
        end
      end
    end
  end

  # Identifying frequency of edges and pruning out edges that do no meet the threshold conditions
  def identify_frequency_and_prune_edges(edges, num)
    # freqEdges maintains the top frequency edges from ALPHA_FREQ to BETA_FREQ
    freqEdges = [] # from alpha = 3 to beta = 10
    # iterating through all the edges
    for j in (0..num-1)
      if !edges[j].nil?
        if edges[j].frequency <= BETA_FREQ && edges[j].frequency >= ALPHA_FREQ && !freqEdges[edges[j].frequency - 1].nil?
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

  def append_to_previous(vtx, plainToken)
    if vtx
      vtx.name = vtx.name + " " + plainToken

      if @labels[plainToken] != 'NMOD' && @labels[plainToken] != 'PMOD'
        # reset labels for the concatenated vertex
        vtx.label = @labels[plainToken]
      end
    end

    vtx
  end

  def create_new_vertex(plainToken, type, state, posTag)
    # the vertex doesn't already exist
    # vertex = search_vertices(@vertices, plainToken, index)
    vtx = Vertex.new(plainToken, type, state, @labels[plainToken], @parents[plainToken], posTag)
    case type
      when NOUN
        @noun_vertices << vtx
      when ADJ
        @adj_vertices << vtx
      when VERB
        @verb_vertices << vtx
      when ADV
        @adv_vertices << vtx
      else
        nil
    end
  end

  def delete_edge(v1, v2)
    if v1 && v2
      @edges.each do |edge|
        # checking for exact match with an edge
        if (edge.in_vertex.name == v1.name && edge.out_vertex.name = v2.name) ||
            (edge.out_vertex.name == v1.name && edge.in_vertex.name = v2.name)
          @edges.delete(edge)
        end
      end
    end
  end

  def create_edge(v1, v2, name, type)
    # if such an edge did not already exist
    if v1 && v2
      edge = Edge.new(name, type)
      edge.in_vertex = v1
      edge.out_vertex = v2
      @edges << edge

      # since an edge was just added we try to check if there exist any redundant edges that can be removed
      # remove_redundant_edges(v1, v2, i)
    end
  end

end

