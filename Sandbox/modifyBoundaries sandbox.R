# modifyBoundaries

# This is used after "assignBoundaries"
# Specifically it is used after "universityBoundaries" 
# and I should probably just move it into there? Probably?
# or.... what, was this already done?

modifyBoundaries <- function(data) {
  
  # adjust size based on "university" designation
  
  data$shape_size[data$boundary_type == "primary , university"] <- 2
  data$shape_size[data$boundary_type == "primary"] <- 0.75
  
  return(data)
  
}