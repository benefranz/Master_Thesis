#install.packages("XML")
#install.packages("mise")
#install.packages("mise")
library(stringi)
library(tictoc) 
library(mise) 
library(XML)
mise()

# Setup
Sys.setenv(LANGUAGE='en')
setwd("/Users/benediktfranz/OneDrive - bwedu/Studium/Master/MasterThesis/French Data")

# Read XML data and convert to lists
tic()
dataxml <- xmlParse("./PrixCarburants_annuel_2020.xml")
datalist <- xmlToList(dataxml)
toc()

# Setup dataframe to store values in
totdata <- data.frame(matrix(vector(), 0, 372), stringsAsFactors=F)
names(totdata) <- c("street", "city", "fuel", "ID", "latitude", "longitude", format(seq(as.Date("2020-01-01"), as.Date("2020-12-31"), by="days"), format="%Y-%m-%d"))

# Loop through prices and different fuel types
tic()
for (k in 1:length(datalist)) {
  print(k)
  str <- datalist[k][[1]][1]
  cit <- datalist[k][[1]][2]
  save <- datalist[k][[1]][5:length(datalist[k][[1]])]
  id <- as.numeric(paste0(datalist[k][[1]][length(datalist[k][[1]])][[1]][1]))
  lat <- as.numeric(paste0(datalist[k][[1]][length(datalist[k][[1]])][[1]][2]))
  long <- as.numeric(paste0(datalist[k][[1]][length(datalist[k][[1]])][[1]][3]))
  
  mydata <- do.call(rbind.data.frame, save) 
  names(mydata) <- c("fuel", "number", "day", "price", "fuel")
  
  # Extract only the dates
  mydata$day <- substr(mydata$day,1,10)
  
  
  for (i in unique(mydata$fuel)) {
    if (!is.element(i, c("Gazole", "SP95", "SP98"))) {
      next
    }
    subframe <- mydata[mydata$fuel==i,]
    totdata[nrow(totdata)+1,] <- NA
    totdata[nrow(totdata),1] <- str
    totdata[nrow(totdata),2] <- cit
    totdata[nrow(totdata),3] <- i
    totdata[nrow(totdata),4] <- id
    totdata[nrow(totdata),5] <- lat
    totdata[nrow(totdata),6] <- long
    for (j in unique(subframe$day)) {
      price <- mean(as.numeric(subframe[subframe$day == j,"price"]))
      totdata[nrow(totdata), j] <- price
    }
  }
}
toc()
write.csv2(totdata, file="./data.csv")