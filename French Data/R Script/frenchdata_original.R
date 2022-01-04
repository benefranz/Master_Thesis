library(XML)
library(ggplot2)
library(maps)
library(scales)
library(RColorBrewer)
library(plyr)

date.available <- Sys.Date() - 40
day <- format(date.available, "%Y%m%d")
baseurl <- "http://donnees.roulez-eco.fr/opendata/jour/"

# Récupération des données
temp <- tempfile()
download.file(paste0(baseurl, day), temp)
xmlsource <- unzip(temp, paste0("PrixCarburants_quotidien_", day, ".xml"))
unlink(temp)
parsed <- xmlParse(xmlsource)

#parsed <- xmlParse("~/R/PrixCarburants_quotidien_20150902.xml")

gazole <- data.frame(
  id = xpathSApply(parsed, "//prix[@nom='Gazole']/../@id"),
  cp = xpathSApply(parsed, "//prix[@nom='Gazole']/../@cp"),
  pop = xpathSApply(parsed, "//prix[@nom='Gazole']/../@pop"),
  ville = xpathSApply(parsed, "//prix[@nom='Gazole']/../ville/text()", xmlValue),
  adresse = xpathSApply(parsed, "//prix[@nom='Gazole']/../adresse/text()", xmlValue),
  latitude = as.numeric(xpathSApply(parsed, "//prix[@nom='Gazole']/../@latitude")) / 100000,
  longitude = as.numeric(xpathSApply(parsed, "//prix[@nom='Gazole']/../@longitude")) / 100000,
  prix = as.numeric(xpathSApply(parsed, "//prix[@nom='Gazole' and position()=1]/@valeur")) / 1000,
  date = as.Date(xpathSApply(parsed, "//prix[@nom='Gazole' and position()=1]/@maj"))
)

# Ajout départements. Cas particuliers : Corse et COM
gazole$dep <- ifelse(substr(gazole$cp, 1, 2) == "97" | substr(gazole$cp, 1, 2) == "20",
                     substr(gazole$cp, 1, 3),
                     substr(gazole$cp, 1, 2)
)
gazole$dep[which(gazole$dep == "200" | gazole$dep == "201")] <- "2A"
gazole$dep[which(gazole$dep == "202" | gazole$dep == "206")] <- "2B"

gazole$dep <- as.factor(gazole$dep)

# Régions
dep <- read.table("http://www.insee.fr/fr/methodes/nomenclatures/cog/telechargement/2015/txt/depts2015.txt", 
                  fill = TRUE, header = TRUE, fileEncoding = "windows-1252", sep="\t", quote="")
reg <- read.table("http://www.insee.fr/fr/methodes/nomenclatures/cog/telechargement/2015/txt/reg2015.txt", 
                  fill = TRUE, header = TRUE, fileEncoding = "windows-1252", sep="\t", quote="")
dep$REGION <- as.factor(dep$REGION)
dep <- rename(dep, c("DEP" = "dep", "NCCENR" = "lib.dep"))  
reg <- rename(reg, c("NCCENR" = "lib.reg")) 

gazole <- join(gazole, dep, by = "dep")
gazole <- join(gazole, reg, by = "REGION")

# Suppression données très anciennes (avant début de l'année)
gazole <- subset(gazole, date >= paste0(substr(day, 1, 4), "-01-01"))

ancien <- data.frame(j = as.numeric(date.available - gazole$date))
ggplot(ancien, aes(x=j)) + 
  geom_histogram() +
  ggtitle("Gazole - Ancienneté des mises à jour") +
  xlab("Jours") +
  ylab("N") 
