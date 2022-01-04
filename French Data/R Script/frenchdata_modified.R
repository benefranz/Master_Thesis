library(mise)
library(XML)
mise()

temp <- tempfile()
download.file("https://donnees.roulez-eco.fr/opendata/annee/2021", temp)
xmlsource <- unzip(temp, "PrixCarburants_annuel_2021.xml")
unlink(temp)
parsed <- xmlParse(xmlsource)

gazole <- data.frame(
  id = xpathSApply(parsed, "//prix[@nom='Gazole']/../@id"),
  cp = xpathSApply(parsed, "//prix[@nom='Gazole']/../@cp"),
  pop = xpathSApply(parsed, "//prix[@nom='Gazole']/../@pop"),
  ville = xpathSApply(parsed, "//prix[@nom='Gazole']/../ville/text()", xmlValue),
  adresse = xpathSApply(parsed, "//prix[@nom='Gazole']/../adresse/text()", xmlValue),
  latitude = as.numeric(xpathSApply(parsed, "//prix[@nom='Gazole']/../@latitude")) / 100000,
  longitude = as.numeric(xpathSApply(parsed, "//prix[@nom='Gazole']/../@longitude")) / 100000,
  prix_gazole = as.numeric(xpathSApply(parsed, "//prix[@nom='Gazole']/@valeur")) / 1000,
  date = as.Date(xpathSApply(parsed, "//prix[@nom='Gazole']/@maj"))
)


write.csv2(gazole, file="/Users/benediktfranz/Downloads//data.csv")


