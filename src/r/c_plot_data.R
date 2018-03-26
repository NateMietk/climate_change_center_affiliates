
tm_shape(college_states) +
  tm_fill("STUSPS",  palette="white",
          title="Population density \n(per square mile)") +
  tm_borders("black")
  
tm_shape(partners) +
  tm_dots(size=.3, border.col="black") +
  tm_text("NAME", auto.placement = TRUE, shadow=TRUE, size=0.8)
