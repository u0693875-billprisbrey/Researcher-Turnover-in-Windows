# Writing over an entire plot sandbox
# 6.18.2025

# Create the layout 
layout(matrix(c(1,1,1,1,2,3,4,5), nrow = 2, byrow = TRUE),
       heights = c(0.3, 1)) 

# Draw five graphics
par(mar = c(0,0,0,0.1))
barplot(as.matrix(c(0.619,0.381)), 
        col = c("gray","pink"), 
        horiz = TRUE)
usr_one <- par("usr")


par(mar = c(0,0,0,0.1))
plot(17:23)
usr_two <- par("usr")

par(mar = c(0,0,0,0.1))
barplot((1:4)^2, col = viridisLite::viridis(4))
usr_three <- par("usr")

par(mar = c(0,0,0,0))
barplot((4:1)^2, col = viridisLite::viridis(4, direction=-1))
usr_four <- par("usr")

par(mar = c(0,0,0,0))
plot(10:1)
usr_five <- par("usr")

# adding lines across the whole thing
# second attempt 

par(fig = c(0, 1, 0, 0.7), new = TRUE, mar = c(0, 0, 0, 0))

plot(NA,
     xlim = c(0, 1),  # stretch across full width
     ylim = usr_five[3:4],  # same vertical scale as last plot
     type = "n", axes = FALSE, xlab = "", ylab = "")

segments(x0 = 0, x1 = 1, y0 = 8, y1 = 8, col = "red", lwd = 2)


# adding a green line over just the middle two at a value of five
plot(NA,
     xlim = c(0.25, 0.75),  # stretch across middle two
     ylim = usr_three[3:4],  # same vertical scale as third plot
     type = "n", axes = FALSE, xlab = "", ylab = "")


segments(x0 = 0, x1 = 1, y0 = 8, y1 = 8, col = "forestgreen", lwd = 2, lty = 2)


#####
#####


# first attempting a value of 8 in the bottom right graphic

par(fig = c(0, 1, 0, 0.7),  # bottom row (second layout row)
    new = TRUE,             # overlay on top of existing
    mar = c(0, 0, 0, 0))    # no margins


# Create an empty plot using the last panel's coordinate system
# Grab the coordinates from the last plot (plot(10:1))
usr <- par("usr")  # gives c(x1, x2, y1, y2)
plot(NA, xlim = c(usr[1], usr[2]), ylim = c(usr[3], usr[4]), type = "n", axes = FALSE, xlab = "", ylab = "")


# Draw the line at y = 8 (in the last plot's user coordinates)
abline(h = 8, col = "red", lwd = 2)


#####
#####

# third attempt
# this works but only based on the coordinates of the last graphic

# Create the layout 
layout(matrix(c(1,1,1,1,2,3,4,5), nrow = 2, byrow = TRUE),
       heights = c(0.3, 1)) 

# Draw five graphics
par(mar = c(0,0,0,0))
barplot(as.matrix(c(0.619,0.381)), 
        col = c("gray","pink"), 
        horiz = TRUE)
usr_one <- par("usr")


par(mar = c(2,2,2,2))
plot(17:23)
usr_two <- par("usr")

par(mar = c(0,0,0,0.1))
barplot((1:4)^2, col = viridisLite::viridis(4))
usr_three <- par("usr")

par(mar = c(0,0,0,0))
barplot((4:1)^2, col = viridisLite::viridis(4, direction=-1))
usr_four <- par("usr")

par(mar = c(0,0,0,0))
plot(10:1)
usr_five <- par("usr")

# adding lines across everything

# Convert y = 8 in the fifth plot’s coordinate system to device space
y_ndc <- grconvertY(8, from = "user", to = "ndc")  # y = 8 in usr_five scale

# Draw a red line across the full bottom row
segments(x0 = grconvertX(0, "ndc", "user"),
         y0 = grconvertY(y_ndc, "ndc", "user"),
         x1 = grconvertX(1, "ndc", "user"),
         y1 = grconvertY(y_ndc, "ndc", "user"),
         col = "red", lwd = 2, xpd = NA)

# Draw a green dashed line across middle two graphics

# y = 5 in usr_five
# y_ndc_green <- grconvertY(5, from = "user", to = "ndc")

# segments(x0 = grconvertX(0.25, "ndc", "user"),
#         y0 = grconvertY(y_ndc_green, "ndc", "user"),
#         x1 = grconvertX(0.75, "ndc", "user"),
#         y1 = grconvertY(y_ndc_green, "ndc", "user"),
#         col = "forestgreen", lwd = 2, lty = 2, xpd = NA)

# attempting y = 5 in usr_three or usr_four
# You have to normalize to the scale used in the last graphic,
# because that is where grconvert is happening
# And this is not. quite. there.

# complicated!

# Assume usr_three has been captured just after the third plot
# usr <- usr_three
# y_user <- 5
# y_frac <- (y_user - usr[3]) / (usr[4] - usr[3])
# y_ndc <- 0 + y_frac * 0.7  # bottom row is from 0 to 0.7 in NDC Y

# segments(x0 = grconvertX(0.25, "ndc", "user"),
#         y0 = grconvertY(y_ndc, "ndc", "user"),
#         x1 = grconvertX(0.75, "ndc", "user"),
#         y1 = grconvertY(y_ndc, "ndc", "user"),
#         col = "forestgreen", lwd = 2, lty = 2, xpd = NA)


# Draw border boxes

# ---- OVERLAY INVISIBLE PLOT FOR GRAY AND PINK BOXES ----

# Make sure we're drawing on top of everything
par(fig = c(0, 1, 0, 1), new = TRUE, mar = c(0, 0, 0, 0))
plot.new()

# Padding adjustment (try tweaking this value)
pad <- 0.025

# Adjusted box coords
xleft_gray   <- 0     - pad
xright_gray  <- 0.5 
xleft_pink   <- 0.5   
xright_pink  <- 1     + pad
ybottom      <- 0     - pad
ytop         <- 0.769 + pad


# Convert to user coords for this null plot (0–1)
rect(xleft = xleft_gray,
     ybottom = ybottom,
     xright = xright_gray,
     ytop = ytop,
     border = "gray30",
     lwd = 4,
     lty = 2,
     xpd = NA)

rect(xleft = xleft_pink,
     ybottom = ybottom,
     xright = xright_pink,
     ytop = ytop,
     border = "deeppink3",
     lwd = 4,
     xpd = NA)


