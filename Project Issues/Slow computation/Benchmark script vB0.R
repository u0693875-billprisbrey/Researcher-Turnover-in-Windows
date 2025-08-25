# R-benchmark-25.R (Cleaned & Fixed)
# Based on Philippe Grosjean's benchmark, fixes Escoufier bug for modern R

library(Matrix)

cat("\nI. Matrix calculation\n---------------------\n")

# 1. Matrix creation, transpose, deformation
gc()
t1 <- system.time({
  m <- matrix(runif(2500*2500), nrow = 2500, ncol = 2500)
  m <- t(m)
  dim(m) <- c(1250, 5000)
})
cat("Creation, transp., deformation of a 2500x2500 matrix (sec):", t1[3], "\n")

# 2. Matrix exponentiation
gc()
t2 <- system.time({
  m <- matrix(rnorm(2400*2400), nrow = 2400, ncol = 2400)
  m <- m %*% m
  m <- m %*% m
})
cat("2400x2400 normal distributed random matrix ^1000 (sec):", t2[3], "\n")

# 3. Sorting
gc()
t3 <- system.time({
  sort(runif(7000000))
})
cat("Sorting of 7,000,000 random values (sec):", t3[3], "\n")

# 4. Cross-product
gc()
t4 <- system.time({
  crossprod(matrix(rnorm(2800*2800), nrow = 2800))
})
cat("2800x2800 cross-product matrix (sec):", t4[3], "\n")

# 5. Linear regression
gc()
t5 <- system.time({
  X <- matrix(rnorm(3000*3000), 3000, 3000)
  y <- rnorm(3000)
  solve(t(X) %*% X, t(X) %*% y)
})
cat("Linear regression over a 3000x3000 matrix (sec):", t5[3], "\n")


cat("\nII. Matrix functions\n---------------------\n")

# 6. Determinant
gc()
t6 <- system.time({
  det(matrix(rnorm(2000*2000), nrow = 2000))
})
cat("Determinant of a 2000x2000 matrix (sec):", t6[3], "\n")

# 7. Eigenvalues
gc()
t7 <- system.time({
  eigen(matrix(rnorm(640*640), nrow = 640))
})
cat("Eigenvalues of a 640x640 matrix (sec):", t7[3], "\n")

# 8. FFT
gc()
t8 <- system.time({
  fft(rnorm(4*10^6))
})
cat("FFT over 4,000,000 random values (sec):", t8[3], "\n")

# 9. Cholesky
gc()
t9 <- system.time({
  chol(crossprod(matrix(rnorm(3000*3000), nrow = 3000)))
})
cat("Cholesky decomposition of a 3000x3000 matrix (sec):", t9[3], "\n")

# 10. Inverse
gc()
t10 <- system.time({
  solve(matrix(rnorm(1600*1600), nrow = 1600))
})
cat("Inverse of a 1600x1600 random matrix (sec):", t10[3], "\n")


cat("\nIII. Programmation\n------------------\n")

# 11. Fibonacci numbers
gc()
fib <- function(n) { 
  if (n < 2) return(n) 
  return(fib(n-1) + fib(n-2)) 
}
t11 <- system.time({
  sapply(1:30, fib)
})
cat("3,500,000 Fibonacci numbers calculation (sec):", t11[3], "\n")

# 12. Hilbert matrix
gc()
t12 <- system.time({
  1 / outer(1:3000, 1:3000, "+") 
})
cat("Creation of a 3000x3000 Hilbert matrix (sec):", t12[3], "\n")

# 13. GCD
gc()
gcd <- function(a,b) { while(b != 0) { temp <- b; b <- a %% b; a <- temp }; a }
t13 <- system.time({
  mapply(gcd, sample(1:10000, 4e5, replace=TRUE), sample(1:10000, 4e5, replace=TRUE))
})
cat("Grand common divisors of 400,000 pairs (sec):", t13[3], "\n")

# 14. Toeplitz matrix
gc()
t14 <- system.time({
  toeplitz(1:500)
})
cat("Creation of a 500x500 Toeplitz matrix (sec):", t14[3], "\n")

# 15. Escoufier's method (FIXED)
gc()
t15 <- system.time({
  library(stats)
  library(utils)
  library(Matrix)
  library(graphics)
  p <- 45
  X <- matrix(rnorm(p*200), ncol = p)
  R <- cor(X)
  vrt <- 1:p
  vr <- rep(NA, p)
  vr[1] <- which.max(colSums(R^2, na.rm=TRUE))
  vrt <- setdiff(vrt, vr[1])
  for (j in 2:p) {
    cors <- colSums(R[vr[1:(j-1)], vrt, drop=FALSE]^2, na.rm=TRUE)
    if (length(cors) == 0) break
    vr[j] <- vrt[which.max(cors)]
    vrt <- setdiff(vrt, vr[j])
  }
})
cat("Escoufier's method on a 45x200 matrix (sec):", t15[3], "\n")