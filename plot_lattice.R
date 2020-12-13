plot_lattice = function(.length = 2, dimensions = 2, target = 1, plot.it = T) {
  g <- graph.lattice(length = .length, dim = dimensions, circular = T)
  e <- as_edgelist(g)
  e.cols = ifelse(apply(e == target, 1, any), 3, 'black') # rows containing the target are color 3
  e.w = ifelse(apply(e == target, 1, any), 7, 1) # rows containing the target are cwidth 1
  v <- V(g)
  v.cols = rep('orange', times = length(v))
  for (i in v) {
    if (any(e[,1] == target & e[,2] == i)) {v.cols[i] <- 3}
    if (any(e[,1] == i & e[,2] == target)) {v.cols[i] <- 3}
  }
  v.cols[v==target] = 'red' # make the first node red
  if (plot.it) {plot(g, edge.color = e.cols, edge.width = e.w, vertex.color = v.cols)}
  return(c(
    'connected_to_target' = which(v.cols == 3)
  ))
}
