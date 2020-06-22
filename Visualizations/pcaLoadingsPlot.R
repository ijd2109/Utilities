###############################################################
# Function for plotting the eigenvector of loadings from a PCA
# produced from stats::prcomp(..., retx = TRUE)
# (supply either an object of class 'prcomp', or its rotation matrix)
# Ian Douglas - March 2020
# 0.0.1
# 

pcaLoadingsPlot <- function(x, n_components, plot.it = TRUE) {
  require(ggplot2)
  require(tibble)
  
  # Extract loadings (if 'prcomp' object supplied), & select desired n_components
  if (class(x) == "prcomp") {
    X <- x$rotation[, 1:n_components]
  } else X <- x[, 1:n_components]
  
  # Format data for plotting
  plt_dat <- as.data.frame(X) %>%
    rownames_to_column(var = "raw_item") %>%
    gather(key = "PC", value = "Loading", -raw_item)
  
  # Generate plot
  plt = ggplot(data = plt_dat) +
    geom_segment(aes(x = raw_item, xend = raw_item, y = Loading, yend = 0), color = "grey") +
    geom_hline(yintercept = 0, linetype = 2, color = "grey") +
    geom_point(aes(x = raw_item, y = Loading)) +
    facet_wrap(~PC) +
    coord_flip() +
    theme_linedraw() +
    xlab("Raw Item")
  
  # # Render
  if (plot.it) {print(plt)} else return(plt)
}