#Travis's Personally Useful Functions:
utils::globalVariables('words')
utils::globalVariables('.')


Percent <- function(true, test)
{
  return(sum(diag(table(true, test)))/sum(table(true, test)))
}

Table_percent <- function(in_table)
{
  return(sum(diag(in_table))/sum(in_table))
}

Cross_val_maker <- function(data, alpha)
{
  if(alpha > 1 || alpha <= 0)
  {
    return("Alpha must be between 0 and 1")
  }
  index <- sample(c(1:nrow(data)), round(nrow(data)*alpha))
  train <- data[-index,]
  test <- data[index,]
  return(list("Train" = as.data.frame(train), "Test" = as.data.frame(test)))
}

Codes_done <- function(title = "Codes Done", msg = " ", sound = FALSE, effect = 1)
{
  theTitle <- title
  theMsg <- msg
  if (Sys.info()["sysname"] == "Darwin")
  {
    cmd <- paste("osascript -e ", "'display notification ", '"', theMsg, '"', ' with title ', '"', theTitle, '"', "'", sep='')
    system(cmd)
  }
  else if(.Platform$OS.type == "windows")
  {
    system('CMD /C "ECHO The R process has finished running && PAUSE"',
           invisible=FALSE, wait=FALSE)
  }
  else if(.Platform$OS.type == "unix")
  {
    cmd <- paste("osascript -e ", "'display notification ", '"', theMsg, '"', ' with title ', '"', theTitle, '"', "'", sep='')
    system(cmd)
  }
  else
  {
    print(title)
    print(msg)
  }

  if(sound == T)
  {
    beepr::beep(effect)
  }
}

Nearest_Centroid <- function(X_train, X_test, Y_train)
{
  names(X_test) = names(X_train)
  results = matrix(0, nrow(X_test), 10)
  indexindex = vector("list", length = 10)
  neighbors = list(vector("list", length = 10))
  s = c(rep(NA, 10))
  time = c(rep(0, 10))
  for(i in 1:10){
    indexindex[[i]] <- X_train[which(Y_train == (i-1)), ]
    neighbors[[i]] <- FNN::get.knnx(indexindex[[i]], X_test,  k=11, algorithm=c("kd_tree"))$nn.index[,-1]
  }
  for(i in 1:nrow(X_test)){
    point_mat <- matrix(0, 10, 10)
    for(k in 1:10){
      s[k] = Sys.time()
      if(k == 1)
      {
        for(l in 1:10){
          candidate = (indexindex[[l]][neighbors[[l]][i, 1:k],])
          point_mat[l, k] = sqrt(sum((X_test[i,] - candidate)^2))
        }
      }
      else{
        for(l in 1:10){
          candidate = apply(indexindex[[l]][neighbors[[l]][i, 1:k],],2, mean)
          point_mat[l, k] = sqrt(sum((X_test[i,] - candidate)^2))
        }
      }
      results[i, k] = max(which(point_mat[, k] == min(point_mat[,k]))) - 1
      s[k] = Sys.time() - s[k]
    }
    time = rbind(time, s)
  }
  return(results)
  #return(list(res = results, time = time))
}

Monty_Hall = function(Games = 10, Choice = "Stay")
{
  choice1 = function()
  {
    return(sample(c(1, 2, 3), 1))
  }

  choice2 = function(Choice = "Random")
  {
    if(Choice == "Random"){
      return(sample(c(1, 2), 1))
    }
    else if (Choice == "Stay")
    {
      return(1)
    }
    else if (Choice == "Switch")
    {
      return(2)
    }
    else
    {
      print("You must choose a valid choice")
    }
  }


  Single_Game = function(Choice = "Random")
  {
    winning_door = sample(c(1, 2, 3), 1)
    round1 = choice1()
    round2 = choice2(Choice)

    if(round2 == 1){
      if(round1 == winning_door){
        return(1)
      }
      else{
        return(0)
      }
    }
    else{
      if(round1 != winning_door){
        return(1)
      }
      else{
        return(0)
      }
    }

  }


  results = {}
  for (i in 1:Games) {
    results = c(results, Single_Game(Choice))

  }

  dat = data.frame(V1 = c(sum(results), Games-sum(results)), V2 = 	c("Win", "Lose"))
  ggplot2::ggplot(data = dat, ggplot2::aes(x = dat$V2, y = dat$V1)) +
    ggplot2::geom_bar(stat = "identity", fill = c("pink", "light blue")) +
    ggplot2::geom_text(ggplot2::aes(label = dat$V1), vjust = 1.1) +
    ggplot2::ylab("Game Count") + ggplot2::xlab(" ") +
    ggplot2::ggtitle("Heres how you did!") +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = .5))
}

Binary_Network = function(X, Y, X_test, val_split, nodes, epochs, batch_size, verbose = 0)
{
  model <- keras_model_sequential()
  model %>%
    layer_dense(units = nodes, input_shape = ncol(X)) %>%
    layer_activation_leaky_relu(alpha = .001) %>%
    layer_dropout(.4) %>%
    layer_dense(units = nodes) %>%
    layer_activation_leaky_relu(.001) %>%
    layer_dense(units = 2, activation = "softmax")
  model %>% compile(
    loss = 'binary_crossentropy',
    optimizer = optimizer_adam(),
    metrics = c('accuracy')
  )
  history <- model %>% fit(
    X, Y,
    epochs = epochs,
    batch_size = batch_size,
    validation_split = val_split
  )

  train = model %>% predict_proba(X)
  test = model %>% predict_proba(X_test)
  dat = list(train = train, test = test)
  return(dat)
}

Feed_Reduction = function(X, Y, X_test, val_split = .1, nodes = NULL, epochs = 15, batch_size = 30, verbose = 0)
{
  if(is.null(nodes) == TRUE){
    nodes = round(ncol(X)/4)
  }
  labels = sort(unique(Y), decreasing = F)
  final_train = matrix(0, nrow = nrow(X), ncol = length(labels))
  final_test = matrix(0, nrow = nrow(X_test), ncol = length(labels))
  i = 1
  for(label in labels){
    index = which(Y == label)
    y <- Y
    y[index] = 1
    y[-index] = 0
    y = to_categorical(y, 2)
    temp = Binary_Network(X, y, X_test, val_split, nodes, epochs, batch_size, verbose)
    final_train[, i] = temp$train[,1]
    final_test[, i] = temp$test[,1]
    i = i + 1

  }

  return(list(train = final_train, test = final_test))
}

Num_Al_Sep = function(vec)
{
  vec = unlist(strsplit(vec, "(?=[A-Za-z])(?<=[0-9])|(?=[0-9])(?<=[A-Za-z])", perl = TRUE))
  vec = paste(vec, collapse = " ")
  return(vec)
}

Pretreatment = function(title_vec, stem = TRUE, lower = TRUE, parallel = FALSE)
{
  Num_Al_Sep = function(vec){
    vec = unlist(strsplit(vec, "(?=[A-Za-z])(?<=[0-9])|(?=[0-9])(?<=[A-Za-z])", perl = TRUE))
    vec = paste(vec, collapse = " ")
    return(vec)
  }
  replace_number_conditional = function(string){
    if("textclean" %in% rownames(installed.packages())){
      return(textclean::replace_number(string))
    }
    else{
      return(gsub("[0-9]", 'X', string))
    }
  }
  if(parallel == F){
    titles = as.character(title_vec) %>%
      lapply(gsub, pattern = "[^[:alnum:][:space:]]",replacement = "") %>%
      unlist() %>%
      lapply(Num_Al_Sep) %>%
      unlist() %>%
      lapply(replace_number_conditional) %>%
      unlist()
    if(stem == TRUE){
      titles = titles %>%
        lapply(stemDocument) %>%
        unlist()
    }
    if(lower == TRUE){
      titles = titles %>%
        lapply(tolower) %>%
        unlist()
    }
    return(titles)
  }
  else{
    numcore = detectCores() - 1
    titles = as.character(title_vec) %>%
      mclapply(gsub, pattern = "[^[:alnum:][:space:]]",replacement = "", mc.cores = numcore) %>%
      unlist() %>%
      mclapply(Num_Al_Sep, mc.cores = numcore) %>%
      unlist() %>%
      mclapply(replace_number_conditional, mc.cores = numcore) %>%
      unlist()
    if(stem == TRUE){
      titles = titles %>%
        mclapply(stemDocument, mc.cores = numcore) %>%
        unlist()
    }
    if(lower == TRUE){
      titles = titles %>%
        mclapply(tolower, mc.cores = numcore) %>%
        unlist()
    }
    return(titles)
  }
}

Stopword_Maker = function(titles, cutoff = 20)
{
  test = unlist(lapply(as.vector(titles), strsplit, split = ' ', fixed = FALSE))
  stopwords = test %>%
    table() %>%
    sort(decreasing = TRUE) %>%
    head(cutoff) %>%
    names()
  return(stopwords)
}

Vector_Puller = function(words, emb_matrix, dimension)
{
  ret = colMeans(emb_matrix[words,], na.rm = TRUE)[1:dimension]
  if(all(is.na(ret)) == T){
    return(rep(0, dimension))
  }
  return(ret)
}

Sentence_Vector = function(Sentence, emb_matrix, dimension, stopwords)
{
  words_list = stringi::stri_extract_all_words(Sentence, simplify = T)
  words_list = words_list[-(words_list %in% stopwords)]
  vecs = Vector_Puller(words_list, emb_matrix, dimension)

  return(t(vecs))
}

Load_Glove_Embeddings = function(path = 'glove.42B.300d.txt', d = 300)
{
  col_names <- c("term", paste("d", 1:d, sep = ""))
  dat <- as.data.frame(read_delim(file = path,
                                  delim = " ",
                                  quote = "",
                                  col_names = col_names))
  rownames(dat) = dat$term
  dat = dat[,-1]
  return(dat)
}

Bootstrap_Vocab = function(vocab, N, stopwds, min_length = 7, max_length = 15)
{

  res = {}
  sent = ''
  cutoff = sample(min_length:max_length, 1)
  while(length(res) < N){
    sent = paste(sent, vocab[sample(1:length(vocab), 1)] %>%
                   strsplit(' ') %>%
                   unlist() %>%
                   data.frame('words' = ., stringsAsFactors = F) %>%
                   filter(!(words %in% stopwds)) %>%
                   sample_n(1), ' ')

    len = strsplit(sent, ' ') %>%
      unlist() %>%
      as.data.frame() %>%
      filter(. != '') %>%
      nrow()


    if(len > cutoff){
      res = c(res, sent)
      sent = ''
      cutoff = sample(min_length:max_length, 1)
    }

  }
  return(res)
} # For one class

Bootstrap_Data_Frame = function(text, tags, stopwords, min_length = 7, max_length = 15)
{
  max_tags =floor(1.1*max(table(tags)))
  newdata = data.frame('text' = text, 'tags' = tags, stringsAsFactors = F)
  for (tag in unique(tags)) {
    tag_index = which(tags == tag)
    num_to_boostrap = max_tags - length(tag_index)
    new_sents = text[tag_index] %>%
      Bootstrap_Vocab(num_to_boostrap, stopwords, min_length, max_length)

    new_row = cbind(new_sents, rep(tag, length(new_sents)))
    new_row = data.frame('text' = new_row[,1], 'tags' = new_row[,2], stringsAsFactors = F)
    newdata = rbind(newdata, new_row)
  }
  newdata$text = as.character(newdata$text)
  return(newdata)
} # For the whole database

Random_Brains = function(data, y, x_test, variables = ceiling(ncol(data)/10),  brains = floor(sqrt(ncol(data))), hiddens = c(3, 4))
{
  # Data: Dataframe or matrix of values
  data = as.data.frame(cbind(data, y))
  colnames(data) = c(paste('V', 1:(ncol(data)-1), sep = ''), 'label')
  preds = matrix(NA, ncol = brains, nrow = nrow(x_test))
  final_preds = c()
  cols = matrix(ncol = variables, nrow = brains)
  for(i in 1:brains){
    coldex = sample(1:(ncol(data)-1), variables)
    cols[i,] = coldex
    res = neuralnet(label~., data = data[,c(coldex, ncol(data))], hidden = hiddens, linear.output = F)
    preds[,i] = apply(predict(res, as.matrix(x_test[,coldex])), 1, which.max)
  }
  for(i in 1:nrow(preds)){
    final_preds = c(final_preds, names(head(sort(table(preds[i,])),1)))
  }
  return(list('predictions' = final_preds, 'num_brains' = brains, 'predictors_per_brain' = variables,
              'hidden_layers' = hiddens, 'preds_per_brain' = cols, 'raw_results' = preds))
}

